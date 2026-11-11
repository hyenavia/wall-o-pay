import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/core/theme.dart';
import 'package:wall_o_pay/data/update_checker.dart';
import 'package:wall_o_pay/features/settings/about_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('About Sheet Botanical Identity Tests', () {
    Widget createTestApp({Locale locale = const Locale('en')}) {
      return MaterialApp(
        theme: buildTheme(),
        locale: locale,
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
      );
    }

    testWidgets('Renders Botanical identity, current version, and omits theme switcher', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text("Wall o' Pay"), findsOneWidget);
      expect(
        find.text('v${UpdateCheckerService.currentVersion} • Release'),
        findsOneWidget,
      );
      expect(find.text('Your money, under your control.'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('The Botanical Sanctuary'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('The Botanical Sanctuary'), findsOneWidget);

      expect(find.text('Cyberpunk'), findsNothing);
      expect(find.text('Switch to Cyberpunk Grid?'), findsNothing);
      expect(find.byIcon(Icons.swap_horiz_rounded), findsNothing);
    });

    testWidgets('In Indonesian locale, renders localized Botanical lore and actions', (tester) async {
      await tester.pumpWidget(createTestApp(locale: const Locale('id')));
      await tester.pumpAndSettle();

      expect(find.text("Wall o' Pay"), findsOneWidget);
      expect(find.text('Uangmu, di bawah kendalimu.'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Suaka Botani Finansial'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Suaka Botani Finansial'), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz_rounded), findsNothing);
    });
  });
}
