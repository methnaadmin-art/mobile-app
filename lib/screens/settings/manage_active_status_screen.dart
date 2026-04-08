import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class ManageActiveStatusScreen extends GetView<SettingsController> {
  const ManageActiveStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSimplePageScaffold(
      title: 'manage_active_status'.tr,
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
                SettingsPlainSwitchTile(
                  title: 'show_active_status'.tr,
                  subtitle: 'show_active_status_desc'.tr,
                  value: controller.showOnlineStatus.value,
                  onChanged: (value) =>
                      controller.updatePrivacy(showOnline: value),
                ),
                SettingsPlainSwitchTile(
                  title: 'show_recently_active'.tr,
                  subtitle: 'show_recently_active_desc'.tr,
                  value: controller.showLastSeen.value,
                  onChanged: (value) =>
                      controller.updatePrivacy(showLastSeenVal: value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
