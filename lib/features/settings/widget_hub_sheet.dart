/// Lembar Hub Android Home Screen Widgets ([showWidgetHubSheet]) untuk meninjau
/// keenam widget bertema Enchanted Glasshouse, melihat pratinjau langsung berbasis data pengguna,
/// memilih gaya transparansi kaca, mengaktifkan modul yang mati, menyinkronkan data seketika,
/// serta menyematkan widget langsung ke Home Screen (Android 8.0+).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/app_database.dart';
import '../../data/budget_rule.dart';
import '../../data/feature_providers.dart';
import '../../data/module_prefs.dart';
import '../../data/prefs.dart';
import '../../data/providers.dart';
import '../../data/quick_widget_service.dart';
import '../../data/recurring_service.dart' show RecurringService;
import '../../data/tables.dart' show TxType;
import '../home/daily_financial_pulse_card.dart';

/// Membuka modal bottom sheet ekosistem Android Home Screen Widgets.
Future<void> showWidgetHubSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const WidgetHubSheet(),
  );
}

class _HomeWidgetSpec {
  const _HomeWidgetSpec({
    required this.key,
    required this.titleKey,
    required this.descKey,
    required this.sizes,
    required this.icon,
    required this.accent,
  });

  final String key;
  final String titleKey;
  final String descKey;
  final String sizes;
  final IconData icon;
  final Color accent;
}

const _homeWidgetSpecs = <_HomeWidgetSpec>[
  _HomeWidgetSpec(
    key: 'daily_pulse',
    titleKey: 'Daily Pulse & Balance',
    descKey:
        'See your total balance, safe daily spending quota, and pace status at a glance.',
    sizes: '2×2 • 4×2',
    icon: Icons.bolt_rounded,
    accent: AppColors.sage,
  ),
  _HomeWidgetSpec(
    key: 'quick_finance',
    titleKey: 'Quick Finance',
    descKey:
        'Record income, expenses, or transfers directly from your Home Screen in seconds.',
    sizes: '4×2',
    icon: Icons.add_card_rounded,
    accent: AppColors.incomeOnDark,
  ),
  _HomeWidgetSpec(
    key: 'quick_action',
    titleKey: 'Quick Action Bar',
    descKey:
        'Compact glassmorphic shortcuts to jump straight into recording transactions.',
    sizes: '2×1 • 4×1',
    icon: Icons.flash_on_rounded,
    accent: AppColors.dewMint,
  ),
  _HomeWidgetSpec(
    key: 'favorite_templates',
    titleKey: 'One-Tap Favorites',
    descKey:
        'Log your saved templates in one tap directly from the Home Screen with instant Undo.',
    sizes: '4×1 • 4×2',
    icon: Icons.star_rounded,
    accent: AppColors.warning,
  ),
  _HomeWidgetSpec(
    key: 'budget_guardrail',
    titleKey: 'Budget Guardrail',
    descKey:
        'Monitor remaining period budget, 85%/100% alert pills, and top category limits.',
    sizes: '2×2 • 4×2',
    icon: Icons.shield_outlined,
    accent: AppColors.expenseOnDark,
  ),
  _HomeWidgetSpec(
    key: 'goals_bills',
    titleKey: 'Goals & Upcoming Bills',
    descKey:
        'Track active savings goal progress and upcoming scheduled bills with live countdowns.',
    sizes: '2×2 • 4×2',
    icon: Icons.flag_rounded,
    accent: Color(0xFF60A5FA),
  ),
];

/// Konten Hub Android Home Screen Widgets dengan pratinjau langsung, pemilih gaya kaca,
/// serta deteksi status modul aktif.
class WidgetHubSheet extends ConsumerStatefulWidget {
  const WidgetHubSheet({super.key});

  @override
  ConsumerState<WidgetHubSheet> createState() => _WidgetHubSheetState();
}

class _WidgetHubSheetState extends ConsumerState<WidgetHubSheet> {
  Map<String, int> _counts = const {};
  bool _pinSupported = false;
  bool _loading = true;
  bool _syncing = false;
  String _glassStyle = 'deep';

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final results = await Future.wait([
      getActiveHomeWidgetCounts(),
      isPinHomeWidgetSupported(),
      getWidgetGlassStyle(),
    ]);
    if (!mounted) return;
    setState(() {
      _counts = results[0] as Map<String, int>;
      _pinSupported = results[1] as bool;
      _glassStyle = results[2] as String;
      _loading = false;
    });
  }

  Future<void> _syncNow() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    await syncWidgetData(ref);
    await syncWidgetSnapshot(ref);
    await _loadStatus();
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('Home widgets synced.'))),
    );
  }

  Future<void> _changeGlassStyle(String style) async {
    if (style == _glassStyle) return;
    setState(() => _glassStyle = style);
    final applied = await setWidgetGlassStyle(style);
    if (!mounted) return;
    setState(() => _glassStyle = applied);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('Glass style updated')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _enableModules(List<String> keys) async {
    final notifier = ref.read(modulePrefsProvider.notifier);
    for (final k in keys) {
      await notifier.setModule(k, true);
    }
    await syncWidgetSnapshot(ref);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('Module enabled'))),
    );
  }

  Future<void> _pinWidget(_HomeWidgetSpec spec) async {
    final triggered = await requestPinHomeWidget(spec.key);
    if (!mounted) return;
    if (!triggered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Long-press your Android Home Screen → Widgets → Wall o\' Pay to add this widget.',
            ),
          ),
        ),
      );
      return;
    }
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _loadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final totalActive = _counts.values.fold<int>(0, (sum, c) => sum + c);

    final hideBalance = ref.watch(hideBalanceProvider);
    final totalBalance = ref.watch(totalCurrentBalanceProvider);
    final modules = ref.watch(modulePrefsProvider);
    final locale = ref.watch(appPrefsProvider).localeCode;
    final period = ref.watch(selectedPeriodProvider);
    final txs = ref.watch(transactionsProvider).value ?? const <TransactionEntry>[];
    final effectiveBudgets = ref.watch(effectiveBudgetProvider);
    final spentByCat = ref.watch(spentByCategoryProvider);
    final budgetPool = ref.watch(budgetRuleProvider).getTotalBudget(period.key);
    final categories = ref.watch(categoryMapProvider);
    final templates = ref.watch(templatesProvider).value ?? const <TxTemplate>[];
    final goals = ref.watch(savingsGoalsProvider).value ?? const <SavingsGoal>[];
    final rules = ref.watch(recurringRulesProvider).value ?? const <RecurringRule>[];
    final pending =
        ref.watch(pendingTransactionsProvider).value ?? const <PendingTransaction>[];

    // Hitung ringkasan langsung untuk pratinjau widget
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    var income = 0;
    var expense = 0;
    var todayExpense = 0;
    for (final t in txs) {
      if (t.type == TxType.income) {
        income += t.amount;
      } else if (t.type == TxType.expense) {
        expense += t.amount;
        if (!t.date.isBefore(todayStart) && t.date.isBefore(todayEnd)) {
          todayExpense += t.amount;
        }
      }
    }

    final guardrail = buildBudgetGuardrailSnapshot(
      budgetPool: budgetPool,
      effectiveBudgets: effectiveBudgets,
      spentByCat: spentByCat,
      totalExpense: expense,
      categories: categories,
      locale: locale,
      hideBalance: hideBalance,
    );

    final upcomingBills = RecurringService.calculateUpcomingExpense(
      rules,
      period,
      pending: pending,
    );
    final goalsAndBills = buildGoalsAndBillsSnapshot(
      goals: goals,
      rules: rules,
      pending: pending,
      hideBalance: hideBalance,
      now: now,
    );
    final pulse = calculateDailyPulse(
      income: income,
      expense: expense,
      totalWalletBalance: totalBalance,
      totalBudget: guardrail.hasConfig ? (budgetPool > 0 ? budgetPool : effectiveBudgets.values.fold<int>(0, (a, b) => a + b)) : 0,
      budgetSpent: budgetPool > 0
          ? expense
          : effectiveBudgets.keys.fold<int>(0, (a, id) => a + (spentByCat[id] ?? 0)),
      todayExpense: todayExpense,
      daysLeft: period.daysLeft,
      upcomingBills: upcomingBills,
      txCount: txs.length,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('Android Home Widgets'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _syncing ? null : _syncNow,
                        icon: _syncing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync_rounded, size: 16),
                        label: Text(context.tr('Sync now')),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr(
                      'Keep Enchanted Glasshouse insights and quick actions right on your Android Home Screen.',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.deepForest.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.dewMint.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          totalActive > 0
                              ? Icons.widgets_rounded
                              : Icons.widgets_outlined,
                          size: 18,
                          color: totalActive > 0 ? AppColors.sage : muted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _loading
                                ? context.tr('Checking Home Screen widgets...')
                                : totalActive > 0
                                    ? context.tr(
                                        '{count} active on Home Screen',
                                        {'count': totalActive},
                                      )
                                    : context.tr(
                                        'Long-press your Android Home Screen → Widgets → Wall o\' Pay to add any widget.',
                                      ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: totalActive > 0
                                  ? AppColors.dewMint
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        context.tr('Glass Style'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.freshSage,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SegmentedButton<String>(
                          segments: [
                            ButtonSegment<String>(
                              value: 'deep',
                              label: Text(context.tr('Deep')),
                            ),
                            ButtonSegment<String>(
                              value: 'frosted',
                              label: Text(context.tr('Frosted')),
                            ),
                            ButtonSegment<String>(
                              value: 'clear',
                              label: Text(context.tr('Clear')),
                            ),
                          ],
                          selected: {_glassStyle},
                          showSelectedIcon: false,
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onSelectionChanged: (sel) {
                            if (sel.isNotEmpty) {
                              _changeGlassStyle(sel.first);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                shrinkWrap: true,
                itemCount: _homeWidgetSpecs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final spec = _homeWidgetSpecs[index];
                  final activeCount = _counts[spec.key] ?? 0;
                  final missingModules = _missingModulesFor(spec.key, modules);

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.deepForest.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: activeCount > 0
                            ? spec.accent.withValues(alpha: 0.45)
                            : AppColors.dewMint.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: spec.accent.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: spec.accent.withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child:
                                  Icon(spec.icon, color: spec.accent, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          context.tr(spec.titleKey),
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.mossShadow
                                              .withValues(alpha: 0.7),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          spec.sizes,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.freshSage,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    context.tr(spec.descKey),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: muted,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (missingModules.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _ModuleDisabledNotice(
                            specKey: spec.key,
                            missingModules: missingModules,
                            onEnable: () => _enableModules(missingModules),
                          ),
                        ],
                        const SizedBox(height: 10),
                        _LiveWidgetMiniPreview(
                          specKey: spec.key,
                          glassStyle: _glassStyle,
                          hideBalance: hideBalance,
                          totalBalance: totalBalance,
                          pulse: pulse,
                          guardrail: guardrail,
                          goalsAndBills: goalsAndBills,
                          templates: templates,
                          goals: goals,
                          transferEnabled: modules.transfer,
                        ),
                        if (activeCount > 0 || _pinSupported) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (activeCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.incomeOnDark
                                        .withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.incomeOnDark
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Text(
                                    context.tr('Active ×{count}', {
                                      'count': activeCount,
                                    }),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.incomeOnDark,
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              if (_pinSupported)
                                OutlinedButton.icon(
                                  onPressed: () => _pinWidget(spec),
                                  icon: const Icon(
                                    Icons.add_to_home_screen_rounded,
                                    size: 15,
                                  ),
                                  label: Text(context.tr('Pin to Home')),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _missingModulesFor(String specKey, ModulePrefs modules) {
    if (specKey == 'budget_guardrail') {
      return modules.budget ? const [] : const ['budget'];
    }
    if (specKey == 'goals_bills') {
      return [
        if (!modules.goals) 'goals',
        if (!modules.recurring) 'recurring',
      ];
    }
    return const [];
  }
}

class _ModuleDisabledNotice extends StatelessWidget {
  const _ModuleDisabledNotice({
    required this.specKey,
    required this.missingModules,
    required this.onEnable,
  });

  final String specKey;
  final List<String> missingModules;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final String msgKey;
    if (specKey == 'budget_guardrail') {
      msgKey = 'Budget module is turned off';
    } else if (missingModules.length == 2) {
      msgKey = 'Goals & Recurring modules are turned off';
    } else if (missingModules.contains('goals')) {
      msgKey = 'Goals module is turned off';
    } else {
      msgKey = 'Recurring module is turned off';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.42),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.tr(msgKey),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
          ),
          TextButton(
            onPressed: onEnable,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.warning,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text(context.tr('Enable')),
          ),
        ],
      ),
    );
  }
}

class _LiveWidgetMiniPreview extends StatelessWidget {
  const _LiveWidgetMiniPreview({
    required this.specKey,
    required this.glassStyle,
    required this.hideBalance,
    required this.totalBalance,
    required this.pulse,
    required this.guardrail,
    required this.goalsAndBills,
    required this.templates,
    required this.goals,
    required this.transferEnabled,
  });

  final String specKey;
  final String glassStyle;
  final bool hideBalance;
  final int totalBalance;
  final DailyPulseResult pulse;
  final BudgetGuardrailSnapshot guardrail;
  final GoalsAndBillsSnapshot goalsAndBills;
  final List<TxTemplate> templates;
  final List<SavingsGoal> goals;
  final bool transferEnabled;

  String _money(int v) => hideBalance ? 'Rp ••••••' : compactRupiah(v);

  @override
  Widget build(BuildContext context) {
    final bgAlpha = switch (glassStyle) {
      'frosted' => 0.78,
      'clear' => 0.56,
      _ => 0.96,
    };
    final borderAlpha = switch (glassStyle) {
      'frosted' => 0.35,
      'clear' => 0.44,
      _ => 0.28,
    };

    // Latar belakang wallpaper botani lembut agar perbedaan Deep / Frosted / Clear langsung tampak
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1F4E43),
            Color(0xFF2B6A58),
            Color(0xFF16332D),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF26503E).withValues(alpha: bgAlpha),
              const Color(0xFF132B21).withValues(alpha: bgAlpha),
            ],
          ),
          border: Border.all(
            color: AppColors.dewMint.withValues(alpha: borderAlpha),
            width: 1,
          ),
        ),
        child: switch (specKey) {
          'daily_pulse' => _buildDailyPulse(context),
          'quick_finance' => _buildQuickFinance(context),
          'quick_action' => _buildQuickAction(context),
          'favorite_templates' => _buildFavorites(context),
          'budget_guardrail' => _buildBudgetGuardrail(context),
          _ => _buildGoalsAndBills(context),
        },
      ),
    );
  }

  Widget _buildDailyPulse(BuildContext context) {
    final tierLabel = switch (pulse.tier) {
      DailyHealthTier.safe => context.tr('Safe'),
      DailyHealthTier.caution => context.tr('Caution'),
      DailyHealthTier.limit => context.tr('Limit'),
    };
    final tierColor = switch (pulse.tier) {
      DailyHealthTier.safe => AppColors.incomeOnDark,
      DailyHealthTier.caution => AppColors.warning,
      DailyHealthTier.limit => AppColors.expenseOnDark,
    };

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.tr('Daily quota'),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.freshSage,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _miniPill(tierLabel, tierColor),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _money(pulse.dailyAllowance),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.softIvory,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              context.tr('Balance'),
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.freshSage,
              ),
            ),
            Text(
              _money(totalBalance),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.dewMint,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickFinance(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "WALL O' PAY",
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
                color: AppColors.freshSage,
              ),
            ),
            Text(
              _money(totalBalance),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.softIvory,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: _miniPill('+ ${context.tr('Income')}', AppColors.incomeOnDark),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _miniPill('- ${context.tr('Expense')}', AppColors.expenseOnDark),
            ),
            if (transferEnabled) ...[
              const SizedBox(width: 5),
              Expanded(
                child: _miniPill('⇄ ${context.tr('Transfer')}', AppColors.dewMint),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAction(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.mossShadow.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.dewMint.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hideBalance
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 11,
                color: AppColors.freshSage,
              ),
              const SizedBox(width: 4),
              Text(
                _money(totalBalance),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.softIvory,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _miniPill('+ In', AppColors.incomeOnDark),
        const SizedBox(width: 4),
        _miniPill('- Out', AppColors.expenseOnDark),
        if (transferEnabled) ...[
          const SizedBox(width: 4),
          _miniPill('⇄', AppColors.dewMint),
        ],
      ],
    );
  }

  Widget _buildFavorites(BuildContext context) {
    final visible = templates.take(3).toList();
    if (visible.isEmpty) {
      return Row(
        children: [
          const Icon(Icons.star_outline_rounded, size: 14, color: AppColors.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              context.tr('Save templates to unlock 1-tap logging'),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.dewMint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: visible.map((t) {
        final color = t.type == TxType.income
            ? AppColors.incomeOnDark
            : AppColors.expenseOnDark;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.mossShadow.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.32)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.name,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.softIvory,
                ),
              ),
              if (t.amount > 0) ...[
                const SizedBox(width: 4),
                Text(
                  _money(t.amount),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBudgetGuardrail(BuildContext context) {
    if (!guardrail.hasConfig) {
      return Text(
        context.tr('No budget set yet'),
        style: const TextStyle(fontSize: 11, color: AppColors.dewMint),
      );
    }

    final pct = guardrail.budgetPct;
    final barColor = switch (guardrail.alertLevel) {
      'over' => AppColors.expenseOnDark,
      'near' => AppColors.warning,
      _ => AppColors.incomeOnDark,
    };
    final rem = (guardrail.totalBudget - guardrail.budgetSpent).clamp(0, 1 << 60);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${context.tr('Remaining')}: ${_money(rem)}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.softIvory,
              ),
            ),
            _miniPill('$pct%', barColor),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: AppColors.mossShadow.withValues(alpha: 0.6),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsAndBills(BuildContext context) {
    final activeGoals = goals
        .where((g) => g.deletedAt == null && g.targetAmount > 0 && g.currentAmount < g.targetAmount)
        .toList();
    if (activeGoals.isEmpty && goalsAndBills.billsDueCount == 0) {
      return Text(
        context.tr('No active goals or bills yet'),
        style: const TextStyle(fontSize: 11, color: AppColors.dewMint),
      );
    }

    final topGoal = activeGoals.isNotEmpty ? activeGoals.first : null;
    final goalPct = topGoal != null
        ? ((topGoal.currentAmount * 100) / topGoal.targetAmount).round().clamp(0, 100)
        : 0;

    return Row(
      children: [
        if (topGoal != null)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${topGoal.name} ($goalPct%)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.softIvory,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (goalPct / 100).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: AppColors.mossShadow.withValues(alpha: 0.6),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF60A5FA),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (topGoal != null && goalsAndBills.billsDueCount > 0)
          const SizedBox(width: 10),
        if (goalsAndBills.billsDueCount > 0)
          _miniPill(
            context.tr('{count} due soon', {
              'count': goalsAndBills.billsDueCount,
            }),
            AppColors.warning,
          ),
      ],
    );
  }

  Widget _miniPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.38), width: 0.7),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
