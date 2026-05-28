import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/splash_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/constants/app_constants.dart';
import 'package:methna_app/core/utils/google_fonts_stub.dart';

/// App splash screen.
///
/// Visuals:
/// - Solid brand-purple background that matches the native (Android 12+ /
///   pre-12 / iOS) splash so there is no color flash on cold start.
/// - Brand logo centered.
/// - Progress indicator pinned to the bottom.
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
    final logoSize =
        (mediaQuery.size.width * 0.42).clamp(140.0, 220.0).toDouble();
    final bottomInset = mediaQuery.padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.primary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SizedBox.expand(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Centered logo
              Center(
                child: Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    AppConstants.appLogoAsset,
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Bottom progress indicator (or biometric retry CTA)
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomInset > 0 ? bottomInset + 32 : 56,
                child: Center(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashSpinner extends StatelessWidget {
  const _SplashSpinner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        color: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.22),
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
        color: Colors.white.withValues(alpha: 0.16),
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
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
