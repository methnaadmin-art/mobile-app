import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/utils/validators.dart';
import 'package:lucide_icons/lucide_icons.dart';

class UsernameScreen extends GetView<SignupController> {
  const UsernameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller.syncStep(AppRoutes.signupUsername);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Scrollable content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Back arrow
                    _BackArrow(isDark: isDark),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'username_identity'.tr,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'username_identity_desc'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryColor,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // ── Nickname input — large centered filled field ──
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              // Static text field — never rebuilt by Obx
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.cardDark
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: TextFormField(
                                  controller: controller.usernameController,
                                  textAlign: TextAlign.center,
                                  validator: Validators.username,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'nickname'.tr,
                                    hintStyle: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                      color: isDark
                                          ? AppColors.textHintDark
                                          : AppColors.textHintLight,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 18),
                                    border: InputBorder.none,
                                    suffixIcon: Obx(() {
                                      if (controller.checkingUsername.value) {
                                        return const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          ),
                                        );
                                      }
                                      if (controller.usernameAvailable.value) {
                                        return const Icon(LucideIcons.checkCircle2,
                                            color: AppColors.emerald);
                                      }
                                      if (controller.usernameError.value.isNotEmpty) {
                                        return const Icon(LucideIcons.alertCircle,
                                            color: AppColors.error);
                                      }
                                      return const SizedBox(width: 0, height: 0);
                                    }),
                                  ),
                                ),
                              ),
                              // Reactive border overlay — only this rebuilds
                              Positioned.fill(
                                child: Obx(() => IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: controller.usernameError.value.isNotEmpty
                                            ? AppColors.error
                                            : (controller.usernameAvailable.value
                                                ? AppColors.emerald
                                                : Colors.transparent),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                )),
                              ),
                            ],
                          ),
                          Obx(() => controller.usernameError.value.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8, left: 16),
                                  child: Text(
                                    controller.usernameError.value,
                                    style: const TextStyle(
                                        color: AppColors.error, fontSize: 13),
                                  ),
                                )
                              : const SizedBox.shrink()),
                        ],
                      ),
                    ),
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
                      onPressed: controller.usernameAvailable.value &&
                              !controller.checkingUsername.value
                          ? () {
                              if (Validators.username(
                                      controller.usernameController.text) ==
                                  null) {
                                controller.goToNextStep();
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
