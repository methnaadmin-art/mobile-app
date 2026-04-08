import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/controllers/signup_data.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/core/widgets/signup_mockup_shell.dart';

class MaritalStatusScreen extends GetView<SignupController> {
  const MaritalStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller.syncStep(AppRoutes.signupMaritalStatus);

    return Obx(() {
      final isFemale =
          controller.selectedGender.value.toLowerCase() == 'female';
      final maleOrder = const [
        'Never Married',
        'Married',
        'Divorced',
        'Widowed',
      ];
      final femaleOrder = const ['Never Married', 'Divorced', 'Widowed'];
      final source = SignupData.maritalStatuses.toSet();
      final statuses = (isFemale ? femaleOrder : maleOrder)
          .where(source.contains)
          .toList(growable: false);

      if (isFemale && controller.selectedMaritalStatus.value == 'Married') {
        controller.selectedMaritalStatus.value = '';
      }

      return SignupMockScaffold(
        progress: controller.progressPercent,
        onBack: controller.goBack,
        title: 'marital_status'.tr,
        subtitle: 'marital_status_desc'.tr,
        body: SingleChildScrollView(
          child: Column(
            children: statuses.map((status) {
              final selected = controller.selectedMaritalStatus.value == status;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: status == statuses.last ? 0 : 12,
                ),
                child: SignupMockCardOption(
                  title: status.tr,
                  description: _descriptionForStatus(status),
                  selected: selected,
                  onTap: () => controller.selectedMaritalStatus.value = status,
                ),
              );
            }).toList(),
          ),
        ),
        footer: SignupMockPrimaryButton(
          label: 'continue'.tr,
          onTap: controller.selectedMaritalStatus.value.isNotEmpty
              ? controller.goToNextStep
              : null,
        ),
      );
    });
  }

  String _descriptionForStatus(String status) {
    switch (status) {
      case 'Never Married':
        return 'marital_never_married_desc'.tr;
      case 'Divorced':
        return 'marital_divorced_desc'.tr;
      case 'Widowed':
        return 'marital_widowed_desc'.tr;
      case 'Married':
        return 'marital_married_desc'.tr;
      default:
        return 'marital_default_desc'.tr;
    }
  }
}
