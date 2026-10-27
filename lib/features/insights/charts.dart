import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/period.dart';
import '../../core/theme.dart';
import '../../data/app_database.dart';
import '../../data/tables.dart' show TxType;

class _Slice {
  const _Slice(this.label, this.color, this.value);
  final String label;
  final Color color;
  final int value;
}

/// Komposisi pengeluaran per kategori (5 teratas + sisanya digabung).
class ExpensePieChart extends StatelessWidget {
  const ExpensePieChart({super.key, required this.spent, required this.cats});

  final Map<String, int> spent;
  final Map<String, Category> cats;

  @override
  Widget build(BuildContext context) {
    final total = spent.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final sorted = spent.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final rest = sorted.skip(5).fold<int>(0, (a, e) => a + e.value);
    final slices = <_Slice>[
      for (final e in sorted.take(5))
        _Slice(
          context.tr(cats[e.key]?.name ?? 'Uncategorized'),
          Color(cats[e.key]?.colorValue ?? 0xFF607D8B),
          e.value,
        ),
      if (rest > 0) _Slice(context.tr('Other categories'), Colors.blueGrey, rest),
    ];

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                for (final s in slices)
                  PieChartSectionData(
                    color: s.color,
                    value: s.value.toDouble(),
                    radius: 52,
                    title: s.value / total >= 0.08
                        ? '${(s.value / total * 100).round()}%'
                        : '',
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            for (final s in slices)
              _Dot(color: s.color, label: '${s.label} • ${rupiah(s.value)}'),
          ],
        ),
      ],
    );
  }
}

/// Income vs expense selama 6 bulan yang berakhir di [month].
class TrendBarChart extends StatelessWidget {
  const TrendBarChart({super.key, required this.txs, required this.period});

  final List<TransactionEntry> txs;
  final Period period;

  @override
  Widget build(BuildContext context) {
    final periods = [for (var i = 5; i >= 0; i--) period.shift(-i)];
    final income = List<int>.filled(6, 0);
    final expense = List<int>.filled(6, 0);
    for (final t in txs) {
      final idx = periods.indexWhere((p) => p.contains(t.date));
      if (idx < 0) continue;
      if (t.type == TxType.income) {
        income[idx] += t.amount;
      } else {
        expense[idx] += t.amount;
      }
    }
    final maxValue = [...income, ...expense].fold<int>(0, math.max);
    const hidden = AxisTitles(sideTitles: SideTitles(showTitles: false));

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxValue == 0 ? 1 : maxValue * 1.15,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: hidden,
                topTitles: hidden,
                rightTitles: hidden,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        periods[value.toInt()].shortLabel(),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < 6; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: income[i].toDouble(),
                        color: AppColors.income,
                        width: 9,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      BarChartRodData(
                        toY: expense[i].toDouble(),
                        color: AppColors.expense,
                        width: 9,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Dot(color: AppColors.income, label: context.tr('Income')),
            const SizedBox(width: 16),
            _Dot(color: AppColors.expense, label: context.tr('Expense')),
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
