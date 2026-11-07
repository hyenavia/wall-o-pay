/// Konfigurasi sistem desain visual Wall o' Pay (Botanical Forest),
/// mencakup token warna ([AppColors]) dan konfigurasi Material 3 ([buildTheme]).
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet dari desain Wall o' Pay (Botanical Forest).
class AppColors {
  static const deepForest = Color(0xFF234B3B);
  static const sage = Color(0xFFA9C5B1);
  static const ivory = Color(0xFFF7F8F4);
  static const ink = Color(0xFF202923);
  static const income = Color(0xFF38B271); // Cerah & berakar botani kontras tinggi di latar gelap
  static const expense = Color(0xFFD64545);
  static const warning = Color(0xFFE8A33D);

  // Surface & Depth Tokens (Botanical Forest)
  static const bg = Color(0xFF121D17); // Lush Botanical Night Pine
  static const cardSurface = Color(0xFF1E3026); // Elevated Velvet Emerald Card Surface
  static const surfaceContainer = Color(0xFF253C2F); // Elevated Container & Dialog Surface
  static const borderOutline = Color(0xFF2F473A); // Crisp Pine Border Outline

  // High-contrast semantic tokens on dark card surfaces
  static const incomeOnDark = Color(0xFF6EE7B7);
  static const expenseOnDark = Color(0xFFFCA5A5);
}

/// Mengaktifkan fitur `tabularFigures` pada seluruh gaya teks agar digit angka memiliki lebar seragam.
TextTheme _applyTabularFigures(TextTheme textTheme) {
  const tabular = [FontFeature.tabularFigures()];
  return textTheme.copyWith(
    displayLarge: textTheme.displayLarge?.copyWith(fontFeatures: tabular),
    displayMedium: textTheme.displayMedium?.copyWith(fontFeatures: tabular),
    displaySmall: textTheme.displaySmall?.copyWith(fontFeatures: tabular),
    headlineLarge: textTheme.headlineLarge?.copyWith(fontFeatures: tabular),
    headlineMedium: textTheme.headlineMedium?.copyWith(fontFeatures: tabular),
    headlineSmall: textTheme.headlineSmall?.copyWith(fontFeatures: tabular),
    titleLarge: textTheme.titleLarge?.copyWith(fontFeatures: tabular),
    titleMedium: textTheme.titleMedium?.copyWith(fontFeatures: tabular),
    titleSmall: textTheme.titleSmall?.copyWith(fontFeatures: tabular),
    bodyLarge: textTheme.bodyLarge?.copyWith(fontFeatures: tabular),
    bodyMedium: textTheme.bodyMedium?.copyWith(fontFeatures: tabular),
    bodySmall: textTheme.bodySmall?.copyWith(fontFeatures: tabular),
    labelLarge: textTheme.labelLarge?.copyWith(fontFeatures: tabular),
    labelMedium: textTheme.labelMedium?.copyWith(fontFeatures: tabular),
    labelSmall: textTheme.labelSmall?.copyWith(fontFeatures: tabular),
  );
}

/// Membangun objek [ThemeData] Material 3 dengan palet gelap Botanical Forest atau Cyberpunk Edgerunners.
ThemeData buildTheme([String preset = 'botanical']) {
  final isCyber = preset == 'cyberpunk';
  final colors = isCyber ? AppThemeColors.cyberpunk : AppThemeColors.botanical;

  final scheme = const ColorScheme.dark().copyWith(
    primary: colors.primary,
    onPrimary: colors.onPrimary,
    primaryContainer: colors.heroBackground,
    onPrimaryContainer: Colors.white,
    secondary: isCyber ? colors.secondaryNeon : colors.primary,
    onSecondary: colors.onPrimary,
    surface: colors.cardSurface,
    onSurface: colors.textPrimary,
    surfaceContainerHighest: colors.surfaceContainer,
    outline: colors.borderOutline,
    outlineVariant: colors.borderOutline,
    error: colors.expense,
    onError: colors.onPrimary,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
  );

  final fontTheme = isCyber
      ? GoogleFonts.rajdhaniTextTheme(base.textTheme)
      : GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

  final styledTextTheme = _applyTabularFigures(
    fontTheme.apply(
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: colors.bg,
    cardColor: colors.cardSurface,
    canvasColor: colors.cardSurface,
    dividerColor: colors.borderOutline,
    dividerTheme: DividerThemeData(color: colors.borderOutline, thickness: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.cardSurface,
      shape: isCyber
          ? const BeveledRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              side: BorderSide(color: Color(0xFF232946), width: 1.2),
            )
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    textTheme: styledTextTheme,
    extensions: [colors],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: colors.textPrimary),
      titleTextStyle: TextStyle(
        color: colors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: isCyber ? const Color(0xFF0D1021) : colors.cardSurface,
      selectedItemColor: colors.primary,
      unselectedItemColor: colors.textMuted,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.cardSurface,
      surfaceTintColor: Colors.transparent,
      shape: isCyber
          ? const BeveledRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              side: BorderSide(color: Color(0xFF232946), width: 1.0),
            )
          : const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colors.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: isCyber
          ? BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: colors.borderOutline, width: 1.0),
            )
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: TextStyle(color: colors.textPrimary),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.surfaceContainer,
      contentTextStyle: TextStyle(color: colors.textPrimary),
      shape: isCyber
          ? BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                color: colors.primary.withValues(alpha: 0.40),
                width: 1.0,
              ),
            )
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colors.fabBackground,
      foregroundColor: colors.fabForeground,
      elevation: 3,
      shape: isCyber
          ? const BeveledRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            )
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          isCyber
              ? const BeveledRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                )
              : RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        shape: isCyber
            ? const BeveledRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(8),
                ),
              )
            : RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: isCyber
            ? GoogleFonts.rajdhani(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.6,
                fontFeatures: const [FontFeature.tabularFigures()],
              )
            : GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colors.primary;
        }
        return isCyber ? Colors.white54 : null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return isCyber
              ? colors.primary.withValues(alpha: 0.35)
              : colors.primary.withValues(alpha: 0.45);
        }
        return isCyber ? colors.surfaceContainer : null;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return isCyber ? colors.primary.withValues(alpha: 0.8) : null;
        }
        return isCyber ? colors.borderOutline : null;
      }),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: colors.primary,
      inactiveTrackColor: isCyber ? colors.surfaceContainer : null,
      thumbColor: colors.primary,
      overlayColor: colors.primary.withValues(alpha: 0.16),
      trackHeight: isCyber ? 3.0 : 4.0,
    ),
  );
}

/// Token warna dinamis yang mendukung tema Botanical Forest dan Cyberpunk Edgerunners.
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.isCyberpunk,
    required this.bg,
    required this.cardSurface,
    required this.surfaceContainer,
    required this.borderOutline,
    required this.primary,
    required this.onPrimary,
    required this.heroBackground,
    required this.fabBackground,
    required this.fabForeground,
    required this.income,
    required this.expense,
    required this.warning,
    required this.secondaryNeon,
    required this.textPrimary,
    required this.textMuted,
  });

  final bool isCyberpunk;
  final Color bg;
  final Color cardSurface;
  final Color surfaceContainer;
  final Color borderOutline;
  final Color primary;
  final Color onPrimary;
  final Color heroBackground;
  final Color fabBackground;
  final Color fabForeground;
  final Color income;
  final Color expense;
  final Color warning;
  final Color secondaryNeon;
  final Color textPrimary;
  final Color textMuted;

  static const botanical = AppThemeColors(
    isCyberpunk: false,
    bg: AppColors.bg,
    cardSurface: AppColors.cardSurface,
    surfaceContainer: AppColors.surfaceContainer,
    borderOutline: AppColors.borderOutline,
    primary: AppColors.sage,
    onPrimary: AppColors.ink,
    heroBackground: AppColors.deepForest,
    fabBackground: AppColors.sage,
    fabForeground: AppColors.ink,
    income: AppColors.incomeOnDark,
    expense: AppColors.expenseOnDark,
    warning: AppColors.warning,
    secondaryNeon: AppColors.sage,
    textPrimary: Color(0xFFE9EFEA),
    textMuted: Color(0xFF7E9687),
  );

  static const cyberpunk = AppThemeColors(
    isCyberpunk: true,
    bg: Color(0xFF080912),
    cardSurface: Color(0xFF121528),
    surfaceContainer: Color(0xFF191E38),
    borderOutline: Color(0xFF232946),
    primary: Color(0xFF00F0FF),
    onPrimary: Color(0xFF080912),
    heroBackground: Color(0xFF13172E),
    fabBackground: Color(0xFFFCEE0A),
    fabForeground: Color(0xFF080912),
    income: Color(0xFF00FF9D),
    expense: Color(0xFFFF2A6D),
    warning: Color(0xFFFCEE0A),
    secondaryNeon: Color(0xFFB829FF),
    textPrimary: Color(0xFFF0F6FF),
    textMuted: Color(0xFF7C86A6),
  );

  @override
  AppThemeColors copyWith({
    bool? isCyberpunk,
    Color? bg,
    Color? cardSurface,
    Color? surfaceContainer,
    Color? borderOutline,
    Color? primary,
    Color? onPrimary,
    Color? heroBackground,
    Color? fabBackground,
    Color? fabForeground,
    Color? income,
    Color? expense,
    Color? warning,
    Color? secondaryNeon,
    Color? textPrimary,
    Color? textMuted,
  }) {
    return AppThemeColors(
      isCyberpunk: isCyberpunk ?? this.isCyberpunk,
      bg: bg ?? this.bg,
      cardSurface: cardSurface ?? this.cardSurface,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      borderOutline: borderOutline ?? this.borderOutline,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      heroBackground: heroBackground ?? this.heroBackground,
      fabBackground: fabBackground ?? this.fabBackground,
      fabForeground: fabForeground ?? this.fabForeground,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      warning: warning ?? this.warning,
      secondaryNeon: secondaryNeon ?? this.secondaryNeon,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      isCyberpunk: t < 0.5 ? isCyberpunk : other.isCyberpunk,
      bg: Color.lerp(bg, other.bg, t) ?? bg,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t) ?? cardSurface,
      surfaceContainer: Color.lerp(surfaceContainer, other.surfaceContainer, t) ?? surfaceContainer,
      borderOutline: Color.lerp(borderOutline, other.borderOutline, t) ?? borderOutline,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t) ?? onPrimary,
      heroBackground: Color.lerp(heroBackground, other.heroBackground, t) ?? heroBackground,
      fabBackground: Color.lerp(fabBackground, other.fabBackground, t) ?? fabBackground,
      fabForeground: Color.lerp(fabForeground, other.fabForeground, t) ?? fabForeground,
      income: Color.lerp(income, other.income, t) ?? income,
      expense: Color.lerp(expense, other.expense, t) ?? expense,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      secondaryNeon: Color.lerp(secondaryNeon, other.secondaryNeon, t) ?? secondaryNeon,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
    );
  }
}

/// Gaya teks untuk angka finansial / nominal mata uang.
/// Di tema Cyberpunk, menggunakan [GoogleFonts.shareTechMono] (tampilan HUD terminal).
/// Di tema Botanical, menggunakan [GoogleFonts.plusJakartaSans] dengan tabularFigures.
/// Gaya teks untuk angka finansial / nominal mata uang.
/// Di tema Cyberpunk, menggunakan [GoogleFonts.shareTechMono] (tampilan HUD terminal).
/// Di tema Botanical, menggunakan [GoogleFonts.plusJakartaSans] dengan tabularFigures.
TextStyle appMoneyStyle(
  BuildContext? context, {
  bool? isCyberpunk,
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
}) {
  final isCyber = isCyberpunk ?? (context != null && context.isCyberpunk);
  const tabular = [FontFeature.tabularFigures()];
  if (isCyber) {
    return GoogleFonts.shareTechMono(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w700,
      color: color,
      letterSpacing: letterSpacing ?? 0.5,
      fontFeatures: tabular,
    );
  }
  return GoogleFonts.plusJakartaSans(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w700,
    color: color,
    letterSpacing: letterSpacing,
    fontFeatures: tabular,
  );
}

/// Helper extension untuk mengakses token warna tema dan tipografi dari [BuildContext].
extension ThemeContextX on BuildContext {
  AppThemeColors get themeColors =>
      Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.botanical;
  bool get isCyberpunk => themeColors.isCyberpunk;

  /// Shortcut praktis untuk mendapatkan gaya teks angka finansial (monospace di Cyberpunk).
  TextStyle moneyStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) =>
      appMoneyStyle(
        this,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
}
