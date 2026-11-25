import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

    test(
      'ProfileController syncs nickname, photo, and frameId across devices via applyRemoteData and tracks pending uploads',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            firebaseReadyProvider.overrideWithValue(false),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(profileProvider.notifier);
        const uid = 'uid-sync-1';

        // Fresh profile has no pending upload (prevents empty overwrite on new device)
        expect(notifier.hasPendingUpload(uid), isFalse);

        // Apply remote personalization from another device
        final samplePhoto = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
        final applied = await notifier.applyRemoteData({
          'nickname': 'Wendy',
          'photo': base64Encode(samplePhoto),
          'frameId': 'border_05',
          'updatedAt': 2000,
        }, uid);
        expect(applied, isTrue);

        var profile = container.read(profileProvider);
        expect(profile.nickname, 'Wendy');
        expect(profile.photo, samplePhoto);
        expect(profile.frameId, 'border_05');
        expect(notifier.hasPendingUpload(uid), isFalse);

        // Stale remote snapshot must not overwrite newer local data
        final staleApplied = await notifier.applyRemoteData({
          'nickname': 'OldName',
          'frameId': 'border_02',
          'updatedAt': 1500,
        }, uid);
        expect(staleApplied, isFalse);
        expect(container.read(profileProvider).nickname, 'Wendy');

        // Clearing remote photo & frameId with newer timestamp removes them locally
        final cleared = await notifier.applyRemoteData({
          'nickname': 'Wendy',
          'photo': null,
          'frameId': null,
          'updatedAt': 3000,
        }, uid);
        expect(cleared, isTrue);
        profile = container.read(profileProvider);
        expect(profile.photo, isNull);
        expect(profile.frameId, isNull);
        expect(notifier.hasPendingUpload(uid), isFalse);
      },
    );

    test(
      'ProfileController marks pending upload on local edits, validates payload, migrates frameId, and clears sync state',
      () async {
        SharedPreferences.setMockInitialValues({
          'nickname_guest': 'GuestHero',
          'profile_frame_guest': 'border_07',
        });
        final prefs = await SharedPreferences.getInstance();
        const uid = 'uid-sync-2';

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            firebaseReadyProvider.overrideWithValue(false),
            currentUserProvider.overrideWithValue(null),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(profileProvider.notifier);
        await notifier.migrateGuestToUser(uid);

        expect(prefs.getString('nickname_$uid'), 'GuestHero');
        expect(prefs.getString('profile_frame_$uid'), 'border_07');
        expect(notifier.hasPendingUpload(uid), isTrue);

        final payload = notifier.buildCloudPayload(uid);
        expect(payload.keys.toSet(), {'nickname', 'photo', 'frameId', 'updatedAt'});
        expect(payload['nickname'], 'GuestHero');
        expect(payload['frameId'], 'border_07');
        expect(payload['updatedAt'], isA<int>());
        expect((payload['updatedAt'] as int) > 0, isTrue);

        // Verify firestore.rules permits all keys produced by buildCloudPayload
        final rulesText = File('firestore.rules').readAsStringSync();
        expect(
          rulesText,
          contains("hasOnlyAllowedFields(['nickname', 'photo', 'frameId', 'updatedAt'])"),
        );

        await notifier.clearLocal(uid);
        expect(prefs.getString('nickname_$uid'), isNull);
        expect(prefs.getString('profile_frame_$uid'), isNull);
        expect(prefs.getInt('profile_updated_$uid'), isNull);
        expect(prefs.getInt('profile_synced_at_$uid'), isNull);
        expect(notifier.hasPendingUpload(uid), isFalse);
      },
    );
  });
}
