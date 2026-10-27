import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_database.dart';
import '../../data/providers.dart';
import '../../data/tables.dart' show TxType;

class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final catsAsync = ref.watch(categoriesProvider);
    final budgets = ref.watch(budgetByCategoryProvider);
    final spent = ref.watch(spentByCategoryProvider);
    final muted = scheme.onSurface.withValues(alpha: 0.6);

    Future<void> editBudget(Category c) async {
      final period = ref.read(selectedPeriodProvider);
      final db = ref.read(databaseProvider);
      final result = await showAmountDialog(
        context,
        title: context.tr('Budget for {name}', {'name': categoryName(context, c)}),
        initial: budgets[c.id],
        helper: context.tr('Enter 0 to remove the budget'),
      );
      if (result != null) {
        await db.setBudget(c.id, period.key, result);
      }
    }

    return Scaffold(
      appBar: pageAppBar(context, title: Text(context.tr('Budget'))),
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(context.tr('Could not load data: {error}', {'error': e})),
        ),
        data: (all) {
          final cats = all.where((c) => c.type == TxType.expense).toList();
          final budgeted = cats.where((c) => (budgets[c.id] ?? 0) > 0).toList()
            ..sort((a, b) {
              double r(Category c) => (spent[c.id] ?? 0) / budgets[c.id]!;
              return r(b).compareTo(r(a));
            });
          final unbudgeted = cats.where((c) => (budgets[c.id] ?? 0) == 0).toList();

          final totalBudget = budgeted.fold<int>(0, (s, c) => s + budgets[c.id]!);
          final totalSpent = budgeted.fold<int>(0, (s, c) => s + (spent[c.id] ?? 0));
          final ratio = totalBudget == 0 ? 0.0 : totalSpent / totalBudget;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              const Center(child: PeriodSwitcher()),
              const SizedBox(height: 4),
              HeroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('Total Budget'),
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(
                      rupiah(totalBudget),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (totalBudget > 0) ...[
                      AppProgressBar(
                        value: ratio,
                        color: ratio > 1 ? AppColors.expense : AppColors.sage,
                        backgroundColor: Colors.white24,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.tr('{amount} spent', {'amount': rupiah(totalSpent)}),
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ),
                          Text(
                            context.tr('{pct}% used', {'pct': (ratio * 100).round()}),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ] else
                      Text(
                        context.tr('Tap a category below to set a budget.'),
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                  ],
                ),
              ),
              if (budgeted.isNotEmpty) SectionHeader(title: context.tr('Categories')),
              for (final c in budgeted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BudgetCard(
                    category: c,
                    budget: budgets[c.id]!,
                    spent: spent[c.id] ?? 0,
                    onTap: () => editBudget(c),
                  ),
                ),
              if (unbudgeted.isNotEmpty) ...[
                SectionHeader(title: context.tr('Not budgeted yet')),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final c in unbudgeted)
                        ListTile(
                          onTap: () => editBudget(c),
                          leading: CategoryBadge(
                            icon: iconFor(c.icon),
                            color: Color(c.colorValue),
                            size: 40,
                          ),
                          title: Text(categoryName(context, c),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          trailing: Text(context.tr('Set budget'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              )),
                          subtitle: (spent[c.id] ?? 0) > 0
                              ? Text(context.tr('{amount} spent', {'amount': rupiah(spent[c.id]!)}),
                                  style: TextStyle(color: muted))
                              : null,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.category,
    required this.budget,
    required this.spent,
    required this.onTap,
  });

  final Category category;
  final int budget;
  final int spent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ratio = spent / budget;
    final color = budgetColor(ratio, scheme);

    return AppCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              CategoryBadge(
                icon: iconFor(category.icon),
                color: Color(category.colorValue),
                size: 42,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(categoryName(context, category),
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      '${rupiah(spent)} / ${rupiah(budget)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(ratio * 100).round()}%',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppProgressBar(value: ratio, color: color),
          if (ratio > 1) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.tr('Over by {amount}', {'amount': rupiah(spent - budget)}),
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.expense),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
