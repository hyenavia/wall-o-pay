/// Form bottom sheet untuk menambah atau mengubah transaksi ([TransactionForm]),
/// mendukung pemasukan, pengeluaran, dan transfer antar dompet, lengkap dengan template cepat,
/// kalkulator mini, lampiran foto struk, dan label Kebutuhan/Keinginan.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/calculator_sheet.dart';
import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_database.dart';
import '../../data/providers.dart';
import '../../data/prefs.dart';
import '../../data/feature_prefs.dart';
import '../../data/feature_providers.dart';
import '../../data/notifications.dart';
import '../../data/tables.dart' show NeedWant, TxType;

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

/// Widget form input/edit transaksi di dalam modal bottom sheet.
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
  late final TextEditingController _fee;
  String? _categoryId;
  String? _walletId;
  String? _toWalletId;
  late DateTime _date;
  String? _receiptPath;
  NeedWant? _needWant;
  String? _error;
  Map<String, int> _usage = const {};
  bool _showMoreDetails = false;
  bool _showAdminFee = false;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    final isEdit = e != null;
    final now = DateTime.now();
    final isNotToday = e != null && (e.date.year != now.year || e.date.month != now.month || e.date.day != now.day);
    final hasNote = (e?.note.isNotEmpty ?? false) || (widget.initialNote?.isNotEmpty ?? false);
    final hasReceipt = (e?.receiptPath != null) || (widget.initialReceiptPath != null);
    final hasNeedWant = e?.needWant != null;

    _showMoreDetails = isEdit && (isNotToday || hasNote || hasReceipt || hasNeedWant);
    _showAdminFee = false;
    _type = e?.type ?? widget.initialType ?? TxType.expense;
    _amount = TextEditingController(
      text: e != null
          ? formatThousands(e.amount)
          : (widget.initialAmount != null && widget.initialAmount! > 0
              ? formatThousands(widget.initialAmount!)
              : ''),
    );
    _note = TextEditingController(text: e?.note ?? widget.initialNote ?? '');
    _fee = TextEditingController();
    _categoryId = e?.categoryId;
    _walletId = e?.walletId ?? widget.initialWalletId;
    _toWalletId = e?.toWalletId;
    _date = e?.date ?? DateTime.now();
    _receiptPath = e?.receiptPath ?? widget.initialReceiptPath;
    _needWant = e?.needWant;

    ref.read(databaseProvider).categoryUsageCounts().then((u) {
      if (mounted) setState(() => _usage = u);
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _fee.dispose();
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

  Future<void> _openCalculator() async {
    final current = parseAmount(_amount.text);
    final result = await showCalculatorSheet(
      context,
      initialValue: current > 0 ? current : null,
    );
    if (result != null && result > 0) {
      setState(() {
        _amount.text = formatThousands(result);
        _error = null;
      });
    }
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


  void _applyTemplate(TxTemplate t) {
    setState(() {
      _type = t.type;
      _amount.text = formatThousands(t.amount);
      _note.text = t.note;
      _categoryId = t.categoryId;
      _walletId = t.walletId ?? _walletId;
      _needWant = t.needWant;
      if (t.note.isNotEmpty || t.needWant != null) {
        _showMoreDetails = true;
      }
      _error = null;
    });
  }

  Future<void> _saveAsTemplate() async {
    final amount = parseAmount(_amount.text);
    if (amount <= 0 || _categoryId == null) {
      setState(() => _error = context.tr('Fill in the amount and category first.'));
      return;
    }
    final controller = TextEditingController(
      text: _note.text.trim().isEmpty ? '' : _note.text.trim(),
    );
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('Save as template')),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: appInput(context, label: context.tr('Template name')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(context.tr('Save')),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(databaseProvider).addTemplate(
          name: name,
          type: _type,
          amount: amount,
          categoryId: _categoryId!,
          walletId: _walletId,
          needWant: _type == TxType.expense ? _needWant : null,
          note: _note.text.trim(),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Template saved.'))),
      );
    }
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
    final feeAmount = parseAmount(_fee.text);

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
        if (feeAmount > 0) {
          final toWalletName = (ref.read(walletsProvider).value ?? const [])
              .where((w) => w.id == _toWalletId)
              .firstOrNull
              ?.name ?? '';
          await db.addTransaction(
            amount: feeAmount,
            type: TxType.expense,
            categoryId: 'cat-exp-other',
            date: day,
            walletId: _walletId!,
            note: trG('Admin fee: transfer to {wallet}', {
              'wallet': toWalletName.isNotEmpty ? trG(toWalletName) : trG('Destination'),
            }),
          );
        }
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
        if (feeAmount > 0) {
          final toWalletName = (ref.read(walletsProvider).value ?? const [])
              .where((w) => w.id == _toWalletId)
              .firstOrNull
              ?.name ?? '';
          await db.addTransaction(
            amount: feeAmount,
            type: TxType.expense,
            categoryId: 'cat-exp-other',
            date: day,
            walletId: _walletId!,
            note: trG('Admin fee: transfer to {wallet}', {
              'wallet': toWalletName.isNotEmpty ? trG(toWalletName) : trG('Destination'),
            }),
          );
        }
      }
    } else {
      if (_categoryId == null) {
        setState(() => _error = context.tr('Please choose a category.'));
        return;
      }

      final activeWallets = ref.read(walletsProvider).value ?? const [];
      final defaultWalletId = activeWallets.isNotEmpty ? activeWallets.first.id : 'wallet-main';
      final actualWalletId = _walletId ?? defaultWalletId;

      if (e == null) {
        await db.addTransaction(
          amount: amount,
          type: _type,
          categoryId: _categoryId!,
          date: day,
          note: _note.text.trim(),
          walletId: actualWalletId,
          receiptPath: _receiptPath,
        );
        if (_type == TxType.expense && feeAmount > 0) {
          final cat = (ref.read(categoriesProvider).value ?? const [])
              .where((c) => c.id == _categoryId)
              .firstOrNull;
          final catName = cat?.name ?? 'Expense';
          final noteContext = _note.text.trim().isNotEmpty
              ? _note.text.trim()
              : trG(catName);
          await db.addTransaction(
            amount: feeAmount,
            type: TxType.expense,
            categoryId: 'cat-exp-other',
            date: day,
            walletId: actualWalletId,
            note: trG('Admin fee: {context}', {'context': noteContext}),
          );
        }
      } else {
        await db.updateTransaction(
          e.id,
          amount: amount,
          type: _type,
          categoryId: _categoryId!,
          date: day,
          note: _note.text.trim(),
          walletId: actualWalletId,
          receiptPath: _receiptPath,
          clearReceipt: _receiptPath == null,
        );
        if (_type == TxType.expense && feeAmount > 0) {
          final cat = (ref.read(categoriesProvider).value ?? const [])
              .where((c) => c.id == _categoryId)
              .firstOrNull;
          final catName = cat?.name ?? 'Expense';
          final noteContext = _note.text.trim().isNotEmpty
              ? _note.text.trim()
              : trG(catName);
          await db.addTransaction(
            amount: feeAmount,
            type: TxType.expense,
            categoryId: 'cat-exp-other',
            date: day,
            walletId: actualWalletId,
            note: trG('Admin fee: {context}', {'context': noteContext}),
          );
        }
      }
    }

    if (_type == TxType.expense && _categoryId != null && ref.read(featurePrefsProvider).budgetAlerts) {
      final cats = ref.read(categoriesProvider).maybeWhen(
            data: (list) => list,
            orElse: () => const <Category>[],
          );
      final cat = cats.where((c) => c.id == _categoryId).firstOrNull;
      await checkBudgetAfterExpense(
        db: db,
        prefs: ref.read(sharedPreferencesProvider),
        periodType: ref.read(appPrefsProvider).periodType,
        categoryId: _categoryId!,
        categoryName: cat?.name ?? 'Uncategorized',
        date: day,
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
    final id = widget.entry!.id;
    final db = ref.read(databaseProvider);
    await db.deleteTransaction(id);
    if (mounted) Navigator.pop(context);
    showUndoSnackBar(
      message: trG('Transaction deleted'),
      onUndo: () => db.restoreTransaction(id),
    );
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
    final templates = ref.watch(templatesProvider).maybeWhen(
          data: (list) => list,
          orElse: () => const <TxTemplate>[],
        );

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
            if (widget.entry == null && templates.isNotEmpty) ...[
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final t in templates)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: const Icon(Icons.flash_on, size: 16),
                          label: Text(t.name),
                          onPressed: () => _applyTemplate(t),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
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
              decoration: appInput(
                context,
                label: context.tr('Amount'),
                prefixText: 'Rp ',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calculate_outlined, color: AppColors.sage),
                  tooltip: context.tr('Calculator'),
                  onPressed: _openCalculator,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickAmountChip(
                    label: '+000',
                    onTap: () {
                      final cur = parseAmount(_amount.text);
                      if (cur == 0) {
                        _amount.text = '1.000';
                      } else if (cur <= 999999999) {
                        _amount.text = formatThousands(cur * 1000);
                      }
                      setState(() => _error = null);
                    },
                  ),
                  const SizedBox(width: 6),
                  _QuickAmountChip(
                    label: '+10rb',
                    onTap: () {
                      final cur = parseAmount(_amount.text);
                      _amount.text = formatThousands(cur + 10000);
                      setState(() => _error = null);
                    },
                  ),
                  const SizedBox(width: 6),
                  _QuickAmountChip(
                    label: '+50rb',
                    onTap: () {
                      final cur = parseAmount(_amount.text);
                      _amount.text = formatThousands(cur + 50000);
                      setState(() => _error = null);
                    },
                  ),
                  const SizedBox(width: 6),
                  _QuickAmountChip(
                    label: '+100rb',
                    onTap: () {
                      final cur = parseAmount(_amount.text);
                      _amount.text = formatThousands(cur + 100000);
                      setState(() => _error = null);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),


            // Core Selection: Transfer vs Income/Expense
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
                      selected: (_walletId ?? (wallets.isNotEmpty ? wallets.first.id : '')) == w.id,
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
                      selected: (_toWalletId ?? (wallets.length > 1 ? wallets[1].id : '')) == w.id,
                      onSelected: () => setState(() => _toWalletId = w.id),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (!_showAdminFee && parseAmount(_fee.text) == 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => setState(() => _showAdminFee = true),
                    icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.sage),
                    label: Text(context.tr('+ Add admin fee'), style: const TextStyle(color: AppColors.sage, fontSize: 13)),
                  ),
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.tr('Admin Fee (Optional)'), style: theme.textTheme.labelLarge),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () => setState(() {
                        _fee.clear();
                        _showAdminFee = false;
                      }),
                      child: Text(
                        parseAmount(_fee.text) > 0 ? context.tr('Free / Rp 0') : context.tr('Hide admin fee'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _fee,
                  keyboardType: TextInputType.number,
                  inputFormatters: amountFormatters(),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    hintText: '0 (${context.tr("Free (Rp 0)")})',
                    helperText: context.tr('Deducted from source wallet as an admin fee expense'),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final opt in [
                      (amount: 0, label: 'Free (Rp 0)'),
                      (amount: 1000, label: 'Rp 1.000'),
                      (amount: 2500, label: 'Rp 2.500'),
                      (amount: 6500, label: 'Rp 6.500'),
                    ])
                      ActionChip(
                        label: Text(context.tr(opt.label)),
                        avatar: (opt.amount == 0 && parseAmount(_fee.text) == 0) ||
                                (opt.amount > 0 && parseAmount(_fee.text) == opt.amount)
                            ? const Icon(Icons.check, size: 16)
                            : null,
                        onPressed: () {
                          setState(() {
                            if (opt.amount == 0) {
                              _fee.clear();
                            } else {
                              _fee.text = formatThousands(opt.amount);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ],
            ] else ...[
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
              const SizedBox(height: 16),
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
                      selected: (_walletId ?? (wallets.isNotEmpty ? wallets.first.id : '')) == w.id,
                      onSelected: () => setState(() => _walletId = w.id),
                    ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            InkWell(
              onTap: () => setState(() => _showMoreDetails = !_showMoreDetails),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _showMoreDetails
                        ? AppColors.deepForest.withValues(alpha: 0.4)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _showMoreDetails ? Icons.expand_less : Icons.tune_rounded,
                      size: 18,
                      color: AppColors.sage,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _showMoreDetails
                          ? context.tr('Hide extra details')
                          : context.tr('More details (Date, note, receipt...)'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.sage,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_showMoreDetails) ...[
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
              if (_type == TxType.expense) ...[
                const SizedBox(height: 16),
                Text(context.tr('Need or want?'), style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<NeedWant>(
                    emptySelectionAllowed: true,
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: NeedWant.need,
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: Text(context.tr('Need')),
                      ),
                      ButtonSegment(
                        value: NeedWant.want,
                        icon: const Icon(Icons.favorite_border, size: 16),
                        label: Text(context.tr('Want')),
                      ),
                    ],
                    selected: _needWant == null ? {} : {_needWant!},
                    onSelectionChanged: (s) => setState(() => _needWant = s.isEmpty ? null : s.first),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.tr('Admin Fee (Optional)'), style: theme.textTheme.labelLarge),
                    if (parseAmount(_fee.text) > 0)
                      TextButton(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () => setState(() => _fee.clear()),
                        child: Text(context.tr('Free / Rp 0'), style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _fee,
                  keyboardType: TextInputType.number,
                  inputFormatters: amountFormatters(),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    hintText: '0 (${context.tr("Free (Rp 0)")})',
                    helperText: context.tr('Recorded as an additional admin fee expense'),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final opt in [
                      (amount: 0, label: 'Free (Rp 0)'),
                      (amount: 1000, label: 'Rp 1.000'),
                      (amount: 2500, label: 'Rp 2.500'),
                      (amount: 5000, label: 'Rp 5.000'),
                    ])
                      ActionChip(
                        label: Text(context.tr(opt.label)),
                        avatar: (opt.amount == 0 && parseAmount(_fee.text) == 0) ||
                                (opt.amount > 0 && parseAmount(_fee.text) == opt.amount)
                            ? const Icon(Icons.check, size: 16)
                            : null,
                        onPressed: () {
                          setState(() {
                            if (opt.amount == 0) {
                              _fee.clear();
                            } else {
                              _fee.text = formatThousands(opt.amount);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ],
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
              if (!isEdit && _type != TxType.transfer) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _saveAsTemplate,
                  icon: const Icon(Icons.bolt, size: 18),
                  label: Text(context.tr('Save as template')),
                ),
              ],
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

class _QuickAmountChip extends StatelessWidget {
  const _QuickAmountChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.sage,
            ),
          ),
        ),
      ),
    );
  }
}
