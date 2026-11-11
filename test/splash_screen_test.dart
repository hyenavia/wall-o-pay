import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/features/splash/splash_page.dart';

void main() {
  group('Enchanted Glasshouse Splash Screen Tests', () {
    testWidgets('Renders combination logo, brand name, and English tagline',
        (tester) async {
      var finished = false;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocale.supported,
          localizationsDelegates: [
            AppStrings.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: SplashPage(
            onFinish: () => finished = true,
          ),
        ),
      );

      // Verify the combination logo is rendered
      expect(find.byType(GlasshouseCombinationLogo), findsOneWidget);

      // Verify the application title is displayed
      expect(find.text("Wall o' Pay"), findsOneWidget);

      // Verify the tagline is displayed in English
      expect(find.text('Grow Your Financial Habits.'), findsOneWidget);

      // Verify onFinish was triggered
      expect(finished, isTrue);
    });

    testWidgets('Renders Indonesian localized tagline properly',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocale.supported,
          localizationsDelegates: [
            AppStrings.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: const SplashPage(),
        ),
      );

      // Verify Indonesian translation
      expect(find.text('Tumbuhkan Kebiasaan Finansialmu.'), findsOneWidget);
      expect(find.byType(GlasshouseCombinationLogo), findsOneWidget);
    });

    testWidgets('GlasshouseCombinationLogo renders asset image correctly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlasshouseCombinationLogo(size: 120, showGlow: true),
            ),
          ),
        ),
      );

      expect(find.byType(GlasshouseCombinationLogo), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });
  });
}

