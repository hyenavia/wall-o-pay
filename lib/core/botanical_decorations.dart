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
  });

  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    // Pendaran radial lembut sunset magenta & neon cyan di sudut kanan atas (tanpa daun)
    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, -0.6),
        radius: 0.9,
        colors: [
          AppColors.sunsetMagenta.withValues(alpha: opacity * 0.9),
          AppColors.neonCyan.withValues(alpha: opacity * 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), glow);
  }

  @override
  bool shouldRepaint(covariant BotanicalCanopyPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.opacity != opacity;
}

/// Painter aksen kartu finansial premium (Vice City Sunset Glow & Neon Rings) untuk HeroCard.
class BotanicalHeroCardPainter extends CustomPainter {
  const BotanicalHeroCardPainter({
    this.glowColor = AppColors.sunsetMagenta,
    this.lineColor = AppColors.neonCyan,
  });

  final Color glowColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    // 1. Vice City Sunset Glow di sudut kanan atas
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, -0.75),
        radius: 0.9,
        colors: [
          glowColor.withValues(alpha: 0.16),
          AppColors.sunsetOrange.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), glowPaint);

    // 2. Neon contour rings halus di sudut kanan bawah
    final strokePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final center = Offset(w * 1.05, h * 1.05);
    canvas.drawCircle(center, w * 0.28, strokePaint);
    canvas.drawCircle(center, w * 0.44, strokePaint);
  }

  @override
  bool shouldRepaint(covariant BotanicalHeroCardPainter oldDelegate) =>
      oldDelegate.glowColor != glowColor || oldDelegate.lineColor != lineColor;
}

/// Painter latar belakang utama bertema Vice City Sunset:
/// gradasi bias cahaya senja tropis (sunset radial glow) bersih tanpa siluet daun botani lama.
class BotanicalBackgroundPainter extends CustomPainter {
  const BotanicalBackgroundPainter({
    this.color = AppColors.neonCyan,
  });

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    // Soft Sunset Ambient Glow di bagian atas (cahaya bias senja tropis)
    final sunbeamPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.4, -0.75),
        radius: 1.1,
        colors: [
          AppColors.sunsetOrange.withValues(alpha: 0.08),
          AppColors.sunsetMagenta.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sunbeamPaint);
  }

  @override
  bool shouldRepaint(covariant BotanicalBackgroundPainter oldDelegate) =>
      oldDelegate.color != color;
}
