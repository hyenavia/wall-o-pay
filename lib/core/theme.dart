import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet dari desain Wall o' Pay.
class AppColors {
  static const deepForest = Color(0xFF234B3B);
  static const sage = Color(0xFFA9C5B1);
  static const ivory = Color(0xFFF7F8F4);
  static const ink = Color(0xFF202923);
  static const income = Color(0xFF2E8B57);
  static const expense = Color(0xFFD64545);
  static const warning = Color(0xFFE8A33D);
}

ThemeData buildTheme([Brightness brightness = Brightness.dark]) {
  // Palet Signature Botanical Forest eksklusif Wall o' Pay
  const bg = Color(0xFF101713); // Atmospheric Night Forest Charcoal
  const cardSurface = Color(0xFF18221C); // Velvet Deep Forest Surface
  const surfaceContainer = Color(0xFF202C24); // Elevated Container
  const borderOutline = Color(0xFF28382E); // Subtle Pine Border

  final scheme = const ColorScheme.dark().copyWith(
    primary: AppColors.sage,
    onPrimary: AppColors.ink,
    primaryContainer: AppColors.deepForest,
    onPrimaryContainer: Colors.white,
    secondary: AppColors.sage,
    onSecondary: AppColors.ink,
    surface: cardSurface,
    onSurface: const Color(0xFFE9EFEA),
    surfaceContainerHighest: surfaceContainer,
    outline: borderOutline,
    outlineVariant: borderOutline,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
  );

  return base.copyWith(
    scaffoldBackgroundColor: bg,
    cardColor: cardSurface,
    canvasColor: cardSurface,
    dialogTheme: const DialogThemeData(backgroundColor: cardSurface),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: const Color(0xFFE9EFEA),
      displayColor: const Color(0xFFE9EFEA),
    ),
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
      backgroundColor: cardSurface,
      selectedItemColor: AppColors.sage,
      unselectedItemColor: Color(0xFF6B7E72),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        backgroundColor: AppColors.deepForest,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
    ),
  );
}
