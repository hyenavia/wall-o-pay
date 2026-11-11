/// Kumpulan [CustomPainter] untuk menggambar ornamen dedaunan dan efek cahaya (glow)
/// bertema Botanical Forest pada header, kartu sorotan (HeroCard), dan latar belakang halaman.
library;

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

    // 3. Garis lengkung kubah kaca konservatori halus (Enchanted Glasshouse Vault Arch)
    final archPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final archPath = Path()
      ..moveTo(0, h * 0.85)
      ..quadraticBezierTo(w * 0.5, -h * 0.15, w, h * 0.85);
    canvas.drawPath(archPath, archPaint);

    final innerArch = Path()
      ..moveTo(w * 0.12, h * 0.9)
      ..quadraticBezierTo(w * 0.5, 0, w * 0.88, h * 0.9);
    canvas.drawPath(innerArch, archPaint);
  }

  @override
  bool shouldRepaint(covariant BotanicalHeroCardPainter oldDelegate) =>
      oldDelegate.glowColor != glowColor || oldDelegate.lineColor != lineColor;
}

/// Painter latar belakang utama bertema Enchanted Glasshouse:
/// gradasi bias cahaya matahari (sunbeam glow), arsitektur kubah kaca konservatori,
/// serta juntaian tanaman merambat rimbun dengan dedaunan presisi tinggi dan tetesan embun.
class BotanicalBackgroundPainter extends CustomPainter {
  const BotanicalBackgroundPainter({
    this.color = AppColors.freshSage,
  });

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    // 1. Soft Sunbeam Radial Glow di bagian atas (cahaya menembus kaca konservatori)
    final sunbeamPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.4, -0.75),
        radius: 1.1,
        colors: [
          AppColors.dewMint.withValues(alpha: 0.10),
          AppColors.emeraldLeaf.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sunbeamPaint);

    // 2. Lengkungan Kubah Kaca Konservatori (Vaulted Glass Arches)
    final archPaint = Paint()
      ..color = AppColors.dewMint.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final archCenter = Path();
    archCenter.moveTo(w * 0.06, 0);
    archCenter.cubicTo(w * 0.06, h * 0.28, w * 0.94, h * 0.28, w * 0.94, 0);
    canvas.drawPath(archCenter, archPaint);

    final archInner = Path();
    archInner.moveTo(w * 0.20, 0);
    archInner.cubicTo(w * 0.20, h * 0.20, w * 0.80, h * 0.20, w * 0.80, 0);
    canvas.drawPath(archInner, archPaint);

    final rayPaint = Paint()
      ..color = AppColors.dewMint.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawLine(Offset(w * 0.5, 0), Offset(w * 0.5, h * 0.28), rayPaint);
    canvas.drawLine(Offset(w * 0.32, 0), Offset(w * 0.25, h * 0.24), rayPaint);
    canvas.drawLine(Offset(w * 0.68, 0), Offset(w * 0.75, h * 0.24), rayPaint);

    // 3. Cat dan Kuas untuk Dedaunan Presisi Tinggi
    final leafFill = Paint()
      ..color = color.withValues(alpha: 0.085)
      ..style = PaintingStyle.fill;

    final leafFillDeep = Paint()
      ..color = AppColors.emeraldLeaf.withValues(alpha: 0.075)
      ..style = PaintingStyle.fill;

    final ribPaint = Paint()
      ..color = AppColors.dewMint.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final stemPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final dewPaint = Paint()
      ..color = AppColors.dewMint.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    final dewGlow = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    // Helper untuk menggambar 1 helai daun presisi dengan tulang daun & urat lateral
    void drawLeaf({
      required Offset origin,
      required double angle,
      required double length,
      required double width,
      Paint? customFill,
    }) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.rotate(angle);

      final p = Path();
      p.moveTo(0, 0);
      p.cubicTo(-width * 0.48, length * 0.32, -width * 0.52, length * 0.72, 0, length);
      p.cubicTo(width * 0.52, length * 0.72, width * 0.48, length * 0.32, 0, 0);
      p.close();
      canvas.drawPath(p, customFill ?? leafFill);

      // Tulang daun utama (midrib)
      canvas.drawLine(const Offset(0, 0), Offset(0, length * 0.92), ribPaint);

      // Urat daun lateral simetris
      for (final t in [0.28, 0.50, 0.72]) {
        final y = length * t;
        final wVein = width * 0.35 * (1.0 - (t - 0.5).abs());
        canvas.drawLine(Offset(0, y), Offset(-wVein, y - length * 0.09), ribPaint);
        canvas.drawLine(Offset(0, y), Offset(wVein, y - length * 0.09), ribPaint);
      }

      canvas.restore();
    }

    void drawDewDrop(Offset center, double radius) {
      canvas.drawCircle(center, radius, dewPaint);
      canvas.drawCircle(Offset(center.dx - radius * 0.25, center.dy - radius * 0.25), radius * 0.35, dewGlow);
    }

    // --- A. Juntaian Ranting & Dedaunan Kanan Atas (Cascading Conservatory Ivy) ---
    final ivyStemRight = Path();
    ivyStemRight.moveTo(w, 0);
    ivyStemRight.cubicTo(w - 30, h * 0.06, w - 55, h * 0.14, w - 25, h * 0.26);
    ivyStemRight.cubicTo(w - 10, h * 0.32, w - 35, h * 0.40, w - 15, h * 0.48);
    canvas.drawPath(ivyStemRight, stemPaint);

    final rightLeaves = [
      (Offset(w - 15, h * 0.04), 0.8, 28.0, 15.0),
      (Offset(w - 38, h * 0.08), -0.6, 26.0, 14.0),
      (Offset(w - 28, h * 0.12), 1.1, 25.0, 13.0),
      (Offset(w - 52, h * 0.16), -0.9, 24.0, 13.0),
      (Offset(w - 38, h * 0.21), 0.7, 22.0, 12.0),
      (Offset(w - 20, h * 0.27), -0.4, 20.0, 11.0),
      (Offset(w - 26, h * 0.34), 0.9, 19.0, 10.0),
      (Offset(w - 18, h * 0.41), -0.6, 17.0, 9.5),
      (Offset(w - 15, h * 0.48), 0.3, 14.0, 7.5),
    ];
    for (final l in rightLeaves) {
      drawLeaf(origin: l.$1, angle: l.$2, length: l.$3, width: l.$4);
    }
    drawDewDrop(Offset(w - 40, h * 0.17), 2.2);
    drawDewDrop(Offset(w - 28, h * 0.35), 1.8);

    // --- B. Ranting Merambat Kiri Atas (Cascading Tendril) ---
    final ivyStemLeft = Path();
    ivyStemLeft.moveTo(0, h * 0.02);
    ivyStemLeft.cubicTo(w * 0.08, h * 0.05, w * 0.14, h * 0.12, w * 0.06, h * 0.22);
    canvas.drawPath(ivyStemLeft, stemPaint);

    final leftLeaves = [
      (Offset(w * 0.03, h * 0.04), -0.7, 25.0, 13.0),
      (Offset(w * 0.09, h * 0.07), 0.9, 24.0, 13.0),
      (Offset(w * 0.13, h * 0.12), -0.5, 22.0, 12.0),
      (Offset(w * 0.10, h * 0.17), 1.2, 20.0, 11.0),
      (Offset(w * 0.06, h * 0.22), -0.2, 16.0, 8.5),
    ];
    for (final l in leftLeaves) {
      drawLeaf(origin: l.$1, angle: l.$2, length: l.$3, width: l.$4);
    }
    drawDewDrop(Offset(w * 0.11, h * 0.13), 2.0);

    // --- C. Semak Dedaunan Botani Rimbun Kiri Bawah (Lush Understory Foliage) ---
    final stemBottomLeft = Path();
    stemBottomLeft.moveTo(-20, h + 10);
    stemBottomLeft.cubicTo(w * 0.12, h * 0.90, w * 0.22, h * 0.85, w * 0.38, h * 0.88);
    canvas.drawPath(stemBottomLeft, stemPaint);

    final bottomLeftCluster = [
      // Lapisan daun besar belakang (warna lebih gelap)
      (Offset(w * 0.05, h * 0.88), -1.8, 48.0, 24.0, leafFillDeep),
      (Offset(w * 0.14, h * 0.83), -1.4, 44.0, 22.0, leafFillDeep),
      (Offset(w * 0.25, h * 0.82), -1.1, 40.0, 20.0, leafFillDeep),
      (Offset(w * 0.35, h * 0.85), -0.8, 34.0, 17.0, leafFillDeep),
      // Lapisan daun depan lebih cerah & bervariasi
      (Offset(w * 0.02, h * 0.94), -2.2, 38.0, 20.0, leafFill),
      (Offset(w * 0.10, h * 0.89), -1.6, 36.0, 18.0, leafFill),
      (Offset(w * 0.18, h * 0.86), -1.2, 34.0, 17.0, leafFill),
      (Offset(w * 0.28, h * 0.84), -0.9, 30.0, 15.0, leafFill),
      (Offset(w * 0.38, h * 0.88), -0.5, 24.0, 12.0, leafFill),
      // Daun aksen menjuntai ke bawah
      (Offset(w * 0.12, h * 0.96), -2.6, 32.0, 16.0, leafFill),
      (Offset(w * 0.22, h * 0.93), -2.1, 28.0, 14.0, leafFill),
    ];
    for (final l in bottomLeftCluster) {
      drawLeaf(
        origin: l.$1,
        angle: l.$2,
        length: l.$3,
        width: l.$4,
        customFill: l.$5,
      );
    }
    drawDewDrop(Offset(w * 0.13, h * 0.85), 2.5);
    drawDewDrop(Offset(w * 0.26, h * 0.84), 2.0);

    // --- D. Semak Dedaunan Kanan Bawah (Lush Trailing Foliage) ---
    final stemBottomRight = Path();
    stemBottomRight.moveTo(w + 30, h * 0.80);
    stemBottomRight.cubicTo(w * 0.84, h * 0.86, w * 0.76, h * 0.92, w * 0.68, h + 15);
    canvas.drawPath(stemBottomRight, stemPaint);

    final bottomRightCluster = [
      (Offset(w * 0.92, h * 0.82), 1.9, 42.0, 21.0, leafFillDeep),
      (Offset(w * 0.84, h * 0.85), 1.5, 38.0, 19.0, leafFillDeep),
      (Offset(w * 0.75, h * 0.89), 1.1, 35.0, 18.0, leafFillDeep),
      (Offset(w * 0.96, h * 0.88), 2.3, 34.0, 17.0, leafFill),
      (Offset(w * 0.88, h * 0.90), 1.7, 32.0, 16.0, leafFill),
      (Offset(w * 0.80, h * 0.93), 1.3, 28.0, 14.0, leafFill),
      (Offset(w * 0.70, h * 0.97), 0.9, 22.0, 11.0, leafFill),
    ];
    for (final l in bottomRightCluster) {
      drawLeaf(
        origin: l.$1,
        angle: l.$2,
        length: l.$3,
        width: l.$4,
        customFill: l.$5,
      );
    }
    drawDewDrop(Offset(w * 0.85, h * 0.87), 2.2);
  }

  @override
  bool shouldRepaint(covariant BotanicalBackgroundPainter oldDelegate) =>
      oldDelegate.color != color;
}
