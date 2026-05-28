import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/locale_controller.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/widgets/custom_button.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class AppAppearanceScreen extends GetView<SettingsController> {
  const AppAppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeCtrl = Get.find<LocaleController>();

    return SettingsSimplePageScaffold(
      title: 'app_appearance'.tr,
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
                  title: 'theme'.tr,
                  value: _themeLabel(controller.themeMode.value),
                  onTap: () => _showThemeSheet(context),
                ),
                SettingsPlainTile(
                  title: 'app_language'.tr,
                  value: localeCtrl.isArabic
                      ? 'language_arabic'.tr
                      : 'language_english'.tr,
                  onTap: () => Get.toNamed(AppRoutes.appLanguage),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _themeLabel(String value) {
    switch (value) {
      case 'light':
        return 'light'.tr;
      case 'dark':
        return 'dark'.tr;
      default:
        return 'light'.tr;
    }
  }

  Future<void> _showThemeSheet(BuildContext context) async {
    final pendingSelection = controller.themeMode.value.obs;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.xl),
            ),
          ),
          child: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.handleDark
                        : AppColors.handleLight,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'choose_theme'.tr,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SettingsPlainListCard(
                  children: [
                    SettingsRadioTile(
                      title: 'light'.tr,
                      selected: pendingSelection.value == 'light',
                      onTap: () => pendingSelection.value = 'light',
                    ),
                    SettingsRadioTile(
                      title: 'dark'.tr,
                      selected: pendingSelection.value == 'dark',
                      onTap: () => pendingSelection.value = 'dark',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'cancel'.tr,
                        variant: CustomButtonVariant.secondary,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: CustomButton(
                        text: 'ok'.tr,
                        onPressed: () {
                          controller.changeTheme(pendingSelection.value);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
