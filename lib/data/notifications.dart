/// Layanan notifikasi lokal Android untuk pengingat pencatatan harian,
/// peringatan pemakaian anggaran (80% & 100%), serta pengingat jatuh tempo utang-piutang.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/format.dart';
import '../core/l10n.dart';
import '../core/period.dart';
import 'app_database.dart';
import 'tables.dart' show DebtDirection, TxType;

/// Notifikasi lokal: peringatan anggaran dan pengingat harian.
/// Semua pemanggilan aman: jika terjadi kesalahan, hanya dicatat ke log.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _reminderId = 7001;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> init() async {
    if (_ready || !_supported) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(settings);
      _ready = true;
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  /// Meminta izin notifikasi (Android 13 ke atas). Mengembalikan true jika diizinkan.
  Future<bool> requestPermission() async {
    if (!_supported) return false;
    await init();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    } catch (e) {
      debugPrint('Notification permission failed: $e');
      return false;
    }
  }

  Future<void> showBudgetAlert({
    required String categoryName,
    required int percent,
    required int notificationId,
  }) async {
    if (!_supported) return;
    await init();
    if (!_ready) return;
    try {
      final over = percent >= 100;
      await _plugin.show(
        notificationId,
        trG(over ? 'Budget exceeded: {category}' : 'Budget almost used: {category}',
            {'category': trG(categoryName)}),
        trG(over
            ? 'You have used all of your {category} budget for this period.'
            : 'You have used {pct}% of your {category} budget.',
            {'category': trG(categoryName), 'pct': percent}),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'budget_alerts',
            trG('Budget alerts'),
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Budget alert failed: $e');
    }
  }

  Future<void> showDebtReminder({
    required int notificationId,
    required String title,
    required String body,
  }) async {
    if (!_supported) return;
    await init();
    if (!_ready) return;
    try {
      await _plugin.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'debt_reminders',
            trG('Debt reminders'),
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Debt reminder failed: $e');
    }
  }

  Future<void> showRecapDigest({
    required int notificationId,
    required String title,
    required String body,
  }) async {
    if (!_supported) return;
    await init();
    if (!_ready) return;
    try {
      await _plugin.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'harvest_recap',
            trG('Harvest recap notifications'),
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Recap digest failed: $e');
    }
  }

  /// Menjadwalkan pengingat harian pada jam lokal [time]. Jadwal dihitung
  /// ulang setiap aplikasi dibuka, jadi tetap akurat jika zona waktu berubah.
  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    if (!_supported) return;
    await init();
    if (!_ready) return;
    try {
      final now = DateTime.now();
      var local = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      if (!local.isAfter(now)) local = local.add(const Duration(days: 1));
      final when = tz.TZDateTime.from(local, tz.UTC);

      await _plugin.zonedSchedule(
        _reminderId,
        trG('Time to log your spending'),
        trG("Have you recorded today's expenses?"),
        when,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            trG('Daily reminder'),
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Schedule reminder failed: $e');
    }
  }

  Future<void> cancelDailyReminder() async {
    if (!_supported) return;
    await init();
    try {
      await _plugin.cancel(_reminderId);
    } catch (e) {
      debugPrint('Cancel reminder failed: $e');
    }
  }

  /// Sesuaikan jadwal pengingat dengan pengaturan terbaru.
  Future<void> syncReminder({required bool enabled, required TimeOfDay time}) {
    return enabled ? scheduleDailyReminder(time) : cancelDailyReminder();
  }
}

/// Periksa anggaran kategori setelah pengeluaran dicatat. Peringatan dikirim
/// sekali saat mencapai 80% dan sekali saat mencapai 100% untuk tiap periode.
Future<void> checkBudgetAfterExpense({
  required AppDatabase db,
  required SharedPreferences prefs,
  required PeriodType periodType,
  required String categoryId,
  required String categoryName,
  required DateTime date,
  int firstDayOfWeek = DateTime.monday,
  int firstDayOfMonth = 1,
  bool rolloverEnabled = false,
  int totalBudgetPool = 0,
}) async {
  final period = Period.containing(
    periodType,
    date,
    firstDayOfWeek: firstDayOfWeek,
    firstDayOfMonth: firstDayOfMonth,
  );
  var budget = await db.budgetAmount(categoryId, period.key);
  if (rolloverEnabled) {
    final prevPeriod = period.shift(-1);
    final prevBudget = await db.budgetAmount(categoryId, prevPeriod.key);
    if (prevBudget > 0) {
      final prevSpent = await db.expenseTotal(
        categoryId,
        prevPeriod.start,
        prevPeriod.end,
      );
      final carryOver = prevBudget - prevSpent;
      if (carryOver > 0) {
        budget += carryOver;
      }
    }
  }

  if (budget > 0) {
    final spent = await db.expenseTotal(categoryId, period.start, period.end);

    final level = spent >= budget ? 100 : (spent * 100 >= budget * 80 ? 80 : 0);
    final key = 'alert_${period.key}_$categoryId';
    final last = prefs.getInt(key) ?? 0;
    if (level > last) {
      await prefs.setInt(key, level);
      await NotificationService.instance.showBudgetAlert(
        categoryName: categoryName,
        percent: level,
        notificationId: categoryId.hashCode & 0x7fffffff,
      );
    } else if (level < last) {
      await prefs.setInt(key, level);
    }
  }

  if (totalBudgetPool > 0) {
    final txs = await db.transactionsBetween(period.start, period.end);
    var totalSpent = 0;
    for (final t in txs) {
      if (t.type == TxType.expense) {
        totalSpent += t.amount;
      }
    }
    final poolLevel = totalSpent >= totalBudgetPool
        ? 100
        : (totalSpent * 100 >= totalBudgetPool * 80 ? 80 : 0);
    final poolKey = 'alert_pool_${period.key}';
    final lastPool = prefs.getInt(poolKey) ?? 0;
    if (poolLevel > lastPool) {
      await prefs.setInt(poolKey, poolLevel);
      await NotificationService.instance.showBudgetAlert(
        categoryName: 'Total Budget',
        percent: poolLevel,
        notificationId: ('pool_${period.key}').hashCode & 0x7fffffff,
      );
    } else if (poolLevel < lastPool) {
      await prefs.setInt(poolKey, poolLevel);
    }
  }
}

/// Periksa utang-piutang yang mendekati atau melewati jatuh tempo.
/// Pengingat dikirim maksimal sekali sehari per item utang.
Future<void> checkDebtDueReminders(AppDatabase db) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final activeDebts = await (db.select(db.debts)
          ..where((d) => d.deletedAt.isNull())
          ..where((d) => d.dueDate.isNotNull()))
        .get();

    for (final debt in activeDebts) {
      if (debt.paidAmount >= debt.amount || debt.dueDate == null) continue;
      final due = DateTime(debt.dueDate!.year, debt.dueDate!.month, debt.dueDate!.day);

      // Cek jatuh tempo: besok (H-1), hari ini (H), atau lewat jatuh tempo hingga 7 hari
      final diffDays = due.difference(todayDate).inDays;
      if (diffDays < -7 || diffDays > 1) continue;

      final key = 'notified_debt_${debt.id}_${todayDate.year}_${todayDate.month}_${todayDate.day}';
      if (prefs.getBool(key) == true) continue;

      final remaining = debt.amount - debt.paidAmount;
      final formattedAmount = rupiah(remaining);
      String formattedDate;
      try {
        formattedDate = shortDate(due);
      } catch (_) {
        formattedDate = '${due.day}/${due.month}/${due.year}';
      }

      final isLent = debt.direction == DebtDirection.lent;
      final title = isLent
          ? trG('Debt collection reminder')
          : trG('Debt repayment reminder');

      final body = isLent
          ? trG('{person} owes you {amount} due on {date}', {
              'person': debt.person,
              'amount': formattedAmount,
              'date': formattedDate,
            })
          : trG('Your debt to {person} of {amount} is due on {date}', {
              'person': debt.person,
              'amount': formattedAmount,
              'date': formattedDate,
            });

      await NotificationService.instance.showDebtReminder(
        notificationId: debt.id.hashCode & 0x7fffffff,
        title: title,
        body: body,
      );

      await prefs.setBool(key, true);
    }
  } catch (e) {
    debugPrint('Debt due reminder check failed: $e');
  }
}

/// Menentukan apakah notifikasi Harvest Recap perlu dikirim untuk periode yang baru selesai.
bool shouldSendRecapNotification({
  required bool enabled,
  required String completedPeriodKey,
  required int completedTxCount,
  required String? lastSeenKey,
  required bool alreadyNotified,
}) {
  if (!enabled || completedTxCount <= 0) return false;
  if (lastSeenKey == completedPeriodKey) return false;
  if (alreadyNotified) return false;
  return true;
}

/// Memeriksa sekali per periode selesai apakah notifikasi Harvest Recap perlu ditampilkan.
Future<void> checkHarvestRecapNotification({
  required AppDatabase db,
  required SharedPreferences prefs,
  required bool enabled,
  required PeriodType periodType,
  int firstDayOfWeek = DateTime.monday,
  int firstDayOfMonth = 1,
  DateTime? now,
}) async {
  try {
    if (!enabled) return;
    final completed = Period.containing(
      periodType,
      now ?? DateTime.now(),
      firstDayOfWeek: firstDayOfWeek,
      firstDayOfMonth: firstDayOfMonth,
    ).shift(-1);

    final seenKey = periodType == PeriodType.weekly
        ? 'last_recap_seen_weekly'
        : 'last_recap_seen_monthly';
    final notifiedKey = 'notified_recap_${completed.key}';

    final lastSeen = prefs.getString(seenKey);
    final alreadyNotified = prefs.getBool(notifiedKey) == true;
    if (lastSeen == completed.key || alreadyNotified) return;

    final txs = await db.watchTransactionsBetween(completed.start, completed.end).first;
    if (!shouldSendRecapNotification(
      enabled: enabled,
      completedPeriodKey: completed.key,
      completedTxCount: txs.length,
      lastSeenKey: lastSeen,
      alreadyNotified: alreadyNotified,
    )) {
      return;
    }

    String periodLabel;
    try {
      periodLabel = completed.label();
    } catch (_) {
      periodLabel = completed.key;
    }

    final title = trG(
      periodType == PeriodType.weekly
          ? 'Weekly Harvest Review'
          : 'Monthly Harvest Review',
    );
    final body = trG(
      'Your recap for {period} is ready inside Insights.',
      {'period': periodLabel},
    );

    await NotificationService.instance.showRecapDigest(
      notificationId: ('recap_${completed.key}').hashCode & 0x7fffffff,
      title: title,
      body: body,
    );
    await prefs.setBool(notifiedKey, true);
  } catch (e) {
    debugPrint('Harvest recap notification check failed: $e');
  }
}
