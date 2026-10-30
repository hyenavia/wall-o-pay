import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/period.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_database.dart';
import '../../data/providers.dart';
import '../../data/tables.dart' show NeedWant, TxType;
import '../transactions/transaction_form.dart';
import 'charts.dart';
import 'insight_engine.dart';

/// Halaman Insight finansial yang menganalisis transaksi secara deterministik:
/// ringkasan periode, perbandingan periode, grafik pengeluaran, kategori teratas,
/// dan ringkasan analitis cerdas (smart financial insights).
class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final period = ref.watch(selectedPeriodProvider);
    final isWeekly = period.type == PeriodType.weekly;
    final cats = ref.watch(categoryMapProvider);

    final currentTxsAsync = ref.watch(transactionsProvider);
    final prevTxsAsync = ref.watch(previousPeriodTransactionsProvider);
    final trendTxsAsync = ref.watch(trendTransactionsProvider);

    return Scaffold(
      appBar: pageAppBar(
        context,
        title: Text(context.tr('Insight')),
      ),
      body: currentTxsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(context.tr('Could not load data: {error}', {'error': e})),
        ),
        data: (currentTxs) {
          final prevTxs = prevTxsAsync.value ?? const <TransactionEntry>[];
          final trendTxs = trendTxsAsync.value ?? const <TransactionEntry>[];

          int needTotal = 0;
          int wantTotal = 0;
          for (final t in currentTxs) {
            if (t.type == TxType.expense) {
              if (t.needWant == NeedWant.need) needTotal += t.amount;
              if (t.needWant == NeedWant.want) wantTotal += t.amount;
            }
          }

          final summary = InsightEngine.computeSummary(
            currentTxs: currentTxs,
            prevTxs: prevTxs,
          );

          final categories = InsightEngine.computeCategories(
            context: context,
            currentTxs: currentTxs,
            prevTxs: prevTxs,
            categoryMap: cats,
            totalExpense: summary.totalExpense,
          );

          final chartPoints = InsightEngine.computeChartPoints(
            currentTxs: currentTxs,
            period: period,
          );

          final smartInsights = InsightEngine.generateSmartInsights(
            context: context,
            summary: summary,
            categories: categories,
            currentTxs: currentTxs,
            period: period,
            categoryMap: cats,
          );

          final periodLabel = isWeekly
              ? context.tr('Ringkasan Minggu Ini')
              : context.tr('Ringkasan Bulan Ini');
          final prevPeriodName = isWeekly
              ? context.tr('minggu lalu')
              : context.tr('bulan lalu');

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              // 1. Pemilih periode & tipe periode
              Center(
                child: Column(
                  children: [
                    const PeriodTypeToggle(),
                    const SizedBox(height: 8),
                    const PeriodSwitcher(),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. KARTU HERO: Ringkasan Periode Ini (Pemasukan, Pengeluaran, Selisih)
              HeroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          periodLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white70,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: summary.isDeficit
                                ? AppColors.expense.withValues(alpha: 0.3)
                                : AppColors.sage.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: summary.isDeficit
                                  ? AppColors.expense.withValues(alpha: 0.6)
                                  : AppColors.sage.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                summary.isDeficit
                                    ? Icons.warning_rounded
                                    : Icons.trending_up_rounded,
                                size: 14,
                                color: summary.isDeficit ? Colors.white : AppColors.sage,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                summary.isDeficit
                                    ? context.tr('Defisit')
                                    : context.tr('Surplus'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: summary.isDeficit ? Colors.white : AppColors.sage,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Nominal Selisih Bersih
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${summary.netBalance >= 0 ? '+' : ''}${rupiah(summary.netBalance)}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.totalIncome > 0 && !summary.isDeficit
                          ? context.tr(
                              '{pct}% dari pemasukan tersisa untuk ditabung',
                              {'pct': summary.savingsRate.toStringAsFixed(1)},
                            )
                          : (summary.isDeficit
                              ? context.tr('Pengeluaran melampaui pemasukan periode ini')
                              : context.tr('Selisih bersih antara pemasukan dan pengeluaran')),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Divider tipis
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 16),

                    // Sub-box: Pemasukan & Pengeluaran
                    Row(
                      children: [
                        Expanded(
                          child: _SummarySubBox(
                            label: context.tr('Income'),
                            amount: rupiah(summary.totalIncome),
                            icon: Icons.arrow_downward_rounded,
                            iconColor: AppColors.income,
                            bgColor: Colors.black.withValues(alpha: 0.18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummarySubBox(
                            label: context.tr('Expense'),
                            amount: rupiah(summary.totalExpense),
                            icon: Icons.arrow_upward_rounded,
                            iconColor: AppColors.expense,
                            bgColor: Colors.black.withValues(alpha: 0.18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. PERBANDINGAN PERIODE (Period Comparison Banner)
              _PeriodComparisonCard(
                summary: summary,
                prevPeriodName: prevPeriodName,
                isWeekly: isWeekly,
              ),

              // 4. LOW DATA STATE vs REGULAR INSIGHTS & CHARTS
              if (summary.isLowData) ...[
                const SizedBox(height: 20),
                _LowDataCard(
                  onAddTransaction: () => showTransactionForm(context),
                ),
              ] else ...[
                // 5. GRAFIK PENGELUARAN (Expense Chart)
                SectionHeader(
                  title: isWeekly
                      ? context.tr('Grafik Pengeluaran Harian')
                      : context.tr('Grafik Pengeluaran Bulanan'),
                ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isWeekly
                                ? context.tr('Tren pengeluaran 7 hari')
                                : context.tr('Distribusi pengeluaran per minggu'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.65),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            rupiah(summary.totalExpense),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.sage,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      PeriodExpenseBarChart(
                        points: chartPoints,
                        totalExpense: summary.totalExpense,
                      ),
                      const SizedBox(height: 10),
                      Divider(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isWeekly
                                ? context.tr('Rata-rata harian:')
                                : context.tr('Rata-rata mingguan:'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            isWeekly
                                ? rupiah(summary.totalExpense ~/ 7)
                                : rupiah(summary.totalExpense ~/ (chartPoints.isEmpty ? 1 : chartPoints.length)),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 6. KATEGORI TERATAS (Top Categories)
                SectionHeader(
                  title: context.tr('Kategori Teratas'),
                ),
                if (categories.isEmpty)
                  AppCard(child: Text(context.tr('No expenses in this period.')))
                else
                  AppCard(
                    child: Column(
                      children: [
                        for (int i = 0; i < categories.length && i < 5; i++)
                          _TopCategoryRow(
                            rank: i + 1,
                            category: categories[i],
                            prevPeriodName: prevPeriodName,
                          ),
                      ],
                    ),
                  ),

                // 7. FINANCIAL INSIGHTS (Analisis Finansial Cerdas)
                if (smartInsights.isNotEmpty) ...[
                  SectionHeader(
                    title: context.tr('Financial Insights'),
                  ),
                  for (final item in smartInsights)
                    _SmartInsightCard(item: item),
                ],

                // 8. KOMPOSISI & TREN 6 PERIODE (Historical Trend)
                SectionHeader(
                  title: isWeekly
                      ? context.tr('Tren 6 Minggu Terakhir')
                      : context.tr('Tren 6 Bulan Terakhir'),
                ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('Perbandingan Pemasukan vs Pengeluaran'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TrendBarChart(txs: trendTxs, period: period),
                    ],
                  ),
                ),

                if (categories.isNotEmpty) ...[
                  SectionHeader(
                    title: context.tr('Komposisi Pengeluaran'),
                  ),
                  AppCard(
                    child: ExpensePieChart(
                      spent: {for (final c in categories) c.categoryId: c.amount},
                      cats: cats,
                    ),
                  ),
                ],
                if (needTotal + wantTotal > 0) ...[
                  SectionHeader(
                    title: context.tr('Needs vs wants'),
                  ),
                  AppCard(
                    child: _NeedsWantsCard(
                      needTotal: needTotal,
                      wantTotal: wantTotal,
                    ),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SummarySubBox extends StatelessWidget {
  const _SummarySubBox({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  final String label;
  final String amount;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
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

class _PeriodComparisonCard extends StatelessWidget {
  const _PeriodComparisonCard({
    required this.summary,
    required this.prevPeriodName,
    required this.isWeekly,
  });

  final InsightSummary summary;
  final String prevPeriodName;
  final bool isWeekly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (summary.prevTotalExpense == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: scheme.onSurface.withValues(alpha: 0.5),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.tr(
                  'Belum ada data pengeluaran di {prev} untuk perbandingan tren.',
                  {'prev': prevPeriodName},
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isLower = summary.expenseDiff < 0;
    final isSame = summary.expenseDiff == 0;
    final pct = summary.expensePctChange?.abs().toStringAsFixed(1) ?? '0';

    final Color badgeColor = isSame
        ? Colors.grey
        : (isLower ? AppColors.income : AppColors.expense);

    final IconData badgeIcon = isSame
        ? Icons.horizontal_rule_rounded
        : (isLower ? Icons.trending_down_rounded : Icons.trending_up_rounded);

    final String title = isSame
        ? context.tr('Pengeluaran sama persis dengan {prev}.', {'prev': prevPeriodName})
        : (isLower
            ? context.tr(
                'Pengeluaran turun {pct}% ({diff} lebih hemat)',
                {
                  'pct': pct,
                  'diff': rupiah(summary.expenseDiff.abs()),
                },
              )
            : context.tr(
                'Pengeluaran naik {pct}% (+{diff})',
                {
                  'pct': pct,
                  'diff': rupiah(summary.expenseDiff),
                },
              ));

    final String subtitle = isSame
        ? context.tr('Total belanja sama dengan periode sebelumnya ({amount}).', {'amount': rupiah(summary.totalExpense)})
        : (isLower
            ? context.tr(
                'Bagus! Pengeluaranmu lebih terkendali dibandingkan {prev} ({amount}).',
                {'prev': prevPeriodName, 'amount': rupiah(summary.prevTotalExpense)},
              )
            : context.tr(
                'Pengeluaran meningkat dibandingkan {prev} ({amount}).',
                {'prev': prevPeriodName, 'amount': rupiah(summary.prevTotalExpense)},
              ));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(badgeIcon, color: badgeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
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

class _TopCategoryRow extends StatelessWidget {
  const _TopCategoryRow({
    required this.rank,
    required this.category,
    required this.prevPeriodName,
  });

  final int rank;
  final CategoryInsight category;
  final String prevPeriodName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rank <= 3
                      ? AppColors.deepForest.withValues(alpha: 0.2)
                      : scheme.outlineVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: rank <= 3 ? AppColors.sage : scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              CategoryBadge(
                icon: iconFor(category.icon),
                color: category.color,
                size: 34,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${category.txCount} ${context.tr('transaksi')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    rupiah(category.amount),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${category.percentage.toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.sage,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      if (category.pctChange != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${category.pctChange! >= 0 ? '+' : ''}${category.pctChange!.toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: category.pctChange! > 0
                                ? AppColors.expense
                                : AppColors.income,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppProgressBar(
            value: category.percentage / 100,
            color: category.color,
            height: 6,
          ),
        ],
      ),
    );
  }
}

class _SmartInsightCard extends StatelessWidget {
  const _SmartInsightCard({required this.item});

  final SmartInsightItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (item.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.badge!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: item.accentColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.75),
                    height: 1.4,
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

class _LowDataCard extends StatelessWidget {
  const _LowDataCard({required this.onAddTransaction});

  final VoidCallback onAddTransaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.deepForest.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.sage,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('Catat beberapa transaksi lagi'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'Catat beberapa transaksi lagi untuk melihat insight keuanganmu, grafik perbandingan pengeluaran, dan kategori teratas.',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAddTransaction,
            icon: const Icon(Icons.add, size: 18),
            label: Text(context.tr('Add transaction')),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.deepForest,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _NeedsWantsCard extends StatelessWidget {
  const _NeedsWantsCard({required this.needTotal, required this.wantTotal});
  final int needTotal;
  final int wantTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = needTotal + wantTotal;
    final needPct = total == 0 ? 0 : ((needTotal / total) * 100).round();
    final wantPct = total == 0 ? 0 : 100 - needPct;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 16, color: AppColors.sage),
                const SizedBox(width: 6),
                Text('${context.tr('Needs')}: $needPct%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.favorite_border, size: 16, color: Color(0xFFEF9A9A)),
                const SizedBox(width: 6),
                Text('${context.tr('Wants')}: $wantPct%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              if (needTotal > 0)
                Expanded(
                  flex: needTotal,
                  child: Container(height: 10, color: AppColors.sage),
                ),
              if (wantTotal > 0)
                Expanded(
                  flex: wantTotal,
                  child: Container(height: 10, color: const Color(0xFFEF9A9A)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(rupiah(needTotal), style: theme.textTheme.bodySmall?.copyWith(color: AppColors.sage, fontWeight: FontWeight.bold)),
            Text(rupiah(wantTotal), style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFEF9A9A), fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
