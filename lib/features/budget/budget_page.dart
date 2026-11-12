/// Halaman utama pengelolaan anggaran ([BudgetPage]) yang menampilkan total anggaran periode,
/// ringkasan metode 50/30/20 (atau alokasi kustom), informasi rollover, dan kartu tiga pilar anggaran.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_database.dart' show Budget;
import '../../data/budget_rule.dart';
import '../../data/feature_prefs.dart';
import '../../data/feature_providers.dart';
import '../../data/providers.dart';
import '../goals/goals_page.dart';
import 'budget_pillar_card.dart';
import 'category_budget_sheet.dart';
import 'total_budget_dialog.dart';

/// Widget halaman tab Anggaran (Budget) pada navigasi utama.
class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final period = ref.watch(selectedPeriodProvider);
    final prevPeriod = ref.watch(prevPeriodProvider);
    final catsAsync = ref.watch(categoriesProvider);
    final baseBudgets = ref.watch(budgetByCategoryProvider);
    final budgets = ref.watch(effectiveBudgetProvider);
    final prevBudgets = ref.watch(prevBudgetsProvider).maybeWhen(
          data: (l) => l.where((b) => b.amount > 0).toList(),
          orElse: () => const <Budget>[],
        );
    final carry = ref.watch(carryOverProvider);
    final totalCarry = ref.watch(totalCarryOverProvider);
    final rolloverActive = ref.watch(
      featurePrefsProvider.select((p) => p.rollover),
    );
    final spent = ref.watch(spentByCategoryProvider);
    final breakdown = ref.watch(budget503020BreakdownProvider);
    final budgetRule = ref.watch(budgetRuleProvider);
    final prevPool = budgetRule.getTotalBudget(prevPeriod.key);
    final canCopyPrev = breakdown.totalBudget <= 0 &&
        !baseBudgets.values.any((v) => v > 0) &&
        (budgetRule.hasPeriodConfig(prevPeriod.key) || prevBudgets.isNotEmpty);

    return Scaffold(
      appBar: pageAppBar(
        context,
        title: Text(context.tr('Budget')),
        bottom: const Center(child: PeriodSwitcher(onDark: true)),
        bottomHeight: 44,
      ),
      body: BotanicalBackgroundSheet(
        child: catsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              context.tr('Could not load data: {error}', {'error': e}),
            ),
          ),
          data: (all) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
              children: [
                const SizedBox(height: 6),

                // ===============================================================
                // 1. HERO CARD: TOTAL ANGGARAN & METODE 50/30/20
                // ===============================================================
                HeroCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('Total Budget'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  rupiah(breakdown.totalBudget),
                                  style: context.moneyStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.edit_outlined, size: 15),
                            label: Text(
                              breakdown.totalBudget > 0
                                  ? context.tr('Edit')
                                  : context.tr('Set budget'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.16,
                              ),
                              foregroundColor: AppColors.dewMint,
                              side: BorderSide(
                                color: AppColors.dewMint.withValues(alpha: 0.35),
                                width: 1,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => showTotalBudgetDialog(
                              context,
                              ref,
                              period.key,
                              breakdown,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (breakdown.totalBudget > 0) ...[
                        // Overall Progress Bar
                        AppProgressBar(
                          value: breakdown.overallRatio,
                          color: breakdown.overallRatio > 1
                              ? AppColors.expenseOnDark
                              : AppColors.dewMint,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.tr('{amount} spent', {
                                  'amount': rupiah(breakdown.totalSpent),
                                }),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                            Text(
                              context.tr('{pct}% used', {
                                'pct': (breakdown.overallRatio * 100).round(),
                              }),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: breakdown.overallRatio > 1
                                    ? AppColors.expenseOnDark
                                    : AppColors.dewMint,
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 3-Color Ratio Bar Preview (50 / 30 / 20)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F221B).withValues(alpha: 0.70),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.dewMint.withValues(alpha: 0.18),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.pie_chart_outline_rounded, size: 14, color: AppColors.dewMint),
                                  const SizedBox(width: 6),
                                  Text(
                                    context.tr('50/30/20 Budgeting Rule'),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.dewMint,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: breakdown.needsPercentage > 0
                                          ? breakdown.needsPercentage
                                          : 50,
                                      child: Container(
                                        height: 7,
                                        color: const Color(0xFF38B271),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      flex: breakdown.wantsPercentage > 0
                                          ? breakdown.wantsPercentage
                                          : 30,
                                      child: Container(
                                        height: 7,
                                        color: const Color(0xFFE8A33D),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      flex: breakdown.savingsPercentage > 0
                                          ? breakdown.savingsPercentage
                                          : 20,
                                      child: Container(
                                        height: 7,
                                        color: const Color(0xFF5EEAD4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ratioLegend(
                                      const Color(0xFF38B271),
                                      '${breakdown.needsPercentage}% ${context.tr('Needs')}',
                                      rupiah(breakdown.needsBudget),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _ratioLegend(
                                      const Color(0xFFE8A33D),
                                      '${breakdown.wantsPercentage}% ${context.tr('Wants')}',
                                      rupiah(breakdown.wantsBudget),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _ratioLegend(
                                      const Color(0xFF5EEAD4),
                                      '${breakdown.savingsPercentage}% ${context.tr('Savings')}',
                                      rupiah(breakdown.savingsBudget),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Text(
                          context.tr(
                            'Enter your total budget to automatically split via 50/30/20 rule.',
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(context.tr('Set Total Budget')),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.dewMint,
                            foregroundColor: AppColors.deepForest,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => showTotalBudgetDialog(
                            context,
                            ref,
                            period.key,
                            breakdown,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Banner Salin Anggaran dari Periode Sebelumnya (jika periode ini masih kosong)
                if (canCopyPrev)
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 2),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.mossShadow.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.dewMint.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.dewMint.withValues(alpha: 0.16),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.content_copy_rounded,
                                color: AppColors.dewMint,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('No budget set for this period'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.softIvory,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    prevPool > 0
                                        ? context.tr(
                                            'Reuse budget setup from {period} ({amount})',
                                            {
                                              'period': prevPeriod.label,
                                              'amount': rupiah(prevPool),
                                            },
                                          )
                                        : context.tr(
                                            'Reuse budget setup from {period}',
                                            {'period': prevPeriod.label},
                                          ),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.freshSage,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            icon: const Icon(Icons.copy_all_rounded, size: 16),
                            label: Text(
                              context.tr('Copy from {period}', {
                                'period': prevPeriod.label,
                              }),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  AppColors.dewMint.withValues(alpha: 0.18),
                              foregroundColor: AppColors.dewMint,
                              side: BorderSide(
                                color: AppColors.dewMint.withValues(alpha: 0.35),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              await ref
                                  .read(budgetRuleProvider.notifier)
                                  .copyFromPeriod(prevPeriod.key, period.key);
                              final db = ref.read(databaseProvider);
                              for (final b in prevBudgets) {
                                await db.setBudget(
                                  b.categoryId,
                                  period.key,
                                  b.amount,
                                );
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.tr(
                                        'Copied budget from {period}',
                                        {'period': prevPeriod.label},
                                      ),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                // Banner Sisa Anggaran Bergulir (Rollover)
                if (rolloverActive && totalCarry > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mossShadow.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.dewMint.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.dewMint.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.redo_rounded,
                            color: AppColors.dewMint,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.tr(
                              'Rollover active: +{amount} from last period',
                              {'amount': rupiah(totalCarry)},
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AppColors.softIvory,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),

                // ===============================================================
                // 2. PILAR 1: KEBUTUHAN (NEEDS - 50%)
                // ===============================================================
                BudgetPillarCard(
                  bucket: BudgetBucket.needs,
                  percentage: breakdown.needsPercentage,
                  allocated: breakdown.needsBudget,
                  spent: breakdown.needsSpent,
                  ratio: breakdown.needsRatio,
                  categories: breakdown.needsCategories,
                  categoryBudgets: budgets,
                  categorySpent: spent,
                  categoryCarryOver: carry,
                  onTapCategory: (c) => showCategoryBudgetSheet(
                    context,
                    ref,
                    c,
                    period.key,
                    budgets[c.id],
                    BudgetBucket.needs,
                  ),
                ),
                const SizedBox(height: 14),

                // ===============================================================
                // 3. PILAR 2: KEINGINAN (WANTS - 30%)
                // ===============================================================
                BudgetPillarCard(
                  bucket: BudgetBucket.wants,
                  percentage: breakdown.wantsPercentage,
                  allocated: breakdown.wantsBudget,
                  spent: breakdown.wantsSpent,
                  ratio: breakdown.wantsRatio,
                  categories: breakdown.wantsCategories,
                  categoryBudgets: budgets,
                  categorySpent: spent,
                  categoryCarryOver: carry,
                  onTapCategory: (c) => showCategoryBudgetSheet(
                    context,
                    ref,
                    c,
                    period.key,
                    budgets[c.id],
                    BudgetBucket.wants,
                  ),
                ),
                const SizedBox(height: 14),

                // ===============================================================
                // 4. PILAR 3: TABUNGAN & TARGET (SAVINGS - 20%)
                // ===============================================================
                BudgetPillarCard(
                  bucket: BudgetBucket.savings,
                  percentage: breakdown.savingsPercentage,
                  allocated: breakdown.savingsBudget,
                  spent: breakdown.savingsSpent,
                  ratio: breakdown.savingsRatio,
                  categories: breakdown.savingsCategories,
                  categoryBudgets: budgets,
                  categorySpent: spent,
                  categoryCarryOver: carry,
                  onTapCategory: (c) => showCategoryBudgetSheet(
                    context,
                    ref,
                    c,
                    period.key,
                    budgets[c.id],
                    BudgetBucket.savings,
                  ),
                  footerWidget: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppColors.dewMint.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5EEAD4).withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF5EEAD4).withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.track_changes_rounded,
                          color: Color(0xFF5EEAD4),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        context.tr('Manage Savings Goals'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.softIvory,
                        ),
                      ),
                      subtitle: Text(
                        context.tr(
                          'View your active savings targets in Goals tab.',
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.freshSage,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.freshSage,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const GoalsPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _ratioLegend(Color color, String title, String amount) {
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
                color: color.withValues(alpha: 0.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                amount,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
