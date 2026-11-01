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

  group('Wallet Ordering & Reorder Tests', () {
    test('Localization for Drag to reorder is correct in both en and id', () {
      AppLocale.code = 'en';
      expect(trG('Drag to reorder'), 'Drag to reorder');

      AppLocale.code = 'id';
      expect(trG('Drag to reorder'), 'Tahan & geser untuk urutkan');
    });

    test('reorder notifier correctly shifts items and saves to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final now = DateTime.now();
      final w1 = Wallet(id: 'w1', name: 'Cash', type: 'cash', icon: 'payments', colorValue: 0, initialBalance: 0, createdAt: now, updatedAt: now);
      final w2 = Wallet(id: 'w2', name: 'BCA', type: 'bank', icon: 'account_balance', colorValue: 0, initialBalance: 0, createdAt: now, updatedAt: now);
      final w3 = Wallet(id: 'w3', name: 'GoPay', type: 'ewallet', icon: 'wallet', colorValue: 0, initialBalance: 0, createdAt: now, updatedAt: now);

      final notifier = container.read(walletOrderProvider.notifier);

      // Reorder: Move w1 (index 0) to index 1 -> expected: [w2, w1, w3]
      await notifier.reorder(0, 1, [w1, w2, w3]);
      expect(container.read(walletOrderProvider), ['w2', 'w1', 'w3']);
      expect(prefs.getStringList('pref_wallet_order'), ['w2', 'w1', 'w3']);

      // Reorder: Move w3 (index 2) to index 0 -> expected: [w3, w2, w1]
      await notifier.reorder(2, 0, [w2, w1, w3]);
      expect(container.read(walletOrderProvider), ['w3', 'w2', 'w1']);
      expect(prefs.getStringList('pref_wallet_order'), ['w3', 'w2', 'w1']);

      // Reorder: Move w2 (index 1) to index 2 -> expected: [w3, w1, w2]
      await notifier.reorder(1, 2, [w3, w2, w1]);
      expect(container.read(walletOrderProvider), ['w3', 'w1', 'w2']);
      expect(prefs.getStringList('pref_wallet_order'), ['w3', 'w1', 'w2']);

      // Reorder: same index is a no-op
      await notifier.reorder(1, 1, [w3, w1, w2]);
      expect(container.read(walletOrderProvider), ['w3', 'w1', 'w2']);

      // Reorder: out of bounds is safely ignored
      await notifier.reorder(-1, 2, [w3, w1, w2]);
      await notifier.reorder(0, 99, [w3, w1, w2]);
      expect(container.read(walletOrderProvider), ['w3', 'w1', 'w2']);
    });

    testWidgets('AccountsPage renders SliverReorderableList with drag handles', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final now = DateTime.now();
      final testWallets = [
        Wallet(id: 'w1', name: 'My Cash', type: 'cash', icon: 'payments', colorValue: 0xFF2E7D32, initialBalance: 100000, createdAt: now, updatedAt: now),
        Wallet(id: 'w2', name: 'BCA', type: 'bank', icon: 'account_balance', colorValue: 0xFF1565C0, initialBalance: 500000, createdAt: now, updatedAt: now),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            walletsProvider.overrideWithValue(AsyncData(testWallets)),
            walletBalancesProvider.overrideWithValue({'w1': 100000, 'w2': 500000}),
            totalCurrentBalanceProvider.overrideWithValue(600000),
            transactionsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            localizationsDelegates: [AppStrings.delegate],
            home: AccountsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SliverReorderableList), findsOneWidget);
      expect(find.text('My Cash'), findsOneWidget);
      expect(find.text('BCA'), findsOneWidget);
      expect(find.byIcon(Icons.drag_indicator_rounded), findsNWidgets(2));
    });
  });
}
