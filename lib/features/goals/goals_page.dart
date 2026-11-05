import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_database.dart';
import '../../data/providers.dart';
import '../../data/tables.dart' show TxType;

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final goalsAsync = ref.watch(savingsGoalsProvider);

    return Scaffold(
      appBar: pageAppBar(context, title: Text(context.tr('Goals'))),
      body: BotanicalBackgroundSheet(
        child: goalsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(context.tr('Could not load data: {error}', {'error': e})),
          ),
          data: (goals) {
          final active = goals.where((g) => g.currentAmount < g.targetAmount).toList();
          final done = goals.where((g) => g.currentAmount >= g.targetAmount).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
                      child: const Icon(Icons.eco_outlined, color: AppColors.sage, size: 34),
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
                AppCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        context.tr('No active goals yet.\nCreate one, like an emergency fund.'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
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
          categoryId: isDeposit ? 'cat-exp-other' : 'cat-inc-other',
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final ratio = goal.targetAmount == 0 ? 0.0 : goal.currentAmount / goal.targetAmount;
    final left = _timeLeft(context, goal.targetDate);

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
                    Text(goal.name,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      '${rupiah(goal.currentAmount)} / ${rupiah(goal.targetAmount)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              Text(
                '${(ratio * 100).round()}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
              PopupMenuButton<String>(
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
          AppProgressBar(value: ratio),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  left ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
              TextButton.icon(
                onPressed: () => _handleFunds(context, ref, true),
                icon: const Icon(Icons.add, size: 18),
                label: Text(context.tr('Add funds')),
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
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(Icons.check, color: theme.colorScheme.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.name,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                Text(
                  context.tr('Reached on {date}', {'date': shortDate(goal.updatedAt)}),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(rupiah(goal.targetAmount),
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
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
              Text(_error!, style: const TextStyle(color: AppColors.expense)),
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
                    DropdownMenuItem(value: w.id, child: Text(w.name)),
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
