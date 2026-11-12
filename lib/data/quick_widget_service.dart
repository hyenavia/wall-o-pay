/// Layanan jembatan sinkronisasi data antara aplikasi Flutter dan
/// ekosistem Android Home Screen Widget (Quick Finance, Daily Pulse, Quick Action,
/// One-Tap Favorites, Budget Guardrail, Goals & Bills) melalui MethodChannel.
/// Mengirimkan snapshot metrik keuangan harian, anggaran periode, target tabungan,
/// tagihan mendatang, total saldo, status sensor privasi, bahasa aktif ke native Android,
/// serta menyinkronkan perubahan native, pinning widget, dan deep link route.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n.dart';
import '../core/period.dart';
import '../features/home/daily_financial_pulse_card.dart';
import 'app_database.dart';
import 'budget_rule.dart';
import 'feature_prefs.dart';
import 'feature_providers.dart';
import 'lock.dart';
import 'module_prefs.dart';
import 'prefs.dart';
import 'providers.dart';
import 'recurring_service.dart' hide recurringRulesProvider;
import 'tables.dart' show TxType;

/// Channel komunikasi ke native Android untuk sinkronisasi data widget.
const _widgetChannel = MethodChannel('com.example.wall_o_pay/widget');

Timer? _snapshotDebounce;
String? _pendingWidgetRoute;
bool _widgetRouteListenerRegistered = false;
bool _widgetLockListenerRegistered = false;
BuildContext? _activeRouteContext;
WidgetRef? _activeRouteRef;
VoidCallback? _onOpenNewTransactionCallback;
VoidCallback? _onOpenGoalsCallback;
VoidCallback? _onOpenRecurringCallback;

/// Hasil kalkulasi ringkas anggaran periode untuk Budget Guardrail Widget.
class BudgetGuardrailSnapshot {
  const BudgetGuardrailSnapshot({
    required this.hasConfig,
    required this.totalBudget,
    required this.budgetSpent,
    required this.budgetPct,
    required this.alertLevel,
    required this.categoriesJson,
  });

  final bool hasConfig;
  final int totalBudget;
  final int budgetSpent;
  final int budgetPct;
  final String alertLevel;
  final String categoriesJson;
}

/// Menghitung snapshot Budget Guardrail secara deterministik dan aman privasi.
BudgetGuardrailSnapshot buildBudgetGuardrailSnapshot({
  required int budgetPool,
  required Map<String, int> effectiveBudgets,
  required Map<String, int> spentByCat,
  required int totalExpense,
  required Map<String, Category> categories,
  required String locale,
  required bool hideBalance,
}) {
  final hasCategoryBudgets = effectiveBudgets.values.any((v) => v > 0);
  final rawTotalBudget = budgetPool > 0
      ? budgetPool
      : effectiveBudgets.values.fold<int>(0, (a, b) => a + b);
  final rawBudgetSpent = budgetPool > 0
      ? totalExpense
      : effectiveBudgets.keys.fold<int>(0, (a, id) => a + (spentByCat[id] ?? 0));

  final hasConfig = rawTotalBudget > 0;
  final budgetPct = hasConfig
      ? ((rawBudgetSpent * 100) / rawTotalBudget).round().clamp(0, 999)
      : 0;
  final alertLevel = !hasConfig
      ? 'none'
      : budgetPct >= 100
          ? 'over'
          : budgetPct >= 85
              ? 'near'
              : 'none';

  final l10n = AppStrings(locale);
  final catItems = <({String id, String name, int spent, int limit, int pct})>[];

  if (hasCategoryBudgets) {
    for (final entry in effectiveBudgets.entries) {
      if (entry.value <= 0) continue;
      final cat = categories[entry.key];
      if (cat == null || cat.deletedAt != null || cat.type != TxType.expense) {
        continue;
      }
      final spent = spentByCat[entry.key] ?? 0;
      final pct = ((spent * 100) / entry.value).round().clamp(0, 999);
      catItems.add((
        id: cat.id,
        name: l10n.tr(cat.name),
        spent: spent,
        limit: entry.value,
        pct: pct,
      ));
    }
    catItems.sort((a, b) {
      final byPct = b.pct.compareTo(a.pct);
      if (byPct != 0) return byPct;
      final bySpent = b.spent.compareTo(a.spent);
      if (bySpent != 0) return bySpent;
      return a.name.compareTo(b.name);
    });
  } else if (budgetPool > 0) {
    for (final entry in spentByCat.entries) {
      if (entry.value <= 0) continue;
      final cat = categories[entry.key];
      if (cat == null || cat.deletedAt != null || cat.type != TxType.expense) {
        continue;
      }
      final pct = ((entry.value * 100) / budgetPool).round().clamp(0, 999);
      catItems.add((
        id: cat.id,
        name: l10n.tr(cat.name),
        spent: entry.value,
        limit: 0,
        pct: pct,
      ));
    }
    catItems.sort((a, b) {
      final bySpent = b.spent.compareTo(a.spent);
      if (bySpent != 0) return bySpent;
      return a.name.compareTo(b.name);
    });
  }

  final topCategories = catItems
      .take(3)
      .map(
        (c) => {
          'id': c.id,
          'name': c.name,
          'spent': hideBalance ? 0 : c.spent,
          'limit': hideBalance ? 0 : c.limit,
          'pct': c.pct,
        },
      )
      .toList();

  return BudgetGuardrailSnapshot(
    hasConfig: hasConfig,
    totalBudget: hideBalance ? 0 : rawTotalBudget,
    budgetSpent: hideBalance ? 0 : rawBudgetSpent,
    budgetPct: budgetPct,
    alertLevel: alertLevel,
    categoriesJson: jsonEncode(topCategories),
  );
}

/// Hasil kalkulasi ringkas target tabungan & tagihan mendatang untuk Goals & Bills Widget.
class GoalsAndBillsSnapshot {
  const GoalsAndBillsSnapshot({
    required this.goalsJson,
    required this.activeGoalCount,
    required this.doneGoalCount,
    required this.billsJson,
    required this.billsDueCount,
    required this.billsDueAmount,
  });

  final String goalsJson;
  final int activeGoalCount;
  final int doneGoalCount;
  final String billsJson;
  final int billsDueCount;
  final int billsDueAmount;
}

/// Menghitung snapshot Target Tabungan & Tagihan Mendatang secara deterministik dan aman privasi.
GoalsAndBillsSnapshot buildGoalsAndBillsSnapshot({
  required List<SavingsGoal> goals,
  required List<RecurringRule> rules,
  required List<PendingTransaction> pending,
  required bool hideBalance,
  DateTime? now,
}) {
  final validGoals = goals
      .where((g) => g.deletedAt == null && g.targetAmount > 0)
      .toList();
  final activeGoals = validGoals
      .where((g) => g.currentAmount < g.targetAmount)
      .toList();
  final doneGoalCount = validGoals
      .where((g) => g.currentAmount >= g.targetAmount)
      .length;

  activeGoals.sort((a, b) {
    final aDate = a.targetDate;
    final bDate = b.targetDate;
    if (aDate != null && bDate != null) {
      final byDate = aDate.compareTo(bDate);
      if (byDate != 0) return byDate;
    } else if (aDate != null) {
      return -1;
    } else if (bDate != null) {
      return 1;
    }
    final aPct = (a.currentAmount * 100) ~/ a.targetAmount;
    final bPct = (b.currentAmount * 100) ~/ b.targetAmount;
    final byPct = bPct.compareTo(aPct);
    if (byPct != 0) return byPct;
    return a.name.compareTo(b.name);
  });

  final encodedGoals = activeGoals.take(10).map((g) {
    final current = g.currentAmount.clamp(0, g.targetAmount);
    final remaining = (g.targetAmount - current).clamp(0, g.targetAmount);
    final pct = ((current * 100) / g.targetAmount).round().clamp(0, 100);
    return {
      'id': g.id,
      'name': g.name,
      'current': hideBalance ? 0 : current,
      'target': hideBalance ? 0 : g.targetAmount,
      'pct': pct,
      'remaining': hideBalance ? 0 : remaining,
    };
  }).toList();

  final refNow = now ?? DateTime.now();
  final todayStart = DateTime(refNow.year, refNow.month, refNow.day);
  final horizonEnd = todayStart.add(const Duration(days: 30));

  final bills = <({String title, int amount, DateTime dueDay, bool isPending})>[];

  for (final p in pending) {
    if (p.deletedAt != null || p.type != TxType.expense || p.amount <= 0) {
      continue;
    }
    final dueDay = DateTime(p.dueDate.year, p.dueDate.month, p.dueDate.day);
    if (!dueDay.isAfter(horizonEnd)) {
      bills.add((
        title: p.title,
        amount: p.amount,
        dueDay: dueDay,
        isPending: true,
      ));
    }
  }

  for (final r in rules) {
    if (!r.isActive ||
        r.deletedAt != null ||
        r.type != TxType.expense ||
        r.amount <= 0) {
      continue;
    }
    final dueDay =
        DateTime(r.nextDueDate.year, r.nextDueDate.month, r.nextDueDate.day);
    if (!dueDay.isAfter(horizonEnd)) {
      bills.add((
        title: r.title,
        amount: r.amount,
        dueDay: dueDay,
        isPending: false,
      ));
    }
  }

  bills.sort((a, b) {
    final byDue = a.dueDay.compareTo(b.dueDay);
    if (byDue != 0) return byDue;
    if (a.isPending != b.isPending) return a.isPending ? -1 : 1;
    final byAmt = b.amount.compareTo(a.amount);
    if (byAmt != 0) return byAmt;
    return a.title.compareTo(b.title);
  });

  final dueSoon = bills
      .where((b) => b.dueDay.difference(todayStart).inDays <= 14)
      .toList();
  final billsDueCount = dueSoon.length;
  final billsDueAmount = hideBalance
      ? 0
      : dueSoon.fold<int>(0, (sum, b) => sum + b.amount);

  final encodedBills = bills.take(5).map((b) {
    return {
      'title': b.title,
      'amount': hideBalance ? 0 : b.amount,
      'dueMs': b.dueDay.millisecondsSinceEpoch,
      'daysUntil': b.dueDay.difference(todayStart).inDays,
      'isPending': b.isPending,
    };
  }).toList();

  return GoalsAndBillsSnapshot(
    goalsJson: jsonEncode(encodedGoals),
    activeGoalCount: activeGoals.length,
    doneGoalCount: doneGoalCount,
    billsJson: jsonEncode(encodedBills),
    billsDueCount: billsDueCount,
    billsDueAmount: billsDueAmount,
  );
}

/// Memetakan nilai `widget_route` dari Home Screen Widget ke indeks tab BottomAppBar.
/// Mengembalikan `null` jika route bukan navigasi tab (misalnya `new_transaction`).
int? resolveWidgetRouteTabIndex(String route, {required bool budgetEnabled}) {
  return switch (route) {
    'tab_home' => 0,
    'tab_transactions' => 1,
    'tab_budget' => budgetEnabled ? 2 : 0,
    'tab_insight' => 3,
    _ => null,
  };
}

/// Mendaftarkan pendengar deep link route (`widget_route`) dari Android Home Screen Widget
/// tanpa pernah melewati LockGate (PIN/biometrik).
void initializeWidgetRouting(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onOpenNewTransaction,
  VoidCallback? onOpenGoals,
  VoidCallback? onOpenRecurring,
}) {
  _activeRouteContext = context;
  _activeRouteRef = ref;
  _onOpenNewTransactionCallback = onOpenNewTransaction;
  _onOpenGoalsCallback = onOpenGoals;
  _onOpenRecurringCallback = onOpenRecurring;

  if (!_widgetLockListenerRegistered) {
    _widgetLockListenerRegistered = true;
    Lock.instance.isLocked.addListener(() {
      if (!Lock.instance.isLocked.value && _pendingWidgetRoute != null) {
        final ctx = _activeRouteContext;
        final activeRef = _activeRouteRef;
        if (ctx != null && ctx.mounted && activeRef != null) {
          _consumeQueuedWidgetRoute(ctx, activeRef);
        }
      }
    });
  }

  if (!_widgetRouteListenerRegistered) {
    _widgetRouteListenerRegistered = true;
    _widgetChannel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetRoute') {
        final route = call.arguments as String?;
        if (route != null && route.isNotEmpty) {
          _pendingWidgetRoute = route;
          try {
            await _widgetChannel.invokeMethod('clearWidgetRoute');
          } catch (_) {}
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = _activeRouteContext;
            final activeRef = _activeRouteRef;
            if (ctx != null && ctx.mounted && activeRef != null) {
              _consumeQueuedWidgetRoute(ctx, activeRef);
            }
          });
        }
      }
    });
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      checkPendingWidgetRoute(context, ref);
    }
  });
}

/// Memeriksa apakah ada `widget_route` tertunda dari intent Android saat launch/resume.
Future<void> checkPendingWidgetRoute(BuildContext context, WidgetRef ref) async {
  _activeRouteContext = context;
  _activeRouteRef = ref;
  try {
    final route = await _widgetChannel.invokeMethod<String>('getPendingWidgetRoute');
    if (route != null && route.isNotEmpty) {
      _pendingWidgetRoute = route;
      await _widgetChannel.invokeMethod('clearWidgetRoute');
    }
  } catch (e) {
    debugPrint('[QuickWidgetService] Failed to check pending widget route: $e');
  }
  if (context.mounted && _pendingWidgetRoute != null) {
    _consumeQueuedWidgetRoute(context, ref);
  }
}

void _runAfterCurrentFrame(VoidCallback action) {
  WidgetsBinding.instance.addPostFrameCallback((_) => action());
  WidgetsBinding.instance.ensureVisualUpdate();
}

void _consumeQueuedWidgetRoute(BuildContext context, WidgetRef ref) {
  final route = _pendingWidgetRoute;
  if (route == null || route.isEmpty) return;
  // Tunggu pengguna membuka LockGate terlebih dahulu sebelum berpindah tab/halaman.
  if (Lock.instance.isLocked.value) return;

  _pendingWidgetRoute = null;
  final budgetEnabled = ref.read(modulePrefsProvider).budget;
  final tabIndex = resolveWidgetRouteTabIndex(route, budgetEnabled: budgetEnabled);
  if (tabIndex != null) {
    ref.read(tabIndexProvider.notifier).set(tabIndex);
    return;
  }
  if (route == 'new_transaction') {
    _runAfterCurrentFrame(() => _onOpenNewTransactionCallback?.call());
    return;
  }
  if (route == 'route_goals') {
    _runAfterCurrentFrame(() => _onOpenGoalsCallback?.call());
    return;
  }
  if (route == 'route_recurring') {
    _runAfterCurrentFrame(() => _onOpenRecurringCallback?.call());
  }
}

/// Mengirimkan data saldo, status sensor, dan bahasa ke Quick Finance Widget.
/// Dipanggil setiap kali total saldo, status sensor, atau bahasa berubah.
Future<void> syncWidgetData(WidgetRef ref) async {
  try {
    final hideBalance = ref.read(hideBalanceProvider);
    final totalBalance = hideBalance ? 0 : ref.read(totalCurrentBalanceProvider);
    final locale = ref.read(appPrefsProvider).localeCode;
    await _widgetChannel.invokeMethod('updateWidgetData', {
      'balance': totalBalance,
      'hideBalance': hideBalance,
      'locale': locale,
    });
  } catch (e) {
    debugPrint('[QuickWidgetService] Failed to sync widget data: $e');
  }
}

/// Mengirimkan data saldo dan status sensor ke widget tanpa WidgetRef.
Future<void> syncWidgetDataDirect({
  required int totalBalance,
  required bool hideBalance,
  String? locale,
}) async {
  try {
    await _widgetChannel.invokeMethod('updateWidgetData', {
      'balance': hideBalance ? 0 : totalBalance,
      'hideBalance': hideBalance,
      'locale': locale ?? AppLocale.code,
    });
  } catch (e) {
    debugPrint('[QuickWidgetService] Failed to sync widget data: $e');
  }
}

/// Menghitung snapshot Daily Pulse periode berjalan secara deterministik dan mengirimkannya
/// ke Shared Snapshot Store di native Android untuk seluruh Home Screen Widget Fase 1.
Future<void> syncWidgetSnapshot(WidgetRef ref) async {
  try {
    // Baca seluruh provider secara sinkron sebelum await pertama agar aman
    // meskipun pemanggil (mis. bottom sheet form) langsung di-pop/unmount.
    final appPrefs = ref.read(appPrefsProvider);
    final hideBalance = ref.read(hideBalanceProvider);
    final totalBalance = ref.read(totalCurrentBalanceProvider);
    final now = DateTime.now();
    final currentPeriod = Period.containing(
      appPrefs.periodType,
      now,
      firstDayOfWeek: appPrefs.firstDayOfWeek,
      firstDayOfMonth: appPrefs.firstDayOfMonth,
    );
    final selectedPeriod = ref.read(selectedPeriodProvider);
    final useSelectedPeriodCache = selectedPeriod.key == currentPeriod.key;
    final txAsync = useSelectedPeriodCache ? ref.read(transactionsProvider) : null;
    final budgetAsync = useSelectedPeriodCache ? ref.read(budgetsProvider) : null;
    final db = ref.read(databaseProvider);
    final categories = ref.read(categoryMapProvider);
    final rolloverActive = ref.read(featurePrefsProvider).rollover;
    final prevTxAsync =
        (rolloverActive && useSelectedPeriodCache) ? ref.read(prevTransactionsProvider) : null;
    final prevBudgetAsync =
        (rolloverActive && useSelectedPeriodCache) ? ref.read(prevBudgetsProvider) : null;
    final budgetRule = ref.read(budgetRuleProvider);
    final rulesCached = ref.read(recurringRulesProvider).value;
    final pendingCached = ref.read(pendingTransactionsProvider).value;
    final goalsCached = ref.read(savingsGoalsProvider).value;

    final List<TransactionEntry> txs;
    final List<Budget> budgetRows;
    if (txAsync != null &&
        budgetAsync != null &&
        txAsync.hasValue &&
        budgetAsync.hasValue) {
      txs = txAsync.value ?? const [];
      budgetRows = budgetAsync.value ?? const [];
    } else {
      txs = await db
          .watchTransactionsBetween(currentPeriod.start, currentPeriod.end)
          .first;
      budgetRows = await db.watchBudgets(currentPeriod.key).first;
    }

    final budgets = <String, int>{
      for (final b in budgetRows)
        if (categories[b.categoryId] != null &&
            categories[b.categoryId]!.deletedAt == null)
          b.categoryId: b.amount,
    };

    final carryByCat = <String, int>{};
    if (rolloverActive) {
      final prevPeriod = currentPeriod.shift(-1);
      final List<TransactionEntry> prevTxs;
      final List<Budget> prevBudgets;
      if (prevTxAsync != null &&
          prevBudgetAsync != null &&
          prevTxAsync.hasValue &&
          prevBudgetAsync.hasValue) {
        prevTxs = prevTxAsync.value ?? const [];
        prevBudgets = prevBudgetAsync.value ?? const [];
      } else {
        prevTxs = await db
            .watchTransactionsBetween(prevPeriod.start, prevPeriod.end)
            .first;
        prevBudgets = await db.watchBudgets(prevPeriod.key).first;
      }
      final prevSpent = <String, int>{};
      for (final t in prevTxs) {
        if (t.type == TxType.expense) {
          prevSpent[t.categoryId] = (prevSpent[t.categoryId] ?? 0) + t.amount;
        }
      }
      for (final b in prevBudgets) {
        final left = b.amount - (prevSpent[b.categoryId] ?? 0);
        if (left > 0) carryByCat[b.categoryId] = left;
      }
    }

    final effectiveBudgets = <String, int>{
      for (final k in {...budgets.keys, ...carryByCat.keys})
        if (categories[k] != null && categories[k]!.deletedAt == null)
          k: (budgets[k] ?? 0) + (carryByCat[k] ?? 0),
    };

    final spentByCat = <String, int>{};
    var income = 0;
    var expense = 0;
    var todayExpense = 0;
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    for (final t in txs) {
      if (t.type == TxType.income) {
        income += t.amount;
      } else if (t.type == TxType.expense) {
        expense += t.amount;
        spentByCat[t.categoryId] = (spentByCat[t.categoryId] ?? 0) + t.amount;
        if (!t.date.isBefore(todayStart) && t.date.isBefore(todayEnd)) {
          todayExpense += t.amount;
        }
      }
    }

    final budgetPool = budgetRule.getTotalBudget(currentPeriod.key);
    final totalBudget = budgetPool > 0
        ? budgetPool
        : effectiveBudgets.values.fold<int>(0, (a, b) => a + b);
    final budgetSpent = budgetPool > 0
        ? expense
        : effectiveBudgets.keys.fold<int>(0, (a, id) => a + (spentByCat[id] ?? 0));

    final guardrail = buildBudgetGuardrailSnapshot(
      budgetPool: budgetPool,
      effectiveBudgets: effectiveBudgets,
      spentByCat: spentByCat,
      totalExpense: expense,
      categories: categories,
      locale: appPrefs.localeCode,
      hideBalance: hideBalance,
    );

    final rules = rulesCached ?? await db.watchRecurringRules().first;
    final pendingList =
        pendingCached ?? await db.watchPendingTransactions().first;
    final goalsList = goalsCached ?? await db.watchSavingsGoals().first;
    final upcomingBills = RecurringService.calculateUpcomingExpense(
      rules,
      currentPeriod,
      pending: pendingList,
    );

    final goalsAndBills = buildGoalsAndBillsSnapshot(
      goals: goalsList,
      rules: rules,
      pending: pendingList,
      hideBalance: hideBalance,
      now: now,
    );

    final pulse = calculateDailyPulse(
      income: income,
      expense: expense,
      totalWalletBalance: totalBalance,
      totalBudget: totalBudget,
      budgetSpent: budgetSpent,
      todayExpense: todayExpense,
      daysLeft: currentPeriod.daysLeft,
      upcomingBills: upcomingBills,
      txCount: txs.length,
    );

    final dateYmd =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await syncWidgetSnapshotDirect(
      totalBalance: totalBalance,
      hideBalance: hideBalance,
      locale: appPrefs.localeCode,
      dailyAllowance: pulse.dailyAllowance,
      todayExpense: todayExpense,
      tier: pulse.tier.name,
      fundingBasis: pulse.fundingBasis.name,
      daysLeft: pulse.daysLeft,
      periodStartMs: currentPeriod.start.millisecondsSinceEpoch,
      periodEndMs: currentPeriod.end.millisecondsSinceEpoch,
      dateYmd: dateYmd,
      budgetHasConfig: guardrail.hasConfig,
      totalBudget: guardrail.totalBudget,
      budgetSpent: guardrail.budgetSpent,
      budgetPct: guardrail.budgetPct,
      budgetAlertLevel: guardrail.alertLevel,
      budgetCategoriesJson: guardrail.categoriesJson,
      goalsJson: goalsAndBills.goalsJson,
      goalsActiveCount: goalsAndBills.activeGoalCount,
      goalsDoneCount: goalsAndBills.doneGoalCount,
      billsJson: goalsAndBills.billsJson,
      billsDueCount: goalsAndBills.billsDueCount,
      billsDueAmount: goalsAndBills.billsDueAmount,
    );
  } catch (e) {
    debugPrint('[QuickWidgetService] Failed to sync widget snapshot: $e');
  }
}

/// Menjadwalkan sinkronisasi snapshot dengan debounce singkat agar perubahan beruntun tidak memicu render berlebih.
void scheduleWidgetSnapshotSync(WidgetRef ref) {
  _snapshotDebounce?.cancel();
  _snapshotDebounce = Timer(const Duration(milliseconds: 250), () {
    syncWidgetSnapshot(ref);
  });
}

/// Mengirimkan snapshot metrik widget secara langsung tanpa WidgetRef (memudahkan unit test).
Future<void> syncWidgetSnapshotDirect({
  required int totalBalance,
  required bool hideBalance,
  String? locale,
  required int dailyAllowance,
  required int todayExpense,
  required String tier,
  required String fundingBasis,
  required int daysLeft,
  required int periodStartMs,
  required int periodEndMs,
  required String dateYmd,
  bool budgetHasConfig = false,
  int totalBudget = 0,
  int budgetSpent = 0,
  int budgetPct = 0,
  String budgetAlertLevel = 'none',
  String budgetCategoriesJson = '[]',
  String goalsJson = '[]',
  int goalsActiveCount = 0,
  int goalsDoneCount = 0,
  String billsJson = '[]',
  int billsDueCount = 0,
  int billsDueAmount = 0,
}) async {
  try {
    await _widgetChannel.invokeMethod('updateWidgetSnapshot', {
      'balance': hideBalance ? 0 : totalBalance,
      'hideBalance': hideBalance,
      'locale': locale ?? AppLocale.code,
      'dailyAllowance': hideBalance ? 0 : dailyAllowance,
      'todayExpense': hideBalance ? 0 : todayExpense,
      'tier': tier,
      'fundingBasis': fundingBasis,
      'daysLeft': daysLeft,
      'periodStartMs': periodStartMs,
      'periodEndMs': periodEndMs,
      'dateYmd': dateYmd,
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      'budgetHasConfig': budgetHasConfig,
      'totalBudget': hideBalance ? 0 : totalBudget,
      'budgetSpent': hideBalance ? 0 : budgetSpent,
      'budgetPct': budgetPct,
      'budgetAlertLevel': budgetAlertLevel,
      'budgetCategoriesJson': budgetCategoriesJson,
      'goalsJson': goalsJson,
      'goalsActiveCount': goalsActiveCount,
      'goalsDoneCount': goalsDoneCount,
      'billsJson': billsJson,
      'billsDueCount': billsDueCount,
      'billsDueAmount': hideBalance ? 0 : billsDueAmount,
    });
  } catch (e) {
    debugPrint('[QuickWidgetService] Failed to send widget snapshot: $e');
  }
}

/// Mengambil jumlah instance aktif setiap widget Android yang sedang terpasang di Home Screen.
Future<Map<String, int>> getActiveHomeWidgetCounts() async {
  try {
    final raw =
        await _widgetChannel.invokeMapMethod<String, dynamic>('getActiveWidgetCounts');
    if (raw == null) return const {};
    return {
      for (final entry in raw.entries)
        entry.key: (entry.value is num) ? (entry.value as num).toInt() : 0,
    };
  } catch (e) {
    debugPrint('[QuickWidgetService] Failed to read active widget counts: $e');
    return const {};
  }
}

/// Memeriksa apakah launcher Android saat ini mendukung penambahan widget langsung dari dalam app (API 26+).
Future<bool> isPinHomeWidgetSupported() async {
  try {
    final res = await _widgetChannel.invokeMethod<bool>('isPinWidgetSupported');
    return res ?? false;
  } catch (e) {
    debugPrint('[QuickWidgetService] Failed to check pin widget support: $e');
    return false;
  }
}

/// Meminta OS Android untuk memunculkan dialog penyematan widget ke Home Screen.
Future<bool> requestPinHomeWidget(String key) async {
  try {
    final res = await _widgetChannel.invokeMethod<bool>(
      'requestPinWidget',
      {'key': key},
    );
    return res ?? false;
  } catch (e) {
    debugPrint('[QuickWidgetService] Failed to request pin widget: $e');
    return false;
  }
}

/// Membaca preset transparansi latar widget ('deep', 'frosted', atau 'clear').
Future<String> getWidgetGlassStyle() async {
  try {
    final style = await _widgetChannel.invokeMethod<String>('getWidgetGlassStyle');
    return switch (style) {
      'frosted' || 'clear' => style!,
      _ => 'deep',
    };
  } catch (e) {
    debugPrint('[QuickWidgetService] Failed to read widget glass style: $e');
    return 'deep';
  }
}

/// Mengubah preset transparansi latar seluruh Android Home Screen Widget dan langsung memperbaruinya.
Future<String> setWidgetGlassStyle(String style) async {
  final normalized = switch (style) {
    'frosted' || 'clear' => style,
    _ => 'deep',
  };
  try {
    final res = await _widgetChannel.invokeMethod<String>(
      'setWidgetGlassStyle',
      {'style': normalized},
    );
    return res ?? normalized;
  } catch (e) {
    debugPrint('[QuickWidgetService] Failed to update widget glass style: $e');
    return normalized;
  }
}

/// Memeriksa apakah widget/dialog native baru saja menulis transaksi ke SQLite
/// atau mengubah status sensor privasi saat aplikasi di latar belakang.
Future<bool> checkNativeWidgetDbDirty(WidgetRef ref) async {
  var changed = false;
  try {
    final nativeHide =
        await _widgetChannel.invokeMethod<bool>('consumeNativeHideBalance');
    if (nativeHide != null) {
      await ref.read(hideBalanceProvider.notifier).set(nativeHide);
      changed = true;
    }
  } catch (e) {
    debugPrint('[QuickWidgetService] Failed to check native hide toggle: $e');
  }

  try {
    final dirty = await _widgetChannel.invokeMethod<bool>('consumeNativeDbDirty');
    if (dirty == true) {
      final db = ref.read(databaseProvider);
      db.markTablesUpdated({db.transactions});
      changed = true;
    }
  } catch (e) {
    debugPrint('[QuickWidgetService] Failed to check native DB dirty flag: $e');
  }
  return changed;
}
