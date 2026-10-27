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

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.deepForest,
    brightness: brightness,
  ).copyWith(
    primary: dark ? AppColors.sage : AppColors.deepForest,
    onPrimary: dark ? AppColors.ink : Colors.white,
    primaryContainer: dark ? const Color(0xFF2C5A47) : const Color(0xFFDCE9E0),
    onPrimaryContainer: dark ? Colors.white : AppColors.deepForest,
    secondary: AppColors.sage,
    surface: dark ? const Color(0xFF1B231E) : Colors.white,
    onSurface: dark ? const Color(0xFFE9EFEA) : AppColors.ink,
    outlineVariant: dark ? const Color(0xFF2F3A33) : const Color(0xFFE6EAE3),
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
  );

  return base.copyWith(
    scaffoldBackgroundColor: dark ? const Color(0xFF131915) : AppColors.ivory,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
    ),
  );
}
