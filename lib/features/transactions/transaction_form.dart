import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
  int? initialAmount,
  String? initialNote,
  String? initialReceiptPath,
  String? initialWalletId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => TransactionForm(
      entry: entry,
      initialType: initialType,
      initialAmount: initialAmount,
      initialNote: initialNote,
      initialReceiptPath: initialReceiptPath,
      initialWalletId: initialWalletId,
    ),
  );
}

class TransactionForm extends ConsumerStatefulWidget {
  const TransactionForm({
    super.key,
    this.entry,
    this.initialType,
    this.initialAmount,
    this.initialNote,
    this.initialReceiptPath,
    this.initialWalletId,
  });

  final TransactionEntry? entry;
  final TxType? initialType;
  final int? initialAmount;
  final String? initialNote;
  final String? initialReceiptPath;
  final String? initialWalletId;

  @override
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<TransactionForm> {
  late TxType _type;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  String? _categoryId;
  String? _walletId;
  String? _toWalletId;
  late DateTime _date;
  String? _receiptPath;
  String? _error;
  Map<String, int> _usage = const {};

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _type = e?.type ?? widget.initialType ?? TxType.expense;
    _amount = TextEditingController(
      text: e != null
          ? formatThousands(e.amount)
          : (widget.initialAmount != null && widget.initialAmount! > 0
              ? formatThousands(widget.initialAmount!)
              : ''),
    );
    _note = TextEditingController(text: e?.note ?? widget.initialNote ?? '');
    _categoryId = e?.categoryId;
    _walletId = e?.walletId ?? widget.initialWalletId ?? 'wallet-main';
    _toWalletId = e?.toWalletId ?? 'wallet-digital';
    _date = e?.date ?? DateTime.now();
    _receiptPath = e?.receiptPath ?? widget.initialReceiptPath;

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

  Future<void> _pickReceipt(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _receiptPath = picked.path);
      }
    } catch (e) {
      debugPrint('Error picking receipt image: $e');
    }
  }

  void _showReceiptPreview(BuildContext context, String path) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            IconButton.filled(
              icon: const Icon(Icons.close, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final amount = parseAmount(_amount.text);
    if (amount <= 0) {
      setState(() => _error = context.tr('Amount must be greater than 0.'));
      return;
    }

    final db = ref.read(databaseProvider);
    final day = DateTime(_date.year, _date.month, _date.day);
    final e = widget.entry;

    if (_type == TxType.transfer) {
      if (_walletId == null || _toWalletId == null) {
        setState(() => _error = context.tr('Please choose source and destination wallets.'));
        return;
      }
      if (_walletId == _toWalletId) {
        setState(() => _error = context.tr('Source and destination wallets must be different.'));
        return;
      }

      if (e == null) {
        await db.transferBetweenWallets(
          amount: amount,
          fromWalletId: _walletId!,
          toWalletId: _toWalletId!,
          date: day,
          note: _note.text.trim(),
          receiptPath: _receiptPath,
        );
      } else {
        await db.updateTransaction(
          e.id,
          amount: amount,
          type: TxType.transfer,
          categoryId: 'cat-tra-transfer',
          date: day,
          note: _note.text.trim(),
          walletId: _walletId,
          toWalletId: _toWalletId,
          receiptPath: _receiptPath,
          clearReceipt: _receiptPath == null,
        );
      }
    } else {
      if (_categoryId == null) {
        setState(() => _error = context.tr('Please choose a category.'));
        return;
      }

      if (e == null) {
        await db.addTransaction(
          amount: amount,
          type: _type,
          categoryId: _categoryId!,
          date: day,
          note: _note.text.trim(),
          walletId: _walletId ?? 'wallet-main',
          receiptPath: _receiptPath,
        );
      } else {
        await db.updateTransaction(
          e.id,
          amount: amount,
          type: _type,
          categoryId: _categoryId!,
          date: day,
          note: _note.text.trim(),
          walletId: _walletId ?? 'wallet-main',
          receiptPath: _receiptPath,
          clearReceipt: _receiptPath == null,
        );
      }
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
    final scheme = theme.colorScheme;
    final wallets = ref.watch(walletsProvider).maybeWhen(
          data: (list) => list,
          orElse: () => const <Wallet>[],
        );
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
                ButtonSegment(
                  value: TxType.expense,
                  label: Text(context.tr('Expense')),
                ),
                ButtonSegment(
                  value: TxType.income,
                  label: Text(context.tr('Income')),
                ),
                ButtonSegment(
                  value: TxType.transfer,
                  label: Text(context.tr('Transfer')),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _categoryId = null;
                _error = null;
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

            // Pilihan Dompet (Wallet Selection)
            if (_type == TxType.transfer) ...[
              Text(context.tr('From Wallet / Account'), style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final w in wallets)
                    AppChip(
                      icon: iconFor(w.icon),
                      label: context.tr(w.name),
                      selected: _walletId == w.id,
                      onSelected: () => setState(() => _walletId = w.id),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(context.tr('To Wallet / Account'), style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final w in wallets)
                    AppChip(
                      icon: iconFor(w.icon),
                      label: context.tr(w.name),
                      selected: _toWalletId == w.id,
                      onSelected: () => setState(() => _toWalletId = w.id),
                    ),
                ],
              ),
            ] else ...[
              Text(
                _type == TxType.expense
                    ? context.tr('Pay from (Wallet / Account)')
                    : context.tr('Deposit to (Wallet / Account)'),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final w in wallets)
                    AppChip(
                      icon: iconFor(w.icon),
                      label: context.tr(w.name),
                      selected: (_walletId ?? 'wallet-main') == w.id,
                      onSelected: () => setState(() => _walletId = w.id),
                    ),
                ],
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
            ],

            const SizedBox(height: 14),
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
            const SizedBox(height: 16),

            // Lampiran Struk / Receipt Attachment
            Text(context.tr('Receipt / Struk (Optional)'), style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            if (_receiptPath != null && File(_receiptPath!).existsSync()) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.deepForest.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showReceiptPreview(context, _receiptPath!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(_receiptPath!),
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Receipt Attached'),
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          GestureDetector(
                            onTap: () => _showReceiptPreview(context, _receiptPath!),
                            child: Text(
                              context.tr('Tap to preview'),
                              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.deepForest),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                      tooltip: context.tr('Remove receipt'),
                      onPressed: () => setState(() => _receiptPath = null),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _pickReceipt(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined, size: 20),
                      label: Text(context.tr('Camera')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _pickReceipt(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 20),
                      label: Text(context.tr('Gallery')),
                    ),
                  ),
                ],
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.expense)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: _type == TxType.transfer
                    ? const Color(0xFF00897B)
                    : (_type == TxType.income ? AppColors.income : AppColors.expense),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _type == TxType.transfer
                    ? context.tr('Transfer Funds')
                    : context.tr('Save'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
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
