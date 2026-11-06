/// Komponen identitas visual brand Wall o' Pay: logo ([BrandMark]) dan layar pembuka ([SplashPage]).
library;

import 'package:flutter/material.dart';

import 'botanical_decorations.dart';
import 'l10n.dart';
import 'theme.dart';

/// Logo Wall o' Pay (gambar dari assets/images/logo.png atau logo_cyberpunk.png).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isCyber = context.isCyberpunk;
    return Image.asset(
      isCyber ? 'assets/images/logo_cyberpunk.png' : 'assets/images/logo.png',
      width: size,
      height: size,
      cacheWidth: (size * 3).round(),
      filterQuality: FilterQuality.medium,
      semanticLabel: "Wall o' Pay",
    );
  }
}

/// Painter gelombang halus berwarna sage di bagian bawah layar splash.
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    void wave(double base, double amp, Color color) {
      final w = size.width;
      final h = size.height;
      final path = Path()
        ..moveTo(0, h * base)
        ..cubicTo(w * 0.3, h * (base - amp), w * 0.6, h * (base + amp), w, h * (base - amp / 2))
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    wave(0.72, 0.07, AppColors.sage.withValues(alpha: 0.35));
    wave(0.82, 0.06, AppColors.sage.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Layar sambutan awal (splash screen) dengan logo dan slogan aplikasi.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCyber = context.isCyberpunk;
    final colors = context.themeColors;

    return Scaffold(
      backgroundColor: isCyber ? colors.bg : AppColors.ivory,
      body: Stack(
        children: [
          if (!isCyber)
            Positioned.fill(child: CustomPaint(painter: _WavePainter()))
          else
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: CyberCanopyPainter()),
              ),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(size: 76),
                const SizedBox(height: 18),
                Text(
                  "Wall o' Pay",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isCyber ? colors.textPrimary : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('Your money, under your control.'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isCyber
                        ? colors.textMuted
                        : AppColors.ink.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
