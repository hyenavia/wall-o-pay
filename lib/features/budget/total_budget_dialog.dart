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
    text: formatThousands(currentBreakdown.totalBudget),
  );
  final savingsCtrl = TextEditingController(
    text: formatThousands(currentBreakdown.savingsBudget),
  );
  final needsCtrl = TextEditingController(
    text: formatThousands(currentBreakdown.needsBudget),
  );
  final wantsCtrl = TextEditingController(
    text: formatThousands(currentBreakdown.wantsBudget),
  );

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final totalVal = parseAmount(totalCtrl.text);
          final savingsVal = parseAmount(savingsCtrl.text);
          final needsVal = parseAmount(needsCtrl.text);
          final wantsVal = parseAmount(wantsCtrl.text);

          // Alokasi standar
          final stdNeeds = (totalVal * 0.50).round();
          final stdWants = (totalVal * 0.30).round();
          final stdSavings = totalVal > 0 ? (totalVal - stdNeeds - stdWants) : 0;

          // Kustom: hitung sisa yang belum teralokasi
          final allocatedCustom = needsVal + wantsVal + savingsVal;
          final remainingToAllocate = totalVal - allocatedCustom;
          final colors = ctx.themeColors;

          return AlertDialog(
            backgroundColor: colors.cardSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(
                color: colors.borderOutline,
                width: 1,
              ),
            ),
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/new_asset/poses/pose_06.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr('Total Budget'),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: colors.textPrimary,
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
                      selectedBackgroundColor: colors.primary,
                      selectedForegroundColor: colors.onPrimary,
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(
                        color: colors.inputBorder,
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
                          if (savingsVal == 0) savingsCtrl.text = formatThousands(stdSavings);
                          if (needsVal == 0) needsCtrl.text = formatThousands(stdNeeds);
                          if (wantsVal == 0) wantsCtrl.text = formatThousands(stdWants);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Input Total Anggaran
                  Text(
                    context.tr('Total Budget'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: totalCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: amountFormatters(),
                    autofocus: totalVal == 0,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    decoration: InputDecoration(
                      prefixText: currencyInputPrefix,
                      prefixStyle: TextStyle(
                        color: colors.isDark ? AppColors.dewMint : colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: colors.textMuted.withValues(alpha: 0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: colors.inputBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: colors.inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: colors.primary,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: colors.isDark
                          ? AppColors.deepForest.withValues(alpha: 0.6)
                          : colors.surfaceContainer,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  if (mode == 0) ...[
                    // Pratinjau Standar 50/30/20
                    Text(
                      context.tr('Budget Split Preview:'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.isDark
                            ? AppColors.deepForest.withValues(alpha: 0.5)
                            : colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colors.borderOutline,
                        ),
                      ),
                      child: Column(
                        children: [
                          _previewRow(
                            ctx,
                            BudgetBucket.needs.colorIn(ctx),
                            context.tr('Needs (50%)'),
                            rupiah(stdNeeds),
                          ),
                          Divider(height: 12, color: colors.borderOutline.withValues(alpha: 0.6)),
                          _previewRow(
                            ctx,
                            BudgetBucket.wants.colorIn(ctx),
                            context.tr('Wants (30%)'),
                            rupiah(stdWants),
                          ),
                          Divider(height: 12, color: colors.borderOutline.withValues(alpha: 0.6)),
                          _previewRow(
                            ctx,
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
                      inputFormatters: amountFormatters(),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      decoration: InputDecoration(
                        prefixText: currencyInputPrefix,
                        prefixStyle: TextStyle(
                          color: BudgetBucket.savings.colorIn(ctx),
                          fontWeight: FontWeight.w700,
                        ),
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: colors.textMuted.withValues(alpha: 0.6),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: BudgetBucket.savings.colorIn(ctx).withValues(alpha: 0.45),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: BudgetBucket.savings.colorIn(ctx).withValues(alpha: 0.45),
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
                            foregroundColor: colors.accentSecondary,
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
                              needsCtrl.text = formatThousands(n);
                              wantsCtrl.text = formatThousands(w);
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
                      inputFormatters: amountFormatters(),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      decoration: InputDecoration(
                        prefixText: currencyInputPrefix,
                        prefixStyle: TextStyle(
                          color: BudgetBucket.needs.colorIn(ctx),
                          fontWeight: FontWeight.w700,
                        ),
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: colors.textMuted.withValues(alpha: 0.6),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: BudgetBucket.needs.colorIn(ctx).withValues(alpha: 0.45),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: BudgetBucket.needs.colorIn(ctx).withValues(alpha: 0.45),
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
                      inputFormatters: amountFormatters(),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      decoration: InputDecoration(
                        prefixText: currencyInputPrefix,
                        prefixStyle: TextStyle(
                          color: BudgetBucket.wants.colorIn(ctx),
                          fontWeight: FontWeight.w700,
                        ),
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: colors.textMuted.withValues(alpha: 0.6),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: BudgetBucket.wants.colorIn(ctx).withValues(alpha: 0.45),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: BudgetBucket.wants.colorIn(ctx).withValues(alpha: 0.45),
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
                        color: (remainingToAllocate == 0 ? colors.income : colors.warning)
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (remainingToAllocate == 0 ? colors.income : colors.warning)
                              .withValues(alpha: 0.35),
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
                            color: remainingToAllocate == 0 ? colors.income : colors.warning,
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
                                color: remainingToAllocate == 0 ? colors.income : colors.warning,
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
                  style: TextStyle(color: colors.textMuted),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
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

Widget _previewRow(BuildContext context, Color color, String title, String amount) {
  final colors = context.themeColors;
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
          style: TextStyle(fontSize: 12, color: colors.textPrimary),
        ),
      ),
      Text(
        amount,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ],
  );
}

