/// Layar pembuka (Splash Screen) bertema Enchanted Glasshouse untuk Wall o' Pay.
/// Menampilkan perpaduan arsitektur rumah kaca modern, elemen kaca transparan,
/// dedaunan botani emerald/sage, serta tunas bertumbuh di dalam lengkungan kaca.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';

/// Simbol kombinasi (combination logo) Wall o' Pay bertema Enchanted Glasshouse:
/// Menampilkan lengkungan arsitektur rumah kaca modern (vaulted glasshouse arch),
/// tunas botani bertumbuh di atas koin finansial, dan cincin orbit bercahaya.
class GlasshouseCombinationLogo extends StatelessWidget {
  const GlasshouseCombinationLogo({
    super.key,
    this.size = 136,
    this.showGlow = true,
    this.useWordmark = false,
  });

  final double size;
  final bool showGlow;
  final bool useWordmark;

  @override
  Widget build(BuildContext context) {
    if (useWordmark) {
      return Image.asset(
        'assets/images/logo_wordmark.png',
        width: size * 2.2,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }

    final imageWidget = Image.asset(
      'assets/images/logo_glasshouse.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: "Wall o' Pay",
    );

    if (!showGlow) return imageWidget;

    return SizedBox(
      width: size * 1.25,
      height: size * 1.25,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient Halo Glow bernuansa botanical dew mint & emerald
          Container(
            width: size * 1.15,
            height: size * 1.15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.dewMint.withValues(alpha: 0.25),
                  AppColors.emeraldLeaf.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          imageWidget,
        ],
      ),
    );
  }
}

/// Painter latar belakang Enchanted Glasshouse:
/// - Gradasi dalam Moss Shadow (#10251F) & Glasshouse Green (#23483B).
/// - Siluet dedaunan emerald dan sage di bagian tepi.
/// - Sinar matahari lembut (soft sunbeam rays) yang menembus panel kaca.
/// - Refleksi kaca dan partikel cahaya halus (floating dew motes).
class EnchantedGlasshouseBackgroundPainter extends CustomPainter {
  EnchantedGlasshouseBackgroundPainter({
    required this.sunbeamAnimation,
    required this.particleAnimation,
  }) : super(repaint: Listenable.merge([sunbeamAnimation, particleAnimation]));

  final Animation<double> sunbeamAnimation;
  final Animation<double> particleAnimation;

  // Koordinat partikel tetap agar pergerakan halus tanpa re-seed acak
  static const List<_MoteData> _motes = [
    _MoteData(0.18, 0.28, 1.6, 0.35, 1.0),
    _MoteData(0.82, 0.22, 2.0, 0.40, 1.2),
    _MoteData(0.28, 0.45, 1.4, 0.25, 0.8),
    _MoteData(0.72, 0.48, 1.8, 0.38, 1.1),
    _MoteData(0.14, 0.65, 2.2, 0.30, 0.9),
    _MoteData(0.85, 0.68, 1.5, 0.42, 1.3),
    _MoteData(0.40, 0.78, 1.8, 0.28, 1.0),
    _MoteData(0.60, 0.82, 1.4, 0.32, 0.9),
    _MoteData(0.24, 0.15, 1.2, 0.25, 1.1),
    _MoteData(0.76, 0.36, 1.7, 0.30, 1.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    // 1. Kanvas Latar Belakang Gradasi Moss Shadow & Glasshouse Green
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.2, -0.6),
        radius: 1.35,
        colors: [
          const Color(0xFF1D3E33),
          AppColors.glasshouseGreen.withValues(alpha: 0.92),
          AppColors.mossShadow,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. Efek Cahaya Matahari Menembus Kaca (Soft Conservatory Sunbeams)
    final sunProgress = sunbeamAnimation.value;
    final sunAlpha = 0.05 + 0.04 * math.sin(sunProgress * math.pi * 2);
    final beamOffset = math.sin(sunProgress * math.pi * 2) * 14.0;

    void drawSunbeam(double startX, double beamWidth, double angle) {
      final beamPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.dewMint.withValues(alpha: sunAlpha * 1.5),
            const Color(0xFFFAF4D0).withValues(alpha: sunAlpha * 0.9),
            Colors.transparent,
          ],
          stops: const [0.0, 0.30, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h));

      final path = Path()
        ..moveTo(startX + beamOffset, -10)
        ..lineTo(startX + beamOffset + beamWidth, -10)
        ..lineTo(startX + beamOffset + beamWidth + h * math.tan(angle), h)
        ..lineTo(startX + beamOffset + h * math.tan(angle), h)
        ..close();
      canvas.drawPath(path, beamPaint);
    }

    drawSunbeam(w * 0.48, w * 0.22, 0.34);
    drawSunbeam(w * 0.70, w * 0.18, 0.30);
    drawSunbeam(w * 0.25, w * 0.14, 0.38);

    // 3. Garis Struktur Atap Kaca Konservatori (Subtle Glass Vault Trusses)
    final trussPaint = Paint()
      ..color = AppColors.dewMint.withValues(alpha: 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final trussArch1 = Path()
      ..moveTo(0, h * 0.14)
      ..cubicTo(w * 0.28, -h * 0.04, w * 0.72, -h * 0.04, w, h * 0.14);
    canvas.drawPath(trussArch1, trussPaint);

    final trussArch2 = Path()
      ..moveTo(0, h * 0.28)
      ..cubicTo(w * 0.28, h * 0.10, w * 0.72, h * 0.10, w, h * 0.28);
    canvas.drawPath(trussArch2, trussPaint);

    // 4. Siluet Dedaunan Emerald & Sage di Bagian Tepi (Minimalist Edge Framing)
    _drawFoliageSilhouettes(canvas, size);

    // 5. Partikel Cahaya & Butiran Embun Berpendar Halus (Enchanted Light Motes)
    final pTime = particleAnimation.value;
    for (final mote in _motes) {
      final dyOffset = ((mote.y - pTime * 0.12 * mote.speed) % 1.0) * h;
      final dxOffset = mote.x * w + math.sin((pTime + mote.x) * math.pi * 2) * 6.0;
      final alphaPulse = (mote.baseAlpha * (0.7 + 0.3 * math.sin((pTime + mote.y) * math.pi * 4)))
          .clamp(0.0, 1.0);

      final motePaint = Paint()
        ..color = AppColors.dewMint.withValues(alpha: alphaPulse)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dxOffset, dyOffset), mote.radius, motePaint);

      // Halo pendaran lembut
      final haloPaint = Paint()
        ..color = Colors.white.withValues(alpha: alphaPulse * 0.45)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dxOffset, dyOffset), mote.radius * 2.2, haloPaint);
    }
  }

  /// Menggambar siluet dedaunan botani yang membingkai sudut layar secara elegan
  void _drawFoliageSilhouettes(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final leafFillEmerald = Paint()
      ..color = AppColors.emeraldLeaf.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    final leafFillSage = Paint()
      ..color = AppColors.freshSage.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final stemPaint = Paint()
      ..color = AppColors.freshSage.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Helper daun tunggal organik
    void drawLeaf(Offset origin, double angle, double length, double width, Paint paint) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.rotate(angle);
      final p = Path()
        ..moveTo(0, 0)
        ..cubicTo(-width * 0.48, length * 0.35, -width * 0.50, length * 0.75, 0, length)
        ..cubicTo(width * 0.50, length * 0.75, width * 0.48, length * 0.35, 0, 0)
        ..close();
      canvas.drawPath(p, paint);
      canvas.restore();
    }

    // A. Sudut Kanan Atas: Ranting merambat halus menjuntai ke bawah
    final stemTR = Path()
      ..moveTo(w, -5)
      ..cubicTo(w - 25, h * 0.05, w - 45, h * 0.12, w - 20, h * 0.22);
    canvas.drawPath(stemTR, stemPaint);

    drawLeaf(Offset(w - 12, h * 0.03), 0.7, 32.0, 16.0, leafFillEmerald);
    drawLeaf(Offset(w - 32, h * 0.07), -0.6, 28.0, 14.0, leafFillSage);
    drawLeaf(Offset(w - 22, h * 0.12), 1.0, 26.0, 13.0, leafFillEmerald);
    drawLeaf(Offset(w - 40, h * 0.16), -0.8, 24.0, 12.0, leafFillSage);
    drawLeaf(Offset(w - 20, h * 0.22), 0.4, 20.0, 10.0, leafFillEmerald);

    // B. Sudut Kiri Atas: Ranting merambat kecil
    final stemTL = Path()
      ..moveTo(-5, h * 0.04)
      ..cubicTo(w * 0.06, h * 0.07, w * 0.10, h * 0.14, w * 0.04, h * 0.20);
    canvas.drawPath(stemTL, stemPaint);

    drawLeaf(Offset(w * 0.02, h * 0.05), -0.6, 26.0, 13.0, leafFillEmerald);
    drawLeaf(Offset(w * 0.07, h * 0.09), 0.8, 24.0, 12.0, leafFillSage);
    drawLeaf(Offset(w * 0.04, h * 0.15), -0.5, 20.0, 10.0, leafFillEmerald);

    // C. Sudut Kiri Bawah: Siluet pakis & dedaunan botani bawah
    final stemBL = Path()
      ..moveTo(-10, h + 5)
      ..cubicTo(w * 0.10, h * 0.90, w * 0.18, h * 0.88, w * 0.28, h * 0.91);
    canvas.drawPath(stemBL, stemPaint);

    drawLeaf(Offset(w * 0.04, h * 0.91), -1.5, 42.0, 20.0, leafFillEmerald);
    drawLeaf(Offset(w * 0.12, h * 0.87), -1.1, 36.0, 18.0, leafFillSage);
    drawLeaf(Offset(w * 0.20, h * 0.86), -0.8, 30.0, 15.0, leafFillEmerald);
    drawLeaf(Offset(w * 0.28, h * 0.90), -0.5, 24.0, 12.0, leafFillSage);

    // D. Sudut Kanan Bawah: Siluet dedaunan menjuntai
    final stemBR = Path()
      ..moveTo(w + 10, h * 0.86)
      ..cubicTo(w * 0.86, h * 0.89, w * 0.78, h * 0.94, w * 0.70, h + 5);
    canvas.drawPath(stemBR, stemPaint);

    drawLeaf(Offset(w * 0.92, h * 0.87), 1.8, 38.0, 18.0, leafFillEmerald);
    drawLeaf(Offset(w * 0.84, h * 0.90), 1.3, 32.0, 16.0, leafFillSage);
    drawLeaf(Offset(w * 0.74, h * 0.94), 0.9, 26.0, 13.0, leafFillEmerald);
  }

  @override
  bool shouldRepaint(covariant EnchantedGlasshouseBackgroundPainter oldDelegate) =>
      true;
}

class _MoteData {
  const _MoteData(this.x, this.y, this.radius, this.baseAlpha, this.speed);
  final double x;
  final double y;
  final double radius;
  final double baseAlpha;
  final double speed;
}

/// Layar pembuka (Splash Screen) utama Wall o' Pay bertema **Enchanted Glasshouse**.
///
/// Komposisi:
/// - Bagian Tengah: Combination Logo (rumah kaca + tunas) & teks "Wall o' Pay" (Outfit SemiBold).
/// - Bagian Bawah: Tagline "Grow Your Financial Habits." (DM Sans Regular) & indikator loading minimalis.
/// - Background: Moss Shadow / Glasshouse Green dengan siluet dedaunan tepi, sinar matahari lembut, dan partikel pendaran kaca.
class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    this.onFinish,
    this.minDuration = const Duration(milliseconds: 1150),
  });

  /// Callback yang dipanggil setelah animasi intro selesai dan aplikasi siap.
  final VoidCallback? onFinish;

  /// Durasi tampilan minimal sebelum callback [onFinish] dipanggil.
  final Duration minDuration;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _ambientController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _loadingFade;

  bool _finishDispatched = false;

  @override
  void initState() {
    super.initState();

    final isTestEnvironment =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');

    _introController = AnimationController(
      vsync: this,
      duration: isTestEnvironment ? Duration.zero : widget.minDuration,
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _logoFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.12, 0.65, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.12, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.35, 0.78, curve: Curves.easeOut),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.35, 0.78, curve: Curves.easeOutCubic),
      ),
    );

    _taglineFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.55, 0.95, curve: Curves.easeOut),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.55, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    _loadingFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
    );

    _introController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerFinish();
      }
    });

    if (isTestEnvironment) {
      _introController.value = 1.0;
      _ambientController.value = 0.5;
      _triggerFinish();
    } else {
      _introController.forward();
      _ambientController.repeat(reverse: true);
    }
  }

  void _triggerFinish() {
    if (_finishDispatched || !mounted) return;
    _finishDispatched = true;
    widget.onFinish?.call();
  }

  @override
  void dispose() {
    _introController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mossShadow,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Lapisan Latar Belakang Enchanted Glasshouse
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: EnchantedGlasshouseBackgroundPainter(
                  sunbeamAnimation: _ambientController,
                  particleAnimation: _ambientController,
                ),
              ),
            ),
          ),

          // 2. Konten Tengah & Bawah
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 4),

                // --- BAGIAN TENGAH: Logo Utama & Nama Aplikasi ---
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: const GlasshouseCombinationLogo(
                      size: 136,
                      showGlow: true,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                FadeTransition(
                  opacity: _titleFade,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: Text(
                      "Wall o' Pay",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w600, // Outfit SemiBold
                        letterSpacing: -0.4,
                        color: AppColors.softIvory,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 5),

                // --- BAGIAN BAWAH: Tagline & Indikator Loading Minimalis ---
                FadeTransition(
                  opacity: _taglineFade,
                  child: SlideTransition(
                    position: _taglineSlide,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.tr('Grow Your Financial Habits.'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w400, // DM Sans Regular
                            letterSpacing: 0.25,
                            color: AppColors.freshSage,
                          ),
                        ),
                        const SizedBox(height: 18),
                        FadeTransition(
                          opacity: _loadingFade,
                          child: const _MinimalLoadingIndicator(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 38),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Indikator loading minimalis berpendar halus bertema Glasshouse Dew Mint.
class _MinimalLoadingIndicator extends StatefulWidget {
  const _MinimalLoadingIndicator();

  @override
  State<_MinimalLoadingIndicator> createState() => _MinimalLoadingIndicatorState();
}

class _MinimalLoadingIndicatorState extends State<_MinimalLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    if (!isTest) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.value = 0.5;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final glowProgress = _pulseController.value;
        return Container(
          width: 48,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.borderOutline.withValues(alpha: 0.40),
            borderRadius: BorderRadius.circular(2),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 20 + 24 * glowProgress,
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.emeraldLeaf.withValues(alpha: 0.60),
                  AppColors.dewMint.withValues(alpha: 0.90),
                  AppColors.emeraldLeaf.withValues(alpha: 0.60),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dewMint.withValues(alpha: 0.35 * glowProgress),
                  blurRadius: 6,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

