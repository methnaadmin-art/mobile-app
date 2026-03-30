import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:methna_app/app/controllers/splash_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final SplashController controller;
  late final AnimationController _heartsController;
  late final List<_FloatingHeart> _hearts;

  @override
  void initState() {
    super.initState();
    controller = Get.put(SplashController());
    _heartsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _hearts = List.generate(15, (_) => _FloatingHeart.random());
  }

  @override
  void dispose() {
    _heartsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Stack(
          children: [
            // ── Floating hearts background ──
            AnimatedBuilder(
              animation: _heartsController,
              builder: (context, _) {
                return CustomPaint(
                  size: size,
                  painter: _HeartsPainter(
                    hearts: _hearts,
                    progress: _heartsController.value,
                  ),
                );
              },
            ),

            // ── Main content ──
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 5),

                    // Logo Icon (Asset)
                    Obx(() => AnimatedOpacity(
                          opacity: controller.showLogo.value ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 1000),
                          child: AnimatedScale(
                            scale: controller.showLogo.value ? 1.0 : 0.5,
                            duration: const Duration(milliseconds: 1200),
                            curve: Curves.elasticOut,
                            child: Hero(
                              tag: 'app_logo',
                              child: Image.asset(
                                'assets/images/splash_logo_transparent.png',
                                width: 140,
                                height: 140,
                              ),
                            ),
                          ),
                        )),

                    const SizedBox(height: 12),

                    // App Name (Outfit Font)
                    Obx(() => AnimatedOpacity(
                          opacity: controller.showLogo.value ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 800),
                          child: AnimatedSlide(
                            offset: controller.showLogo.value
                                ? Offset.zero
                                : const Offset(0, 0.2),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutBack,
                            child: Text(
                              AppConstants.appName,
                              style: GoogleFonts.outfit(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        )),

                    const Spacer(flex: 5),

                    // Biometric Auth UI or Modern Loader
                    Obx(() {
                      if (controller.biometricFailed.value) {
                        // Biometric failed - show retry button
                        return Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.fingerprint, size: 32, color: AppColors.error),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'biometric_failed'.tr,
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => controller.retryBiometric(),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: Text('try_again'.tr),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        );
                      } else if (controller.requiresBiometric.value) {
                        // Waiting for biometric
                        return Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.fingerprint, size: 32, color: AppColors.primary),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'authenticate_to_access'.tr,
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        );
                      }
                      // Normal loader
                      return AnimatedOpacity(
                        opacity: controller.animationProgress.value > 0 ? 0.8 : 0.0,
                        duration: const Duration(milliseconds: 600),
                        child: Column(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
                              ),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(AppColors.primary),
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Logo painter: speech-bubble with heart ───────────────────────────
class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 4);
    final radius = size.width * 0.38;

    // White circle background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius, bgPaint);

    // Small tail / pointer at bottom
    final tailPath = Path()
      ..moveTo(center.dx - 8, center.dy + radius - 4)
      ..lineTo(center.dx - 14, center.dy + radius + 14)
      ..lineTo(center.dx + 6, center.dy + radius - 2)
      ..close();
    canvas.drawPath(tailPath, bgPaint);

    // Heart icon inside
    _drawHeart(canvas, Offset(center.dx, center.dy + 2), radius * 0.52,
        AppColors.primary);
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size;
    final h = size;
    final x = center.dx - w / 2;
    final y = center.dy - h / 2;

    path.moveTo(x + w / 2, y + h);
    path.cubicTo(x + w / 2, y + h, x, y + h * 0.65, x, y + h * 0.35);
    path.cubicTo(x, y + h * 0.1, x + w * 0.25, y, x + w / 2, y + h * 0.2);
    path.cubicTo(x + w * 0.75, y, x + w, y + h * 0.1, x + w, y + h * 0.35);
    path.cubicTo(x + w, y + h * 0.65, x + w / 2, y + h, x + w / 2, y + h);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Floating hearts data & painter ───────────────────────────────────
class _FloatingHeart {
  final double x; // 0..1 horizontal position
  final double startY; // 0..1 starting vertical
  final double size; // icon size
  final double speed; // multiplier
  final double opacity;

  _FloatingHeart({
    required this.x,
    required this.startY,
    required this.size,
    required this.speed,
    required this.opacity,
  });

  factory _FloatingHeart.random() {
    final rng = Random();
    return _FloatingHeart(
      x: rng.nextDouble(),
      startY: rng.nextDouble(),
      size: 10 + rng.nextDouble() * 18,
      speed: 0.3 + rng.nextDouble() * 0.7,
      opacity: 0.06 + rng.nextDouble() * 0.14,
    );
  }
}

class _HeartsPainter extends CustomPainter {
  final List<_FloatingHeart> hearts;
  final double progress;

  _HeartsPainter({required this.hearts, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final h in hearts) {
      final y = ((h.startY + progress * h.speed) % 1.2) * size.height;
      final x = h.x * size.width + sin(progress * 2 * pi + h.startY * 6) * 20;
      final paint = Paint()
        ..color = AppColors.primary.withValues(alpha: h.opacity)
        ..style = PaintingStyle.fill;

      _drawSmallHeart(canvas, Offset(x, y), h.size, paint);
    }
  }

  void _drawSmallHeart(Canvas canvas, Offset center, double s, Paint paint) {
    final path = Path();
    final x = center.dx - s / 2;
    final y = center.dy - s / 2;

    path.moveTo(x + s / 2, y + s);
    path.cubicTo(x + s / 2, y + s, x, y + s * 0.65, x, y + s * 0.35);
    path.cubicTo(x, y + s * 0.1, x + s * 0.25, y, x + s / 2, y + s * 0.2);
    path.cubicTo(x + s * 0.75, y, x + s, y + s * 0.1, x + s, y + s * 0.35);
    path.cubicTo(x + s, y + s * 0.65, x + s / 2, y + s, x + s / 2, y + s);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartsPainter old) => old.progress != progress;
}
