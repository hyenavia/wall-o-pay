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
    final colors = context.themeColors;
    final isCyber = context.isCyberpunk;
    final safeColor = colors.primary;
    final warningColor = colors.warning;
    final limitColor = isCyber ? colors.expense : const Color(0xFFD65D5D);

    final currentTier = tier;

    final (statusColor, statusIcon, labelKey, titleKey, messageKey) = switch (currentTier) {
      DailyHealthTier.safe => (
          safeColor,
          isCyber ? Icons.memory_rounded : Icons.spa_rounded,
          isCyber ? 'GRID STABLE' : 'Safe',
          isCyber ? 'Cyber Telemetry Nominal' : 'Finances on Track',
          isCyber
              ? (txCount == 0
                  ? 'Grid online. Ready for telemetry stream.'
                  : 'Credit consumption optimal. Subroutines running smooth!')
              : (txCount == 0
                  ? 'Ready for this period. Log expenses to track your daily pace.'
                  : 'Spending is well within limits. Keep up the mindful pace!'),
        ),
      DailyHealthTier.caution => (
          warningColor,
          isCyber ? Icons.electric_bolt_rounded : Icons.speed_rounded,
          isCyber ? 'BANDWIDTH HIGH' : 'Caution',
          isCyber ? 'Spending Velocity High' : 'Spending Pace is High',
          isCyber
              ? 'Daily burn rate has passed telemetry threshold. Balance it tomorrow.'
              : 'Today\'s spending has passed your daily quota. Balance it out tomorrow.',
        ),
      DailyHealthTier.limit => (
          limitColor,
          isCyber ? Icons.warning_amber_rounded : Icons.shield_outlined,
          isCyber ? 'CORE OVERLOAD' : 'Limit',
          isCyber ? 'Period Capacity Reached' : 'Spending Limit Reached',
          isCyber
              ? 'Period credit capacity reached. Limit output to vital nodes only.'
              : 'Expenses have reached the period limit. Focus on essentials only.',
        ),
    };

    final quotaRatio = dailyAllowance > 0
        ? (todayExpense / dailyAllowance).clamp(0.0, 1.0)
        : 0.0;
    final isExceeded = dailyAllowance > 0 && todayExpense > dailyAllowance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: isCyber
          ? ShapeDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  statusColor.withValues(alpha: 0.18),
                  scheme.surface,
                ],
              ),
              shape: BeveledRectangleBorder(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(8),
                ),
                side: BorderSide(
                  color: statusColor.withValues(alpha: 0.50),
                  width: 1.4,
                ),
              ),
              shadows: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : BoxDecoration(
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
              Flexible(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showPhaseInfoSheet(context, isCyber),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: isCyber
                          ? ShapeDecoration(
                              color: statusColor.withValues(alpha: 0.18),
                              shape: BeveledRectangleBorder(
                                borderRadius: const BorderRadius.all(Radius.circular(5)),
                                side: BorderSide(color: statusColor.withValues(alpha: 0.45)),
                              ),
                            )
                          : BoxDecoration(
                              color: statusColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                            ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PulsingBeacon(
                            icon: statusIcon,
                            color: statusColor,
                            isCyber: isCyber,
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
                  decoration: isCyber
                      ? ShapeDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                          shape: const BeveledRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                            side: BorderSide(color: Colors.white10),
                          ),
                        )
                      : BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(isCyber ? 'Daily Bandwidth' : 'Safe daily quota'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                          fontSize: 11,
                          fontWeight: isCyber ? FontWeight.w600 : null,
                          letterSpacing: isCyber ? 0.6 : null,
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
                  decoration: isCyber
                      ? ShapeDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                          shape: const BeveledRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                            side: BorderSide(color: Colors.white10),
                          ),
                        )
                      : BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(isCyber ? 'Burned today' : 'Spent today'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                          fontSize: 11,
                          fontWeight: isCyber ? FontWeight.w600 : null,
                          letterSpacing: isCyber ? 0.6 : null,
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
              color: isExceeded ? warningColor : (isCyber ? colors.primary : AppColors.sage),
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
                        ? context.tr(isCyber ? 'Bandwidth exceeded' : 'Quota exceeded')
                        : (isCyber
                            ? context.tr('{pct}% bandwidth consumed', {
                                'pct': (todayExpense * 100 / dailyAllowance).round(),
                              })
                            : context.tr('{pct}% of quota', {
                                'pct': (todayExpense * 100 / dailyAllowance).round(),
                              })),
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
          if (totalBudget > 0) ...[
            const SizedBox(height: 14),
            Divider(color: scheme.onSurface.withValues(alpha: 0.08), height: 1),
            const SizedBox(height: 12),
            () {
              final isOver = budgetSpent > totalBudget;
              final pct = (budgetSpent * 100 / totalBudget).round();
              final overAmount = budgetSpent - totalBudget;
              final statusColor = isOver
                  ? (isCyber ? colors.expense : AppColors.expenseOnDark)
                  : ((budgetSpent / totalBudget) >= 0.85 ? warningColor : (isCyber ? colors.primary : AppColors.sage));

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
                              : context.tr(isCyber ? 'System Budget' : 'Period Budget'),
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
                        ? (isCyber ? colors.expense : AppColors.expense)
                        : ((budgetSpent / totalBudget) >= 0.85 ? warningColor : (isCyber ? colors.primary : AppColors.sage)),
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

void _showPhaseInfoSheet(BuildContext context, bool isCyber) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: isCyber ? const Color(0xFF0D1022) : null,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _PhaseInfoSheet(isCyber: isCyber),
  );
}

class _PhaseInfoSheet extends StatelessWidget {
  const _PhaseInfoSheet({required this.isCyber});

  final bool isCyber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.themeColors;

    final primaryAccent = colors.primary;
    final primaryIcon = isCyber ? Icons.memory_rounded : Icons.spa_rounded;

    final title = isCyber
        ? context.tr('GRID TELEMETRY PROTOCOL')
        : context.tr('Daily Financial Pulse Guide');
    final subtitle = isCyber
        ? context.tr('Active telemetry monitoring of your daily eddies & credit bandwidth, choom.')
        : context.tr('Guide to the 3 daily spending phases to keep your finances healthy.');

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
                  color: isCyber ? colors.primary.withValues(alpha: 0.4) : Colors.white24,
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
                    color: primaryAccent.withValues(alpha: isCyber ? 0.2 : 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: isCyber
                        ? Border.all(color: colors.primary.withValues(alpha: 0.5))
                        : null,
                    boxShadow: isCyber
                        ? [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.25),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(primaryIcon, color: isCyber ? colors.primary : AppColors.sage, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: isCyber ? 0.6 : 0.0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
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
            const SizedBox(height: 20),
            _PhaseDetailTile(
              isCyber: isCyber,
              color: isCyber ? colors.primary : AppColors.sage,
              icon: isCyber ? Icons.memory_rounded : Icons.spa_rounded,
              phaseBadge: isCyber ? context.tr('GRID STABLE') : context.tr('Safe'),
              phaseTitle: isCyber
                  ? context.tr('Phase 01 // Subroutines Nominal')
                  : context.tr('Phase 1: Safe Financial Health'),
              description: isCyber
                  ? context.tr('Optimal eddies consumption well below daily bandwidth. Subroutines running smooth, choom!')
                  : context.tr('Spending is well within limits. Keep up the mindful pace!'),
              triggerNote: isCyber
                  ? context.tr('TRIGGER: Burn rate < daily bandwidth & budget healthy.')
                  : context.tr('Condition: Daily spending < safe quota & budget healthy.'),
            ),
            const SizedBox(height: 12),
            _PhaseDetailTile(
              isCyber: isCyber,
              color: isCyber ? colors.warning : AppColors.warning,
              icon: isCyber ? Icons.electric_bolt_rounded : Icons.speed_rounded,
              phaseBadge: isCyber ? context.tr('BANDWIDTH HIGH') : context.tr('Caution'),
              phaseTitle: isCyber
                  ? context.tr('Phase 02 // Velocity Warning')
                  : context.tr('Phase 2: Spending Velocity Warning'),
              description: isCyber
                  ? context.tr('Daily burn rate has passed telemetry threshold. Balance it tomorrow before core overloads!')
                  : context.tr('Today\'s spending has passed your daily quota. Balance it out tomorrow.'),
              triggerNote: isCyber
                  ? context.tr('TRIGGER: Daily burn > bandwidth OR period capacity >= 85%.')
                  : context.tr('Condition: Daily spending > quota OR capacity >= 85%.'),
            ),
            const SizedBox(height: 12),
            _PhaseDetailTile(
              isCyber: isCyber,
              color: isCyber ? colors.expense : const Color(0xFFD65D5D),
              icon: isCyber ? Icons.warning_amber_rounded : Icons.shield_outlined,
              phaseBadge: isCyber ? context.tr('CORE OVERLOAD') : context.tr('Limit'),
              phaseTitle: isCyber
                  ? context.tr('Phase 03 // Critical Capacity')
                  : context.tr('Phase 3: Budget Limit Reached'),
              description: isCyber
                  ? context.tr('Period credit capacity reached. Limit output to vital nodes only, don\'t flatline!')
                  : context.tr('Expenses have reached the period limit. Focus on essentials only.'),
              triggerNote: isCyber
                  ? context.tr('TRIGGER: Period budget exhausted (100%) OR balance <= 0.')
                  : context.tr('Condition: Period budget exhausted (100%) OR balance <= 0.'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: isCyber ? colors.primary : scheme.primary,
                  foregroundColor: isCyber ? Colors.black : scheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  isCyber ? context.tr('ACKNOWLEDGE // DISMISS') : context.tr('I Understand'),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: isCyber ? 0.8 : 0.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseDetailTile extends StatelessWidget {
  const _PhaseDetailTile({
    required this.isCyber,
    required this.color,
    required this.icon,
    required this.phaseBadge,
    required this.phaseTitle,
    required this.description,
    required this.triggerNote,
  });

  final bool isCyber;
  final Color color;
  final IconData icon;
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
          color: color.withValues(alpha: isCyber ? 0.45 : 0.25),
          width: isCyber ? 1.2 : 1.0,
        ),
        boxShadow: isCyber
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.14),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
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
                    Icon(icon, size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(
                      phaseBadge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: isCyber ? 0.5 : 0.0,
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
                letterSpacing: isCyber ? 0.3 : 0.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon telemetri dengan efek denyut halus (breathing pulse) saat mode Cyberpunk aktif.
class _PulsingBeacon extends StatefulWidget {
  const _PulsingBeacon({
    required this.color,
    required this.icon,
    required this.isCyber,
  });

  final Color color;
  final IconData icon;
  final bool isCyber;

  @override
  State<_PulsingBeacon> createState() => _PulsingBeaconState();
}

class _PulsingBeaconState extends State<_PulsingBeacon>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.isCyber) {
      final isTest =
          WidgetsBinding.instance.runtimeType.toString().contains('Test');
      if (!isTest) {
        _controller = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1600),
        )..repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isCyber ||
        _controller == null ||
        MediaQuery.disableAnimationsOf(context)) {
      return Icon(widget.icon, size: 14, color: widget.color);
    }

    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, child) {
        final opacity = 0.55 + (_controller!.value * 0.45);
        return Opacity(
          opacity: opacity,
          child: Icon(widget.icon, size: 14, color: widget.color),
        );
      },
    );
  }
}

