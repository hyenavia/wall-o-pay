import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/l10n.dart';
import 'data/cloud.dart';
import 'data/prefs.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Data tanggal untuk kedua bahasa (Inggris default, Indonesia pilihan).
  await initializeDateFormatting('en');
  await initializeDateFormatting('id');

  final prefs = await SharedPreferences.getInstance();
  AppLocale.code = prefs.getString('pref_locale') == 'id' ? 'id' : 'en';

  // Firebase dipakai untuk login dan backup cloud.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase is not available: $e');
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
