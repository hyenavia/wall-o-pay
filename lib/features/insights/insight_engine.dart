/// Mesin kalkulasi analitik deterministik ([InsightEngine]) yang mengolah daftar transaksi
/// menjadi ringkasan metrik ([InsightSummary]), perincian kategori ([CategoryInsight]),
/// titik grafik ([ChartPoint]), serta kartu wawasan pintar ([SmartInsightItem]).
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/period.dart';
import '../../core/theme.dart';
import '../../data/app_database.dart';
import '../../data/tables.dart' show DebtDirection, NeedWant, TxType;

class InsightSummary {
  const InsightSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.savingsRate,
    required this.prevTotalIncome,
    required this.prevTotalExpense,
    required this.expenseDiff,
    required this.expensePctChange,
    required this.txCount,
    required this.expenseTxCount,
  });

  final int totalIncome;
  final int totalExpense;
  final int netBalance;
  final double savingsRate;
  final int prevTotalIncome;
  final int prevTotalExpense;
  final int expenseDiff;
  final double? expensePctChange;
  final int txCount;
  final int expenseTxCount;

  bool get isDeficit => netBalance < 0;
  bool get hasExpenses => totalExpense > 0;
  bool get isLowData => expenseTxCount < 3;
}

class CategoryInsight {
  const CategoryInsight({
    required this.categoryId,
    required this.name,
    required this.color,
    required this.icon,
    required this.amount,
    required this.percentage,
    required this.txCount,
    required this.prevAmount,
    required this.amountChange,
    required this.pctChange,
  });

  final String categoryId;
  final String name;
  final Color color;
  final String icon;
  final int amount;
  final double percentage;
  final int txCount;
  final int prevAmount;
  final int amountChange;
  final double? pctChange;
}

class ChartPoint {
  const ChartPoint({
    required this.label,
    required this.fullLabel,
    required this.amount,
  });

  final String label;
  final String fullLabel;
  final int amount;
}

class SmartInsightItem {
  const SmartInsightItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    this.badge,
    this.filterCategoryId,
    this.filterType,
    this.filterNeedWant,
    this.maxAmount,
    this.targetTransactionId,
    this.filterDay,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String? badge;
  final String? filterCategoryId;
  final TxType? filterType;
  final NeedWant? filterNeedWant;
  final int? maxAmount;
  final String? targetTransactionId;
  final DateTime? filterDay;

  bool get hasDrillDown =>
      filterCategoryId != null ||
      filterType != null ||
      filterNeedWant != null ||
      maxAmount != null ||
      targetTransactionId != null ||
      filterDay != null;
}

class RecapCategoryItem {
  const RecapCategoryItem({
    required this.categoryId,
    required this.name,
    required this.colorValue,
    required this.icon,
    required this.amount,
    required this.percentage,
    required this.txCount,
  });

  final String categoryId;
  final String name;
  final int colorValue;
  final String icon;
  final int amount;
  final double percentage;
  final int txCount;
}

class RecapCategoryHighlight {
  const RecapCategoryHighlight({
    required this.categoryId,
    required this.name,
    required this.diffAmount,
    required this.pctChange,
  });

  final String categoryId;
  final String name;
  final int diffAmount;
  final double pctChange;
}

class RecapPeriodSummary {
  const RecapPeriodSummary({
    required this.period,
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.savingsRate,
    required this.needTotal,
    required this.wantTotal,
    required this.expensePctChange,
    required this.topCategories,
    required this.topSavingCategory,
    required this.topSurgeCategory,
    required this.totalTxCount,
    required this.activeGoalsCount,
    required this.goalsSavedTotal,
    required this.goalsTargetTotal,
  });

  final Period period;
  final int totalIncome;
  final int totalExpense;
  final int netSavings;
  final double savingsRate;
  final int needTotal;
  final int wantTotal;
  final double? expensePctChange;
  final List<RecapCategoryItem> topCategories;
  final RecapCategoryHighlight? topSavingCategory;
  final RecapCategoryHighlight? topSurgeCategory;
  final int totalTxCount;
  final int activeGoalsCount;
  final int goalsSavedTotal;
  final int goalsTargetTotal;

  bool get isDeficit => netSavings < 0;
  bool get hasData => totalTxCount > 0;
  bool get isWeekly => period.type == PeriodType.weekly;
}

/// Ringkasan kekayaan bersih (Net Worth) tanpa penghitungan ganda atas alokasi goal tabungan.
class NetWorthSummary {
  const NetWorthSummary({
    required this.liquidAssets,
    required this.receivables,
    required this.liabilities,
    required this.allocatedGoalReserve,
  });

  final int liquidAssets;
  final int receivables;
  final int liabilities;
  final int allocatedGoalReserve;

  int get netWorth => liquidAssets + receivables - liabilities;
}

enum VitalityTier { starter, fragile, needsCare, steadyGrowth, thriving }

class VitalityPillar {
  const VitalityPillar({
    required this.id,
    required this.labelKey,
    required this.score,
    required this.maxScore,
    required this.active,
    required this.detailKey,
    this.detailArgs = const <String, Object>{},
  });

  final String id;
  final String labelKey;
  final double score;
  final double maxScore;
  final bool active;
  final String detailKey;
  final Map<String, Object> detailArgs;

  double get ratio => maxScore > 0 ? (score / maxScore).clamp(0.0, 1.0) : 0.0;
}

class VitalityScoreSummary {
  const VitalityScoreSummary({
    required this.score,
    required this.hasEnoughData,
    required this.tier,
    required this.pillars,
    required this.activePillarCount,
  });

  final int score;
  final bool hasEnoughData;
  final VitalityTier tier;
  final List<VitalityPillar> pillars;
  final int activePillarCount;
}

/// Kelas statis pengolah data transaksi menjadi metrik statistik dan rekomendasi keuangan.
class InsightEngine {
  static InsightSummary computeSummary({
    required List<TransactionEntry> currentTxs,
    required List<TransactionEntry> prevTxs,
  }) {
    int curIncome = 0;
    int curExpense = 0;
    int curExpCount = 0;

    for (final t in currentTxs) {
      if (t.type == TxType.income) {
        curIncome += t.amount;
      } else if (t.type == TxType.expense) {
        curExpense += t.amount;
        curExpCount++;
      }
    }

    int prevIncome = 0;
    int prevExpense = 0;
    for (final t in prevTxs) {
      if (t.type == TxType.income) {
        prevIncome += t.amount;
      } else if (t.type == TxType.expense) {
        prevExpense += t.amount;
      }
    }

    final net = curIncome - curExpense;
    final savingsRate = curIncome > 0 && net > 0 ? (net / curIncome) * 100 : 0.0;
    final diff = curExpense - prevExpense;
    final pctChange = prevExpense > 0 ? (diff / prevExpense) * 100 : null;

    return InsightSummary(
      totalIncome: curIncome,
      totalExpense: curExpense,
      netBalance: net,
      savingsRate: savingsRate,
      prevTotalIncome: prevIncome,
      prevTotalExpense: prevExpense,
      expenseDiff: diff,
      expensePctChange: pctChange,
      txCount: currentTxs.length,
      expenseTxCount: curExpCount,
    );
  }

  static List<CategoryInsight> computeCategories({
    required BuildContext context,
    required List<TransactionEntry> currentTxs,
    required List<TransactionEntry> prevTxs,
    required Map<String, Category> categoryMap,
    required int totalExpense,
  }) {
    final catCurrent = <String, int>{};
    final catCounts = <String, int>{};
    for (final t in currentTxs) {
      if (t.type == TxType.expense) {
        catCurrent[t.categoryId] = (catCurrent[t.categoryId] ?? 0) + t.amount;
        catCounts[t.categoryId] = (catCounts[t.categoryId] ?? 0) + 1;
      }
    }

    final catPrev = <String, int>{};
    for (final t in prevTxs) {
      if (t.type == TxType.expense) {
        catPrev[t.categoryId] = (catPrev[t.categoryId] ?? 0) + t.amount;
      }
    }

    final list = <CategoryInsight>[];
    catCurrent.forEach((catId, amount) {
      final cat = categoryMap[catId];
      final name = context.tr(cat?.name ?? 'Uncategorized');
      final color = Color(cat?.colorValue ?? 0xFF607D8B);
      final icon = cat?.icon ?? 'more';
      final percentage = totalExpense > 0 ? (amount / totalExpense) * 100 : 0.0;
      final prevAmt = catPrev[catId] ?? 0;
      final change = amount - prevAmt;
      final pct = prevAmt > 0 ? (change / prevAmt) * 100 : null;

      list.add(CategoryInsight(
        categoryId: catId,
        name: name,
        color: color,
        icon: icon,
        amount: amount,
        percentage: percentage,
        txCount: catCounts[catId] ?? 0,
        prevAmount: prevAmt,
        amountChange: change,
        pctChange: pct,
      ));
    });

    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  static List<ChartPoint> computeChartPoints({
    required List<TransactionEntry> currentTxs,
    required Period period,
  }) {
    final loc = AppLocale.code;
    final expTxs = currentTxs.where((t) => t.type == TxType.expense).toList();

    if (period.type == PeriodType.weekly) {
      // 7 days
      final points = <ChartPoint>[];
      for (int i = 0; i < 7; i++) {
        final d = DateTime(period.start.year, period.start.month, period.start.day + i);
        final daySum = expTxs
            .where((t) =>
                t.date.year == d.year &&
                t.date.month == d.month &&
                t.date.day == d.day)
            .fold<int>(0, (s, t) => s + t.amount);
        final shortLabel = DateFormat('E', loc).format(d);
        final fullLabel = DateFormat('EEEE, d MMM', loc).format(d);
        points.add(ChartPoint(
          label: shortLabel,
          fullLabel: fullLabel,
          amount: daySum,
        ));
      }
      return points;
    } else {
      // Monthly view: group into 7-day slices relative to period.start (supports custom payday)
      final points = <ChartPoint>[];
      var sliceStart = DateTime(period.start.year, period.start.month, period.start.day);
      var index = 0;

      while (sliceStart.isBefore(period.end)) {
        index++;
        final nextStart = DateTime(sliceStart.year, sliceStart.month, sliceStart.day + 7);
        final sliceEnd = nextStart.isBefore(period.end) ? nextStart : period.end;
        final lastDayInSlice = DateTime(sliceEnd.year, sliceEnd.month, sliceEnd.day - 1);

        final weekSum = expTxs
            .where((t) => !t.date.isBefore(sliceStart) && t.date.isBefore(sliceEnd))
            .fold<int>(0, (s, t) => s + t.amount);

        final label = 'W$index';
        final fullLabel = sliceStart.month == lastDayInSlice.month
            ? '${sliceStart.day} – ${lastDayInSlice.day} ${DateFormat('MMM', loc).format(sliceStart)}'
            : '${DateFormat('d MMM', loc).format(sliceStart)} – ${DateFormat('d MMM', loc).format(lastDayInSlice)}';
        points.add(ChartPoint(
          label: label,
          fullLabel: fullLabel,
          amount: weekSum,
        ));

        sliceStart = sliceEnd;
      }
      return points;
    }
  }

  /// Menyaring daftar transaksi periode aktif sesuai konteks filter kartu [item].
  static List<TransactionEntry> filterTransactionsForInsight(
    SmartInsightItem item,
    List<TransactionEntry> currentTxs,
  ) {
    if (!item.hasDrillDown) return const <TransactionEntry>[];
    final filtered = currentTxs.where((t) {
      if (item.targetTransactionId != null && t.id != item.targetTransactionId) {
        return false;
      }
      if (item.filterType != null && t.type != item.filterType) {
        return false;
      }
      if (item.filterCategoryId != null && t.categoryId != item.filterCategoryId) {
        return false;
      }
      if (item.filterNeedWant != null && t.needWant != item.filterNeedWant) {
        return false;
      }
      if (item.maxAmount != null && (t.amount <= 0 || t.amount > item.maxAmount!)) {
        return false;
      }
      if (item.filterDay != null &&
          (t.date.year != item.filterDay!.year ||
              t.date.month != item.filterDay!.month ||
              t.date.day != item.filterDay!.day)) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
    });
    return filtered;
  }

  static List<SmartInsightItem> generateSmartInsights({
    required BuildContext context,
    required InsightSummary summary,
    required List<CategoryInsight> categories,
    required List<TransactionEntry> currentTxs,
    required Period period,
    required Map<String, Category> categoryMap,
  }) {
    final insights = <SmartInsightItem>[];
    final isWeekly = period.type == PeriodType.weekly;
    final periodName = isWeekly ? context.tr('week') : context.tr('month');
    final prevPeriodName = isWeekly ? context.tr('last week') : context.tr('last month');

    // 1. Cashflow & Savings rate insight
    if (summary.totalIncome > 0 && summary.netBalance > 0) {
      insights.add(SmartInsightItem(
        title: context.tr('Positive Cashflow & Savings'),
        description: context.tr(
          'You managed to save {pct}% ({amount}) of your total income this period.',
          {
            'pct': summary.savingsRate.toStringAsFixed(1),
            'amount': rupiah(summary.netBalance),
          },
        ),
        icon: Icons.savings_outlined,
        accentColor: AppColors.income,
        badge: context.tr('{pct}% Saved', {'pct': summary.savingsRate.toStringAsFixed(0)}),
        filterType: TxType.income,
      ));
    } else if (summary.isDeficit && summary.totalIncome > 0) {
      insights.add(SmartInsightItem(
        title: context.tr('Spending Exceeded Income'),
        description: context.tr(
          'Total spending exceeded income by {amount}. Review your secondary expenses to keep your cashflow healthy.',
          {'amount': rupiah(summary.netBalance.abs())},
        ),
        icon: Icons.warning_amber_rounded,
        accentColor: AppColors.expense,
        badge: context.tr('Deficit'),
        filterType: TxType.expense,
      ));
    }

    // 2. Category Shift (Significant surge or drop vs previous period)
    CategoryInsight? maxIncreaseCat;
    double maxIncreasePct = 0;
    CategoryInsight? maxSavedCat;
    double maxSavedPct = 0;

    for (final c in categories) {
      if (c.pctChange != null) {
        if (c.pctChange! > maxIncreasePct && c.amountChange >= 10000) {
          maxIncreasePct = c.pctChange!;
          maxIncreaseCat = c;
        } else if (c.pctChange! < maxSavedPct && c.amountChange.abs() >= 10000) {
          maxSavedPct = c.pctChange!;
          maxSavedCat = c;
        }
      }
    }

    if (maxIncreaseCat != null && maxIncreasePct >= 10) {
      final catName = context.tr(maxIncreaseCat.name);
      insights.add(SmartInsightItem(
        title: context.tr('Category Surge: {category}', {'category': catName}),
        description: context.tr(
          '{category} spending increased by {pct}% (+{diff}) compared to {prev}.',
          {
            'category': catName,
            'pct': maxIncreasePct.toStringAsFixed(0),
            'diff': rupiah(maxIncreaseCat.amountChange),
            'prev': prevPeriodName,
          },
        ),
        icon: Icons.trending_up_rounded,
        accentColor: AppColors.warning,
        badge: '+${maxIncreasePct.toStringAsFixed(0)}%',
        filterCategoryId: maxIncreaseCat.categoryId,
        filterType: TxType.expense,
      ));
    } else if (maxSavedCat != null && maxSavedPct <= -10) {
      final catName = context.tr(maxSavedCat.name);
      insights.add(SmartInsightItem(
        title: context.tr('Savings: {category}', {'category': catName}),
        description: context.tr(
          'Great job! {category} spending was cut by {pct}% (saved {saved}) compared to {prev}.',
          {
            'category': catName,
            'pct': maxSavedPct.abs().toStringAsFixed(0),
            'saved': rupiah(maxSavedCat.amountChange.abs()),
            'prev': prevPeriodName,
          },
        ),
        icon: Icons.trending_down_rounded,
        accentColor: AppColors.income,
        badge: '-${maxSavedPct.abs().toStringAsFixed(0)}%',
        filterCategoryId: maxSavedCat.categoryId,
        filterType: TxType.expense,
      ));
    }

    // 3. Dominant Category
    if (categories.isNotEmpty && categories.first.percentage >= 35) {
      final top = categories.first;
      final topCatName = context.tr(top.name);
      insights.add(SmartInsightItem(
        title: context.tr('Spending Hub: {category}', {'category': topCatName}),
        description: context.tr(
          '{category} accounted for the largest share at {pct}% ({amount}) of all spending this {period}.',
          {
            'category': topCatName,
            'pct': top.percentage.toStringAsFixed(1),
            'amount': rupiah(top.amount),
            'period': periodName,
          },
        ),
        icon: Icons.pie_chart_outline_rounded,
        accentColor: top.color,
        badge: context.tr('{pct}% of Total', {'pct': top.percentage.toStringAsFixed(0)}),
        filterCategoryId: top.categoryId,
        filterType: TxType.expense,
      ));
    }

    // 4. Largest single transaction
    final expTxs = currentTxs.where((t) => t.type == TxType.expense).toList();
    if (expTxs.isNotEmpty) {
      final largest = expTxs.reduce((a, b) => a.amount > b.amount ? a : b);
      final cat = categoryMap[largest.categoryId];
      final catName = context.tr(cat?.name ?? 'Uncategorized');
      final dateStr = DateFormat('d MMM', AppLocale.code).format(largest.date);
      final noteStr = largest.note.isNotEmpty ? ' ("${largest.note}")' : '';

      insights.add(SmartInsightItem(
        title: context.tr('Largest Transaction'),
        description: context.tr(
          'The largest purchase this period was {cat}{note} for {amount} on {date}.',
          {
            'cat': catName,
            'note': noteStr,
            'amount': rupiah(largest.amount),
            'date': dateStr,
          },
        ),
        icon: Icons.receipt_long_rounded,
        accentColor: AppColors.sage,
        targetTransactionId: largest.id,
      ));
    }

    // 5. Peak Spending Day (if at least 2 distinct days of spending)
    final daysMap = <int, int>{};
    final dayDateMap = <int, DateTime>{};
    for (final t in expTxs) {
      final key = t.date.year * 10000 + t.date.month * 100 + t.date.day;
      daysMap[key] = (daysMap[key] ?? 0) + t.amount;
      dayDateMap[key] = t.date;
    }

    if (daysMap.length >= 2) {
      int peakKey = daysMap.keys.first;
      int peakAmount = 0;
      daysMap.forEach((k, v) {
        if (v > peakAmount) {
          peakAmount = v;
          peakKey = k;
        }
      });
      final peakDate = dayDateMap[peakKey]!;
      final dayName = DateFormat('EEEE, d MMM', AppLocale.code).format(peakDate);

      insights.add(SmartInsightItem(
        title: context.tr('Peak Spending Day'),
        description: context.tr(
          'Busiest spending occurred on {day} with total expenditure of {amount}.',
          {
            'day': dayName,
            'amount': rupiah(peakAmount),
          },
        ),
        icon: Icons.calendar_today_rounded,
        accentColor: AppColors.warning,
        filterType: TxType.expense,
        filterDay: DateTime(peakDate.year, peakDate.month, peakDate.day),
      ));
    }

    // 6. Needs vs Wants Insight (jika ada transaksi yang ditandai)
    int needTotal = 0;
    int wantTotal = 0;
    for (final t in expTxs) {
      if (t.needWant == NeedWant.need) needTotal += t.amount;
      if (t.needWant == NeedWant.want) wantTotal += t.amount;
    }
    if (needTotal + wantTotal > 0) {
      final totalTagged = needTotal + wantTotal;
      final wantPct = ((wantTotal / totalTagged) * 100).round();
      if (wantPct > 40) {
        insights.add(SmartInsightItem(
          title: context.tr('High Proportion of Wants'),
          description: context.tr(
            '{pct}% of tagged spending was allocated to wants ({amount}). Consider evaluating non-essential spending to increase savings.',
            {'pct': '$wantPct', 'amount': rupiah(wantTotal)},
          ),
          icon: Icons.favorite_border,
          accentColor: const Color(0xFFEF9A9A),
          badge: context.tr('{pct}% Wants', {'pct': '$wantPct'}),
          filterType: TxType.expense,
          filterNeedWant: NeedWant.want,
        ));
      } else {
        insights.add(SmartInsightItem(
          title: context.tr('Balanced Needs Allocation'),
          description: context.tr(
            '{pct}% of spending was allocated to essential needs ({amount}). Your core spending habits are well on track!',
            {'pct': '${100 - wantPct}', 'amount': rupiah(needTotal)},
          ),
          icon: Icons.check_circle_outline,
          accentColor: AppColors.sage,
          badge: context.tr('{pct}% Needs', {'pct': '${100 - wantPct}'}),
          filterType: TxType.expense,
          filterNeedWant: NeedWant.need,
        ));
      }
    }

    // 7. Frequent Small Purchases ("Latte Factor" <= Rp 50.000, >= 3x)
    const microThreshold = 50000;
    final microTxs = expTxs.where((t) => t.amount > 0 && t.amount <= microThreshold).toList();
    if (microTxs.length >= 3) {
      final microTotal = microTxs.fold<int>(0, (sum, t) => sum + t.amount);
      final microCatCounts = <String, int>{};
      for (final t in microTxs) {
        microCatCounts[t.categoryId] = (microCatCounts[t.categoryId] ?? 0) + 1;
      }
      String topMicroCatId = microCatCounts.keys.first;
      int topMicroCount = 0;
      microCatCounts.forEach((catId, count) {
        if (count > topMicroCount) {
          topMicroCount = count;
          topMicroCatId = catId;
        }
      });
      final topMicroCatName = context.tr(categoryMap[topMicroCatId]?.name ?? 'Uncategorized');
      insights.add(SmartInsightItem(
        title: context.tr('Frequent Small Purchases'),
        description: context.tr(
          'You made {count} small purchases (≤ Rp 50.000) totaling {amount}, mostly in {cat}.',
          {
            'count': '${microTxs.length}',
            'amount': rupiah(microTotal),
            'cat': topMicroCatName,
          },
        ),
        icon: Icons.local_cafe_outlined,
        accentColor: AppColors.warning,
        badge: '${microTxs.length}x',
        filterType: TxType.expense,
        maxAmount: microThreshold,
      ));
    }

    return insights;
  }

  /// Menghitung ringkasan rekapitulasi mingguan atau bulanan yang telah selesai ([completedPeriod])
  /// dibandingkan dengan periode sebelumnya ([priorTxs]), tanpa ketergantungan [BuildContext].
  static RecapPeriodSummary computeRecap({
    required Period completedPeriod,
    required List<TransactionEntry> completedTxs,
    required List<TransactionEntry> priorTxs,
    required Map<String, Category> categoryMap,
    List<SavingsGoal> goals = const <SavingsGoal>[],
    String Function(String key)? translate,
  }) {
    final tr = translate ?? (String key) => key;

    int totalIncome = 0;
    int totalExpense = 0;
    int needTotal = 0;
    int wantTotal = 0;
    final catCurrent = <String, int>{};
    final catCounts = <String, int>{};

    for (final t in completedTxs) {
      if (t.type == TxType.income) {
        totalIncome += t.amount;
      } else if (t.type == TxType.expense) {
        totalExpense += t.amount;
        catCurrent[t.categoryId] = (catCurrent[t.categoryId] ?? 0) + t.amount;
        catCounts[t.categoryId] = (catCounts[t.categoryId] ?? 0) + 1;
        if (t.needWant == NeedWant.need) {
          needTotal += t.amount;
        } else if (t.needWant == NeedWant.want) {
          wantTotal += t.amount;
        }
      }
    }

    int priorExpense = 0;
    final catPrior = <String, int>{};
    for (final t in priorTxs) {
      if (t.type == TxType.expense) {
        priorExpense += t.amount;
        catPrior[t.categoryId] = (catPrior[t.categoryId] ?? 0) + t.amount;
      }
    }

    final netSavings = totalIncome - totalExpense;
    final savingsRate =
        totalIncome > 0 && netSavings > 0 ? (netSavings / totalIncome) * 100 : 0.0;
    final expensePctChange = priorExpense > 0
        ? ((totalExpense - priorExpense) / priorExpense) * 100
        : null;

    final topCategories = <RecapCategoryItem>[];
    catCurrent.forEach((catId, amount) {
      final cat = categoryMap[catId];
      topCategories.add(
        RecapCategoryItem(
          categoryId: catId,
          name: tr(cat?.name ?? 'Uncategorized'),
          colorValue: cat?.colorValue ?? 0xFF607D8B,
          icon: cat?.icon ?? 'more',
          amount: amount,
          percentage: totalExpense > 0 ? (amount / totalExpense) * 100 : 0.0,
          txCount: catCounts[catId] ?? 0,
        ),
      );
    });
    topCategories.sort((a, b) => b.amount.compareTo(a.amount));

    RecapCategoryHighlight? topSavingCategory;
    RecapCategoryHighlight? topSurgeCategory;
    int bestSavedDiff = 0;
    int worstSurgeDiff = 0;

    final allCatIds = <String>{...catCurrent.keys, ...catPrior.keys};
    for (final catId in allCatIds) {
      final cur = catCurrent[catId] ?? 0;
      final prev = catPrior[catId] ?? 0;
      if (prev <= 0) continue;
      final diff = cur - prev;
      final pct = (diff / prev) * 100;
      final catName = tr(categoryMap[catId]?.name ?? 'Uncategorized');

      if (diff <= -10000 && diff < bestSavedDiff && pct <= -10) {
        bestSavedDiff = diff;
        topSavingCategory = RecapCategoryHighlight(
          categoryId: catId,
          name: catName,
          diffAmount: diff.abs(),
          pctChange: pct,
        );
      } else if (diff >= 10000 && diff > worstSurgeDiff && pct >= 10) {
        worstSurgeDiff = diff;
        topSurgeCategory = RecapCategoryHighlight(
          categoryId: catId,
          name: catName,
          diffAmount: diff,
          pctChange: pct,
        );
      }
    }

    final activeGoals = goals.where((g) => g.deletedAt == null).toList();
    final goalsSavedTotal =
        activeGoals.fold<int>(0, (sum, g) => sum + g.currentAmount);
    final goalsTargetTotal =
        activeGoals.fold<int>(0, (sum, g) => sum + g.targetAmount);

    return RecapPeriodSummary(
      period: completedPeriod,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netSavings: netSavings,
      savingsRate: savingsRate,
      needTotal: needTotal,
      wantTotal: wantTotal,
      expensePctChange: expensePctChange,
      topCategories: topCategories.take(3).toList(),
      topSavingCategory: topSavingCategory,
      topSurgeCategory: topSurgeCategory,
      totalTxCount: completedTxs.length,
      activeGoalsCount: activeGoals.length,
      goalsSavedTotal: goalsSavedTotal,
      goalsTargetTotal: goalsTargetTotal,
    );
  }

  /// Menghitung Net Worth dari saldo likuid ditambah piutang aktif dikurangi utang aktif.
  /// Dana goal tabungan dicatat terpisah sebagai [allocatedGoalReserve] agar tidak terjadi double-counting.
  static NetWorthSummary computeNetWorth({
    required int liquidAssets,
    required List<Debt> debts,
    required List<SavingsGoal> goals,
  }) {
    int receivables = 0;
    int liabilities = 0;

    for (final d in debts) {
      if (d.deletedAt != null) continue;
      final remaining = (d.amount - d.paidAmount).clamp(0, d.amount);
      if (remaining <= 0) continue;
      if (d.direction == DebtDirection.lent) {
        receivables += remaining;
      } else {
        liabilities += remaining;
      }
    }

    int allocatedGoalReserve = 0;
    for (final g in goals) {
      if (g.deletedAt != null) continue;
      if (g.currentAmount > 0) allocatedGoalReserve += g.currentAmount;
    }

    return NetWorthSummary(
      liquidAssets: liquidAssets,
      receivables: receivables,
      liabilities: liabilities,
      allocatedGoalReserve: allocatedGoalReserve,
    );
  }

  /// Menghitung Glasshouse Vitality Score (0-100) dari 4 pilar deterministik:
  /// Savings Rate (30), Budget Discipline (25), Needs/Wants Balance (25), dan Debt Cushion (20).
  static VitalityScoreSummary computeVitalityScore({
    required InsightSummary summary,
    required NetWorthSummary netWorth,
    required Map<String, int> budgets,
    required Map<String, int> spentByCategory,
    required int needTotal,
    required int wantTotal,
  }) {
    final pillars = <VitalityPillar>[];

    // 1. Savings Rate (maks 30)
    final savingsActive = summary.totalIncome > 0 || summary.totalExpense > 0;
    final double savingsScore;
    final String savingsDetailKey;
    final Map<String, Object> savingsDetailArgs;
    if (!savingsActive) {
      savingsScore = 0;
      savingsDetailKey = 'Record income or expenses to score this pillar.';
      savingsDetailArgs = const {};
    } else if (summary.totalIncome <= 0) {
      savingsScore = 0;
      savingsDetailKey = 'No income recorded in this period yet.';
      savingsDetailArgs = const {};
    } else if (summary.netBalance <= 0) {
      savingsScore = 0;
      savingsDetailKey = 'Spending met or exceeded income this period.';
      savingsDetailArgs = const {};
    } else {
      savingsScore = (summary.savingsRate / 20.0).clamp(0.0, 1.0) * 30.0;
      savingsDetailKey = 'Saved {pct}% of period income (target 20%+).';
      savingsDetailArgs = {'pct': summary.savingsRate.toStringAsFixed(0)};
    }
    pillars.add(VitalityPillar(
      id: 'savings_rate',
      labelKey: 'Savings Rate',
      score: savingsScore,
      maxScore: 30,
      active: savingsActive,
      detailKey: savingsDetailKey,
      detailArgs: savingsDetailArgs,
    ));

    // 2. Budget Discipline (maks 25)
    final budgetedEntries = budgets.entries.where((e) => e.value > 0).toList();
    final budgetActive = budgetedEntries.isNotEmpty;
    double budgetScore = 0;
    int withinCount = 0;
    if (budgetActive) {
      double complianceSum = 0;
      for (final entry in budgetedEntries) {
        final spent = spentByCategory[entry.key] ?? 0;
        final ratio = spent / entry.value;
        if (ratio <= 1.0) {
          withinCount++;
          complianceSum += 1.0;
        } else {
          complianceSum += (1.0 - (ratio - 1.0)).clamp(0.0, 1.0);
        }
      }
      budgetScore = (complianceSum / budgetedEntries.length) * 25.0;
    }
    pillars.add(VitalityPillar(
      id: 'budget_discipline',
      labelKey: 'Budget Discipline',
      score: budgetScore,
      maxScore: 25,
      active: budgetActive,
      detailKey: budgetActive
          ? '{within} of {total} budgeted categories within limit.'
          : 'Set category budgets to include this pillar.',
      detailArgs: budgetActive
          ? {'within': withinCount, 'total': budgetedEntries.length}
          : const {},
    ));

    // 3. Needs vs Wants Balance (maks 25)
    final taggedTotal = needTotal + wantTotal;
    final nwActive = taggedTotal > 0;
    double nwScore = 0;
    int wantPct = 0;
    if (nwActive) {
      final wantShare = wantTotal / taggedTotal;
      wantPct = (wantShare * 100).round();
      nwScore = ((0.70 - wantShare) / 0.40).clamp(0.0, 1.0) * 25.0;
    }
    pillars.add(VitalityPillar(
      id: 'needs_wants',
      labelKey: 'Needs vs Wants',
      score: nwScore,
      maxScore: 25,
      active: nwActive,
      detailKey: nwActive
          ? 'Wants make up {pct}% of tagged spending (ideal ≤ 30%).'
          : 'Tag expenses as Need or Want to score balance.',
      detailArgs: nwActive ? {'pct': wantPct} : const {},
    ));

    // 4. Debt & Liquidity Cushion (maks 20)
    final cushionActive = netWorth.liquidAssets != 0 ||
        netWorth.liabilities > 0 ||
        netWorth.receivables > 0;
    final double cushionScore;
    final String cushionDetailKey;
    final Map<String, Object> cushionDetailArgs;
    if (!cushionActive) {
      cushionScore = 0;
      cushionDetailKey = 'Add wallet balances or debts to measure cushion.';
      cushionDetailArgs = const {};
    } else if (netWorth.liabilities == 0) {
      if (netWorth.liquidAssets >= 0) {
        cushionScore = 20.0;
        cushionDetailKey = 'Debt-free with positive liquid reserve.';
      } else {
        cushionScore = 8.0;
        cushionDetailKey = 'No debt, though wallet balance is negative.';
      }
      cushionDetailArgs = const {};
    } else if (netWorth.liquidAssets <= 0) {
      cushionScore = 0.0;
      cushionDetailKey = 'Liabilities exceed current liquid reserve.';
      cushionDetailArgs = const {};
    } else {
      final coverage = netWorth.liquidAssets / netWorth.liabilities;
      if (coverage >= 2.0) {
        cushionScore = 20.0;
      } else if (coverage >= 1.0) {
        cushionScore = 14.0 + ((coverage - 1.0) * 6.0);
      } else {
        cushionScore = (coverage * 14.0).clamp(0.0, 14.0);
      }
      cushionDetailKey = 'Liquid reserve covers {ratio}x active debt.';
      cushionDetailArgs = {'ratio': coverage.toStringAsFixed(1)};
    }
    pillars.add(VitalityPillar(
      id: 'debt_cushion',
      labelKey: 'Debt Cushion',
      score: cushionScore,
      maxScore: 20,
      active: cushionActive,
      detailKey: cushionDetailKey,
      detailArgs: cushionDetailArgs,
    ));

    final activePillars = pillars.where((p) => p.active).toList();
    if (activePillars.isEmpty) {
      return VitalityScoreSummary(
        score: 0,
        hasEnoughData: false,
        tier: VitalityTier.starter,
        pillars: pillars,
        activePillarCount: 0,
      );
    }

    final earned = activePillars.fold<double>(0, (s, p) => s + p.score);
    final maxPossible = activePillars.fold<double>(0, (s, p) => s + p.maxScore);
    final normalized = maxPossible > 0
        ? ((earned / maxPossible) * 100).round().clamp(0, 100)
        : 0;

    final VitalityTier tier;
    if (normalized >= 80) {
      tier = VitalityTier.thriving;
    } else if (normalized >= 60) {
      tier = VitalityTier.steadyGrowth;
    } else if (normalized >= 40) {
      tier = VitalityTier.needsCare;
    } else {
      tier = VitalityTier.fragile;
    }

    return VitalityScoreSummary(
      score: normalized,
      hasEnoughData: true,
      tier: tier,
      pillars: pillars,
      activePillarCount: activePillars.length,
    );
  }
}

