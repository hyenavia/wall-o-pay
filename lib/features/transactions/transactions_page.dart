import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/widgets.dart';
import '../../data/app_database.dart';
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

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionsProvider);
    final cats = ref.watch(categoryMapProvider);
    final wallets = ref.watch(walletMapProvider);

    return Scaffold(
      appBar: pageAppBar(context, title: Text(context.tr('Transactions'))),
      body: txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(context.tr('Could not load data: {error}', {'error': e})),
        ),
        data: (txs) {
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
              const Center(child: PeriodSwitcher()),
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
              if (txs.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: context.tr('No transactions in this period.\nTap + to add your first one.'),
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
