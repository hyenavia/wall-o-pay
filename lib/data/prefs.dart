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
  });

  final ThemeMode themeMode;
  final String localeCode; // 'en' (default) atau 'id'
  final PeriodType periodType;

  AppPrefs copyWith({ThemeMode? themeMode, String? localeCode, PeriodType? periodType}) {
    return AppPrefs(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      periodType: periodType ?? this.periodType,
    );
  }
}

/// Pengaturan tampilan dan cara mengelola uang, disimpan di perangkat.
class AppPrefsController extends Notifier<AppPrefs> {
  static const _kTheme = 'pref_theme';
  static const _kLocale = 'pref_locale';
  static const _kPeriod = 'pref_period';

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
    AppLocale.code = locale;
    return AppPrefs(themeMode: theme, localeCode: locale, periodType: period);
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
}

final appPrefsProvider =
    NotifierProvider<AppPrefsController, AppPrefs>(AppPrefsController.new);
