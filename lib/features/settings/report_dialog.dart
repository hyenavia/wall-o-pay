import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../data/providers.dart';
import '../../data/report_service.dart';

/// Pilih rentang laporan (periode ini, periode lalu, atau kustom), lalu bagikan PDF-nya.
Future<void> showReportDialog(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final period = container.read(selectedPeriodProvider);
  final db = container.read(databaseProvider);

  DateTimeRange periodRange(DateTime start, DateTime end) => DateTimeRange(
        start: start,
        end: DateTime(end.year, end.month, end.day - 1),
      );

  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: Text(period.label()),
            subtitle: Text(context.tr('Selected period')),
            onTap: () => Navigator.pop(ctx, 'current'),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(period.shift(-1).label()),
            subtitle: Text(context.tr('Previous period')),
            onTap: () => Navigator.pop(ctx, 'previous'),
          ),
          ListTile(
            leading: const Icon(Icons.date_range),
            title: Text(context.tr('Custom range...')),
            onTap: () => Navigator.pop(ctx, 'custom'),
          ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;

  DateTimeRange? range;
  if (choice == 'current') {
    range = periodRange(period.start, period.end);
  } else if (choice == 'previous') {
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
    await ReportService(db).shareReport(range);
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(trG('Failed: {error}', {'error': e}))),
    );
  }
}
