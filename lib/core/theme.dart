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

/// Membangun objek [ThemeData] Material 3 dengan palet gelap Botanical Forest.
ThemeData buildTheme([Brightness brightness = Brightness.dark]) {
  final scheme = const ColorScheme.dark().copyWith(
    primary: AppColors.sage,
    onPrimary: AppColors.ink,
    primaryContainer: AppColors.deepForest,
    onPrimaryContainer: Colors.white,
    secondary: AppColors.sage,
    onSecondary: AppColors.ink,
    surface: AppColors.cardSurface,
    onSurface: const Color(0xFFE9EFEA),
    surfaceContainerHighest: AppColors.surfaceContainer,
    outline: AppColors.borderOutline,
    outlineVariant: AppColors.borderOutline,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
  );

  final styledTextTheme = _applyTabularFigures(
    GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: const Color(0xFFE9EFEA),
      displayColor: const Color(0xFFE9EFEA),
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    cardColor: AppColors.cardSurface,
    canvasColor: AppColors.cardSurface,
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.cardSurface),
    textTheme: styledTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: Color(0xFFE9EFEA)),
      titleTextStyle: TextStyle(
        color: Color(0xFFE9EFEA),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.cardSurface,
      selectedItemColor: AppColors.sage,
      unselectedItemColor: Color(0xFF7E9687),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.cardSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(color: Color(0xFFE9EFEA)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceContainer,
      contentTextStyle: const TextStyle(color: Color(0xFFE9EFEA)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.sage,
      foregroundColor: AppColors.ink,
      elevation: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        backgroundColor: AppColors.sage,
        foregroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ),
  );
}
