import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/app.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/core/theme.dart';
import 'package:wall_o_pay/data/cloud.dart';
import 'package:wall_o_pay/data/app_database.dart';
import 'package:wall_o_pay/data/prefs.dart';
import 'package:wall_o_pay/data/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('id');
  });

  Future<void> pumpHomeShellAtSize(
    WidgetTester tester,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    AppLocale.code = 'en';
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
          firebaseReadyProvider.overrideWithValue(false),
          currentUserProvider.overrideWithValue(null),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          locale: const Locale('en'),
          supportedLocales: AppLocale.supported,
          localizationsDelegates: [
            AppStrings.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: const HomeShell(),
        ),
      ),
    );

    // Advance past HomeShell's 1500ms delayed update check so no pending timers remain.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
  }

  Future<void> unmountAndFlush(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('HomeShell Responsive Layout Tests', () {
    testWidgets('Portrait phone uses BottomAppBar and omits NavigationRail', (tester) async {
      await pumpHomeShellAtSize(tester, const Size(390, 844));

      expect(find.byType(BottomAppBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      await unmountAndFlush(tester);
    });

    testWidgets('Landscape phone uses compact NavigationRail without BottomAppBar', (tester) async {
      await pumpHomeShellAtSize(tester, const Size(844, 390));

      expect(find.byType(BottomAppBar), findsNothing);
      final railFinder = find.byType(NavigationRail);
      expect(railFinder, findsOneWidget);
      final rail = tester.widget<NavigationRail>(railFinder);
      expect(rail.extended, isFalse);

      await unmountAndFlush(tester);
    });

    testWidgets('Tablet uses extended NavigationRail without BottomAppBar', (tester) async {
      await pumpHomeShellAtSize(tester, const Size(1024, 768));

      expect(find.byType(BottomAppBar), findsNothing);
      final railFinder = find.byType(NavigationRail);
      expect(railFinder, findsOneWidget);
      final rail = tester.widget<NavigationRail>(railFinder);
      expect(rail.extended, isTrue);

      await unmountAndFlush(tester);
    });
  });
}
