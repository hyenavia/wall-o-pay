import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/core/calculator_sheet.dart';
import 'package:wall_o_pay/core/l10n.dart';
import 'package:wall_o_pay/core/theme.dart';
import 'package:wall_o_pay/data/app_database.dart';
import 'package:wall_o_pay/data/budget_rule.dart';
import 'package:wall_o_pay/data/prefs.dart';
import 'package:wall_o_pay/data/tables.dart' show TxType;
import 'package:wall_o_pay/features/budget/budget_pillar_card.dart';
import 'package:wall_o_pay/features/more/more_page.dart';
import 'package:wall_o_pay/features/onboarding/onboarding_page.dart';
import 'package:wall_o_pay/features/settings/about_sheet.dart';
import 'package:wall_o_pay/features/splash/splash_page.dart';
import 'package:wall_o_pay/features/transactions/transaction_tile.dart';

double _linearizeChannel(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _relativeLuminance(Color color) {
  final r = _linearizeChannel(color.r);
  final g = _linearizeChannel(color.g);
  final b = _linearizeChannel(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color a, Color b) {
  final l1 = _relativeLuminance(a);
  final l2 = _relativeLuminance(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Theme tokens & WCAG AA contrast', () {
    test('Vice City Sunset (dark) meets WCAG AA contrast targets', () {
      const c = AppThemeColors.viceCitySunset;
      expect(_contrastRatio(c.textPrimary, c.bg), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.textPrimary, c.cardSurface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.textMuted, c.cardSurface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.textMuted, c.surfaceContainer), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.primary, c.cardSurface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.onPrimary, c.primary), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.accentSecondary, c.cardSurface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.highlightGold, c.cardSurface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.income, c.cardSurface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.expense, c.cardSurface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.warning, c.cardSurface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.transfer, c.cardSurface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.transfer, c.surfaceContainer), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.onHeroIncome, c.heroBackground), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.onHeroExpense, c.heroBackground), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.inputBorder, c.cardSurface), greaterThanOrEqualTo(3.0));
    });

    test('Vice City Daylight (light) meets WCAG AA contrast targets', () {
      const c = AppThemeColors.viceCityDaylight;
      const sapphireTop = Color(0xFF0A4DA6);
      const sapphireBottom = Color(0xFF082E6E);
      expect(_contrastRatio(c.textPrimary, c.bg), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.textPrimary, c.cardSurface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.textMuted, c.bg), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.textMuted, c.cardSurface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.textMuted, c.surfaceContainer), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.primary, c.cardSurface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.onPrimary, c.primary), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.accentSecondary, c.cardSurface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.accentSecondary, c.surfaceContainer), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.highlightGold, c.cardSurface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.income, c.cardSurface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.expense, c.cardSurface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.warning, c.cardSurface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.transfer, c.cardSurface), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.transfer, c.surfaceContainer), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.onHeroIncome, sapphireTop), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.onHeroIncome, sapphireBottom), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.onHeroExpense, sapphireTop), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.onHeroExpense, sapphireBottom), greaterThanOrEqualTo(4.5));
      expect(_contrastRatio(c.inputBorder, c.cardSurface), greaterThanOrEqualTo(3.0));
    });

    test('resolveAccent maps dark tokens to crisp Daylight tokens', () {
      const dark = AppThemeColors.viceCitySunset;
      const light = AppThemeColors.viceCityDaylight;
      expect(light.resolveAccent(AppColors.neonCyan), light.accentSecondary);
      expect(light.resolveAccent(AppColors.dewMint), light.highlightGold);
      expect(light.resolveAccent(AppColors.incomeOnDark), light.income);
      expect(light.resolveAccent(AppColors.expenseOnDark), light.expense);
      expect(light.resolveAccent(AppColors.warning), light.warning);
      expect(dark.resolveAccent(AppColors.dewMint), AppColors.dewMint);
    });

    test('buildLightTheme and buildDarkTheme return matching brightness and extension', () {
      final dark = buildDarkTheme();
      final light = buildLightTheme();
      expect(dark.brightness, Brightness.dark);
      expect(dark.extension<AppThemeColors>()?.isDark, isTrue);
      expect(light.brightness, Brightness.light);
      expect(light.extension<AppThemeColors>()?.isDark, isFalse);
      expect(light.scaffoldBackgroundColor, AppThemeColors.viceCityDaylight.bg);
    });
  });

  group('AppPrefs themeMode default & persistence', () {
    test('defaults to ThemeMode.dark for new users and persists ThemeMode.light', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(appPrefsProvider).themeMode, ThemeMode.dark);

      await container.read(appPrefsProvider.notifier).setThemeMode(ThemeMode.light);
      expect(container.read(appPrefsProvider).themeMode, ThemeMode.light);
      expect(prefs.getString('pref_theme'), 'light');
    });
  });

  group('Phase 2 Light Mode widget smoke tests', () {
    testWidgets('TransactionTile renders cleanly in Vice City Daylight', (tester) async {
      final now = DateTime(2026, 11, 25);
      final category = Category(
        id: 'cat-food',
        name: 'Food',
        type: TxType.expense,
        icon: 'restaurant',
        colorValue: 0xFFE65100,
        createdAt: now,
        updatedAt: now,
      );
      final entry = TransactionEntry(
        id: 'tx-1',
        amount: 45000,
        type: TxType.expense,
        categoryId: 'cat-food',
        note: 'Coffee & Lunch',
        date: now,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          themeMode: ThemeMode.light,
          home: Scaffold(
            body: TransactionTile(
              entry: entry,
              category: category,
              trailingNote: '25 Nov',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Coffee & Lunch'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CalculatorSheet renders cleanly in Vice City Daylight', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          themeMode: ThemeMode.light,
          home: const Scaffold(
            body: CalculatorSheet(initialValue: 10000),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('7'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('BudgetPillarCard renders and adapts BudgetBucket colorIn for Light Mode', (tester) async {
      final now = DateTime(2026, 11, 25);
      final cat = Category(
        id: 'cat-groceries',
        name: 'Groceries',
        type: TxType.expense,
        icon: 'shopping_cart',
        colorValue: 0xFF047857,
        createdAt: now,
        updatedAt: now,
      );
      late Color resolvedNeedsColor;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          themeMode: ThemeMode.light,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                resolvedNeedsColor = BudgetBucket.needs.colorIn(context);
                return SingleChildScrollView(
                  child: BudgetPillarCard(
                    bucket: BudgetBucket.needs,
                    percentage: 50,
                    allocated: 5000000,
                    spent: 2500000,
                    ratio: 0.5,
                    categories: [cat],
                    categoryBudgets: const {'cat-groceries': 2000000},
                    categorySpent: const {'cat-groceries': 1000000},
                    onTapCategory: (_) {},
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(resolvedNeedsColor, AppThemeColors.viceCityDaylight.income);
      expect(find.text('50%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Phase 3 Light Mode widget smoke tests', () {
    Widget wrapLight(Widget child) {
      return MaterialApp(
        theme: buildLightTheme(),
        themeMode: ThemeMode.light,
        locale: const Locale('en'),
        supportedLocales: AppLocale.supported,
        localizationsDelegates: const [
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      );
    }

    testWidgets('SplashPage renders Ocean Sapphire Daylight mode cleanly', (tester) async {
      await tester.pumpWidget(wrapLight(const SplashPage()));
      await tester.pump();

      expect(find.byType(GlasshouseCombinationLogo), findsOneWidget);
      expect(find.text('Grow Your Financial Habits.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AboutWallOPaySheet renders in Vice City Daylight cleanly', (tester) async {
      await tester.pumpWidget(
        wrapLight(const Scaffold(body: AboutWallOPaySheet())),
      );
      await tester.pumpAndSettle();

      expect(find.text("About Wall o' Pay"), findsOneWidget);
      expect(find.text('Your money, under your control.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MorePage renders feature groups in Vice City Daylight cleanly', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: wrapLight(const MorePage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('More Features'), findsOneWidget);
      expect(find.text('Accounts'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('OnboardingPage renders Daylight coastal canvas cleanly', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: wrapLight(OnboardingPage(onDone: () {})),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
