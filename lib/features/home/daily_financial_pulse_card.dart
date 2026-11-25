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

/// Sumber dana utama yang dipakai dalam perhitungan kuota belanja harian.
enum PulseFundingBasis {
  periodBudget,
  periodCashflow,
  walletBalance,
  none,
}

/// Hasil murni perhitungan Daily Financial Pulse agar mudah diuji dan dijelaskan ke pengguna.
class DailyPulseResult {
  const DailyPulseResult({
    required this.tier,
    required this.dailyAllowance,
    required this.fundingBasis,
    required this.basisAmount,
    required this.availablePool,
    required this.upcomingBills,
    required this.daysLeft,
  });

  final DailyHealthTier tier;
  final int dailyAllowance;
  final PulseFundingBasis fundingBasis;
  final int basisAmount;
  final int availablePool;
  final int upcomingBills;
  final int daysLeft;
}

/// Menghitung status kesehatan finansial harian dan kuota belanja aman secara deterministik.
DailyPulseResult calculateDailyPulse({
  required int income,
  required int expense,
  required int totalWalletBalance,
  required int totalBudget,
  required int budgetSpent,
  required int todayExpense,
  required int daysLeft,
  required int upcomingBills,
  required int txCount,
}) {
  final safeDays = daysLeft > 0 ? daysLeft : 0;

  if (totalBudget > 0) {
    final budgetRemaining = totalBudget - budgetSpent;
    final available = budgetRemaining - upcomingBills;
    final allowance = (available > 0 && safeDays > 0) ? available ~/ safeDays : 0;

    final DailyHealthTier tier;
    if (budgetSpent >= totalBudget) {
      tier = DailyHealthTier.limit;
    } else if ((budgetSpent / totalBudget) >= 0.85 ||
        (allowance > 0 && todayExpense > allowance) ||
        (available <= 0 && txCount > 0)) {
      tier = DailyHealthTier.caution;
    } else {
      tier = DailyHealthTier.safe;
    }

    return DailyPulseResult(
      tier: tier,
      dailyAllowance: allowance,
      fundingBasis: PulseFundingBasis.periodBudget,
      basisAmount: budgetRemaining,
      availablePool: available,
      upcomingBills: upcomingBills,
      daysLeft: daysLeft,
    );
  }

  if (income > 0) {
    final periodBalance = income - expense;
    final available = periodBalance - upcomingBills;
    final allowance = (available > 0 && safeDays > 0) ? available ~/ safeDays : 0;

    final DailyHealthTier tier;
    if (periodBalance <= 0 && totalWalletBalance <= 0 && txCount > 0) {
      tier = DailyHealthTier.limit;
    } else if ((periodBalance <= 0 && txCount > 0) ||
        (allowance > 0 && todayExpense > allowance) ||
        (available <= 0 && txCount > 0)) {
      tier = DailyHealthTier.caution;
    } else {
      tier = DailyHealthTier.safe;
    }

    return DailyPulseResult(
      tier: tier,
      dailyAllowance: allowance,
      fundingBasis: PulseFundingBasis.periodCashflow,
      basisAmount: periodBalance,
      availablePool: available,
      upcomingBills: upcomingBills,
      daysLeft: daysLeft,
    );
  }

  if (totalWalletBalance > 0 || txCount > 0) {
    final available = totalWalletBalance - upcomingBills;
    final allowance = (available > 0 && safeDays > 0) ? available ~/ safeDays : 0;

    final DailyHealthTier tier;
    if (totalWalletBalance <= 0 && txCount > 0) {
      tier = DailyHealthTier.limit;
    } else if ((allowance > 0 && todayExpense > allowance) ||
        (available <= 0 && txCount > 0)) {
      tier = DailyHealthTier.caution;
    } else {
      tier = DailyHealthTier.safe;
    }

    return DailyPulseResult(
      tier: tier,
      dailyAllowance: allowance,
      fundingBasis: PulseFundingBasis.walletBalance,
      basisAmount: totalWalletBalance,
      availablePool: available,
      upcomingBills: upcomingBills,
      daysLeft: daysLeft,
    );
  }

  return DailyPulseResult(
    tier: DailyHealthTier.safe,
    dailyAllowance: 0,
    fundingBasis: PulseFundingBasis.none,
    basisAmount: 0,
    availablePool: 0,
    upcomingBills: upcomingBills,
    daysLeft: daysLeft,
  );
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
    this.onTapUpcomingBills,
    this.pulse,
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
  final VoidCallback? onTapUpcomingBills;
  final DailyPulseResult? pulse;

  DailyHealthTier get tier {
    if (pulse != null) return pulse!.tier;

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
    final colors = context.themeColors;
    final safeColor = colors.income;
    final warningColor = colors.warning;
    final limitColor = colors.expense;

    final currentTier = tier;

    final (statusColor, statusIcon, labelKey, titleKey, messageKey) = switch (currentTier) {
      DailyHealthTier.safe => (
          safeColor,
          Icons.spa_rounded,
          'Safe',
          'Finances on Track',
          txCount == 0
              ? 'Ready for this period. Log expenses to track your daily pace.'
              : 'Spending is well within limits. Keep up the mindful pace!',
        ),
      DailyHealthTier.caution => (
          warningColor,
          Icons.speed_rounded,
          'Caution',
          'Spending Pace is High',
          'Today\'s spending has passed your daily quota. Balance it out tomorrow.',
        ),
      DailyHealthTier.limit => (
          limitColor,
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
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.dewMint.withValues(alpha: 0.20),
          width: 1.0,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.10),
            AppColors.cardSurface.withValues(alpha: 0.96),
            AppColors.surfaceContainer.withValues(alpha: 0.90),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: statusColor.withValues(alpha: 0.12),
            blurRadius: 10,
            spreadRadius: -2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showPhaseInfoSheet(
                      context,
                      pulse: pulse ??
                          DailyPulseResult(
                            tier: currentTier,
                            dailyAllowance: dailyAllowance,
                            fundingBasis: totalBudget > 0
                                ? PulseFundingBasis.periodBudget
                                : PulseFundingBasis.periodCashflow,
                            basisAmount: totalBudget > 0 ? (totalBudget - budgetSpent) : balance,
                            availablePool: totalBudget > 0 ? (totalBudget - budgetSpent) : balance,
                            upcomingBills: 0,
                            daysLeft: daysLeft,
                          ),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            currentTier == DailyHealthTier.safe
                                ? 'assets/icons/vice_city/growth.png'
                                : (currentTier == DailyHealthTier.caution
                                    ? 'assets/icons/vice_city/pulse.png'
                                    : 'assets/icons/vice_city/minus.png'),
                            width: 14,
                            height: 14,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              context.tr(labelKey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: statusColor.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: context.tr('Tap for financial advice from Wendy'),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showWendyAdviceSheet(context, currentTier),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor.withValues(alpha: 0.16),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.20),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        currentTier == DailyHealthTier.safe
                            ? 'assets/new_asset/expression/expression_01.png'
                            : (currentTier == DailyHealthTier.caution
                                ? 'assets/new_asset/expression/expression_03.png'
                                : 'assets/new_asset/expression/expression_06.png'),
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer.withValues(alpha: 0.60),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.dewMint.withValues(alpha: 0.12),
                      width: 1.0,
                    ),
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
                        style: context.moneyStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: dailyAllowance > 0 ? safeColor : muted,
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
                    color: AppColors.surfaceContainer.withValues(alpha: 0.60),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.dewMint.withValues(alpha: 0.12),
                      width: 1.0,
                    ),
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
                        style: context.moneyStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isExceeded ? warningColor : scheme.onSurface,
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
              color: isExceeded ? warningColor : AppColors.sage,
              backgroundColor: scheme.surfaceContainerHighest,
              height: 6,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isExceeded
                        ? context.tr('Quota exceeded')
                        : context.tr('{pct}% of quota', {
                            'pct': (todayExpense * 100 / dailyAllowance).round(),
                          }),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isExceeded ? warningColor : muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
          if ((pulse?.upcomingBills ?? 0) > 0) ...[
            const SizedBox(height: 10),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTapUpcomingBills,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_repeat_rounded,
                        size: 13,
                        color: onTapUpcomingBills != null ? AppColors.dewMint : muted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          context.tr('Reserves {amount} for upcoming scheduled bills', {
                            'amount': rupiah(pulse!.upcomingBills),
                          }),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (onTapUpcomingBills != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 15,
                          color: AppColors.dewMint.withValues(alpha: 0.8),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
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
                  : ((budgetSpent / totalBudget) >= 0.85 ? warningColor : AppColors.sage);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          budgetTitle != null
                              ? context.tr(budgetTitle!)
                              : context.tr('Period Budget'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                        : ((budgetSpent / totalBudget) >= 0.85 ? warningColor : AppColors.sage),
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

void _showPhaseInfoSheet(
  BuildContext context, {
  required DailyPulseResult pulse,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _PhaseInfoSheet(pulse: pulse),
  );
}

class _PhaseInfoSheet extends StatelessWidget {
  const _PhaseInfoSheet({required this.pulse});

  final DailyPulseResult pulse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.themeColors;

    final basisLabel = switch (pulse.fundingBasis) {
      PulseFundingBasis.periodBudget => context.tr('Remaining period budget'),
      PulseFundingBasis.periodCashflow => context.tr('Net period cashflow'),
      PulseFundingBasis.walletBalance => context.tr('Total account balance'),
      PulseFundingBasis.none => context.tr('Available funds'),
    };
    final safeDays = pulse.daysLeft > 0 ? pulse.daysLeft : 0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Image.asset('assets/icons/vice_city/pulse.png', width: 24, height: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('Daily Financial Pulse Guide'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        context.tr('Guide to the 3 daily spending phases to keep your finances healthy.'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.7),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.dewMint.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('How your quota is calculated'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.dewMint,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _BreakdownRow(
                    label: basisLabel,
                    value: rupiah(pulse.basisAmount),
                    valueColor: scheme.onSurface,
                  ),
                  const SizedBox(height: 6),
                  _BreakdownRow(
                    label: context.tr('Upcoming scheduled bills'),
                    value: pulse.upcomingBills > 0
                        ? '- ${rupiah(pulse.upcomingBills)}'
                        : rupiah(0),
                    valueColor: pulse.upcomingBills > 0
                        ? colors.warning
                        : scheme.onSurface.withValues(alpha: 0.65),
                  ),
                  const SizedBox(height: 6),
                  _BreakdownRow(
                    label: context.tr('Days remaining'),
                    value: safeDays == 1
                        ? context.tr('1 day')
                        : context.tr('{n} days', {'n': safeDays}),
                    valueColor: scheme.onSurface,
                  ),
                  const SizedBox(height: 8),
                  Divider(color: scheme.onSurface.withValues(alpha: 0.10), height: 1),
                  const SizedBox(height: 8),
                  _BreakdownRow(
                    label: context.tr('Safe daily quota'),
                    value: pulse.dailyAllowance > 0
                        ? '${rupiah(pulse.dailyAllowance)} / ${context.tr('day')}'
                        : '-',
                    valueColor: colors.income,
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _PhaseDetailTile(
              color: colors.income,
              icon: Icons.spa_rounded,
              customAsset: 'assets/icons/vice_city/growth.png',
              phaseBadge: context.tr('Safe'),
              phaseTitle: context.tr('Phase 1: Safe Financial Health'),
              description: context.tr('Spending is well within limits. Keep up the mindful pace!'),
              triggerNote: context.tr('Condition: Daily spending < safe quota & budget healthy.'),
            ),
            const SizedBox(height: 12),
            _PhaseDetailTile(
              color: AppColors.warning,
              icon: Icons.speed_rounded,
              customAsset: 'assets/icons/vice_city/pulse.png',
              phaseBadge: context.tr('Caution'),
              phaseTitle: context.tr('Phase 2: Spending Velocity Warning'),
              description: context.tr('Today\'s spending has passed your daily quota. Balance it out tomorrow.'),
              triggerNote: context.tr('Condition: Daily spending > quota OR capacity >= 85%.'),
            ),
            const SizedBox(height: 12),
            _PhaseDetailTile(
              color: colors.expense,
              icon: Icons.shield_outlined,
              customAsset: 'assets/icons/vice_city/minus.png',
              phaseBadge: context.tr('Limit'),
              phaseTitle: context.tr('Phase 3: Budget Limit Reached'),
              description: context.tr('Expenses have reached the period limit. Focus on essentials only.'),
              triggerNote: context.tr('Condition: Period budget exhausted (100%) OR balance <= 0.'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  context.tr('I Understand'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.72);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: bold ? theme.colorScheme.onSurface : muted,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: context.moneyStyle(
            fontSize: bold ? 13 : 12,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _PhaseDetailTile extends StatelessWidget {
  const _PhaseDetailTile({
    required this.color,
    required this.icon,
    this.customAsset,
    required this.phaseBadge,
    required this.phaseTitle,
    required this.description,
    required this.triggerNote,
  });

  final Color color;
  final IconData icon;
  final String? customAsset;
  final String phaseBadge;
  final String phaseTitle;
  final String description;
  final String triggerNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    customAsset != null
                        ? Image.asset(customAsset!, width: 12, height: 12)
                        : Icon(icon, size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(
                      phaseBadge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  phaseTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.8),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              triggerNote,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal saran finansial interaktif dari Wendy Companion berdasarkan status kesehatan harian.
void _showWendyAdviceSheet(BuildContext context, DailyHealthTier tier) {
  final colors = context.themeColors;

  final adviceList = [
    (
      'assets/new_asset/expression/expression_01.png',
      "Wendy's Advice: Safe & Steady",
      'Your spending velocity is in great shape! Stick to the safe daily quota and your cashflow will remain resilient.',
      colors.income,
    ),
    (
      'assets/new_asset/expression/expression_02.png',
      "Wendy's Advice: Surplus Trajectory",
      'Consistent pacing builds surplus reserves. Consider sweeping extra surplus into your savings goals!',
      AppColors.neonCyan,
    ),
    (
      'assets/new_asset/expression/expression_03.png',
      "Wendy's Advice: Caution Ahead",
      "You've exceeded today's safe allowance or your budget capacity is getting tight. Pace your spending tomorrow to stay on track.",
      colors.warning,
    ),
    (
      'assets/new_asset/expression/expression_04.png',
      "Wendy's Advice: Balanced Discipline",
      'Your Needs, Wants, and Savings pools are harmoniously balanced. Keep this steady momentum going!',
      AppColors.goldenYellow,
    ),
    (
      'assets/new_asset/expression/expression_05.png',
      "Wendy's Advice: Savings Streak",
      'Great financial habits pay off over time. Your commitment to saving regularly is building real freedom.',
      AppColors.sunsetMagenta,
    ),
    (
      'assets/new_asset/expression/expression_06.png',
      "Wendy's Advice: Budget Limit",
      'Your period budget is exhausted! Focus strictly on primary essentials until your next income or period reset.',
      colors.expense,
    ),
    (
      'assets/new_asset/expression/expression_07.png',
      "Wendy's Advice: Debt Due Reminder",
      'Check your upcoming debt and split bill schedules so you never get caught off guard by due dates.',
      AppColors.goldenYellow,
    ),
    (
      'assets/new_asset/expression/expression_08.png',
      "Wendy's Advice: Mindful Wants",
      'Notice if spontaneous wants are outpacing your essentials. A quick pause before purchasing works wonders.',
      AppColors.sunsetOrange,
    ),
    (
      'assets/new_asset/expression/expression_09.png',
      "Wendy's Advice: Emergency Shield",
      'Building an untouchable 3-month emergency reserve ensures peace of mind through any unexpected storm.',
      AppColors.neonCyan,
    ),
    (
      'assets/new_asset/expression/expression_10.png',
      "Wendy's Advice: Month-End Victory",
      'Celebrate your monthly financial progress. Every conscious decision sharpens your mastery over money!',
      AppColors.softWhite,
    ),
  ];

  final initialIndex = switch (tier) {
    DailyHealthTier.safe => 0,
    DailyHealthTier.caution => 2,
    DailyHealthTier.limit => 5,
  };
  var selectedIndex = initialIndex;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (sheetCtx, setModalState) {
        final (asset, titleKey, adviceKey, adviceColor) = adviceList[selectedIndex];

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.midnightNavy,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: adviceColor.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 28,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: adviceColor.withValues(alpha: 0.15),
                      border: Border.all(color: adviceColor.withValues(alpha: 0.45)),
                      boxShadow: [
                        BoxShadow(
                          color: adviceColor.withValues(alpha: 0.25),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Image.asset(asset, width: 76, height: 76, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.tr(titleKey),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.softWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(adviceKey),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedBlueGray,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 46,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: adviceList.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (c, idx) {
                      final item = adviceList[idx];
                      final isSelected = idx == selectedIndex;
                      return InkWell(
                        onTap: () => setModalState(() => selectedIndex = idx),
                        borderRadius: BorderRadius.circular(23),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? item.$4.withValues(alpha: 0.25)
                                : AppColors.deepNavy,
                            border: Border.all(
                              color: isSelected
                                  ? item.$4
                                  : AppColors.borderOutline.withValues(alpha: 0.5),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(item.$1, fit: BoxFit.contain),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.sunsetMagenta,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(sheetCtx),
                    child: Text(context.tr('Got it!'), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

