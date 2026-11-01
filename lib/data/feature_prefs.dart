import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs.dart';

/// Pengaturan fitur tambahan: rollover anggaran, peringatan, dan pengingat harian.
class FeaturePrefs {
  const FeaturePrefs({
    required this.rollover,
    required this.budgetAlerts,
    required this.dailyReminder,
    required this.reminderHour,
    required this.reminderMinute,
  });

  final bool rollover;
  final bool budgetAlerts;
  final bool dailyReminder;
  final int reminderHour;
  final int reminderMinute;

  TimeOfDay get reminderTime => TimeOfDay(hour: reminderHour, minute: reminderMinute);

  FeaturePrefs copyWith({
    bool? rollover,
    bool? budgetAlerts,
    bool? dailyReminder,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return FeaturePrefs(
      rollover: rollover ?? this.rollover,
      budgetAlerts: budgetAlerts ?? this.budgetAlerts,
      dailyReminder: dailyReminder ?? this.dailyReminder,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }
}

class FeaturePrefsController extends Notifier<FeaturePrefs> {
  static const _kRollover = 'pref_rollover';
  static const _kAlerts = 'pref_budget_alerts';
  static const _kReminder = 'pref_daily_reminder';
  static const _kHour = 'pref_reminder_hour';
  static const _kMinute = 'pref_reminder_minute';

  @override
  FeaturePrefs build() {
    final p = ref.read(sharedPreferencesProvider);
    return FeaturePrefs(
      rollover: p.getBool(_kRollover) ?? false,
      budgetAlerts: p.getBool(_kAlerts) ?? false,
      dailyReminder: p.getBool(_kReminder) ?? false,
      reminderHour: p.getInt(_kHour) ?? 20,
      reminderMinute: p.getInt(_kMinute) ?? 0,
    );
  }

  void _syncToCloud() {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        ref.read(appPrefsProvider.notifier).uploadToCloud(uid);
      }
    } catch (_) {}
  }

  void applyRemote({
    bool? rollover,
    bool? budgetAlerts,
    bool? dailyReminder,
    int? reminderHour,
    int? reminderMinute,
  }) {
    state = state.copyWith(
      rollover: rollover,
      budgetAlerts: budgetAlerts,
      dailyReminder: dailyReminder,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
    );
    final p = ref.read(sharedPreferencesProvider);
    if (rollover != null) p.setBool(_kRollover, rollover);
    if (budgetAlerts != null) p.setBool(_kAlerts, budgetAlerts);
    if (dailyReminder != null) p.setBool(_kReminder, dailyReminder);
    if (reminderHour != null) p.setInt(_kHour, reminderHour);
    if (reminderMinute != null) p.setInt(_kMinute, reminderMinute);
  }

  Future<void> setRollover(bool v) async {
    state = state.copyWith(rollover: v);
    await ref.read(sharedPreferencesProvider).setBool(_kRollover, v);
    _syncToCloud();
  }

  Future<void> setBudgetAlerts(bool v) async {
    state = state.copyWith(budgetAlerts: v);
    await ref.read(sharedPreferencesProvider).setBool(_kAlerts, v);
    _syncToCloud();
  }

  Future<void> setDailyReminder(bool v) async {
    state = state.copyWith(dailyReminder: v);
    await ref.read(sharedPreferencesProvider).setBool(_kReminder, v);
    _syncToCloud();
  }

  Future<void> setReminderTime(TimeOfDay t) async {
    state = state.copyWith(reminderHour: t.hour, reminderMinute: t.minute);
    final p = ref.read(sharedPreferencesProvider);
    await p.setInt(_kHour, t.hour);
    await p.setInt(_kMinute, t.minute);
    _syncToCloud();
  }
}

final featurePrefsProvider =
    NotifierProvider<FeaturePrefsController, FeaturePrefs>(FeaturePrefsController.new);
