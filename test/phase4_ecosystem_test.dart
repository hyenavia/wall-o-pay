import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/core/period.dart';
import 'package:wall_o_pay/data/app_database.dart';
import 'package:wall_o_pay/data/feature_prefs.dart';
import 'package:wall_o_pay/data/notifications.dart';
import 'package:wall_o_pay/data/prefs.dart';
import 'package:wall_o_pay/data/tables.dart';
import 'package:wall_o_pay/features/goals/goals_page.dart';
import 'package:wall_o_pay/features/insights/insight_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 4 Advanced Ecosystem Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Paket 4A: computeNetWorth calculates liquid + receivables - liabilities without double counting goals', () async {
      await db.addDebt(
        person: 'Rani',
        direction: DebtDirection.lent,
        amount: 500000,
      );
      await db.addDebt(
        person: 'Budi',
        direction: DebtDirection.borrowed,
        amount: 300000,
      );
      final debts = await db.watchDebts().first;
      final rani = debts.firstWhere((d) => d.person == 'Rani');
      await db.addDebtPayment(rani.id, 100000);

      await db.addSavingsGoal('Emergency Fund', 5000000);
      final goals = await db.watchSavingsGoals().first;
      await db.addToSavings(goals.first.id, 1200000);

      final updatedDebts = await db.watchDebts().first;
      final updatedGoals = await db.watchSavingsGoals().first;

      final nw = InsightEngine.computeNetWorth(
        liquidAssets: 2500000,
        debts: updatedDebts,
        goals: updatedGoals,
      );

      // Liquid 2.5M + Receivables 400k (500k - 100k) - Liabilities 300k = 2.6M
      expect(nw.liquidAssets, 2500000);
      expect(nw.receivables, 400000);
      expect(nw.liabilities, 300000);
      expect(nw.netWorth, 2600000);
      expect(nw.allocatedGoalReserve, 1200000);
    });

    test('Paket 4A: computeVitalityScore handles starter, thriving, partial, and fragile profiles', () {
      const emptySummary = InsightSummary(
        totalIncome: 0,
        totalExpense: 0,
        netBalance: 0,
        savingsRate: 0,
        prevTotalIncome: 0,
        prevTotalExpense: 0,
        expenseDiff: 0,
        expensePctChange: null,
        txCount: 0,
        expenseTxCount: 0,
      );
      const emptyNw = NetWorthSummary(
        liquidAssets: 0,
        receivables: 0,
        liabilities: 0,
        allocatedGoalReserve: 0,
      );
      final starter = InsightEngine.computeVitalityScore(
        summary: emptySummary,
        netWorth: emptyNw,
        budgets: const {},
        spentByCategory: const {},
        needTotal: 0,
        wantTotal: 0,
      );
      expect(starter.hasEnoughData, isFalse);
      expect(starter.tier, VitalityTier.starter);
      expect(starter.activePillarCount, 0);

      // Thriving across all 4 pillars
      const thrivingSummary = InsightSummary(
        totalIncome: 10000000,
        totalExpense: 6000000,
        netBalance: 4000000,
        savingsRate: 40.0,
        prevTotalIncome: 10000000,
        prevTotalExpense: 6500000,
        expenseDiff: -500000,
        expensePctChange: -7.7,
        txCount: 15,
        expenseTxCount: 12,
      );
      const thrivingNw = NetWorthSummary(
        liquidAssets: 10000000,
        receivables: 0,
        liabilities: 2000000,
        allocatedGoalReserve: 3000000,
      );
      final thriving = InsightEngine.computeVitalityScore(
        summary: thrivingSummary,
        netWorth: thrivingNw,
        budgets: const {'cat-exp-food': 2000000, 'cat-exp-fun': 1000000},
        spentByCategory: const {'cat-exp-food': 1500000, 'cat-exp-fun': 800000},
        needTotal: 4500000,
        wantTotal: 1500000,
      );
      expect(thriving.hasEnoughData, isTrue);
      expect(thriving.activePillarCount, 4);
      expect(thriving.score, 100);
      expect(thriving.tier, VitalityTier.thriving);

      // Partial setup (no budgets, no need/want tags): still normalizes cleanly
      final partial = InsightEngine.computeVitalityScore(
        summary: thrivingSummary,
        netWorth: thrivingNw,
        budgets: const {},
        spentByCategory: const {},
        needTotal: 0,
        wantTotal: 0,
      );
      expect(partial.activePillarCount, 2);
      expect(partial.score, 100);

      // Fragile profile (deficit, overspent budget, 80% wants, debt > liquid)
      const fragileSummary = InsightSummary(
        totalIncome: 3000000,
        totalExpense: 4500000,
        netBalance: -1500000,
        savingsRate: 0.0,
        prevTotalIncome: 3000000,
        prevTotalExpense: 3000000,
        expenseDiff: 1500000,
        expensePctChange: 50.0,
        txCount: 8,
        expenseTxCount: 7,
      );
      const fragileNw = NetWorthSummary(
        liquidAssets: 500000,
        receivables: 0,
        liabilities: 5000000,
        allocatedGoalReserve: 0,
      );
      final fragile = InsightEngine.computeVitalityScore(
        summary: fragileSummary,
        netWorth: fragileNw,
        budgets: const {'cat-exp-fun': 500000},
        spentByCategory: const {'cat-exp-fun': 1500000},
        needTotal: 1000000,
        wantTotal: 3500000,
      );
      expect(fragile.tier, VitalityTier.fragile);
      expect(fragile.score, lessThan(40));
    });

    test('Paket 4B: computeGoalPace computes monthly, weekly, onTrack, behindSchedule, dueToday, and overdue', () {
      final baseCreated = DateTime(2026, 1, 1);
      final midNow = DateTime(2026, 2, 1); // ~31 days elapsed out of 90 (~34% elapsed)

      SavingsGoal makeGoal({
        required int current,
        required int target,
        DateTime? targetDate,
      }) =>
          SavingsGoal(
            id: 'g1',
            name: 'Laptop',
            targetAmount: target,
            currentAmount: current,
            targetDate: targetDate,
            createdAt: baseCreated,
            updatedAt: baseCreated,
            deletedAt: null,
          );

      // No target date -> null
      expect(
        computeGoalPace(makeGoal(current: 100000, target: 1000000), PeriodType.monthly, now: midNow),
        isNull,
      );

      // Already completed -> null
      expect(
        computeGoalPace(
          makeGoal(current: 1000000, target: 1000000, targetDate: DateTime(2026, 4, 1)),
          PeriodType.monthly,
          now: midNow,
        ),
        isNull,
      );

      // On track (50% saved vs ~34% elapsed), 59 days remaining -> ceil(59/30)=2 months, ceil(59/7)=9 weeks
      final onTrackGoal = makeGoal(
        current: 5000000,
        target: 10000000,
        targetDate: DateTime(2026, 4, 1),
      );
      final monthlyPace = computeGoalPace(onTrackGoal, PeriodType.monthly, now: midNow)!;
      expect(monthlyPace.status, GoalPaceStatus.onTrack);
      expect(monthlyPace.periodsLeft, 2);
      expect(monthlyPace.recommendedPerPeriod, 2500000);

      final weeklyPace = computeGoalPace(onTrackGoal, PeriodType.weekly, now: midNow)!;
      expect(weeklyPace.periodsLeft, 9);
      expect(weeklyPace.recommendedPerPeriod, (5000000 / 9).ceil());

      // Behind schedule (10% saved vs ~34% elapsed)
      final behindGoal = makeGoal(
        current: 1000000,
        target: 10000000,
        targetDate: DateTime(2026, 4, 1),
      );
      final behindPace = computeGoalPace(behindGoal, PeriodType.monthly, now: midNow)!;
      expect(behindPace.status, GoalPaceStatus.behindSchedule);

      // Due today
      final dueTodayPace = computeGoalPace(
        makeGoal(current: 600000, target: 1000000, targetDate: midNow),
        PeriodType.monthly,
        now: midNow,
      )!;
      expect(dueTodayPace.status, GoalPaceStatus.dueToday);
      expect(dueTodayPace.recommendedPerPeriod, 400000);

      // Overdue
      final overduePace = computeGoalPace(
        makeGoal(
          current: 600000,
          target: 1000000,
          targetDate: DateTime(2026, 1, 20),
        ),
        PeriodType.monthly,
        now: midNow,
      )!;
      expect(overduePace.status, GoalPaceStatus.overdue);
      expect(overduePace.recommendedPerPeriod, 400000);
    });

    test('Paket 4C: shouldSendRecapNotification and FeaturePrefs recapAlerts behave reliably', () async {
      expect(
        shouldSendRecapNotification(
          enabled: false,
          completedPeriodKey: '2026-10',
          completedTxCount: 5,
          lastSeenKey: null,
          alreadyNotified: false,
        ),
        isFalse,
      );
      expect(
        shouldSendRecapNotification(
          enabled: true,
          completedPeriodKey: '2026-10',
          completedTxCount: 0,
          lastSeenKey: null,
          alreadyNotified: false,
        ),
        isFalse,
      );
      expect(
        shouldSendRecapNotification(
          enabled: true,
          completedPeriodKey: '2026-10',
          completedTxCount: 5,
          lastSeenKey: '2026-10',
          alreadyNotified: false,
        ),
        isFalse,
      );
      expect(
        shouldSendRecapNotification(
          enabled: true,
          completedPeriodKey: '2026-10',
          completedTxCount: 5,
          lastSeenKey: '2026-09',
          alreadyNotified: true,
        ),
        isFalse,
      );
      expect(
        shouldSendRecapNotification(
          enabled: true,
          completedPeriodKey: '2026-10',
          completedTxCount: 5,
          lastSeenKey: '2026-09',
          alreadyNotified: false,
        ),
        isTrue,
      );

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(featurePrefsProvider).recapAlerts, isFalse);
      await container.read(featurePrefsProvider.notifier).setRecapAlerts(true);
      expect(container.read(featurePrefsProvider).recapAlerts, isTrue);
      expect(prefs.getBool('pref_recap_alerts'), isTrue);

      container.read(featurePrefsProvider.notifier).applyRemote(recapAlerts: false);
      expect(container.read(featurePrefsProvider).recapAlerts, isFalse);
      expect(prefs.getBool('pref_recap_alerts'), isFalse);

      // Verify checkHarvestRecapNotification records deduplication key on completed period with txs
      final now = DateTime(2026, 11, 10);
      await db.addTransaction(
        amount: 50000,
        type: TxType.expense,
        categoryId: 'cat-exp-food',
        date: DateTime(2026, 10, 15),
        note: 'October lunch',
      );
      await checkHarvestRecapNotification(
        db: db,
        prefs: prefs,
        enabled: true,
        periodType: PeriodType.monthly,
        now: now,
      );
      expect(prefs.getBool('notified_recap_2026-10'), isTrue);
    });
  });
}

