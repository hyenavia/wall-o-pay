import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/core/theme.dart';
import 'package:wall_o_pay/data/lock.dart';
import 'package:wall_o_pay/data/prefs.dart';
import 'package:wall_o_pay/data/share_service.dart';
import 'package:wall_o_pay/features/security/lock_screen.dart';

class _MountTracker extends StatefulWidget {
  const _MountTracker({required this.onMount, required this.onDispose});

  final VoidCallback onMount;
  final VoidCallback onDispose;

  @override
  State<_MountTracker> createState() => _MountTrackerState();
}

class _MountTrackerState extends State<_MountTracker> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('UnlockedHomeShell'));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const shareChannel = MethodChannel('com.example.wall_o_pay/share');
  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  const localAuthChannel = MethodChannel('plugins.flutter.io/local_auth');

  group('Batch 1 — LockGate & Security Lifecycle Tests', () {
    late SharedPreferences prefs;
    late Map<String, String> secureStore;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      secureStore = <String, String>{};
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorageChannel, (call) async {
        final args = (call.arguments as Map?)?.cast<dynamic, dynamic>() ?? const {};
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
      Lock.instance.bypassForQuickAction.value = false;
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(shareChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorageChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(localAuthChannel, null);
      await Lock.instance.clearLocal('guest');
      await Lock.instance.clearLocal('uid_with_pin');
      await Lock.instance.clearLocal('uid_legacy');
      await Lock.instance.loadForUser(null);
      Lock.instance.bypassForQuickAction.value = false;
    });

    Widget wrapGate(Widget child) {
      return ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
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
          home: child,
        ),
      );
    }

    testWidgets(
      'LockGate does not mount child while locked and mounts only after PIN unlock',
      (tester) async {
        await tester.runAsync(() => Lock.instance.setPin('123456'));

        var mountCount = 0;
        var disposeCount = 0;

        await tester.pumpWidget(
          wrapGate(
            LockGate(
              child: _MountTracker(
                onMount: () => mountCount++,
                onDispose: () => disposeCount++,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(mountCount, 0);
        expect(Lock.instance.isLocked.value, isTrue);
        expect(find.text('UnlockedHomeShell'), findsNothing);
        expect(find.text('Enter your 6-digit PIN'), findsOneWidget);

        for (final digit in ['1', '2', '3', '4', '5', '6']) {
          await tester.tap(find.text(digit).last);
          await tester.pump();
        }

        expect(mountCount, 1);
        expect(disposeCount, 0);
        expect(Lock.instance.isLocked.value, isFalse);
        expect(find.text('UnlockedHomeShell'), findsOneWidget);

        // Unmounting LockGate cleans up isLocked state safely.
        await tester.pumpWidget(const SizedBox.shrink());
        expect(Lock.instance.isLocked.value, isFalse);
      },
    );

    testWidgets(
      'LockGate keeps unlocked when user creates PIN interactively via setPin',
      (tester) async {
        var mountCount = 0;

        await tester.pumpWidget(
          wrapGate(
            LockGate(
              child: _MountTracker(
                onMount: () => mountCount++,
                onDispose: () {},
              ),
            ),
          ),
        );
        await tester.pump();

        expect(mountCount, 1);
        expect(Lock.instance.isLocked.value, isFalse);

        await tester.runAsync(() => Lock.instance.setPin('654321'));
        await tester.pump();

        expect(Lock.instance.state.value.enabled, isTrue);
        expect(Lock.instance.isLocked.value, isFalse);
        expect(find.text('UnlockedHomeShell'), findsOneWidget);
      },
    );

    testWidgets(
      'LockGate locks when switching to a uid that already has local PIN',
      (tester) async {
        // Pre-seed a PIN for uid_with_pin, then switch active state back to guest (no PIN).
        await tester.runAsync(() async {
          await Lock.instance.ensureLocalLoaded('uid_with_pin');
          await Lock.instance.setPin('246810');
          await Lock.instance.ensureLocalLoaded(null);
        });
        expect(Lock.instance.state.value.enabled, isFalse);

        var mountCount = 0;

        await tester.pumpWidget(
          wrapGate(
            LockGate(
              key: const ValueKey('uid_with_pin'),
              uid: 'uid_with_pin',
              child: _MountTracker(
                onMount: () => mountCount++,
                onDispose: () {},
              ),
            ),
          ),
        );

        // Resolving local lock must hold off child mount and transition to locked.
        expect(mountCount, 0);
        expect(Lock.instance.isLocked.value, isTrue);

        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump();
        await tester.pump();
        expect(mountCount, 0);
        expect(Lock.instance.isLocked.value, isTrue);
        expect(find.text('Enter your 6-digit PIN'), findsOneWidget);
      },
    );

    testWidgets(
      'LockGate auto-locks on resume after delayMin timeout and unmounts child',
      (tester) async {
        await tester.runAsync(() async {
          await Lock.instance.setPin('123456');
          await Lock.instance.setDelay(0); // 3s grace
        });

        var mountCount = 0;
        var disposeCount = 0;

        await tester.pumpWidget(
          wrapGate(
            LockGate(
              child: _MountTracker(
                onMount: () => mountCount++,
                onDispose: () => disposeCount++,
              ),
            ),
          ),
        );
        await tester.pump();

        for (final digit in ['1', '2', '3', '4', '5', '6']) {
          await tester.tap(find.text(digit).last);
          await tester.pump();
        }
        expect(mountCount, 1);
        expect(disposeCount, 0);
        expect(Lock.instance.isLocked.value, isFalse);

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3100)));
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();

        expect(Lock.instance.isLocked.value, isTrue);
        expect(disposeCount, 1);
        expect(find.text('UnlockedHomeShell'), findsNothing);
        expect(find.text('Enter your 6-digit PIN'), findsOneWidget);
      },
    );

    test('ShareService.preloadInitialData keeps bypassForQuickAction false', () async {
      ShareService.resetForTesting();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(shareChannel, (call) async {
        if (call.method == 'consumeSharedData') {
          return <String, dynamic>{'shortcutType': 'expense'};
        }
        if (call.method == 'getSharedData') {
          return <String, dynamic>{'shortcutType': 'expense'};
        }
        if (call.method == 'clearSharedData') {
          return true;
        }
        return null;
      });

      await ShareService.preloadInitialData();

      expect(ShareService.hasPendingShortcut, isTrue);
      expect(Lock.instance.bypassForQuickAction.value, isFalse);
      ShareService.resetForTesting();
    });

    test('Lock awaits legacy SharedPreferences migration before reading secrets', () async {
      SharedPreferences.setMockInitialValues({
        'lock.hash': 'legacy_hash_value',
        'lock.salt': 'legacy_salt_value',
        'lock.delay': 5,
      });
      prefs = await SharedPreferences.getInstance();

      await Lock.instance.loadForUser('uid_legacy');

      expect(prefs.getString('lock.hash'), isNull);
      expect(prefs.getString('lock.salt'), isNull);
      expect(prefs.getInt('lock.delay'), isNull);
      expect(secureStore['lock.hash.uid_legacy'], 'legacy_hash_value');
      expect(secureStore['lock.salt.uid_legacy'], 'legacy_salt_value');
      expect(prefs.getInt('lock.delay.uid_legacy'), 5);
      expect(Lock.instance.state.value.enabled, isTrue);
      expect(Lock.instance.state.value.delayMin, 5);
    });
  });
}
