import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/core/period.dart';
import 'package:wall_o_pay/core/theme.dart';
import 'package:wall_o_pay/data/app_database.dart';
import 'package:wall_o_pay/data/feature_providers.dart';
import 'package:wall_o_pay/data/prefs.dart';
import 'package:wall_o_pay/data/providers.dart';
import 'package:wall_o_pay/data/report_service.dart';
import 'package:wall_o_pay/data/tables.dart';
import 'package:wall_o_pay/features/home/daily_financial_pulse_card.dart';
import 'package:wall_o_pay/features/insights/insight_engine.dart';
import 'package:wall_o_pay/features/insights/insights_page.dart';
import 'package:wall_o_pay/features/settings/guest_backup_nudge_banner.dart';
import 'package:wall_o_pay/features/transactions/transactions_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('id');
  });

  group('Wave 3 — Insights Drill-Down, Pulse Links, & Export Polish', () {
    test('ReportService.formatTransactionAmount distinguishes income, expense, and transfer', () {
      expect(ReportService.formatTransactionAmount(TxType.income, 100000), '+Rp 100.000');
      expect(ReportService.formatTransactionAmount(TxType.expense, 50000), '-Rp 50.000');
      expect(ReportService.formatTransactionAmount(TxType.transfer, 250000), '<-> Rp 250.000');
    });

    testWidgets('SmartInsightItem drill-down metadata & InsightsPage modal drill-down work',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      AppLocale.code = 'en';
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => tester.runAsync(db.close));

      final seededCats = await tester.runAsync(() => db.watchCategories().first) ?? const [];
      final catMap = {for (final c in seededCats) c.id: c};
      final period = Period.containing(PeriodType.monthly, DateTime(2026, 11, 12));

      final txs = [
        TransactionEntry(
          id: 'tx-1',
          amount: 180000,
          type: TxType.expense,
          categoryId: 'cat-exp-food',
          note: 'Team Lunch',
          date: DateTime(2026, 11, 5),
          walletId: 'wallet-main',
          toWalletId: null,
          receiptPath: null,
          needWant: NeedWant.want,
          createdAt: DateTime(2026, 11, 5),
          updatedAt: DateTime(2026, 11, 5),
        ),
        TransactionEntry(
          id: 'tx-2',
          amount: 25000,
          type: TxType.expense,
          categoryId: 'cat-exp-food',
          note: 'Coffee',
          date: DateTime(2026, 11, 6),
          walletId: 'wallet-main',
          toWalletId: null,
          receiptPath: null,
          needWant: NeedWant.want,
          createdAt: DateTime(2026, 11, 6),
          updatedAt: DateTime(2026, 11, 6),
        ),
        TransactionEntry(
          id: 'tx-3',
          amount: 30000,
          type: TxType.expense,
          categoryId: 'cat-exp-food',
          note: 'Snack',
          date: DateTime(2026, 11, 7),
          walletId: 'wallet-main',
          toWalletId: null,
          receiptPath: null,
          needWant: NeedWant.need,
          createdAt: DateTime(2026, 11, 7),
          updatedAt: DateTime(2026, 11, 7),
        ),
        TransactionEntry(
          id: 'tx-4',
          amount: 35000,
          type: TxType.expense,
          categoryId: 'cat-exp-transport',
          note: 'Ojek',
          date: DateTime(2026, 11, 7),
          walletId: 'wallet-main',
          toWalletId: null,
          receiptPath: null,
          needWant: NeedWant.need,
          createdAt: DateTime(2026, 11, 7),
          updatedAt: DateTime(2026, 11, 7),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
            selectedPeriodProvider.overrideWithValue(period),
            categoriesProvider.overrideWithValue(AsyncData(seededCats)),
            allCategoriesProvider.overrideWithValue(AsyncData(seededCats)),
            transactionsProvider.overrideWithValue(AsyncData(txs)),
            previousPeriodTransactionsProvider.overrideWithValue(const AsyncData([])),
            trendTransactionsProvider.overrideWithValue(AsyncData(txs)),
            debtsProvider.overrideWithValue(const AsyncData([])),
            savingsGoalsProvider.overrideWithValue(const AsyncData([])),
            budgetsProvider.overrideWithValue(const AsyncData([])),
            walletsProvider.overrideWithValue(const AsyncData([])),
            walletBalancesProvider.overrideWithValue(const {}),
          ],
          child: MaterialApp(
            theme: buildTheme(),
            home: const InsightsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify unit filtering on generated SmartInsightItem items.
      final element = tester.element(find.byType(InsightsPage));
      final summary = InsightEngine.computeSummary(currentTxs: txs, prevTxs: const []);
      final cats = InsightEngine.computeCategories(
        context: element,
        currentTxs: txs,
        prevTxs: const [],
        categoryMap: catMap,
        totalExpense: summary.totalExpense,
      );
      final insights = InsightEngine.generateSmartInsights(
        context: element,
        summary: summary,
        categories: cats,
        currentTxs: txs,
        period: period,
        categoryMap: catMap,
      );

      final largestInsight = insights.firstWhere((i) => i.title == 'Largest Transaction');
      expect(largestInsight.hasDrillDown, isTrue);
      final largestMatches = InsightEngine.filterTransactionsForInsight(largestInsight, txs);
      expect(largestMatches.map((e) => e.id).toList(), ['tx-1']);

      final microInsight = insights.firstWhere((i) => i.title == 'Frequent Small Purchases');
      expect(microInsight.maxAmount, 50000);
      final microMatches = InsightEngine.filterTransactionsForInsight(microInsight, txs);
      expect(microMatches.length, 3); // Coffee 25k, Snack 30k, Ojek 35k

      // Scroll to and tap 'Largest Transaction' insight card in the UI.
      await tester.scrollUntilVisible(find.text('Largest Transaction'), 300);
      await tester.tap(find.text('Largest Transaction'));
      await tester.pumpAndSettle();

      // Drill-down sheet shows the matching transaction note 'Team Lunch'.
      expect(find.text('Team Lunch'), findsOneWidget);
      Navigator.of(tester.element(find.text('Team Lunch'))).pop();
      await tester.pumpAndSettle();
    });

    testWidgets('DailyFinancialPulseCard invokes onTapUpcomingBills when upcoming reserve row tapped',
        (tester) async {
      AppLocale.code = 'en';
      var tapped = false;
      const pulse = DailyPulseResult(
        tier: DailyHealthTier.safe,
        dailyAllowance: 50000,
        fundingBasis: PulseFundingBasis.periodBudget,
        basisAmount: 1500000,
        availablePool: 1000000,
        upcomingBills: 500000,
        daysLeft: 20,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: Scaffold(
            body: DailyFinancialPulseCard(
              dailyAllowance: 50000,
              todayExpense: 10000,
              daysLeft: 20,
              balance: 1500000,
              totalBudget: 2000000,
              budgetSpent: 500000,
              txCount: 3,
              pulse: pulse,
              onTapUpcomingBills: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Reserves Rp 500.000 for upcoming scheduled bills'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('TransactionsPage exposes Export PDF report & Export transactions (CSV) menu',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      AppLocale.code = 'en';
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => tester.runAsync(db.close));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
            allCategoriesProvider.overrideWithValue(const AsyncData([])),
            walletsProvider.overrideWithValue(const AsyncData([])),
            transactionsProvider.overrideWithValue(const AsyncData([])),
            walletNetFlowsProvider.overrideWithValue(const AsyncData({})),
          ],
          child: MaterialApp(
            theme: buildTheme(),
            home: const TransactionsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Export'));
      await tester.pumpAndSettle();

      expect(find.text('Export PDF report'), findsOneWidget);
      expect(find.text('Export transactions (CSV)'), findsOneWidget);
    });

    testWidgets('GuestBackupNudgeBanner shows when >=10 active transactions & dismisses cleanly',
        (tester) async {
      AppLocale.code = 'en';
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => tester.runAsync(db.close));

      await tester.runAsync(() async {
        for (int i = 0; i < 10; i++) {
          await db.addTransaction(
            amount: 10000,
            type: TxType.expense,
            categoryId: 'cat-exp-food',
            date: DateTime(2026, 11, 1),
          );
        }
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: buildTheme(),
            home: Scaffold(
              body: GuestBackupNudgeBanner(
                onBackupNow: () async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Back up your local records'), findsOneWidget);
      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pumpAndSettle();

      expect(find.text('Back up your local records'), findsNothing);
      expect(prefs.getInt('guest_backup_nudge_dismissed_ms'), isNotNull);
    });
  });
}

