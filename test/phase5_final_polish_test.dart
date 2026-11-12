import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/core/period.dart';
import 'package:wall_o_pay/core/theme.dart';
import 'package:wall_o_pay/data/app_database.dart';
import 'package:wall_o_pay/data/cloud.dart';
import 'package:wall_o_pay/data/feature_providers.dart';
import 'package:wall_o_pay/data/prefs.dart';
import 'package:wall_o_pay/data/providers.dart';
import 'package:wall_o_pay/data/tables.dart';
import 'package:wall_o_pay/features/goals/goals_page.dart';
import 'package:wall_o_pay/features/insights/insights_page.dart';
import 'package:wall_o_pay/features/settings/settings_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('id');
  });

  group('Phase 5 Final Hardening & UI Smoke Tests', () {
    test('All Phase 4 UI strings have distinct Indonesian translations', () {
      final en = AppStrings('en');
      final id = AppStrings('id');

      const keys = [
        'Net Worth',
        'Liquid Assets',
        'Receivables',
        'Liabilities',
        'Net Worth & Vitality Score',
        'Net Worth Breakdown',
        'Glasshouse Vitality Score',
        'Vitality Pillars',
        'Thriving',
        'Steady Growth',
        'Needs Care',
        'Fragile',
        'Starter',
        'Savings Rate',
        'Budget Discipline',
        'Needs vs Wants',
        'Debt Cushion',
        'On Track',
        'Behind Schedule',
        'Due Today',
        'Overdue',
        'Harvest recap notifications',
      ];

      for (final k in keys) {
        final enVal = en.tr(k);
        final idVal = id.tr(k);
        expect(enVal, k);
        expect(idVal, isNotEmpty);
        expect(idVal, isNot(k), reason: 'Key "$k" missing Indonesian translation');
      }
    });

    testWidgets('InsightsPage renders Net Worth & Vitality Score card and opens breakdown sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      AppLocale.code = 'en';
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final now = DateTime.now();
      final cats = {for (final c in await db.allCategories()) c.id: c};
      final txs = [
        TransactionEntry(
          id: 'tx-1',
          amount: 10000000,
          type: TxType.income,
          categoryId: 'cat-inc-parttime',
          walletId: 'w1',
          date: now,
          note: 'Income',
          needWant: null,
          createdAt: now,
          updatedAt: now,
          deletedAt: null,
        ),
        TransactionEntry(
          id: 'tx-2',
          amount: 2000000,
          type: TxType.expense,
          categoryId: 'cat-exp-food',
          walletId: 'w1',
          date: now,
          note: 'Food',
          needWant: NeedWant.need,
          createdAt: now,
          updatedAt: now,
          deletedAt: null,
        ),
      ];
      final debts = [
        Debt(
          id: 'd1',
          person: 'Rani',
          direction: DebtDirection.lent,
          amount: 500000,
          paidAmount: 100000,
          date: now,
          note: '',
          createdAt: now,
          updatedAt: now,
          deletedAt: null,
        ),
        Debt(
          id: 'd2',
          person: 'Budi',
          direction: DebtDirection.borrowed,
          amount: 300000,
          paidAmount: 0,
          date: now,
          note: '',
          createdAt: now,
          updatedAt: now,
          deletedAt: null,
        ),
      ];
      final goals = [
        SavingsGoal(
          id: 'g1',
          name: 'Emergency Fund',
          targetAmount: 5000000,
          currentAmount: 1200000,
          targetDate: now.add(const Duration(days: 90)),
          createdAt: now,
          updatedAt: now,
          deletedAt: null,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
            categoryMapProvider.overrideWithValue(cats),
            transactionsProvider.overrideWith((ref) => Stream.value(txs)),
            previousPeriodTransactionsProvider.overrideWith((ref) => Stream.value([])),
            trendTransactionsProvider.overrideWith((ref) => Stream.value(txs)),
            totalCurrentBalanceProvider.overrideWithValue(2500000),
            debtsProvider.overrideWith((ref) => Stream.value(debts)),
            savingsGoalsProvider.overrideWith((ref) => Stream.value(goals)),
            budgetByCategoryProvider.overrideWithValue({'cat-exp-food': 3000000}),
            spentByCategoryProvider.overrideWithValue({'cat-exp-food': 2000000}),
          ],
          child: MaterialApp(
            theme: buildTheme(),
            locale: const Locale('en'),
            supportedLocales: AppLocale.supported,
            localizationsDelegates: const [
              AppStrings.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            home: const InsightsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Net worth = 2.500.000 + 400.000 - 300.000 = 2.600.000
      expect(find.text('Net Worth'), findsOneWidget);
      expect(find.text('Rp 2.600.000'), findsOneWidget);
      expect(find.text('100/100'), findsOneWidget);
      expect(find.text('Thriving'), findsOneWidget);

      // Tap Net Worth card to open breakdown modal sheet
      await tester.tap(find.text('Net Worth'));
      await tester.pumpAndSettle();

      expect(find.text('Net Worth & Vitality Score'), findsOneWidget);
      expect(find.text('Vitality Pillars'), findsOneWidget);
      expect(find.text('Savings Rate'), findsOneWidget);
      expect(find.text('Budget Discipline'), findsOneWidget);
      expect(find.text('Needs vs Wants'), findsOneWidget);
      expect(find.text('Debt Cushion'), findsOneWidget);
    });

    testWidgets('GoalsPage renders Goal Pace badge and quick-fills recommended pace inside Add funds dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      AppLocale.code = 'en';
      SharedPreferences.setMockInitialValues({'pref_period': 'monthly'});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final now = DateTime.now();
      final futureTarget = DateTime(now.year, now.month, now.day).add(const Duration(days: 60));
      final goal = SavingsGoal(
        id: 'goal-1',
        name: 'Travel Canopy',
        targetAmount: 6000000,
        currentAmount: 2000000,
        targetDate: futureTarget,
        createdAt: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30)),
        updatedAt: now,
        deletedAt: null,
      );

      final expectedPace = computeGoalPace(goal, PeriodType.monthly)!;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
            savingsGoalsProvider.overrideWith((ref) => Stream.value([goal])),
            walletsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: buildTheme(),
            locale: const Locale('en'),
            supportedLocales: AppLocale.supported,
            localizationsDelegates: const [
              AppStrings.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            home: const GoalsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Travel Canopy'), findsOneWidget);
      expect(find.text('On Track'), findsOneWidget);

      await tester.tap(find.text('Add funds'));
      await tester.pumpAndSettle();

      final chipFinder = find.byType(ActionChip);
      expect(chipFinder, findsOneWidget);
      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      // Ensure dialog text field now holds formatted recommended pace
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(
        textField.controller?.text.replaceAll('.', ''),
        expectedPace.recommendedPerPeriod.toString(),
      );
    });

    testWidgets('SettingsPage displays Harvest recap notifications toggle in Indonesian locale', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      AppLocale.code = 'id';
      SharedPreferences.setMockInitialValues({'pref_locale': 'id'});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
            firebaseReadyProvider.overrideWithValue(false),
            currentUserProvider.overrideWithValue(null),
            allTransactionsProvider.overrideWith((ref) => Stream.value([])),
            walletsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: buildTheme(),
            locale: const Locale('id'),
            supportedLocales: AppLocale.supported,
            localizationsDelegates: const [
              AppStrings.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            home: const SettingsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final toggleFinder = find.text('Notifikasi rekap panen');
      await tester.scrollUntilVisible(toggleFinder, 250);
      expect(toggleFinder, findsOneWidget);
    });
  });
}

