/// Kumpulan widget grafik visual berbasis `fl_chart` untuk halaman Insight,
/// meliputi diagram lingkaran kategori ([ExpensePieChart]) dan grafik batang tren ([TrendBarChart]).
library;

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/period.dart';
import '../../core/theme.dart';
import '../../data/app_database.dart';
import '../../data/tables.dart' show TxType;
import 'insight_engine.dart';

class _Slice {
  const _Slice(this.categoryId, this.label, this.color, this.value);
  final String? categoryId;
  final String label;
  final Color color;
  final int value;
}

/// Komposisi pengeluaran per kategori (5 teratas + sisanya digabung).
class ExpensePieChart extends StatelessWidget {
  const ExpensePieChart({
    super.key,
    required this.spent,
    required this.cats,
    this.onCategoryTap,
  });

  final Map<String, int> spent;
  final Map<String, Category> cats;
  final ValueChanged<String>? onCategoryTap;

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
          e.key,
          context.tr(cats[e.key]?.name ?? 'Uncategorized'),
          Color(cats[e.key]?.colorValue ?? 0xFF607D8B),
          e.value,
        ),
      if (rest > 0) _Slice(null, context.tr('Other categories'), Colors.blueGrey, rest),
    ];

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 38,
              pieTouchData: onCategoryTap == null
                  ? PieTouchData(enabled: false)
                  : PieTouchData(
                      touchCallback: (event, response) {
                        if (event is FlTapUpEvent &&
                            response?.touchedSection != null) {
                          final idx = response!.touchedSection!.touchedSectionIndex;
                          if (idx >= 0 && idx < slices.length) {
                            final catId = slices[idx].categoryId;
                            if (catId != null) onCategoryTap!(catId);
                          }
                        }
                      },
                    ),
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
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (final s in slices)
              if (s.categoryId != null && onCategoryTap != null)
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onCategoryTap!(s.categoryId!),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: _Dot(
                      color: s.color,
                      label: '${s.label} • ${rupiah(s.value)}',
                    ),
                  ),
                )
              else
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
    const incColor = AppColors.incomeOnDark;
    const expColor = AppColors.expenseOnDark;

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
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.freshSage,
                          fontWeight: FontWeight.w600,
                        ),
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
                        color: incColor,
                        width: 9,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: expense[i].toDouble(),
                        color: expColor,
                        width: 9,
                        borderRadius: BorderRadius.circular(4),
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
            _Dot(color: incColor, label: context.tr('Income')),
            const SizedBox(width: 16),
            _Dot(color: expColor, label: context.tr('Expense')),
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.55),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.freshSage,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Grafik batang pengeluaran harian atau mingguan untuk periode terpilih.
class PeriodExpenseBarChart extends StatefulWidget {
  const PeriodExpenseBarChart({
    super.key,
    required this.points,
    required this.totalExpense,
  });

  final List<ChartPoint> points;
  final int totalExpense;

  @override
  State<PeriodExpenseBarChart> createState() => _PeriodExpenseBarChartState();
}

class _PeriodExpenseBarChartState extends State<PeriodExpenseBarChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final maxAmount = widget.points.fold<int>(0, (m, p) => math.max(m, p.amount));
    final maxY = maxAmount == 0 ? 10000.0 : (maxAmount * 1.25).toDouble();

    const hidden = AxisTitles(sideTitles: SideTitles(showTitles: false));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 0 ? maxY / 3 : 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.borderOutline.withValues(alpha: 0.25),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                enabled: true,
                touchCallback: (event, response) {
                  setState(() {
                    if (event is FlTapUpEvent || event is FlPanEndEvent) {
                      _touchedIndex = null;
                    } else if (response != null && response.spot != null) {
                      _touchedIndex = response.spot!.touchedBarGroupIndex;
                    }
                  });
                },
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => AppColors.mossShadow,
                  tooltipBorder: BorderSide(
                    color: AppColors.dewMint.withValues(alpha: 0.35),
                    width: 1,
                  ),
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final p = widget.points[group.x.toInt()];
                    return BarTooltipItem(
                      '${p.fullLabel}\n',
                      const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: rupiah(rod.toY.toInt()),
                          style: const TextStyle(
                            color: AppColors.dewMint,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: hidden,
                topTitles: hidden,
                rightTitles: hidden,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= widget.points.length) {
                        return const SizedBox.shrink();
                      }
                      final isSelected = _touchedIndex == idx;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          widget.points[idx].label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected ? AppColors.dewMint : AppColors.freshSage,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (int i = 0; i < widget.points.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: widget.points[i].amount.toDouble(),
                        color: _touchedIndex == i
                            ? AppColors.dewMint
                            : (widget.points[i].amount > 0
                                ? const Color(0xFF38B271)
                                : AppColors.borderOutline.withValues(alpha: 0.4)),
                        width: widget.points.length > 7 ? 14 : 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: AppColors.mossShadow.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
