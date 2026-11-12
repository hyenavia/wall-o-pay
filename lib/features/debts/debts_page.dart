/// Halaman pencatatan buku utang-piutang ([DebtsPage]), pelunasan bertahap,
/// serta kalkulator pembagian tagihan patungan bersama teman (`showSplitSheet`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_database.dart';
import '../../data/feature_providers.dart';
import '../../data/notifications.dart';
import '../../data/providers.dart';
import '../../data/tables.dart' show DebtDirection, TxType;

class CustomSplitResult {
  const CustomSplitResult({
    required this.isValid,
    required this.friendsTotal,
    required this.myShare,
    this.errorKey,
  });

  final bool isValid;
  final int friendsTotal;
  final int myShare;
  final String? errorKey;
}

/// Memvalidasi dan menghitung total porsi teman serta porsi pribadi pada mode Patungan Kustom.
CustomSplitResult computeCustomSplit({
  required int total,
  required List<int> friendAmounts,
}) {
  if (total <= 0 || friendAmounts.isEmpty) {
    return const CustomSplitResult(
      isValid: false,
      friendsTotal: 0,
      myShare: 0,
      errorKey: 'Enter the total and at least one friend.',
    );
  }
  if (friendAmounts.any((a) => a <= 0)) {
    return CustomSplitResult(
      isValid: false,
      friendsTotal: friendAmounts.fold<int>(0, (s, a) => s + a),
      myShare: total - friendAmounts.fold<int>(0, (s, a) => s + a),
      errorKey: "Every friend's share must be greater than 0.",
    );
  }
  final friendsTotal = friendAmounts.fold<int>(0, (s, a) => s + a);
  final myShare = total - friendsTotal;
  if (friendsTotal > total) {
    return CustomSplitResult(
      isValid: false,
      friendsTotal: friendsTotal,
      myShare: myShare,
      errorKey: "Friends' total exceeds the bill total.",
    );
  }
  return CustomSplitResult(
    isValid: true,
    friendsTotal: friendsTotal,
    myShare: myShare,
  );
}

/// Halaman utama fitur Utang & Patungan (Piutangku vs Utangku).
class DebtsPage extends ConsumerStatefulWidget {
  const DebtsPage({super.key});

  @override
  ConsumerState<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends ConsumerState<DebtsPage> {
  DebtDirection _tab = DebtDirection.lent;

  @override
  Widget build(BuildContext context) {
    final debtsAsync = ref.watch(debtsProvider);

    return Scaffold(
      appBar: secondaryAppBar(
        context,
        title: Text(context.tr('Debts & splits')),
        actions: [
          IconButton(
            tooltip: context.tr('Split a bill'),
            icon: const Icon(Icons.groups_outlined),
            onPressed: () => showSplitSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDebtForm(context, initial: _tab),
        icon: const Icon(Icons.add),
        label: Text(context.tr('Add debt')),
      ),
      body: debtsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(context.tr('Could not load data: {error}', {'error': e})),
        ),
        data: (all) {
          int remaining(DebtDirection d) => all
              .where((x) => x.direction == d)
              .fold<int>(0, (s, x) => s + (x.amount - x.paidAmount));
          final list = all.where((d) => d.direction == _tab).toList()
            ..sort((a, b) {
              final aDone = a.paidAmount >= a.amount ? 1 : 0;
              final bDone = b.paidAmount >= b.amount ? 1 : 0;
              return aDone.compareTo(bDone);
            });

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            children: [
              HeroCard(
                child: Row(
                  children: [
                    Expanded(
                      child: _Total(
                        label: context.tr('Owed to me'),
                        value: rupiah(remaining(DebtDirection.lent)),
                      ),
                    ),
                    Container(width: 1, height: 44, color: Colors.white24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _Total(
                        label: context.tr('I owe'),
                        value: rupiah(remaining(DebtDirection.borrowed)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SegmentedButton<DebtDirection>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.dewMint.withValues(alpha: 0.22),
                  selectedForegroundColor: AppColors.dewMint,
                  foregroundColor: AppColors.freshSage,
                  side: BorderSide(
                    color: AppColors.dewMint.withValues(alpha: 0.25),
                  ),
                ),
                segments: [
                  ButtonSegment(
                    value: DebtDirection.lent,
                    label: Text(
                      context.tr('Owed to me'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  ButtonSegment(
                    value: DebtDirection.borrowed,
                    label: Text(
                      context.tr('I owe'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('Debts are a separate ledger and do not change your account balances.'),
                style: const TextStyle(fontSize: 12, color: AppColors.freshSage),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                EmptyStateCard(
                  icon: Icons.handshake_outlined,
                  title: context.tr(
                    _tab == DebtDirection.lent
                        ? 'No receivables recorded yet'
                        : 'No debts recorded yet',
                  ),
                  subtitle: context.tr(
                    'Track money owed and bill splits separately from your main accounts.',
                  ),
                  actionLabel: context.tr('Add debt'),
                  onAction: () => showDebtForm(context, initial: _tab),
                )
              else
                for (final d in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DebtCard(debt: d),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.moneyStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({required this.debt});

  final Debt debt;

  @override
  Widget build(BuildContext context) {
    final left = debt.amount - debt.paidAmount;
    final done = left <= 0;
    final ratio = debt.amount == 0 ? 0.0 : debt.paidAmount / debt.amount;
    final overdue = !done &&
        debt.dueDate != null &&
        debt.dueDate!.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    return AppCard(
      onTap: () => showDebtDetail(context, debt),
      child: Opacity(
        opacity: done ? 0.6 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryBadge(
                  icon: done ? Icons.check : Icons.person_outline,
                  color: done ? AppColors.incomeOnDark : AppColors.dewMint,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.person,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.softIvory,
                        ),
                      ),
                      if (debt.note.isNotEmpty)
                        Text(
                          debt.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.freshSage,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  done ? context.tr('Settled') : rupiah(left),
                  style: done
                      ? const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.incomeOnDark,
                        )
                      : context.moneyStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.softIvory,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AppProgressBar(
              value: ratio,
              color: done ? AppColors.incomeOnDark : AppColors.dewMint,
              backgroundColor: AppColors.mossShadow.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('{paid} of {total}', {
                      'paid': rupiah(debt.paidAmount),
                      'total': rupiah(debt.amount),
                    }),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.freshSage,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                if (debt.dueDate != null)
                  Text(
                    context.tr('Due {date}', {'date': shortDate(debt.dueDate!)}),
                    style: TextStyle(
                      fontSize: 11,
                      color: overdue ? AppColors.expenseOnDark : AppColors.freshSage,
                      fontWeight: overdue ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail dan pembayaran
// ---------------------------------------------------------------------------

Future<void> showDebtDetail(BuildContext context, Debt debt) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _DebtDetail(debt: debt),
  );
}

class _DebtDetail extends ConsumerWidget {
  const _DebtDetail({required this.debt});

  final Debt debt;

  Future<void> _record(
    WidgetRef ref,
    Debt liveDebt,
    int amount,
    bool alsoTransaction,
    String? walletId,
  ) async {
    final db = ref.read(databaseProvider);
    final lent = liveDebt.direction == DebtDirection.lent;
    await db.recordDebtPayment(
      debtId: liveDebt.id,
      amount: amount,
      createWalletTransaction: alsoTransaction,
      walletId: walletId,
      transactionNote: lent
          ? trG('Repayment from {person}', {'person': liveDebt.person})
          : trG('Payment to {person}', {'person': liveDebt.person}),
    );
    checkDebtDueReminders(db);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final liveDebt = (ref.watch(debtsProvider).value ?? const <Debt>[])
        .firstWhere((d) => d.id == debt.id, orElse: () => debt);
    final payments = ref.watch(debtPaymentsProvider(liveDebt.id)).value ??
        const <DebtPayment>[];
    final wallets = ref.watch(walletMapProvider);
    final left = liveDebt.amount - liveDebt.paidAmount;
    final lent = liveDebt.direction == DebtDirection.lent;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      liveDebt.person,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr('Edit'),
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {
                      Navigator.pop(context);
                      showDebtForm(context, debt: liveDebt);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                context.tr(lent ? 'They owe you' : 'You owe them'),
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(height: 16),
              Text(
                rupiah(left > 0 ? left : 0),
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                context.tr('{paid} of {total}', {
                  'paid': rupiah(liveDebt.paidAmount),
                  'total': rupiah(liveDebt.amount),
                }),
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
              if (liveDebt.note.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(liveDebt.note),
              ],
              const SizedBox(height: 20),
              if (left > 0) ...[
                FilledButton.icon(
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(context.tr('Record payment')),
                  onPressed: () async {
                    final result = await showDialog<(int, bool, String?)>(
                      context: context,
                      builder: (_) => _PaymentDialog(remaining: left, lent: lent),
                    );
                    if (result != null && result.$1 > 0) {
                      await _record(ref, liveDebt, result.$1, result.$2, result.$3);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    final result = await showDialog<(int, bool, String?)>(
                      context: context,
                      builder: (_) => _PaymentDialog(
                        remaining: left,
                        lent: lent,
                        fixedFullPayment: true,
                      ),
                    );
                    if (result != null && result.$1 > 0) {
                      await _record(ref, liveDebt, left, result.$2, result.$3);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: Text(context.tr('Mark as fully paid')),
                ),
              ],
              if (payments.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  context.tr('Payment History'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.dewMint,
                  ),
                ),
                const SizedBox(height: 8),
                for (final p in payments)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.dewMint.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shortDate(p.date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: AppColors.softIvory,
                                ),
                              ),
                              if (p.walletId != null && wallets[p.walletId!] != null)
                                Text(
                                  context.tr(wallets[p.walletId!]!.name),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.freshSage,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          rupiah(p.amount),
                          style: context.moneyStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.incomeOnDark,
                          ),
                        ),
                        IconButton(
                          tooltip: context.tr('Delete payment'),
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.freshSage,
                          ),
                          onPressed: () async {
                            final db = ref.read(databaseProvider);
                            await db.deleteDebtPayment(p.id);
                            showUndoSnackBar(
                              message: trG('Payment record deleted'),
                              onUndo: () => db.restoreDebtPayment(p.id),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
              TextButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: Text(context.tr('Delete')),
                onPressed: () async {
                  final id = liveDebt.id;
                  final db = ref.read(databaseProvider);
                  await db.deleteDebt(id);
                  if (context.mounted) Navigator.pop(context);
                  showUndoSnackBar(
                    message: trG('Debt deleted'),
                    onUndo: () => db.restoreDebt(id),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentDialog extends ConsumerStatefulWidget {
  const _PaymentDialog({
    required this.remaining,
    required this.lent,
    this.fixedFullPayment = false,
  });

  final int remaining;
  final bool lent;
  final bool fixedFullPayment;

  @override
  ConsumerState<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<_PaymentDialog> {
  late final TextEditingController _amount =
      TextEditingController(text: formatThousands(widget.remaining));
  bool _record = true;
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

    return AlertDialog(
      title: Text(
        context.tr(widget.fixedFullPayment ? 'Mark as fully paid' : 'Record payment'),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.fixedFullPayment) ...[
              Text(
                context.tr('Confirm full settlement of {amount}?', {
                  'amount': rupiah(widget.remaining),
                }),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ] else ...[
              TextField(
                controller: _amount,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: amountFormatters(),
                decoration: appInput(context, prefixText: 'Rp '),
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _record,
              onChanged: (v) => setState(() => _record = v),
              title: Text(context.tr(widget.lent
                  ? 'Also add as income'
                  : 'Also add as expense')),
            ),
            if (_record && wallets.isNotEmpty) ...[
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
            final v = widget.fixedFullPayment
                ? widget.remaining
                : parseAmount(_amount.text).clamp(0, widget.remaining).toInt();
            Navigator.pop(context, (v, _record, _walletId));
          },
          child: Text(
            context.tr(widget.fixedFullPayment ? 'Mark as paid' : 'Save'),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Form utang
// ---------------------------------------------------------------------------

Future<void> showDebtForm(
  BuildContext context, {
  DebtDirection initial = DebtDirection.lent,
  Debt? debt,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _DebtForm(initial: initial, debt: debt),
  );
}

class _DebtForm extends ConsumerStatefulWidget {
  const _DebtForm({required this.initial, this.debt});

  final DebtDirection initial;
  final Debt? debt;

  @override
  ConsumerState<_DebtForm> createState() => _DebtFormState();
}

class _DebtFormState extends ConsumerState<_DebtForm> {
  final _person = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late DebtDirection _direction;
  DateTime? _due;
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = widget.debt;
    _direction = d?.direction ?? widget.initial;
    if (d != null) {
      _person.text = d.person;
      _amount.text = formatThousands(d.amount);
      _note.text = d.note;
      _due = d.dueDate;
    }
  }

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> _save() async {
    final person = _person.text.trim();
    final amount = parseAmount(_amount.text);
    if (person.isEmpty || amount <= 0) {
      setState(() => _error = context.tr('Enter a name and an amount.'));
      return;
    }
    final db = ref.read(databaseProvider);
    final existing = widget.debt;
    if (existing == null) {
      await db.addDebt(
        person: person,
        direction: _direction,
        amount: amount,
        dueDate: _due,
        note: _note.text.trim(),
      );
    } else {
      await db.updateDebt(
        existing.id,
        person: person,
        direction: _direction,
        amount: amount,
        dueDate: _due,
        clearDueDate: _due == null,
        note: _note.text.trim(),
      );
    }
    checkDebtDueReminders(db);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.debt != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.tr(isEdit ? 'Edit debt' : 'Add debt'),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            SegmentedButton<DebtDirection>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                    value: DebtDirection.lent, label: Text(context.tr('Owed to me'))),
                ButtonSegment(
                    value: DebtDirection.borrowed, label: Text(context.tr('I owe'))),
              ],
              selected: {_direction},
              onSelectionChanged: (s) => setState(() => _direction = s.first),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _person,
              textCapitalization: TextCapitalization.words,
              decoration: appInput(context, label: context.tr('Person')),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: amountFormatters(),
              decoration: appInput(context, label: context.tr('Amount'), prefixText: 'Rp '),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(_due == null ? context.tr('Due date (optional)') : shortDate(_due!)),
              trailing: _due == null
                  ? const Icon(Icons.chevron_right)
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _due = null),
                    ),
              onTap: _pickDue,
            ),
            TextField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              decoration: appInput(context, label: context.tr('Note (optional)')),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: context.themeColors.expense)),
            ],
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: Text(context.tr('Save'))),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Patungan
// ---------------------------------------------------------------------------

Future<void> showSplitSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _SplitSheet(),
  );
}

class _SplitSheet extends ConsumerStatefulWidget {
  const _SplitSheet();

  @override
  ConsumerState<_SplitSheet> createState() => _SplitSheetState();
}

class _SplitSheetState extends ConsumerState<_SplitSheet> {
  final _total = TextEditingController();
  final _friends = TextEditingController();
  final _note = TextEditingController();
  final List<TextEditingController> _customControllers = [];
  bool _isCustomSplit = false;
  bool _recordMyShare = false;
  bool _deductFullBill = false;
  String? _categoryId;
  String? _walletId;
  String? _error;

  @override
  void dispose() {
    _total.dispose();
    _friends.dispose();
    _note.dispose();
    for (final c in _customControllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _names => _friends.text
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  void _syncCustomControllers({bool forcePrefill = false}) {
    final names = _names;
    final total = parseAmount(_total.text);
    final equalShare =
        (total > 0 && names.isNotEmpty) ? total ~/ (names.length + 1) : 0;

    while (_customControllers.length < names.length) {
      final ctrl = TextEditingController(
        text: equalShare > 0 ? formatThousands(equalShare) : '',
      );
      _customControllers.add(ctrl);
    }
    while (_customControllers.length > names.length) {
      _customControllers.removeLast().dispose();
    }
    if (forcePrefill) {
      for (final ctrl in _customControllers) {
        ctrl.text = equalShare > 0 ? formatThousands(equalShare) : '';
      }
    }
  }

  Future<void> _save() async {
    final total = parseAmount(_total.text);
    final names = _names;
    if (total <= 0 || names.isEmpty) {
      setState(() => _error = context.tr('Enter the total and at least one friend.'));
      return;
    }

    final List<int> amountsPerFriend;
    final int myShare;

    if (_isCustomSplit) {
      _syncCustomControllers();
      amountsPerFriend = [
        for (var i = 0; i < names.length; i++)
          parseAmount(_customControllers[i].text),
      ];
      final result = computeCustomSplit(
        total: total,
        friendAmounts: amountsPerFriend,
      );
      if (!result.isValid) {
        setState(() => _error = context.tr(result.errorKey!));
        return;
      }
      myShare = result.myShare;
    } else {
      final people = names.length + 1;
      final share = total ~/ people;
      amountsPerFriend = List<int>.filled(names.length, share);
      myShare = total - share * names.length; // sisa pembulatan jadi bagianku
    }

    if (_recordMyShare && _categoryId == null) {
      setState(() => _error = context.tr('Please choose a category.'));
      return;
    }
    final note = _note.text.trim().isEmpty ? trG('Split bill') : _note.text.trim();

    final db = ref.read(databaseProvider);
    for (var i = 0; i < names.length; i++) {
      await db.addDebt(
        person: names[i],
        direction: DebtDirection.lent,
        amount: amountsPerFriend[i],
        note: note,
      );
    }
    if (_recordMyShare) {
      final wallets = ref.read(walletsProvider).value ?? const <Wallet>[];
      final targetWalletId = _walletId ?? (wallets.isNotEmpty ? wallets.first.id : null);
      final expenseAmount = _deductFullBill ? total : myShare;
      if (expenseAmount > 0) {
        await db.addTransaction(
          amount: expenseAmount,
          type: TxType.expense,
          categoryId: _categoryId!,
          walletId: targetWalletId,
          date: DateTime.now(),
          note: note,
        );
      }
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final cats = ref.watch(categoriesProvider).maybeWhen(
          data: (l) => l.where((c) => c.type == TxType.expense).toList(),
          orElse: () => <Category>[],
        );
    final wallets = ref.watch(walletsProvider).value ?? const <Wallet>[];
    final effectiveWalletId = _walletId ?? (wallets.isNotEmpty ? wallets.first.id : null);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final total = parseAmount(_total.text);
    final names = _names;
    if (_isCustomSplit) {
      _syncCustomControllers();
    }
    final share = names.isEmpty ? 0 : total ~/ (names.length + 1);
    final customAmounts = _isCustomSplit
        ? [
            for (var i = 0; i < names.length; i++)
              parseAmount(_customControllers[i].text),
          ]
        : const <int>[];
    final customFriendsTotal = customAmounts.fold<int>(0, (s, a) => s + a);
    final customMyShare = total - customFriendsTotal;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.tr('Split a bill'),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              context.tr(
                _isCustomSplit
                    ? 'You paid the whole bill. Set each friend\'s custom share below.'
                    : 'You paid the whole bill. Each friend owes an equal share.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _total,
              keyboardType: TextInputType.number,
              inputFormatters: amountFormatters(),
              onChanged: (_) => setState(() {
                _error = null;
              }),
              decoration: appInput(context, label: context.tr('Total bill'), prefixText: 'Rp '),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _friends,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {
                if (_isCustomSplit) _syncCustomControllers();
                _error = null;
              }),
              decoration: appInput(
                context,
                label: context.tr("Friends' names"),
                helper: context.tr('Separate names with commas, e.g. Ayu, Budi, Citra'),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              decoration: appInput(context, label: context.tr('Note (optional)')),
            ),
            const SizedBox(height: 14),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(context.tr('Equal Split')),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(context.tr('Custom Split')),
                ),
              ],
              selected: {_isCustomSplit},
              onSelectionChanged: (s) {
                setState(() {
                  _isCustomSplit = s.first;
                  _error = null;
                  if (_isCustomSplit) {
                    _syncCustomControllers(forcePrefill: true);
                  }
                });
              },
            ),
            if (!_isCustomSplit && names.isNotEmpty && total > 0) ...[
              const SizedBox(height: 12),
              Text(
                context.tr('{n} people, {amount} each', {
                  'n': names.length + 1,
                  'amount': rupiah(share),
                }),
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
            if (_isCustomSplit && names.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (var i = 0; i < names.length; i++) ...[
                TextField(
                  controller: _customControllers[i],
                  keyboardType: TextInputType.number,
                  inputFormatters: amountFormatters(),
                  onChanged: (_) => setState(() => _error = null),
                  decoration: appInput(
                    context,
                    label: names[i],
                    prefixText: 'Rp ',
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (total > 0)
                Text(
                  context.tr("Friends: {friends} • Your share: {mine}", {
                    'friends': rupiah(customFriendsTotal),
                    'mine': rupiah(customMyShare),
                  }),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: customMyShare < 0
                        ? context.themeColors.expense
                        : AppColors.dewMint,
                  ),
                ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _recordMyShare,
              onChanged: (v) => setState(() => _recordMyShare = v),
              title: Text(context.tr('Record my share as an expense')),
            ),
            if (_recordMyShare) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppChip(
                    label: context.tr('My share only'),
                    selected: !_deductFullBill,
                    onSelected: () => setState(() => _deductFullBill = false),
                  ),
                  AppChip(
                    label: context.tr('Full bill paid by me'),
                    selected: _deductFullBill,
                    onSelected: () => setState(() => _deductFullBill = true),
                  ),
                ],
              ),
              if (wallets.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  context.tr('Payment Account'),
                  style: theme.textTheme.labelMedium?.copyWith(color: muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final w in wallets)
                      AppChip(
                        icon: iconFor(w.icon),
                        label: context.tr(w.name),
                        selected: effectiveWalletId == w.id,
                        onSelected: () => setState(() => _walletId = w.id),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Text(
                context.tr('Category'),
                style: theme.textTheme.labelMedium?.copyWith(color: muted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in cats)
                    AppChip(
                      icon: iconFor(c.icon),
                      label: context.tr(c.name),
                      selected: _categoryId == c.id,
                      onSelected: () => setState(() => _categoryId = c.id),
                    ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: context.themeColors.expense)),
            ],
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: Text(context.tr('Create debts'))),
          ],
        ),
      ),
    );
  }
}
