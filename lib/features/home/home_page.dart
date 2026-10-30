import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/brand.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/icons.dart';
import '../../data/app_database.dart';
import '../../core/l10n.dart';
import '../../core/period.dart';
import '../../core/widgets.dart';
import '../../data/profile.dart';
import '../../data/providers.dart';
import '../../data/tables.dart' show TxType;

import '../profile/profile_page.dart';
import '../settings/settings_page.dart';
import '../more/more_page.dart';
import '../transactions/transaction_form.dart';
import '../transactions/transaction_tile.dart';
import '../../data/cloud.dart';
import '../../data/cloud_sync.dart';
import '../../data/auto_tracker.dart';
import 'pending_inbox_card.dart';
import '../../data/budget_rule.dart';
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
      ref.read(autoTrackerServiceProvider).syncPendingFromNative();
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
      ref.read(autoTrackerServiceProvider).syncPendingFromNative();
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

    void openProfile() => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
        );
    void openSettings() => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
        );

    return Scaffold(
      body: SafeArea(
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

            final budgetTitle = isCurrent
                ? (isWeekly ? "This Week's Budget" : "This Month's Budget")
                : (isWeekly ? 'Weekly Budget' : 'Monthly Budget');

            return RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  ref.read(autoSyncServiceProvider).triggerTwoWaySync(),
                  ref.read(autoTrackerServiceProvider).syncPendingFromNative(),
                  UpdateCheckerService.checkAndNotify(ref, context: context),
                ]);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Row(
                    children: [
                      const BrandMark(size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Wall o' Pay",
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Consumer(
                        builder: (ctx, r, _) {
                          final sync = r.watch(syncStateProvider);
                          if (sync.status == SyncStatus.syncing) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          return IconButton(
                            tooltip: ctx.tr('Sync Now'),
                            icon: const Icon(Icons.sync, size: 20),
                            onPressed: () =>
                                r.read(autoSyncServiceProvider).triggerTwoWaySync(),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: context.tr('Settings'),
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: openSettings,
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    UserAvatar(size: 52, onTap: openProfile),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name != null ? '${greeting()},' : greeting(),
                            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                          ),
                          Text(
                            name ?? context.tr('Your money, under your control.'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Center(child: PeriodTypeToggle()),
                const SizedBox(height: 4),
                const Center(child: PeriodSwitcher(compact: true)),
                const SizedBox(height: 8),
                _BalanceCard(
                  totalBalance: totalBalance,
                  periodFlow: balance,
                  periodLabel: context.tr(isWeekly ? 'Weekly Flow' : 'Monthly Flow'),
                  income: income,
                  expense: expense,
                ),
                const SizedBox(height: 14),
                const _WalletsSection(),
                const SizedBox(height: 14),
                if (updateInfo != null) ...[
                  _UpdateBannerCard(
                    info: updateInfo,
                    onDismiss: () => ref.read(availableUpdateProvider.notifier).dismiss(),
                    onUpdate: () => UpdateCheckerService.showUpdateDialog(context, updateInfo),
                  ),
                  const SizedBox(height: 14),
                ],
                const PendingInboxCard(),
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
                if (isCurrent) ...[
                  const SizedBox(height: 14),
                  AppCard(
                    child: Row(
                      children: [
                        CategoryBadge(
                          icon: Icons.today_outlined,
                          color: scheme.primary,
                          size: 40,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('Safe daily spend'),
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                balance > 0
                                    ? (daysLeft == 1
                                        ? context.tr('1 day left')
                                        : context.tr('{n} days left', {'n': daysLeft}))
                                    : context.tr('Expenses already exceed income'),
                                style: theme.textTheme.bodySmall?.copyWith(color: muted),
                              ),
                            ],
                          ),
                        ),
                        if (balance > 0)
                          Text(
                            context.tr('{amount}/day', {'amount': rupiah(dailyAllowance)}),
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    _QuickAction(
                      icon: Icons.add_circle_outline,
                      label: context.tr('Add Income'),
                      onTap: () => showTransactionForm(context, initialType: TxType.income),
                    ),
                    _QuickAction(
                      icon: Icons.remove_circle_outline,
                      label: context.tr('Add Expense'),
                      onTap: () => showTransactionForm(context, initialType: TxType.expense),
                    ),
                    _QuickAction(
                      icon: Icons.insights_outlined,
                      label: context.tr('Insight'),
                      onTap: () => ref.read(tabIndexProvider.notifier).set(3),
                    ),
                    _QuickAction(
                      icon: Icons.more_horiz,
                      label: context.tr('More'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(builder: (_) => const MorePage()),
                      ),
                    ),
                  ],
                ),
                SectionHeader(
                  title: context.tr('Recent Transactions'),
                  actionLabel: context.tr('See All'),
                  onAction: () => ref.read(tabIndexProvider.notifier).set(1),
                ),
                if (txs.isEmpty)
                  AppCard(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          context.tr('No transactions yet. Tap + to add one.'),
                          style: theme.textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ),
                    ),
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
  });

  final int totalBalance;
  final int periodFlow;
  final String periodLabel;
  final int income;
  final int expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSurplus = periodFlow >= 0;
    final hidden = ref.watch(hideBalanceProvider);

    String money(int v) => hidden ? 'Rp ••••••' : rupiah(v);

    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      context.tr('Total Balance'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        context.tr('All Accounts'),
                        style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
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
          Text(
            money(totalBalance),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
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
                  ': ',
                  style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
                Text(
                  hidden ? '••••••' : (isSurplus ? '+${rupiah(periodFlow)}' : rupiah(periodFlow)),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isSurplus ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
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
                    value: money(income),
                  ),
                ),
                Container(width: 1, height: 36, color: Colors.white24),
                const SizedBox(width: 12),
                Expanded(
                  child: _FlowTile(
                    icon: Icons.arrow_upward,
                    label: context.tr('Expense'),
                    value: money(expense),
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
  const _FlowTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Icon(icon, color: scheme.primary),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
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


class _WalletsSection extends ConsumerWidget {
  const _WalletsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);
    final balances = ref.watch(walletBalancesProvider);
    final hidden = ref.watch(hideBalanceProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return walletsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (wallets) {
        if (wallets.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('Wallets & Accounts'),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: Text(context.tr('Transfer')),
                  onPressed: () => showTransactionForm(context, initialType: TxType.transfer),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: wallets.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) {
                  final w = wallets[i];
                  final bal = balances[w.id] ?? 0;
                  final wColor = Color(w.colorValue);

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showWalletDetails(ctx, ref, w, bal),
                    child: Container(
                      width: 154,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: wColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(iconFor(w.icon), size: 14, color: wColor),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  context.tr(w.name),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            hidden ? 'Rp ••••••' : rupiah(bal),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: bal < 0 ? AppColors.expense : scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showWalletDetails(BuildContext context, WidgetRef ref, Wallet wallet, int currentBalance) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final scheme = theme.colorScheme;
        final wColor = Color(wallet.colorValue);
        final netTx = currentBalance - wallet.initialBalance;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: wColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconFor(wallet.icon), size: 24, color: wColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ctx.tr(wallet.name),
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ref.read(hideBalanceProvider) ? 'Rp ••••••' : rupiah(currentBalance),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: currentBalance < 0 ? AppColors.expense : scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(ctx.tr('Initial Balance:'), style: const TextStyle(fontSize: 13)),
                        Text(
                          rupiah(wallet.initialBalance),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(ctx.tr('Net Transactions:'), style: const TextStyle(fontSize: 13)),
                        Text(
                          '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: netTx >= 0 ? AppColors.income : AppColors.expense,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: Text(ctx.tr('Adjust Balance')),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAdjustBalanceDialog(context, ref, wallet, currentBalance);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.deepForest),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: Text(ctx.tr('Transfer')),
                      onPressed: () {
                        Navigator.pop(ctx);
                        showTransactionForm(context, initialType: TxType.transfer);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAdjustBalanceDialog(
    BuildContext context,
    WidgetRef ref,
    Wallet wallet,
    int currentBalance,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _AdjustBalanceDialog(
        wallet: wallet,
        currentBalance: currentBalance,
        ref: ref,
      ),
    );
  }
}

class _AdjustBalanceDialog extends StatefulWidget {
  const _AdjustBalanceDialog({
    required this.wallet,
    required this.currentBalance,
    required this.ref,
  });

  final Wallet wallet;
  final int currentBalance;
  final WidgetRef ref;

  @override
  State<_AdjustBalanceDialog> createState() => _AdjustBalanceDialogState();
}

class _AdjustBalanceDialogState extends State<_AdjustBalanceDialog> {
  int _mode = 0; // 0: Saldo Saat Ini, 1: Saldo Awal
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: formatThousands(widget.currentBalance),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _switchMode(int mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _controller.text = formatThousands(
        mode == 0 ? widget.currentBalance : widget.wallet.initialBalance,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final wName = context.tr(widget.wallet.name);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(context.tr('Adjust Balance')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _switchMode(0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _mode == 0 ? scheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          context.tr('Current Balance'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _mode == 0 ? scheme.onPrimary : scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _switchMode(1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _mode == 1 ? scheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          context.tr('Initial Balance'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _mode == 1 ? scheme.onPrimary : scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _mode == 0
                  ? context.tr(
                      'Set the actual current balance for {name}. The system will adjust the starting balance automatically so the total matches instantly.',
                      {'name': wName},
                    )
                  : context.tr(
                      'Set the original starting balance for {name} before any transactions took place.',
                      {'name': wName},
                    ),
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, height: 1.35),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: amountFormatters(),
              decoration: appInput(
                context,
                label: _mode == 0 ? context.tr('Current Balance') : context.tr('Initial Balance'),
                prefixText: 'Rp ',
              ),
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.deepForest),
          onPressed: () async {
            final amount = parseAmount(_controller.text);
            if (_mode == 0) {
              final netTx = widget.currentBalance - widget.wallet.initialBalance;
              final newInitial = amount - netTx;
              await widget.ref.read(databaseProvider).updateWalletInitialBalance(widget.wallet.id, newInitial);
            } else {
              await widget.ref.read(databaseProvider).updateWalletInitialBalance(widget.wallet.id, amount);
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(context.tr('Save')),
        ),
      ],
    );
  }
}
