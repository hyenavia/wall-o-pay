/// Halaman analitik keuangan ([InsightsPage]) dengan 3 tab (Ringkasan, Kategori, dan Tren)
/// untuk mengevaluasi pola pengeluaran, rasio tabungan, dan perbandingan antar periode.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/period.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_database.dart';
import '../../data/feature_providers.dart';
import '../../data/prefs.dart';
import '../../data/providers.dart';
import '../../data/tables.dart' show NeedWant, TxType;
import '../transactions/transaction_form.dart';
import '../transactions/transaction_tile.dart';
import 'charts.dart';
import 'insight_engine.dart';

/// Menyaring dan mengurutkan transaksi pengeluaran untuk kategori tertentu pada drill-down Insight.
List<TransactionEntry> filterCategoryDrillDownTransactions({
  required List<TransactionEntry> transactions,
  required String categoryId,
  TxType type = TxType.expense,
}) {
  final filtered = transactions
      .where((t) => t.type == type && t.categoryId == categoryId)
      .toList();
  filtered.sort((a, b) {
    final byDate = b.date.compareTo(a.date);
    return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
  });
  return filtered;
}

/// Halaman Insight bertab: Ringkasan, Kategori, dan Tren dengan analisis deterministik.
class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  int _tab = 0;

  Period _completedRecapPeriod(PeriodType type) {
    final appPrefs = ref.read(appPrefsProvider);
    return Period.containing(
      type,
      DateTime.now(),
      firstDayOfWeek: appPrefs.firstDayOfWeek,
      firstDayOfMonth: appPrefs.firstDayOfMonth,
    ).shift(-1);
  }

  bool _isRecapUnseen(PeriodType type) {
    final prefs = ref.read(sharedPreferencesProvider);
    final key = type == PeriodType.weekly
        ? 'last_recap_seen_weekly'
        : 'last_recap_seen_monthly';
    return prefs.getString(key) != _completedRecapPeriod(type).key;
  }

  Future<void> _openRecapSheet(
    BuildContext context,
    PeriodType initialType,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FinancialRecapSheet(
        initialType: initialType,
        onViewed: () {
          if (mounted) setState(() {});
        },
      ),
    );
    if (mounted) setState(() {});
  }

  void _openVitalitySheet(
    BuildContext context,
    NetWorthSummary netWorth,
    VitalityScoreSummary vitality,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _VitalityDetailsSheet(netWorth: netWorth, vitality: vitality),
    );
  }

  void _openCategoryDrillDown({
    required BuildContext context,
    required CategoryInsight category,
    required Period period,
    required List<TransactionEntry> periodTxs,
  }) {
    final matchingTxs = filterCategoryDrillDownTransactions(
      transactions: periodTxs,
      categoryId: category.categoryId,
    );
    final cats = ref.read(categoryMapProvider);
    final wallets = ref.read(walletMapProvider);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final colors = ctx.themeColors;
        final maxH = MediaQuery.of(ctx).size.height * 0.78;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    children: [
                      CategoryBadge(
                        icon: iconFor(category.icon),
                        color: category.color,
                        categoryKey: category.icon,
                        size: 42,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(category.name),
                              style: Theme.of(ctx).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colors.textPrimary,
                                  ),
                            ),
                            Text(
                              '${period.label()} • ${category.txCount == 1 ? context.tr('1 transaction') : context.tr('{count} transactions', {'count': category.txCount})}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textMuted,
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
                            style: ctx.moneyStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: colors.expense,
                            ),
                          ),
                          Text(
                            '${category.percentage.toStringAsFixed(1)}%',
                            style: ctx.moneyStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: colors.isDark
                                  ? AppColors.dewMint
                                  : colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: colors.borderOutline.withValues(alpha: 0.35),
                ),
                if (matchingTxs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        context.tr('No expenses in this period.'),
                        style: TextStyle(color: colors.textMuted),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                      itemCount: matchingTxs.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        indent: 68,
                        color: colors.borderOutline.withValues(alpha: 0.25),
                      ),
                      itemBuilder: (_, idx) {
                        final t = matchingTxs[idx];
                        return TransactionTile(
                          entry: t,
                          category: cats[t.categoryId],
                          wallet: t.walletId != null
                              ? wallets[t.walletId!]
                              : null,
                          toWallet: t.toWalletId != null
                              ? wallets[t.toWalletId!]
                              : null,
                          trailingNote: shortDate(t.date),
                          onTap: () {
                            Navigator.pop(ctx);
                            showTransactionForm(context, entry: t);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSmartInsightDrillDown({
    required BuildContext context,
    required SmartInsightItem item,
    required Period period,
    required List<TransactionEntry> periodTxs,
  }) {
    final matchingTxs = InsightEngine.filterTransactionsForInsight(
      item,
      periodTxs,
    );
    final totalAmount = matchingTxs.fold<int>(0, (sum, t) => sum + t.amount);
    final cats = ref.read(categoryMapProvider);
    final wallets = ref.read(walletMapProvider);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final colors = ctx.themeColors;
        final accent = colors.resolveAccent(item.accentColor);
        final maxH = MediaQuery.of(ctx).size.height * 0.78;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.35),
                          ),
                        ),
                        child: AppDuotoneIcon(
                          phosphorForIcon(item.icon) ??
                              PhosphorIconsDuotone.chartBar,
                          color: accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: Theme.of(ctx).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colors.textPrimary,
                                  ),
                            ),
                            Text(
                              '${period.label()} • ${matchingTxs.length == 1 ? context.tr('1 transaction') : context.tr('{count} transactions', {'count': matchingTxs.length})}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        rupiah(totalAmount),
                        style: ctx.moneyStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: item.filterType == TxType.income
                              ? colors.income
                              : colors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: colors.borderOutline.withValues(alpha: 0.35),
                ),
                if (matchingTxs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        context.tr('No matching transactions'),
                        style: TextStyle(color: colors.textMuted),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                      itemCount: matchingTxs.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        indent: 68,
                        color: colors.borderOutline.withValues(alpha: 0.25),
                      ),
                      itemBuilder: (_, idx) {
                        final t = matchingTxs[idx];
                        return TransactionTile(
                          entry: t,
                          category: cats[t.categoryId],
                          wallet: t.walletId != null
                              ? wallets[t.walletId!]
                              : null,
                          toWallet: t.toWalletId != null
                              ? wallets[t.toWalletId!]
                              : null,
                          trailingNote: shortDate(t.date),
                          onTap: () {
                            Navigator.pop(ctx);
                            showTransactionForm(context, entry: t);
                          },
                          onLongPress: () {
                            Navigator.pop(ctx);
                            showDuplicateTransactionForm(context, t);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.themeColors;
    final period = ref.watch(selectedPeriodProvider);
    final isWeekly = period.type == PeriodType.weekly;
    final cats = ref.watch(categoryMapProvider);

    final currentTxsAsync = ref.watch(transactionsProvider);
    final prevTxsAsync = ref.watch(previousPeriodTransactionsProvider);
    final trendTxsAsync = ref.watch(trendTransactionsProvider);
    final liquidAssets = ref.watch(totalCurrentBalanceProvider);
    final debtsList = ref.watch(debtsProvider).value ?? const <Debt>[];
    final goalsList =
        ref.watch(savingsGoalsProvider).value ?? const <SavingsGoal>[];
    final budgetsMap = ref.watch(budgetByCategoryProvider);
    final spentMap = ref.watch(spentByCategoryProvider);

    return Scaffold(
      appBar: pageAppBar(
        context,
        title: Text(context.tr('Insight')),
        actions: [
          IconButton(
            tooltip: context.tr('Financial Recap'),
            onPressed: () => _openRecapSheet(context, period.type),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const AppDuotoneIcon(
                  PhosphorIconsDuotone.calendarBlank,
                  size: 22,
                  color: Colors.white,
                ),
                if (_isRecapUnseen(period.type))
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.isDark
                            ? AppColors.dewMint
                            : AppColors.goldenYellow,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        bottom: const Center(child: PeriodSwitcher(onDark: true)),
        bottomHeight: 44,
      ),
      body: BotanicalBackgroundSheet(
        child: currentTxsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              context.tr('Could not load data: {error}', {'error': e}),
            ),
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

            final netWorth = InsightEngine.computeNetWorth(
              liquidAssets: liquidAssets,
              debts: debtsList,
              goals: goalsList,
            );

            final vitality = InsightEngine.computeVitalityScore(
              summary: summary,
              netWorth: netWorth,
              budgets: budgetsMap,
              spentByCategory: spentMap,
              needTotal: needTotal,
              wantTotal: wantTotal,
            );

            final periodLabel = isWeekly
                ? context.tr('Weekly Summary')
                : context.tr('Monthly Summary');
            final prevPeriodName = isWeekly
                ? context.tr('last week')
                : context.tr('last month');
            final trendTitle = isWeekly
                ? context.tr('Last 6 Weeks Trend')
                : context.tr('Last 6 Months Trend');

            final List<Widget> content;
            switch (_tab) {
              case 1:
                content = [
                  if (needTotal + wantTotal > 0) ...[
                    SectionHeader(title: context.tr('Needs vs wants')),
                    AppCard(
                      child: _NeedsWantsCard(
                        needTotal: needTotal,
                        wantTotal: wantTotal,
                      ),
                    ),
                  ],
                  SectionHeader(title: context.tr('Spending by category')),
                  if (categories.isEmpty)
                    AppCard(
                      child: Text(context.tr('No expenses in this period.')),
                    )
                  else
                    AppCard(
                      child: Column(
                        children: [
                          for (int i = 0; i < categories.length; i++)
                            _TopCategoryRow(
                              rank: i + 1,
                              category: categories[i],
                              prevPeriodName: prevPeriodName,
                              onTap: () => _openCategoryDrillDown(
                                context: context,
                                category: categories[i],
                                period: period,
                                periodTxs: currentTxs,
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (categories.isNotEmpty) ...[
                    SectionHeader(title: context.tr('Expense Composition')),
                    AppCard(
                      child: ExpensePieChart(
                        spent: {
                          for (final c in categories) c.categoryId: c.amount,
                        },
                        cats: cats,
                        onCategoryTap: (catId) {
                          final match = categories
                              .where((c) => c.categoryId == catId)
                              .firstOrNull;
                          if (match != null) {
                            _openCategoryDrillDown(
                              context: context,
                              category: match,
                              period: period,
                              periodTxs: currentTxs,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ];
                break;
              case 2:
                content = [
                  SectionHeader(title: trendTitle),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('Income vs Expense Comparison'),
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TrendBarChart(txs: trendTxs, period: period),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TrendTable(txs: trendTxs, period: period),
                ];
                break;
              default:
                content = [
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (summary.isDeficit
                                            ? colors.onHeroExpense
                                            : colors.onHeroIncome)
                                        .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      (summary.isDeficit
                                              ? colors.onHeroExpense
                                              : colors.onHeroIncome)
                                          .withValues(alpha: 0.4),
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
                                    color: summary.isDeficit
                                        ? colors.onHeroExpense
                                        : colors.onHeroIncome,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    summary.isDeficit
                                        ? context.tr('Deficit')
                                        : context.tr('Surplus'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: summary.isDeficit
                                          ? colors.onHeroExpense
                                          : colors.onHeroIncome,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${summary.netBalance >= 0 ? '+' : ''}${rupiah(summary.netBalance)}',
                              style: context.moneyStyle(
                                fontSize: 30,
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
                                  '{pct}% of income left for savings',
                                  {
                                    'pct': summary.savingsRate.toStringAsFixed(
                                      1,
                                    ),
                                  },
                                )
                              : (summary.isDeficit
                                    ? context.tr(
                                        'Spending exceeded income this period',
                                      )
                                    : context.tr(
                                        'Net difference between income and expenses',
                                      )),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _SummarySubBox(
                                label: context.tr('Income'),
                                amount: rupiah(summary.totalIncome),
                                icon: Icons.arrow_downward_rounded,
                                iconColor: colors.onHeroIncome,
                                bgColor: colors.isDark
                                    ? const Color(0xFF0F221B)
                                          .withValues(alpha: 0.65)
                                    : Colors.black.withValues(alpha: 0.22),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SummarySubBox(
                                label: context.tr('Expense'),
                                amount: rupiah(summary.totalExpense),
                                icon: Icons.arrow_upward_rounded,
                                iconColor: colors.onHeroExpense,
                                bgColor: colors.isDark
                                    ? const Color(0xFF0F221B)
                                          .withValues(alpha: 0.65)
                                    : Colors.black.withValues(alpha: 0.22),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _HarvestRecapBanner(
                    periodLabel: _completedRecapPeriod(period.type).label(),
                    isWeekly: isWeekly,
                    hasUnread: _isRecapUnseen(period.type),
                    onTap: () => _openRecapSheet(context, period.type),
                  ),
                  const SizedBox(height: 12),
                  _NetWorthVitalityCard(
                    netWorth: netWorth,
                    vitality: vitality,
                    onTap: () =>
                        _openVitalitySheet(context, netWorth, vitality),
                  ),
                  const SizedBox(height: 12),
                  _PeriodComparisonCard(
                    summary: summary,
                    prevPeriodName: prevPeriodName,
                    isWeekly: isWeekly,
                  ),
                  if (summary.isLowData) ...[
                    const SizedBox(height: 20),
                    _LowDataCard(
                      onAddTransaction: () => showTransactionForm(context),
                    ),
                  ] else ...[
                    SectionHeader(
                      title: isWeekly
                          ? context.tr('Daily Expense Chart')
                          : context.tr('Monthly Expense Chart'),
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
                                    ? context.tr('7-day spending trend')
                                    : context.tr(
                                        'Weekly spending distribution',
                                      ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                rupiah(summary.totalExpense),
                                style: context.moneyStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: colors.expense,
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
                          Divider(
                            color: colors.borderOutline.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isWeekly
                                    ? context.tr('Daily average:')
                                    : context.tr('Weekly average:'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textMuted,
                                ),
                              ),
                              Text(
                                isWeekly
                                    ? rupiah(summary.totalExpense ~/ 7)
                                    : rupiah(
                                        summary.totalExpense ~/
                                            (chartPoints.isEmpty
                                                ? 1
                                                : chartPoints.length),
                                      ),
                                style: context.moneyStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (smartInsights.isNotEmpty) ...[
                      SectionHeader(title: context.tr('Financial Insights')),
                      for (final item in smartInsights)
                        _SmartInsightCard(
                          item: item,
                          onTap: item.hasDrillDown
                              ? () => _openSmartInsightDrillDown(
                                  context: context,
                                  item: item,
                                  period: period,
                                  periodTxs: currentTxs,
                                )
                              : null,
                        ),
                    ],
                    SectionHeader(title: context.tr('Top Categories')),
                    if (categories.isEmpty)
                      AppCard(
                        child: Text(context.tr('No expenses in this period.')),
                      )
                    else
                      AppCard(
                        child: Column(
                          children: [
                            for (int i = 0; i < categories.length && i < 3; i++)
                              _TopCategoryRow(
                                rank: i + 1,
                                category: categories[i],
                                prevPeriodName: prevPeriodName,
                                onTap: () => _openCategoryDrillDown(
                                  context: context,
                                  category: categories[i],
                                  period: period,
                                  periodTxs: currentTxs,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ];
                break;
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: colors.isDark
                          ? AppColors.dewMint.withValues(alpha: 0.22)
                          : colors.primary,
                      selectedForegroundColor: colors.isDark
                          ? AppColors.dewMint
                          : colors.onPrimary,
                      foregroundColor: colors.isDark
                          ? AppColors.freshSage
                          : colors.textPrimary,
                      side: BorderSide(
                        color: colors.isDark
                            ? AppColors.dewMint.withValues(alpha: 0.25)
                            : colors.inputBorder,
                      ),
                    ),
                    segments: [
                      ButtonSegment(
                        value: 0,
                        label: Text(
                          context.tr('Overview'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text(
                          context.tr('Categories'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      ButtonSegment(
                        value: 2,
                        label: Text(
                          context.tr('Trend'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (s) => setState(() => _tab = s.first),
                  ),
                ),
                const SizedBox(height: 12),
                ...content,
              ],
            );
          },
        ),
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
    final colors = context.themeColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.isDark
              ? AppColors.dewMint.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: AppDuotoneIcon(
              phosphorForIcon(icon) ?? PhosphorIconsDuotone.chartBar,
              color: iconColor,
              size: 16,
            ),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.moneyStyle(
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
    final colors = context.themeColors;

    if (summary.prevTotalExpense == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.borderOutline.withValues(
              alpha: colors.isDark ? 0.4 : 0.7,
            ),
          ),
          boxShadow: colors.isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            AppDuotoneIcon(
              PhosphorIconsDuotone.chartLineUp,
              size: 20,
              color: colors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.tr('No expense data in {prev} for trend comparison.', {
                  'prev': prevPeriodName,
                }),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
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
        ? colors.textMuted
        : (isLower ? colors.income : colors.expense);

    final IconData badgeIcon = isSame
        ? Icons.horizontal_rule_rounded
        : (isLower ? Icons.trending_down_rounded : Icons.trending_up_rounded);

    final String title = isSame
        ? context.tr('Spending exactly matches {prev}.', {
            'prev': prevPeriodName,
          })
        : (isLower
              ? context.tr('Spending down {pct}% ({diff} saved)', {
                  'pct': pct,
                  'diff': rupiah(summary.expenseDiff.abs()),
                })
              : context.tr('Spending up {pct}% (+{diff})', {
                  'pct': pct,
                  'diff': rupiah(summary.expenseDiff),
                }));

    final String subtitle = isSame
        ? context.tr('Total spending equals previous period ({amount}).', {
            'amount': rupiah(summary.totalExpense),
          })
        : (isLower
              ? context.tr(
                  'Great! Your spending is more controlled than in {prev} ({amount}).',
                  {
                    'prev': prevPeriodName,
                    'amount': rupiah(summary.prevTotalExpense),
                  },
                )
              : context.tr(
                  'Spending increased compared to {prev} ({amount}).',
                  {
                    'prev': prevPeriodName,
                    'amount': rupiah(summary.prevTotalExpense),
                  },
                ));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.isDark
            ? AppColors.cardSurface.withValues(alpha: 0.95)
            : colors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badgeColor.withValues(alpha: colors.isDark ? 0.35 : 0.45),
          width: 1,
        ),
        boxShadow: colors.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: badgeColor.withValues(alpha: 0.35),
                width: 1,
              ),
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
                    color: colors.textMuted,
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
    this.onTap,
  });

  final int rank;
  final CategoryInsight category;
  final String prevPeriodName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final rankAccent = colors.isDark ? AppColors.dewMint : colors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
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
                        ? (colors.isDark
                              ? AppColors.emeraldLeaf.withValues(alpha: 0.35)
                              : colors.primary.withValues(alpha: 0.14))
                        : colors.cardSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: rank <= 3
                          ? rankAccent.withValues(alpha: 0.3)
                          : colors.borderOutline.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: rank <= 3 ? rankAccent : colors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CategoryBadge(
                  icon: iconFor(category.icon),
                  color: category.color,
                  categoryKey: category.icon,
                  size: 34,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(category.name),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        '${category.txCount} ${context.tr('transactions')}',
                        style: TextStyle(color: colors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      rupiah(category.amount),
                      style: context.moneyStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${category.percentage.toStringAsFixed(1)}%',
                          style: context.moneyStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: rankAccent,
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
                                  ? colors.expense
                                  : colors.income,
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
              backgroundColor: colors.isDark
                  ? AppColors.mossShadow.withValues(alpha: 0.6)
                  : colors.surfaceContainer,
              height: 6,
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartInsightCard extends StatelessWidget {
  const _SmartInsightCard({required this.item, this.onTap});

  final SmartInsightItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final accent = colors.resolveAccent(item.accentColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.borderOutline.withValues(
            alpha: colors.isDark ? 0.45 : 0.7,
          ),
        ),
        boxShadow: colors.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: AppDuotoneIcon(
                    phosphorForIcon(item.icon) ?? PhosphorIconsDuotone.chartBar,
                    color: accent,
                    size: 22,
                  ),
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
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          if (item.badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                item.badge!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                          if (onTap != null) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: colors.textMuted,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textMuted,
                          height: 1.4,
                        ),
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

class _LowDataCard extends StatelessWidget {
  const _LowDataCard({required this.onAddTransaction});

  final VoidCallback onAddTransaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.themeColors;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.borderOutline.withValues(
            alpha: colors.isDark ? 0.45 : 0.7,
          ),
        ),
        boxShadow: colors.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/illustrations/empty_analytics.png',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('Record a few more transactions'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'Record a few more transactions to see your financial insights, spending charts, and top categories.',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAddTransaction,
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              context.tr('Add transaction'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
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
    final colors = context.themeColors;
    final total = needTotal + wantTotal;
    final needPct = total == 0 ? 0 : ((needTotal / total) * 100).round();
    final wantPct = total == 0 ? 0 : 100 - needPct;

    final needColor = colors.isDark ? const Color(0xFF38B271) : colors.income;
    final wantColor = colors.isDark ? const Color(0xFFE8A33D) : colors.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: needColor.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: needColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${context.tr('Needs')}: $needPct%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: wantColor.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_border,
                      size: 14,
                      color: wantColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${context.tr('Wants')}: $wantPct%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              if (needTotal > 0)
                Expanded(
                  flex: needTotal,
                  child: Container(height: 8, color: needColor),
                ),
              if (needTotal > 0 && wantTotal > 0) const SizedBox(width: 2),
              if (wantTotal > 0)
                Expanded(
                  flex: wantTotal,
                  child: Container(height: 8, color: wantColor),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              rupiah(needTotal),
              style: context.moneyStyle(
                fontSize: 12,
                color: needColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              rupiah(wantTotal),
              style: context.moneyStyle(
                fontSize: 12,
                color: wantColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Pemasukan dan pengeluaran tiap periode dalam 6 periode terakhir.
class _TrendTable extends StatelessWidget {
  const _TrendTable({required this.txs, required this.period});

  final List<TransactionEntry> txs;
  final Period period;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final periods = [for (var i = 5; i >= 0; i--) period.shift(-i)];

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int idx = 0; idx < periods.length; idx++)
            Builder(
              builder: (context) {
                final p = periods.reversed.toList()[idx];
                final inPeriod = txs.where((t) => p.contains(t.date));
                final income = inPeriod
                    .where((t) => t.type == TxType.income)
                    .fold<int>(0, (a, t) => a + t.amount);
                final expense = inPeriod
                    .where((t) => t.type == TxType.expense)
                    .fold<int>(0, (a, t) => a + t.amount);
                return Column(
                  children: [
                    ListTile(
                      dense: true,
                      title: Text(
                        p.label(),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: colors.textPrimary,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+${rupiah(income)}',
                            style: context.moneyStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.income,
                            ),
                          ),
                          Text(
                            '-${rupiah(expense)}',
                            style: context.moneyStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.expense,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (idx < periods.length - 1)
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: colors.borderOutline.withValues(alpha: 0.3),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HarvestRecapBanner extends StatelessWidget {
  const _HarvestRecapBanner({
    required this.periodLabel,
    required this.isWeekly,
    required this.hasUnread,
    required this.onTap,
  });

  final String periodLabel;
  final bool isWeekly;
  final bool hasUnread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final badgeAccent = colors.isDark ? AppColors.dewMint : colors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors.isDark
                ? [
                    AppColors.emeraldLeaf.withValues(alpha: 0.24),
                    AppColors.cardSurface.withValues(alpha: 0.96),
                  ]
                : [colors.primary.withValues(alpha: 0.08), colors.cardSurface],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: badgeAccent.withValues(alpha: hasUnread ? 0.55 : 0.26),
          ),
          boxShadow: colors.isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: badgeAccent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: badgeAccent.withValues(alpha: 0.3)),
              ),
              child: AppDuotoneIcon(
                PhosphorIconsDuotone.chartPieSlice,
                size: 20,
                color: badgeAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          context.tr(
                            isWeekly
                                ? 'Weekly Financial Review'
                                : 'Monthly Financial Review',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            context.tr('Ready'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: badgeAccent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr('Review completed recap for {period}', {
                      'period': periodLabel,
                    }),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: colors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: badgeAccent, size: 20),
          ],
        ),
      ),
    );
  }
}

class _FinancialRecapSheet extends ConsumerStatefulWidget {
  const _FinancialRecapSheet({required this.initialType, this.onViewed});

  final PeriodType initialType;
  final VoidCallback? onViewed;

  @override
  ConsumerState<_FinancialRecapSheet> createState() =>
      _FinancialRecapSheetState();
}

class _FinancialRecapSheetState extends ConsumerState<_FinancialRecapSheet> {
  late PeriodType _type;
  late Future<RecapPeriodSummary> _recapFuture;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _recapFuture = _loadRecap(_type);
  }

  Future<RecapPeriodSummary> _loadRecap(PeriodType type) async {
    final appPrefs = ref.read(appPrefsProvider);
    final currentPeriod = Period.containing(
      type,
      DateTime.now(),
      firstDayOfWeek: appPrefs.firstDayOfWeek,
      firstDayOfMonth: appPrefs.firstDayOfMonth,
    );
    final completedPeriod = currentPeriod.shift(-1);
    final priorPeriod = completedPeriod.shift(-1);

    final db = ref.read(databaseProvider);
    final txs = await db.transactionsBetween(
      priorPeriod.start,
      completedPeriod.end,
    );
    final completedTxs = txs
        .where((t) => completedPeriod.contains(t.date))
        .toList();
    final priorTxs = txs.where((t) => priorPeriod.contains(t.date)).toList();

    final cats = ref.read(categoryMapProvider);
    final goals = ref.read(savingsGoalsProvider).value ?? const <SavingsGoal>[];

    final prefs = ref.read(sharedPreferencesProvider);
    final seenKey = type == PeriodType.weekly
        ? 'last_recap_seen_weekly'
        : 'last_recap_seen_monthly';
    await prefs.setString(seenKey, completedPeriod.key);
    widget.onViewed?.call();

    return InsightEngine.computeRecap(
      completedPeriod: completedPeriod,
      completedTxs: completedTxs,
      priorTxs: priorTxs,
      categoryMap: cats,
      goals: goals,
      translate: trG,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.themeColors;
    final recapAccent = colors.isDark ? AppColors.dewMint : colors.primary;
    final maxH = MediaQuery.of(context).size.height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: recapAccent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AppDuotoneIcon(
                      PhosphorIconsDuotone.chartPieSlice,
                      size: 22,
                      color: recapAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('Financial Recap'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          context.tr('Financial Review'),
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SegmentedButton<PeriodType>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: PeriodType.weekly,
                    label: Text(context.tr('Weekly Recap')),
                  ),
                  ButtonSegment(
                    value: PeriodType.monthly,
                    label: Text(context.tr('Monthly Recap')),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) {
                  setState(() {
                    _type = s.first;
                    _recapFuture = _loadRecap(_type);
                  });
                },
              ),
              const SizedBox(height: 14),
              Flexible(
                child: FutureBuilder<RecapPeriodSummary>(
                  future: _recapFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final recap = snapshot.data;
                    if (recap == null || !recap.hasData) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: EmptyStateCard(
                          icon: Icons.insights_outlined,
                          illustrationAsset:
                              'assets/illustrations/empty_analytics.png',
                          title: context.tr('No recap activity yet'),
                          subtitle: context.tr(
                            'No transactions were recorded during this completed period.',
                          ),
                        ),
                      );
                    }

                    final taggedTotal = recap.needTotal + recap.wantTotal;
                    final needPct = taggedTotal > 0
                        ? ((recap.needTotal / taggedTotal) * 100).round()
                        : 0;
                    final wantPct = taggedTotal > 0 ? 100 - needPct : 0;

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          HeroCard(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        recap.period.label(),
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (recap.isDeficit
                                                    ? colors.onHeroExpense
                                                    : colors.onHeroIncome)
                                                .withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        recap.isDeficit
                                            ? context.tr('Deficit')
                                            : context.tr('{pct}% Saved', {
                                                'pct': recap.savingsRate
                                                    .toStringAsFixed(0),
                                              }),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: recap.isDeficit
                                              ? colors.onHeroExpense
                                              : colors.onHeroIncome,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.tr('Net Savings'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white60,
                                  ),
                                ),
                                Text(
                                  '${recap.netSavings >= 0 ? '+' : ''}${rupiah(recap.netSavings)}',
                                  style: context.moneyStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                if (recap.expensePctChange != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    recap.expensePctChange! <= 0
                                        ? context.tr(
                                            'Spending down {pct}% vs prior period',
                                            {
                                              'pct': recap.expensePctChange!
                                                  .abs()
                                                  .toStringAsFixed(0),
                                            },
                                          )
                                        : context.tr(
                                            'Spending up {pct}% vs prior period',
                                            {
                                              'pct': recap.expensePctChange!
                                                  .abs()
                                                  .toStringAsFixed(0),
                                            },
                                          ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: recap.expensePctChange! <= 0
                                          ? colors.onHeroIncome
                                          : colors.onHeroExpense,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _SummarySubBox(
                                        label: context.tr('Income'),
                                        amount: rupiah(recap.totalIncome),
                                        icon: Icons.arrow_downward_rounded,
                                        iconColor: colors.onHeroIncome,
                                        bgColor: colors.isDark
                                            ? const Color(0xFF0F221B)
                                                  .withValues(alpha: 0.65)
                                            : Colors.black.withValues(
                                                alpha: 0.22,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _SummarySubBox(
                                        label: context.tr('Expense'),
                                        amount: rupiah(recap.totalExpense),
                                        icon: Icons.arrow_upward_rounded,
                                        iconColor: colors.onHeroExpense,
                                        bgColor: colors.isDark
                                            ? const Color(0xFF0F221B)
                                                  .withValues(alpha: 0.65)
                                            : Colors.black.withValues(
                                                alpha: 0.22,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (recap.topCategories.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              context.tr('Top Categories'),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: recapAccent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AppCard(
                              child: Column(
                                children: [
                                  for (
                                    int i = 0;
                                    i < recap.topCategories.length;
                                    i++
                                  )
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        children: [
                                          CategoryBadge(
                                            icon: iconFor(
                                              recap.topCategories[i].icon,
                                            ),
                                            color: Color(
                                              recap.topCategories[i].colorValue,
                                            ),
                                            categoryKey:
                                                recap.topCategories[i].icon,
                                            size: 32,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  context.tr(
                                                    recap.topCategories[i].name,
                                                  ),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13.5,
                                                    color: colors.textPrimary,
                                                  ),
                                                ),
                                                Text(
                                                  '${recap.topCategories[i].txCount} ${context.tr('transactions')} • ${recap.topCategories[i].percentage.toStringAsFixed(0)}%',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: colors.textMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            rupiah(
                                              recap.topCategories[i].amount,
                                            ),
                                            style: context.moneyStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                              color: colors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                          if (taggedTotal > 0) ...[
                            const SizedBox(height: 12),
                            AppCard(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${context.tr('Needs')}: $needPct%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: colors.income,
                                    ),
                                  ),
                                  Text(
                                    '${context.tr('Wants')}: $wantPct%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: colors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (recap.topSavingCategory != null) ...[
                            const SizedBox(height: 10),
                            _SmartInsightCard(
                              item: SmartInsightItem(
                                title: context.tr('Biggest Cut: {category}', {
                                  'category': recap.topSavingCategory!.name,
                                }),
                                description: context.tr(
                                  'Saved {amount} (-{pct}%) vs prior period.',
                                  {
                                    'amount': rupiah(
                                      recap.topSavingCategory!.diffAmount,
                                    ),
                                    'pct': recap.topSavingCategory!.pctChange
                                        .abs()
                                        .toStringAsFixed(0),
                                  },
                                ),
                                icon: Icons.trending_down_rounded,
                                accentColor: colors.income,
                              ),
                            ),
                          ],
                          if (recap.topSurgeCategory != null) ...[
                            const SizedBox(height: 4),
                            _SmartInsightCard(
                              item: SmartInsightItem(
                                title: context.tr('Watch Area: {category}', {
                                  'category': recap.topSurgeCategory!.name,
                                }),
                                description: context.tr(
                                  'Increased by {amount} (+{pct}%) vs prior period.',
                                  {
                                    'amount': rupiah(
                                      recap.topSurgeCategory!.diffAmount,
                                    ),
                                    'pct': recap.topSurgeCategory!.pctChange
                                        .abs()
                                        .toStringAsFixed(0),
                                  },
                                ),
                                icon: Icons.trending_up_rounded,
                                accentColor: colors.warning,
                              ),
                            ),
                          ],
                          if (recap.activeGoalsCount > 0) ...[
                            const SizedBox(height: 10),
                            AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        context.tr('Savings Goals Progress'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${recap.activeGoalsCount} ${context.tr('Goals')}',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: colors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  AppProgressBar(
                                    value: recap.goalsTargetTotal > 0
                                        ? recap.goalsSavedTotal /
                                              recap.goalsTargetTotal
                                        : 0,
                                    color: recapAccent,
                                    backgroundColor: colors.isDark
                                        ? AppColors.mossShadow.withValues(
                                            alpha: 0.6,
                                          )
                                        : colors.surfaceContainer,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${rupiah(recap.goalsSavedTotal)} / ${rupiah(recap.goalsTargetTotal)}',
                                    style: context.moneyStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: recapAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

(String labelKey, Color color) _vitalityTierMeta(
  BuildContext context,
  VitalityTier tier, {
  bool onHero = false,
}) {
  final colors = context.themeColors;
  if (onHero) {
    return switch (tier) {
      VitalityTier.thriving => ('Thriving', colors.onHeroIncome),
      VitalityTier.steadyGrowth => (
        'Steady Growth',
        colors.isDark ? AppColors.dewMint : AppColors.goldenYellow,
      ),
      VitalityTier.needsCare => (
        'Needs Care',
        colors.isDark ? AppColors.warning : const Color(0xFFFCD34D),
      ),
      VitalityTier.fragile => ('Fragile', colors.onHeroExpense),
      VitalityTier.starter => (
        'Starter',
        colors.isDark ? AppColors.freshSage : Colors.white70,
      ),
    };
  }
  return switch (tier) {
    VitalityTier.thriving => ('Thriving', colors.income),
    VitalityTier.steadyGrowth => ('Steady Growth', colors.accentSecondary),
    VitalityTier.needsCare => ('Needs Care', colors.warning),
    VitalityTier.fragile => ('Fragile', colors.expense),
    VitalityTier.starter => ('Starter', colors.textMuted),
  };
}

class _NetWorthVitalityCard extends StatelessWidget {
  const _NetWorthVitalityCard({
    required this.netWorth,
    required this.vitality,
    required this.onTap,
  });

  final NetWorthSummary netWorth;
  final VitalityScoreSummary vitality;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final (tierKey, tierColor) = _vitalityTierMeta(context, vitality.tier);
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppDuotoneIcon(
                  PhosphorIconsDuotone.sparkle,
                  size: 22,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Net Worth'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rupiah(netWorth.netWorth),
                      style: context.moneyStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: netWorth.netWorth >= 0
                            ? colors.textPrimary
                            : colors.expense,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tierColor.withValues(alpha: 0.38)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppDuotoneIcon(
                      PhosphorIconsDuotone.plant,
                      size: 16,
                      color: tierColor,
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          vitality.hasEnoughData
                              ? '${vitality.score}/100'
                              : '--/100',
                          style: context.moneyStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: tierColor,
                          ),
                        ),
                        Text(
                          context.tr(tierKey),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: tierColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _NetWorthChip(
                label: context.tr('Liquid Assets'),
                amount: rupiah(netWorth.liquidAssets),
                color: colors.accentSecondary,
              ),
              if (netWorth.receivables > 0)
                _NetWorthChip(
                  label: context.tr('Receivables'),
                  amount: '+${rupiah(netWorth.receivables)}',
                  color: colors.income,
                ),
              if (netWorth.liabilities > 0)
                _NetWorthChip(
                  label: context.tr('Liabilities'),
                  amount: '-${rupiah(netWorth.liabilities)}',
                  color: colors.expense,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  vitality.hasEnoughData
                      ? context.tr(
                          'Financial Health Score • {n}/4 pillars active',
                          {'n': vitality.activePillarCount},
                        )
                      : context.tr(
                          'Record activity to unlock your Financial Health Score',
                        ),
                  style: TextStyle(fontSize: 11.5, color: colors.textMuted),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colors.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetWorthChip extends StatelessWidget {
  const _NetWorthChip({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11.5, color: colors.textMuted),
        ),
        Text(
          amount,
          style: context.moneyStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _VitalityDetailsSheet extends StatelessWidget {
  const _VitalityDetailsSheet({required this.netWorth, required this.vitality});

  final NetWorthSummary netWorth;
  final VitalityScoreSummary vitality;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final (tierKey, tierColor) = _vitalityTierMeta(
      context,
      vitality.tier,
      onHero: true,
    );
    final pillarAccent = colors.isDark ? AppColors.dewMint : colors.primary;
    final maxH = MediaQuery.of(context).size.height * 0.84;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AppDuotoneIcon(
                      PhosphorIconsDuotone.sparkle,
                      size: 22,
                      color: pillarAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('Net Worth & Vitality Score'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                HeroCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('Financial Health Score'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tierColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              context.tr(tierKey),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: tierColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        vitality.hasEnoughData
                            ? '${vitality.score} / 100'
                            : '-- / 100',
                        style: context.moneyStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AppProgressBar(
                        value: vitality.hasEnoughData
                            ? vitality.score / 100.0
                            : 0.0,
                        color: tierColor,
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('Net Worth Breakdown'),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _NetWorthLine(
                        label: context.tr('Liquid Assets'),
                        amount: rupiah(netWorth.liquidAssets),
                        color: colors.accentSecondary,
                      ),
                      const SizedBox(height: 6),
                      _NetWorthLine(
                        label: context.tr('Receivables'),
                        amount: '+${rupiah(netWorth.receivables)}',
                        color: colors.income,
                      ),
                      const SizedBox(height: 6),
                      _NetWorthLine(
                        label: context.tr('Liabilities'),
                        amount: '-${rupiah(netWorth.liabilities)}',
                        color: colors.expense,
                      ),
                      Divider(
                        height: 18,
                        color: colors.borderOutline.withValues(alpha: 0.35),
                      ),
                      _NetWorthLine(
                        label: context.tr('Net Worth'),
                        amount: rupiah(netWorth.netWorth),
                        color: netWorth.netWorth >= 0
                            ? colors.textPrimary
                            : colors.expense,
                        bold: true,
                      ),
                      if (netWorth.allocatedGoalReserve > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          context.tr(
                            'Allocated to Savings Goals: {amount} (already tracked inside accounts or virtual reserve).',
                            {'amount': rupiah(netWorth.allocatedGoalReserve)},
                          ),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.tr('Vitality Pillars'),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                for (final p in vitality.pillars)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      child: Opacity(
                        opacity: p.active ? 1.0 : 0.65,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.tr(p.labelKey),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  p.active
                                      ? '${p.score.round()} / ${p.maxScore.round()}'
                                      : context.tr('Inactive'),
                                  style: context.moneyStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: p.active
                                        ? pillarAccent
                                        : colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            AppProgressBar(
                              value: p.active ? p.ratio : 0.0,
                              color: p.ratio >= 0.7
                                  ? colors.income
                                  : (p.ratio >= 0.4
                                        ? colors.warning
                                        : colors.expense),
                              backgroundColor: colors.isDark
                                  ? AppColors.mossShadow.withValues(alpha: 0.6)
                                  : colors.surfaceContainer,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.tr(p.detailKey, p.detailArgs),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
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

class _NetWorthLine extends StatelessWidget {
  const _NetWorthLine({
    required this.label,
    required this.amount,
    required this.color,
    this.bold = false,
  });

  final String label;
  final String amount;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 13.5 : 12.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: bold ? colors.textPrimary : colors.textMuted,
          ),
        ),
        Text(
          amount,
          style: context.moneyStyle(
            fontSize: bold ? 14 : 12.5,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
