import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/app_database.dart';
import '../../data/auto_tracker.dart';
import '../../data/providers.dart';
import '../../data/tables.dart';

/// BottomSheet interaktif untuk mengonfirmasi atau mengedit transaksi yang ditangkap dari notifikasi.
class PendingReviewSheet extends ConsumerStatefulWidget {
  const PendingReviewSheet({
    super.key,
    required this.pending,
  });

  final PendingTransaction pending;

  static Future<void> show(BuildContext context, PendingTransaction pending) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PendingReviewSheet(pending: pending),
    );
  }

  @override
  ConsumerState<PendingReviewSheet> createState() => _PendingReviewSheetState();
}

class _PendingReviewSheetState extends ConsumerState<PendingReviewSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late TxType _type;
  late DateTime _date;
  String? _selectedCategoryId;
  String? _walletId;
  bool _showRawText = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.pending.amount.toString());
    _noteController = TextEditingController(text: widget.pending.note);
    _type = widget.pending.type;
    _date = widget.pending.date;
    _selectedCategoryId = widget.pending.suggestedCategory;
    _walletId = AutoTrackerService.suggestWalletId(widget.pending.sourceApp);
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

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  Future<void> _onConfirm(List<Category> categories) async {
    final amount = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please enter a valid amount'))),
      );
      return;
    }

    // Pastikan kategori terpilih valid untuk tipe saat ini
    final validCatId = _selectedCategoryId ??
        categories
            .where((c) => c.type == _type && c.deletedAt == null)
            .firstOrNull
            ?.id ??
        (_type == TxType.expense ? 'cat-exp-other' : 'cat-inc-other');

    setState(() => _saving = true);

    try {
      final tracker = ref.read(autoTrackerServiceProvider);
      await tracker.confirmPending(
        pending: widget.pending,
        categoryId: validCatId,
        amount: amount,
        type: _type,
        note: _noteController.text.trim(),
        date: _date,
        walletId: _walletId,
        receiptPath: widget.pending.receiptPath,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.income,
            content: Text(context.tr('Transaction confirmed and saved!')),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Error: {error}', {'error': e}))),
        );
      }
    }
  }

  Future<void> _onDiscard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('Discard Transaction?')),
        content: Text(ctx.tr('This detected transaction will be removed from your pending inbox without affecting your balance.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr('Discard')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final tracker = ref.read(autoTrackerServiceProvider);
      await tracker.dismissPending(widget.pending.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Transaction discarded.'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final catsAsync = ref.watch(categoriesProvider);
    final wallets = ref.watch(walletsProvider).maybeWhen(
          data: (w) => w,
          orElse: () => const <Wallet>[],
        );

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: catsAsync.when(
        loading: () => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (categories) {
          final matchingCats = categories
              .where((c) => c.type == _type && c.deletedAt == null)
              .toList();

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Header with Source Badge
                Row(
                  children: [
                    Builder(builder: (context) {
                      final isRecur = widget.pending.sourceApp.toLowerCase() == 'recurring';
                      final isReceipt = widget.pending.sourceApp.toLowerCase().contains('receipt') || widget.pending.sourceApp.toLowerCase().contains('struk');
                      final badgeIcon = isRecur
                          ? Icons.repeat
                          : (isReceipt ? Icons.receipt_long : Icons.notifications_active_outlined);
                      final badgeLabel = isRecur
                          ? context.tr('Scheduled Recurring')
                          : (isReceipt ? context.tr('Shared Receipt') : widget.pending.sourceApp);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.sage.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(badgeIcon, size: 16, color: AppColors.deepForest),
                            const SizedBox(width: 5),
                            Text(
                              badgeLabel,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.deepForest,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Text(
                  context.tr('Confirm Transaction'),
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  context.tr('Review details before recording into your balance.'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 16),

                // Raw Notification Snippet (Expandable)
                InkWell(
                  onTap: () => setState(() => _showRawText = !_showRawText),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 14, color: scheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              context.tr('Original Notification'),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              _showRawText ? Icons.expand_less : Icons.expand_more,
                              size: 18,
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.pending.rawNotification,
                          maxLines: _showRawText ? null : 2,
                          overflow: _showRawText ? TextOverflow.visible : TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: scheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Type Toggle (Expense vs Income)
                SegmentedButton<TxType>(
                  segments: [
                    ButtonSegment(
                      value: TxType.expense,
                      label: Text(context.tr('Expense')),
                      icon: const Icon(Icons.arrow_downward, color: AppColors.expense),
                    ),
                    ButtonSegment(
                      value: TxType.income,
                      label: Text(context.tr('Income')),
                      icon: const Icon(Icons.arrow_upward, color: AppColors.income),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (set) {
                    setState(() {
                      _type = set.first;
                      _selectedCategoryId = null; // reset to allow matching type
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Amount Input
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _type == TxType.expense ? AppColors.expense : AppColors.income,
                  ),
                  decoration: InputDecoration(
                    labelText: context.tr('Amount (Rp)'),
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),

                // Receipt Attachment Preview (if any)
                if (widget.pending.receiptPath != null && File(widget.pending.receiptPath!).existsSync()) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.deepForest.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showReceiptPreview(context, widget.pending.receiptPath!),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(widget.pending.receiptPath!),
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
                                onTap: () => _showReceiptPreview(context, widget.pending.receiptPath!),
                                child: Text(
                                  context.tr('Tap to preview'),
                                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.deepForest),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Wallet Dropdown
                if (wallets.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    initialValue: wallets.any((w) => w.id == _walletId) ? _walletId : wallets.firstOrNull?.id,
                    decoration: InputDecoration(
                      labelText: _type == TxType.expense
                          ? context.tr('Pay from (Wallet / Account)')
                          : context.tr('Deposit to (Wallet / Account)'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                    ),
                    items: [
                      for (final w in wallets)
                        DropdownMenuItem(
                          value: w.id,
                          child: Text(context.tr(w.name)),
                        ),
                    ],
                    onChanged: (id) => setState(() => _walletId = id),
                  ),
                  const SizedBox(height: 14),
                ],

                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: matchingCats.any((c) => c.id == _selectedCategoryId)
                      ? _selectedCategoryId
                      : matchingCats.firstOrNull?.id,
                  decoration: InputDecoration(
                    labelText: context.tr('Category'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                  items: [
                    for (final c in matchingCats)
                      DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      ),
                  ],
                  onChanged: (id) => setState(() => _selectedCategoryId = id),
                ),
                const SizedBox(height: 14),

                // Note & Date row
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: context.tr('Note / Merchant'),
                    hintText: context.tr('e.g. Kopi Kenangan, Grab, Alfamart'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    prefixIcon: const Icon(Icons.edit_note_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                // Date Picker row
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('EEEE, d MMM yyyy, HH:mm', AppLocale.code).format(_date),
                          style: theme.textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        Text(
                          context.tr('Change'),
                          style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Actions: Confirm & Discard
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.expense,
                          side: const BorderSide(color: AppColors.expense),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(context.tr('Discard')),
                        onPressed: _saving ? null : _onDiscard,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.deepForest,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          _saving ? context.tr('Saving...') : context.tr('Confirm & Save'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: _saving ? null : () => _onConfirm(categories),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
}
