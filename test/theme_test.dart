import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wall_o_pay/core/theme.dart';
import 'package:wall_o_pay/core/widgets.dart';
import 'package:wall_o_pay/data/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Theme System Tests', () {
    late SharedPreferences sp;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sp = await SharedPreferences.getInstance();
    });
    test('Botanical theme tokens, color scheme, and organic rounded shapes are configured correctly', () {
      final theme = buildTheme();
      final colors = theme.extension<AppThemeColors>()!;

      expect(colors, AppThemeColors.botanical);
      expect(colors.primary, AppColors.sage);
      expect(colors.heroBackground, AppColors.deepForest);
      expect(colors.income, AppColors.incomeOnDark);
      expect(colors.expense, AppColors.expenseOnDark);
      expect(colors.warning, AppColors.warning);
      expect(theme.colorScheme.primary, colors.primary);
      expect(theme.colorScheme.secondary, colors.primary);
      expect(theme.colorScheme.error, colors.expense);
      expect(theme.dividerColor, colors.borderOutline);
      expect(theme.dividerTheme.color, colors.borderOutline);
      expect(theme.dialogTheme.shape, isA<RoundedRectangleBorder>());
      expect(theme.snackBarTheme.shape, isA<RoundedRectangleBorder>());
      expect(theme.floatingActionButtonTheme.shape, isA<RoundedRectangleBorder>());
    });

    test('budgetColor dynamically responds to ratio and theme colors', () {
      const botanicalColors = AppThemeColors.botanical;
      const scheme = ColorScheme.dark();

      expect(budgetColor(0.5, scheme, botanicalColors), scheme.primary);
      expect(budgetColor(0.85, scheme, botanicalColors), botanicalColors.warning);
      expect(budgetColor(1.2, scheme, botanicalColors), botanicalColors.expense);
    });

    test('appMoneyStyle applies DM Sans with tabular figures', () {
      final botanicalStyle = appMoneyStyle(
        null,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      );
      expect(botanicalStyle.fontFamily, contains('DMSans'));
      expect(botanicalStyle.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    test('Botanical Switch and Slider theme styles are configured', () {
      final theme = buildTheme();
      final colors = theme.extension<AppThemeColors>()!;

      expect(theme.switchTheme.thumbColor?.resolve({WidgetState.selected}), colors.primary);
      expect(theme.sliderTheme.activeTrackColor, colors.primary);
      expect(theme.sliderTheme.thumbColor, colors.primary);
    });

    testWidgets('AnimatedMoneyCounter animates and formats currency properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedMoneyCounter(amount: 1500000),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rp 1.500.000'), findsOneWidget);
    });

    testWidgets('UserAvatar renders CircleAvatar in Botanical theme', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
          child: MaterialApp(
            theme: buildTheme(),
            home: const Scaffold(
              body: UserAvatar(size: 80),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CircleAvatar), findsOneWidget);
    });
  });
}
