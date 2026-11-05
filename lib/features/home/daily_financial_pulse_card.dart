/// Komponen kartu indikator kesehatan keuangan harian ([DailyFinancialPulseCard]) di halaman Beranda,
/// menghitung kuota belanja harian aman dan tingkat kewaspadaan ([DailyHealthTier]).
library;

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Status kesehatan finansial harian berdasarkan kecepatan belanja dan kuota periode.
enum DailyHealthTier {
  safe,
  caution,
  limit,
}

/// Card ringkasan kondisi keuangan harian (Daily Financial Pulse) bergaya hangat, humanis,
/// dan berbasis palet botani Wall o' Pay (Safe / Waspada / Batas).
class DailyFinancialPulseCard extends StatelessWidget {
  const DailyFinancialPulseCard({
    super.key,
    required this.dailyAllowance,
    required this.todayExpense,
    required this.daysLeft,
    required this.balance,
    required this.totalBudget,
    required this.budgetSpent,
    required this.txCount,
    this.budgetTitle,
    this.onSetBudget,
  });

  final int dailyAllowance;
  final int todayExpense;
  final int daysLeft;
  final int balance;
  final int totalBudget;
  final int budgetSpent;
  final int txCount;
  final String? budgetTitle;
  final VoidCallback? onSetBudget;

  DailyHealthTier get tier {
    final isBudgetOver = totalBudget > 0 && budgetSpent >= totalBudget;
    final isNegativeBalance = balance <= 0 && txCount > 0;

    if (isBudgetOver || isNegativeBalance) {
      return DailyHealthTier.limit;
    }

    final isNearBudget = totalBudget > 0 && (budgetSpent / totalBudget) >= 0.85;
    final isOverDailyAllowance = dailyAllowance > 0 && todayExpense > dailyAllowance;

    if (isNearBudget || isOverDailyAllowance) {
      return DailyHealthTier.caution;
    }

    return DailyHealthTier.safe;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.65);

    final currentTier = tier;

    final (statusColor, statusIcon, labelKey, titleKey, messageKey) = switch (currentTier) {
      DailyHealthTier.safe => (
          AppColors.sage,
          Icons.spa_rounded,
          'Safe',
          'Finances on Track',
          txCount == 0
              ? 'Ready for this period. Log expenses to track your daily pace.'
              : 'Spending is well within limits. Keep up the mindful pace!',
        ),
      DailyHealthTier.caution => (
          AppColors.warning,
          Icons.speed_rounded,
          'Caution',
          'Spending Pace is High',
          'Today\'s spending has passed your daily quota. Balance it out tomorrow.',
        ),
      DailyHealthTier.limit => (
          const Color(0xFFD65D5D),
          Icons.shield_outlined,
          'Limit',
          'Spending Limit Reached',
          'Expenses have reached the period limit. Focus on essentials only.',
        ),
    };

    final quotaRatio = dailyAllowance > 0
        ? (todayExpense / dailyAllowance).clamp(0.0, 1.0)
        : 0.0;
    final isExceeded = dailyAllowance > 0 && todayExpense > dailyAllowance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.12),
            scheme.surface,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 5),
                    Text(
                      context.tr(labelKey),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 12, color: muted),
                  const SizedBox(width: 5),
                  Text(
                    daysLeft <= 0
                        ? context.tr('Period ended')
                        : (daysLeft == 1
                            ? context.tr('1 day left')
                            : context.tr('{n} days left', {'n': daysLeft})),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.tr(titleKey),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr(messageKey),
            style: theme.textTheme.bodySmall?.copyWith(
              color: muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('Safe daily quota'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dailyAllowance > 0 ? rupiah(dailyAllowance) : '-',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: dailyAllowance > 0 ? AppColors.sage : muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('Spent today'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rupiah(todayExpense),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isExceeded ? AppColors.warning : scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (dailyAllowance > 0) ...[
            const SizedBox(height: 12),
            AppProgressBar(
              value: quotaRatio,
              color: isExceeded ? AppColors.warning : AppColors.sage,
              backgroundColor: scheme.surfaceContainerHighest,
              height: 6,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isExceeded
                      ? context.tr('Quota exceeded')
                      : context.tr('{pct}% of quota', {
                          'pct': (todayExpense * 100 / dailyAllowance).round(),
                        }),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isExceeded ? AppColors.warning : muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                Text(
                  rupiah(dailyAllowance),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
          if (totalBudget > 0) ...[
            const SizedBox(height: 14),
            Divider(color: scheme.onSurface.withValues(alpha: 0.08), height: 1),
            const SizedBox(height: 12),
            () {
              final isOver = budgetSpent > totalBudget;
              final pct = (budgetSpent * 100 / totalBudget).round();
              final overAmount = budgetSpent - totalBudget;
              final statusColor = isOver
                  ? AppColors.expenseOnDark
                  : ((budgetSpent / totalBudget) >= 0.85 ? AppColors.warning : AppColors.sage);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        budgetTitle != null ? context.tr(budgetTitle!) : context.tr('Period Budget'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        isOver
                            ? context.tr('{pct}% used (Over by {amount})', {
                                'pct': pct,
                                'amount': rupiah(overAmount),
                              })
                            : context.tr('{pct}% used', {'pct': pct}),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('{spent} of {total}', {
                          'spent': rupiah(budgetSpent),
                          'total': rupiah(totalBudget),
                        }),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppProgressBar(
                    value: (budgetSpent / totalBudget).clamp(0.0, 1.0),
                    color: isOver
                        ? AppColors.expense
                        : ((budgetSpent / totalBudget) >= 0.85 ? AppColors.warning : AppColors.sage),
                    backgroundColor: scheme.surfaceContainerHighest,
                    height: 6,
                  ),
                ],
              );
            }(),
          ] else if (onSetBudget != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('No budget set yet.'),
                  style: theme.textTheme.bodySmall?.copyWith(color: muted, fontSize: 11),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: onSetBudget,
                  child: Text(context.tr('Set budget'), style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

