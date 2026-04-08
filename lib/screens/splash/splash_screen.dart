import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/splash_controller.dart';
import 'package:methna_app/core/constants/app_constants.dart';
import 'package:methna_app/core/utils/google_fonts_stub.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final SplashController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<SplashController>()
        ? Get.find<SplashController>()
        : Get.put(SplashController());
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final logoSize = (mediaQuery.size.width * 0.42)
        .clamp(140.0, 210.0)
        .toDouble();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF8F18FF),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFA020F9), Color(0xFF7D18FF)],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(child: _SplashBackdrop()),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const Spacer(flex: 4),
                      Expanded(
                        flex: 7,
                        child: Center(
                          child: Obx(
                            () => AnimatedOpacity(
                              duration: const Duration(milliseconds: 320),
                              opacity: controller.showLogo.value ? 1 : 0,
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 460),
                                curve: Curves.easeOutBack,
                                scale: controller.showLogo.value ? 1 : 0.92,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Hero(
                                      tag: 'app_logo',
                                      child: Image.asset(
                                        AppConstants.appLogoAsset,
                                        width: logoSize,
                                        height: logoSize,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      AppConstants.appName,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 34,
                                        fontWeight: FontWeight.w700,
                                        height: 1,
                                        letterSpacing: -0.7,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: mediaQuery.padding.bottom > 0 ? 20 : 38,
                        ),
                        child: Obx(() {
                          if (controller.biometricFailed.value) {
                            return _SplashActionButton(
                              label: 'try_again'.tr,
                              onTap: controller.retryBiometric,
                            );
                          }

                          if (controller.requiresBiometric.value) {
                            return _SplashStatusLabel(
                              label: 'authenticate_to_continue'.tr,
                            );
                          }

                          return const _SplashSpinner();
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashBackdrop extends StatefulWidget {
  const _SplashBackdrop();

  @override
  State<_SplashBackdrop> createState() => _SplashBackdropState();
}

class _SplashBackdropState extends State<_SplashBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartsController;

  static const List<_FallingHeartSpec> _hearts = [
    _FallingHeartSpec(
      xFactor: 0.06,
      size: 10,
      opacity: 0.17,
      speed: 1.18,
      phase: 0.03,
      drift: 10,
    ),
    _FallingHeartSpec(
      xFactor: 0.18,
      size: 14,
      opacity: 0.14,
      speed: 0.96,
      phase: 0.27,
      drift: 14,
    ),
    _FallingHeartSpec(
      xFactor: 0.31,
      size: 9,
      opacity: 0.2,
      speed: 1.22,
      phase: 0.52,
      drift: 8,
    ),
    _FallingHeartSpec(
      xFactor: 0.42,
      size: 12,
      opacity: 0.15,
      speed: 1.08,
      phase: 0.73,
      drift: 12,
    ),
    _FallingHeartSpec(
      xFactor: 0.55,
      size: 18,
      opacity: 0.12,
      speed: 0.92,
      phase: 0.16,
      drift: 16,
    ),
    _FallingHeartSpec(
      xFactor: 0.68,
      size: 11,
      opacity: 0.18,
      speed: 1.28,
      phase: 0.39,
      drift: 10,
    ),
    _FallingHeartSpec(
      xFactor: 0.79,
      size: 15,
      opacity: 0.14,
      speed: 0.98,
      phase: 0.61,
      drift: 13,
    ),
    _FallingHeartSpec(
      xFactor: 0.9,
      size: 9,
      opacity: 0.2,
      speed: 1.2,
      phase: 0.84,
      drift: 9,
    ),
    _FallingHeartSpec(
      xFactor: 0.11,
      size: 16,
      opacity: 0.12,
      speed: 0.88,
      phase: 0.48,
      drift: 18,
    ),
    _FallingHeartSpec(
      xFactor: 0.24,
      size: 10,
      opacity: 0.17,
      speed: 1.14,
      phase: 0.67,
      drift: 9,
    ),
    _FallingHeartSpec(
      xFactor: 0.36,
      size: 13,
      opacity: 0.15,
      speed: 1.02,
      phase: 0.9,
      drift: 11,
    ),
    _FallingHeartSpec(
      xFactor: 0.5,
      size: 8,
      opacity: 0.22,
      speed: 1.3,
      phase: 0.11,
      drift: 7,
    ),
    _FallingHeartSpec(
      xFactor: 0.63,
      size: 12,
      opacity: 0.16,
      speed: 1.04,
      phase: 0.34,
      drift: 13,
    ),
    _FallingHeartSpec(
      xFactor: 0.74,
      size: 17,
      opacity: 0.12,
      speed: 0.9,
      phase: 0.57,
      drift: 17,
    ),
    _FallingHeartSpec(
      xFactor: 0.86,
      size: 10,
      opacity: 0.18,
      speed: 1.24,
      phase: 0.79,
      drift: 8,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _heartsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _heartsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _heartsController,
            builder: (context, _) {
              return Stack(
                children: [
                  for (final heart in _hearts)
                    _AnimatedHeart(
                      spec: heart,
                      progress: _heartsController.value,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _AnimatedHeart extends StatelessWidget {
  const _AnimatedHeart({
    required this.spec,
    required this.progress,
    required this.width,
    required this.height,
  });

  final _FallingHeartSpec spec;
  final double progress;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final travel = (progress * spec.speed + spec.phase) % 1.0;
    final wave = math.sin((travel * math.pi * 2) + (spec.phase * math.pi * 2));
    final top = -48 + ((height + 96) * travel);
    final left = ((width * spec.xFactor) + (wave * spec.drift))
        .clamp(-24.0, width - spec.size + 24.0)
        .toDouble();

    return Positioned(
      top: top,
      left: left,
      child: Transform.rotate(
        angle: wave * 0.16,
        child: Icon(
          Icons.favorite_rounded,
          size: spec.size,
          color: Colors.white.withValues(alpha: spec.opacity),
        ),
      ),
    );
  }
}

class _FallingHeartSpec {
  const _FallingHeartSpec({
    required this.xFactor,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.phase,
    required this.drift,
  });

  final double xFactor;
  final double size;
  final double opacity;
  final double speed;
  final double phase;
  final double drift;
}

class _SplashSpinner extends StatelessWidget {
  const _SplashSpinner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: CircularProgressIndicator(
        strokeWidth: 4,
        color: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.18),
        strokeCap: StrokeCap.round,
      ),
    );
  }
}

class _SplashStatusLabel extends StatelessWidget {
  final String label;

  const _SplashStatusLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SplashActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SplashActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF8D19FF),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
