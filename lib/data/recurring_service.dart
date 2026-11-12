/// Layanan perhitungan tanggal jatuh tempo dan pencatatan otomatis untuk jadwal transaksi berulang.
library;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/period.dart';
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
    DateTime? referenceNow,
  }) {
    final now = referenceNow ?? DateTime.now();
    final DateTime base = fromDate.isBefore(now) ? now : fromDate;

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
        final int targetDay = dayOfMonth ?? base.day;
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
  /// lalu menambahkannya ke antrean transaksi tertunda (`PendingTransactions`)
  /// agar pengguna dapat meninjau dan mengonfirmasi sebelum dicatat ke buku kas resmi.
  static Future<int> checkAndGenerateDue(AppDatabase db, {DateTime? now}) async {
    try {
      final refNow = now ?? DateTime.now();
      final dueRules = await db.getDueRecurringRules(refNow);
      var generatedCount = 0;

      for (final rule in dueRules) {
        if (rule.amount <= 0) continue;
        final nextDue = calculateNextDueDate(
          rule.frequency,
          rule.nextDueDate,
          dayOfWeek: rule.dayOfWeek,
          dayOfMonth: rule.dayOfMonth,
          referenceNow: refNow,
        );

        await db.transaction(() async {
          await db.into(db.pendingTransactions).insert(
                PendingTransactionsCompanion.insert(
                  recurringRuleId: Value(rule.id),
                  title: rule.title,
                  amount: rule.amount,
                  type: rule.type,
                  categoryId: rule.type == TxType.transfer
                      ? 'cat-tra-transfer'
                      : rule.categoryId,
                  walletId: Value(rule.walletId ?? 'wallet-main'),
                  toWalletId: Value(
                    rule.type == TxType.transfer ? rule.toWalletId : null,
                  ),
                  dueDate: DateTime(
                    rule.nextDueDate.year,
                    rule.nextDueDate.month,
                    rule.nextDueDate.day,
                  ),
                  note: Value(rule.note),
                ),
              );

          await (db.update(db.recurringRules)
                ..where((r) => r.id.equals(rule.id)))
              .write(
            RecurringRulesCompanion(
              nextDueDate: Value(nextDue),
              lastGeneratedDate: Value(refNow),
              updatedAt: Value(refNow),
            ),
          );
        });
        generatedCount++;
      }

      if (generatedCount > 0) {
        debugPrint('[RecurringService] Queued $generatedCount pending recurring transactions.');
      }
      return generatedCount;
    } catch (e) {
      debugPrint('[RecurringService] Error checking due recurring rules: $e');
      return 0;
    }
  }

  /// Mencatat transaksi secara langsung saat ini atas permintaan pengguna ("Record Now")
  /// dan memajukan `nextDueDate` ke siklus berikutnya.
  static Future<DateTime> recordRuleNow(
    AppDatabase db,
    RecurringRule rule, {
    DateTime? now,
  }) async {
    final refNow = now ?? DateTime.now();
    final nextDue = calculateNextDueDate(
      rule.frequency,
      rule.nextDueDate,
      dayOfWeek: rule.dayOfWeek,
      dayOfMonth: rule.dayOfMonth,
      referenceNow: refNow,
    );

    await db.transaction(() async {
      await db.addTransaction(
        amount: rule.amount,
        type: rule.type,
        categoryId:
            rule.type == TxType.transfer ? 'cat-tra-transfer' : rule.categoryId,
        walletId: rule.walletId,
        toWalletId: rule.type == TxType.transfer ? rule.toWalletId : null,
        note: rule.note.isNotEmpty ? rule.note : rule.title,
        date: DateTime(refNow.year, refNow.month, refNow.day),
      );
      await db.updateRecurringNextDueDate(rule.id, nextDue, refNow);
    });
    return nextDue;
  }

  /// Melewati satu jadwal jatuh tempo berikutnya tanpa mencatat transaksi ("Skip Next Due").
  static Future<DateTime> skipNextDueDate(
    AppDatabase db,
    RecurringRule rule, {
    DateTime? now,
  }) async {
    final refNow = now ?? DateTime.now();
    final nextDue = calculateNextDueDate(
      rule.frequency,
      rule.nextDueDate,
      dayOfWeek: rule.dayOfWeek,
      dayOfMonth: rule.dayOfMonth,
      referenceNow: refNow,
    );
    await db.updateRecurringNextDueDate(
      rule.id,
      nextDue,
      rule.lastGeneratedDate ?? refNow,
    );
    return nextDue;
  }

  /// Menghitung total pengeluaran berulang aktif (plus tagihan tertunda yang belum dikonfirmasi)
  /// yang dijadwalkan jatuh tempo dari hari ini hingga akhir [period] (tidak termasuk `period.end`).
  static int calculateUpcomingExpense(
    List<RecurringRule> rules,
    Period period, {
    List<PendingTransaction> pending = const [],
    DateTime? now,
  }) {
    final refNow = now ?? DateTime.now();
    if (!period.contains(refNow)) return 0;
    final todayStart = DateTime(refNow.year, refNow.month, refNow.day);
    var total = 0;

    for (final p in pending) {
      if (p.deletedAt != null || p.type != TxType.expense || p.amount <= 0) {
        continue;
      }
      final dueDay = DateTime(p.dueDate.year, p.dueDate.month, p.dueDate.day);
      if (dueDay.isBefore(period.end)) {
        total += p.amount;
      }
    }

    for (final r in rules) {
      if (!r.isActive || r.deletedAt != null || r.type != TxType.expense || r.amount <= 0) {
        continue;
      }
      var due = DateTime(r.nextDueDate.year, r.nextDueDate.month, r.nextDueDate.day);
      var guard = 0;
      while (due.isBefore(period.end) && guard < 62) {
        guard++;
        if (!due.isBefore(todayStart)) {
          total += r.amount;
        }
        due = switch (r.frequency) {
          RecurFrequency.daily => DateTime(due.year, due.month, due.day + 1),
          RecurFrequency.weekly => DateTime(due.year, due.month, due.day + 7),
          RecurFrequency.monthly => () {
              final targetDay = r.dayOfMonth ?? due.day;
              var nextMonth = due.month + 1;
              var nextYear = due.year;
              if (nextMonth > 12) {
                nextMonth = 1;
                nextYear++;
              }
              final daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
              final validDay = targetDay > daysInNextMonth ? daysInNextMonth : targetDay;
              return DateTime(nextYear, nextMonth, validDay);
            }(),
        };
      }
    }
    return total;
  }
}

