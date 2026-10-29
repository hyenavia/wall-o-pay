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

/// Pengaturan tampilan dan cara mengelola uang, disimpan di perangkat.
class AppPrefsController extends Notifier<AppPrefs> {
  static const _kTheme = 'pref_theme';
  static const _kLocale = 'pref_locale';
  static const _kPeriod = 'pref_period';
  static const _kFirstDayOfWeek = 'pref_first_day_of_week';

  @override
  AppPrefs build() {
    final p = ref.read(sharedPreferencesProvider);
    final theme = switch (p.getString(_kTheme)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final locale = p.getString(_kLocale) == 'id' ? 'id' : 'en';
    final period = p.getString(_kPeriod) == 'weekly'
        ? PeriodType.weekly
        : PeriodType.monthly;
    final firstDay = p.getInt(_kFirstDayOfWeek) ?? DateTime.monday;

    AppLocale.code = locale;
    return AppPrefs(
      themeMode: theme,
      localeCode: locale,
      periodType: period,
      firstDayOfWeek: firstDay,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await ref.read(sharedPreferencesProvider).setString(_kTheme, mode.name);
  }

  Future<void> setLocale(String code) async {
    final value = code == 'id' ? 'id' : 'en';
    AppLocale.code = value; // harus diset sebelum UI dibangun ulang
    state = state.copyWith(localeCode: value);
    await ref.read(sharedPreferencesProvider).setString(_kLocale, value);
  }

  Future<void> setPeriodType(PeriodType type) async {
    state = state.copyWith(periodType: type);
    await ref.read(sharedPreferencesProvider).setString(_kPeriod, type.name);
  }

  Future<void> setFirstDayOfWeek(int day) async {
    state = state.copyWith(firstDayOfWeek: day);
    await ref.read(sharedPreferencesProvider).setInt(_kFirstDayOfWeek, day);
  }
}

final appPrefsProvider =
    NotifierProvider<AppPrefsController, AppPrefs>(AppPrefsController.new);
