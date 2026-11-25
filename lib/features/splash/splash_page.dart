/// Layar pembuka (Splash Screen) bertema Enchanted Glasshouse untuk Wall o' Pay.
/// Menampilkan perpaduan arsitektur rumah kaca modern, elemen kaca transparan,
/// dedaunan botani emerald/sage, serta tunas bertumbuh di dalam lengkungan kaca.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    final imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        semanticLabel: "Wall o' Pay",
      ),
    );

    if (!showGlow) return imageWidget;

    return SizedBox(
      width: size * 1.25,
      height: size * 1.25,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient Halo Glow bernuansa Vice City sunset magenta & neon cyan
          Container(
            width: size * 1.15,
            height: size * 1.15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.sunsetMagenta.withValues(alpha: 0.35),
                  AppColors.neonCyan.withValues(alpha: 0.18),
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

    // 1. Kanvas Latar Belakang Gradasi Deep Navy & Midnight Navy
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.2, -0.6),
        radius: 1.35,
        colors: [
          const Color(0xFF162354),
          const Color(0xFF0F183C),
          AppColors.midnightNavy,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. Efek Cahaya Sunset Menembus Cakrawala (Soft Sunset Sunbeams)
    final sunProgress = sunbeamAnimation.value;
    final sunAlpha = 0.05 + 0.04 * math.sin(sunProgress * math.pi * 2);
    final beamOffset = math.sin(sunProgress * math.pi * 2) * 14.0;

    void drawSunbeam(double startX, double beamWidth, double angle) {
      final beamPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.sunsetOrange.withValues(alpha: sunAlpha * 1.5),
            AppColors.sunsetMagenta.withValues(alpha: sunAlpha * 0.9),
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

    // 3. Lengkungan Cahaya Neon Sunset (Retro Horizon Arc Waves)
    final arcPaintCyan = Paint()
      ..color = AppColors.neonCyan.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final arcArch1 = Path()
      ..moveTo(0, h * 0.18)
      ..cubicTo(w * 0.30, h * 0.06, w * 0.70, h * 0.06, w, h * 0.18);
    canvas.drawPath(arcArch1, arcPaintCyan);

    final arcPaintMagenta = Paint()
      ..color = AppColors.sunsetMagenta.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final arcArch2 = Path()
      ..moveTo(0, h * 0.32)
      ..cubicTo(w * 0.30, h * 0.20, w * 0.70, h * 0.20, w, h * 0.32);
    canvas.drawPath(arcArch2, arcPaintMagenta);

    // 4. Siluet Pesisir Tropis Halus di Sudut Layar (Vice City Palms Silhouette)
    _drawTropicalSilhouettes(canvas, size);

    // 5. Partikel Cahaya Starlight & Sunset Dust Berpendar Halus
    final pTime = particleAnimation.value;
    for (int i = 0; i < _motes.length; i++) {
      final mote = _motes[i];
      final dyOffset = ((mote.y - pTime * 0.12 * mote.speed) % 1.0) * h;
      final dxOffset =
          mote.x * w + math.sin((pTime + mote.x) * math.pi * 2) * 6.0;
      final alphaPulse =
          (mote.baseAlpha *
                  (0.7 + 0.3 * math.sin((pTime + mote.y) * math.pi * 4)))
              .clamp(0.0, 1.0);

      final moteColor = (i % 3 == 0)
          ? AppColors.sunsetMagenta
          : (i % 3 == 1)
          ? AppColors.goldenYellow
          : AppColors.neonCyan;

      final motePaint = Paint()
        ..color = moteColor.withValues(alpha: alphaPulse * 0.75)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dxOffset, dyOffset), mote.radius, motePaint);

      // Halo pendaran lembut
      final haloPaint = Paint()
        ..color = Colors.white.withValues(alpha: alphaPulse * 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(dxOffset, dyOffset),
        mote.radius * 2.2,
        haloPaint,
      );
    }
  }

  /// Menggambar siluet palem pesisir tropis bernuansa Vice City Sunset gelap
  void _drawTropicalSilhouettes(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final palmPaint = Paint()
      ..color = const Color(0xFF04081E).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final trunkPaint = Paint()
      ..color = const Color(0xFF04081E).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    // Helper daun palem tunggal
    void drawFrond(Offset origin, double angle, double length, double width) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.rotate(angle);
      final p = Path()
        ..moveTo(0, 0)
        ..cubicTo(
          -width * 0.45,
          length * 0.35,
          -width * 0.45,
          length * 0.75,
          0,
          length,
        )
        ..cubicTo(
          width * 0.45,
          length * 0.75,
          width * 0.45,
          length * 0.35,
          0,
          0,
        )
        ..close();
      canvas.drawPath(p, palmPaint);
      canvas.restore();
    }

    // A. Sudut Kanan Atas: Siluet palem pesisir halus
    canvas.drawLine(Offset(w + 10, -5), Offset(w - 28, h * 0.12), trunkPaint);
    drawFrond(Offset(w - 28, h * 0.12), 0.6, 36.0, 14.0);
    drawFrond(Offset(w - 28, h * 0.12), 1.1, 32.0, 13.0);
    drawFrond(Offset(w - 28, h * 0.12), -0.4, 30.0, 12.0);
    drawFrond(Offset(w - 28, h * 0.12), 1.6, 28.0, 11.0);

    // B. Sudut Kiri Bawah: Siluet palem pesisir kecil
    canvas.drawLine(Offset(-8, h + 8), Offset(w * 0.10, h * 0.88), trunkPaint);
    drawFrond(Offset(w * 0.10, h * 0.88), -0.7, 34.0, 14.0);
    drawFrond(Offset(w * 0.10, h * 0.88), -1.2, 30.0, 12.0);
    drawFrond(Offset(w * 0.10, h * 0.88), 0.3, 28.0, 11.0);
  }

  @override
  bool shouldRepaint(
    covariant EnchantedGlasshouseBackgroundPainter oldDelegate,
  ) => true;
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

    final isTestEnvironment = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('Test');

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

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.16), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(0.35, 0.78, curve: Curves.easeOutCubic),
          ),
        );

    _taglineFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.55, 0.95, curve: Curves.easeOut),
    );

    _taglineSlide =
        Tween<Offset>(begin: const Offset(0, 0.16), end: Offset.zero).animate(
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ambientController.stop();
      _ambientController.value = 0.5;
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.midnightNavy,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.midnightNavy,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Lapisan Latar Belakang Vice City Sunset
            Positioned.fill(
              child: ExcludeSemantics(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: EnchantedGlasshouseBackgroundPainter(
                      sunbeamAnimation: _ambientController,
                      particleAnimation: _ambientController,
                    ),
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
                      child: Image.asset(
                        'assets/new_asset/custom_text/logo_wordmark_glossy_neon.png',
                        height: 48,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        semanticLabel: "Wall o' Pay",
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
                              color: AppColors.mutedBlueGray,
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
      ),
    );
  }
}

/// Indikator loading minimalis berpendar halus bertema Glasshouse Dew Mint.
class _MinimalLoadingIndicator extends StatefulWidget {
  const _MinimalLoadingIndicator();

  @override
  State<_MinimalLoadingIndicator> createState() =>
      _MinimalLoadingIndicatorState();
}

class _MinimalLoadingIndicatorState extends State<_MinimalLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulseController.stop();
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
                  AppColors.sunsetMagenta.withValues(alpha: 0.70),
                  AppColors.goldenYellow.withValues(alpha: 0.95),
                  AppColors.neonCyan.withValues(alpha: 0.70),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.sunsetMagenta.withValues(
                    alpha: 0.35 * glowProgress,
                  ),
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
