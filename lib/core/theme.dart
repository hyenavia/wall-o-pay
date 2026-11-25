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
  static const midnightNavy = Color(
    0xFF14092B,
  ); // Background utama (Deep Twilight Purple — bukan abu-abu kusam)
  static const deepNavy = Color(
    0xFF1F103D,
  ); // Surface dan card (Rich Twilight Plum)
  static const sunsetMagenta = Color(
    0xFFFF4D8D,
  ); // Primary accent (Sunset Pink / Fuchsia Pink)
  static const coralPink = Color(
    0xFFFF1AD9,
  ); // Secondary neon accent (Hot Magenta)
  static const sunsetOrange = Color(0xFFFF8A3D); // Highlight (Miami Orange)
  static const goldenYellow = Color(
    0xFFFFD166,
  ); // Positive highlight (Sunset Yellow)
  static const sunsetAmber = goldenYellow; // Alias Sunset Yellow
  static const neonCyan = Color(
    0xFF00D1D1,
  ); // Aksen sekunder (Ocean Teal — seimbang, tidak silau)
  static const tropicalBlue = Color(
    0xFF00A6FF,
  ); // Aksen biru tropis (Tropical Blue)
  static const neonPurple = Color(0xFF7A00FF); // Aksen ungu neon (Neon Purple)
  static const softWhite = Color(0xFFFAF5FF); // Teks utama (Warm Pearl White)
  static const mutedBlueGray = Color(
    0xFFC4B5E3,
  ); // Teks sekunder (Soft Twilight Lavender — kontras tinggi)

  // Surface & Depth Tokens (Vice City Sunset)
  static const bg = midnightNavy;
  static const cardSurface = deepNavy;
  static const surfaceContainer = Color(
    0xFF2B1554,
  ); // Midnight Purple (#2B0057 dikalibrasi)
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

/// Membangun objek [ThemeData] Material 3 untuk palet Vice City Sunset (gelap)
/// atau Vice City Daylight (terang).
/// Menggunakan Google Fonts Outfit untuk heading/angka finansial dan Inter untuk body.
ThemeData buildTheme([Brightness brightness = Brightness.dark]) {
  final colors = brightness == Brightness.dark
      ? AppThemeColors.viceCitySunset
      : AppThemeColors.viceCityDaylight;

  final baseScheme = brightness == Brightness.dark
      ? const ColorScheme.dark()
      : const ColorScheme.light();

  final scheme = baseScheme.copyWith(
    primary: colors.primary,
    onPrimary: colors.onPrimary,
    primaryContainer: colors.isDark
        ? colors.heroBackground
        : colors.surfaceContainer,
    onPrimaryContainer: colors.isDark ? Colors.white : colors.textPrimary,
    secondary: colors.accentSecondary,
    onSecondary: colors.isDark ? colors.onPrimary : Colors.white,
    surface: colors.cardSurface,
    onSurface: colors.textPrimary,
    onSurfaceVariant: colors.textMuted,
    surfaceContainerHighest: colors.surfaceContainer,
    outline: colors.inputBorder,
    outlineVariant: colors.borderOutline,
    error: colors.expense,
    onError: Colors.white,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
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
      constraints: const BoxConstraints(maxWidth: 640),
      dragHandleColor: colors.textMuted.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: colors.borderOutline, width: 1.0),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colors.isDark ? colors.surfaceContainer : colors.cardSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.borderOutline, width: 1.0),
      ),
      textStyle: TextStyle(color: colors.textPrimary),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.isDark
          ? colors.surfaceContainer
          : colors.cardSurface,
      contentTextStyle: TextStyle(color: colors.textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.borderOutline, width: 1.0),
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
          color: colors.isDark
              ? AppColors.goldenYellow.withValues(alpha: 0.45)
              : colors.borderOutline,
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
            return colors.primary;
          }
          return colors.surfaceContainer.withValues(
            alpha: colors.isDark ? 0.65 : 0.85,
          );
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.onPrimary;
          }
          return colors.isDark ? colors.accentSecondary : colors.textPrimary;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BorderSide(
              color: colors.isDark
                  ? AppColors.goldenYellow.withValues(alpha: 0.55)
                  : colors.primary,
              width: 1.2,
            );
          }
          return BorderSide(
            color: colors.isDark ? colors.borderOutline : colors.inputBorder,
            width: 1.0,
          );
        }),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colors.surfaceContainer.withValues(
        alpha: colors.isDark ? 0.65 : 0.85,
      ),
      selectedColor: colors.primary,
      secondarySelectedColor: colors.primary,
      labelStyle: TextStyle(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: TextStyle(
        color: colors.onPrimary,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(
        color: colors.isDark ? colors.borderOutline : colors.inputBorder,
        width: 1.0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      iconTheme: IconThemeData(color: colors.accentSecondary, size: 18),
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

/// Membangun tema gelap Vice City Sunset.
ThemeData buildDarkTheme() => buildTheme(Brightness.dark);

/// Membangun tema terang Vice City Daylight.
ThemeData buildLightTheme() => buildTheme(Brightness.light);

/// Token warna adaptif untuk Vice City Sunset (gelap) dan Vice City Daylight (terang).
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.isDark,
    required this.bg,
    required this.cardSurface,
    required this.surfaceContainer,
    required this.borderOutline,
    required this.inputBorder,
    required this.primary,
    required this.onPrimary,
    required this.accentSecondary,
    required this.highlightGold,
    required this.heroBackground,
    required this.fabBackground,
    required this.fabForeground,
    required this.income,
    required this.expense,
    required this.warning,
    required this.transfer,
    required this.onHeroIncome,
    required this.onHeroExpense,
    required this.textPrimary,
    required this.textMuted,
    required this.headerCanopyTop,
    required this.headerCanopyBottom,
    required this.verticalBgAsset,
    required this.heroBgAsset,
    required this.coastalBgAsset,
  });

  final bool isDark;
  final Color bg;
  final Color cardSurface;
  final Color surfaceContainer;
  final Color borderOutline;
  final Color inputBorder;
  final Color primary;
  final Color onPrimary;
  final Color accentSecondary;
  final Color highlightGold;
  final Color heroBackground;
  final Color fabBackground;
  final Color fabForeground;
  final Color income;
  final Color expense;
  final Color warning;
  final Color transfer;
  final Color onHeroIncome;
  final Color onHeroExpense;
  final Color textPrimary;
  final Color textMuted;
  final Color headerCanopyTop;
  final Color headerCanopyBottom;
  final String verticalBgAsset;
  final String heroBgAsset;
  final String coastalBgAsset;

  static const viceCitySunset = AppThemeColors(
    isDark: true,
    bg: AppColors.bg,
    cardSurface: AppColors.cardSurface,
    surfaceContainer: AppColors.surfaceContainer,
    borderOutline: AppColors.borderOutline,
    inputBorder: Color(0xFF8B6BB8),
    primary: AppColors.sage,
    onPrimary: AppColors.midnightNavy,
    accentSecondary: AppColors.neonCyan,
    highlightGold: AppColors.goldenYellow,
    heroBackground: AppColors.deepForest,
    fabBackground: AppColors.sage,
    fabForeground: AppColors.midnightNavy,
    income: AppColors.incomeOnDark,
    expense: AppColors.expenseOnDark,
    warning: AppColors.warning,
    transfer: Color(0xFF5EEAD4),
    onHeroIncome: AppColors.incomeOnDark,
    onHeroExpense: AppColors.expenseOnDark,
    textPrimary: AppColors.softWhite,
    textMuted: AppColors.mutedBlueGray,
    headerCanopyTop: AppColors.headerCanopyTop,
    headerCanopyBottom: AppColors.headerCanopyBottom,
    verticalBgAsset: 'assets/images/vice_city_vertical_bg.jpg',
    heroBgAsset: 'assets/images/vice_city_bg.jpg',
    coastalBgAsset: 'assets/images/coastal_sunset_bg.jpg',
  );

  static const viceCityDaylight = AppThemeColors(
    isDark: false,
    bg: Color(0xFFF8F5FC),
    cardSurface: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFEFE9F7),
    borderOutline: Color(0xFFD8CCE8),
    inputBorder: Color(0xFF8570A3),
    primary: Color(0xFFC2185B),
    onPrimary: Color(0xFFFFFFFF),
    accentSecondary: Color(0xFF006B73),
    highlightGold: Color(0xFF8F5B00),
    heroBackground: Color(0xFF0A4DA6),
    fabBackground: Color(0xFFC2185B),
    fabForeground: Color(0xFFFFFFFF),
    income: Color(0xFF047857),
    expense: Color(0xFFBE123C),
    warning: Color(0xFFB45309),
    transfer: Color(0xFF0F766E),
    onHeroIncome: Color(0xFF6EE7B7),
    onHeroExpense: Color(0xFFFECDD3),
    textPrimary: Color(0xFF1A0E33),
    textMuted: Color(0xFF584673),
    headerCanopyTop: Color(0xFF0A3D73),
    headerCanopyBottom: Color(0xFF0D2E5C),
    verticalBgAsset: 'assets/images/vice_city_daylight_vertical_bg.jpg',
    heroBgAsset: 'assets/images/vice_city_daylight_bg.jpg',
    coastalBgAsset: 'assets/images/coastal_daylight_bg.jpg',
  );

  /// Alias kanonikal untuk kompatibilitas mundur
  static const enchantedGlasshouse = viceCitySunset;
  static const botanical = viceCitySunset;

  /// Memetakan konstanta aksen palet gelap (misalnya dari engine non-context)
  /// ke token tema aktif agar kontras tetap terjaga di Light Mode.
  Color resolveAccent(Color raw) {
    if (isDark) return raw;
    if (raw == AppColors.income ||
        raw == AppColors.incomeOnDark ||
        raw == const Color(0xFF38B271)) {
      return income;
    }
    if (raw == AppColors.expense ||
        raw == AppColors.expenseOnDark ||
        raw == const Color(0xFFEF9A9A)) {
      return expense;
    }
    if (raw == AppColors.warning ||
        raw == AppColors.sunsetOrange ||
        raw == const Color(0xFFE8A33D)) {
      return warning;
    }
    if (raw == AppColors.sage || raw == AppColors.sunsetMagenta) {
      return primary;
    }
    if (raw == AppColors.neonCyan || raw == AppColors.freshSage) {
      return accentSecondary;
    }
    if (raw == AppColors.goldenYellow || raw == AppColors.dewMint) {
      return highlightGold;
    }
    if (raw == const Color(0xFF5EEAD4) || raw == const Color(0xFF00897B)) {
      return transfer;
    }
    return raw;
  }

  @override
  AppThemeColors copyWith({
    bool? isDark,
    Color? bg,
    Color? cardSurface,
    Color? surfaceContainer,
    Color? borderOutline,
    Color? inputBorder,
    Color? primary,
    Color? onPrimary,
    Color? accentSecondary,
    Color? highlightGold,
    Color? heroBackground,
    Color? fabBackground,
    Color? fabForeground,
    Color? income,
    Color? expense,
    Color? warning,
    Color? transfer,
    Color? onHeroIncome,
    Color? onHeroExpense,
    Color? textPrimary,
    Color? textMuted,
    Color? headerCanopyTop,
    Color? headerCanopyBottom,
    String? verticalBgAsset,
    String? heroBgAsset,
    String? coastalBgAsset,
  }) {
    return AppThemeColors(
      isDark: isDark ?? this.isDark,
      bg: bg ?? this.bg,
      cardSurface: cardSurface ?? this.cardSurface,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      borderOutline: borderOutline ?? this.borderOutline,
      inputBorder: inputBorder ?? this.inputBorder,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      highlightGold: highlightGold ?? this.highlightGold,
      heroBackground: heroBackground ?? this.heroBackground,
      fabBackground: fabBackground ?? this.fabBackground,
      fabForeground: fabForeground ?? this.fabForeground,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      warning: warning ?? this.warning,
      transfer: transfer ?? this.transfer,
      onHeroIncome: onHeroIncome ?? this.onHeroIncome,
      onHeroExpense: onHeroExpense ?? this.onHeroExpense,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      headerCanopyTop: headerCanopyTop ?? this.headerCanopyTop,
      headerCanopyBottom: headerCanopyBottom ?? this.headerCanopyBottom,
      verticalBgAsset: verticalBgAsset ?? this.verticalBgAsset,
      heroBgAsset: heroBgAsset ?? this.heroBgAsset,
      coastalBgAsset: coastalBgAsset ?? this.coastalBgAsset,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      isDark: t < 0.5 ? isDark : other.isDark,
      bg: Color.lerp(bg, other.bg, t) ?? bg,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t) ?? cardSurface,
      surfaceContainer:
          Color.lerp(surfaceContainer, other.surfaceContainer, t) ??
          surfaceContainer,
      borderOutline:
          Color.lerp(borderOutline, other.borderOutline, t) ?? borderOutline,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t) ?? inputBorder,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t) ?? onPrimary,
      accentSecondary:
          Color.lerp(accentSecondary, other.accentSecondary, t) ??
          accentSecondary,
      highlightGold:
          Color.lerp(highlightGold, other.highlightGold, t) ?? highlightGold,
      heroBackground:
          Color.lerp(heroBackground, other.heroBackground, t) ?? heroBackground,
      fabBackground:
          Color.lerp(fabBackground, other.fabBackground, t) ?? fabBackground,
      fabForeground:
          Color.lerp(fabForeground, other.fabForeground, t) ?? fabForeground,
      income: Color.lerp(income, other.income, t) ?? income,
      expense: Color.lerp(expense, other.expense, t) ?? expense,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      transfer: Color.lerp(transfer, other.transfer, t) ?? transfer,
      onHeroIncome:
          Color.lerp(onHeroIncome, other.onHeroIncome, t) ?? onHeroIncome,
      onHeroExpense:
          Color.lerp(onHeroExpense, other.onHeroExpense, t) ?? onHeroExpense,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      headerCanopyTop:
          Color.lerp(headerCanopyTop, other.headerCanopyTop, t) ??
          headerCanopyTop,
      headerCanopyBottom:
          Color.lerp(headerCanopyBottom, other.headerCanopyBottom, t) ??
          headerCanopyBottom,
      verticalBgAsset: t < 0.5 ? verticalBgAsset : other.verticalBgAsset,
      heroBgAsset: t < 0.5 ? heroBgAsset : other.heroBgAsset,
      coastalBgAsset: t < 0.5 ? coastalBgAsset : other.coastalBgAsset,
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

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Shortcut praktis untuk mendapatkan gaya teks angka finansial.
  TextStyle moneyStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) => appMoneyStyle(
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
  }) => appMonoStyle(
    this,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
  );
}
