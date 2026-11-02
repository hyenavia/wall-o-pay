import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/data/app_database.dart';
import 'package:wall_o_pay/data/prefs.dart';
import 'package:wall_o_pay/data/providers.dart';
import 'package:wall_o_pay/features/accounts/accounts_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Account Categories & Grouping Tests', () {
    test('Localization for account categories in en and id', () {
      AppLocale.code = 'en';
      expect(trG('Commercial Bank'), 'Commercial Bank');
      expect(trG('Digital Bank'), 'Digital Bank');
      expect(trG('E-Wallet'), 'E-Wallet');
      expect(trG('Cash'), 'Cash');

      AppLocale.code = 'id';
      expect(trG('Commercial Bank'), 'Bank Konvensional');
      expect(trG('Digital Bank'), 'Bank Digital');
      expect(trG('E-Wallet'), 'E-Wallet');
      expect(trG('Cash'), 'Tunai');
    });

    testWidgets('AccountsPage renders categorized headers with subtotals and counts', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      AppLocale.code = 'en';
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final now = DateTime.now();
      final testWallets = [
        Wallet(id: 'w1', name: 'BCA', type: 'bank', icon: 'account_balance', colorValue: 0xFF1565C0, initialBalance: 1500000, createdAt: now, updatedAt: now),
        Wallet(id: 'w2', name: 'Mandiri', type: 'bank', icon: 'account_balance', colorValue: 0xFF1E88E5, initialBalance: 500000, createdAt: now, updatedAt: now),
        Wallet(id: 'w3', name: 'SeaBank', type: 'digital', icon: 'devices', colorValue: 0xFFF57C00, initialBalance: 300000, createdAt: now, updatedAt: now),
        Wallet(id: 'w4', name: 'GoPay', type: 'ewallet', icon: 'wallet', colorValue: 0xFF00897B, initialBalance: 50000, createdAt: now, updatedAt: now),
        Wallet(id: 'w5', name: 'Tunai Dompet', type: 'cash', icon: 'payments', colorValue: 0xFF2E7D32, initialBalance: 20000, createdAt: now, updatedAt: now),
      ];

      final balances = {
        'w1': 1500000,
        'w2': 500000,
        'w3': 300000,
        'w4': 50000,
        'w5': 20000,
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            walletsProvider.overrideWithValue(AsyncData(testWallets)),
            walletBalancesProvider.overrideWithValue(balances),
            totalCurrentBalanceProvider.overrideWithValue(2370000),
            transactionsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocale.supported,
            localizationsDelegates: [AppStrings.delegate],
            home: AccountsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify category headers are rendered
      expect(find.text('Commercial Bank'), findsWidgets);
      expect(find.text('Digital Bank'), findsWidgets);
      expect(find.text('E-Wallet'), findsWidgets);
      expect(find.text('Cash'), findsWidgets);

      // Verify account names
      expect(find.text('BCA'), findsOneWidget);
      expect(find.text('Mandiri'), findsOneWidget);
      expect(find.text('SeaBank'), findsOneWidget);
      expect(find.text('GoPay'), findsOneWidget);
      expect(find.text('Tunai Dompet'), findsOneWidget);

      // Verify subtotals are present
      // Commercial Bank subtotal: 1.500.000 + 500.000 = Rp 2.000.000
      expect(find.text('Rp 2.000.000'), findsOneWidget);
      // Digital Bank subtotal: Rp 300.000
      expect(find.text('Rp 300.000'), findsWidgets);
      // E-Wallet subtotal: Rp 50.000
      expect(find.text('Rp 50.000'), findsWidgets);
      // Cash subtotal: Rp 20.000
      expect(find.text('Rp 20.000'), findsWidgets);

      // Verify no drag indicator icons exist (clean UI per Opsi A)
      expect(find.byIcon(Icons.drag_indicator_rounded), findsNothing);

      // Verify eye toggle button in HeroCard works to hide and reveal balances
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      // Amounts are now blurred via ImageFiltered instead of replaced with dots
      expect(find.byType(ImageFiltered), findsWidgets);

      // Tap again to restore balance visibility
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.text('Rp 2.000.000'), findsOneWidget);
    });
  });
}
