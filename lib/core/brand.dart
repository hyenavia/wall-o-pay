/// Komponen identitas visual brand Wall o' Pay: logo ([BrandMark]) dan layar pembuka ([SplashPage]).
library;

import 'package:flutter/material.dart';

export '../features/splash/splash_page.dart';

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
