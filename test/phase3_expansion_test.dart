import 'package:drift/native.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/core/period.dart';
import 'package:wall_o_pay/data/app_database.dart';
import 'package:wall_o_pay/data/cloud_sync.dart';
import 'package:wall_o_pay/data/export_service.dart';
import 'package:wall_o_pay/data/module_prefs.dart';
import 'package:wall_o_pay/data/prefs.dart';
import 'package:wall_o_pay/data/report_service.dart';
import 'package:wall_o_pay/data/tables.dart';
import 'package:wall_o_pay/features/debts/debts_page.dart';
import 'package:wall_o_pay/features/insights/insight_engine.dart';
import 'package:wall_o_pay/features/insights/insights_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3 Feature Expansion Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Paket 3A: computeRecap calculates monthly & weekly recaps accurately', () async {
      final cats = {for (final c in await db.allCategories()) c.id: c};
      await db.addSavingsGoal('Dana Darurat', 1000000);
      final goals = await db.watchSavingsGoals().first;
      await db.addToSavings(goals.first.id, 400000);
      final updatedGoals = await db.watchSavingsGoals().first;

      final octPeriod = Period(PeriodType.monthly, DateTime(2026, 10, 1));
      final sepPeriod = Period(PeriodType.monthly, DateTime(2026, 9, 1));

      await db.addTransaction(
        amount: 5000000,
        type: TxType.income,
        categoryId: 'cat-inc-parttime',
        date: DateTime(2026, 10, 2),
        note: 'Gaji Oktober',
      );
      await db.addTransaction(
        amount: 1200000,
        type: TxType.expense,
        categoryId: 'cat-exp-food',
        date: DateTime(2026, 10, 5),
        needWant: NeedWant.need,
        note: 'Belanja makan',
      );
      await db.addTransaction(
        amount: 400000,
        type: TxType.expense,
        categoryId: 'cat-exp-fun',
        date: DateTime(2026, 10, 10),
        needWant: NeedWant.want,
        note: 'Nonton bioskop',
      );
      // Prior month expenses: food 1.600.000 (saved 400k), fun 150.000 (surged +250k)
      await db.addTransaction(
        amount: 1600000,
        type: TxType.expense,
        categoryId: 'cat-exp-food',
        date: DateTime(2026, 9, 8),
        note: 'Makan Sep',
      );
      await db.addTransaction(
        amount: 150000,
        type: TxType.expense,
        categoryId: 'cat-exp-fun',
        date: DateTime(2026, 9, 12),
        note: 'Hiburan Sep',
      );

      final all = await db.allActiveTransactions();
      final octTxs = all.where((t) => octPeriod.contains(t.date)).toList();
      final sepTxs = all.where((t) => sepPeriod.contains(t.date)).toList();

      final monthlyRecap = InsightEngine.computeRecap(
        completedPeriod: octPeriod,
        completedTxs: octTxs,
        priorTxs: sepTxs,
        categoryMap: cats,
        goals: updatedGoals,
      );

      expect(monthlyRecap.isWeekly, isFalse);
      expect(monthlyRecap.totalIncome, 5000000);
      expect(monthlyRecap.totalExpense, 1600000);
      expect(monthlyRecap.netSavings, 3400000);
      expect(monthlyRecap.savingsRate, closeTo(68.0, 0.01));
      expect(monthlyRecap.needTotal, 1200000);
      expect(monthlyRecap.wantTotal, 400000);
      expect(monthlyRecap.topCategories.length, 2);
      expect(monthlyRecap.topCategories.first.categoryId, 'cat-exp-food');
      expect(monthlyRecap.topSavingCategory?.categoryId, 'cat-exp-food');
      expect(monthlyRecap.topSavingCategory?.diffAmount, 400000);
      expect(monthlyRecap.topSurgeCategory?.categoryId, 'cat-exp-fun');
      expect(monthlyRecap.topSurgeCategory?.diffAmount, 250000);
      expect(monthlyRecap.activeGoalsCount, 1);
      expect(monthlyRecap.goalsSavedTotal, 400000);
      expect(monthlyRecap.goalsTargetTotal, 1000000);

      // Weekly recap check (deficit period)
      final weeklyPeriod = Period(PeriodType.weekly, DateTime(2026, 11, 2));
      await db.addTransaction(
        amount: 100000,
        type: TxType.income,
        categoryId: 'cat-inc-other',
        date: DateTime(2026, 11, 3),
      );
      await db.addTransaction(
        amount: 250000,
        type: TxType.expense,
        categoryId: 'cat-exp-transport',
        date: DateTime(2026, 11, 4),
      );
      final weekTxs = (await db.allActiveTransactions())
          .where((t) => weeklyPeriod.contains(t.date))
          .toList();
      final weeklyRecap = InsightEngine.computeRecap(
        completedPeriod: weeklyPeriod,
        completedTxs: weekTxs,
        priorTxs: const [],
        categoryMap: cats,
      );
      expect(weeklyRecap.isWeekly, isTrue);
      expect(weeklyRecap.isDeficit, isTrue);
      expect(weeklyRecap.netSavings, -150000);
      expect(weeklyRecap.savingsRate, 0.0);
    });

    test('Paket 3A: filterCategoryDrillDownTransactions filters & sorts newest first', () async {
      await db.addTransaction(
        amount: 25000,
        type: TxType.expense,
        categoryId: 'cat-exp-food',
        date: DateTime(2026, 11, 1),
        note: 'Hari 1',
      );
      await db.addTransaction(
        amount: 45000,
        type: TxType.expense,
        categoryId: 'cat-exp-food',
        date: DateTime(2026, 11, 5),
        note: 'Hari 5',
      );
      await db.addTransaction(
        amount: 80000,
        type: TxType.expense,
        categoryId: 'cat-exp-transport',
        date: DateTime(2026, 11, 6),
        note: 'Transport',
      );

      final all = await db.allActiveTransactions();
      final foodOnly = filterCategoryDrillDownTransactions(
        transactions: all,
        categoryId: 'cat-exp-food',
      );
      expect(foodOnly.length, 2);
      expect(foodOnly.first.note, 'Hari 5');
      expect(foodOnly.last.note, 'Hari 1');
    });

    test('Paket 3B: CSV export filters by wallet & range and escapes enriched columns', () async {
      await db.addWallet(name: 'BCA', type: 'bank', initialBalance: 1000000);
      final wallets = await db.watchWallets().first;
      final mainId = wallets.first.id;
      final bcaId = wallets.last.id;
      final cats = {for (final c in await db.allCategories()) c.id: c};
      final walletMap = {for (final w in wallets) w.id: w};

      await db.addTransaction(
        amount: 50000,
        type: TxType.expense,
        categoryId: 'cat-exp-food',
        walletId: mainId,
        date: DateTime(2026, 11, 2),
        needWant: NeedWant.need,
        note: 'Nasi "Goreng", Pedas',
      );
      await db.transferBetweenWallets(
        amount: 200000,
        fromWalletId: mainId,
        toWalletId: bcaId,
        date: DateTime(2026, 11, 4),
        note: 'Topup BCA',
      );
      await db.addTransaction(
        amount: 30000,
        type: TxType.expense,
        categoryId: 'cat-exp-fun',
        walletId: mainId,
        date: DateTime(2026, 10, 20),
        note: 'Bulan lalu',
      );

      final allRows = await db.allActiveTransactions();

      // Wallet filter helper matches transfers to destination wallet too
      final bcaRows = ReportService.filterTransactionsByWallet(allRows, bcaId);
      expect(bcaRows.length, 1);
      expect(bcaRows.first.type, TxType.transfer);

      // Build CSV for Nov 1..10 filtered to bcaId
      final csv = ExportService.buildCsvContent(
        rows: allRows,
        categories: cats,
        wallets: walletMap,
        range: DateTimeRange(
          start: DateTime(2026, 11, 1),
          end: DateTime(2026, 11, 10),
        ),
        walletId: bcaId,
      );

      expect(csv, startsWith('\uFEFFDate,Type,Category,Wallet,ToWallet,NeedWant,Amount,Note'));
      expect(csv, contains('2026-11-04,Transfer,'));
      expect(csv, contains('"BCA"'));
      expect(csv, isNot(contains('Nasi')));
      expect(csv, isNot(contains('Bulan lalu')));

      // Unfiltered CSV escapes quotes inside Note
      final fullCsv = ExportService.buildCsvContent(
        rows: allRows,
        categories: cats,
        wallets: walletMap,
      );
      expect(fullCsv, contains('"Nasi ""Goreng"", Pedas"'));
      expect(fullCsv, contains(',Need,50000,'));
    });

    test('Paket 3B: Guest JSON backup nudge follows txCount & 14-day threshold', () {
      final now = DateTime(2026, 11, 12, 12);
      final recentMs = now.subtract(const Duration(days: 5)).millisecondsSinceEpoch;
      final staleMs = now.subtract(const Duration(days: 15)).millisecondsSinceEpoch;

      expect(
        ExportService.shouldShowGuestBackupNudge(
          isGuest: false,
          txCount: 25,
          lastBackupMs: null,
          now: now,
        ),
        isFalse,
      );
      expect(
        ExportService.shouldShowGuestBackupNudge(
          isGuest: true,
          txCount: 9,
          lastBackupMs: null,
          now: now,
        ),
        isFalse,
      );
      expect(
        ExportService.shouldShowGuestBackupNudge(
          isGuest: true,
          txCount: 10,
          lastBackupMs: null,
          now: now,
        ),
        isTrue,
      );
      expect(
        ExportService.shouldShowGuestBackupNudge(
          isGuest: true,
          txCount: 20,
          lastBackupMs: recentMs,
          now: now,
        ),
        isFalse,
      );
      expect(
        ExportService.shouldShowGuestBackupNudge(
          isGuest: true,
          txCount: 20,
          lastBackupMs: staleMs,
          now: now,
        ),
        isTrue,
      );
      expect(
        ExportService.shouldShowGuestBackupNudge(
          isGuest: true,
          txCount: 20,
          lastBackupMs: staleMs,
          dismissedAtMs: recentMs,
          now: now,
        ),
        isFalse,
      );
    });

    test('Paket 3C: computeCustomSplit validates unequal shares & edge cases', () {
      final ok = computeCustomSplit(
        total: 150000,
        friendAmounts: [40000, 65000],
      );
      expect(ok.isValid, isTrue);
      expect(ok.friendsTotal, 105000);
      expect(ok.myShare, 45000);

      final fullCoveredByFriends = computeCustomSplit(
        total: 100000,
        friendAmounts: [50000, 50000],
      );
      expect(fullCoveredByFriends.isValid, isTrue);
      expect(fullCoveredByFriends.myShare, 0);

      final zeroShare = computeCustomSplit(
        total: 100000,
        friendAmounts: [60000, 0],
      );
      expect(zeroShare.isValid, isFalse);
      expect(zeroShare.errorKey, "Every friend's share must be greater than 0.");

      final overTotal = computeCustomSplit(
        total: 100000,
        friendAmounts: [70000, 50000],
      );
      expect(overTotal.isValid, isFalse);
      expect(overTotal.errorKey, "Friends' total exceeds the bill total.");
    });

    test('Paket 3C: ModulePrefsController persists toggles & minimalist preset', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(modulePrefsProvider).activeCount, 5);
      await container.read(modulePrefsProvider.notifier).setModule('budget', false);
      expect(container.read(modulePrefsProvider).budget, isFalse);
      expect(container.read(modulePrefsProvider).activeCount, 4);

      await container.read(modulePrefsProvider.notifier).setAll(
            goals: false,
            debts: false,
            recurring: false,
            transfer: false,
            budget: false,
          );
      expect(container.read(modulePrefsProvider).activeCount, 0);

      // Re-reading from a fresh container restores persisted SharedPreferences state
      final restoredContainer = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(restoredContainer.dispose);
      expect(restoredContainer.read(modulePrefsProvider).activeCount, 0);
      expect(restoredContainer.read(modulePrefsProvider).budget, isFalse);
    });

    test('Paket 3D: AutoSyncService incremental cursor helpers & clearPullCursor', () async {
      SharedPreferences.setMockInitialValues({
        AutoSyncService.pullCursorKey('user-1'): 500000,
      });
      final prefs = await SharedPreferences.getInstance();

      expect(AutoSyncService.computeIncrementalPullSinceMs(null), isNull);
      expect(AutoSyncService.computeIncrementalPullSinceMs(0), isNull);
      expect(
        AutoSyncService.computeIncrementalPullSinceMs(500000, overlapMs: 30000),
        470000,
      );
      expect(
        AutoSyncService.computeIncrementalPullSinceMs(10000, overlapMs: 30000),
        0,
      );

      final next = AutoSyncService.computeNextPullCursorMs(
        previousCursorMs: 500000,
        pulledUpdatedAtMs: [510000, 625000],
        syncStartedMs: 600000,
      );
      expect(next, 625000);

      final nonRegressing = AutoSyncService.computeNextPullCursorMs(
        previousCursorMs: 700000,
        pulledUpdatedAtMs: const [],
        syncStartedMs: 650000,
      );
      expect(nonRegressing, 700000);

      await AutoSyncService.clearPullCursor(prefs, 'user-1');
      expect(prefs.getInt(AutoSyncService.pullCursorKey('user-1')), isNull);
    });

    test('Phase 3 EN/ID l10n strings exist without falling back', () {
      final en = AppStrings('en');
      final id = AppStrings('id');

      expect(en.tr('Financial Recap'), 'Financial Recap');
      expect(id.tr('Financial Recap'), 'Rekap Keuangan');
      expect(en.tr('Weekly Recap'), 'Weekly Recap');
      expect(id.tr('Weekly Recap'), 'Rekap Mingguan');
      expect(en.tr('Monthly Recap'), 'Monthly Recap');
      expect(id.tr('Monthly Recap'), 'Rekap Bulanan');
      expect(en.tr('Custom Split'), 'Custom Split');
      expect(id.tr('Custom Split'), 'Nominal Kustom');
      expect(en.tr('Export PDF'), 'Export PDF');
      expect(id.tr('Export PDF'), 'Ekspor PDF');
    });
  });
}
