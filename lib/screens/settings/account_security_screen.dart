import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class AccountSecurityScreen extends GetView<SettingsController> {
  const AccountSecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSimplePageScaffold(
      title: 'account_security'.tr,
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
                  title: 'Security status',
                  subtitle: controller.isUpdatingBiometric.value
                      ? 'Updating security preference...'
                      : controller.biometricId.value
                          ? 'Biometric lock is active on this device.'
                          : 'biometric_lock_desc'.tr,
                  trailing: controller.isUpdatingBiometric.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsPlainListCard(
              children: [
                SettingsPlainSwitchTile(
                  title: 'remember_me'.tr,
                  value: controller.rememberMe.value,
                  onChanged: controller.toggleRememberMe,
                ),
                SettingsPlainSwitchTile(
                  title: 'biometric_lock'.tr,
                  subtitle: 'biometric_lock_desc'.tr,
                  value:
                      controller.biometricId.value || controller.faceId.value,
                  onChanged: controller.isUpdatingBiometric.value
                      ? null
                      : (value) {
                          controller.toggleBiometric(value);
                        },
                ),
                SettingsPlainTile(
                  title: 'change_password'.tr,
                  subtitle:
                      'Use your current password and create a stronger one.',
                  onTap: () => Get.toNamed(AppRoutes.changePassword),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsPlainListCard(
              children: [
                SettingsPlainTile(
                  title: 'deactivate_account'.tr,
                  subtitle: 'deactivate_account_desc'.tr,
                  onTap: () => Get.toNamed(AppRoutes.deactivateAccount),
                ),
                SettingsPlainTile(
                  title: 'delete_account'.tr,
                  subtitle: 'delete_account_desc'.tr,
                  destructive: true,
                  leading: const Icon(
                    LucideIcons.alertTriangle,
                    size: 18,
                    color: AppColors.error,
                  ),
                  onTap: () => Get.toNamed(AppRoutes.deleteAccount),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
