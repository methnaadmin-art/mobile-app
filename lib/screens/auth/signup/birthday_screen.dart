import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BirthdayScreen extends GetView<SignupController> {
  const BirthdayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller.syncStep(AppRoutes.signupBirthday);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHintLight;

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'birthday_title'.tr,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'birthday_desc'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryColor,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Cake icon ──
                    Center(
                      child: Text(
                        '🎂',
                        style: const TextStyle(fontSize: 64),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── MM  DD  YYYY fields ──
                    Obx(() {
                      final dob = controller.dateOfBirth.value;
                      return GestureDetector(
                        onTap: () => _pickDate(context),
                        child: Row(
                          children: [
                            // MM
                            Expanded(
                              child: _DateBox(
                                label: 'mm'.tr,
                                value: dob?.month.toString().padLeft(2, '0'),
                                isDark: isDark,
                                borderColor: borderColor,
                                hintColor: hintColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // DD
                            Expanded(
                              child: _DateBox(
                                label: 'dd'.tr,
                                value: dob?.day.toString().padLeft(2, '0'),
                                isDark: isDark,
                                borderColor: borderColor,
                                hintColor: hintColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // YYYY
                            Expanded(
                              flex: 2,
                              child: _DateBox(
                                label: 'yyyy'.tr,
                                value: dob?.year.toString(),
                                isDark: isDark,
                                borderColor: borderColor,
                                hintColor: hintColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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
                      onPressed: controller.dateOfBirth.value != null
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

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().subtract(const Duration(days: 365 * 22)),
      firstDate: DateTime(1960),
      lastDate:
          DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (date != null) controller.dateOfBirth.value = date;
  }
}

// ─── Date box widget ──────────────────────────────────────────────────────
class _DateBox extends StatelessWidget {
  final String label;
  final String? value;
  final bool isDark;
  final Color borderColor;
  final Color hintColor;

  const _DateBox({
    required this.label,
    this.value,
    required this.isDark,
    required this.borderColor,
    required this.hintColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: value != null ? AppColors.primary : borderColor,
            width: value != null ? 2 : 1.5,
          ),
        ),
      ),
      child: Center(
        child: Text(
          value ?? label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: value != null ? FontWeight.w600 : FontWeight.w400,
            color: value != null
                ? (isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight)
                : hintColor,
            letterSpacing: value != null ? 0 : 2,
          ),
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
