import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/l10n.dart';
import '../core/period.dart';
import 'app_database.dart';

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
}) async {
  final period = Period.containing(periodType, date);
  final budget = await db.budgetAmount(categoryId, period.key);
  if (budget <= 0) return;
  final spent = await db.expenseTotal(categoryId, period.start, period.end);

  final level = spent >= budget ? 100 : (spent * 100 >= budget * 80 ? 80 : 0);
  final key = 'alert_${period.key}_$categoryId';
  final last = prefs.getInt(key) ?? 0;
  if (level <= last) {
    if (level < last) await prefs.setInt(key, level);
    return;
  }
  await prefs.setInt(key, level);
  await NotificationService.instance.showBudgetAlert(
    categoryName: categoryName,
    percent: level,
    notificationId: categoryId.hashCode & 0x7fffffff,
  );
}
