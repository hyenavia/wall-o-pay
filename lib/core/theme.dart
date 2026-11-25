/// Konfigurasi sistem desain visual Wall o' Pay (Vice City Sunset — Balanced),
/// perpaduan atmosfer kota pesisir tropis saat matahari terbenam, neon signage halus,
/// dan estetika retro-modern berlatar gelap kontras tinggi.
/// Mencakup token warna ([AppColors]) dan konfigurasi Material 3 ([buildTheme]).
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet dari desain Wall o' Pay (Vice City Sunset Edition — GTA VI Vibes, dikalibrasi).
class AppColors {
  // Palet Utama Vice City Sunset (berbasis assets/new_asset/color_pallete.png)
  static const midnightNavy = Color(0xFF14092B); // Background utama (Deep Twilight Purple — bukan abu-abu kusam)
  static const deepNavy = Color(0xFF1F103D);     // Surface dan card (Rich Twilight Plum)
  static const sunsetMagenta = Color(0xFFFF4D8D); // Primary accent (Sunset Pink / Fuchsia Pink)
  static const coralPink = Color(0xFFFF1AD9);     // Secondary neon accent (Hot Magenta)
  static const sunsetOrange = Color(0xFFFF8A3D);  // Highlight (Miami Orange)
  static const goldenYellow = Color(0xFFFFD166);  // Positive highlight (Sunset Yellow)
  static const sunsetAmber = goldenYellow;        // Alias Sunset Yellow
  static const neonCyan = Color(0xFF00D1D1);      // Aksen sekunder (Ocean Teal — seimbang, tidak silau)
  static const tropicalBlue = Color(0xFF00A6FF);  // Aksen biru tropis (Tropical Blue)
  static const neonPurple = Color(0xFF7A00FF);    // Aksen ungu neon (Neon Purple)
  static const softWhite = Color(0xFFFAF5FF);     // Teks utama (Warm Pearl White)
  static const mutedBlueGray = Color(0xFFC4B5E3); // Teks sekunder (Soft Twilight Lavender — kontras tinggi)

  // Surface & Depth Tokens (Vice City Sunset)
  static const bg = midnightNavy;
  static const cardSurface = deepNavy;
  static const surfaceContainer = Color(0xFF2B1554); // Midnight Purple (#2B0057 dikalibrasi)
  static const borderOutline = Color(0xFF4A277A); // Garis Tepi Twilight Violet

  // Semantik Finansial Universal & Ramah Mata
  static const income = Color(0xFF10B981); // Emerald 500
  static const expense = Color(0xFFFF4D8D); // Sunset Pink
  static const warning = Color(0xFFFF8A3D); // Miami Orange
  static const positiveHighlight = Color(0xFFFFD166); // Sunset Yellow

  // High-contrast semantic tokens on dark card surfaces
  static const incomeOnDark = Color(0xFF34D399); // Emerald 400
  static const expenseOnDark = Color(0xFFFF6B9D); // Soft Sunset Pink

  // Atmospheric Header Canopy Tokens
  static const headerCanopyTop = Color(0xFF100624);
  static const headerCanopyBottom = Color(0xFF1C0B3B);

  // Alias kanonikal untuk kompatibilitas mundur
  static const glasshouseGreen = deepNavy;
  static const emeraldLeaf = sunsetMagenta;
  static const freshSage = neonCyan;
  static const dewMint = goldenYellow;
  static const softIvory = softWhite;
  static const mossShadow = midnightNavy;

  static const deepForest = deepNavy;
  static const sage = sunsetMagenta;
  static const ivory = softWhite;
  static const ink = midnightNavy;
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

/// Membangun objek [ThemeData] Material 3 dengan palet Enchanted Glasshouse.
/// Menggunakan Google Fonts Outfit untuk heading/angka finansial dan Inter untuk body.
ThemeData buildTheme() {
  const colors = AppThemeColors.enchantedGlasshouse;

  final scheme = const ColorScheme.dark().copyWith(
    primary: colors.primary,
    onPrimary: colors.onPrimary,
    primaryContainer: colors.heroBackground,
    onPrimaryContainer: Colors.white,
    secondary: colors.primary,
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

  final outfitTheme = GoogleFonts.outfitTextTheme(base.textTheme);
  final interTheme = GoogleFonts.interTextTheme(base.textTheme);

  // Padukan Outfit untuk display/heading dan Inter untuk body/label deskripsi
  final blendedTextTheme = interTheme.copyWith(
    displayLarge: outfitTheme.displayLarge,
    displayMedium: outfitTheme.displayMedium,
    displaySmall: outfitTheme.displaySmall,
    headlineLarge: outfitTheme.headlineLarge,
    headlineMedium: outfitTheme.headlineMedium,
    headlineSmall: outfitTheme.headlineSmall,
    titleLarge: outfitTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    titleMedium: outfitTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    titleSmall: outfitTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
  );

  final styledTextTheme = _applyTabularFigures(
    blendedTextTheme.apply(
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      backgroundColor: colors.cardSurface,
      selectedItemColor: colors.primary,
      unselectedItemColor: colors.textMuted,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.cardSurface,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: AppColors.mutedBlueGray.withValues(alpha: 0.35),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(
          color: AppColors.borderOutline,
          width: 1.0,
        ),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colors.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.borderOutline,
          width: 1.0,
        ),
      ),
      textStyle: TextStyle(color: colors.textPrimary),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.surfaceContainer,
      contentTextStyle: TextStyle(color: colors.textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: AppColors.borderOutline,
          width: 1.0,
        ),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colors.fabBackground,
      foregroundColor: colors.fabForeground,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: AppColors.goldenYellow.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.sunsetMagenta;
          }
          return AppColors.surfaceContainer.withValues(alpha: 0.65);
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.midnightNavy;
          }
          return AppColors.neonCyan;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BorderSide(color: AppColors.goldenYellow.withValues(alpha: 0.55), width: 1.2);
          }
          return BorderSide(color: AppColors.borderOutline, width: 1.0);
        }),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.65),
      selectedColor: AppColors.sunsetMagenta,
      secondarySelectedColor: AppColors.sunsetMagenta,
      labelStyle: const TextStyle(color: AppColors.softWhite, fontWeight: FontWeight.w600),
      secondaryLabelStyle: const TextStyle(color: AppColors.midnightNavy, fontWeight: FontWeight.w700),
      side: const BorderSide(color: AppColors.borderOutline, width: 1.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      iconTheme: const IconThemeData(color: AppColors.neonCyan, size: 18),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.dmSans(
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
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colors.primary.withValues(alpha: 0.45);
        }
        return null;
      }),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: colors.primary,
      thumbColor: colors.primary,
      overlayColor: colors.primary.withValues(alpha: 0.16),
      trackHeight: 4.0,
    ),
  );
}

/// Token warna tema Botanical Forest.
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
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
    required this.textPrimary,
    required this.textMuted,
  });

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
  final Color textPrimary;
  final Color textMuted;

  static const viceCitySunset = AppThemeColors(
    bg: AppColors.bg,
    cardSurface: AppColors.cardSurface,
    surfaceContainer: AppColors.surfaceContainer,
    borderOutline: AppColors.borderOutline,
    primary: AppColors.sage,
    onPrimary: AppColors.midnightNavy,
    heroBackground: AppColors.deepForest,
    fabBackground: AppColors.sage,
    fabForeground: AppColors.midnightNavy,
    income: AppColors.incomeOnDark,
    expense: AppColors.expenseOnDark,
    warning: AppColors.warning,
    textPrimary: AppColors.softWhite,
    textMuted: AppColors.mutedBlueGray,
  );

  /// Alias kanonikal untuk kompatibilitas mundur
  static const enchantedGlasshouse = viceCitySunset;
  static const botanical = viceCitySunset;

  @override
  AppThemeColors copyWith({
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
    Color? textPrimary,
    Color? textMuted,
  }) {
    return AppThemeColors(
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
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
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
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
    );
  }
}

/// Gaya teks untuk angka finansial / nominal mata uang menggunakan [GoogleFonts.outfit]
/// dengan fitur tabularFigures agar digit angka sejajar rapi.
TextStyle appMoneyStyle(
  BuildContext? context, {
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
}) {
  const tabular = [FontFeature.tabularFigures()];
  return GoogleFonts.outfit(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w700,
    color: color,
    letterSpacing: letterSpacing,
    fontFeatures: tabular,
  );
}

/// Gaya teks untuk metadata teknis / kode ledger menggunakan [GoogleFonts.jetBrainsMono]
TextStyle appMonoStyle(
  BuildContext? context, {
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
}) {
  return GoogleFonts.jetBrainsMono(
    fontSize: fontSize,
    fontWeight: fontWeight ?? FontWeight.w500,
    color: color,
    letterSpacing: letterSpacing,
  );
}

/// Helper extension untuk mengakses token warna tema dan tipografi dari [BuildContext].
extension ThemeContextX on BuildContext {
  AppThemeColors get themeColors =>
      Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.botanical;

  /// Shortcut praktis untuk mendapatkan gaya teks angka finansial.
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

  /// Shortcut praktis untuk mendapatkan gaya teks metadata teknis monospace.
  TextStyle monoStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) =>
      appMonoStyle(
        this,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
}
