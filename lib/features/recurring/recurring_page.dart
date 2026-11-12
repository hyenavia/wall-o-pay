/// Halaman pengelolaan jadwal transaksi berulang dan langganan ([RecurringPage]),
/// mendukung frekuensi harian, mingguan, dan bulanan.
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
import '../../data/budget_rule.dart';
import '../../data/feature_prefs.dart';
import '../../data/feature_providers.dart';
import '../../data/notifications.dart';
import '../../data/prefs.dart';
import '../../data/providers.dart';
import '../../data/recurring_service.dart' hide recurringRulesProvider;
import '../../data/tables.dart';

/// Widget halaman daftar jadwal transaksi berulang, antrean konfirmasi jatuh tempo,
/// serta dialog tambah/ubah jadwal.
class RecurringPage extends ConsumerWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(recurringRulesProvider);
    final pendingList =
        ref.watch(pendingTransactionsProvider).value ?? const <PendingTransaction>[];
    final cats = ref.watch(categoryMapProvider);
    final wallets = ref.watch(walletsProvider).value ?? const <Wallet>[];
    final walletMap = {for (final w in wallets) w.id: w};

    return Scaffold(
      appBar: secondaryAppBar(
        context,
        title: Text(context.tr('Recurring & Subscriptions')),
      ),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(context.tr('Error: {error}', {'error': e})),
        ),
        data: (rules) {
          if (rules.isEmpty && pendingList.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: EmptyStateCard(
                  icon: Icons.repeat_rounded,
                  title: context.tr('No recurring schedules yet.'),
                  subtitle: context.tr(
                    'Set up regular income, bills, or subscription schedules. They will prompt you for confirmation on their due date before recording.',
                  ),
                  actionLabel: context.tr('Add Schedule'),
                  onAction: () => _showAddOrEditDialog(context),
                ),
              ),
            );
          }

          final activeCount = rules.where((r) => r.isActive).length;
          final monthlyExpenseEst = rules
              .where((r) => r.isActive && r.type == TxType.expense)
              .fold<int>(0, (sum, r) {
            final factor = switch (r.frequency) {
              RecurFrequency.daily => 30,
              RecurFrequency.weekly => 4,
              RecurFrequency.monthly => 1,
            };
            return sum + (r.amount * factor);
          });

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            children: [
              if (pendingList.isNotEmpty) ...[
                _PendingSectionHeader(count: pendingList.length),
                const SizedBox(height: 8),
                for (final p in pendingList) ...[
                  _PendingCard(
                    pending: p,
                    category: cats[p.categoryId],
                    wallet: p.walletId != null ? walletMap[p.walletId] : null,
                    toWallet:
                        p.toWalletId != null ? walletMap[p.toWalletId] : null,
                    onConfirm: () => _confirmPending(context, ref, p),
                    onEdit: () => _showEditPendingSheet(context, ref, p),
                    onSkip: () => _skipPending(context, ref, p),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
              ],
              if (rules.isNotEmpty) ...[
                HeroCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('Active Schedules'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activeCount == 1
                                  ? context.tr('1 active schedule')
                                  : context.tr('{count} active schedules', {
                                      'count': activeCount,
                                    }),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            context.tr('Est. monthly bills'),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rupiah(monthlyExpenseEst),
                            style: context.moneyStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.dewMint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              for (final r in rules) ...[
                _RuleCard(
                  rule: r,
                  category: cats[r.categoryId],
                  wallet: r.walletId != null ? walletMap[r.walletId] : null,
                  toWallet:
                      r.toWalletId != null ? walletMap[r.toWalletId] : null,
                  freqText: switch (r.frequency) {
                    RecurFrequency.daily => context.tr('Daily'),
                    RecurFrequency.weekly => context.tr('Every {day}', {
                        'day': _weekdayName(context, r.dayOfWeek ?? 1),
                      }),
                    RecurFrequency.monthly => context.tr(
                        'Every month on the {day}th',
                        {'day': r.dayOfMonth ?? 1},
                      ),
                  },
                  onTap: () => _showAddOrEditDialog(context, existing: r),
                  onToggle: (active) async {
                    await ref
                        .read(databaseProvider)
                        .toggleRecurringRule(r.id, active);
                  },
                  onAction: (action) async {
                    final db = ref.read(databaseProvider);
                    switch (action) {
                      case 'edit':
                        _showAddOrEditDialog(context, existing: r);
                      case 'record_now':
                        await _recordRuleNow(context, ref, r);
                      case 'skip_next':
                        final next =
                            await RecurringService.skipNextDueDate(db, r);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.tr('Skipped. Next due on {date}.', {
                                  'date': shortDate(next),
                                }),
                              ),
                            ),
                          );
                        }
                      case 'delete':
                        await db.deleteRecurringRule(r.id);
                        showUndoSnackBar(
                          message: trG('Recurring schedule deleted'),
                          onUndo: () => db.restoreRecurringRule(r.id),
                        );
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: context.themeColors.heroBackground,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(context.tr('Add Schedule')),
        onPressed: () => _showAddOrEditDialog(context),
      ),
    );
  }

  Future<void> _confirmPending(
    BuildContext context,
    WidgetRef ref,
    PendingTransaction p, {
    int? amountOverride,
    String? walletIdOverride,
    String? toWalletIdOverride,
    String? noteOverride,
  }) async {
    final db = ref.read(databaseProvider);
    final created = await db.confirmPendingTransaction(
      p.id,
      amountOverride: amountOverride,
      walletIdOverride: walletIdOverride,
      toWalletIdOverride: toWalletIdOverride,
      noteOverride: noteOverride,
    );
    if (created != null && created.type == TxType.expense) {
      final fPrefs = ref.read(featurePrefsProvider);
      if (fPrefs.budgetAlerts) {
        final appPrefs = ref.read(appPrefsProvider);
        final cat = ref.read(categoryMapProvider)[created.categoryId];
        final txPeriod = Period.containing(
          appPrefs.periodType,
          created.date,
          firstDayOfWeek: appPrefs.firstDayOfWeek,
          firstDayOfMonth: appPrefs.firstDayOfMonth,
        );
        checkBudgetAfterExpense(
          db: db,
          prefs: ref.read(sharedPreferencesProvider),
          periodType: appPrefs.periodType,
          categoryId: created.categoryId,
          categoryName: cat?.name ?? 'Uncategorized',
          date: created.date,
          firstDayOfWeek: appPrefs.firstDayOfWeek,
          firstDayOfMonth: appPrefs.firstDayOfMonth,
          rolloverEnabled: fPrefs.rollover,
          totalBudgetPool: ref.read(budgetRuleProvider).getTotalBudget(txPeriod.key),
        );
      }
    }
    if (context.mounted && created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Transaction recorded'))),
      );
    }
  }

  Future<void> _skipPending(
    BuildContext context,
    WidgetRef ref,
    PendingTransaction p,
  ) async {
    final db = ref.read(databaseProvider);
    await db.dismissPendingTransaction(p.id);
    showUndoSnackBar(
      message: trG('Pending item skipped'),
      onUndo: () => db.restorePendingTransaction(p.id),
    );
  }

  Future<void> _recordRuleNow(
    BuildContext context,
    WidgetRef ref,
    RecurringRule r,
  ) async {
    final db = ref.read(databaseProvider);
    final nextDue = await RecurringService.recordRuleNow(db, r);
    if (r.type == TxType.expense) {
      final fPrefs = ref.read(featurePrefsProvider);
      if (fPrefs.budgetAlerts) {
        final appPrefs = ref.read(appPrefsProvider);
        final cat = ref.read(categoryMapProvider)[r.categoryId];
        final now = DateTime.now();
        final txPeriod = Period.containing(
          appPrefs.periodType,
          now,
          firstDayOfWeek: appPrefs.firstDayOfWeek,
          firstDayOfMonth: appPrefs.firstDayOfMonth,
        );
        checkBudgetAfterExpense(
          db: db,
          prefs: ref.read(sharedPreferencesProvider),
          periodType: appPrefs.periodType,
          categoryId: r.categoryId,
          categoryName: cat?.name ?? 'Uncategorized',
          date: now,
          firstDayOfWeek: appPrefs.firstDayOfWeek,
          firstDayOfMonth: appPrefs.firstDayOfMonth,
          rolloverEnabled: fPrefs.rollover,
          totalBudgetPool: ref.read(budgetRuleProvider).getTotalBudget(txPeriod.key),
        );
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('Recorded! Next due on {date}.', {
              'date': shortDate(nextDue),
            }),
          ),
        ),
      );
    }
  }

  void _showEditPendingSheet(
    BuildContext context,
    WidgetRef ref,
    PendingTransaction p,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PendingEditSheet(
        pending: p,
        onConfirm: (amount, walletId, toWalletId, note) => _confirmPending(
          context,
          ref,
          p,
          amountOverride: amount,
          walletIdOverride: walletId,
          toWalletIdOverride: toWalletId,
          noteOverride: note,
        ),
      ),
    );
  }

  static String _weekdayName(BuildContext ctx, int day) {
    return switch (day) {
      1 => ctx.tr('Monday'),
      2 => ctx.tr('Tuesday'),
      3 => ctx.tr('Wednesday'),
      4 => ctx.tr('Thursday'),
      5 => ctx.tr('Friday'),
      6 => ctx.tr('Saturday'),
      7 => ctx.tr('Sunday'),
      _ => ctx.tr('Monday'),
    };
  }

  void _showAddOrEditDialog(BuildContext context, {RecurringRule? existing}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RecurringFormSheet(existing: existing),
    );
  }
}

class _PendingSectionHeader extends StatelessWidget {
  const _PendingSectionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.pending_actions_rounded, size: 18, color: AppColors.dewMint),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.tr('Pending Confirmation ({count})', {'count': count}),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              color: AppColors.softIvory,
            ),
          ),
        ),
      ],
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.pending,
    required this.category,
    required this.wallet,
    required this.toWallet,
    required this.onConfirm,
    required this.onEdit,
    required this.onSkip,
  });

  final PendingTransaction pending;
  final Category? category;
  final Wallet? wallet;
  final Wallet? toWallet;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final isTransfer = pending.type == TxType.transfer;
    final isIncome = pending.type == TxType.income;
    final accentColor = isTransfer
        ? AppColors.dewMint
        : (isIncome ? AppColors.incomeOnDark : AppColors.expenseOnDark);
    final sign = isTransfer ? '' : (isIncome ? '+' : '-');
    final walletSummary = isTransfer && wallet != null && toWallet != null
        ? '${context.tr(wallet!.name)} -> ${context.tr(toWallet!.name)}'
        : (wallet != null ? context.tr(wallet!.name) : '');

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryBadge(
                icon: isTransfer
                    ? Icons.swap_horiz_rounded
                    : iconFor(category?.icon ?? 'more'),
                color: category != null ? Color(category!.colorValue) : AppColors.dewMint,
                size: 40,
                categoryKey: category?.id,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pending.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.softIvory,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      walletSummary.isNotEmpty
                          ? '${context.tr('Due {date}', {'date': shortDate(pending.dueDate)})} • $walletSummary'
                          : context.tr('Due {date}', {'date': shortDate(pending.dueDate)}),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.freshSage,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$sign${rupiah(pending.amount)}',
                style: context.moneyStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSkip,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.freshSage,
                    side: BorderSide(color: AppColors.dewMint.withValues(alpha: 0.22)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(context.tr('Skip')),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.softIvory,
                  side: BorderSide(color: AppColors.dewMint.withValues(alpha: 0.25)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(context.tr('Edit')),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check_rounded, size: 17),
                  label: Text(
                    context.tr('Confirm'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.dewMint,
                    foregroundColor: AppColors.deepForest,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.category,
    required this.wallet,
    required this.toWallet,
    required this.freqText,
    required this.onTap,
    required this.onToggle,
    required this.onAction,
  });

  final RecurringRule rule;
  final Category? category;
  final Wallet? wallet;
  final Wallet? toWallet;
  final String freqText;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final isTransfer = rule.type == TxType.transfer;
    final isIncome = rule.type == TxType.income;
    final catColor = category != null ? Color(category!.colorValue) : AppColors.sage;
    final amountColor = isTransfer
        ? AppColors.dewMint
        : (isIncome ? AppColors.incomeOnDark : AppColors.expenseOnDark);
    final sign = isTransfer ? '' : (isIncome ? '+' : '-');
    final walletLabel = isTransfer && wallet != null && toWallet != null
        ? '${context.tr(wallet!.name)} -> ${context.tr(toWallet!.name)}'
        : (wallet != null ? context.tr(wallet!.name) : '');

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isTransfer
                  ? Icons.swap_horiz_rounded
                  : iconFor(category?.icon ?? 'more'),
              color: catColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rule.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.softIvory,
                          decoration: rule.isActive ? null : TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                    Text(
                      '$sign${rupiah(rule.amount)}',
                      style: context.moneyStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: amountColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  walletLabel.isNotEmpty ? '$freqText • $walletLabel' : freqText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.freshSage,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('Next due: {date}', {
                    'date': shortDate(rule.nextDueDate),
                  }),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.dewMint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Switch(
            value: rule.isActive,
            onChanged: onToggle,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: onAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(context.tr('Edit')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'record_now',
                child: Row(
                  children: [
                    const Icon(Icons.play_arrow_rounded, size: 18, color: AppColors.incomeOnDark),
                    const SizedBox(width: 8),
                    Text(context.tr('Record now')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'skip_next',
                child: Row(
                  children: [
                    const Icon(Icons.skip_next_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(context.tr('Skip next due')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: context.themeColors.expense, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('Delete'),
                      style: TextStyle(color: context.themeColors.expense),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingEditSheet extends ConsumerStatefulWidget {
  const _PendingEditSheet({
    required this.pending,
    required this.onConfirm,
  });

  final PendingTransaction pending;
  final Future<void> Function(
    int amount,
    String? walletId,
    String? toWalletId,
    String note,
  ) onConfirm;

  @override
  ConsumerState<_PendingEditSheet> createState() => _PendingEditSheetState();
}

class _PendingEditSheetState extends ConsumerState<_PendingEditSheet> {
  late final TextEditingController _amountCtl =
      TextEditingController(text: formatThousands(widget.pending.amount));
  late final TextEditingController _noteCtl =
      TextEditingController(text: widget.pending.note);
  late String? _walletId = widget.pending.walletId;
  late String? _toWalletId = widget.pending.toWalletId;

  @override
  void dispose() {
    _amountCtl.dispose();
    _noteCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wallets = ref.watch(walletsProvider).value ?? const <Wallet>[];
    final isTransfer = widget.pending.type == TxType.transfer;
    if (_walletId == null && wallets.isNotEmpty) {
      _walletId = wallets.first.id;
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.pending.title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtl,
              keyboardType: TextInputType.number,
              inputFormatters: amountFormatters(),
              decoration: appInput(context, label: context.tr('Amount'), prefixText: 'Rp '),
            ),
            const SizedBox(height: 12),
            if (wallets.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: wallets.any((w) => w.id == _walletId) ? _walletId : wallets.first.id,
                decoration: appInput(
                  context,
                  label: context.tr(isTransfer ? 'From wallet' : 'Wallet / Account'),
                ),
                items: [
                  for (final w in wallets)
                    DropdownMenuItem(value: w.id, child: Text(context.tr(w.name))),
                ],
                onChanged: (val) => setState(() => _walletId = val),
              ),
              const SizedBox(height: 12),
            ],
            if (isTransfer && wallets.length > 1) ...[
              DropdownButtonFormField<String>(
                initialValue: wallets.any((w) => w.id == _toWalletId)
                    ? _toWalletId
                    : wallets.last.id,
                decoration: appInput(context, label: context.tr('To wallet')),
                items: [
                  for (final w in wallets)
                    DropdownMenuItem(value: w.id, child: Text(context.tr(w.name))),
                ],
                onChanged: (val) => setState(() => _toWalletId = val),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _noteCtl,
              decoration: appInput(context, label: context.tr('Note (optional)')),
            ),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: context.themeColors.heroBackground,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () async {
                final amount = parseAmount(_amountCtl.text);
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('Amount must be greater than 0.'))),
                  );
                  return;
                }
                if (isTransfer && (_walletId == null || _toWalletId == null || _walletId == _toWalletId)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('Source and destination wallets must be different.'))),
                  );
                  return;
                }
                Navigator.pop(context);
                await widget.onConfirm(amount, _walletId, _toWalletId, _noteCtl.text.trim());
              },
              child: Text(context.tr('Confirm & Record')),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringFormSheet extends ConsumerStatefulWidget {
  const _RecurringFormSheet({this.existing});

  final RecurringRule? existing;

  @override
  ConsumerState<_RecurringFormSheet> createState() => _RecurringFormSheetState();
}

class _RecurringFormSheetState extends ConsumerState<_RecurringFormSheet> {
  late final TextEditingController _titleCtl =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _amountCtl = TextEditingController(
    text: widget.existing != null ? formatThousands(widget.existing!.amount) : '',
  );
  late final TextEditingController _noteCtl =
      TextEditingController(text: widget.existing?.note ?? '');

  late TxType _type = widget.existing?.type ?? TxType.expense;
  late RecurFrequency _freq = widget.existing?.frequency ?? RecurFrequency.weekly;
  late int _dayOfWeek = widget.existing?.dayOfWeek ?? DateTime.wednesday;
  late int _dayOfMonth = widget.existing?.dayOfMonth ?? 1;
  late String? _categoryId = widget.existing?.categoryId;
  late String? _walletId = widget.existing?.walletId ?? 'wallet-main';
  late String? _toWalletId = widget.existing?.toWalletId;

  @override
  void dispose() {
    _titleCtl.dispose();
    _amountCtl.dispose();
    _noteCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;
    final allCats = ref.watch(categoriesProvider).value ?? const <Category>[];
    final cats = allCats.where((c) => c.type == _type).toList();
    final wallets = ref.watch(walletsProvider).value ?? const <Wallet>[];

    if (_type != TxType.transfer &&
        (_categoryId == null || !cats.any((c) => c.id == _categoryId)) &&
        cats.isNotEmpty) {
      _categoryId = cats.first.id;
    }
    if (_walletId == null && wallets.isNotEmpty) {
      _walletId = wallets.first.id;
    }
    if (_type == TxType.transfer && _toWalletId == null && wallets.length > 1) {
      _toWalletId = wallets.firstWhere((w) => w.id != _walletId, orElse: () => wallets.last).id;
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(isEdit ? 'Edit Recurring Schedule' : 'New Recurring Schedule'),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<TxType>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: TxType.expense, label: Text(context.tr('Expense'))),
                  ButtonSegment(value: TxType.income, label: Text(context.tr('Income'))),
                  ButtonSegment(value: TxType.transfer, label: Text(context.tr('Transfer'))),
                ],
                selected: {_type},
                onSelectionChanged: (s) {
                  setState(() {
                    _type = s.first;
                    _categoryId = _type == TxType.transfer ? 'cat-tra-transfer' : null;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtl,
              decoration: appInput(context, label: context.tr('Title (e.g. Kiriman Ortu, Kost, Netflix)')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtl,
              keyboardType: TextInputType.number,
              inputFormatters: amountFormatters(),
              decoration: appInput(context, label: context.tr('Amount'), prefixText: 'Rp '),
            ),
            const SizedBox(height: 14),
            Text(context.tr('Frequency'), style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<RecurFrequency>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: RecurFrequency.weekly, label: Text(context.tr('Weekly'))),
                  ButtonSegment(value: RecurFrequency.monthly, label: Text(context.tr('Monthly'))),
                  ButtonSegment(value: RecurFrequency.daily, label: Text(context.tr('Daily'))),
                ],
                selected: {_freq},
                onSelectionChanged: (s) => setState(() => _freq = s.first),
              ),
            ),
            const SizedBox(height: 12),
            if (_freq == RecurFrequency.weekly) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.tr('Day of week'), style: theme.textTheme.bodyMedium),
                  DropdownButton<int>(
                    value: _dayOfWeek,
                    underline: const SizedBox(),
                    borderRadius: BorderRadius.circular(12),
                    items: [
                      DropdownMenuItem(value: DateTime.monday, child: Text(context.tr('Monday'))),
                      DropdownMenuItem(value: DateTime.tuesday, child: Text(context.tr('Tuesday'))),
                      DropdownMenuItem(value: DateTime.wednesday, child: Text(context.tr('Wednesday'))),
                      DropdownMenuItem(value: DateTime.thursday, child: Text(context.tr('Thursday'))),
                      DropdownMenuItem(value: DateTime.friday, child: Text(context.tr('Friday'))),
                      DropdownMenuItem(value: DateTime.saturday, child: Text(context.tr('Saturday'))),
                      DropdownMenuItem(value: DateTime.sunday, child: Text(context.tr('Sunday'))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _dayOfWeek = val);
                    },
                  ),
                ],
              ),
            ] else if (_freq == RecurFrequency.monthly) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.tr('Day of month'), style: theme.textTheme.bodyMedium),
                  DropdownButton<int>(
                    value: _dayOfMonth,
                    underline: const SizedBox(),
                    borderRadius: BorderRadius.circular(12),
                    items: [
                      for (int d = 1; d <= 31; d++)
                        DropdownMenuItem(value: d, child: Text(context.tr('Day {n}', {'n': d}))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _dayOfMonth = val);
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (wallets.isNotEmpty) ...[
              Text(
                context.tr(_type == TxType.transfer ? 'From wallet' : 'Wallet / Account'),
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: wallets.any((w) => w.id == _walletId) ? _walletId : wallets.first.id,
                decoration: appInput(context),
                items: [
                  for (final w in wallets)
                    DropdownMenuItem(value: w.id, child: Text(context.tr(w.name))),
                ],
                onChanged: (val) => setState(() => _walletId = val),
              ),
              const SizedBox(height: 12),
            ],
            if (_type == TxType.transfer && wallets.length > 1) ...[
              Text(context.tr('To wallet'), style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: wallets.any((w) => w.id == _toWalletId)
                    ? _toWalletId
                    : wallets.last.id,
                decoration: appInput(context),
                items: [
                  for (final w in wallets)
                    DropdownMenuItem(value: w.id, child: Text(context.tr(w.name))),
                ],
                onChanged: (val) => setState(() => _toWalletId = val),
              ),
              const SizedBox(height: 12),
            ],
            if (_type != TxType.transfer && cats.isNotEmpty) ...[
              Text(context.tr('Category'), style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: cats.any((c) => c.id == _categoryId) ? _categoryId : cats.first.id,
                decoration: appInput(context),
                items: [
                  for (final c in cats)
                    DropdownMenuItem(value: c.id, child: Text(context.tr(c.name))),
                ],
                onChanged: (val) => setState(() => _categoryId = val),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _noteCtl,
              decoration: appInput(context, label: context.tr('Note (optional)')),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: context.themeColors.heroBackground,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final title = _titleCtl.text.trim();
                  final amount = parseAmount(_amountCtl.text);
                  final effectiveCat =
                      _type == TxType.transfer ? 'cat-tra-transfer' : _categoryId;
                  if (title.isEmpty || amount <= 0 || effectiveCat == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('Please fill in title and amount.'))),
                    );
                    return;
                  }
                  if (_type == TxType.transfer &&
                      (_walletId == null || _toWalletId == null || _walletId == _toWalletId)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.tr('Source and destination wallets must be different.'),
                        ),
                      ),
                    );
                    return;
                  }

                  final now = DateTime.now();
                  final db = ref.read(databaseProvider);

                  if (isEdit) {
                    final old = widget.existing!;
                    final scheduleChanged = old.frequency != _freq ||
                        (_freq == RecurFrequency.weekly && old.dayOfWeek != _dayOfWeek) ||
                        (_freq == RecurFrequency.monthly && old.dayOfMonth != _dayOfMonth);
                    final nextDue = scheduleChanged
                        ? RecurringService.calculateNextDueDate(
                            _freq,
                            now,
                            dayOfWeek: _dayOfWeek,
                            dayOfMonth: _dayOfMonth,
                          )
                        : old.nextDueDate;

                    await db.updateRecurringRule(
                      old.id,
                      title: title,
                      amount: amount,
                      type: _type,
                      categoryId: effectiveCat,
                      walletId: _walletId,
                      toWalletId: _type == TxType.transfer ? _toWalletId : null,
                      clearToWalletId: _type != TxType.transfer,
                      frequency: _freq,
                      dayOfWeek: _freq == RecurFrequency.weekly ? _dayOfWeek : null,
                      dayOfMonth: _freq == RecurFrequency.monthly ? _dayOfMonth : null,
                      nextDueDate: nextDue,
                      note: _noteCtl.text.trim(),
                    );
                  } else {
                    final nextDue = RecurringService.calculateNextDueDate(
                      _freq,
                      now,
                      dayOfWeek: _dayOfWeek,
                      dayOfMonth: _dayOfMonth,
                    );
                    await db.addRecurringRule(
                      title: title,
                      amount: amount,
                      type: _type,
                      categoryId: effectiveCat,
                      walletId: _walletId,
                      toWalletId: _type == TxType.transfer ? _toWalletId : null,
                      frequency: _freq,
                      dayOfWeek: _freq == RecurFrequency.weekly ? _dayOfWeek : null,
                      dayOfMonth: _freq == RecurFrequency.monthly ? _dayOfMonth : null,
                      startDate: now,
                      nextDueDate: nextDue,
                      note: _noteCtl.text.trim(),
                    );
                  }

                  await RecurringService.checkAndGenerateDue(db);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.tr(
                            isEdit
                                ? 'Recurring schedule updated!'
                                : 'Recurring schedule created!',
                          ),
                        ),
                      ),
                    );
                  }
                },
                child: Text(context.tr('Save Schedule')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
