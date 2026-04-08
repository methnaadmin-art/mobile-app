import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/forgot_password_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/utils/validators.dart';
import 'package:methna_app/core/widgets/auth_flow.dart';
import 'package:methna_app/core/widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ForgotPasswordController());

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
                    const _EmailHero(),
                    const SizedBox(height: AppSpacing.xl),
                    AuthTitleBlock(
                      title: 'reset_your_password'.tr,
                      subtitle: 'forgot_email_body'.tr,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AuthSurfacePanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            controller: controller.emailController,
                            label: 'email'.tr,
                            hint: 'email_hint'.tr,
                            prefixIcon: LucideIcons.mail,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            validator: Validators.email,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: 0.14,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.badgeInfo,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'otp_info_message'.tr,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ),
                              ],
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
                label: 'continue_text'.tr,
                onPressed: controller.isLoading.value
                    ? null
                    : controller.sendResetCode,
                isLoading: controller.isLoading.value,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailHero extends StatelessWidget {
  const _EmailHero();

  @override
  Widget build(BuildContext context) {
    return AuthHeroPanel(
      gradientColors: const [AppColors.primary, AppColors.primaryLight],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.mailCheck,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'reset_password'.tr,
            style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'reset_password_hero_desc'.tr,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
        ],
      ),
    );
  }
}
