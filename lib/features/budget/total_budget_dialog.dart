import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/budget_rule.dart';

/// Menampilkan dialog untuk mengatur total anggaran dan pembagian alokasi (50/30/20 atau kustom).
Future<void> showTotalBudgetDialog(
  BuildContext context,
  WidgetRef ref,
  String periodKey,
  Budget503020Breakdown currentBreakdown,
) async {
  final scheme = Theme.of(context).colorScheme;

  int mode = currentBreakdown.isCustom ? 1 : 0; // 0 = Standar 50/30/20, 1 = Kustom Nominal

  final totalCtrl = TextEditingController(
    text: currentBreakdown.totalBudget > 0 ? currentBreakdown.totalBudget.toString() : '',
  );
  final savingsCtrl = TextEditingController(
    text: currentBreakdown.savingsBudget > 0 ? currentBreakdown.savingsBudget.toString() : '',
  );
  final needsCtrl = TextEditingController(
    text: currentBreakdown.needsBudget > 0 ? currentBreakdown.needsBudget.toString() : '',
  );
  final wantsCtrl = TextEditingController(
    text: currentBreakdown.wantsBudget > 0 ? currentBreakdown.wantsBudget.toString() : '',
  );

  int parse(TextEditingController c) =>
      int.tryParse(c.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final totalVal = parse(totalCtrl);
          final savingsVal = parse(savingsCtrl);
          final needsVal = parse(needsCtrl);
          final wantsVal = parse(wantsCtrl);

          // Alokasi standar
          final stdNeeds = (totalVal * 0.50).round();
          final stdWants = (totalVal * 0.30).round();
          final stdSavings = totalVal > 0 ? (totalVal - stdNeeds - stdWants) : 0;

          // Kustom: hitung sisa yang belum teralokasi
          final allocatedCustom = needsVal + wantsVal + savingsVal;
          final remainingToAllocate = totalVal - allocatedCustom;

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
                  // Mode Toggle: Standar 50/30/20 vs Kustom Nominal
                  SegmentedButton<int>(
                    segments: [
                      ButtonSegment(
                        value: 0,
                        label: Text(context.tr('Standard (50/30/20)'), style: const TextStyle(fontSize: 11)),
                        icon: const Icon(Icons.pie_chart_outline, size: 16),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text(context.tr('Custom Nominal'), style: const TextStyle(fontSize: 11)),
                        icon: const Icon(Icons.tune_rounded, size: 16),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) {
                      setState(() {
                        mode = s.first;
                        if (mode == 1 && totalVal > 0) {
                          if (savingsVal == 0) savingsCtrl.text = stdSavings.toString();
                          if (needsVal == 0) needsCtrl.text = stdNeeds.toString();
                          if (wantsVal == 0) wantsCtrl.text = stdWants.toString();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Input Total Anggaran
                  Text(
                    context.tr('Total Budget'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: totalCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: totalVal == 0,
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      hintText: '0',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  if (mode == 0) ...[
                    // Pratinjau Standar 50/30/20
                    Text(
                      context.tr('Budget Split Preview:'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          _previewRow(
                            BudgetBucket.needs.color,
                            context.tr('Needs (50%)'),
                            rupiah(stdNeeds),
                          ),
                          const Divider(height: 12),
                          _previewRow(
                            BudgetBucket.wants.color,
                            context.tr('Wants (30%)'),
                            rupiah(stdWants),
                          ),
                          const Divider(height: 12),
                          _previewRow(
                            BudgetBucket.savings.color,
                            context.tr('Savings & Goals (20%)'),
                            rupiah(stdSavings),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Input Kustom Nominal (Tabungan, Kebutuhan, Keinginan)
                    Text(
                      context.tr('Savings Allocation'),
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: BudgetBucket.savings.color),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: savingsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        hintText: '100000',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: BudgetBucket.savings.color.withValues(alpha: 0.08),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // Shortcut tombol bagi sisa 70/30
                    if (totalVal > savingsVal)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          icon: const Icon(Icons.auto_awesome, size: 14),
                          label: Text(
                            context.tr('Split remaining 70/30'),
                            style: const TextStyle(fontSize: 11),
                          ),
                          onPressed: () {
                            final rem = totalVal - savingsVal;
                            final n = (rem * 0.70).round();
                            final w = rem - n;
                            setState(() {
                              needsCtrl.text = n.toString();
                              wantsCtrl.text = w.toString();
                            });
                          },
                        ),
                      ),

                    Text(
                      context.tr('Needs Allocation'),
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: BudgetBucket.needs.color),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: needsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        hintText: '350000',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: BudgetBucket.needs.color.withValues(alpha: 0.08),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      context.tr('Wants Allocation'),
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: BudgetBucket.wants.color),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: wantsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        hintText: '150000',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: BudgetBucket.wants.color.withValues(alpha: 0.08),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // Status Alokasi Kustom
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: remainingToAllocate == 0
                            ? AppColors.deepForest.withValues(alpha: 0.1)
                            : Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            remainingToAllocate == 0
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            size: 16,
                            color: remainingToAllocate == 0 ? AppColors.deepForest : Colors.amber[800],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              remainingToAllocate == 0
                                  ? context.tr('All funds allocated')
                                  : context.tr('Remaining to allocate: {amount}', {
                                      'amount': rupiah(remainingToAllocate),
                                    }),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: remainingToAllocate == 0 ? AppColors.deepForest : Colors.amber[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                  if (mode == 0) {
                    await ref.read(budgetRuleProvider.notifier).setTotalBudget(periodKey, totalVal);
                  } else {
                    await ref.read(budgetRuleProvider.notifier).setCustomAllocations(
                          periodKey,
                          total: totalVal,
                          needs: needsVal,
                          wants: wantsVal,
                          savings: savingsVal,
                        );
                  }
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

