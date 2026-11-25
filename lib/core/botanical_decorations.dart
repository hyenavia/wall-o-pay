/// Kumpulan [CustomPainter] untuk menggambar ornamen pesisir tropis,
/// garis gelombang busur neon (neon arc waves), dan efek cahaya sunset (sunset glow)
/// bertema Vice City Sunset (Balanced) pada header, kartu sorotan (HeroCard), dan latar belakang halaman.
library;

import 'package:flutter/material.dart';
import 'theme.dart';

typedef ViceCityCanopyPainter = BotanicalCanopyPainter;
typedef ViceCityHeroCardPainter = BotanicalHeroCardPainter;
typedef ViceCityBackgroundPainter = BotanicalBackgroundPainter;

/// Painter pendaran sunset halus tanpa dedaunan untuk header (AppBar & HomeHeader).
class BotanicalCanopyPainter extends CustomPainter {
  const BotanicalCanopyPainter({
    this.color = AppColors.neonCyan,
    this.opacity = 0.08,
    this.isDark = true,
  });

  final Color color;
  final double opacity;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, -0.6),
        radius: 0.9,
        colors: isDark
            ? [
                AppColors.sunsetMagenta.withValues(alpha: opacity * 0.9),
                AppColors.neonCyan.withValues(alpha: opacity * 0.4),
                Colors.transparent,
              ]
            : [
                AppColors.neonCyan.withValues(alpha: opacity * 0.75),
                AppColors.goldenYellow.withValues(alpha: opacity * 0.35),
                Colors.transparent,
              ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), glow);
  }

  @override
  bool shouldRepaint(covariant BotanicalCanopyPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.opacity != opacity ||
      oldDelegate.isDark != isDark;
}

/// Painter aksen kartu finansial premium (Vice City Sunset Glow & Neon Rings) untuk HeroCard.
class BotanicalHeroCardPainter extends CustomPainter {
  const BotanicalHeroCardPainter({
    this.glowColor = AppColors.sunsetMagenta,
    this.lineColor = AppColors.neonCyan,
    this.isDark = true,
  });

  final Color glowColor;
  final Color lineColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    // 1. Vice City Sunset / Daylight Glow di sudut kanan atas
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, -0.75),
        radius: 0.9,
        colors: isDark
            ? [
                glowColor.withValues(alpha: 0.16),
                AppColors.sunsetOrange.withValues(alpha: 0.08),
                Colors.transparent,
              ]
            : [
                Colors.white.withValues(alpha: 0.14),
                AppColors.neonCyan.withValues(alpha: 0.10),
                Colors.transparent,
              ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), glowPaint);

    // 2. Contour rings halus di sudut kanan bawah
    final strokePaint = Paint()
      ..color = (isDark ? lineColor : Colors.white).withValues(alpha: isDark ? 0.06 : 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final center = Offset(w * 1.05, h * 1.05);
    canvas.drawCircle(center, w * 0.28, strokePaint);
    canvas.drawCircle(center, w * 0.44, strokePaint);
  }

  @override
  bool shouldRepaint(covariant BotanicalHeroCardPainter oldDelegate) =>
      oldDelegate.glowColor != glowColor ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.isDark != isDark;
}

/// Painter latar belakang utama bertema Vice City Sunset / Daylight:
/// gradasi bias cahaya senja atau pagi tropis bersih tanpa siluet daun botani lama.
class BotanicalBackgroundPainter extends CustomPainter {
  const BotanicalBackgroundPainter({
    this.color = AppColors.neonCyan,
    this.isDark = true,
  });

  final Color color;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    final sunbeamPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.4, -0.75),
        radius: 1.1,
        colors: isDark
            ? [
                AppColors.sunsetOrange.withValues(alpha: 0.08),
                AppColors.sunsetMagenta.withValues(alpha: 0.05),
                Colors.transparent,
              ]
            : [
                const Color(0xFF00A6FF).withValues(alpha: 0.05),
                const Color(0xFFFF4D8D).withValues(alpha: 0.04),
                Colors.transparent,
              ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sunbeamPaint);
  }

  @override
  bool shouldRepaint(covariant BotanicalBackgroundPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isDark != isDark;
}
