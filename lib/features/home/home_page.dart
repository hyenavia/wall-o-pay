import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/l10n.dart';
import '../../core/period.dart';
import '../../core/widgets.dart';
import '../../data/profile.dart';
import '../../data/providers.dart';
import '../../data/tables.dart' show TxType;

import '../accounts/accounts_page.dart';
import '../profile/profile_page.dart';
import '../settings/settings_page.dart';
import '../more/more_page.dart';
import 'daily_financial_pulse_card.dart';
import '../transactions/transaction_form.dart';
import '../transactions/transaction_tile.dart';
import '../../data/cloud.dart';
import '../../data/cloud_sync.dart';
import '../../data/budget_rule.dart';
import '../../data/module_prefs.dart';
import '../../data/update_checker.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(autoSyncServiceProvider).startSync(user.uid);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(autoSyncServiceProvider).triggerTwoWaySync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final period = ref.watch(selectedPeriodProvider);
    final isWeekly = period.type == PeriodType.weekly;
    final txAsync = ref.watch(transactionsProvider);
    final cats = ref.watch(categoryMapProvider);
    final budgets = ref.watch(budgetByCategoryProvider);
    final spent = ref.watch(spentByCategoryProvider);
    final name = ref.watch(displayNameProvider);
    final muted = scheme.onSurface.withValues(alpha: 0.65);
    final updateInfo = ref.watch(availableUpdateProvider);
    final modules = ref.watch(modulePrefsProvider);

    void openProfile() => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
        );
    void openMore() => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const MorePage()),
        );
    void openSettings() => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
        );

    return Scaffold(
      backgroundColor: AppColors.deepForest,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _HomeHeader(
                name: name,
                onProfile: openProfile,
                onMore: openMore,
                onSettings: openSettings,
              ),
              Expanded(
                child: _Sheet(
                  child: txAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text(context.tr('Could not load data: {error}', {'error': e})),
                    ),
                    data: (txs) {
                      final income = txs
                          .where((t) => t.type == TxType.income)
                          .fold<int>(0, (s, t) => s + t.amount);
                      final expense = txs
                          .where((t) => t.type == TxType.expense)
                          .fold<int>(0, (s, t) => s + t.amount);
                      final balance = income - expense;
                      final totalBalance = ref.watch(totalCurrentBalanceProvider);

                      final budgetPool = ref.watch(currentTotalBudgetPoolProvider);
                      final totalBudget = budgetPool > 0
                          ? budgetPool
                          : budgets.values.fold<int>(0, (a, b) => a + b);
                      final budgetSpent = budgetPool > 0
                          ? expense
                          : budgets.keys.fold<int>(0, (a, id) => a + (spent[id] ?? 0));
                      final ratio = totalBudget == 0 ? 0.0 : budgetSpent / totalBudget;

                      final daysLeft = period.daysLeft;
                      final dailyAllowance =
                          balance > 0 && daysLeft > 0 ? balance ~/ daysLeft : 0;
                      final isCurrent = period.isCurrent;

                      final now = DateTime.now();
                      final todayStart = DateTime(now.year, now.month, now.day);
                      final todayEnd = todayStart.add(const Duration(days: 1));
                      final todayExpense = txs
                          .where((t) =>
                              t.type == TxType.expense &&
                              !t.date.isBefore(todayStart) &&
                              t.date.isBefore(todayEnd))
                          .fold<int>(0, (s, t) => s + t.amount);

                      final budgetTitle = isCurrent
                          ? (isWeekly ? "This Week's Budget" : "This Month's Budget")
                          : (isWeekly ? 'Weekly Budget' : 'Monthly Budget');

                      final savedPct = income > 0
                          ? ((income - expense) * 100 / income).round()
                          : null;

                      return RefreshIndicator(
                        onRefresh: () async {
                          await Future.wait([
                            ref.read(autoSyncServiceProvider).triggerTwoWaySync(),
                            UpdateCheckerService.checkAndNotify(ref, context: context),
                          ]);
                        },
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                          children: [
                            if (updateInfo != null) ...[
                              _UpdateBannerCard(
                                info: updateInfo,
                                onDismiss: () => ref.read(availableUpdateProvider.notifier).dismiss(),
                                onUpdate: () => UpdateCheckerService.showUpdateDialog(context, updateInfo),
                              ),
                              const SizedBox(height: 12),
                            ],
                            const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Expanded(child: PeriodSwitcher(compact: true)),
                                  PeriodTypeToggle(compact: true),
                                ],
                              ),
                            ),
                            _BalanceCard(
                              totalBalance: totalBalance,
                              periodFlow: balance,
                              periodLabel: context.tr(isWeekly ? 'Weekly Flow' : 'Monthly Flow'),
                              income: income,
                              expense: expense,
                              savedPct: savedPct,
                            ),
                            const SizedBox(height: 14),
                            const AccountsSummaryCard(),
                            const SizedBox(height: 14),
                            if (modules.budget) ...[
                              AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            context.tr(budgetTitle),
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                        if (totalBudget > 0)
                                          Text(
                                            context.tr('{pct}% used', {'pct': (ratio * 100).round()}),
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: budgetColor(ratio, scheme),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (totalBudget > 0) ...[
                                      AppProgressBar(value: ratio, color: budgetColor(ratio, scheme)),
                                      const SizedBox(height: 8),
                                      Text(
                                        context.tr('{spent} of {total}', {
                                          'spent': rupiah(budgetSpent),
                                          'total': rupiah(totalBudget),
                                        }),
                                        style: theme.textTheme.bodySmall?.copyWith(color: muted),
                                      ),
                                    ] else
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              context.tr('No budget set yet.'),
                                              style: theme.textTheme.bodySmall?.copyWith(color: muted),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => ref.read(tabIndexProvider.notifier).set(2),
                                            child: Text(context.tr('Set budget')),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (isCurrent) ...[
                              DailyFinancialPulseCard(
                                dailyAllowance: dailyAllowance,
                                todayExpense: todayExpense,
                                daysLeft: daysLeft,
                                balance: balance,
                                totalBudget: totalBudget,
                                budgetSpent: budgetSpent,
                                txCount: txs.length,
                              ),
                              const SizedBox(height: 14),
                            ],
                            SectionHeader(
                              title: context.tr('Recent Transactions'),
                              actionLabel: context.tr('See All'),
                              onAction: () => ref.read(tabIndexProvider.notifier).set(1),
                            ),
                            if (txs.isEmpty)
                              EmptyStateCard(
                                title: context.tr('Start recording your first transaction!'),
                                subtitle: context.tr(
                                  'Every small transaction brings you closer to your financial goals.',
                                ),
                                actionLabel: context.tr('Add transaction'),
                                onAction: () => showTransactionForm(context),
                              )
                            else
                              TransactionGroupCard(
                                children: [
                                  for (final t in txs.take(4))
                                    TransactionTile(
                                      entry: t,
                                      category: cats[t.categoryId],
                                      trailingNote: shortDate(t.date),
                                      onTap: () => showTransactionForm(context, entry: t),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header hijau di Beranda: foto, sapaan, status sinkronisasi, menu lainnya, dan pengaturan.
class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({
    required this.name,
    required this.onProfile,
    required this.onMore,
    required this.onSettings,
  });

  final String? name;
  final VoidCallback onProfile;
  final VoidCallback onMore;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sync = ref.watch(syncStateProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 8, 20),
      child: Row(
        children: [
          UserAvatar(size: 48, onTap: onProfile),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        greeting(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (sync.status == SyncStatus.syncing) ...[
                      const SizedBox(width: 6),
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  (name != null && name!.trim().isNotEmpty)
                      ? name!.trim()
                      : context.tr('Wall o\' Pay'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.tr('More Features'),
            color: Colors.white,
            icon: const Icon(Icons.grid_view_rounded, size: 22),
            onPressed: onMore,
          ),
          IconButton(
            tooltip: context.tr('Settings'),
            color: Colors.white,
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

/// Lembar background berujung melengkung di bawah header hijau.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.white,
              Colors.white,
            ],
            stops: [0.0, 0.028, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: child,
      ),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard({
    required this.totalBalance,
    required this.periodFlow,
    required this.periodLabel,
    required this.income,
    required this.expense,
    this.savedPct,
  });

  final int totalBalance;
  final int periodFlow;
  final String periodLabel;
  final int income;
  final int expense;
  final int? savedPct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSurplus = periodFlow >= 0;
    final hidden = ref.watch(hideBalanceProvider);

    Widget blurred(Widget child) => hidden
        ? ClipRect(child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: child))
        : child;

    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('Total Balance'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (savedPct != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+$savedPct% ${context.tr('saved')}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              IconButton(
                tooltip: context.tr(hidden ? 'Show amounts' : 'Hide amounts'),
                visualDensity: VisualDensity.compact,
                color: Colors.white70,
                icon: Icon(hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => ref.read(hideBalanceProvider.notifier).toggle(),
              ),
            ],
          ),
          const SizedBox(height: 2),
          blurred(
            Text(
              rupiah(totalBalance),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSurplus ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 15,
                  color: isSurplus ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                ),
                const SizedBox(width: 6),
                Text(
                  '$periodLabel: ',
                  style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
                blurred(
                  Text(
                    isSurplus ? '+${rupiah(periodFlow)}' : rupiah(periodFlow),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSurplus ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _FlowTile(
                    icon: Icons.arrow_downward,
                    label: context.tr('Income'),
                    value: rupiah(income),
                    blurred: hidden,
                  ),
                ),
                Container(width: 1, height: 36, color: Colors.white24),
                const SizedBox(width: 12),
                Expanded(
                  child: _FlowTile(
                    icon: Icons.arrow_upward,
                    label: context.tr('Expense'),
                    value: rupiah(expense),
                    blurred: hidden,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowTile extends StatelessWidget {
  const _FlowTile({required this.icon, required this.label, required this.value, this.blurred = false});

  final IconData icon;
  final String label;
  final String value;
  final bool blurred;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueWidget = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
    return Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: Colors.white.withValues(alpha: 0.14),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
              blurred
                  ? ClipRect(child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: valueWidget))
                  : valueWidget,
            ],
          ),
        ),
      ],
    );
  }
}

class _UpdateBannerCard extends StatelessWidget {
  const _UpdateBannerCard({
    required this.info,
    required this.onDismiss,
    required this.onUpdate,
  });

  final AppUpdateInfo info;
  final VoidCallback onDismiss;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.deepForest,
            Color(0xFF2C5A47),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepForest.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onUpdate,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.tr('Update Available (v{version})!', {
                                'version': info.latestVersion,
                              }),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: onDismiss,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr(
                            'A new version of Wall o\' Pay is ready with performance improvements and updates.'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'v${info.currentVersion} ➔ v${info.latestVersion}',
                            style: const TextStyle(
                              color: Color(0xFF6EE7B7),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  context.tr('Update Now'),
                                  style: const TextStyle(
                                    color: AppColors.deepForest,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: AppColors.deepForest,
                                  size: 13,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

