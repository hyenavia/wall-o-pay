import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_database.dart';
import '../../data/feature_providers.dart';
import '../../data/providers.dart';
import '../../data/tables.dart' show DebtDirection, TxType;

class DebtsPage extends ConsumerStatefulWidget {
  const DebtsPage({super.key});

  @override
  ConsumerState<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends ConsumerState<DebtsPage> {
  DebtDirection _tab = DebtDirection.lent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final debtsAsync = ref.watch(debtsProvider);

    return Scaffold(
      appBar: pageAppBar(
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
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
                segments: [
                  ButtonSegment(
                      value: DebtDirection.lent, label: Text(context.tr('Owed to me'))),
                  ButtonSegment(
                      value: DebtDirection.borrowed, label: Text(context.tr('I owe'))),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('Debts are a separate ledger and do not change your account balances.'),
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: EmptyState(
                    icon: Icons.handshake_outlined,
                    message: context.tr('Nothing here yet.'),
                  ),
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
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);
    final left = debt.amount - debt.paidAmount;
    final done = left <= 0;
    final ratio = debt.amount == 0 ? 0.0 : debt.paidAmount / debt.amount;
    final overdue = !done &&
        debt.dueDate != null &&
        debt.dueDate!.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    return AppCard(
      onTap: () => showDebtDetail(context, debt),
      child: Opacity(
        opacity: done ? 0.55 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryBadge(
                  icon: done ? Icons.check : Icons.person_outline,
                  color: done ? AppColors.income : scheme.primary,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(debt.person,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      if (debt.note.isNotEmpty)
                        Text(debt.note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                    ],
                  ),
                ),
                Text(
                  done ? context.tr('Settled') : rupiah(left),
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AppProgressBar(value: ratio),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('{paid} of {total}', {
                      'paid': rupiah(debt.paidAmount),
                      'total': rupiah(debt.amount),
                    }),
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ),
                if (debt.dueDate != null)
                  Text(
                    context.tr('Due {date}', {'date': shortDate(debt.dueDate!)}),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: overdue ? AppColors.expense : muted,
                      fontWeight: overdue ? FontWeight.w700 : null,
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

  Future<void> _record(WidgetRef ref, int amount, bool alsoTransaction) async {
    final db = ref.read(databaseProvider);
    await db.addDebtPayment(debt.id, amount);
    if (alsoTransaction) {
      final lent = debt.direction == DebtDirection.lent;
      await db.addTransaction(
        amount: amount,
        type: lent ? TxType.income : TxType.expense,
        categoryId: lent ? 'cat-inc-other' : 'cat-exp-other',
        date: DateTime.now(),
        note: lent
            ? trG('Repayment from {person}', {'person': debt.person})
            : trG('Payment to {person}', {'person': debt.person}),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final left = debt.amount - debt.paidAmount;
    final lent = debt.direction == DebtDirection.lent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(debt.person,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            context.tr(lent ? 'They owe you' : 'You owe them'),
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 16),
          Text(rupiah(left > 0 ? left : 0),
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          Text(
            context.tr('{paid} of {total}',
                {'paid': rupiah(debt.paidAmount), 'total': rupiah(debt.amount)}),
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          if (debt.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(debt.note),
          ],
          const SizedBox(height: 20),
          if (left > 0) ...[
            FilledButton.icon(
              icon: const Icon(Icons.payments_outlined),
              label: Text(context.tr('Record payment')),
              onPressed: () async {
                final result = await showDialog<(int, bool)>(
                  context: context,
                  builder: (_) => _PaymentDialog(remaining: left, lent: lent),
                );
                if (result != null && result.$1 > 0) {
                  await _record(ref, result.$1, result.$2);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                await _record(ref, left, false);
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(context.tr('Mark as fully paid')),
            ),
          ],
          TextButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: Text(context.tr('Delete')),
            onPressed: () async {
              await ref.read(databaseProvider).deleteDebt(debt.id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.remaining, required this.lent});

  final int remaining;
  final bool lent;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late final TextEditingController _amount =
      TextEditingController(text: formatThousands(widget.remaining));
  bool _record = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('Record payment')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: amountFormatters(),
            decoration: appInput(context, prefixText: 'Rp '),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _record,
            onChanged: (v) => setState(() => _record = v),
            title: Text(context.tr(widget.lent
                ? 'Also add as income'
                : 'Also add as expense')),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          onPressed: () {
            final v = parseAmount(_amount.text).clamp(0, widget.remaining).toInt();
            Navigator.pop(context, (v, _record));
          },
          child: Text(context.tr('Save')),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Form utang
// ---------------------------------------------------------------------------

Future<void> showDebtForm(BuildContext context, {DebtDirection initial = DebtDirection.lent}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _DebtForm(initial: initial),
  );
}

class _DebtForm extends ConsumerStatefulWidget {
  const _DebtForm({required this.initial});

  final DebtDirection initial;

  @override
  ConsumerState<_DebtForm> createState() => _DebtFormState();
}

class _DebtFormState extends ConsumerState<_DebtForm> {
  final _person = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late DebtDirection _direction = widget.initial;
  DateTime? _due;
  String? _error;

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
    await ref.read(databaseProvider).addDebt(
          person: person,
          direction: _direction,
          amount: amount,
          dueDate: _due,
          note: _note.text.trim(),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.tr('Add debt'),
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
              Text(_error!, style: const TextStyle(color: AppColors.expense)),
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
  bool _recordMyShare = false;
  String? _categoryId;
  String? _error;

  @override
  void dispose() {
    _total.dispose();
    _friends.dispose();
    _note.dispose();
    super.dispose();
  }

  List<String> get _names => _friends.text
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<void> _save() async {
    final total = parseAmount(_total.text);
    final names = _names;
    if (total <= 0 || names.isEmpty) {
      setState(() => _error = context.tr('Enter the total and at least one friend.'));
      return;
    }
    if (_recordMyShare && _categoryId == null) {
      setState(() => _error = context.tr('Please choose a category.'));
      return;
    }
    final people = names.length + 1;
    final share = total ~/ people;
    final myShare = total - share * names.length; // sisa pembulatan jadi bagianku
    final note = _note.text.trim().isEmpty ? trG('Split bill') : _note.text.trim();

    final db = ref.read(databaseProvider);
    for (final n in names) {
      await db.addDebt(
        person: n,
        direction: DebtDirection.lent,
        amount: share,
        note: note,
      );
    }
    if (_recordMyShare) {
      await db.addTransaction(
        amount: myShare,
        type: TxType.expense,
        categoryId: _categoryId!,
        date: DateTime.now(),
        note: note,
      );
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final total = parseAmount(_total.text);
    final names = _names;
    final share = names.isEmpty ? 0 : total ~/ (names.length + 1);

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
              context.tr('You paid the whole bill. Each friend owes an equal share.'),
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _total,
              keyboardType: TextInputType.number,
              inputFormatters: amountFormatters(),
              onChanged: (_) => setState(() {}),
              decoration: appInput(context, label: context.tr('Total bill'), prefixText: 'Rp '),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _friends,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
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
            if (names.isNotEmpty && total > 0) ...[
              const SizedBox(height: 12),
              Text(
                context.tr('{n} people, {amount} each', {
                  'n': names.length + 1,
                  'amount': rupiah(share),
                }),
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _recordMyShare,
              onChanged: (v) => setState(() => _recordMyShare = v),
              title: Text(context.tr('Record my share as an expense')),
            ),
            if (_recordMyShare)
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
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.expense)),
            ],
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: Text(context.tr('Create debts'))),
          ],
        ),
      ),
    );
  }
}
