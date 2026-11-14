import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/app.dart';
import 'package:wall_o_pay/core/brand.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/core/widgets.dart';
import 'package:wall_o_pay/data/app_database.dart';
import 'package:wall_o_pay/data/cloud.dart';
import 'package:wall_o_pay/data/lock.dart';
import 'package:wall_o_pay/data/prefs.dart';
import 'package:wall_o_pay/data/profile.dart';
import 'package:wall_o_pay/data/providers.dart';
import 'package:wall_o_pay/data/update_checker.dart';
import 'package:wall_o_pay/features/onboarding/onboarding_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Batch 3 — Profile & Initialization Reliability Tests', () {
    test(
      'ProfileController safely ignores corrupt base64 without deleting stored data or crashing',
      () async {
        const corruptB64 = '!!!not-valid-base64-data!!!';
        SharedPreferences.setMockInitialValues({
          'nickname_guest': 'Budi',
          'photo_guest': corruptB64,
        });
        final prefs = await SharedPreferences.getInstance();

        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        final profile = container.read(profileProvider);
        expect(profile.nickname, 'Budi');
        expect(profile.photo, isNull);
        expect(profile.photoImage, isNull);
        // Data mentah tidak dihapus otomatis tanpa mekanisme aman
        expect(prefs.getString('photo_guest'), corruptB64);

        // Migrasi dari guest dengan foto korup ke uid baru juga tidak crash
        await container.read(profileProvider.notifier).migrateGuestToUser('uid-1');
        expect(container.read(profileProvider).photo, isNull);
        expect(prefs.getString('photo_uid-1'), corruptB64);
      },
    );

    testWidgets(
      'UserAvatar renders initial fallback safely even when decoded image bytes are corrupt',
      (tester) async {
        // Base64 valid, namun bukan file gambar PNG/JPEG valid
        final invalidImageBytes = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7]);
        SharedPreferences.setMockInitialValues({
          'nickname_guest': 'Rani',
          'photo_guest': base64Encode(invalidImageBytes),
        });
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: const MaterialApp(
              home: Scaffold(
                body: Center(child: UserAvatar(size: 48)),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CircleAvatar), findsOneWidget);
        expect(find.text('R'), findsOneWidget);
      },
    );

    test(
      'AppPrefsController.applyRemoteData normalizes unsupported remote locale codes to en/id',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        await container.read(appPrefsProvider.notifier).applyRemoteData(
          {
            'localeCode': 'fr_FR',
            'updatedAt': 1000,
          },
          'uid-locale',
        );
        expect(container.read(appPrefsProvider).localeCode, 'en');
        expect(AppLocale.code, 'en');

        await container.read(appPrefsProvider.notifier).applyRemoteData(
          {
            'localeCode': 'id',
            'updatedAt': 2000,
          },
          'uid-locale',
        );
        expect(container.read(appPrefsProvider).localeCode, 'id');
        expect(AppLocale.code, 'id');
      },
    );

    test(
      'Lock.ensureLocalLoaded awaits legacy lock key migration before state read',
      () async {
        // Set kunci legacy pre-multi-akun (belum ada scope uid)
        SharedPreferences.setMockInitialValues({
          'lock.hash': 'v2:dummyhash',
          'lock.salt': 'dummysalt',
          'lock.delay': 5,
          'lock.updatedAt': 12345,
        });
        final prefs = await SharedPreferences.getInstance();

        await Lock.instance.ensureLocalLoaded('uid-legacy');

        expect(Lock.instance.state.value.enabled, isTrue);
        expect(Lock.instance.state.value.delayMin, 5);
        expect(prefs.getString('lock.hash'), isNull);
        expect(prefs.getString('lock.salt'), isNull);
      },
    );

    testWidgets(
      'AuthGate does not render a duplicate SplashPage while auth stream is loading',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final pendingAuthController = StreamController<User?>.broadcast();
        addTearDown(pendingAuthController.close);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              firebaseReadyProvider.overrideWithValue(true),
              authStateProvider.overrideWith(
                (ref) => pendingAuthController.stream,
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: [AppStrings.delegate],
              supportedLocales: AppLocale.supported,
              home: AuthGate(),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(SplashPage), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'OnboardingGate safely resolves without hanging when onboarding is already completed',
      (tester) async {
        SharedPreferences.setMockInitialValues({'onboarding_done_local': true});
        final prefs = await SharedPreferences.getInstance();
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              databaseProvider.overrideWithValue(db),
            ],
            child: const MaterialApp(
              localizationsDelegates: [AppStrings.delegate],
              supportedLocales: AppLocale.supported,
              home: OnboardingGate(child: Scaffold(body: Text('MainChild'))),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('MainChild'), findsOneWidget);
      },
    );

    test('UpdateCheckerService.cancelPendingPrompt cleans up lock listener safely', () {
      Lock.instance.isLocked.value = true;
      UpdateCheckerService.cancelPendingPrompt();
      // Pastikan pembatalan idempoten dan tidak melempar exception saat lock berubah
      Lock.instance.isLocked.value = false;
      UpdateCheckerService.cancelPendingPrompt();
    });
  });
}
