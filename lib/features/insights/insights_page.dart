import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/period.dart';
import '../../core/widgets.dart';
import '../../data/app_database.dart';
import '../../data/providers.dart';
import 'charts.dart';

/// Ringkasan visual: pengeluaran per kategori, komposisi, dan tren 6 bulan.
class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final period = ref.watch(selectedPeriodProvider);
    final cats = ref.watch(categoryMapProvider);
    final budgets = ref.watch(budgetByCategoryProvider);
    final spent = ref.watch(spentByCategoryProvider);
    final trend = ref.watch(trendTransactionsProvider).maybeWhen(
          data: (list) => list,
          orElse: () => const <TransactionEntry>[],
        );

    final total = spent.values.fold<int>(0, (a, b) => a + b);
    final entries = spent.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: pageAppBar(context, title: Text(context.tr('Insights'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          const Center(child: PeriodSwitcher()),
          SectionHeader(title: context.tr('Spending by category')),
          if (entries.isEmpty)
            AppCard(child: Text(context.tr('No expenses in this period.')))
          else
            AppCard(
              child: Column(
                children: [
                  for (final e in entries)
                    _CategoryRow(
                      name: categoryName(context, cats[e.key]),
                      icon: iconFor(cats[e.key]?.icon ?? 'more'),
                      color: Color(cats[e.key]?.colorValue ?? 0xFF607D8B),
                      spent: e.value,
                      budget: budgets[e.key],
                      totalExpense: total,
                      scheme: scheme,
                    ),
                ],
              ),
            ),
          if (total > 0) ...[
            SectionHeader(title: context.tr('Expense breakdown')),
            AppCard(child: ExpensePieChart(spent: spent, cats: cats)),
          ],
          SectionHeader(
            title: context.tr(
              period.type == PeriodType.weekly ? 'Last 6 weeks' : 'Last 6 months',
            ),
          ),
          AppCard(child: TrendBarChart(txs: trend, period: period)),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.name,
    required this.icon,
    required this.color,
    required this.spent,
    required this.budget,
    required this.totalExpense,
    required this.scheme,
  });

  final String name;
  final IconData icon;
  final Color color;
  final int spent;
  final int? budget;
  final int totalExpense;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final hasBudget = budget != null && budget! > 0;
    final base = hasBudget ? budget! : totalExpense;
    final ratio = base == 0 ? 0.0 : spent / base;
    final barColor = hasBudget ? budgetColor(ratio, scheme) : color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryBadge(icon: icon, color: color, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text(name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Text(
                hasBudget ? '${rupiah(spent)} / ${rupiah(budget!)}' : rupiah(spent),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: hasBudget && ratio > 1 ? barColor : null,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppProgressBar(value: ratio, color: barColor),
        ],
      ),
    );
  }
}
