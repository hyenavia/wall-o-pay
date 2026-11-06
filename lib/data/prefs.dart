/// Pengelolaan preferensi tampilan dan siklus periode pengguna (tema, bahasa,
/// tipe periode bulanan/mingguan, hari awal minggu, dan tanggal gajian) beserta sinkronisasi cloud.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/l10n.dart';
import '../core/period.dart';
import 'feature_prefs.dart';
import 'notifications.dart';
import 'providers.dart';

/// Diisi di main.dart dengan instance SharedPreferences yang sudah dimuat.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider belum di-override'),
);

class AppPrefs {
  const AppPrefs({
    required this.themeMode,
    required this.localeCode,
    required this.periodType,
    this.firstDayOfWeek = DateTime.monday,
    this.firstDayOfMonth = 1,
    this.themePreset = 'botanical',
    this.cyberpunkUnlocked = true,
  });

  final ThemeMode themeMode;
  final String localeCode; // 'en' (default) atau 'id'
  final PeriodType periodType;
  final int firstDayOfWeek; // 1 (Monday) sampai 7 (Sunday)
  final int firstDayOfMonth; // 1 s.d. 28 (Hari/tanggal gajian)
  final String themePreset; // 'botanical' (default) atau 'cyberpunk'
  final bool cyberpunkUnlocked;

  bool get isCyberpunk => themePreset == 'cyberpunk';

  AppPrefs copyWith({
    ThemeMode? themeMode,
    String? localeCode,
    PeriodType? periodType,
    int? firstDayOfWeek,
    int? firstDayOfMonth,
    String? themePreset,
    bool? cyberpunkUnlocked,
  }) {
    return AppPrefs(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      periodType: periodType ?? this.periodType,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      firstDayOfMonth: firstDayOfMonth ?? this.firstDayOfMonth,
      themePreset: themePreset ?? this.themePreset,
      cyberpunkUnlocked: cyberpunkUnlocked ?? this.cyberpunkUnlocked,
    );
  }
}

/// Pengaturan tampilan dan personalisasi, disimpan di perangkat per-akun dan otomatis tersinkron ke cloud.
class AppPrefsController extends Notifier<AppPrefs> {
  static const _kTheme = 'pref_theme';
  static const _kLocale = 'pref_locale';
  static const _kPeriod = 'pref_period';
  static const _kFirstDayOfWeek = 'pref_first_day_of_week';
  static const _kFirstDayOfMonth = 'pref_first_day_of_month';
  static const _kThemePreset = 'pref_theme_preset';
  static const _kCyberpunkUnlocked = 'pref_cyberpunk_unlocked';
  static const _kUpdated = 'pref_prefs_updated';

  String? _uid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  String _k(String key, [String? uid]) {
    final u = uid ?? _uid();
    return u != null ? '${key}_$u' : key;
  }

  DocumentReference<Map<String, dynamic>>? _doc(String uid) {
    try {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('meta')
          .doc('preferences');
    } catch (_) {
      return null;
    }
  }

  @override
  AppPrefs build() {
    final uid = _uid();
    final p = ref.read(sharedPreferencesProvider);

    final themeStr = p.getString(_k(_kTheme, uid)) ?? p.getString(_kTheme);
    final theme = switch (themeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final locale = (p.getString(_k(_kLocale, uid)) ?? p.getString(_kLocale)) == 'id' ? 'id' : 'en';
    final periodStr = p.getString(_k(_kPeriod, uid)) ?? p.getString(_kPeriod);
    final period = periodStr == 'weekly' ? PeriodType.weekly : PeriodType.monthly;
    final firstDay = p.getInt(_k(_kFirstDayOfWeek, uid)) ?? p.getInt(_kFirstDayOfWeek) ?? DateTime.monday;
    final firstDayMonth = p.getInt(_k(_kFirstDayOfMonth, uid)) ?? p.getInt(_kFirstDayOfMonth) ?? 1;
    final themePreset = p.getString(_k(_kThemePreset, uid)) ?? p.getString(_kThemePreset) ?? 'botanical';
    final cyberpunkUnlocked = p.getBool(_k(_kCyberpunkUnlocked, uid)) ?? p.getBool(_kCyberpunkUnlocked) ?? true;

    AppLocale.code = locale;
    return AppPrefs(
      themeMode: theme,
      localeCode: locale,
      periodType: period,
      firstDayOfWeek: firstDay,
      firstDayOfMonth: firstDayMonth,
      themePreset: themePreset,
      cyberpunkUnlocked: cyberpunkUnlocked,
    );
  }

  /// Muat personalisasi akun tertentu saat login / ganti akun
  void loadForUser(String? uid) {
    if (uid == null) return;
    final p = ref.read(sharedPreferencesProvider);
    final themeStr = p.getString(_k(_kTheme, uid)) ?? p.getString(_kTheme);
    final theme = switch (themeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final locale = (p.getString(_k(_kLocale, uid)) ?? p.getString(_kLocale)) == 'id' ? 'id' : 'en';
    final periodStr = p.getString(_k(_kPeriod, uid)) ?? p.getString(_kPeriod);
    final period = periodStr == 'weekly' ? PeriodType.weekly : PeriodType.monthly;
    final firstDay = p.getInt(_k(_kFirstDayOfWeek, uid)) ?? p.getInt(_kFirstDayOfWeek) ?? DateTime.monday;
    final firstDayMonth = p.getInt(_k(_kFirstDayOfMonth, uid)) ?? p.getInt(_kFirstDayOfMonth) ?? 1;
    final themePreset = p.getString(_k(_kThemePreset, uid)) ?? p.getString(_kThemePreset) ?? 'botanical';
    final cyberpunkUnlocked = p.getBool(_k(_kCyberpunkUnlocked, uid)) ?? p.getBool(_kCyberpunkUnlocked) ?? true;

    AppLocale.code = locale;
    state = AppPrefs(
      themeMode: theme,
      localeCode: locale,
      periodType: period,
      firstDayOfWeek: firstDay,
      firstDayOfMonth: firstDayMonth,
      themePreset: themePreset,
      cyberpunkUnlocked: cyberpunkUnlocked,
    );
  }

  /// Sinkronkan dan pulihkan personalisasi dari Cloud Firestore
  Future<void> restoreFromCloud(String uid) async {
    try {
      final doc = _doc(uid);
      if (doc == null) return;
      final snap = await doc.get().timeout(const Duration(seconds: 15));
      final data = snap.data();
      if (data == null) return;

      await applyRemoteData(data, uid);
    } catch (e) {
      debugPrint('[AppPrefs] Error restoring preferences: $e');
    }
  }

  /// Terapkan data personalisasi dari cloud secara instan (dari get maupun snapshot)
  Future<void> applyRemoteData(Map<String, dynamic> data, String uid) async {
    final p = ref.read(sharedPreferencesProvider);
    final remoteAt = (data['updatedAt'] as num?)?.toInt() ?? 0;
    final localAt = p.getInt(_k(_kUpdated, uid)) ?? 0;

    if (remoteAt >= localAt) {
      final themeStr = data['themeMode'] as String?;
      final theme = switch (themeStr) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      final locale = data['localeCode'] as String? ?? 'en';
      final periodStr = data['periodType'] as String?;
      final period = periodStr == 'weekly' ? PeriodType.weekly : PeriodType.monthly;
      final firstDay = (data['firstDayOfWeek'] as num?)?.toInt() ?? DateTime.monday;
      final firstDayMonth = (data['firstDayOfMonth'] as num?)?.toInt() ?? 1;
      final themePreset = (data['themePreset'] as String?) ?? p.getString(_k(_kThemePreset, uid)) ?? p.getString(_kThemePreset) ?? 'botanical';
      final cyberpunkUnlocked = (data['cyberpunkUnlocked'] as bool?) ?? p.getBool(_k(_kCyberpunkUnlocked, uid)) ?? p.getBool(_kCyberpunkUnlocked) ?? true;

      AppLocale.code = locale;
      state = AppPrefs(
        themeMode: theme,
        localeCode: locale,
        periodType: period,
        firstDayOfWeek: firstDay,
        firstDayOfMonth: firstDayMonth,
        themePreset: themePreset,
        cyberpunkUnlocked: cyberpunkUnlocked,
      );

      await p.setString(_k(_kTheme, uid), theme.name);
      await p.setString(_k(_kLocale, uid), locale);
      await p.setString(_k(_kPeriod, uid), period.name);
      await p.setInt(_k(_kFirstDayOfWeek, uid), firstDay);
      await p.setInt(_k(_kFirstDayOfMonth, uid), firstDayMonth);
      await p.setString(_k(_kThemePreset, uid), themePreset);
      await p.setBool(_k(_kCyberpunkUnlocked, uid), cyberpunkUnlocked);
      await p.setInt(_k(_kUpdated, uid), remoteAt);

      // Terapkan pengaturan fitur & pengingat (FeaturePrefs)
      final rollover = data['rollover'] as bool?;
      final budgetAlerts = data['budgetAlerts'] as bool?;
      final dailyReminder = data['dailyReminder'] as bool?;
      final reminderHour = (data['reminderHour'] as num?)?.toInt();
      final reminderMinute = (data['reminderMinute'] as num?)?.toInt();

      ref.read(featurePrefsProvider.notifier).applyRemote(
        rollover: rollover,
        budgetAlerts: budgetAlerts,
        dailyReminder: dailyReminder,
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
      );

      // Jadwalkan notifikasi lokal di perangkat ini jika pengingat harian aktif di cloud
      if (dailyReminder != null) {
        final hour = reminderHour ?? ref.read(featurePrefsProvider).reminderHour;
        final min = reminderMinute ?? ref.read(featurePrefsProvider).reminderMinute;
        await NotificationService.instance.syncReminder(
          enabled: dailyReminder,
          time: TimeOfDay(hour: hour, minute: min),
        );
      }

      // Terapkan sensor privasi saldo
      final hide = data['hideBalance'] as bool?;
      if (hide != null) {
        await ref.read(hideBalanceProvider.notifier).set(hide);
      }

      // Terapkan status onboarding jika sudah pernah diselesaikan
      final onboardingDone = data['onboardingDone'] as bool?;
      if (onboardingDone == true) {
        await p.setBool('onboarding_done_$uid', true);
      }
    }
  }

  /// Unggah personalisasi saat ini ke Cloud Firestore
  Future<void> uploadToCloud(String uid) async {
    try {
      final doc = _doc(uid);
      if (doc == null) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      final p = ref.read(sharedPreferencesProvider);
      final feat = ref.read(featurePrefsProvider);
      final hide = ref.read(hideBalanceProvider);
      final onboardingDone = p.getBool('onboarding_done_$uid') ?? false;

      await doc.set({
        'themeMode': state.themeMode.name,
        'localeCode': state.localeCode,
        'periodType': state.periodType.name,
        'firstDayOfWeek': state.firstDayOfWeek,
        'firstDayOfMonth': state.firstDayOfMonth,
        'themePreset': state.themePreset,
        'cyberpunkUnlocked': state.cyberpunkUnlocked,
        'rollover': feat.rollover,
        'budgetAlerts': feat.budgetAlerts,
        'dailyReminder': feat.dailyReminder,
        'reminderHour': feat.reminderHour,
        'reminderMinute': feat.reminderMinute,
        'hideBalance': hide,
        'onboardingDone': onboardingDone,
        'updatedAt': now,
      }, SetOptions(merge: true));

      await p.setInt(_k(_kUpdated, uid), now);
    } catch (e) {
      debugPrint('[AppPrefs] Error uploading preferences: $e');
    }
  }

  /// Ekspor pengaturan fungsional ke dalam Map untuk backup JSON.
  Map<String, dynamic> exportPreferences() {
    final feat = ref.read(featurePrefsProvider);
    final hide = ref.read(hideBalanceProvider);
    return {
      'themeMode': state.themeMode.name,
      'localeCode': state.localeCode,
      'periodType': state.periodType.name,
      'firstDayOfWeek': state.firstDayOfWeek,
      'firstDayOfMonth': state.firstDayOfMonth,
      'themePreset': state.themePreset,
      'cyberpunkUnlocked': state.cyberpunkUnlocked,
      'rollover': feat.rollover,
      'budgetAlerts': feat.budgetAlerts,
      'dailyReminder': feat.dailyReminder,
      'reminderHour': feat.reminderHour,
      'reminderMinute': feat.reminderMinute,
      'hideBalance': hide,
    };
  }

  /// Impor pengaturan fungsional dari file backup JSON.
  Future<void> importPreferences(Map<String, dynamic> data) async {
    final uid = _uid();
    final p = ref.read(sharedPreferencesProvider);

    final themeStr = data['themeMode'] as String?;
    final theme = switch (themeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final locale = (data['localeCode'] as String? ?? 'en') == 'id' ? 'id' : 'en';
    final periodStr = data['periodType'] as String?;
    final period = periodStr == 'weekly' ? PeriodType.weekly : PeriodType.monthly;
    final firstDay = (data['firstDayOfWeek'] as num?)?.toInt() ?? DateTime.monday;
    final firstDayMonth = (data['firstDayOfMonth'] as num?)?.toInt() ?? 1;
    final themePreset = data['themePreset'] as String? ?? 'botanical';
    final cyberpunkUnlocked = data['cyberpunkUnlocked'] as bool? ?? true;

    AppLocale.code = locale;
    state = AppPrefs(
      themeMode: theme,
      localeCode: locale,
      periodType: period,
      firstDayOfWeek: firstDay,
      firstDayOfMonth: firstDayMonth,
      themePreset: themePreset,
      cyberpunkUnlocked: cyberpunkUnlocked,
    );

    await p.setString(_kTheme, theme.name);
    await p.setString(_kLocale, locale);
    await p.setString(_kPeriod, period.name);
    await p.setInt(_kFirstDayOfWeek, firstDay);
    await p.setInt(_kFirstDayOfMonth, firstDayMonth);
    await p.setString(_kThemePreset, themePreset);
    await p.setBool(_kCyberpunkUnlocked, cyberpunkUnlocked);
    if (uid != null) {
      await p.setString(_k(_kTheme, uid), theme.name);
      await p.setString(_k(_kLocale, uid), locale);
      await p.setString(_k(_kPeriod, uid), period.name);
      await p.setInt(_k(_kFirstDayOfWeek, uid), firstDay);
      await p.setInt(_k(_kFirstDayOfMonth, uid), firstDayMonth);
      await p.setString(_k(_kThemePreset, uid), themePreset);
      await p.setBool(_k(_kCyberpunkUnlocked, uid), cyberpunkUnlocked);
      await p.setInt(_k(_kFirstDayOfMonth, uid), firstDayMonth);
      final now = DateTime.now().millisecondsSinceEpoch;
      await p.setInt(_k(_kUpdated, uid), now);
    }

    final rollover = data['rollover'] as bool?;
    final budgetAlerts = data['budgetAlerts'] as bool?;
    final dailyReminder = data['dailyReminder'] as bool?;
    final reminderHour = (data['reminderHour'] as num?)?.toInt();
    final reminderMinute = (data['reminderMinute'] as num?)?.toInt();

    ref.read(featurePrefsProvider.notifier).applyRemote(
      rollover: rollover,
      budgetAlerts: budgetAlerts,
      dailyReminder: dailyReminder,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
    );

    if (dailyReminder != null) {
      final hour = reminderHour ?? ref.read(featurePrefsProvider).reminderHour;
      final min = reminderMinute ?? ref.read(featurePrefsProvider).reminderMinute;
      await NotificationService.instance.syncReminder(
        enabled: dailyReminder,
        time: TimeOfDay(hour: hour, minute: min),
      );
    }

    final hide = data['hideBalance'] as bool?;
    if (hide != null) {
      await ref.read(hideBalanceProvider.notifier).set(hide);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final p = ref.read(sharedPreferencesProvider);
    final uid = _uid();
    await p.setString(_kTheme, mode.name);
    if (uid != null) {
      await p.setString(_k(_kTheme, uid), mode.name);
      uploadToCloud(uid);
    }
  }

  Future<void> setLocale(String code) async {
    final value = code == 'id' ? 'id' : 'en';
    AppLocale.code = value;
    state = state.copyWith(localeCode: value);
    final p = ref.read(sharedPreferencesProvider);
    final uid = _uid();
    await p.setString(_kLocale, value);
    if (uid != null) {
      await p.setString(_k(_kLocale, uid), value);
      uploadToCloud(uid);
    }
  }

  Future<void> setPeriodType(PeriodType type) async {
    state = state.copyWith(periodType: type);
    final p = ref.read(sharedPreferencesProvider);
    final uid = _uid();
    await p.setString(_kPeriod, type.name);
    if (uid != null) {
      await p.setString(_k(_kPeriod, uid), type.name);
      uploadToCloud(uid);
    }
  }

  Future<void> setFirstDayOfWeek(int day) async {
    state = state.copyWith(firstDayOfWeek: day);
    final p = ref.read(sharedPreferencesProvider);
    final uid = _uid();
    await p.setInt(_kFirstDayOfWeek, day);
    if (uid != null) {
      await p.setInt(_k(_kFirstDayOfWeek, uid), day);
      uploadToCloud(uid);
    }
  }

  Future<void> setFirstDayOfMonth(int day) async {
    state = state.copyWith(firstDayOfMonth: day);
    final p = ref.read(sharedPreferencesProvider);
    final uid = _uid();
    await p.setInt(_kFirstDayOfMonth, day);
    if (uid != null) {
      await p.setInt(_k(_kFirstDayOfMonth, uid), day);
      uploadToCloud(uid);
    }
  }

  Future<void> setThemePreset(String preset) async {
    final value = preset == 'cyberpunk' ? 'cyberpunk' : 'botanical';
    state = state.copyWith(themePreset: value);
    final p = ref.read(sharedPreferencesProvider);
    final uid = _uid();
    await p.setString(_kThemePreset, value);
    if (uid != null) {
      await p.setString(_k(_kThemePreset, uid), value);
      uploadToCloud(uid);
    }
  }

  Future<void> unlockCyberpunk([bool unlock = true]) async {
    state = state.copyWith(cyberpunkUnlocked: unlock);
    final p = ref.read(sharedPreferencesProvider);
    final uid = _uid();
    await p.setBool(_kCyberpunkUnlocked, unlock);
    if (uid != null) {
      await p.setBool(_k(_kCyberpunkUnlocked, uid), unlock);
      uploadToCloud(uid);
    }
  }
}

final appPrefsProvider =
    NotifierProvider<AppPrefsController, AppPrefs>(AppPrefsController.new);
