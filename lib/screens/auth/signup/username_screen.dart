import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/utils/validators.dart';
import 'package:methna_app/core/widgets/signup_exact_frame.dart';

class UsernameScreen extends GetView<SignupController> {
  const UsernameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller.syncStep(AppRoutes.signupUsername);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ExactSignupScaffold(
      progress: controller.progressPercent,
      onBack: controller.goBack,
      footer: Obx(() {
        controller.usernameInputTick.value;
        final isBusy =
            controller.isNavigatingStep.value || controller.isLoading.value;
        final usernameValidation = Validators.username(
          controller.usernameController.text.trim(),
        );
        final hasValidUsername = usernameValidation == null;
        final canContinue =
            hasValidUsername &&
          !controller.checkingUsername.value &&
          (controller.usernameAvailable.value ||
            controller.usernameCheckFailed.value) &&
            !controller.usernameTaken.value &&
            !isBusy;

        return ExactSignupPrimaryButton(
          label: 'continue'.tr,
          isLoading: isBusy,
          onTap: canContinue ? controller.goToNextStep : null,
        );
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'username_identity'.tr,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: signupText(isDark),
            ),
          ),
          const SizedBox(height: 18),
          ExactSignupTextField(
            controller: controller.usernameController,
            hint: 'nickname'.tr,
            textAlign: TextAlign.center,
            validator: Validators.username,
            suffix: Obx(
              () => _AvailabilityIcon(
                checking: controller.checkingUsername.value,
                available: controller.usernameAvailable.value,
                hasError: controller.usernameError.value.isNotEmpty,
              ),
            ),
          ),
          Obx(
            () => controller.usernameError.value.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      controller.usernameError.value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.error,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityIcon extends StatelessWidget {
  final bool checking;
  final bool available;
  final bool hasError;

  const _AvailabilityIcon({
    required this.checking,
    required this.available,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (available) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: Icon(LucideIcons.badgeCheck, color: AppColors.success, size: 19),
      );
    }

    if (hasError) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: Icon(LucideIcons.alertCircle, color: AppColors.error, size: 19),
      );
    }

    return const SizedBox.shrink();
  }
}
