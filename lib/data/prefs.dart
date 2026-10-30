import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/l10n.dart';
import '../core/period.dart';

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
  });

  final ThemeMode themeMode;
  final String localeCode; // 'en' (default) atau 'id'
  final PeriodType periodType;
  final int firstDayOfWeek; // 1 (Monday) sampai 7 (Sunday)

  AppPrefs copyWith({
    ThemeMode? themeMode,
    String? localeCode,
    PeriodType? periodType,
    int? firstDayOfWeek,
  }) {
    return AppPrefs(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      periodType: periodType ?? this.periodType,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
    );
  }
}

/// Pengaturan tampilan dan personalisasi, disimpan di perangkat per-akun dan otomatis tersinkron ke cloud.
class AppPrefsController extends Notifier<AppPrefs> {
  static const _kTheme = 'pref_theme';
  static const _kLocale = 'pref_locale';
  static const _kPeriod = 'pref_period';
  static const _kFirstDayOfWeek = 'pref_first_day_of_week';
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

    AppLocale.code = locale;
    return AppPrefs(
      themeMode: theme,
      localeCode: locale,
      periodType: period,
      firstDayOfWeek: firstDay,
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

    AppLocale.code = locale;
    state = AppPrefs(
      themeMode: theme,
      localeCode: locale,
      periodType: period,
      firstDayOfWeek: firstDay,
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

      AppLocale.code = locale;
      state = AppPrefs(
        themeMode: theme,
        localeCode: locale,
        periodType: period,
        firstDayOfWeek: firstDay,
      );

      await p.setString(_k(_kTheme, uid), theme.name);
      await p.setString(_k(_kLocale, uid), locale);
      await p.setString(_k(_kPeriod, uid), period.name);
      await p.setInt(_k(_kFirstDayOfWeek, uid), firstDay);
      await p.setInt(_k(_kUpdated, uid), remoteAt);
    }
  }

  /// Unggah personalisasi saat ini ke Cloud Firestore
  Future<void> uploadToCloud(String uid) async {
    try {
      final doc = _doc(uid);
      if (doc == null) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      await doc.set({
        'themeMode': state.themeMode.name,
        'localeCode': state.localeCode,
        'periodType': state.periodType.name,
        'firstDayOfWeek': state.firstDayOfWeek,
        'updatedAt': now,
      }, SetOptions(merge: true));

      final p = ref.read(sharedPreferencesProvider);
      await p.setInt(_k(_kUpdated, uid), now);
    } catch (e) {
      debugPrint('[AppPrefs] Error uploading preferences: $e');
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
}

final appPrefsProvider =
    NotifierProvider<AppPrefsController, AppPrefs>(AppPrefsController.new);
