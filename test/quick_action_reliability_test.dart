import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/core/theme.dart';
import 'package:wall_o_pay/data/app_database.dart';
import 'package:wall_o_pay/data/feature_providers.dart';
import 'package:wall_o_pay/data/lock.dart';
import 'package:wall_o_pay/data/prefs.dart';
import 'package:wall_o_pay/data/providers.dart';
import 'package:wall_o_pay/data/share_service.dart';
import 'package:wall_o_pay/features/transactions/transaction_form.dart';

class _TestHost extends ConsumerStatefulWidget {
  const _TestHost();

  @override
  ConsumerState<_TestHost> createState() => _TestHostState();
}

class _TestHostState extends ConsumerState<_TestHost> {
  @override
  void initState() {
    super.initState();
    ShareService.initialize(context, ref);
  }

  @override
  void dispose() {
    ShareService.detachContext(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('HostReady')));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const shareChannel = MethodChannel('com.example.wall_o_pay/share');

  setUp(() {
    ShareService.resetForTesting();
    Lock.instance.isLocked.value = false;
    Lock.instance.bypassForQuickAction.value = false;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, null);
    ShareService.resetForTesting();
    Lock.instance.isLocked.value = false;
    Lock.instance.bypassForQuickAction.value = false;
  });

  Future<Object?> simulateNativeOnShareReceived(
    Map<String, dynamic> payload,
  ) async {
    const codec = StandardMethodCodec();
    final encoded = codec.encodeMethodCall(
      MethodCall('onShareReceived', payload),
    );
    Object? decodedResult;
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(shareChannel.name, encoded, (ByteData? reply) {
          if (reply != null) {
            decodedResult = codec.decodeEnvelope(reply);
          }
        });
    return decodedResult;
  }

  group('Batch 4 — Quick Action & Cold/Warm Start Shortcut Reliability Tests', () {
    test(
      'preloadInitialData uses atomic consumeSharedData and deduplicates adjacent shortcuts',
      () async {
        var consumedCount = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(shareChannel, (call) async {
          if (call.method == 'consumeSharedData') {
            consumedCount++;
            return consumedCount == 1
                ? <String, dynamic>{'shortcutType': 'expense'}
                : null;
          }
          return null;
        });

        await ShareService.preloadInitialData();
        expect(consumedCount, 1);
        expect(ShareService.hasPendingShortcut, isTrue);
        expect(ShareService.pendingQueueLength, 1);
        expect(Lock.instance.bypassForQuickAction.value, isFalse);

        // Simulasikan shortcut expense duplikat yang tiba berturut-turut sebelum antrean dikosongkan
        final ack = await simulateNativeOnShareReceived({'shortcutType': 'expense'});
        expect(ack, isTrue);
        expect(ShareService.pendingQueueLength, 1);
      },
    );

    testWidgets(
      'SHORTCUT_EXPENSE queues while locked and opens expense form once unlocked',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(() => tester.runAsync(db.close));

        final seededWallets =
            await tester.runAsync(() => db.watchWallets().first) ?? const [];
        final seededCats =
            await tester.runAsync(() => db.watchCategories().first) ?? const [];

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(shareChannel, (call) async {
          if (call.method == 'consumeSharedData') {
            return <String, dynamic>{'shortcutType': 'expense'};
          }
          return null;
        });

        await ShareService.preloadInitialData();
        expect(ShareService.hasPendingShortcut, isTrue);

        // Aplikasi terkunci: form tidak boleh terbuka lebih dulu
        Lock.instance.isLocked.value = true;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              databaseProvider.overrideWithValue(db),
              walletsProvider.overrideWithValue(AsyncData(seededWallets)),
              categoriesProvider.overrideWithValue(AsyncData(seededCats)),
              templatesProvider.overrideWithValue(const AsyncData([])),
              walletBalancesProvider.overrideWithValue(const {}),
            ],
            child: MaterialApp(
              theme: buildTheme(),
              localizationsDelegates: const [
                AppStrings.delegate,
                GlobalMaterialLocalizations.delegate,
              ],
              supportedLocales: AppLocale.supported,
              home: const _TestHost(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(TransactionForm), findsNothing);
        expect(ShareService.pendingQueueLength, 1);

        // Saat kunci dibuka, SHORTCUT_EXPENSE langsung diproses membuka form transaksi
        Lock.instance.isLocked.value = false;
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(TransactionForm), findsOneWidget);
        expect(ShareService.pendingQueueLength, 0);

        Navigator.of(tester.element(find.byType(TransactionForm))).pop();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Warm-start onShareReceived queues multiple distinct shortcuts and drains sequentially without dropping',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(() => tester.runAsync(db.close));

        final seededWallets =
            await tester.runAsync(() => db.watchWallets().first) ?? const [];
        final seededCats =
            await tester.runAsync(() => db.watchCategories().first) ?? const [];

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(shareChannel, (call) async => null);

        await ShareService.preloadInitialData();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              databaseProvider.overrideWithValue(db),
              walletsProvider.overrideWithValue(AsyncData(seededWallets)),
              categoriesProvider.overrideWithValue(AsyncData(seededCats)),
              templatesProvider.overrideWithValue(const AsyncData([])),
              walletBalancesProvider.overrideWithValue(const {}),
            ],
            child: MaterialApp(
              theme: buildTheme(),
              localizationsDelegates: const [
                AppStrings.delegate,
                GlobalMaterialLocalizations.delegate,
              ],
              supportedLocales: AppLocale.supported,
              home: const _TestHost(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Terima SHORTCUT_EXPENSE lalu SHORTCUT_INCOME hampir bersamaan
        final res1 = await simulateNativeOnShareReceived({'shortcutType': 'expense'});
        final res2 = await simulateNativeOnShareReceived({'shortcutType': 'income'});
        expect(res1, isTrue);
        expect(res2, isTrue);

        // Item pertama terbuka di frame berikutnya
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.byType(TransactionForm), findsOneWidget);
        expect(ShareService.pendingQueueLength, 1);

        // Tutup modal pertama -> item kedua (income) langsung diproses dari antrean
        Navigator.of(tester.element(find.byType(TransactionForm))).pop();
        await tester.pumpAndSettle();

        expect(find.byType(TransactionForm), findsOneWidget);
        expect(ShareService.pendingQueueLength, 0);

        Navigator.of(tester.element(find.byType(TransactionForm))).pop();
        await tester.pumpAndSettle();
      },
    );
  });
}
