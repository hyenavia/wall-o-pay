/// Dialog pemilihan rentang waktu (periode ini, periode lalu, atau rentang tanggal kustom)
/// serta filter rekening untuk mengekspor dan membagikan laporan keuangan berformat PDF.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_database.dart' show Wallet;
import '../../data/export_service.dart';
import '../../data/providers.dart';
import '../../data/report_service.dart';
import 'settings_actions.dart';

/// Pilih rentang laporan (periode ini, periode lalu, atau kustom) dan filter akun, lalu bagikan PDF-nya.
Future<void> showReportDialog(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final period = container.read(selectedPeriodProvider);
  final db = container.read(databaseProvider);
  final wallets = container.read(walletsProvider).value ?? const <Wallet>[];

  DateTimeRange periodRange(DateTime start, DateTime end) => DateTimeRange(
        start: start,
        end: DateTime(end.year, end.month, end.day - 1),
      );

  final selection = await showModalBottomSheet<({String choice, String? walletId})>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      var chosenRange = 'current';
      String? selectedWalletId;

      return StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ctx.tr('PDF report'),
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                RadioGroup<String>(
                  groupValue: chosenRange,
                  onChanged: (v) {
                    if (v != null) setModalState(() => chosenRange = v);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        value: 'current',
                        contentPadding: EdgeInsets.zero,
                        title: Text(period.label()),
                        subtitle: Text(ctx.tr('Selected period')),
                      ),
                      RadioListTile<String>(
                        value: 'previous',
                        contentPadding: EdgeInsets.zero,
                        title: Text(period.shift(-1).label()),
                        subtitle: Text(ctx.tr('Previous period')),
                      ),
                      RadioListTile<String>(
                        value: 'custom',
                        contentPadding: EdgeInsets.zero,
                        title: Text(ctx.tr('Custom range...')),
                      ),
                    ],
                  ),
                ),
                if (wallets.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    ctx.tr('Filter by account'),
                    style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                          color: AppColors.freshSage,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedWalletId,
                    decoration: appInput(ctx, label: ctx.tr('Account / Wallet')),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(ctx.tr('All Accounts')),
                      ),
                      for (final w in wallets)
                        DropdownMenuItem<String?>(
                          value: w.id,
                          child: Text(ctx.tr(w.name)),
                        ),
                    ],
                    onChanged: (v) => setModalState(() => selectedWalletId = v),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(
                    ctx,
                    (choice: chosenRange, walletId: selectedWalletId),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: Text(ctx.tr('Export PDF')),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  if (selection == null || !context.mounted) return;

  DateTimeRange? range;
  if (selection.choice == 'current') {
    range = periodRange(period.start, period.end);
  } else if (selection.choice == 'previous') {
    final p = period.shift(-1);
    range = periodRange(p.start, p.end);
  } else {
    final now = DateTime.now();
    range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
  }
  if (range == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  try {
    await ReportService(db).shareReport(range, walletId: selection.walletId);
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(trG('Failed: {error}', {'error': e}))),
    );
  }
}

/// Dialog pemilihan rentang waktu serta filter rekening untuk mengekspor transaksi ke file CSV.
Future<void> showCsvExportDialog(BuildContext context, WidgetRef ref) async {
  final period = ref.read(selectedPeriodProvider);
  final wallets = ref.read(walletsProvider).value ?? const <Wallet>[];

  final selection =
      await showModalBottomSheet<({String scope, String? walletId})>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      var chosenScope = 'all';
      String? selectedWalletId;

      return StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ctx.tr('Export transactions (CSV)'),
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                RadioGroup<String>(
                  groupValue: chosenScope,
                  onChanged: (v) {
                    if (v != null) setModalState(() => chosenScope = v);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        value: 'all',
                        contentPadding: EdgeInsets.zero,
                        title: Text(ctx.tr('All transactions')),
                        subtitle:
                            Text(ctx.tr('Include your complete history')),
                      ),
                      RadioListTile<String>(
                        value: 'current',
                        contentPadding: EdgeInsets.zero,
                        title: Text(period.label()),
                        subtitle: Text(ctx.tr('Selected period')),
                      ),
                      RadioListTile<String>(
                        value: 'custom',
                        contentPadding: EdgeInsets.zero,
                        title: Text(ctx.tr('Custom range...')),
                      ),
                    ],
                  ),
                ),
                if (wallets.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedWalletId,
                    decoration:
                        appInput(ctx, label: ctx.tr('Account / Wallet')),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(ctx.tr('All Accounts')),
                      ),
                      for (final w in wallets)
                        DropdownMenuItem<String?>(
                          value: w.id,
                          child: Text(ctx.tr(w.name)),
                        ),
                    ],
                    onChanged: (v) =>
                        setModalState(() => selectedWalletId = v),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(
                    ctx,
                    (scope: chosenScope, walletId: selectedWalletId),
                  ),
                  icon: const Icon(Icons.table_view_outlined, size: 18),
                  label: Text(ctx.tr('Export CSV')),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  if (selection == null || !context.mounted) return;

  DateTimeRange? range;
  if (selection.scope == 'current') {
    range = DateTimeRange(
      start: period.start,
      end: DateTime(period.end.year, period.end.month, period.end.day - 1),
    );
  } else if (selection.scope == 'custom') {
    final now = DateTime.now();
    range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (range == null || !context.mounted) return;
  }

  await SettingsActions.runAction(context, () async {
    final count = await ExportService(ref.read(databaseProvider)).shareCsv(
      range: range,
      walletId: selection.walletId,
    );
    return count == 0
        ? trG('CSV file exported (0 matching transactions).')
        : trG('CSV file ready to share ({count} transactions).', {
            'count': count,
          });
  });
}
