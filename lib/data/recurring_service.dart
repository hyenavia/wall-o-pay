import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import 'app_database.dart';
import 'providers.dart';
import 'tables.dart';

final recurringRulesProvider = StreamProvider<List<RecurringRule>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchRecurringRules();
});

class RecurringService {
  RecurringService._();

  /// Menghitung tanggal jatuh tempo berikutnya berdasarkan frekuensi.
  static DateTime calculateNextDueDate(
    RecurFrequency frequency,
    DateTime fromDate, {
    int? dayOfWeek,
    int? dayOfMonth,
  }) {
    final now = DateTime.now();
    DateTime base = fromDate.isBefore(now) ? now : fromDate;

    switch (frequency) {
      case RecurFrequency.daily:
        return DateTime(base.year, base.month, base.day + 1);

      case RecurFrequency.weekly:
        var next = DateTime(base.year, base.month, base.day + 1);
        if (dayOfWeek != null && dayOfWeek >= 1 && dayOfWeek <= 7) {
          while (next.weekday != dayOfWeek) {
            next = next.add(const Duration(days: 1));
          }
        } else {
          next = base.add(const Duration(days: 7));
        }
        return DateTime(next.year, next.month, next.day);

      case RecurFrequency.monthly:
        int targetDay = dayOfMonth ?? base.day;
        int nextMonth = base.month + 1;
        int nextYear = base.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }
        // Handle tanggal akhir bulan (misal tgl 31 di bulan Februari)
        final daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        final validDay = targetDay > daysInNextMonth ? daysInNextMonth : targetDay;
        return DateTime(nextYear, nextMonth, validDay);
    }
  }

  /// Memeriksa seluruh aturan transaksi berulang yang telah jatuh tempo,
  /// lalu menambahkannya ke antrean transaksi tertunda (Pending Transactions)
  /// agar pengguna dapat meninjau dan mengonfirmasi terlebih dahulu sebelum dicatat resmi.
  static Future<int> checkAndGenerateDue(AppDatabase db) async {
    try {
      final now = DateTime.now();
      final dueRules = await db.getDueRecurringRules(now);
      var generatedCount = 0;

      for (final rule in dueRules) {
        // Masukkan ke inbox konfirmasi (PendingTransactions)
        await db.insertPendingTransaction(
          PendingTransactionsCompanion.insert(
            amount: rule.amount,
            type: rule.type,
            sourceApp: 'recurring',
            rawNotification: 'Transaksi Terjadwal: ${rule.title}',
            suggestedCategory: Value(rule.categoryId),
            note: Value(rule.note.isNotEmpty ? rule.note : rule.title),
            date: DateTime(now.year, now.month, now.day),
          ),
        );

        // Perbarui tanggal jatuh tempo berikutnya
        final nextDue = calculateNextDueDate(
          rule.frequency,
          rule.nextDueDate,
          dayOfWeek: rule.dayOfWeek,
          dayOfMonth: rule.dayOfMonth,
        );

        await db.updateRecurringNextDueDate(rule.id, nextDue, now);
        generatedCount++;
      }

      if (generatedCount > 0) {
        debugPrint('[RecurringService] Generated $generatedCount pending recurring transactions.');
      }
      return generatedCount;
    } catch (e) {
      debugPrint('[RecurringService] Error checking due recurring rules: $e');
      return 0;
    }
  }
}
