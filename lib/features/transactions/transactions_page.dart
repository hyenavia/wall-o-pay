import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_database.dart';
import '../../data/feature_providers.dart';
import '../../data/providers.dart';
import '../../data/tables.dart' show TxType;
import 'transaction_form.dart';
import 'transaction_tile.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  String _query = '';
  TxType? _filter;
  DateTimeRange? _range;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = _range == null
        ? ref.watch(transactionsProvider)
        : ref.watch(rangeTransactionsProvider(_range!));
    final cats = ref.watch(categoryMapProvider);
    final wallets = ref.watch(walletMapProvider);

    return Scaffold(
      appBar: pageAppBar(
        context,
        title: Text(context.tr('Transactions')),
        actions: [
          IconButton(
            tooltip: context.tr('Filter by date range'),
            icon: Icon(
              Icons.date_range,
              color: _range == null ? null : Theme.of(context).colorScheme.primary,
            ),
            onPressed: _pickRange,
          ),
        ],
      ),
      body: txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(context.tr('Could not load data: {error}', {'error': e})),
        ),
        data: (txs) {
          final totalIncome = txs
              .where((t) => t.type == TxType.income)
              .fold<int>(0, (a, t) => a + t.amount);
          final totalExpense = txs
              .where((t) => t.type == TxType.expense)
              .fold<int>(0, (a, t) => a + t.amount);

          final shown = txs.where((t) {
            if (_filter != null && t.type != _filter) return false;
            if (_query.isEmpty) return true;
            final name = cats[t.categoryId]?.name.toLowerCase() ?? '';
            return name.contains(_query) || t.note.toLowerCase().contains(_query);
          }).toList();

          // Kelompokkan per hari (urutan sudah dari terbaru).
          final groups = <DateTime, List<TransactionEntry>>{};
          for (final t in shown) {
            final day = DateTime(t.date.year, t.date.month, t.date.day);
            groups.putIfAbsent(day, () => []).add(t);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              if (_range == null)
                const Center(child: PeriodSwitcher())
              else
                Center(
                  child: InputChip(
                    avatar: const Icon(Icons.date_range, size: 18),
                    label: Text('${shortDate(_range!.start)} - ${shortDate(_range!.end)}'),
                    onDeleted: () => setState(() => _range = null),
                  ),
                ),
              const SizedBox(height: 4),
              TextField(
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                decoration: appInput(
                  context,
                  hint: context.tr('Search transaction...'),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in <(String, TxType?)>[
                      (context.tr('All'), null),
                      (context.tr('Expense'), TxType.expense),
                      (context.tr('Income'), TxType.income),
                      (context.tr('Transfer'), TxType.transfer),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AppChip(
                          label: f.$1,
                          selected: _filter == f.$2,
                          onSelected: () => setState(() => _filter = f.$2),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      label: context.tr('Total Income'),
                      value: rupiah(totalIncome),
                      color: AppColors.income,
                      icon: Icons.arrow_downward,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryTile(
                      label: context.tr('Total Expense'),
                      value: rupiah(totalExpense),
                      color: AppColors.expense,
                      icon: Icons.arrow_upward,
                    ),
                  ),
                ],
              ),
              if (txs.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: EmptyStateCard(
                    title: context.tr('Start recording your first transaction!'),
                    subtitle: context.tr(
                      'Every small transaction brings you closer to your financial goals.',
                    ),
                    actionLabel: context.tr('Add Transaction'),
                    onAction: () => showTransactionForm(context),
                  ),
                )
              else if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: EmptyState(
                    icon: Icons.search_off,
                    message: context.tr('No matching transactions.'),
                  ),
                )
              else
                for (final entry in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 18, bottom: 8),
                    child: Text(
                      dayHeader(entry.key),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.65),
                          ),
                    ),
                  ),
                  TransactionGroupCard(
                    children: [
                      for (final t in entry.value)
                        TransactionTile(
                          entry: t,
                          category: cats[t.categoryId],
                          wallet: t.walletId != null ? wallets[t.walletId!] : null,
                          toWallet: t.toWalletId != null ? wallets[t.toWalletId!] : null,
                          trailingNote: timeLabel(t.createdAt),
                          onTap: () => showTransactionForm(context, entry: t),
                        ),
                    ],
                  ),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CategoryBadge(icon: icon, color: color, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
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
