import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/core/theme.dart';
import 'package:wall_o_pay/data/budget_rule.dart';
import 'package:wall_o_pay/data/cloud.dart';
import 'package:wall_o_pay/data/lock.dart';
import 'package:wall_o_pay/data/prefs.dart';
import 'package:wall_o_pay/data/profile.dart';
import 'package:wall_o_pay/features/auth/auth_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Guest Mode State & Migration Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('SkipAuth skip() and reset() persist to SharedPreferences', () async {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(skipAuthProvider), isFalse);

      await container.read(skipAuthProvider.notifier).skip();
      expect(container.read(skipAuthProvider), isTrue);
      expect(prefs.getBool('pref_skip_auth'), isTrue);

      await container.read(skipAuthProvider.notifier).reset();
      expect(container.read(skipAuthProvider), isFalse);
      expect(prefs.getBool('pref_skip_auth'), isNull);
    });

    test('ProfileController stores guest profile locally and migrates to user', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          firebaseReadyProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(profileProvider).nickname, isNull);
      expect(container.read(displayNameProvider), isNull);

      final sampleBytes = Uint8List.fromList([1, 2, 3, 4]);
      await container.read(profileProvider.notifier).setNickname('Rani');
      await container.read(profileProvider.notifier).setPhoto(sampleBytes);

      expect(container.read(profileProvider).nickname, 'Rani');
      expect(container.read(profileProvider).photo, sampleBytes);
      expect(container.read(displayNameProvider), 'Rani');
      expect(prefs.getString('nickname_guest'), 'Rani');

      await container.read(profileProvider.notifier).migrateGuestToUser('uid_123');
      expect(prefs.getString('nickname_guest'), isNull);
      expect(prefs.getString('photo_guest'), isNull);
      expect(prefs.getString('nickname_uid_123'), 'Rani');
      expect(prefs.getString('photo_uid_123'), isNotNull);
    });

    test('BudgetRuleController migrates guest budget pools to user uid', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          firebaseReadyProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(budgetRuleProvider.notifier)
          .setTotalBudget('2026-11', 5000000);
      expect(container.read(budgetRuleProvider).getTotalBudget('2026-11'), 5000000);

      await container
          .read(budgetRuleProvider.notifier)
          .migrateGuestToUser('uid_abc');

      expect(prefs.getString('pref_budget_total_pools'), isNull);
      expect(prefs.getString('pref_budget_total_pools_uid_abc'), isNotNull);
      expect(container.read(budgetRuleProvider).getTotalBudget('2026-11'), 5000000);
    });

    test('Lock supports guest PIN, migration to user, and clearLocal', () async {
      await Lock.instance.load();
      expect(Lock.instance.state.value.enabled, isFalse);

      await Lock.instance.setPin('123456');
      expect(Lock.instance.state.value.enabled, isTrue);
      expect(Lock.instance.verify('123456'), isTrue);
      expect(Lock.instance.verify('000000'), isFalse);

      await Lock.instance.clearLocal('guest');
      expect(Lock.instance.state.value.enabled, isFalse);

      await Lock.instance.setPin('654321');
      expect(Lock.instance.state.value.enabled, isTrue);

      await Lock.instance.migrateGuestToUser('uid_pin_1');
      expect(prefs.getString('lock.hash.guest'), isNull);
      expect(prefs.getString('lock.hash.uid_pin_1'), isNotNull);
      expect(Lock.instance.verify('654321'), isTrue);

      await Lock.instance.clearLocal('uid_pin_1');
      await Lock.instance.loadForUser(null);
    });

    test('Lock enforces persistent brute-force lockout after 5 failed PIN attempts', () async {
      await Lock.instance.load();
      await Lock.instance.setPin('123456');
      expect(Lock.instance.isLockedOut, isFalse);

      for (var i = 0; i < 4; i++) {
        expect(Lock.instance.verify('000000'), isFalse);
        expect(Lock.instance.isLockedOut, isFalse);
      }

      // 5th wrong attempt triggers 30s lockout persisted in SharedPreferences
      expect(Lock.instance.verify('000000'), isFalse);
      expect(Lock.instance.isLockedOut, isTrue);
      expect(Lock.instance.remainingLockoutSeconds, greaterThan(0));
      // Even the correct PIN is rejected while locked out
      expect(Lock.instance.verify('123456'), isFalse);

      await Lock.instance.clearLocal('guest');
      expect(Lock.instance.isLockedOut, isFalse);
    });

    testWidgets('AuthPage shows Continue as Guest button and activates skipAuth',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          firebaseReadyProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildTheme(),
            locale: const Locale('en'),
            supportedLocales: AppLocale.supported,
            localizationsDelegates: const [
              AppStrings.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AuthPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final guestBtn = find.text('Continue as Guest');
      expect(guestBtn, findsOneWidget);

      await tester.ensureVisible(guestBtn);
      await tester.tap(guestBtn);
      await tester.pump();

      expect(container.read(skipAuthProvider), isTrue);
    });

    test('Bilingual Guest Mode translations exist in EN and ID', () {
      final en = AppStrings('en');
      final id = AppStrings('id');

      expect(en.tr('Continue as Guest'), 'Continue as Guest');
      expect(id.tr('Continue as Guest'), 'Lanjut sebagai Tamu');
      expect(en.tr('Guest Mode (Offline)'), 'Guest Mode (Offline)');
      expect(id.tr('Guest Mode (Offline)'), 'Mode Tamu (Offline)');
      expect(en.tr('Sign In / Create Account'), 'Sign In / Create Account');
      expect(id.tr('Sign In / Create Account'), 'Masuk / Buat Akun');
    });
  });
}
