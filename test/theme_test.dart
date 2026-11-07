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
      final theme = buildTheme('botanical');
      final colors = theme.extension<AppThemeColors>()!;

      expect(colors.isCyberpunk, isFalse);
      expect(theme.colorScheme.primary, colors.primary);
      expect(theme.colorScheme.error, colors.expense);
      expect(theme.dividerColor, colors.borderOutline);
      expect(theme.dividerTheme.color, colors.borderOutline);
      expect(theme.dialogTheme.shape, isA<RoundedRectangleBorder>());
      expect(theme.snackBarTheme.shape, isA<RoundedRectangleBorder>());
      expect(theme.floatingActionButtonTheme.shape, isA<RoundedRectangleBorder>());
    });

    test('Cyberpunk theme tokens, neon color scheme, and beveled HUD shapes are configured correctly', () {
      final theme = buildTheme('cyberpunk');
      final colors = theme.extension<AppThemeColors>()!;

      expect(colors.isCyberpunk, isTrue);
      expect(colors.primary, const Color(0xFF00F0FF));
      expect(colors.expense, const Color(0xFFFF2A6D));
      expect(colors.income, const Color(0xFF00FF9D));
      expect(colors.warning, const Color(0xFFFCEE0A));
      expect(theme.colorScheme.primary, colors.primary);
      expect(theme.colorScheme.secondary, colors.secondaryNeon);
      expect(theme.colorScheme.error, colors.expense);
      expect(theme.dividerColor, colors.borderOutline);
      expect(theme.dialogTheme.shape, isA<BeveledRectangleBorder>());
      expect(theme.snackBarTheme.shape, isA<BeveledRectangleBorder>());
      expect(theme.floatingActionButtonTheme.shape, isA<BeveledRectangleBorder>());
    });

    test('budgetColor dynamically responds to ratio and theme colors', () {
      final cyberColors = AppThemeColors.cyberpunk;
      const scheme = ColorScheme.dark();

      expect(budgetColor(0.5, scheme, cyberColors), scheme.primary);
      expect(budgetColor(0.85, scheme, cyberColors), cyberColors.warning);
      expect(budgetColor(1.2, scheme, cyberColors), cyberColors.expense);

      final botanicalColors = AppThemeColors.botanical;
      expect(budgetColor(0.85, scheme, botanicalColors), botanicalColors.warning);
      expect(budgetColor(1.2, scheme, botanicalColors), botanicalColors.expense);
    });

    test('appMoneyStyle applies Share Tech Mono in Cyberpunk and Plus Jakarta Sans in Botanical', () {
      final cyberStyle = appMoneyStyle(
        null,
        isCyberpunk: true,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      );
      expect(cyberStyle.fontFamily, contains('ShareTechMono'));
      expect(cyberStyle.fontFeatures, contains(const FontFeature.tabularFigures()));

      final botanicalStyle = appMoneyStyle(
        null,
        isCyberpunk: false,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      );
      expect(botanicalStyle.fontFamily, contains('PlusJakartaSans'));
    });

    test('Cyberpunk Switch and Slider theme styles are configured', () {
      final theme = buildTheme('cyberpunk');
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

    testWidgets('UserAvatar renders CircleAvatar in Botanical and Chamfered HUD badge in Cyberpunk', (tester) async {
      // 1. Botanical mode renders CircleAvatar
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
          child: MaterialApp(
            theme: buildTheme('botanical'),
            home: const Scaffold(
              body: UserAvatar(size: 80),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CircleAvatar), findsOneWidget);

      // 2. Cyberpunk mode renders chamfered HUD badge with BeveledRectangleBorder and ID tag
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
          child: MaterialApp(
            theme: buildTheme('cyberpunk'),
            home: const Scaffold(
              body: UserAvatar(size: 80),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CircleAvatar), findsNothing);
      expect(find.text('ID'), findsOneWidget);

      // Verify ClipPath with BeveledRectangleBorder
      final clipPath = tester.widget<ClipPath>(find.byType(ClipPath));
      final clipper = clipPath.clipper as ShapeBorderClipper;
      expect(clipper.shape, isA<BeveledRectangleBorder>());
    });
  });
}
