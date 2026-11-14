import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/data/app_database.dart';
import 'package:wall_o_pay/data/cloud_sync.dart';
import 'package:wall_o_pay/data/lock.dart';
import 'package:wall_o_pay/data/prefs.dart';
import 'package:wall_o_pay/data/providers.dart';
import 'package:wall_o_pay/data/recurring_service.dart';
import 'package:wall_o_pay/data/tables.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Batch 2 — Recurring & Cloud Synchronization Stability Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'RecurringService.checkAndGenerateDue coalesces concurrent calls and creates zero duplicates',
      () async {
        final today = DateTime(2026, 11, 15, 9, 0);
        final dueDate = DateTime(2026, 11, 14);

        await db.addRecurringRule(
          title: 'Internet Bulanan',
          amount: 350000,
          type: TxType.expense,
          categoryId: 'cat-exp-housing',
          walletId: 'wallet-main',
          frequency: RecurFrequency.monthly,
          dayOfMonth: 14,
          startDate: dueDate,
          nextDueDate: dueDate,
        );

        final results = await Future.wait([
          RecurringService.checkAndGenerateDue(db, now: today),
          RecurringService.checkAndGenerateDue(db, now: today),
          RecurringService.checkAndGenerateDue(db, now: today),
        ]);

        // Coalesced in-flight calls return the same Future (each observes 1 generated)
        expect(results, [1, 1, 1]);

        final pending = await db.getPendingTransactions();
        expect(pending.length, 1);
        expect(pending.single.title, 'Internet Bulanan');

        // Pemanggilan ulang sesudah jadwal maju tidak menghasilkan duplikat
        final secondRun = await RecurringService.checkAndGenerateDue(db, now: today);
        expect(secondRun, 0);
        expect((await db.getPendingTransactions()).length, 1);
      },
    );

    test(
      'RecurringService.checkAndGenerateDue stays idempotent if active PendingTransaction already exists for dueDate',
      () async {
        final today = DateTime(2026, 11, 15, 9, 0);
        final dueDate = DateTime(2026, 11, 14);

        await db.addRecurringRule(
          title: 'Sewa Kos',
          amount: 1500000,
          type: TxType.expense,
          categoryId: 'cat-exp-housing',
          walletId: 'wallet-main',
          frequency: RecurFrequency.monthly,
          dayOfMonth: 14,
          startDate: dueDate,
          nextDueDate: dueDate,
        );
        final ruleId = (await db.watchRecurringRules().first).single.id;

        // Simulasikan pending transaction sudah ada terlebih dahulu (mis. dari cloud pull)
        await db.into(db.pendingTransactions).insert(
              PendingTransactionsCompanion.insert(
                recurringRuleId: Value(ruleId),
                title: 'Sewa Kos',
                amount: 1500000,
                type: TxType.expense,
                categoryId: 'cat-exp-housing',
                walletId: const Value('wallet-main'),
                dueDate: dueDate,
              ),
            );

        final generated = await RecurringService.checkAndGenerateDue(db, now: today);
        expect(generated, 0);

        final pending = await db.getPendingTransactions();
        expect(pending.length, 1);

        // Jadwal rule tetap dimajukan ke bulan berikutnya
        final rule = await (db.select(db.recurringRules)
              ..where((r) => r.id.equals(ruleId)))
            .getSingle();
        expect(rule.nextDueDate.isAfter(dueDate), isTrue);
      },
    );

    test(
      'AutoSyncService.startSync coalesces same-UID calls, isolates account switch via resetAllData, and stops cleanly',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await Lock.instance.load();

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(db),
          ],
        );
        addTearDown(container.dispose);

        final sync = container.read(autoSyncServiceProvider);

        // Concurrent startSync untuk UID yang sama tidak boleh saling menimpa
        await Future.wait([
          sync.startSync('uid-alpha'),
          sync.startSync('uid-alpha'),
        ]);
        expect(prefs.getString('current_sync_user_id'), 'uid-alpha');

        // Tambah transaksi lokal milik uid-alpha
        await db.addTransaction(
          amount: 120000,
          type: TxType.expense,
          categoryId: 'cat-exp-food',
          date: DateTime(2026, 11, 15),
          note: 'Alpha Coffee',
        );
        expect((await db.allActiveTransactions()).length, 1);

        // Pergantian akun uid-alpha -> uid-beta mereset DB lokal agar data akun tidak tercampur
        await sync.startSync('uid-beta');
        expect(prefs.getString('current_sync_user_id'), 'uid-beta');
        expect(await db.allActiveTransactions(), isEmpty);

        // Stop sync harus membersihkan sesi dengan aman
        sync.stopSync();
        await sync.triggerTwoWaySync();
        expect(container.read(syncStateProvider).status, SyncStatus.idle);
      },
    );

    test(
      'AutoSyncService handles concurrent UID switch and discardGuestDataOnNextLogin cleanly',
      () async {
        SharedPreferences.setMockInitialValues({
          'onboarding_done_local': true,
        });
        final prefs = await SharedPreferences.getInstance();
        await Lock.instance.load();

        await db.addTransaction(
          amount: 50000,
          type: TxType.expense,
          categoryId: 'cat-exp-food',
          date: DateTime(2026, 11, 15),
          note: 'Guest Snack',
        );
        expect((await db.allActiveTransactions()).length, 1);

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(db),
          ],
        );
        addTearDown(container.dispose);

        final sync = container.read(autoSyncServiceProvider);
        sync.discardGuestDataOnNextLogin = true;

        // Pergantian UID berurutan/paralel (uid-one lalu uid-two) harus berakhir konsisten di uid-two
        await Future.wait([
          sync.startSync('uid-one'),
          sync.startSync('uid-two'),
        ]);

        expect(prefs.getString('current_sync_user_id'), 'uid-two');
        expect(prefs.getBool('onboarding_done_local'), isNull);
        expect(await db.allActiveTransactions(), isEmpty);
      },
    );
  });
}
