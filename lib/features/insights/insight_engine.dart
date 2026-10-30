import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/period.dart';
import '../../core/theme.dart';
import '../../data/app_database.dart';
import '../../data/tables.dart' show NeedWant, TxType;

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
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String? badge;
}

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
        final d = period.start.add(Duration(days: i));
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
      // Monthly view: Group into 4 or 5 weekly buckets of the month
      final lastDay = DateTime(period.end.year, period.end.month, period.end.day - 1);
      final totalDays = lastDay.day;
      final points = <ChartPoint>[];

      final buckets = [
        [1, 7],
        [8, 14],
        [15, 21],
        [22, 28],
        if (totalDays > 28) [29, totalDays],
      ];

      for (int i = 0; i < buckets.length; i++) {
        final b = buckets[i];
        final startDay = b[0];
        final endDay = b[1];
        final weekSum = expTxs
            .where((t) =>
                t.date.year == period.start.year &&
                t.date.month == period.start.month &&
                t.date.day >= startDay &&
                t.date.day <= endDay)
            .fold<int>(0, (s, t) => s + t.amount);

        final label = 'W${i + 1}';
        final fullLabel = 'Tgl $startDay – $endDay ${DateFormat('MMM', loc).format(period.start)}';
        points.add(ChartPoint(
          label: label,
          fullLabel: fullLabel,
          amount: weekSum,
        ));
      }
      return points;
    }
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
    final periodName = isWeekly ? context.tr('minggu') : context.tr('bulan');
    final prevPeriodName = isWeekly ? context.tr('minggu lalu') : context.tr('bulan lalu');

    // 1. Cashflow & Savings rate insight
    if (summary.totalIncome > 0 && summary.netBalance > 0) {
      insights.add(SmartInsightItem(
        title: context.tr('Cashflow Positif & Tabungan'),
        description: context.tr(
          'Kamu berhasil menyisihkan {pct}% ({amount}) dari total pemasukanmu periode ini.',
          {
            'pct': summary.savingsRate.toStringAsFixed(1),
            'amount': rupiah(summary.netBalance),
          },
        ),
        icon: Icons.savings_outlined,
        accentColor: AppColors.income,
        badge: '${summary.savingsRate.toStringAsFixed(0)}% Disimpan',
      ));
    } else if (summary.isDeficit && summary.totalIncome > 0) {
      insights.add(SmartInsightItem(
        title: context.tr('Pengeluaran Melebihi Pemasukan'),
        description: context.tr(
          'Total belanja melebihi pemasukan sebesar {amount}. Periksa kembali pos pengeluaran sekunder agar arus kas tetap sehat.',
          {'amount': rupiah(summary.netBalance.abs())},
        ),
        icon: Icons.warning_amber_rounded,
        accentColor: AppColors.expense,
        badge: 'Defisit',
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
      insights.add(SmartInsightItem(
        title: context.tr('Lonjakan Kategori: {category}', {'category': maxIncreaseCat.name}),
        description: context.tr(
          'Pengeluaran {category} meningkat {pct}% (+{diff}) dibandingkan {prev}.',
          {
            'category': maxIncreaseCat.name,
            'pct': maxIncreasePct.toStringAsFixed(0),
            'diff': rupiah(maxIncreaseCat.amountChange),
            'prev': prevPeriodName,
          },
        ),
        icon: Icons.trending_up_rounded,
        accentColor: AppColors.warning,
        badge: '+${maxIncreasePct.toStringAsFixed(0)}%',
      ));
    } else if (maxSavedCat != null && maxSavedPct <= -10) {
      insights.add(SmartInsightItem(
        title: context.tr('Penghematan: {category}', {'category': maxSavedCat.name}),
        description: context.tr(
          'Hebat! Pengeluaran {category} berhasil ditekan turun {pct}% (hemat {saved}) dibanding {prev}.',
          {
            'category': maxSavedCat.name,
            'pct': maxSavedPct.abs().toStringAsFixed(0),
            'saved': rupiah(maxSavedCat.amountChange.abs()),
            'prev': prevPeriodName,
          },
        ),
        icon: Icons.trending_down_rounded,
        accentColor: AppColors.income,
        badge: '-${maxSavedPct.abs().toStringAsFixed(0)}%',
      ));
    }

    // 3. Dominant Category
    if (categories.isNotEmpty && categories.first.percentage >= 35) {
      final top = categories.first;
      insights.add(SmartInsightItem(
        title: context.tr('Pusat Pengeluaran: {category}', {'category': top.name}),
        description: context.tr(
          '{category} menyerap porsi terbesar yaitu {pct}% ({amount}) dari seluruh belanja {period}.',
          {
            'category': top.name,
            'pct': top.percentage.toStringAsFixed(1),
            'amount': rupiah(top.amount),
            'period': periodName,
          },
        ),
        icon: Icons.pie_chart_outline_rounded,
        accentColor: top.color,
        badge: '${top.percentage.toStringAsFixed(0)}% Total',
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
        title: context.tr('Transaksi Terbesar'),
        description: context.tr(
          'Pembelian terbesar periode ini adalah {cat}{note} sebesar {amount} pada {date}.',
          {
            'cat': catName,
            'note': noteStr,
            'amount': rupiah(largest.amount),
            'date': dateStr,
          },
        ),
        icon: Icons.receipt_long_rounded,
        accentColor: AppColors.sage,
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
        title: context.tr('Hari Pengeluaran Tertinggi'),
        description: context.tr(
          'Aktivitas belanja paling padat terjadi pada {day} dengan total pengeluaran {amount}.',
          {
            'day': dayName,
            'amount': rupiah(peakAmount),
          },
        ),
        icon: Icons.calendar_today_rounded,
        accentColor: AppColors.warning,
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
          title: context.tr('Porsi Keinginan (Wants) Cukup Tinggi'),
          description: context.tr(
            '{pct}% pengeluaran yang ditandai dialokasikan untuk pos keinginan ({amount}). Coba evaluasi pos belanja non-esensial untuk menambah tabungan.',
            {'pct': '$wantPct', 'amount': rupiah(wantTotal)},
          ),
          icon: Icons.favorite_border,
          accentColor: const Color(0xFFEF9A9A),
          badge: '$wantPct% Keinginan',
        ));
      } else {
        insights.add(SmartInsightItem(
          title: context.tr('Alokasi Kebutuhan Seimbang'),
          description: context.tr(
            '{pct}% pengeluaran dialokasikan untuk kebutuhan pokok ({amount}). Pola belanja esensialmu terjaga dengan baik!',
            {'pct': '${100 - wantPct}', 'amount': rupiah(needTotal)},
          ),
          icon: Icons.check_circle_outline,
          accentColor: AppColors.sage,
          badge: '${100 - wantPct}% Kebutuhan',
        ));
      }
    }

    return insights;
  }
}

