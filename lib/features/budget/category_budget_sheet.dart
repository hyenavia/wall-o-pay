/// Bottom sheet interaktif untuk memindahkan kategori ke pilar anggaran lain
/// (Kebutuhan, Keinginan, atau Tabungan) serta menetapkan batas anggaran spesifik per kategori.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_database.dart';
import '../../data/budget_rule.dart';
import '../../data/providers.dart';

/// Bottom sheet untuk mengubah pilar kelompok (Kebutuhan/Keinginan/Tabungan) dan limit anggaran spesifik kategori.
Future<void> showCategoryBudgetSheet(
  BuildContext context,
  WidgetRef ref,
  Category category,
  String periodKey,
  int? currentBudget,
  BudgetBucket currentBucket,
) async {
  var selectedBucket = currentBucket;
  final budgetController = TextEditingController(
    text: (currentBudget != null && currentBudget > 0) ? currentBudget.toString() : '',
  );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.mossShadow,
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      side: BorderSide(
        color: AppColors.dewMint.withValues(alpha: 0.25),
        width: 1,
      ),
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
                      color: AppColors.dewMint.withValues(alpha: 0.35),
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
                      categoryKey: category.icon,
                      size: 44,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoryName(context, category),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: AppColors.softIvory,
                            ),
                          ),
                          Text(
                            context.tr('Manage Category & Budget'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.freshSage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr('Select Budget Group'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.softIvory,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final b in BudgetBucket.values)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: ChoiceChip(
                            side: BorderSide(
                              color: selectedBucket == b
                                  ? b.color
                                  : AppColors.dewMint.withValues(alpha: 0.2),
                              width: 1,
                            ),
                            backgroundColor: AppColors.emeraldLeaf.withValues(alpha: 0.25),
                            label: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  b.icon,
                                  size: 18,
                                  color: selectedBucket == b ? AppColors.deepForest : b.color,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  b.shortName(context),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: selectedBucket == b
                                        ? FontWeight.w800
                                        : FontWeight.normal,
                                    color: selectedBucket == b ? AppColors.deepForest : AppColors.softIvory,
                                  ),
                                ),
                                Text(
                                  '${b.percentage}%',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: selectedBucket == b
                                        ? AppColors.deepForest.withValues(alpha: 0.8)
                                        : AppColors.freshSage,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.softIvory,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('Enter 0 to remove specific limit'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.freshSage,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: budgetController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: AppColors.softIvory,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(
                      color: AppColors.dewMint,
                      fontWeight: FontWeight.w700,
                    ),
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: AppColors.freshSage.withValues(alpha: 0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.dewMint.withValues(alpha: 0.25),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.dewMint.withValues(alpha: 0.25),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.dewMint,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.deepForest.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.dewMint,
                      foregroundColor: AppColors.deepForest,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                    child: Text(
                      context.tr('Save'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
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

