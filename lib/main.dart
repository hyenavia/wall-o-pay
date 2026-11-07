/// Titik masuk utama (entry point) aplikasi Wall o' Pay.
/// Menginisialisasi binding Flutter, format tanggal lokal, zona waktu,
/// notifikasi lokal, preferensi bahasa, Firebase, kunci PIN, dan versi aplikasi
/// sebelum menjalankan widget utama di dalam [ProviderScope].
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tz;

import 'app.dart';
import 'core/l10n.dart';
import 'data/cloud.dart';
import 'data/lock.dart';
import 'data/notifications.dart';
import 'data/prefs.dart';
import 'data/share_service.dart';
import 'data/update_checker.dart';
import 'firebase_options.dart';

/// Fungsi utama yang dieksekusi pertama kali saat aplikasi dibuka.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi tabel zona waktu 10-tahunan yang ringan.
  tz.initializeTimeZones();

  late final SharedPreferences prefs;
  var firebaseReady = false;

  // Jalankan seluruh inisialisasi independen secara paralel untuk mempercepat cold start.
  await Future.wait<void>([
    initializeDateFormatting('en'),
    initializeDateFormatting('id'),
    NotificationService.instance.init(),
    ShareService.preloadInitialData(),
    SharedPreferences.getInstance().then((p) => prefs = p),
    () async {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        firebaseReady = true;
      } catch (e) {
        debugPrint('Firebase is not available: $e');
      }
    }(),
    () async {
      try {
        await UpdateCheckerService.getInstalledVersion();
      } catch (e) {
        debugPrint('Error loading app version: $e');
      }
    }(),
  ]);

  AppLocale.code = prefs.getString('pref_locale') == 'id' ? 'id' : 'en';

  // Muat status kunci PIN aplikasi setelah SharedPreferences & Firebase siap.
  try {
    await Lock.instance.load();
  } catch (e) {
    debugPrint('Error loading lock state: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        firebaseReadyProvider.overrideWithValue(firebaseReady),
      ],
      child: const WallOPayApp(),
    ),
  );
}
