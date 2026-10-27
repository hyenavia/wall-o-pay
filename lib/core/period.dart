import 'package:intl/intl.dart';

import 'l10n.dart';

enum PeriodType { monthly, weekly }

int _daysBetween(DateTime a, DateTime b) => DateTime.utc(b.year, b.month, b.day)
    .difference(DateTime.utc(a.year, a.month, a.day))
    .inDays;

String _two(int n) => n.toString().padLeft(2, '0');

/// Satu periode pengelolaan keuangan: satu bulan kalender atau satu minggu
/// (Senin sampai Minggu).
class Period {
  const Period(this.type, this.start);

  final PeriodType type;
  final DateTime start;

  factory Period.containing(PeriodType type, DateTime d) {
    if (type == PeriodType.monthly) return Period(type, DateTime(d.year, d.month));
    return Period(type, DateTime(d.year, d.month, d.day - (d.weekday - 1)));
  }

  /// Batas akhir (tidak termasuk).
  DateTime get end => type == PeriodType.monthly
      ? DateTime(start.year, start.month + 1)
      : DateTime(start.year, start.month, start.day + 7);

  Period shift(int n) => type == PeriodType.monthly
      ? Period(type, DateTime(start.year, start.month + n))
      : Period(type, DateTime(start.year, start.month, start.day + 7 * n));

  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);

  bool get isCurrent => contains(DateTime.now());

  /// Sisa hari termasuk hari ini (bermakna untuk periode yang sedang berjalan).
  int get daysLeft => _daysBetween(DateTime.now(), end);

  /// Kunci untuk menyimpan anggaran: 2026-10 (bulanan) atau W2026-10-26 (mingguan).
  String get key => type == PeriodType.monthly
      ? '${start.year}-${_two(start.month)}'
      : 'W${start.year}-${_two(start.month)}-${_two(start.day)}';

  String label() {
    final loc = AppLocale.code;
    if (type == PeriodType.monthly) {
      return DateFormat('MMMM yyyy', loc).format(start);
    }
    final last = DateTime(end.year, end.month, end.day - 1);
    final from = start.year == last.year
        ? DateFormat('d MMM', loc).format(start)
        : DateFormat('d MMM yyyy', loc).format(start);
    return '$from – ${DateFormat('d MMM yyyy', loc).format(last)}';
  }

  String shortLabel() => type == PeriodType.monthly
      ? DateFormat('MMM', AppLocale.code).format(start)
      : DateFormat('d MMM', AppLocale.code).format(start);
}
