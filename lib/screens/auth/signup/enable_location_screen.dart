import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/data/services/location_service.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EnableLocationScreen extends GetView<SignupController> {
  const EnableLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller.syncStep(AppRoutes.signupLocation);
    final locationService = Get.find<LocationService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.backgroundDark : const Color(0xFFFFF8F0);
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: back arrow + progress ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => controller.goBack(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LucideIcons.chevronLeft,
                        size: 16,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() => ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: controller.progressPercent,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.primary),
                          ),
                        )),
                  ),
                ],
              ),
            ),

            // ── Center content ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Decorative hearts
                    SizedBox(
                      width: 120,
                      height: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: 10,
                            top: 0,
                            child: Icon(LucideIcons.heart,
                                size: 16,
                                color: AppColors.primary
                                    .withValues(alpha: 0.2)),
                          ),
                          Positioned(
                            right: 10,
                            top: 5,
                            child: Icon(LucideIcons.heart,
                                size: 12,
                                color: AppColors.primary
                                    .withValues(alpha: 0.15)),
                          ),
                          Positioned(
                            left: 30,
                            bottom: 0,
                            child: Icon(LucideIcons.heart,
                                size: 10,
                                color: AppColors.primary
                                    .withValues(alpha: 0.2)),
                          ),
                        ],
                      ),
                    ),

                    // Location pin icon in pink circle
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.mapPin,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'enable_location'.tr,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      'location_subtitle'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryColor,
                        height: 1.5,
                      ),
                    ),

                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),

            // ── Bottom: Allow Location button ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Obx(() => SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (controller.isLoading.value ||
                              locationService.isFetching.value)
                          ? null
                          : () async {
                              try {
                                final pos = await locationService
                                    .requestLocationWithFeedback();
                                if (pos != null) {
                                  controller.locationEnabled.value = true;
                                }
                                // Always proceed to complete signup
                                await controller.completeSignup();
                              } catch (e) {
                                debugPrint('[Location] Error: $e');
                                // Still try to complete signup even on error
                                await controller.completeSignup();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: (controller.isLoading.value ||
                              locationService.isFetching.value)
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'enable_location'.tr,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
                    ),
                  )),
            ),

            // ── Skip button (so user is never stuck) ──
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Obx(() => TextButton(
                onPressed: (controller.isLoading.value || locationService.isFetching.value)
                    ? null
                    : () async {
                        controller.locationEnabled.value = false;
                        await controller.completeSignup();
                      },
                child: Text(
                  'skip'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}
