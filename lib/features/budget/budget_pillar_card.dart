/// Komponen kartu visual untuk menampilkan satu pilar anggaran (Needs, Wants, atau Savings)
/// beserta daftar kategori pengeluaran yang tergabung di dalamnya.
library;

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_database.dart';
import '../../data/budget_rule.dart';

/// Kartu satu pilar dari 50/30/20 (Kebutuhan, Keinginan, atau Tabungan)
class BudgetPillarCard extends StatelessWidget {
  const BudgetPillarCard({
    super.key,
    required this.bucket,
    required this.percentage,
    required this.allocated,
    required this.spent,
    required this.ratio,
    required this.categories,
    required this.categoryBudgets,
    required this.categorySpent,
    required this.onTapCategory,
    this.categoryCarryOver = const <String, int>{},
    this.footerWidget,
  });

  final BudgetBucket bucket;
  final int percentage;
  final int allocated;
  final int spent;
  final double ratio;
  final List<Category> categories;
  final Map<String, int> categoryBudgets;
  final Map<String, int> categorySpent;
  final Map<String, int> categoryCarryOver;
  final void Function(Category) onTapCategory;
  final Widget? footerWidget;

  @override
  Widget build(BuildContext context) {
    final bucketColor = bucket.colorIn(context);
    final isOver = allocated > 0 && spent > allocated;
    final color = isOver ? AppColors.expenseOnDark : bucketColor;

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
                        color: bucketColor.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: bucketColor.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Icon(bucket.icon, color: bucketColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bucket.label(context, percentage),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.softIvory,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            allocated > 0
                                ? '${rupiah(spent)} / ${rupiah(allocated)}'
                                : context.tr('Spent: {amount}', {'amount': rupiah(spent)}),
                            style: context.moneyStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isOver
                                  ? AppColors.expenseOnDark
                                  : AppColors.freshSage,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (allocated > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: color.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${(ratio * 100).round()}%',
                          style: context.moneyStyle(
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
                  backgroundColor: AppColors.mossShadow.withValues(alpha: 0.6),
                ),
                if (isOver) ...[
                  const SizedBox(height: 6),
                  Text(
                    context.tr('Over budget by {amount}', {'amount': rupiah(spent - allocated)}),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.expenseOnDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderOutline.withValues(alpha: 0.4)),

          // Daftar Sub-Kategori di dalam pilar
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  context.tr('No categories in this group'),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.freshSage.withValues(alpha: 0.6),
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
              separatorBuilder: (context, index) =>
                  Divider(height: 1, indent: 64, color: AppColors.borderOutline.withValues(alpha: 0.3)),
              itemBuilder: (ctx, i) {
                final c = categories[i];
                final cSpent = categorySpent[c.id] ?? 0;
                final cBudget = categoryBudgets[c.id];
                final cCarry = categoryCarryOver[c.id] ?? 0;
                final hasSpecificLimit = cBudget != null && cBudget > 0;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  onTap: () => onTapCategory(c),
                  leading: CategoryBadge(
                    icon: iconFor(c.icon),
                    color: Color(c.colorValue),
                    categoryKey: c.icon,
                    size: 40,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          categoryName(context, c),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.softIvory,
                          ),
                        ),
                      ),
                      if (cCarry > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldLeaf.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.dewMint.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '+${rupiah(cCarry)}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dewMint,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    hasSpecificLimit
                        ? (cCarry > 0
                            ? '${rupiah(cSpent)} / ${rupiah(cBudget)} (${context.tr('includes {amount} rollover', {'amount': rupiah(cCarry)})})'
                            : '${rupiah(cSpent)} / ${rupiah(cBudget)}')
                        : (cSpent > 0
                            ? context.tr('Spent: {amount}', {'amount': rupiah(cSpent)})
                            : context.tr('Tap to set budget or reassign')),
                    style: context.moneyStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: (hasSpecificLimit && cSpent > cBudget)
                          ? AppColors.expenseOnDark
                          : AppColors.freshSage,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.freshSage,
                  ),
                );
              },
            ),

          if (footerWidget != null) ...[
            Divider(height: 1, color: AppColors.borderOutline.withValues(alpha: 0.4)),
            footerWidget!,
          ],
        ],
      ),
    );
  }
}

