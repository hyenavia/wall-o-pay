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
import 'package:wall_o_pay/data/budget_rule.dart';
import 'package:wall_o_pay/data/feature_providers.dart';
import 'package:wall_o_pay/data/notifications.dart';
import 'package:wall_o_pay/data/prefs.dart';
import 'package:wall_o_pay/data/providers.dart';
import 'package:wall_o_pay/data/tables.dart';
import 'package:wall_o_pay/features/budget/budget_page.dart';
import 'package:wall_o_pay/features/budget/category_budget_sheet.dart';
import 'package:wall_o_pay/features/budget/total_budget_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('id');
  });

  group('Wave 2 — Budget Continuity, Formatting, & Alerts', () {
    test('BudgetRuleNotifier.copyFromPeriod copies standard and custom allocations', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(budgetRuleProvider.notifier);

      // Nothing to copy from an unconfigured period.
      expect(await notifier.copyFromPeriod('2026-09', '2026-10'), isFalse);

      // Copy standard 50/30/20 total budget.
      await notifier.setTotalBudget('2026-09', 4000000);
      expect(await notifier.copyFromPeriod('2026-09', '2026-10'), isTrue);
      var state = container.read(budgetRuleProvider);
      expect(state.getTotalBudget('2026-10'), 4000000);
      expect(state.getCustomAllocation('2026-10'), isNull);

      // Copy custom allocations.
      await notifier.setCustomAllocations(
        '2026-10',
        total: 5000000,
        needs: 2500000,
        wants: 1000000,
        savings: 1500000,
      );
      expect(await notifier.copyFromPeriod('2026-10', '2026-11'), isTrue);
      state = container.read(budgetRuleProvider);
      expect(state.getTotalBudget('2026-11'), 5000000);
      expect(state.getCustomAllocation('2026-11'), {
        'needs': 2500000,
        'wants': 1000000,
        'savings': 1500000,
      });
    });

    testWidgets('TotalBudgetDialog & CategoryBudgetSheet format amounts with thousands separators',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      AppLocale.code = 'en';
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => tester.runAsync(db.close));

      final cats = await tester.runAsync(() => db.watchCategories().first) ?? const [];
      final foodCat = cats.firstWhere((c) => c.id == 'cat-exp-food');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: buildTheme(),
            home: Consumer(
              builder: (context, ref, _) => Scaffold(
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => showTotalBudgetDialog(
                        context,
                        ref,
                        '2026-11',
                        const Budget503020Breakdown(
                          totalBudget: 2500000,
                          needsBudget: 1250000,
                          wantsBudget: 750000,
                          savingsBudget: 500000,
                          needsSpent: 0,
                          wantsSpent: 0,
                          savingsSpent: 0,
                          totalSpent: 0,
                          needsCategories: [],
                          wantsCategories: [],
                          savingsCategories: [],
                          isCustom: false,
                        ),
                      ),
                      child: const Text('Open Total Dialog'),
                    ),
                    ElevatedButton(
                      onPressed: () => showCategoryBudgetSheet(
                        context,
                        ref,
                        foodCat,
                        '2026-11',
                        750000,
                        BudgetBucket.needs,
                      ),
                      child: const Text('Open Category Sheet'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // 1. TotalBudgetDialog initializes with formatted text & formats live input.
      await tester.tap(find.text('Open Total Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('2.500.000'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '3000000');
      await tester.pump();
      expect(find.text('3.000.000'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.text('Save'));
      });
      await tester.pumpAndSettle();

      // 2. CategoryBudgetSheet initializes with formatted text & formats live input.
      await tester.tap(find.text('Open Category Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('750.000'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '900000');
      await tester.pump();
      expect(find.text('900.000'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.text('Save'));
      });
      await tester.pumpAndSettle();

      final savedLimit = await tester.runAsync(() => db.budgetAmount(foodCat.id, '2026-11'));
      expect(savedLimit, 900000);
    });

    testWidgets('BudgetPage shows 1-tap copy banner and copies previous period budget',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      AppLocale.code = 'en';
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => tester.runAsync(db.close));

      final cats = await tester.runAsync(() => db.watchCategories().first) ?? const [];
      final currentPeriod = Period.containing(PeriodType.monthly, DateTime(2026, 11, 12));
      final prevPeriod = currentPeriod.shift(-1);

      final prevBudgetRow = Budget(
        id: 'b-prev-food',
        categoryId: 'cat-exp-food',
        monthKey: prevPeriod.key,
        amount: 600000,
        createdAt: prevPeriod.start,
        updatedAt: prevPeriod.start,
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          categoriesProvider.overrideWithValue(AsyncData(cats)),
          budgetsProvider.overrideWithValue(const AsyncData([])),
          transactionsProvider.overrideWithValue(const AsyncData([])),
          prevBudgetsProvider.overrideWithValue(AsyncData([prevBudgetRow])),
          prevTransactionsProvider.overrideWithValue(const AsyncData([])),
          selectedPeriodProvider.overrideWithValue(currentPeriod),
        ],
      );
      addTearDown(container.dispose);

      await container.read(budgetRuleProvider.notifier).setTotalBudget(prevPeriod.key, 3000000);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildTheme(),
            home: const BudgetPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No budget set for this period'), findsOneWidget);
      final copyBtnFinder = find.text('Copy from ${prevPeriod.label}');
      expect(copyBtnFinder, findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(copyBtnFinder);
      });
      await tester.pumpAndSettle();

      expect(container.read(budgetRuleProvider).getTotalBudget(currentPeriod.key), 3000000);
      final copiedCatBudget = await tester.runAsync(
        () => db.budgetAmount('cat-exp-food', currentPeriod.key),
      );
      expect(copiedCatBudget, 600000);
    });

    test('checkBudgetAfterExpense respects rollover carryover and totalBudgetPool', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final date = DateTime(2026, 11, 10);
      final period = Period.containing(PeriodType.monthly, date);
      final prevPeriod = period.shift(-1);

      // Prev period had 500k budget and 200k spent -> 300k rollover carryover.
      await db.setBudget('cat-exp-food', prevPeriod.key, 500000);
      await db.addTransaction(
        amount: 200000,
        type: TxType.expense,
        categoryId: 'cat-exp-food',
        date: prevPeriod.start.add(const Duration(days: 2)),
      );

      // Current period base budget = 500k. Effective with rollover = 800k.
      // Spending 450k is 90% of base (would alert 80% without rollover),
      // but only 56% of effective 800k (no alert with rolloverEnabled: true!).
      // Meanwhile totalBudgetPool = 500k -> 450k hits 80% pool alert!
      await db.setBudget('cat-exp-food', period.key, 500000);
      await db.addTransaction(
        amount: 450000,
        type: TxType.expense,
        categoryId: 'cat-exp-food',
        date: date,
      );

      await checkBudgetAfterExpense(
        db: db,
        prefs: prefs,
        periodType: PeriodType.monthly,
        categoryId: 'cat-exp-food',
        categoryName: 'Food & Drinks',
        date: date,
        rolloverEnabled: true,
        totalBudgetPool: 500000,
      );

      expect(prefs.getInt('alert_${period.key}_cat-exp-food'), isNull);
      expect(prefs.getInt('alert_pool_${period.key}'), 80);

      // Now add another 200k -> 650k category spent (81% of 800k) and >= 100% of 500k pool!
      await db.addTransaction(
        amount: 200000,
        type: TxType.expense,
        categoryId: 'cat-exp-food',
        date: date,
      );

      await checkBudgetAfterExpense(
        db: db,
        prefs: prefs,
        periodType: PeriodType.monthly,
        categoryId: 'cat-exp-food',
        categoryName: 'Food & Drinks',
        date: date,
        rolloverEnabled: true,
        totalBudgetPool: 500000,
      );

      expect(prefs.getInt('alert_${period.key}_cat-exp-food'), 80);
      expect(prefs.getInt('alert_pool_${period.key}'), 100);
    });
  });
}
