import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/controllers/signup_data.dart';
import 'package:lucide_icons/lucide_icons.dart';

class GenderScreen extends GetView<SignupController> {
  const GenderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller.syncStep(AppRoutes.signupGender);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    // Map display labels
    final genderLabels = {'Female': 'woman'.tr, 'Male': 'man'.tr};

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: back arrow + progress ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  _BackArrow(isDark: isDark),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() => _ProgressBar(
                          progress: controller.progressPercent,
                        )),
                  ),
                ],
              ),
            ),

            // ── Content ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'select_gender'.tr,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Pill options ──
                    Obx(() => Column(
                          children: SignupData.genders.map((gender) {
                            final selected =
                                controller.selectedGender.value == gender;
                            final label = genderLabels[gender] ?? gender;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: GestureDetector(
                                onTap: () =>
                                    controller.selectedGender.value = gender,
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 250),
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 18),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.cardDark
                                            : Colors.white),
                                    borderRadius:
                                        BorderRadius.circular(28),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.primary
                                          : borderColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? Colors.white
                                              : (isDark
                                                  ? AppColors
                                                      .textPrimaryDark
                                                  : AppColors
                                                      .textPrimaryLight),
                                        ),
                                      ),
                                      if (selected) ...[
                                        const SizedBox(width: 8),
                                        const Icon(
                                          LucideIcons.check,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        )),

                    const Spacer(),
                  ],
                ),
              ),
            ),

            // ── Bottom: Continue button ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Obx(() => SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          controller.selectedGender.value.isNotEmpty
                              ? controller.goToNextStep
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.4),
                        disabledForegroundColor: Colors.white70,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'continue_text'.tr,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
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

// ─── Progress bar ─────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final double progress;
  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 6,
        backgroundColor: Colors.grey.shade200,
        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
      ),
    );
  }
}

// ─── Reusable back arrow ──────────────────────────────────────────────────
class _BackArrow extends StatelessWidget {
  final bool isDark;
  const _BackArrow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.find<SignupController>().goBack(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          LucideIcons.chevronLeft,
          size: 16,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}
