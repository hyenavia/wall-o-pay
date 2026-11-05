import 'package:flutter/material.dart';
import 'theme.dart';

/// Painter kanopi daun botani melengkung halus untuk header (AppBar & HomeHeader).
class BotanicalCanopyPainter extends CustomPainter {
  const BotanicalCanopyPainter({
    this.color = AppColors.sage,
    this.opacity = 0.08,
  });

  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // Ranting & dedaunan melengkung di sudut kanan atas
    final rightPath = Path();
    final w = size.width;
    final h = size.height;

    // Daun 1 (besar, menjuntai dari kanan atas)
    rightPath.moveTo(w, 0);
    rightPath.quadraticBezierTo(w - 70, h * 0.15, w - 100, h * 0.55);
    rightPath.quadraticBezierTo(w - 45, h * 0.40, w, h * 0.25);
    rightPath.close();
    canvas.drawPath(rightPath, paint);

    // Daun 2 (medium, sedikit miring)
    final leaf2 = Path();
    leaf2.moveTo(w - 15, 0);
    leaf2.quadraticBezierTo(w - 90, h * 0.35, w - 130, h * 0.85);
    leaf2.quadraticBezierTo(w - 75, h * 0.70, w - 50, h * 0.30);
    leaf2.close();
    canvas.drawPath(leaf2, paint);

    // Daun 3 (aksen kecil)
    final leaf3 = Path();
    leaf3.moveTo(w - 60, 0);
    leaf3.quadraticBezierTo(w - 120, h * 0.20, w - 150, h * 0.45);
    leaf3.quadraticBezierTo(w - 105, h * 0.35, w - 80, 0);
    leaf3.close();
    canvas.drawPath(leaf3, paint);

    // Siluet tangkai halus dari kanan
    final stemPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final stemPath = Path();
    stemPath.moveTo(w, 0);
    stemPath.quadraticBezierTo(w - 80, h * 0.30, w - 125, h * 0.80);
    canvas.drawPath(stemPath, stemPaint);
  }

  @override
  bool shouldRepaint(covariant BotanicalCanopyPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.opacity != opacity;
}

/// Painter aksen kartu finansial premium (Forest Aurora Glow & Contour Rings) untuk HeroCard.
class BotanicalHeroCardPainter extends CustomPainter {
  const BotanicalHeroCardPainter({
    this.glowColor = AppColors.income,
    this.lineColor = AppColors.sage,
  });

  final Color glowColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    // 1. Aurora Glow halus di sudut kanan atas (gradasi diagonal bernuansa mint/emerald)
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, -0.75),
        radius: 0.9,
        colors: [
          glowColor.withValues(alpha: 0.16),
          AppColors.sage.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), glowPaint);

    // 2. Garis kontur topografi / cincin pertumbuhan melengkung halus di sudut kanan bawah (opasitas 4%-6%)
    final strokePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final center = Offset(w * 1.05, h * 1.05);

    // 3 lapis cincin kurva melengkung lembut
    canvas.drawCircle(center, w * 0.28, strokePaint);
    canvas.drawCircle(center, w * 0.44, strokePaint);
    canvas.drawCircle(center, w * 0.60, strokePaint);
  }

  @override
  bool shouldRepaint(covariant BotanicalHeroCardPainter oldDelegate) =>
      oldDelegate.glowColor != glowColor || oldDelegate.lineColor != lineColor;
}

/// Painter latar belakang utama (soft radial glow & siluet daun ekstra halus).
class BotanicalBackgroundPainter extends CustomPainter {
  const BotanicalBackgroundPainter({
    this.color = AppColors.sage,
  });

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    // 1. Soft Emerald Radial Glow di kanan atas
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.7, -0.6),
        radius: 0.9,
        colors: [
          AppColors.sage.withValues(alpha: 0.04),
          AppColors.deepForest.withValues(alpha: 0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), glowPaint);

    // 2. Siluet daun ekstra tipis (2.5% opacity) di sudut kiri bawah layar
    final bgLeafPaint = Paint()
      ..color = color.withValues(alpha: 0.025)
      ..style = PaintingStyle.fill;

    final bgLeaf = Path();
    bgLeaf.moveTo(-20, h + 20);
    bgLeaf.cubicTo(
      w * 0.10,
      h * 0.85,
      w * 0.25,
      h * 0.75,
      w * 0.35,
      h * 0.88,
    );
    bgLeaf.cubicTo(
      w * 0.20,
      h * 0.95,
      w * 0.10,
      h * 1.05,
      -20,
      h + 20,
    );
    bgLeaf.close();
    canvas.drawPath(bgLeaf, bgLeafPaint);

    // Daun kedua tipis di kanan bawah
    final bgLeaf2 = Path();
    bgLeaf2.moveTo(w + 30, h * 0.75);
    bgLeaf2.cubicTo(
      w * 0.85,
      h * 0.82,
      w * 0.75,
      h * 0.92,
      w * 0.82,
      h + 20,
    );
    bgLeaf2.cubicTo(
      w * 0.92,
      h * 0.95,
      w * 0.98,
      h * 0.85,
      w + 30,
      h * 0.75,
    );
    bgLeaf2.close();
    canvas.drawPath(bgLeaf2, bgLeafPaint);
  }

  @override
  bool shouldRepaint(covariant BotanicalBackgroundPainter oldDelegate) =>
      oldDelegate.color != color;
}
