import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class ProfilePrivacyScreen extends GetView<SettingsController> {
  const ProfilePrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSimplePageScaffold(
      title: 'profile_privacy'.tr,
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
                SettingsPlainTile(
                  title: 'username'.tr,
                  value: controller.username.isEmpty
                      ? '@methna'
                      : '@${controller.username}',
                  onTap: () => Get.toNamed(AppRoutes.changeUsername),
                ),
                SettingsPlainTile(
                  title: 'share_my_profile'.tr,
                  onTap: () {
                    final username = controller.username;
                    final link = 'https://methna.app/profile/$username';
                    Clipboard.setData(ClipboardData(text: link));
                    Helpers.showSnackbar(message: 'profile_link_copied'.tr);
                  },
                ),
                SettingsPlainTile(
                  title: 'privacy_visibility'.tr,
                  value: _visibilityLabel(controller.visibility.value),
                  onTap: () => Get.toNamed(AppRoutes.visibility),
                ),
                SettingsPlainSwitchTile(
                  title: 'privacy_mode'.tr,
                  value: controller.privacyMode.value,
                  onChanged: (value) =>
                      controller.updatePrivacy(privacyModeVal: value),
                ),
                SettingsPlainTile(
                  title: 'profile_verification'.tr,
                  onTap: () => Get.toNamed(AppRoutes.verificationCenter),
                ),
                SettingsPlainTile(
                  title:
                      '${'blocked_users'.tr} (${controller.blockedUsers.length})',
                  onTap: () => Get.toNamed(AppRoutes.blockedUsers),
                ),
                SettingsPlainTile(
                  title: 'manage_active_status'.tr,
                  onTap: () => Get.toNamed(AppRoutes.manageActiveStatus),
                ),
                SettingsPlainTile(
                  title: 'manage_messages'.tr,
                  onTap: () => Get.toNamed(AppRoutes.manageMessages),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsSectionLabel(text: 'more_controls'.tr),
            SettingsPlainListCard(
              children: [
                SettingsPlainSwitchTile(
                  title: 'show_age'.tr,
                  value: controller.showAge.value,
                  onChanged: (value) =>
                      controller.updatePrivacy(showAgeVal: value),
                ),
                SettingsPlainSwitchTile(
                  title: 'show_distance'.tr,
                  value: controller.showDistance.value,
                  onChanged: (value) =>
                      controller.updatePrivacy(showDist: value),
                ),
                SettingsPlainSwitchTile(
                  title: 'show_online_status'.tr,
                  value: controller.showOnlineStatus.value,
                  onChanged: (value) =>
                      controller.updatePrivacy(showOnline: value),
                ),
                SettingsPlainSwitchTile(
                  title: 'show_last_seen'.tr,
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

  String _visibilityLabel(String value) {
    switch (value) {
      case 'matches':
        return 'only_matches'.tr;
      case 'nobody':
        return 'nobody'.tr;
      default:
        return 'everyone'.tr;
    }
  }
}
