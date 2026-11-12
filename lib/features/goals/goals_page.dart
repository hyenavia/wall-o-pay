/// Halaman pengelolaan target tabungan impian ([GoalsPage]), penambahan dana tabungan,
/// dan riwayat target yang telah tercapai.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/period.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_database.dart';
import '../../data/prefs.dart';
import '../../data/providers.dart';
import '../../data/tables.dart' show TxType;

enum GoalPaceStatus { onTrack, behindSchedule, dueToday, overdue }

class GoalPaceSummary {
  const GoalPaceSummary({
    required this.remainingAmount,
    required this.daysLeft,
    required this.periodsLeft,
    required this.recommendedPerPeriod,
    required this.periodType,
    required this.status,
  });

  final int remainingAmount;
  final int daysLeft;
  final int periodsLeft;
  final int recommendedPerPeriod;
  final PeriodType periodType;
  final GoalPaceStatus status;
}

/// Menghitung proyeksi setoran per periode ([PeriodType.weekly] / [PeriodType.monthly]) dan status ritme tabungan goal.
GoalPaceSummary? computeGoalPace(
  SavingsGoal goal,
  PeriodType periodType, {
  DateTime? now,
}) {
  final targetDate = goal.targetDate;
  if (targetDate == null || goal.currentAmount >= goal.targetAmount) {
    return null;
  }

  final refNow = now ?? DateTime.now();
  final today = DateTime(refNow.year, refNow.month, refNow.day);
  final due = DateTime(targetDate.year, targetDate.month, targetDate.day);
  final remaining = goal.targetAmount - goal.currentAmount;
  final daysLeft = due.difference(today).inDays;

  if (daysLeft < 0) {
    return GoalPaceSummary(
      remainingAmount: remaining,
      daysLeft: daysLeft,
      periodsLeft: 1,
      recommendedPerPeriod: remaining,
      periodType: periodType,
      status: GoalPaceStatus.overdue,
    );
  }
  if (daysLeft == 0) {
    return GoalPaceSummary(
      remainingAmount: remaining,
      daysLeft: 0,
      periodsLeft: 1,
      recommendedPerPeriod: remaining,
      periodType: periodType,
      status: GoalPaceStatus.dueToday,
    );
  }

  final cycleDays = periodType == PeriodType.weekly ? 7 : 30;
  final periodsLeft = (daysLeft / cycleDays).ceil().clamp(1, 10000);
  final recommendedPerPeriod = (remaining / periodsLeft).ceil();

  final createdDay = DateTime(
    goal.createdAt.year,
    goal.createdAt.month,
    goal.createdAt.day,
  );
  final totalSpan = due.difference(createdDay).inDays;
  final GoalPaceStatus status;
  if (totalSpan <= 0) {
    status = GoalPaceStatus.onTrack;
  } else {
    final elapsed = today.difference(createdDay).inDays.clamp(0, totalSpan);
    final expectedRatio = elapsed / totalSpan;
    final actualRatio =
        goal.targetAmount > 0 ? goal.currentAmount / goal.targetAmount : 0.0;
    status = (actualRatio + 0.05 >= expectedRatio)
        ? GoalPaceStatus.onTrack
        : GoalPaceStatus.behindSchedule;
  }

  return GoalPaceSummary(
    remainingAmount: remaining,
    daysLeft: daysLeft,
    periodsLeft: periodsLeft,
    recommendedPerPeriod: recommendedPerPeriod,
    periodType: periodType,
    status: status,
  );
}

/// Halaman daftar target tabungan aktif dan selesai.
class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final goalsAsync = ref.watch(savingsGoalsProvider);

    return Scaffold(
      appBar: secondaryAppBar(context, title: Text(context.tr('Goals'))),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(context.tr('Could not load data: {error}', {'error': e})),
        ),
        data: (goals) {
          final active = goals.where((g) => g.currentAmount < g.targetAmount).toList();
          final done = goals.where((g) => g.currentAmount >= g.targetAmount).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              HeroCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('A little closer\nto your dreams'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('Small, steady savings add up over time.'),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.sage.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco_outlined,
                        color: AppColors.sage,
                        size: 34,
                      ),
                    ),
                  ],
                ),
              ),
              SectionHeader(
                title: context.tr('Active Goals'),
                actionLabel: context.tr('New goal'),
                onAction: () => _addGoal(context, ref),
              ),
              if (active.isEmpty)
                EmptyStateCard(
                  icon: Icons.flag_outlined,
                  title: context.tr('No active goals yet.'),
                  subtitle: context.tr(
                    'Create one, like an emergency fund or your next milestone.',
                  ),
                  actionLabel: context.tr('New goal'),
                  onAction: () => _addGoal(context, ref),
                )
              else
                for (final g in active)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _GoalCard(goal: g),
                  ),
              if (done.isNotEmpty) ...[
                SectionHeader(title: context.tr('Completed Goals')),
                for (final g in done)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CompletedGoalCard(goal: g),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _addGoal(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final result = await showDialog<(String, int, DateTime?)>(
      context: context,
      builder: (_) => const _GoalDialog(),
    );
    if (result != null) {
      await db.addSavingsGoal(result.$1, result.$2, targetDate: result.$3);
    }
  }
}

Color _goalColor(SavingsGoal g) =>
    Color(categoryColors[g.id.hashCode.abs() % categoryColors.length]);

String? _timeLeft(BuildContext context, DateTime? target) {
  if (target == null) return null;
  final days = target.difference(DateTime.now()).inDays;
  if (days < 0) return context.tr('Past target date');
  if (days == 0) return context.tr('Due today');
  if (days < 30) {
    return days == 1
        ? context.tr('1 day left')
        : context.tr('{n} days left', {'n': days});
  }
  final months = (days / 30).round();
  return months == 1
      ? context.tr('1 month left')
      : context.tr('{n} months left', {'n': months});
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});

  final SavingsGoal goal;

  Future<void> _handleFunds(BuildContext context, WidgetRef ref, bool isDeposit) async {
    final result = await showDialog<(int, bool, String?)>(
      context: context,
      builder: (_) => _GoalFundsDialog(goal: goal, isDeposit: isDeposit),
    );
    if (result != null && result.$1 > 0) {
      final amount = result.$1;
      final affectWallet = result.$2;
      final walletId = result.$3;
      final db = ref.read(databaseProvider);

      await db.addToSavings(goal.id, isDeposit ? amount : -amount);

      if (affectWallet && walletId != null) {
        await db.addTransaction(
          amount: amount,
          type: isDeposit ? TxType.expense : TxType.income,
          categoryId: isDeposit ? 'cat-exp-savings' : 'cat-inc-savings',
          walletId: walletId,
          date: DateTime.now(),
          note: isDeposit
              ? trG('Savings deposit: {name}', {'name': goal.name})
              : trG('Savings withdrawal: {name}', {'name': goal.name}),
        );
      }
    }
  }

  Future<void> _editGoal(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final result = await showDialog<(String, int, DateTime?)>(
      context: context,
      builder: (_) => _GoalDialog(editingGoal: goal),
    );
    if (result != null) {
      await db.updateSavingsGoal(
        goal.id,
        name: result.$1,
        targetAmount: result.$2,
        currentAmount: goal.currentAmount,
        targetDate: result.$3,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratio = goal.targetAmount == 0 ? 0.0 : goal.currentAmount / goal.targetAmount;
    final left = _timeLeft(context, goal.targetDate);
    final periodType = ref.watch(appPrefsProvider.select((p) => p.periodType));
    final pace = computeGoalPace(goal, periodType);

    final (String statusKey, Color statusColor)? paceBadge = pace == null
        ? null
        : switch (pace.status) {
            GoalPaceStatus.onTrack => ('On Track', AppColors.incomeOnDark),
            GoalPaceStatus.behindSchedule => ('Behind Schedule', AppColors.warning),
            GoalPaceStatus.dueToday => ('Due Today', AppColors.warning),
            GoalPaceStatus.overdue => ('Overdue', AppColors.expenseOnDark),
          };
    final String? paceText = pace == null
        ? null
        : (pace.status == GoalPaceStatus.dueToday ||
                pace.status == GoalPaceStatus.overdue)
            ? context.tr('Remaining: {amount}', {
                'amount': rupiah(pace.remainingAmount),
              })
            : context.tr(
                pace.periodType == PeriodType.weekly
                    ? 'Pace: {amount} / wk'
                    : 'Pace: {amount} / mo',
                {'amount': rupiah(pace.recommendedPerPeriod)},
              );

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              CategoryBadge(icon: Icons.flag_outlined, color: _goalColor(goal), size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.softIvory,
                      ),
                    ),
                    Text(
                      '${rupiah(goal.currentAmount)} / ${rupiah(goal.targetAmount)}',
                      style: context.moneyStyle(
                        fontSize: 12,
                        color: AppColors.freshSage,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(ratio * 100).round()}%',
                style: context.moneyStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dewMint,
                ),
              ),
              PopupMenuButton<String>(
                iconColor: AppColors.freshSage,
                onSelected: (v) async {
                  if (v == 'edit') {
                    await _editGoal(context, ref);
                  } else if (v == 'withdraw') {
                    await _handleFunds(context, ref, false);
                  } else if (v == 'delete') {
                    final id = goal.id;
                    final db = ref.read(databaseProvider);
                    await db.deleteSavingsGoal(id);
                    showUndoSnackBar(
                      message: trG('Savings goal deleted'),
                      onUndo: () => db.restoreSavingsGoal(id),
                    );
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text(context.tr('Edit goal'))),
                  if (goal.currentAmount > 0)
                    PopupMenuItem(value: 'withdraw', child: Text(context.tr('Withdraw funds'))),
                  PopupMenuItem(value: 'delete', child: Text(context.tr('Delete goal'))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppProgressBar(
            value: ratio,
            color: AppColors.dewMint,
            backgroundColor: AppColors.mossShadow.withValues(alpha: 0.6),
          ),
          if (paceBadge != null && paceText != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: paceBadge.$2.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: paceBadge.$2.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    context.tr(paceBadge.$1),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: paceBadge.$2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    paceText,
                    style: context.moneyStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.softIvory,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  left ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.freshSage,
                  ),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.dewMint,
                ),
                onPressed: () => _handleFunds(context, ref, true),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  context.tr('Add funds'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletedGoalCard extends StatelessWidget {
  const _CompletedGoalCard({required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.incomeOnDark.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.incomeOnDark.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: const Icon(Icons.check, color: AppColors.incomeOnDark, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.softIvory,
                  ),
                ),
                Text(
                  context.tr('Reached on {date}', {'date': shortDate(goal.updatedAt)}),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.freshSage,
                  ),
                ),
              ],
            ),
          ),
          Text(
            rupiah(goal.targetAmount),
            style: context.moneyStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.incomeOnDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalDialog extends StatefulWidget {
  const _GoalDialog({this.editingGoal});

  final SavingsGoal? editingGoal;

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.editingGoal?.name ?? '');
  late final TextEditingController _target = TextEditingController(
      text: widget.editingGoal != null
          ? formatThousands(widget.editingGoal!.targetAmount)
          : '');
  late DateTime? _date = widget.editingGoal?.targetDate;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 90)),
      firstDate: now,
      lastDate: DateTime(now.year + 30),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    final name = _name.text.trim();
    final target = parseAmount(_target.text);
    if (name.isEmpty || target <= 0) {
      setState(() => _error = context.tr('Enter a name and a target amount.'));
      return;
    }
    Navigator.pop(context, (name, target, _date));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr(widget.editingGoal != null ? 'Edit goal' : 'New goal')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: appInput(context, label: context.tr('Goal name')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _target,
              keyboardType: TextInputType.number,
              inputFormatters: amountFormatters(),
              decoration: appInput(
                context,
                label: context.tr('Target amount'),
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(_date == null ? context.tr('Target date (optional)') : shortDate(_date!)),
              trailing: _date == null
                  ? const Icon(Icons.chevron_right)
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _date = null),
                    ),
              onTap: _pickDate,
            ),
            if (_error != null)
              Text(_error!, style: TextStyle(color: context.themeColors.expense)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(onPressed: _submit, child: Text(context.tr('Save'))),
      ],
    );
  }
}

class _GoalFundsDialog extends ConsumerStatefulWidget {
  const _GoalFundsDialog({
    required this.goal,
    required this.isDeposit,
  });

  final SavingsGoal goal;
  final bool isDeposit;

  @override
  ConsumerState<_GoalFundsDialog> createState() => _GoalFundsDialogState();
}

class _GoalFundsDialogState extends ConsumerState<_GoalFundsDialog> {
  late final TextEditingController _amount = TextEditingController();
  bool _affectWallet = true;
  String? _walletId;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletsProvider).value ?? [];
    if (_walletId == null && wallets.isNotEmpty) {
      _walletId = wallets.first.id;
    }

    final maxWithdraw = widget.goal.currentAmount;
    final periodType = ref.watch(appPrefsProvider.select((p) => p.periodType));
    final pace = widget.isDeposit
        ? computeGoalPace(widget.goal, periodType)
        : null;

    return AlertDialog(
      title: Text(context.tr(
        widget.isDeposit ? 'Add funds to {name}' : 'Withdraw from {name}',
        {'name': widget.goal.name},
      )),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: amountFormatters(),
              decoration: appInput(
                context,
                prefixText: 'Rp ',
                hint: widget.isDeposit ? '0' : formatThousands(maxWithdraw),
              ),
            ),
            if (pace != null && pace.recommendedPerPeriod > 0) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  avatar: const Icon(
                    Icons.bolt_rounded,
                    size: 16,
                    color: AppColors.dewMint,
                  ),
                  label: Text(
                    context.tr('Use pace: {amount}', {
                      'amount': rupiah(pace.recommendedPerPeriod),
                    }),
                    style: context.moneyStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dewMint,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _amount.text = formatThousands(pace.recommendedPerPeriod);
                    });
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _affectWallet,
              onChanged: (v) => setState(() => _affectWallet = v),
              title: Text(context.tr(
                widget.isDeposit ? 'Deduct from account' : 'Deposit to account',
              )),
            ),
            if (_affectWallet && wallets.isNotEmpty) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _walletId,
                decoration: appInput(context, label: context.tr('Account / Wallet')),
                items: [
                  for (final w in wallets)
                    DropdownMenuItem(value: w.id, child: Text(context.tr(w.name))),
                ],
                onChanged: (val) => setState(() => _walletId = val),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          onPressed: () {
            var val = parseAmount(_amount.text);
            if (!widget.isDeposit && val > maxWithdraw) {
              val = maxWithdraw;
            }
            if (val > 0) {
              Navigator.pop(context, (val, _affectWallet, _walletId));
            }
          },
          child: Text(context.tr('Save')),
        ),
      ],
    );
  }
}
