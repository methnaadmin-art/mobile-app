import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/reset_password_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/widgets/auth_flow.dart';
import 'package:methna_app/core/widgets/custom_text_field.dart';

class ResetPasswordScreen extends GetView<ResetPasswordController> {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      compact: true,
      child: Column(
        children: [
          AuthHeader(onBack: Get.back),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    const _PasswordHero(),
                    const SizedBox(height: AppSpacing.xl),
                    AuthTitleBlock(
                      title: 'create_new_password'.tr,
                      subtitle: 'create_password_body'.tr,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AuthSurfacePanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Obx(
                            () => CustomTextField(
                              controller: controller.newPasswordController,
                              label: 'new_password'.tr,
                              hint: 'new_password'.tr,
                              prefixIcon: LucideIcons.lock,
                              obscureText: controller.obscureNew.value,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'please_enter_password'.tr;
                                }
                                if (v.length < 8) {
                                  return 'password_min_length'.tr;
                                }
                                return null;
                              },
                              suffix: IconButton(
                                onPressed: controller.toggleNewVisibility,
                                icon: Icon(
                                  controller.obscureNew.value
                                      ? LucideIcons.eyeOff
                                      : LucideIcons.eye,
                                  size: 18,
                                  color: AppColors.textHintLight,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Obx(
                            () => CustomTextField(
                              controller: controller.confirmPasswordController,
                              label: 'confirm_new_password'.tr,
                              hint: 'confirm_new_password'.tr,
                              prefixIcon: LucideIcons.shieldCheck,
                              obscureText: controller.obscureConfirm.value,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'confirm_password_required'.tr;
                                }
                                if (v !=
                                    controller.newPasswordController.text) {
                                  return 'passwords_no_match'.tr;
                                }
                                return null;
                              },
                              textInputAction: TextInputAction.done,
                              suffix: IconButton(
                                onPressed: controller.toggleConfirmVisibility,
                                icon: Icon(
                                  controller.obscureConfirm.value
                                      ? LucideIcons.eyeOff
                                      : LucideIcons.eye,
                                  size: 18,
                                  color: AppColors.textHintLight,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AuthBottomBar(
            child: Obx(
              () => AuthPrimaryButtonBar(
                label: 'save_new_password'.tr,
                onPressed: controller.isLoading.value
                    ? null
                    : controller.resetPassword,
                isLoading: controller.isLoading.value,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordHero extends StatelessWidget {
  const _PasswordHero();

  @override
  Widget build(BuildContext context) {
    return AuthHeroPanel(
      gradientColors: const [
        AppColors.primaryDark,
        AppColors.primary,
        AppColors.primaryLight,
      ],
      child: Row(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(LucideIcons.lock, color: Colors.white, size: 32),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              'strong_password_hint'.tr,
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white.withValues(alpha: 0.86),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
