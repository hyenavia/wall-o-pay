/// Halaman utama pengelolaan anggaran ([BudgetPage]) yang menampilkan total anggaran periode,
/// ringkasan metode 50/30/20 (atau alokasi kustom), informasi rollover, dan kartu tiga pilar anggaran.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
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
    final scheme = theme.colorScheme;
    final period = ref.watch(selectedPeriodProvider);
    final catsAsync = ref.watch(categoriesProvider);
    final budgets = ref.watch(effectiveBudgetProvider);
    final carry = ref.watch(carryOverProvider);
    final totalCarry = ref.watch(totalCarryOverProvider);
    final rolloverActive = ref.watch(featurePrefsProvider.select((p) => p.rollover));
    final spent = ref.watch(spentByCategoryProvider);
    final breakdown = ref.watch(budget503020BreakdownProvider);

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
            child: Text(context.tr('Could not load data: {error}', {'error': e})),
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
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                rupiah(breakdown.totalBudget),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: Text(
                            breakdown.totalBudget > 0
                                ? context.tr('Edit')
                                : context.tr('Set budget'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.18),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        color: breakdown.overallRatio > 1 ? AppColors.expense : AppColors.sage,
                        backgroundColor: Colors.white24,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.tr('{amount} spent', {
                                'amount': rupiah(breakdown.totalSpent),
                              }),
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                            ),
                          ),
                          Text(
                            context.tr('{pct}% used', {
                              'pct': (breakdown.overallRatio * 100).round(),
                            }),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 3-Color Ratio Bar Preview (50 / 30 / 20)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('50/30/20 Budgeting Rule'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white70,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: breakdown.needsPercentage > 0 ? breakdown.needsPercentage : 50,
                                    child: Container(
                                      height: 6,
                                      color: BudgetBucket.needs.color,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    flex: breakdown.wantsPercentage > 0 ? breakdown.wantsPercentage : 30,
                                    child: Container(
                                      height: 6,
                                      color: BudgetBucket.wants.color,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    flex: breakdown.savingsPercentage > 0 ? breakdown.savingsPercentage : 20,
                                    child: Container(
                                      height: 6,
                                      color: BudgetBucket.savings.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _ratioLegend(BudgetBucket.needs.color, '${breakdown.needsPercentage}% ${context.tr('Needs')}',
                                    rupiah(breakdown.needsBudget)),
                                _ratioLegend(BudgetBucket.wants.color, '${breakdown.wantsPercentage}% ${context.tr('Wants')}',
                                    rupiah(breakdown.wantsBudget)),
                                _ratioLegend(BudgetBucket.savings.color, '${breakdown.savingsPercentage}% ${context.tr('Savings')}',
                                    rupiah(breakdown.savingsBudget)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        context.tr(
                            'Enter your total budget to automatically split via 50/30/20 rule.'),
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(context.tr('Set Total Budget')),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.deepForest,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

              // Banner Sisa Anggaran Bergulir (Rollover)
              if (rolloverActive && totalCarry > 0)
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.sage.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.sage.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.redo_rounded, color: AppColors.deepForest, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.tr('Rollover active: +{amount} from last period', {
                            'amount': rupiah(totalCarry),
                          }),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppColors.deepForest,
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
                footerWidget: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: BudgetBucket.savings.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.track_changes_rounded,
                        color: BudgetBucket.savings.color, size: 20),
                  ),
                  title: Text(
                    context.tr('Manage Savings Goals'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    context.tr('View your active savings targets in Goals tab.'),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(builder: (_) => const GoalsPage()),
                    );
                  },
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.white70)),
            Text(amount,
                style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ],
    );
  }
}
