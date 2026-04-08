import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/core/widgets/signup_mockup_shell.dart';

class GenderScreen extends GetView<SignupController> {
  const GenderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller.syncStep(AppRoutes.signupGender);

    return Obx(
      () => SignupMockScaffold(
        progress: controller.progressPercent,
        onBack: controller.goBack,
        title: 'select_gender'.tr,
        subtitle:
            'choose_gender_desc'.tr,
        body: Column(
          children: [
            SignupMockWideOption(
              label: 'man'.tr,
              selected: controller.selectedGender.value.toLowerCase() == 'male',
              onTap: () => controller.selectedGender.value = 'male',
            ),
            const SizedBox(height: 12),
            SignupMockWideOption(
              label: 'woman'.tr,
              selected: controller.selectedGender.value.toLowerCase() == 'female',
              onTap: () => controller.selectedGender.value = 'female',
            ),
          ],
        ),
        footer: SignupMockPrimaryButton(
          label: 'continue'.tr,
          onTap: controller.selectedGender.value.isNotEmpty
              ? controller.goToNextStep
              : null,
        ),
      ),
    );
  }
}
