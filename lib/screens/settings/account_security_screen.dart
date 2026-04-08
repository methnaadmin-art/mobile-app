import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/widgets/app_card.dart';
import 'package:methna_app/core/widgets/custom_button.dart';
import 'package:methna_app/core/widgets/custom_text_field.dart';
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
                  onChanged: (value) {
                    controller.toggleBiometric(value);
                    controller.toggleFaceId(value);
                  },
                ),
                SettingsPlainTile(
                  title: 'change_password'.tr,
                  onTap: () => _showChangePasswordDialog(context),
                ),
                SettingsPlainTile(
                  title: 'deactivate_account'.tr,
                  onTap: () => _showConfirm(
                    context,
                    title: 'deactivate_account'.tr,
                    description: 'deactivate_confirm'.tr,
                    actionLabel: 'deactivate'.tr,
                    action: () async {
                      controller.deactivateAccount();
                      return true;
                    },
                  ),
                ),
                SettingsPlainTile(
                  title: 'delete_account'.tr,
                  destructive: true,
                  onTap: () => _showConfirm(
                    context,
                    title: 'delete_account'.tr,
                    description: 'delete_account_confirm'.tr,
                    actionLabel: 'delete'.tr,
                    isDanger: true,
                    action: () async {
                      controller.deleteAccount();
                      return true;
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

  void _showChangePasswordDialog(BuildContext context) {
    final oldPwCtrl = TextEditingController();
    final newPwCtrl = TextEditingController();
    final confirmPwCtrl = TextEditingController();
    final obscureOld = true.obs;
    final obscureNew = true.obs;
    final obscureConfirm = true.obs;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: AppCard(
          radius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('change_password'.tr, style: Get.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.lg),
              Obx(
                () => CustomTextField(
                  controller: oldPwCtrl,
                  hint: 'current_password'.tr,
                  label: 'current_password'.tr,
                  obscureText: obscureOld.value,
                  prefixIcon: LucideIcons.lock,
                  suffix: IconButton(
                    onPressed: obscureOld.toggle,
                    icon: Icon(
                      obscureOld.value ? LucideIcons.eyeOff : LucideIcons.eye,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Obx(
                () => CustomTextField(
                  controller: newPwCtrl,
                  hint: 'new_password'.tr,
                  label: 'new_password'.tr,
                  obscureText: obscureNew.value,
                  prefixIcon: LucideIcons.key,
                  suffix: IconButton(
                    onPressed: obscureNew.toggle,
                    icon: Icon(
                      obscureNew.value ? LucideIcons.eyeOff : LucideIcons.eye,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Obx(
                () => CustomTextField(
                  controller: confirmPwCtrl,
                  hint: 'confirm_new_password'.tr,
                  label: 'confirm_new_password'.tr,
                  obscureText: obscureConfirm.value,
                  prefixIcon: LucideIcons.key,
                  suffix: IconButton(
                    onPressed: obscureConfirm.toggle,
                    icon: Icon(
                      obscureConfirm.value
                          ? LucideIcons.eyeOff
                          : LucideIcons.eye,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'cancel'.tr,
                        variant: CustomButtonVariant.outline,
                        onPressed: () => Get.back(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: CustomButton(
                        text: 'save'.tr,
                        isLoading: controller.isChangingPassword.value,
                        onPressed: controller.isChangingPassword.value
                            ? null
                            : () async {
                                if (newPwCtrl.text != confirmPwCtrl.text) {
                                  Get.snackbar(
                                    'error'.tr,
                                    'passwords_no_match'.tr,
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                  return;
                                }
                                final success = await controller.changePassword(
                                  oldPwCtrl.text,
                                  newPwCtrl.text,
                                );
                                if (success) {
                                  Get.back();
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showConfirm(
    BuildContext context, {
    required String title,
    required String description,
    required String actionLabel,
    required Future<bool> Function() action,
    bool isDanger = false,
  }) async {
    await Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: AppCard(
          radius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDanger ? LucideIcons.alertTriangle : LucideIcons.shield,
                color: isDanger ? AppColors.error : AppColors.primary,
                size: 30,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: Get.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Get.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'cancel'.tr,
                      variant: CustomButtonVariant.outline,
                      onPressed: () => Get.back(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: CustomButton(
                      text: actionLabel,
                      backgroundColor: isDanger
                          ? AppColors.error
                          : AppColors.primary,
                      gradient: null,
                      onPressed: () async {
                        Get.back();
                        await action();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
