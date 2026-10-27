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

/// Buka form tambah transaksi, atau ubah jika [entry] diisi.
Future<void> showTransactionForm(
  BuildContext context, {
  TransactionEntry? entry,
  TxType? initialType,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => TransactionForm(entry: entry, initialType: initialType),
  );
}

class TransactionForm extends ConsumerStatefulWidget {
  const TransactionForm({super.key, this.entry, this.initialType});

  final TransactionEntry? entry;
  final TxType? initialType;

  @override
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<TransactionForm> {
  late TxType _type;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  String? _categoryId;
  late DateTime _date;
  String? _error;
  Map<String, int> _usage = const {};

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _type = e?.type ?? widget.initialType ?? TxType.expense;
    _amount = TextEditingController(text: e == null ? '' : formatThousands(e.amount));
    _note = TextEditingController(text: e?.note ?? '');
    _categoryId = e?.categoryId;
    _date = e?.date ?? DateTime.now();
    ref.read(databaseProvider).categoryUsageCounts().then((u) {
      if (mounted) setState(() => _usage = u);
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = parseAmount(_amount.text);
    if (amount <= 0) {
      setState(() => _error = context.tr('Amount must be greater than 0.'));
      return;
    }
    if (_categoryId == null) {
      setState(() => _error = context.tr('Please choose a category.'));
      return;
    }
    final db = ref.read(databaseProvider);
    final day = DateTime(_date.year, _date.month, _date.day);
    final e = widget.entry;
    if (e == null) {
      await db.addTransaction(
        amount: amount,
        type: _type,
        categoryId: _categoryId!,
        date: day,
        note: _note.text.trim(),
      );
    } else {
      await db.updateTransaction(
        e.id,
        amount: amount,
        type: _type,
        categoryId: _categoryId!,
        date: day,
        note: _note.text.trim(),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('Delete this transaction?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('Delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(databaseProvider).deleteTransaction(widget.entry!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cats = ref.watch(categoriesProvider).maybeWhen(
          data: (list) => list.where((c) => c.type == _type).toList(),
          orElse: () => <Category>[],
        )
      ..sort((a, b) {
        final byUsage = (_usage[b.id] ?? 0).compareTo(_usage[a.id] ?? 0);
        return byUsage != 0 ? byUsage : a.name.compareTo(b.name);
      });
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.entry != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr(isEdit ? 'Edit transaction' : 'Add transaction'),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            SegmentedButton<TxType>(
              segments: [
                ButtonSegment(value: TxType.expense, label: Text(context.tr('Expense'))),
                ButtonSegment(value: TxType.income, label: Text(context.tr('Income'))),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _categoryId = null;
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: amountFormatters(),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              decoration: appInput(context, label: context.tr('Amount'), prefixText: 'Rp '),
            ),
            const SizedBox(height: 16),
            Text(context.tr('Category'), style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
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
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(dateLabel(_date)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
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
            if (isEdit)
              TextButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
                label: Text(context.tr('Delete transaction')),
              ),
          ],
        ),
      ),
    );
  }
}
