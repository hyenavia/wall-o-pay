import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_database.dart';
import '../../data/budget_rule.dart';
import '../../data/providers.dart';
import '../goals/goals_page.dart';

class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final period = ref.watch(selectedPeriodProvider);
    final catsAsync = ref.watch(categoriesProvider);
    final budgets = ref.watch(budgetByCategoryProvider);
    final spent = ref.watch(spentByCategoryProvider);
    final breakdown = ref.watch(budget503020BreakdownProvider);

    return Scaffold(
      appBar: pageAppBar(context, title: Text(context.tr('Budget'))),
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(context.tr('Could not load data: {error}', {'error': e})),
        ),
        data: (all) {

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const Center(child: PeriodSwitcher()),
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
                          onPressed: () => _showTotalBudgetDialog(
                            context,
                            ref,
                            period.key,
                            breakdown.totalBudget,
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
                                    flex: 50,
                                    child: Container(
                                      height: 6,
                                      color: BudgetBucket.needs.color,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    flex: 30,
                                    child: Container(
                                      height: 6,
                                      color: BudgetBucket.wants.color,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    flex: 20,
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
                                _ratioLegend(BudgetBucket.needs.color, '50% ${context.tr('Needs')}',
                                    rupiah(breakdown.needsBudget)),
                                _ratioLegend(BudgetBucket.wants.color, '30% ${context.tr('Wants')}',
                                    rupiah(breakdown.wantsBudget)),
                                _ratioLegend(BudgetBucket.savings.color, '20% ${context.tr('Savings')}',
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
                        onPressed: () => _showTotalBudgetDialog(
                          context,
                          ref,
                          period.key,
                          0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ===============================================================
              // 2. PILAR 1: KEBUTUHAN (NEEDS - 50%)
              // ===============================================================
              _PillarCard(
                bucket: BudgetBucket.needs,
                allocated: breakdown.needsBudget,
                spent: breakdown.needsSpent,
                ratio: breakdown.needsRatio,
                categories: breakdown.needsCategories,
                categoryBudgets: budgets,
                categorySpent: spent,
                onTapCategory: (c) => _showCategoryManageSheet(
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
              _PillarCard(
                bucket: BudgetBucket.wants,
                allocated: breakdown.wantsBudget,
                spent: breakdown.wantsSpent,
                ratio: breakdown.wantsRatio,
                categories: breakdown.wantsCategories,
                categoryBudgets: budgets,
                categorySpent: spent,
                onTapCategory: (c) => _showCategoryManageSheet(
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
              _PillarCard(
                bucket: BudgetBucket.savings,
                allocated: breakdown.savingsBudget,
                spent: breakdown.savingsSpent,
                ratio: breakdown.savingsRatio,
                categories: breakdown.savingsCategories,
                categoryBudgets: budgets,
                categorySpent: spent,
                onTapCategory: (c) => _showCategoryManageSheet(
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

  /// Dialog memasukkan total anggaran bulanan/mingguan
  Future<void> _showTotalBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    String periodKey,
    int currentAmount,
  ) async {
    final controller = TextEditingController(
      text: currentAmount > 0 ? currentAmount.toString() : '',
    );
    final theme = Theme.of(context);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final val = int.tryParse(controller.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            final nBudget = (val * 0.5).round();
            final wBudget = (val * 0.3).round();
            final sBudget = val > 0 ? (val - nBudget - wBudget) : 0;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.deepForest.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.calculate_outlined, color: AppColors.deepForest),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('Total Budget'),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                          'Enter your total budget to automatically split via 50/30/20 rule.'),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        hintText: '0',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('Budget Split Preview:'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          _previewRow(
                            BudgetBucket.needs.color,
                            context.tr('Needs (50%)'),
                            rupiah(nBudget),
                          ),
                          const Divider(height: 12),
                          _previewRow(
                            BudgetBucket.wants.color,
                            context.tr('Wants (30%)'),
                            rupiah(wBudget),
                          ),
                          const Divider(height: 12),
                          _previewRow(
                            BudgetBucket.savings.color,
                            context.tr('Savings & Goals (20%)'),
                            rupiah(sBudget),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(context.tr('Cancel')),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.deepForest,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await ref.read(budgetRuleProvider.notifier).setTotalBudget(periodKey, val);
                  },
                  child: Text(context.tr('Save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _previewRow(Color color, String title, String amount) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 12)),
        ),
        Text(amount, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }

  /// Bottom sheet untuk mengubah pilar kelompok (Kebutuhan/Keinginan/Tabungan) dan limit spesifik
  Future<void> _showCategoryManageSheet(
    BuildContext context,
    WidgetRef ref,
    Category category,
    String periodKey,
    int? currentBudget,
    BudgetBucket currentBucket,
  ) async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    var selectedBucket = currentBucket;
    final budgetController = TextEditingController(
      text: (currentBudget != null && currentBudget > 0) ? currentBudget.toString() : '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CategoryBadge(
                        icon: iconFor(category.icon),
                        color: Color(category.colorValue),
                        size: 44,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryName(context, category),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                            ),
                            Text(
                              context.tr('Manage Category & Budget'),
                              style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.tr('Select Budget Group'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final b in BudgetBucket.values)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: ChoiceChip(
                              label: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(b.icon,
                                      size: 18,
                                      color: selectedBucket == b ? Colors.white : b.color),
                                  const SizedBox(height: 2),
                                  Text(
                                    b.shortName(context),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: selectedBucket == b
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  Text(
                                    '${b.percentage}%',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: selectedBucket == b
                                          ? Colors.white70
                                          : scheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                              selected: selectedBucket == b,
                              selectedColor: b.color,
                              onSelected: (val) {
                                if (val) setState(() => selectedBucket = b);
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.tr('Specific category limit (optional)'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('Enter 0 to remove specific limit'),
                    style: TextStyle(fontSize: 11, color: scheme.onSurface.withValues(alpha: 0.55)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: budgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      hintText: '0',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.deepForest,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);

                        // 1. Simpan kelompok kategori
                        await ref
                            .read(budgetRuleProvider.notifier)
                            .setCategoryBucket(category.id, selectedBucket);

                        // 2. Simpan batas anggaran spesifik (jika ada)
                        final db = ref.read(databaseProvider);
                        final limitVal = int.tryParse(
                                budgetController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                            0;
                        await db.setBudget(category.id, periodKey, limitVal);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.tr('Category moved to {group}', {
                                  'group': selectedBucket.label(context),
                                }),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Text(context.tr('Save')),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Kartu satu pilar dari 50/30/20 (Kebutuhan, Keinginan, atau Tabungan)
class _PillarCard extends StatelessWidget {
  const _PillarCard({
    required this.bucket,
    required this.allocated,
    required this.spent,
    required this.ratio,
    required this.categories,
    required this.categoryBudgets,
    required this.categorySpent,
    required this.onTapCategory,
    this.footerWidget,
  });

  final BudgetBucket bucket;
  final int allocated;
  final int spent;
  final double ratio;
  final List<Category> categories;
  final Map<String, int> categoryBudgets;
  final Map<String, int> categorySpent;
  final void Function(Category) onTapCategory;
  final Widget? footerWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isOver = allocated > 0 && spent > allocated;
    final color = isOver ? AppColors.expense : bucket.color;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Pilar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: bucket.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(bucket.icon, color: bucket.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bucket.label(context),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            allocated > 0
                                ? '${rupiah(spent)} / ${rupiah(allocated)}'
                                : context.tr('Spent: {amount}', {'amount': rupiah(spent)}),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isOver ? AppColors.expense : scheme.onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (allocated > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(ratio * 100).round()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                AppProgressBar(
                  value: allocated == 0 ? 0.0 : ratio,
                  color: color,
                ),
                if (isOver) ...[
                  const SizedBox(height: 6),
                  Text(
                    context.tr('Over budget by {amount}', {'amount': rupiah(spent - allocated)}),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.expense,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // Daftar Sub-Kategori di dalam pilar
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  context.tr('No categories in this group'),
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 64),
              itemBuilder: (ctx, i) {
                final c = categories[i];
                final cSpent = categorySpent[c.id] ?? 0;
                final cBudget = categoryBudgets[c.id];
                final hasSpecificLimit = cBudget != null && cBudget > 0;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  onTap: () => onTapCategory(c),
                  leading: CategoryBadge(
                    icon: iconFor(c.icon),
                    color: Color(c.colorValue),
                    size: 40,
                  ),
                  title: Text(
                    categoryName(context, c),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    hasSpecificLimit
                        ? '${rupiah(cSpent)} / ${rupiah(cBudget)}'
                        : (cSpent > 0
                            ? context.tr('Spent: {amount}', {'amount': rupiah(cSpent)})
                            : context.tr('Tap to set budget or reassign')),
                    style: TextStyle(
                      fontSize: 12,
                      color: (hasSpecificLimit && cSpent > cBudget)
                          ? AppColors.expense
                          : scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                );
              },
            ),

          if (footerWidget != null) ...[
            const Divider(height: 1),
            footerWidget!,
          ],
        ],
      ),
    );
  }
}
