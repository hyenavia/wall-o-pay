import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/data/app_database.dart';
import 'package:wall_o_pay/data/lock.dart';
import 'package:wall_o_pay/data/module_prefs.dart';
import 'package:wall_o_pay/data/prefs.dart';
import 'package:wall_o_pay/data/providers.dart';
import 'package:wall_o_pay/data/quick_widget_service.dart';
import 'package:wall_o_pay/data/tables.dart';
import 'package:wall_o_pay/features/settings/widget_hub_sheet.dart';

class _TestSyncConsumer extends ConsumerWidget {
  const _TestSyncConsumer({required this.onReady});
  final void Function(WidgetRef ref) onReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onReady(ref);
    return const SizedBox.shrink();
  }
}

class _WidgetRouteTestHost extends ConsumerStatefulWidget {
  const _WidgetRouteTestHost({
    super.key,
    required this.onRef,
    this.onOpenGoals,
    this.onOpenRecurring,
  });
  final void Function(WidgetRef ref) onRef;
  final VoidCallback? onOpenGoals;
  final VoidCallback? onOpenRecurring;

  @override
  ConsumerState<_WidgetRouteTestHost> createState() => _WidgetRouteTestHostState();
}

class _WidgetRouteTestHostState extends ConsumerState<_WidgetRouteTestHost> {
  @override
  void initState() {
    super.initState();
    initializeWidgetRouting(
      context,
      ref,
      onOpenGoals: widget.onOpenGoals,
      onOpenRecurring: widget.onOpenRecurring,
    );
  }

  @override
  Widget build(BuildContext context) {
    widget.onRef(ref);
    return const SizedBox.shrink();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Quick Finance Widget & Service Tests', () {
    final List<MethodCall> methodCalls = [];
    var mockDirtyFlag = false;
    bool? mockNativeHidePending;
    String? mockPendingWidgetRoute;
    var mockGlassStyle = 'deep';

    setUp(() {
      methodCalls.clear();
      mockDirtyFlag = false;
      mockNativeHidePending = null;
      mockPendingWidgetRoute = null;
      mockGlassStyle = 'deep';
      Lock.instance.isLocked.value = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example.wall_o_pay/widget'),
        (MethodCall call) async {
          methodCalls.add(call);
          if (call.method == 'updateWidgetData' || call.method == 'updateWidgetSnapshot') {
            return true;
          }
          if (call.method == 'consumeNativeHideBalance') {
            final res = mockNativeHidePending;
            mockNativeHidePending = null;
            return res;
          }
          if (call.method == 'consumeNativeDbDirty') {
            final res = mockDirtyFlag;
            mockDirtyFlag = false;
            return res;
          }
          if (call.method == 'getPendingWidgetRoute') {
            return mockPendingWidgetRoute;
          }
          if (call.method == 'clearWidgetRoute') {
            mockPendingWidgetRoute = null;
            return true;
          }
          if (call.method == 'getActiveWidgetCounts') {
            return {'daily_pulse': 1, 'goals_bills': 2};
          }
          if (call.method == 'isPinWidgetSupported') {
            return true;
          }
          if (call.method == 'requestPinWidget') {
            final args = Map<String, dynamic>.from(call.arguments as Map);
            return args['key'] == 'goals_bills';
          }
          if (call.method == 'getWidgetGlassStyle') {
            return mockGlassStyle;
          }
          if (call.method == 'setWidgetGlassStyle') {
            final args = Map<String, dynamic>.from(call.arguments as Map);
            mockGlassStyle = (args['style'] as String?) ?? 'deep';
            return mockGlassStyle;
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example.wall_o_pay/widget'),
        null,
      );
    });

    test('syncWidgetDataDirect sends balance, locale, and masks balance when hidden', () async {
      await syncWidgetDataDirect(
        totalBalance: 15000000,
        hideBalance: false,
        locale: 'id',
      );

      expect(methodCalls.length, 1);
      expect(methodCalls.first.method, 'updateWidgetData');
      expect(methodCalls.first.arguments, {
        'balance': 15000000,
        'hideBalance': false,
        'locale': 'id',
      });

      // When hideBalance is true, balance passed across channel must be masked (0)
      await syncWidgetDataDirect(
        totalBalance: 2500000,
        hideBalance: true,
        locale: 'en',
      );

      expect(methodCalls.length, 2);
      expect(methodCalls.last.arguments, {
        'balance': 0,
        'hideBalance': true,
        'locale': 'en',
      });
    });

    testWidgets('checkNativeWidgetDbDirty notifies Drift tableUpdates when native write occurred', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      var tableUpdateTriggered = false;
      final sub = db.tableUpdates().listen((updates) {
        if (updates.any((u) => u.table == 'transactions')) {
          tableUpdateTriggered = true;
        }
      });
      addTearDown(sub.cancel);

      WidgetRef? capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
          child: _TestSyncConsumer(onReady: (ref) => capturedRef = ref),
        ),
      );

      // Initially clean
      mockDirtyFlag = false;
      final firstCheck = await checkNativeWidgetDbDirty(capturedRef!);
      expect(firstCheck, isFalse);
      await tester.pump();
      expect(tableUpdateTriggered, isFalse);

      // Native widget wrote a transaction
      mockDirtyFlag = true;
      final secondCheck = await checkNativeWidgetDbDirty(capturedRef!);
      expect(secondCheck, isTrue);
      await tester.pump();
      expect(tableUpdateTriggered, isTrue);
    });

    test('Localization verifies Quick Finance strings in English and Indonesian', () {
      final en = AppStrings('en');
      final id = AppStrings('id');

      expect(en.tr('Quick Finance'), 'Quick Finance');
      expect(id.tr('Quick Finance'), 'Keuangan Cepat');

      expect(en.tr('Quick Finance Widget'), 'Quick Finance Widget');
      expect(id.tr('Quick Finance Widget'), 'Widget Keuangan Cepat');

      expect(en.tr('Record Transaction'), 'Record Transaction');
      expect(id.tr('Record Transaction'), 'Catat Transaksi');

      expect(en.tr('Save Transaction'), 'Save Transaction');
      expect(id.tr('Save Transaction'), 'Simpan Transaksi');
    });

    test('TxType enum contains all three Quick Finance transaction types', () {
      expect(TxType.values.contains(TxType.income), isTrue);
      expect(TxType.values.contains(TxType.expense), isTrue);
      expect(TxType.values.contains(TxType.transfer), isTrue);
    });

    test('syncWidgetSnapshotDirect sends full Daily Pulse snapshot and masks values when hidden', () async {
      await syncWidgetSnapshotDirect(
        totalBalance: 4850000,
        hideBalance: false,
        locale: 'id',
        dailyAllowance: 125000,
        todayExpense: 42000,
        tier: 'safe',
        fundingBasis: 'periodBudget',
        daysLeft: 18,
        periodStartMs: 1700000000000,
        periodEndMs: 1702592000000,
        dateYmd: '2026-11-12',
      );

      expect(methodCalls.length, 1);
      expect(methodCalls.first.method, 'updateWidgetSnapshot');
      final args = Map<String, dynamic>.from(methodCalls.first.arguments as Map);
      expect(args['balance'], 4850000);
      expect(args['hideBalance'], false);
      expect(args['locale'], 'id');
      expect(args['dailyAllowance'], 125000);
      expect(args['todayExpense'], 42000);
      expect(args['tier'], 'safe');
      expect(args['fundingBasis'], 'periodBudget');
      expect(args['daysLeft'], 18);
      expect(args['dateYmd'], '2026-11-12');

      // When hideBalance is true, balance, dailyAllowance, and todayExpense must all be masked (0)
      await syncWidgetSnapshotDirect(
        totalBalance: 4850000,
        hideBalance: true,
        locale: 'en',
        dailyAllowance: 125000,
        todayExpense: 42000,
        tier: 'caution',
        fundingBasis: 'periodBudget',
        daysLeft: 18,
        periodStartMs: 1700000000000,
        periodEndMs: 1702592000000,
        dateYmd: '2026-11-12',
      );

      final maskedArgs = Map<String, dynamic>.from(methodCalls.last.arguments as Map);
      expect(maskedArgs['balance'], 0);
      expect(maskedArgs['dailyAllowance'], 0);
      expect(maskedArgs['todayExpense'], 0);
      expect(maskedArgs['hideBalance'], true);
      expect(maskedArgs['tier'], 'caution');
    });

    testWidgets('checkNativeWidgetDbDirty syncs native hideBalance toggle back to hideBalanceProvider', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      WidgetRef? capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(db),
          ],
          child: _TestSyncConsumer(onReady: (ref) => capturedRef = ref),
        ),
      );

      expect(capturedRef!.read(hideBalanceProvider), isFalse);

      mockNativeHidePending = true;
      final changed = await checkNativeWidgetDbDirty(capturedRef!);
      expect(changed, isTrue);
      expect(capturedRef!.read(hideBalanceProvider), isTrue);
    });

    test('buildBudgetGuardrailSnapshot computes alert levels, top 3 categories, and privacy masking', () {
      final now = DateTime(2026, 11, 1);
      final cats = {
        'c1': Category(
          id: 'c1',
          name: 'Food & Drinks',
          type: TxType.expense,
          icon: 'food',
          colorValue: 0xFF38B271,
          createdAt: now,
          updatedAt: now,
        ),
        'c2': Category(
          id: 'c2',
          name: 'Transport',
          type: TxType.expense,
          icon: 'transport',
          colorValue: 0xFF38B271,
          createdAt: now,
          updatedAt: now,
        ),
        'c3': Category(
          id: 'c3',
          name: 'Shopping',
          type: TxType.expense,
          icon: 'shopping',
          colorValue: 0xFF38B271,
          createdAt: now,
          updatedAt: now,
        ),
        'c4': Category(
          id: 'c4',
          name: 'Entertainment',
          type: TxType.expense,
          icon: 'fun',
          colorValue: 0xFF38B271,
          createdAt: now,
          updatedAt: now,
        ),
      };

      final snap = buildBudgetGuardrailSnapshot(
        budgetPool: 0,
        effectiveBudgets: {
          'c1': 1000000,
          'c2': 500000,
          'c3': 400000,
          'c4': 100000,
        },
        spentByCat: {
          'c1': 850000, // 85%
          'c2': 550000, // 110% (highest pct -> #1)
          'c3': 360000, // 90% (#2)
          'c4': 10000, // 10% (4th, truncated)
        },
        totalExpense: 1770000,
        categories: cats,
        locale: 'id',
        hideBalance: false,
      );

      expect(snap.hasConfig, isTrue);
      expect(snap.totalBudget, 2000000);
      expect(snap.budgetSpent, 1770000);
      expect(snap.budgetPct, 89);
      expect(snap.alertLevel, 'near');

      final parsed = List<Map<String, dynamic>>.from(jsonDecode(snap.categoriesJson) as List);
      expect(parsed.length, 3);
      expect(parsed[0]['id'], 'c2');
      expect(parsed[0]['name'], 'Transportasi');
      expect(parsed[0]['pct'], 110);
      expect(parsed[1]['id'], 'c3');
      expect(parsed[1]['name'], 'Belanja');
      expect(parsed[2]['id'], 'c1');
      expect(parsed[2]['name'], 'Makanan & Minuman');

      // Privacy masking keeps pct/alertLevel/hasConfig while zeroing money amounts
      final hidden = buildBudgetGuardrailSnapshot(
        budgetPool: 1000000,
        effectiveBudgets: const {},
        spentByCat: const {'c1': 1100000},
        totalExpense: 1100000,
        categories: cats,
        locale: 'en',
        hideBalance: true,
      );
      expect(hidden.hasConfig, isTrue);
      expect(hidden.totalBudget, 0);
      expect(hidden.budgetSpent, 0);
      expect(hidden.budgetPct, 110);
      expect(hidden.alertLevel, 'over');
      final hiddenCats = List<Map<String, dynamic>>.from(jsonDecode(hidden.categoriesJson) as List);
      expect(hiddenCats.first['spent'], 0);
      expect(hiddenCats.first['limit'], 0);
      expect(hiddenCats.first['pct'], 110);
    });

    test('resolveWidgetRouteTabIndex maps widget routes accurately', () {
      expect(resolveWidgetRouteTabIndex('tab_home', budgetEnabled: true), 0);
      expect(resolveWidgetRouteTabIndex('tab_transactions', budgetEnabled: true), 1);
      expect(resolveWidgetRouteTabIndex('tab_budget', budgetEnabled: true), 2);
      expect(resolveWidgetRouteTabIndex('tab_budget', budgetEnabled: false), 0);
      expect(resolveWidgetRouteTabIndex('tab_insight', budgetEnabled: true), 3);
      expect(resolveWidgetRouteTabIndex('tab_insight', budgetEnabled: false), 3);
      expect(resolveWidgetRouteTabIndex('new_transaction', budgetEnabled: true), isNull);
    });

    testWidgets('widget route waits for LockGate unlock before switching tabs', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      // Lock app first, then simulate widget route arrival during launch
      Lock.instance.isLocked.value = true;
      mockPendingWidgetRoute = 'tab_budget';

      WidgetRef? capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(db),
          ],
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: _WidgetRouteTestHost(onRef: (ref) => capturedRef = ref),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should NOT switch tab while locked and should have consumed/queued native route
      expect(mockPendingWidgetRoute, isNull);
      expect(capturedRef!.read(tabIndexProvider), 0);

      // Unlock app -> queued widget route activates immediately
      Lock.instance.isLocked.value = false;
      await tester.pumpAndSettle();
      expect(capturedRef!.read(tabIndexProvider), 2);
    });

    test('buildGoalsAndBillsSnapshot computes active goals, upcoming bills, overdue ordering, and privacy masking', () {
      final now = DateTime(2026, 11, 12, 10, 0);
      final goals = [
        SavingsGoal(
          id: 'g_done',
          name: 'Headphones',
          targetAmount: 2000000,
          currentAmount: 2000000,
          targetDate: DateTime(2026, 12, 1),
          createdAt: now,
          updatedAt: now,
        ),
        SavingsGoal(
          id: 'g_later',
          name: 'Japan Trip',
          targetAmount: 20000000,
          currentAmount: 5000000,
          targetDate: DateTime(2027, 4, 1),
          createdAt: now,
          updatedAt: now,
        ),
        SavingsGoal(
          id: 'g_soon',
          name: 'Emergency Fund',
          targetAmount: 10000000,
          currentAmount: 7500000,
          targetDate: DateTime(2026, 12, 15),
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final rules = [
        RecurringRule(
          id: 'r1',
          title: 'Internet Fiber',
          amount: 350000,
          type: TxType.expense,
          categoryId: 'c_bills',
          walletId: 'wallet-main',
          frequency: RecurFrequency.monthly,
          dayOfMonth: 15,
          startDate: DateTime(2026, 1, 15),
          nextDueDate: DateTime(2026, 11, 15), // +3 days (within 14d)
          isActive: true,
          note: '',
          createdAt: now,
          updatedAt: now,
        ),
        RecurringRule(
          id: 'r_far',
          title: 'Cloud Storage',
          amount: 150000,
          type: TxType.expense,
          categoryId: 'c_bills',
          walletId: 'wallet-main',
          frequency: RecurFrequency.monthly,
          dayOfMonth: 10,
          startDate: DateTime(2026, 1, 10),
          nextDueDate: DateTime(2026, 12, 5), // +23 days (outside 14d, inside 30d)
          isActive: true,
          note: '',
          createdAt: now,
          updatedAt: now,
        ),
        RecurringRule(
          id: 'r_income',
          title: 'Salary',
          amount: 12000000,
          type: TxType.income,
          categoryId: 'c_salary',
          walletId: 'wallet-main',
          frequency: RecurFrequency.monthly,
          dayOfMonth: 25,
          startDate: DateTime(2026, 1, 25),
          nextDueDate: DateTime(2026, 11, 25),
          isActive: true,
          note: '',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final pending = [
        PendingTransaction(
          id: 'p1',
          recurringRuleId: 'r_old',
          title: 'Electricity PLN',
          amount: 500000,
          type: TxType.expense,
          categoryId: 'c_bills',
          walletId: 'wallet-main',
          dueDate: DateTime(2026, 11, 11), // -1 day overdue -> #1
          note: '',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final snap = buildGoalsAndBillsSnapshot(
        goals: goals,
        rules: rules,
        pending: pending,
        hideBalance: false,
        now: now,
      );

      expect(snap.activeGoalCount, 2);
      expect(snap.doneGoalCount, 1);
      final parsedGoals =
          List<Map<String, dynamic>>.from(jsonDecode(snap.goalsJson) as List);
      expect(parsedGoals.length, 2);
      expect(parsedGoals[0]['name'], 'Emergency Fund'); // earlier targetDate first
      expect(parsedGoals[0]['pct'], 75);
      expect(parsedGoals[0]['remaining'], 2500000);
      expect(parsedGoals[1]['name'], 'Japan Trip');

      expect(snap.billsDueCount, 2); // overdue Electricity + +3d Internet Fiber
      expect(snap.billsDueAmount, 850000);
      final parsedBills =
          List<Map<String, dynamic>>.from(jsonDecode(snap.billsJson) as List);
      expect(parsedBills.length, 3);
      expect(parsedBills[0]['title'], 'Electricity PLN');
      expect(parsedBills[0]['daysUntil'], -1);
      expect(parsedBills[0]['isPending'], true);
      expect(parsedBills[1]['title'], 'Internet Fiber');
      expect(parsedBills[1]['daysUntil'], 3);
      expect(parsedBills[2]['title'], 'Cloud Storage');
      expect(parsedBills[2]['daysUntil'], 23);

      // Privacy masking zeroes monetary amounts while keeping counts/percentages/dates
      final masked = buildGoalsAndBillsSnapshot(
        goals: goals,
        rules: rules,
        pending: pending,
        hideBalance: true,
        now: now,
      );
      expect(masked.billsDueCount, 2);
      expect(masked.billsDueAmount, 0);
      final maskedGoals =
          List<Map<String, dynamic>>.from(jsonDecode(masked.goalsJson) as List);
      expect(maskedGoals[0]['current'], 0);
      expect(maskedGoals[0]['target'], 0);
      expect(maskedGoals[0]['pct'], 75);
      final maskedBills =
          List<Map<String, dynamic>>.from(jsonDecode(masked.billsJson) as List);
      expect(maskedBills[0]['amount'], 0);
      expect(maskedBills[0]['title'], 'Electricity PLN');
    });

    testWidgets('route_goals and route_recurring wait for LockGate unlock before navigating', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      var goalsOpened = 0;
      var recurringOpened = 0;
      Lock.instance.isLocked.value = true;
      mockPendingWidgetRoute = 'route_goals';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(db),
          ],
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: _WidgetRouteTestHost(
              onRef: (_) {},
              onOpenGoals: () => goalsOpened++,
              onOpenRecurring: () => recurringOpened++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(goalsOpened, 0);
      Lock.instance.isLocked.value = false;
      await tester.pumpAndSettle();
      expect(goalsOpened, 1);

      // Simulate tapping upcoming bills card while locked
      Lock.instance.isLocked.value = true;
      mockPendingWidgetRoute = 'route_recurring';
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('recurring_host'),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(db),
          ],
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: _WidgetRouteTestHost(
              key: const ValueKey('recurring_widget'),
              onRef: (_) {},
              onOpenGoals: () => goalsOpened++,
              onOpenRecurring: () => recurringOpened++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(recurringOpened, 0);

      Lock.instance.isLocked.value = false;
      await tester.pumpAndSettle();
      expect(recurringOpened, 1);
    });

    test('Widget Hub channel helpers return counts, pin support, and trigger pin request', () async {
      final counts = await getActiveHomeWidgetCounts();
      expect(counts, {'daily_pulse': 1, 'goals_bills': 2});

      final supported = await isPinHomeWidgetSupported();
      expect(supported, isTrue);

      final pinnedGoals = await requestPinHomeWidget('goals_bills');
      expect(pinnedGoals, isTrue);

      final pinnedOther = await requestPinHomeWidget('daily_pulse');
      expect(pinnedOther, isFalse);
    });

    test('Widget glass style helpers normalize presets and round-trip via channel', () async {
      expect(await getWidgetGlassStyle(), 'deep');

      expect(await setWidgetGlassStyle('frosted'), 'frosted');
      expect(await getWidgetGlassStyle(), 'frosted');

      expect(await setWidgetGlassStyle('clear'), 'clear');
      expect(await getWidgetGlassStyle(), 'clear');

      // Unknown style must fall back safely to 'deep'
      expect(await setWidgetGlassStyle('invalid_glass'), 'deep');
      expect(await getWidgetGlassStyle(), 'deep');
    });

    testWidgets(
      'WidgetHubSheet shows Glass Style presets, live previews, and quick-enables disabled modules',
      (tester) async {
        AppLocale.code = 'en';
        SharedPreferences.setMockInitialValues({
          'pref_module_budget': false,
        });
        final prefs = await SharedPreferences.getInstance();
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        WidgetRef? capturedRef;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              databaseProvider.overrideWithValue(db),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    capturedRef = ref;
                    return const WidgetHubSheet();
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Glass style selector is visible and switches to Frosted
        expect(find.text('Glass Style'), findsOneWidget);
        expect(find.text('Frosted'), findsOneWidget);
        await tester.tap(find.text('Frosted'));
        await tester.pumpAndSettle();
        expect(mockGlassStyle, 'frosted');

        // Scroll to Budget Guardrail card and verify disabled module notice + Enable button
        await tester.scrollUntilVisible(
          find.text('Budget module is turned off'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Budget module is turned off'), findsOneWidget);
        expect(capturedRef!.read(modulePrefsProvider).budget, isFalse);

        await tester.tap(find.text('Enable').first);
        await tester.pumpAndSettle();
        expect(capturedRef!.read(modulePrefsProvider).budget, isTrue);

        // Unmount widget tree and pump so Drift's 0ms stream cleanup timers drain cleanly.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  });
}
