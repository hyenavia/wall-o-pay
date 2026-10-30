import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'app.dart';
import 'core/l10n.dart';
import 'data/cloud.dart';
import 'data/lock.dart';
import 'data/notifications.dart';
import 'data/prefs.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Data tanggal untuk kedua bahasa (Inggris default, Indonesia pilihan).
  await initializeDateFormatting('en');
  await initializeDateFormatting('id');

  // Inisialisasi zona waktu & layanan notifikasi lokal.
  tz.initializeTimeZones();
  await NotificationService.instance.init();

  final prefs = await SharedPreferences.getInstance();
  AppLocale.code = prefs.getString('pref_locale') == 'id' ? 'id' : 'en';

  // Firebase diinisialisasi terlebih dahulu sebelum layanan yang mengandalkan auth
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase is not available: $e');
  }

  // Muat status kunci PIN aplikasi (offline-first & sync cloud).
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
