import 'dart:io';

import 'package:drift/native.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/core/theme.dart';
import 'package:wall_o_pay/data/app_database.dart';
import 'package:wall_o_pay/data/cloud.dart';
import 'package:wall_o_pay/data/export_service.dart';
import 'package:wall_o_pay/data/lock.dart';
import 'package:wall_o_pay/data/prefs.dart';
import 'package:wall_o_pay/data/profile.dart';
import 'package:wall_o_pay/data/providers.dart';
import 'package:wall_o_pay/data/tables.dart';
import 'package:wall_o_pay/data/update_checker.dart';
import 'package:wall_o_pay/features/security/lock_screen.dart';

class _FakeUser extends Fake implements User {
  _FakeUser(this.uid);
  @override
  final String uid;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  const localAuthChannel = MethodChannel('plugins.flutter.io/local_auth');

  group('Threat Model Security Remediation Tests (TM-01 .. TM-14)', () {
    late SharedPreferences prefs;
    late Map<String, String> secureStore;
    late AppDatabase db;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      secureStore = <String, String>{};
      db = AppDatabase(NativeDatabase.memory());

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorageChannel, (call) async {
        final args =
            (call.arguments as Map?)?.cast<dynamic, dynamic>() ?? const {};
        final key = args['key'] as String?;
        switch (call.method) {
          case 'read':
            return key == null ? null : secureStore[key];
          case 'write':
            if (key != null && args['value'] != null) {
              secureStore[key] = args['value'] as String;
            }
            return null;
          case 'delete':
            if (key != null) secureStore.remove(key);
            return null;
          case 'deleteAll':
            secureStore.clear();
            return null;
          case 'readAll':
            return Map<String, String>.from(secureStore);
          default:
            return null;
        }
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(localAuthChannel, (call) async {
        if (call.method == 'getAvailableBiometrics') return <String>[];
        return false;
      });
      await Lock.instance.load();
      await Lock.instance.clearLocal('guest');
      await Lock.instance.clearLocal('user-sec-1');
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorageChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(localAuthChannel, null);
      await Lock.instance.clearLocal('guest');
      await Lock.instance.clearLocal('user-sec-1');
      await db.close();
    });

    testWidgets(
      'TM-01: Forgot PIN -> Log Out wipes local SQLite database, profile, and sync cursor for logged-in user',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.runAsync(() async {
          await prefs.setString('current_sync_user_id', 'user-sec-1');
          await prefs.setInt('sync_pull_cursor_user-sec-1', 123456789);
          await prefs.setString('nickname_user-sec-1', 'SecretUser');
          await db.addTransaction(
            amount: 950000,
            type: TxType.expense,
            categoryId: 'cat-exp-food',
            date: DateTime(2026, 11, 20),
            note: 'Confidential Dinner',
          );
          await Lock.instance.ensureLocalLoaded('user-sec-1');
          await Lock.instance.setPin('123456');
        });

        expect((await tester.runAsync(db.allActiveTransactions))?.length, 1);
        expect(Lock.instance.state.value.enabled, isTrue);

        var unlockedCalled = false;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              databaseProvider.overrideWithValue(db),
              currentUserProvider.overrideWithValue(_FakeUser('user-sec-1')),
            ],
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
              home: LockScreen(onUnlock: () => unlockedCalled = true),
            ),
          ),
        );
        await tester.pump();

        // Tap "Forgot PIN?" and confirm "Log Out" inside runAsync so real SQLite I/O completes
        await tester.tap(find.text('Forgot PIN?'));
        await tester.pumpAndSettle();
        expect(find.text('Log Out'), findsOneWidget);

        await tester.tap(find.text('Log Out'));
        await tester.pump();
        for (var i = 0; i < 10 && !unlockedCalled; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          await tester.pump();
        }
        await tester.pumpAndSettle();

        expect(unlockedCalled, isTrue);
        final remainingTxs =
            await tester.runAsync(db.allActiveTransactions) ?? const [];
        expect(remainingTxs, isEmpty);
        expect(prefs.getString('current_sync_user_id'), isNull);
        expect(prefs.getInt('sync_pull_cursor_user-sec-1'), isNull);
        expect(prefs.getString('nickname_user-sec-1'), isNull);
        expect(secureStore['lock.hash.user-sec-1'], isNull);
        expect(
          prefs.getBool('pending_pin_reset_after_auth_user-sec-1'),
          isTrue,
        );
      },
    );

    test(
      'TM-03: ExportService.buildCsvContent neutralizes formula injection prefixes (=, +, -, @, tab, CR)',
      () async {
        final now = DateTime(2026, 11, 21);
        final cats = {
          'cat-exp-food': Category(
            id: 'cat-exp-food',
            name: '=HYPERLINK("http://evil.tld","Food")',
            type: TxType.expense,
            icon: 'restaurant',
            colorValue: 0xFFEF6C00,
            createdAt: now,
            updatedAt: now,
          ),
        };
        final wallets = {
          'wallet-main': Wallet(
            id: 'wallet-main',
            name: '@SUM(A1:A10)',
            type: 'bank',
            initialBalance: 0,
            icon: 'account_balance',
            colorValue: 0xFF1E4238,
            createdAt: now,
            updatedAt: now,
          ),
        };
        final rows = [
          TransactionEntry(
            id: 'tx-formula-1',
            amount: 50000,
            type: TxType.expense,
            categoryId: 'cat-exp-food',
            walletId: 'wallet-main',
            date: now,
            note: '=cmd|\' /C calc\'!A0',
            createdAt: now,
            updatedAt: now,
          ),
          TransactionEntry(
            id: 'tx-formula-2',
            amount: 25000,
            type: TxType.expense,
            categoryId: 'cat-exp-food',
            walletId: 'wallet-main',
            date: now,
            note: '  -2+3+cmd|\' /C notepad\'!A0',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final csv = ExportService.buildCsvContent(
          rows: rows,
          categories: cats,
          wallets: wallets,
        );

        expect(csv, contains('"\'=HYPERLINK(""http://evil.tld"",""Food"")"'));
        expect(csv, contains('"\'@SUM(A1:A10)"'));
        expect(csv, contains('"\'=cmd|\' /C calc\'!A0"'));
        expect(csv, contains('"\'  -2+3+cmd|\' /C notepad\'!A0"'));
      },
    );

    test(
      'TM-05 & TM-13: Lock stores lockout counters in FlutterSecureStorage and guards against backward clock rollback',
      () async {
        await Lock.instance.ensureLocalLoaded('user-sec-1');
        await Lock.instance.setPin('654321');

        for (var i = 0; i < 4; i++) {
          expect(Lock.instance.verify('000000'), isFalse);
          expect(Lock.instance.isLockedOut, isFalse);
        }
        // Fails count is stored in secureStore, not plaintext SharedPreferences
        expect(secureStore['lock.fails.user-sec-1'], '4');
        expect(prefs.getInt('lock.fails.user-sec-1'), isNull);

        // 5th failure triggers lockout tier 1 (30s)
        expect(Lock.instance.verify('000000'), isFalse);
        expect(Lock.instance.isLockedOut, isTrue);
        expect(secureStore['lock.lockoutTier.user-sec-1'], '1');
        expect(secureStore['lock.lockoutUntil.user-sec-1'], isNotNull);
        expect(prefs.getInt('lock.lockoutUntil.user-sec-1'), isNull);

        // Simulate backward clock tampering (lockoutUntil is suddenly 2 hours in the future relative to wall clock)
        final farFutureMs = DateTime.now()
            .add(const Duration(hours: 2))
            .millisecondsSinceEpoch;
        secureStore['lock.lockoutUntil.user-sec-1'] = farFutureMs.toString();
        await Lock.instance.ensureLocalLoaded('user-sec-1');

        // remainingLockoutSeconds must be clamped to <= 300s (5 minutes max tier)
        expect(Lock.instance.remainingLockoutSeconds, lessThanOrEqualTo(300));
        expect(Lock.instance.remainingLockoutSeconds, greaterThan(250));
      },
    );

    test(
      'TM-09: clampRemoteUpdatedAt, applyRemote validation, and isSafeReceiptDeletionPath prevent poisoning & arbitrary file delete',
      () async {
        final now = DateTime(2026, 11, 21, 12, 0);
        final poisonedFuture = DateTime(2099, 1, 1);
        final clamped =
            AppDatabase.clampRemoteUpdatedAt(poisonedFuture, now: now);
        expect(clamped, now);

        // applyRemote clamps far-future updatedAt, strips unsafe .sqlite receiptPath, and rejects negative amount
        final txSync =
            db.syncTables.firstWhere((t) => t.name == 'transactions');
        final rejectedNegative = await txSync.applyRemote({
          'id': 'tx-neg',
          'amount': -50000,
          'type': 'expense',
          'categoryId': 'cat-exp-food',
          'note': 'Negative',
          'date': now.millisecondsSinceEpoch,
          'walletId': 'wallet-main',
          'toWalletId': null,
          'receiptPath': null,
          'needWant': null,
          'createdAt': now.millisecondsSinceEpoch,
          'updatedAt': now.millisecondsSinceEpoch,
          'deletedAt': null,
        });
        expect(rejectedNegative, isFalse);

        final appliedPoisoned = await txSync.applyRemote({
          'id': 'tx-poison',
          'amount': 75000,
          'type': 'expense',
          'categoryId': 'cat-exp-food',
          'note': 'Poisoned receipt & timestamp',
          'date': now.millisecondsSinceEpoch,
          'walletId': 'wallet-main',
          'toWalletId': null,
          'receiptPath': '/data/user/0/com.example.wall_o_pay/databases/wall_o_pay.sqlite',
          'needWant': null,
          'createdAt': now.millisecondsSinceEpoch,
          'updatedAt': poisonedFuture.millisecondsSinceEpoch,
          'deletedAt': null,
        });
        expect(appliedPoisoned, isTrue);

        final saved = (await db.allActiveTransactions()).single;
        expect(saved.id, 'tx-poison');
        expect(saved.receiptPath, isNull);
        expect(
          saved.updatedAt.isBefore(DateTime.now().add(const Duration(minutes: 1))),
          isTrue,
        );

        // Verify isSafeReceiptDeletionPath blocks deleting arbitrary files outside allowed receipt/cache directories
        final tempRoot = Directory.systemTemp.createTempSync('wop_sec_test_');
        addTearDown(() {
          if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
        });
        final allowedReceiptsDir = Directory('${tempRoot.path}/shared_receipts')
          ..createSync(recursive: true);
        final otherDbDir = Directory('${tempRoot.path}/databases')
          ..createSync(recursive: true);

        final safeReceiptFile =
            File('${allowedReceiptsDir.path}/receipt_123.jpg');
        final sensitiveDbFile = File('${otherDbDir.path}/wall_o_pay.sqlite');
        final xmlPrefFile =
            File('${allowedReceiptsDir.path}/shared_prefs.xml');

        expect(
          AppDatabase.isSafeReceiptDeletionPath(
            safeReceiptFile.path,
            allowedParentDirs: [allowedReceiptsDir.path],
          ),
          isTrue,
        );
        expect(
          AppDatabase.isSafeReceiptDeletionPath(
            sensitiveDbFile.path,
            allowedParentDirs: [allowedReceiptsDir.path],
          ),
          isFalse,
        );
        expect(
          AppDatabase.isSafeReceiptDeletionPath(
            xmlPrefFile.path,
            allowedParentDirs: [allowedReceiptsDir.path],
          ),
          isFalse,
        );
      },
    );

    test(
      'TM-12 & TM-14: UpdateCheckerService.isTrustedReleaseUrl and ProfileController.maxPhotoBase64Length enforce bounds',
      () {
        expect(
          UpdateCheckerService.isTrustedReleaseUrl(
            'https://github.com/hyenavia/wall-o-pay/releases/latest/download/Wall_o_Pay.apk',
          ),
          isTrue,
        );
        expect(
          UpdateCheckerService.isTrustedReleaseUrl(
            'https://objects.githubusercontent.com/github-production-release-asset/Wall_o_Pay.apk',
          ),
          isTrue,
        );
        expect(
          UpdateCheckerService.isTrustedReleaseUrl(
            'http://github.com/hyenavia/wall-o-pay/releases/latest/download/Wall_o_Pay.apk',
          ),
          isFalse,
        );
        expect(
          UpdateCheckerService.isTrustedReleaseUrl(
            'https://evil.example.com/Wall_o_Pay.apk',
          ),
          isFalse,
        );
        expect(
          UpdateCheckerService.isTrustedReleaseUrl(
            'https://github.com/other-user/other-repo/releases/download/v1.0/app.apk',
          ),
          isFalse,
        );

        expect(ProfileController.maxPhotoBase64Length, 800000);
      },
    );
  });
}
