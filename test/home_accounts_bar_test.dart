import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/core/theme.dart';
import 'package:wall_o_pay/data/profile.dart';
import 'package:wall_o_pay/data/app_database.dart';
import 'package:wall_o_pay/data/prefs.dart';
import 'package:wall_o_pay/data/providers.dart';
import 'package:wall_o_pay/features/accounts/accounts_page.dart';
import 'package:wall_o_pay/features/home/home_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('id');
  });

  group('Home Total Balance & Accounts Quick Bar Tests', () {
    test('Localization for accounts summary in en and id', () {
      AppLocale.code = 'en';
      expect(trG('1 Account'), '1 Account');
      expect(trG('{count} Accounts', {'count': 3}), '3 Accounts');
      expect(trG('Add accounts & wallets'), 'Add accounts & wallets');

      AppLocale.code = 'id';
      expect(trG('1 Account'), '1 Akun');
      expect(trG('{count} Accounts', {'count': 3}), '3 Akun');
      expect(trG('Add accounts & wallets'), 'Tambah akun & rekening');
    });

    testWidgets('Renders Total Balance chevron and accounts quick bar with stacked avatars', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      AppLocale.code = 'en';
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final now = DateTime.now();
      final testWallets = [
        Wallet(id: 'w1', name: 'BCA', type: 'bank', icon: 'account_balance', colorValue: 0xFF1565C0, initialBalance: 1500000, createdAt: now, updatedAt: now),
        Wallet(id: 'w2', name: 'GoPay', type: 'ewallet', icon: 'wallet', colorValue: 0xFF00897B, initialBalance: 50000, createdAt: now, updatedAt: now),
        Wallet(id: 'w3', name: 'Cash', type: 'cash', icon: 'payments', colorValue: 0xFF2E7D32, initialBalance: 20000, createdAt: now, updatedAt: now),
        Wallet(id: 'w4', name: 'Mandiri', type: 'bank', icon: 'account_balance', colorValue: 0xFF1E88E5, initialBalance: 500000, createdAt: now, updatedAt: now),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            walletsProvider.overrideWithValue(AsyncData(testWallets)),
            walletBalancesProvider.overrideWithValue({'w1': 1500000, 'w2': 50000, 'w3': 20000, 'w4': 500000}),
            totalCurrentBalanceProvider.overrideWithValue(2070000),
            transactionsProvider.overrideWithValue(const AsyncData(<TransactionEntry>[])),
          ],
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Total Balance title with chevron is present
      expect(find.text('Total Balance'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);

      // Check summary bar renders 4 Accounts and wallet names
      expect(find.textContaining('4 Accounts · BCA, GoPay...'), findsOneWidget);
      // Extra badge for 4th account (+1)
      expect(find.text('+1'), findsOneWidget);

      // Tapping the accounts bar opens AccountsPage
      await tester.tap(find.textContaining('4 Accounts · BCA, GoPay...'));
      await tester.pumpAndSettle();

      expect(find.byType(AccountsPage), findsOneWidget);
    });

    testWidgets('Renders empty accounts prompt when no wallets exist', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      AppLocale.code = 'en';
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            walletsProvider.overrideWithValue(const AsyncData(<Wallet>[])),
            walletBalancesProvider.overrideWithValue(const <String, int>{}),
            totalCurrentBalanceProvider.overrideWithValue(0),
            transactionsProvider.overrideWithValue(const AsyncData(<TransactionEntry>[])),
          ],
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Add accounts & wallets'), findsOneWidget);

      // Tapping empty prompt opens AccountsPage
      await tester.tap(find.text('Add accounts & wallets'));
      await tester.pumpAndSettle();

      expect(find.byType(AccountsPage), findsOneWidget);
    });

    testWidgets('Cyberpunk mode renders 3-line header with status, cycle, and name', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            walletsProvider.overrideWithValue(const AsyncData(<Wallet>[])),
            walletBalancesProvider.overrideWithValue({}),
            totalCurrentBalanceProvider.overrideWithValue(0),
            transactionsProvider.overrideWithValue(const AsyncData(<TransactionEntry>[])),
            displayNameProvider.overrideWithValue('Olivia Adeline'),
          ],
          child: MaterialApp(
            theme: buildTheme('cyberpunk'),
            home: const HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Olivia Adeline'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) =>
            w is Text &&
            (w.data == 'BANGUN, CHOOM' ||
                w.data == 'NETRUNNER ONLINE' ||
                w.data == 'NIGHT CITY MEMANGGIL' ||
                w.data == 'WAKE UP, CHOOM' ||
                w.data == 'NIGHT CITY CALLS')),
        findsOneWidget,
      );
    });
  });
}
