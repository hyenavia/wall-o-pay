/// Dialog pengaturan total anggaran periode dengan pilihan mode Standar 50/30/20
/// atau mode Alokasi Nominal Kustom untuk masing-masing pilar.
library;

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
            backgroundColor: AppColors.mossShadow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(
                color: AppColors.dewMint.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.dewMint.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.dewMint.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: const Icon(Icons.calculate_outlined, color: AppColors.dewMint),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr('Total Budget'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.softIvory,
                    ),
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
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppColors.dewMint.withValues(alpha: 0.25),
                      selectedForegroundColor: AppColors.dewMint,
                      foregroundColor: AppColors.freshSage,
                      side: BorderSide(
                        color: AppColors.dewMint.withValues(alpha: 0.25),
                      ),
                    ),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.softIvory,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: totalCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: totalVal == 0,
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
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.dewMint.withValues(alpha: 0.25),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.dewMint.withValues(alpha: 0.25),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.dewMint,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.deepForest.withValues(alpha: 0.6),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  if (mode == 0) ...[
                    // Pratinjau Standar 50/30/20
                    Text(
                      context.tr('Budget Split Preview:'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.softIvory,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.deepForest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.dewMint.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          _previewRow(
                            BudgetBucket.needs.colorIn(ctx),
                            context.tr('Needs (50%)'),
                            rupiah(stdNeeds),
                          ),
                          Divider(height: 12, color: AppColors.borderOutline.withValues(alpha: 0.4)),
                          _previewRow(
                            BudgetBucket.wants.colorIn(ctx),
                            context.tr('Wants (30%)'),
                            rupiah(stdWants),
                          ),
                          Divider(height: 12, color: AppColors.borderOutline.withValues(alpha: 0.4)),
                          _previewRow(
                            BudgetBucket.savings.colorIn(ctx),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: BudgetBucket.savings.colorIn(ctx),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: savingsCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: AppColors.softIvory,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        prefixStyle: TextStyle(
                          color: BudgetBucket.savings.colorIn(ctx),
                          fontWeight: FontWeight.w700,
                        ),
                        hintText: '100000',
                        hintStyle: TextStyle(
                          color: AppColors.freshSage.withValues(alpha: 0.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: BudgetBucket.savings.colorIn(ctx).withValues(alpha: 0.35),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: BudgetBucket.savings.colorIn(ctx).withValues(alpha: 0.35),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: BudgetBucket.savings.colorIn(ctx),
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: BudgetBucket.savings.colorIn(ctx).withValues(alpha: 0.10),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // Shortcut tombol bagi sisa 70/30
                    if (totalVal > savingsVal)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: AppColors.dewMint,
                          ),
                          icon: const Icon(Icons.auto_awesome, size: 14),
                          label: Text(
                            context.tr('Split remaining 70/30'),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: BudgetBucket.needs.colorIn(ctx),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: needsCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: AppColors.softIvory,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        prefixStyle: TextStyle(
                          color: BudgetBucket.needs.colorIn(ctx),
                          fontWeight: FontWeight.w700,
                        ),
                        hintText: '350000',
                        hintStyle: TextStyle(
                          color: AppColors.freshSage.withValues(alpha: 0.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: BudgetBucket.needs.colorIn(ctx).withValues(alpha: 0.35),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: BudgetBucket.needs.colorIn(ctx).withValues(alpha: 0.35),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: BudgetBucket.needs.colorIn(ctx),
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: BudgetBucket.needs.colorIn(ctx).withValues(alpha: 0.10),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      context.tr('Wants Allocation'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: BudgetBucket.wants.colorIn(ctx),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: wantsCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: AppColors.softIvory,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        prefixStyle: TextStyle(
                          color: BudgetBucket.wants.colorIn(ctx),
                          fontWeight: FontWeight.w700,
                        ),
                        hintText: '150000',
                        hintStyle: TextStyle(
                          color: AppColors.freshSage.withValues(alpha: 0.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: BudgetBucket.wants.colorIn(ctx).withValues(alpha: 0.35),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: BudgetBucket.wants.colorIn(ctx).withValues(alpha: 0.35),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: BudgetBucket.wants.colorIn(ctx),
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: BudgetBucket.wants.colorIn(ctx).withValues(alpha: 0.10),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // Status Alokasi Kustom
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: remainingToAllocate == 0
                            ? AppColors.emeraldLeaf.withValues(alpha: 0.35)
                            : const Color(0xFFE8A33D).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: remainingToAllocate == 0
                              ? AppColors.dewMint.withValues(alpha: 0.3)
                              : const Color(0xFFE8A33D).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            remainingToAllocate == 0
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            size: 16,
                            color: remainingToAllocate == 0
                                ? AppColors.dewMint
                                : const Color(0xFFE8A33D),
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
                                color: remainingToAllocate == 0
                                    ? AppColors.dewMint
                                    : const Color(0xFFE8A33D),
                                fontFeatures: const [FontFeature.tabularFigures()],
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
                child: Text(
                  context.tr('Cancel'),
                  style: const TextStyle(color: AppColors.freshSage),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dewMint,
                  foregroundColor: AppColors.deepForest,
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
                child: Text(
                  context.tr('Save'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
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
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 12, color: AppColors.softIvory),
        ),
      ),
      Text(
        amount,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.softIvory,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    ],
  );
}

