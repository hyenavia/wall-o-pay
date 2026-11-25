/// Halaman utama pengelolaan anggaran ([BudgetPage]) yang menampilkan total anggaran periode,
/// ringkasan metode 50/30/20 (atau alokasi kustom), informasi rollover, dan kartu tiga pilar anggaran.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
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
    final colors = context.themeColors;
    final period = ref.watch(selectedPeriodProvider);
    final prevPeriod = ref.watch(prevPeriodProvider);
    final catsAsync = ref.watch(categoriesProvider);
    final baseBudgets = ref.watch(budgetByCategoryProvider);
    final budgets = ref.watch(effectiveBudgetProvider);
    final prevBudgets = ref
        .watch(prevBudgetsProvider)
        .maybeWhen(
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
    final canCopyPrev =
        breakdown.totalBudget <= 0 &&
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
                            icon: AppDuotoneIcon(
                              PhosphorIconsDuotone.gearSix,
                              size: 16,
                              color: colors.isDark ? AppColors.dewMint : Colors.white,
                            ),
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
                              foregroundColor: colors.isDark ? AppColors.dewMint : Colors.white,
                              side: BorderSide(
                                color: (colors.isDark ? AppColors.dewMint : Colors.white)
                                    .withValues(alpha: 0.35),
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
                              ? colors.onHeroExpense
                              : (colors.isDark ? AppColors.dewMint : colors.onHeroIncome),
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
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              context.tr('{pct}% used', {
                                'pct': (breakdown.overallRatio * 100).round(),
                              }),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: breakdown.overallRatio > 1
                                    ? colors.onHeroExpense
                                    : (colors.isDark ? AppColors.dewMint : colors.onHeroIncome),
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (breakdown.overallRatio > 1) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: colors.onHeroExpense.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.onHeroExpense.withValues(alpha: 0.40)),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/new_asset/ui/budget_warning.png',
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    context.tr('Budget capacity exceeded! Pace remaining expenses carefully.'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colors.onHeroExpense,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // 3-Color Ratio Bar Preview (50 / 30 / 20)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.isDark
                                ? const Color(0xFF0F221B).withValues(alpha: 0.70)
                                : Colors.black.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colors.isDark
                                  ? AppColors.dewMint.withValues(alpha: 0.18)
                                  : Colors.white.withValues(alpha: 0.22),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.pie_chart_outline_rounded,
                                    size: 14,
                                    color: colors.isDark ? AppColors.dewMint : Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    context.tr('50/30/20 Budgeting Rule'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: colors.isDark ? AppColors.dewMint : Colors.white,
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
                                        color: colors.isDark
                                            ? const Color(0xFF38B271)
                                            : const Color(0xFF6EE7B7),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      flex: breakdown.wantsPercentage > 0
                                          ? breakdown.wantsPercentage
                                          : 30,
                                      child: Container(
                                        height: 7,
                                        color: colors.isDark
                                            ? const Color(0xFFE8A33D)
                                            : const Color(0xFFFDE68A),
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
                                      colors.isDark
                                          ? const Color(0xFF38B271)
                                          : const Color(0xFF6EE7B7),
                                      '${breakdown.needsPercentage}% ${context.tr('Needs')}',
                                      rupiah(breakdown.needsBudget),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _ratioLegend(
                                      colors.isDark
                                          ? const Color(0xFFE8A33D)
                                          : const Color(0xFFFDE68A),
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
                          icon: AppDuotoneIcon(
                            PhosphorIconsDuotone.plusCircle,
                            size: 18,
                            color: colors.isDark ? AppColors.deepForest : colors.primary,
                          ),
                          label: Text(context.tr('Set Total Budget')),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.isDark ? AppColors.dewMint : Colors.white,
                            foregroundColor: colors.isDark ? AppColors.deepForest : colors.primary,
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
                      color: colors.isDark
                          ? AppColors.mossShadow.withValues(alpha: 0.9)
                          : colors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.isDark
                            ? AppColors.dewMint.withValues(alpha: 0.3)
                            : colors.borderOutline,
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
                                color: colors.accentSecondary.withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.content_copy_rounded,
                                color: colors.accentSecondary,
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: colors.textPrimary,
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
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.textMuted,
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
                              backgroundColor: colors.primary.withValues(alpha: 0.14),
                              foregroundColor: colors.primary,
                              side: BorderSide(
                                color: colors.primary.withValues(alpha: 0.35),
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
                      color: colors.isDark
                          ? AppColors.mossShadow.withValues(alpha: 0.85)
                          : colors.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colors.isDark
                            ? AppColors.dewMint.withValues(alpha: 0.25)
                            : colors.borderOutline,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colors.accentSecondary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.redo_rounded,
                            color: colors.accentSecondary,
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
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: colors.textPrimary,
                              fontFeatures: const [FontFeature.tabularFigures()],
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
                          color: colors.borderOutline.withValues(
                            alpha: colors.isDark ? 0.35 : 0.9,
                          ),
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
                        width: 36,
                        height: 36,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: colors.transfer.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.transfer.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: AppDuotoneIcon(
                          PhosphorIconsDuotone.target,
                          size: 20,
                          color: colors.transfer,
                        ),
                      ),
                      title: Text(
                        context.tr('Manage Savings Goals'),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        context.tr(
                          'View your active savings targets in Goals tab.',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textMuted,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: colors.textMuted,
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
