import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class VisibilityScreen extends GetView<SettingsController> {
  const VisibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();
    final isPremium = auth.currentUser.value?.isPremium ?? false;
    final monetization = Get.find<MonetizationService>();

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
            // Discovery visibility section
            SettingsPlainListCard(
              children: [
                SettingsRadioTile(
                  title: 'everyone'.tr,
                  selected: controller.visibility.value == 'everyone',
                  onTap: () => controller.updateVisibility('everyone'),
                ),
                SettingsRadioTile(
                  title: 'only_matches'.tr,
                  subtitle: 'only_matches_desc'.tr,
                  selected: controller.visibility.value == 'matches',
                  onTap: () => controller.updateVisibility('matches'),
                ),
                SettingsRadioTile(
                  title: 'person_i_liked'.tr,
                  subtitle: isPremium
                      ? 'person_i_liked_desc'.tr
                      : 'upgrade_to_unlock'.tr,
                  selected: controller.visibility.value == 'liked_people',
                  onTap: () {
                    if (!isPremium) {
                      Helpers.showSnackbar(
                        message: 'upgrade_to_unlock'.tr,
                        isError: true,
                      );
                      return;
                    }
                    controller.updateVisibility('liked_people');
                  },
                ),
                SettingsRadioTile(
                  title: 'nobody'.tr,
                  subtitle: 'nobody_desc'.tr,
                  selected: controller.visibility.value == 'nobody',
                  onTap: () => controller.updateVisibility('nobody'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Invisible Mode section — separate privacy/incognito mode
            SettingsPlainListCard(
              children: [
                SettingsPlainTile(
                  title: 'invisible_mode'.tr,
                  subtitle: monetization.isInvisible.value
                      ? 'invisible_mode_on_desc'.tr
                      : 'invisible_mode_off_desc'.tr,
                  trailing: Switch(
                    value: monetization.isInvisible.value,
                    activeThumbColor: AppColors.primary,
                    onChanged: (value) async {
                      if (!isPremium) {
                        Helpers.showSnackbar(
                          message: 'upgrade_to_unlock'.tr,
                          isError: true,
                        );
                        return;
                      }
                      await monetization.toggleInvisibleMode(value);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
