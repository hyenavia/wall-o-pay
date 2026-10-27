import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/brand.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/period.dart';
import '../../core/widgets.dart';
import '../../data/profile.dart';
import '../../data/providers.dart';
import '../../data/tables.dart' show TxType;
import '../insights/insights_page.dart';
import '../profile/profile_page.dart';
import '../settings/settings_page.dart';
import '../transactions/transaction_form.dart';
import '../transactions/transaction_tile.dart';
import '../../data/auto_tracker.dart';
import 'pending_inbox_card.dart';

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

            final totalBudget = budgets.values.fold<int>(0, (a, b) => a + b);
            final budgetSpent =
                budgets.keys.fold<int>(0, (a, id) => a + (spent[id] ?? 0));
            final ratio = totalBudget == 0 ? 0.0 : budgetSpent / totalBudget;

            final daysLeft = period.daysLeft;
            final dailyAllowance =
                balance > 0 && daysLeft > 0 ? balance ~/ daysLeft : 0;
            final isCurrent = period.isCurrent;

            final budgetTitle = isCurrent
                ? (isWeekly ? "This Week's Budget" : "This Month's Budget")
                : (isWeekly ? 'Weekly Budget' : 'Monthly Budget');

            return ListView(
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
                  title: context.tr(isWeekly ? 'Weekly Balance' : 'Monthly Balance'),
                  balance: balance,
                  income: income,
                  expense: expense,
                ),
                const SizedBox(height: 14),
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
                      label: context.tr('Insights'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(builder: (_) => const InsightsPage()),
                      ),
                    ),
                    _QuickAction(
                      icon: Icons.more_horiz,
                      label: context.tr('More'),
                      onTap: openSettings,
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
            );
          },
        ),
      ),
    );
  }
}

class _BalanceCard extends StatefulWidget {
  const _BalanceCard({
    required this.title,
    required this.balance,
    required this.income,
    required this.expense,
  });

  final String title;
  final int balance;
  final int income;
  final int expense;

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard> {
  bool _hidden = false;

  String _money(int v) => _hidden ? 'Rp ••••••' : rupiah(v);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ),
              IconButton(
                tooltip: context.tr(_hidden ? 'Show amounts' : 'Hide amounts'),
                visualDensity: VisualDensity.compact,
                color: Colors.white70,
                icon: Icon(_hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _hidden = !_hidden),
              ),
            ],
          ),
          Text(
            _money(widget.balance),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
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
                    value: _money(widget.income),
                  ),
                ),
                Container(width: 1, height: 36, color: Colors.white24),
                const SizedBox(width: 12),
                Expanded(
                  child: _FlowTile(
                    icon: Icons.arrow_upward,
                    label: context.tr('Expense'),
                    value: _money(widget.expense),
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
