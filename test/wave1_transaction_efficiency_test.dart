import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/core/format.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/core/theme.dart';
import 'package:wall_o_pay/data/app_database.dart';
import 'package:wall_o_pay/data/feature_providers.dart';
import 'package:wall_o_pay/data/prefs.dart';
import 'package:wall_o_pay/data/providers.dart';
import 'package:wall_o_pay/data/tables.dart';
import 'package:wall_o_pay/data/transaction_parser.dart';
import 'package:wall_o_pay/features/transactions/transaction_form.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('id');
  });

  group('Wave 1 — Transaction Efficiency Tests', () {
    test('compactRupiah formats amounts cleanly in ID and EN locales', () {
      AppLocale.code = 'id';
      expect(compactRupiah(1500000), 'Rp 1,5jt');
      expect(compactRupiah(2000000), 'Rp 2jt');
      expect(compactRupiah(250000), 'Rp 250rb');
      expect(compactRupiah(5000), 'Rp 5.000');

      AppLocale.code = 'en';
      expect(compactRupiah(1500000), 'Rp 1.5M');
      expect(compactRupiah(250000), 'Rp 250K');
      expect(compactRupiah(-500000), '-Rp 500K');
    });

    test('resolveTransferWallets picks non-colliding default source and destination', () {
      final now = DateTime.now();
      final wallets = [
        Wallet(
          id: 'w1',
          name: 'Main Account',
          type: 'bank',
          icon: 'bank',
          colorValue: 0xFF1565C0,
          initialBalance: 500000,
          createdAt: now,
          updatedAt: now,
        ),
        Wallet(
          id: 'w2',
          name: 'Digital Bank',
          type: 'digital',
          icon: 'digital',
          colorValue: 0xFF00897B,
          initialBalance: 100000,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final defaults = resolveTransferWallets(wallets);
      expect(defaults.fromId, 'w1');
      expect(defaults.toId, 'w2');

      final swapped = resolveTransferWallets(wallets, walletId: 'w2');
      expect(swapped.fromId, 'w2');
      expect(swapped.toId, 'w1');

      final single = resolveTransferWallets([wallets.first]);
      expect(single.fromId, 'w1');
      expect(single.toId, isNull);
    });

    test('TransactionParser.parseSharedText extracts type, categoryId, amount, and clean note', () {
      final expense = TransactionParser.parseSharedText(
        'Transaksi GoPay di Kopi Kenangan sebesar Rp 28.000 berhasil',
      );
      expect(expense.amount, 28000);
      expect(expense.type, TxType.expense);
      expect(expense.sourceApp, 'GoPay');
      expect(expense.categoryId, 'cat-exp-food');
      expect(expense.note, '[GoPay] Kopi Kenangan');

      final income = TransactionParser.parseSharedText(
        'Transfer masuk BCA sebesar IDR 500.000 dari Budi',
      );
      expect(income.amount, 500000);
      expect(income.type, TxType.income);
      expect(income.sourceApp, 'BCA');
      expect(income.categoryId, 'cat-inc-other');
      expect(income.note, 'Transaksi BCA');
    });

    testWidgets('Transfer saves with default selected wallets without re-tapping chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      AppLocale.code = 'en';
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => tester.runAsync(db.close));

      final seededWallets = await tester.runAsync(() => db.watchWallets().first) ?? const [];
      final seededCats = await tester.runAsync(() => db.watchCategories().first) ?? const [];
      expect(seededWallets.length, greaterThanOrEqualTo(2));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
            walletsProvider.overrideWithValue(AsyncData(seededWallets)),
            categoriesProvider.overrideWithValue(AsyncData(seededCats)),
            templatesProvider.overrideWithValue(const AsyncData([])),
            walletBalancesProvider.overrideWithValue({
              seededWallets[0].id: 1500000,
              seededWallets[1].id: 250000,
            }),
          ],
          child: MaterialApp(
            theme: buildTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showTransactionForm(
                    context,
                    initialType: TxType.transfer,
                  ),
                  child: const Text('Open Form'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Form'));
      await tester.pumpAndSettle();

      // Wallet chip balances are shown inline on the form chips.
      expect(find.text('Rp 1.5M'), findsNWidgets(2));
      expect(find.text('Rp 250K'), findsNWidgets(2));

      // Enter transfer amount without touching wallet chips and submit.
      await tester.enterText(find.byType(TextField).first, '100000');
      await tester.runAsync(() async {
        await tester.tap(find.text('Transfer Funds'));
      });
      await tester.pumpAndSettle();

      final txs = await tester.runAsync(db.allActiveTransactions) ?? const [];
      expect(txs.length, 1);
      expect(txs.first.type, TxType.transfer);
      expect(txs.first.amount, 100000);
      expect(txs.first.walletId, seededWallets[0].id);
      expect(txs.first.toWalletId, seededWallets[1].id);

      // Unmount ProviderScope & flush Drift StreamQueryStore.markAsClosed zero-timers.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });

    testWidgets('Wallet chip balances are hidden when hideBalance is enabled & Save as template is visible', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      AppLocale.code = 'en';
      SharedPreferences.setMockInitialValues({'pref_hide_balance': true});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => tester.runAsync(db.close));

      final seededWallets = await tester.runAsync(() => db.watchWallets().first) ?? const [];
      final seededCats = await tester.runAsync(() => db.watchCategories().first) ?? const [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
            walletsProvider.overrideWithValue(AsyncData([seededWallets.first])),
            categoriesProvider.overrideWithValue(AsyncData(seededCats)),
            templatesProvider.overrideWithValue(const AsyncData([])),
            walletBalancesProvider.overrideWithValue({seededWallets.first.id: 1500000}),
          ],
          child: MaterialApp(
            theme: buildTheme(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: TransactionForm(
                  initialType: TxType.expense,
                  initialAmount: 35000,
                  initialCategoryId: 'cat-exp-food',
                  initialNote: 'Lunch',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rp 1.5M'), findsNothing);
      expect(find.text('Save as template'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
    });

    testWidgets('Duplicate helper prefills a fresh transaction form for today', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      AppLocale.code = 'en';
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => tester.runAsync(db.close));

      final seededWallets = await tester.runAsync(() => db.watchWallets().first) ?? const [];
      final seededCats = await tester.runAsync(() => db.watchCategories().first) ?? const [];
      final oldDate = DateTime(2025, 1, 15);
      final oldEntry = TransactionEntry(
        id: 'tx-old',
        amount: 45000,
        type: TxType.expense,
        categoryId: 'cat-exp-food',
        note: 'Nasi Goreng',
        date: oldDate,
        walletId: seededWallets.first.id,
        toWalletId: null,
        receiptPath: null,
        needWant: NeedWant.need,
        createdAt: oldDate,
        updatedAt: oldDate,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
            walletsProvider.overrideWithValue(AsyncData(seededWallets)),
            categoriesProvider.overrideWithValue(AsyncData(seededCats)),
            templatesProvider.overrideWithValue(const AsyncData([])),
            walletBalancesProvider.overrideWithValue({
              for (final w in seededWallets) w.id: 500000,
            }),
          ],
          child: MaterialApp(
            theme: buildTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => showDuplicateTransactionForm(context, oldEntry),
                      child: const Text('Duplicate'),
                    ),
                    ElevatedButton(
                      onPressed: () => showTransactionForm(context, entry: oldEntry),
                      child: const Text('Edit'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();

      expect(find.text('Add transaction'), findsOneWidget);
      expect(find.text('45.000'), findsOneWidget);
      expect(find.text('Nasi Goreng'), findsOneWidget);

      // Dismiss duplicated sheet and verify Edit header duplicate icon works too.
      Navigator.of(tester.element(find.text('Add transaction'))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit transaction'), findsOneWidget);
      await tester.tap(find.byTooltip('Record again'));
      await tester.pumpAndSettle();

      expect(find.text('Add transaction'), findsOneWidget);
      expect(find.text('45.000'), findsOneWidget);
      expect(find.text('Nasi Goreng'), findsOneWidget);
    });
  });
}
