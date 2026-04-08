import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class VisibilityScreen extends GetView<SettingsController> {
  const VisibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSimplePageScaffold(
      title: 'privacy_visibility'.tr,
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            SettingsPlainListCard(
              children: [
                SettingsRadioTile(
                  title: 'everyone'.tr,
                  selected: controller.visibility.value == 'everyone',
                  onTap: () => controller.updateVisibility('everyone'),
                ),
                SettingsRadioTile(
                  title: 'only_matches'.tr,
                  selected: controller.visibility.value == 'matches',
                  onTap: () => controller.updateVisibility('matches'),
                ),
                SettingsRadioTile(
                  title: 'nobody'.tr,
                  selected: controller.visibility.value == 'nobody',
                  onTap: () => controller.updateVisibility('nobody'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
