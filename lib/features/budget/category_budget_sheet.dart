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
                                Icon(
                                  b.icon,
                                  size: 18,
                                  color: selectedBucket == b ? Colors.white : b.color,
                                ),
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

