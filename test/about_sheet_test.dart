import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/core/theme.dart';
import 'package:wall_o_pay/data/prefs.dart';
import 'package:wall_o_pay/features/settings/about_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('About Sheet Minimalist Theme Switcher Tests', () {
    late SharedPreferences sp;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sp = await SharedPreferences.getInstance();
    });

    Widget createTestApp(ProviderContainer container, {String themePreset = 'botanical'}) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildTheme(themePreset),
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocale.supported,
          home: const Scaffold(
            body: AboutWallOPaySheet(),
          ),
        ),
      );
    }

    testWidgets('Renders minimalist Botanical aesthetic badge in About sheet', (tester) async {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(container, themePreset: 'botanical'));
      await tester.pumpAndSettle();

      expect(find.text('Wall o\' Pay'), findsOneWidget);
      expect(find.text('Botanical'), findsOneWidget);
      expect(find.byIcon(Icons.eco_rounded), findsOneWidget);
    });

    testWidgets('Tapping Botanical aesthetic badge opens confirmation warn bubble and can switch to Cyberpunk', (tester) async {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(container, themePreset: 'botanical'));
      await tester.pumpAndSettle();

      // Tap the aesthetic badge
      await tester.tap(find.text('Botanical'));
      await tester.pumpAndSettle();

      // Verify the confirmation dialog / warn bubble appears
      expect(find.text('Switch to Cyberpunk Grid?'), findsOneWidget);
      expect(find.byIcon(Icons.electric_bolt_rounded), findsOneWidget);
      expect(find.text('Jack In'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Jack In
      await tester.tap(find.text('Jack In'));
      await tester.pumpAndSettle();

      // Preference should now be updated to cyberpunk
      expect(container.read(appPrefsProvider).themePreset, 'cyberpunk');
    });

    testWidgets('Tapping Cancel in confirmation dialog leaves theme unchanged', (tester) async {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(container, themePreset: 'botanical'));
      await tester.pumpAndSettle();

      // Tap the aesthetic badge
      await tester.tap(find.text('Botanical'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Switch to Cyberpunk Grid?'), findsNothing);
      expect(container.read(appPrefsProvider).themePreset, 'botanical');
    });

    testWidgets('In Cyberpunk mode, badge shows Cyberpunk and prompts return to Sanctuary', (tester) async {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
      );
      addTearDown(container.dispose);

      // Set initial to cyberpunk
      container.read(appPrefsProvider.notifier).setThemePreset('cyberpunk');

      await tester.pumpWidget(createTestApp(container, themePreset: 'cyberpunk'));
      await tester.pumpAndSettle();

      expect(find.text('Cyberpunk'), findsOneWidget);

      await tester.tap(find.text('Cyberpunk'));
      await tester.pumpAndSettle();

      // Warn bubble for returning to Botanical Sanctuary (in Cyberpunk EN, localized to Edgerunner terminology)
      expect(find.text('RETURN TO BOTANICAL SANCTUARY?'), findsOneWidget);
      expect(find.text('RETURN TO SANCTUARY'), findsOneWidget);

      // Confirm return
      await tester.tap(find.text('RETURN TO SANCTUARY'));
      await tester.pumpAndSettle();

      expect(container.read(appPrefsProvider).themePreset, 'botanical');
    });

    testWidgets('In Indonesian locale, confirmation dialog renders Indonesian warning bubble', (tester) async {
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildTheme('botanical'),
            locale: const Locale('id'),
            localizationsDelegates: const [
              AppStrings.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocale.supported,
            home: const Scaffold(
              body: AboutWallOPaySheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Botanical'));
      await tester.pumpAndSettle();

      expect(find.text('Beralih ke Tema Cyberpunk?'), findsOneWidget);
      expect(find.text('Masuk Grid'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      await tester.tap(find.text('Masuk Grid'));
      await tester.pumpAndSettle();

      expect(container.read(appPrefsProvider).themePreset, 'cyberpunk');
    });
  });
}
