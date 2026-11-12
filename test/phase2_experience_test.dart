import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/core/period.dart';
import 'package:wall_o_pay/data/app_database.dart';
import 'package:wall_o_pay/data/recurring_service.dart';
import 'package:wall_o_pay/data/tables.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2 Experience Enhancement Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('schemaVersion is 9 with expected tables, indexes, and legacy upgrade guard', () async {
      expect(db.schemaVersion, 9);

      final indexes = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%'",
          )
          .get();
      final indexNames = indexes.map((r) => r.read<String>('name')).toSet();
      expect(indexNames, contains('debt_payments_debt_idx'));
      expect(indexNames, contains('pending_tx_rule_idx'));

      // Uji skenario upgrade dari v8 yang masih memiliki tabel pending_transactions lawas (pre-v1.11.15)
      final tempDir = Directory.systemTemp.createTempSync('wallopay_v9_mig_');
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });
      final dbFile = File('${tempDir.path}/upgrade_test.sqlite');

      // 1. Inisialisasi DB, sisipkan 1 transaksi agar teruji tidak hilang saat upgrade, lalu tutup
      final firstDb = AppDatabase(NativeDatabase(dbFile));
      await firstDb.addTransaction(
        amount: 75000,
        type: TxType.expense,
        categoryId: 'cat-exp-food',
        date: DateTime(2026, 11, 10),
        note: 'Data v8 selamat',
      );
      await firstDb.close();

      // 2. Turunkan ke state v8 dengan tabel pending_transactions format lama (tanpa updated_at & due_date)
      final rawDb = AppDatabase(NativeDatabase(dbFile));
      await rawDb.customStatement('DROP TABLE pending_transactions');
      await rawDb.customStatement(
        'CREATE TABLE pending_transactions (id TEXT NOT NULL PRIMARY KEY, body TEXT NOT NULL)',
      );
      await rawDb.customStatement("INSERT INTO pending_transactions (id, body) VALUES ('old-1', 'BCA Rp 10.000')");
      await rawDb.customStatement('PRAGMA user_version = 8');
      await rawDb.close();

      // 3. Buka ulang sebagai AppDatabase v9 — harus mendrop tabel lawas, membuat skema v9 bersih,
      //    dan tetap menjaga data transaksi pengguna dari v8.
      final upgradedDb = AppDatabase(NativeDatabase(dbFile));
      final cols = await upgradedDb.customSelect("PRAGMA table_info('pending_transactions')").get();
      final colNames = cols.map((c) => c.read<String>('name')).toSet();
      expect(colNames, containsAll(['updated_at', 'due_date', 'title', 'recurring_rule_id']));

      final pendingRows = await upgradedDb.getPendingTransactions();
      expect(pendingRows, isEmpty);

      final preservedTxs = await upgradedDb.allActiveTransactions();
      expect(preservedTxs.length, 1);
      expect(preservedTxs.first.note, 'Data v8 selamat');
      await upgradedDb.close();
    });

    test('watchSearchTransactions filters by walletId (incl. transfer target), categoryId, needWant, matchedCategoryIds, and >100 rows', () async {
      final baseDate = DateTime(2026, 11, 12);

      // Transfer keluar dari wallet-main ke wallet-digital
      await db.transferBetweenWallets(
        amount: 250000,
        fromWalletId: 'wallet-main',
        toWalletId: 'wallet-digital',
        date: baseDate,
        note: 'Top up tabungan digital',
      );

      await db.addTransaction(
        amount: 35000,
        type: TxType.expense,
        categoryId: 'cat-exp-food',
        walletId: 'wallet-digital',
        date: baseDate,
        note: 'Bakso Malang',
        needWant: NeedWant.need,
      );

      await db.addTransaction(
        amount: 45000,
        type: TxType.expense,
        categoryId: 'cat-exp-fun',
        walletId: 'wallet-cash',
        date: baseDate,
        note: 'Tiket bioskop',
        needWant: NeedWant.want,
      );

      // Filter wallet-digital harus memunculkan expense di wallet-digital DAN incoming transfer ke wallet-digital
      final digitalTxs = await db.watchSearchTransactions(
        query: '',
        walletId: 'wallet-digital',
      ).first;
      expect(digitalTxs.length, 2);
      expect(digitalTxs.any((t) => t.type == TxType.transfer), isTrue);

      // Filter categoryId
      final funOnly = await db.watchSearchTransactions(
        query: '',
        categoryId: 'cat-exp-fun',
      ).first;
      expect(funOnly.length, 1);
      expect(funOnly.first.note, 'Tiket bioskop');

      // Filter needWant
      final wantsOnly = await db.watchSearchTransactions(
        query: '',
        needWant: NeedWant.want,
      ).first;
      expect(wantsOnly.length, 1);
      expect(wantsOnly.first.amount, 45000);

      // Pencarian memakai matchedCategoryIds (misal hasil padanan bahasa Indonesia 'Makanan')
      final localizedFood = await db.watchSearchTransactions(
        query: 'makanan',
        matchedCategoryIds: ['cat-exp-food'],
      ).first;
      expect(localizedFood.length, 1);
      expect(localizedFood.first.note, 'Bakso Malang');

      // Uji batas hasil >100 (default baru limit = 250)
      for (var i = 0; i < 125; i++) {
        await db.addTransaction(
          amount: 1000 + i,
          type: TxType.expense,
          categoryId: 'cat-exp-other',
          walletId: 'wallet-cash',
          date: baseDate.subtract(Duration(minutes: i + 1)),
          note: 'Batch row #$i',
        );
      }
      final batchResults = await db.watchSearchTransactions(query: 'Batch row').first;
      expect(batchResults.length, 125);
    });

    test('Recurring lifecycle: queue pending -> edit/confirm/skip -> update/recordNow/skipNextDue/undo & upcoming calc', () async {
      final today = DateTime(2026, 11, 12, 9, 0);
      final dueYesterday = DateTime(2026, 11, 11);

      // 1. Buat aturan expense yang sudah jatuh tempo & aturan transfer
      await db.addRecurringRule(
        title: 'Tagihan Internet',
        amount: 350000,
        type: TxType.expense,
        categoryId: 'cat-exp-housing',
        walletId: 'wallet-main',
        frequency: RecurFrequency.monthly,
        dayOfMonth: 11,
        startDate: dueYesterday,
        nextDueDate: dueYesterday,
        note: 'WiFi rumah',
      );

      await db.addRecurringRule(
        title: 'Sisihkan Tabungan',
        amount: 500000,
        type: TxType.transfer,
        categoryId: 'cat-tra-transfer',
        walletId: 'wallet-main',
        toWalletId: 'wallet-digital',
        frequency: RecurFrequency.weekly,
        dayOfWeek: DateTime.friday,
        startDate: dueYesterday,
        nextDueDate: dueYesterday,
      );

      // 2. checkAndGenerateDue memindahkan jadwal jatuh tempo ke antrean pending tanpa menulis transaksi resmi dulu
      final generated = await RecurringService.checkAndGenerateDue(db, now: today);
      expect(generated, 2);
      expect(await db.allActiveTransactions(), isEmpty);

      final pendingList = await db.getPendingTransactions();
      expect(pendingList.length, 2);

      final internetPending = pendingList.firstWhere((p) => p.title == 'Tagihan Internet');
      final transferPending = pendingList.firstWhere((p) => p.title == 'Sisihkan Tabungan');

      // 3. calculateUpcomingExpense menghitung tagihan pending expense sebelum akhir periode
      final period = Period(PeriodType.monthly, DateTime(2026, 11, 1));
      final upcomingWithPending = RecurringService.calculateUpcomingExpense(
        await db.watchRecurringRules().first,
        period,
        pending: pendingList,
        now: today,
      );
      // Tagihan pending 350rb ada di November; jadwal rule berikutnya sudah maju ke Desember
      expect(upcomingWithPending, 350000);

      // 4. Konfirmasi pending dengan penyesuaian nominal (override)
      final confirmed = await db.confirmPendingTransaction(
        internetPending.id,
        amountOverride: 375000,
        noteOverride: 'WiFi + addon',
      );
      expect(confirmed, isNotNull);
      expect(confirmed!.amount, 375000);
      expect(confirmed.note, 'WiFi + addon');

      // 5. Skip pending lalu Undo (restorePendingTransaction), kemudian konfirmasi transfer
      await db.dismissPendingTransaction(transferPending.id);
      expect(await db.getPendingTransactions(), isEmpty);

      await db.restorePendingTransaction(transferPending.id);
      expect((await db.getPendingTransactions()).length, 1);

      final confirmedTransfer = await db.confirmPendingTransaction(transferPending.id);
      expect(confirmedTransfer, isNotNull);
      expect(confirmedTransfer!.type, TxType.transfer);
      expect(confirmedTransfer.categoryId, 'cat-tra-transfer');
      expect(confirmedTransfer.toWalletId, 'wallet-digital');

      // Verifikasi arus bersih dompet pasca konfirmasi (wallet-main: -375rb -500rb = -875rb, digital: +500rb)
      final netFlows = await db.watchWalletNetFlows().first;
      expect(netFlows['wallet-main'], -875000);
      expect(netFlows['wallet-digital'], 500000);

      // 6. Edit schedule + Record now + Skip next due (clamping 31 Jan -> 28 Feb) + Delete/Undo
      final rules = await db.watchRecurringRules().first;
      final internetRule = rules.firstWhere((r) => r.title == 'Tagihan Internet');
      await db.updateRecurringRule(
        internetRule.id,
        title: 'WiFi Fiber',
        amount: 400000,
        type: TxType.expense,
        categoryId: 'cat-exp-housing',
        walletId: 'wallet-digital',
        frequency: RecurFrequency.monthly,
        dayOfMonth: 31,
        nextDueDate: DateTime(2026, 1, 31),
        note: 'Paket baru',
      );

      final updatedRule = (await db.watchRecurringRules().first)
          .firstWhere((r) => r.id == internetRule.id);
      expect(updatedRule.title, 'WiFi Fiber');
      expect(updatedRule.amount, 400000);

      final skippedTo = await RecurringService.skipNextDueDate(
        db,
        updatedRule,
        now: DateTime(2026, 1, 31),
      );
      expect(skippedTo, DateTime(2026, 2, 28));

      final ruleAfterSkip = (await db.watchRecurringRules().first)
          .firstWhere((r) => r.id == internetRule.id);
      final recordedNext = await RecurringService.recordRuleNow(
        db,
        ruleAfterSkip,
        now: DateTime(2026, 2, 28),
      );
      expect(recordedNext, DateTime(2026, 3, 31));

      final allTxs = await db.allActiveTransactions();
      expect(allTxs.length, 3);

      // Soft delete & Undo restore rule
      await db.deleteRecurringRule(internetRule.id);
      expect((await db.watchRecurringRules().first).length, 1);
      await db.restoreRecurringRule(internetRule.id);
      expect((await db.watchRecurringRules().first).length, 2);
    });

    test('DebtPayment history: atomic recordDebtPayment, deleteDebtPayment rollback, restoreDebtPayment undo, and clamp check', () async {
      await db.addDebt(
        person: 'Sinta',
        direction: DebtDirection.lent,
        amount: 300000,
        note: 'Patungan hotel',
      );
      final debt = (await db.watchDebts().first).first;

      // Cicilan 1 terhubung ke dompet wallet-digital (+100rb income)
      await db.recordDebtPayment(
        debtId: debt.id,
        amount: 100000,
        createWalletTransaction: true,
        walletId: 'wallet-digital',
        transactionNote: 'Repayment from Sinta',
        paymentNote: 'Cicilan 1',
      );

      // Cicilan 2 tanpa mencatat ke dompet (catatan saja) + melebihi sisa -> terclamp ke sisa 200rb
      await db.addDebtPayment(debt.id, 500000, note: 'Pelunasan tunai');

      var liveDebt = (await db.watchDebts().first).first;
      expect(liveDebt.paidAmount, 300000);

      var payments = await db.watchDebtPayments(debt.id).first;
      expect(payments.length, 2);
      var netFlows = await db.watchWalletNetFlows().first;
      expect(netFlows['wallet-digital'], 100000);

      // Hapus cicilan pertama -> paidAmount berkurang 100rb dan transaksi dompet ikut terhapus
      final linkedPayment = payments.firstWhere((p) => p.transactionId != null);
      await db.deleteDebtPayment(linkedPayment.id);

      liveDebt = (await db.watchDebts().first).first;
      expect(liveDebt.paidAmount, 200000);
      payments = await db.watchDebtPayments(debt.id).first;
      expect(payments.length, 1);
      netFlows = await db.watchWalletNetFlows().first;
      expect(netFlows['wallet-digital'] ?? 0, 0);

      // Undo hapus cicilan -> paidAmount kembali 300rb dan transaksi dompet pulih
      await db.restoreDebtPayment(linkedPayment.id);
      liveDebt = (await db.watchDebts().first).first;
      expect(liveDebt.paidAmount, 300000);
      payments = await db.watchDebtPayments(debt.id).first;
      expect(payments.length, 2);
      netFlows = await db.watchWalletNetFlows().first;
      expect(netFlows['wallet-digital'], 100000);
    });

    test('Backup round-trip preserves debtPayments & pendingTransactions and ignores legacy remote pending docs', () async {
      await db.addDebt(
        person: 'Andi',
        direction: DebtDirection.borrowed,
        amount: 200000,
      );
      final debt = (await db.watchDebts().first).first;
      await db.recordDebtPayment(
        debtId: debt.id,
        amount: 50000,
        createWalletTransaction: false,
      );
      await db.addPendingTransaction(
        title: 'Listrik PLN',
        amount: 150000,
        type: TxType.expense,
        categoryId: 'cat-exp-housing',
        walletId: 'wallet-main',
        dueDate: DateTime(2026, 11, 20),
      );

      final backup = await db.exportBackup();
      expect((backup['debtPayments'] as List).length, 1);
      expect((backup['pendingTransactions'] as List).length, 1);

      final restoreDb = AppDatabase(NativeDatabase.memory());
      addTearDown(restoreDb.close);
      final applied = await restoreDb.importBackup(backup);
      expect(applied, greaterThanOrEqualTo(3));

      final restoredPayments = await restoreDb.watchDebtPayments(debt.id).first;
      expect(restoredPayments.length, 1);
      expect(restoredPayments.first.amount, 50000);

      final restoredPending = await restoreDb.getPendingTransactions();
      expect(restoredPending.length, 1);
      expect(restoredPending.first.title, 'Listrik PLN');

      // Uji toleransi syncTables terhadap dokumen remote pending_transactions format lawas
      final pendingSync = restoreDb.syncTables.firstWhere((s) => s.name == 'pendingTransactions');
      final legacyApplied = await pendingSync.applyRemote({
        'id': 'legacy-doc-1',
        'body': 'Old v1.11 notification body',
      });
      expect(legacyApplied, isFalse);
    });

    test('Localization provides complete EN and ID translations for Phase 2 UI strings', () {
      final en = AppStrings('en');
      final id = AppStrings('id');

      const keys = [
        'Clear search',
        'Filter by Need / Want',
        'All Needs & Wants',
        'Need / Want',
        'Searching across all dates',
        'Active Schedules',
        'Est. monthly bills',
        'Pending Confirmation ({count})',
        'Record now',
        'Skip next due',
        'Confirm & Record',
        'Edit Recurring Schedule',
        'No receivables recorded yet',
        'No debts recorded yet',
        'Payment History',
        'Delete payment',
        'No active goals yet.',
        '1 recurring item ready to confirm',
        '{count} recurring items ready to confirm',
        'Review',
      ];

      for (final key in keys) {
        expect(en.tr(key, {'count': 3}), isNotEmpty);
        final translated = id.tr(key, {'count': 3});
        expect(translated, isNot(equals(key.replaceAll('{count}', '3'))), reason: 'Missing ID translation for "$key"');
      }
    });
  });
}
