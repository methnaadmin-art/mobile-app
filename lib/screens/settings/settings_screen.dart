import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';
import 'package:methna_app/screens/settings/third_party_integrations_screen.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSimplePageScaffold(
      title: 'settings'.tr,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          SettingsPromoBanner(
            title: 'upgrade_membership_title'.tr,
            subtitle: 'upgrade_desc'.tr,
            onTap: () => Get.toNamed(AppRoutes.subscription),
          ),
          const SizedBox(height: AppSpacing.md),
          SettingsPlainListCard(
            children: [
              SettingsPlainTile(
                title: 'discovery_preferences'.tr,
                onTap: () => Get.toNamed(AppRoutes.discoveryPreferences),
              ),
              SettingsPlainTile(
                title: 'profile_privacy'.tr,
                onTap: () => Get.toNamed(AppRoutes.profilePrivacy),
              ),
              SettingsPlainTile(
                title: 'notification'.tr,
                onTap: () => Get.toNamed(AppRoutes.notificationSettings),
              ),
              SettingsPlainTile(
                title: 'account_security'.tr,
                onTap: () => Get.toNamed(AppRoutes.accountSecurity),
              ),
              SettingsPlainTile(
                title: 'subscription'.tr,
                onTap: () => Get.toNamed(AppRoutes.subscription),
              ),
              SettingsPlainTile(
                title: 'app_appearance'.tr,
                onTap: () => Get.toNamed(AppRoutes.appAppearance),
              ),
              SettingsPlainTile(
                title: 'integrations'.tr,
                onTap: () => Get.to(() => const ThirdPartyIntegrationsScreen()),
              ),
              SettingsPlainTile(
                title: 'help_support'.tr,
                onTap: () => Get.toNamed(AppRoutes.helpSupport),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SettingsPlainListCard(
            children: [
              SettingsPlainTile(
                title: 'download_my_data'.tr,
                onTap: () => _confirmSimpleAction(
                  context,
                  title: 'download_my_data'.tr,
                  description: 'request_data_confirm_desc'.tr,
                  actionLabel: 'request'.tr,
                  action: controller.requestDataDownload,
                ),
              ),
              SettingsPlainTile(
                title: 'clear_cache'.tr,
                onTap: () => Get.toNamed(AppRoutes.clearCacheInfo),
              ),
              SettingsPlainTile(
                title: 'reset_app_data'.tr,
                destructive: true,
                onTap: () => Get.toNamed(AppRoutes.resetAppDataInfo),
              ),
              SettingsPlainTile(
                title: 'terms_conditions'.tr,
                onTap: () => Get.toNamed(AppRoutes.termsConditions),
              ),
              SettingsPlainTile(
                title: 'privacy_policy'.tr,
                onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
              ),
              SettingsPlainTile(
                title: 'logout'.tr,
                destructive: true,
                onTap: () => _confirmLogout(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    await _confirmSimpleAction(
      context,
      title: 'logout'.tr,
      description: 'logout_confirm'.tr,
      actionLabel: 'logout'.tr,
      action: () async {
        await controller.logout();
        return true;
      },
      isDanger: true,
    );
  }

  Future<void> _confirmSimpleAction(
    BuildContext context, {
    required String title,
    required String description,
    required String actionLabel,
    required Future<bool> Function() action,
    bool isDanger = false,
  }) async {
    await Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () async {
              Get.back();
              await action();
            },
            child: Text(
              actionLabel,
              style: TextStyle(
                color: isDanger ? AppColors.error : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
