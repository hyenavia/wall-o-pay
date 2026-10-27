import 'package:flutter/material.dart';

import 'l10n.dart';
import 'theme.dart';

/// Logo Wall o' Pay (gambar dari assets/images/logo.png).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      cacheWidth: (size * 3).round(),
      filterQuality: FilterQuality.medium,
      semanticLabel: "Wall o' Pay",
    );
  }
}

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

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _WavePainter())),
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
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('Your money, under your control.'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.65),
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
