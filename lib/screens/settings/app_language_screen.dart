import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/locale_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class AppLanguageScreen extends StatelessWidget {
  const AppLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeCtrl = Get.find<LocaleController>();

    return SettingsSimplePageScaffold(
      title: 'app_language'.tr,
      body: Obx(() {
        final currentLang = localeCtrl.currentLocale.value.languageCode;

        return ListView(
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
                  title: 'language_english'.tr,
                  leading: const _LanguageBadge(label: 'EN'),
                  trailing: currentLang == 'en'
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => localeCtrl.changeLocale('en', 'US'),
                ),
                SettingsPlainTile(
                  title: 'language_arabic'.tr,
                  leading: const _LanguageBadge(label: 'AR'),
                  trailing: currentLang == 'ar'
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => localeCtrl.changeLocale('ar', 'DZ'),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _LanguageBadge extends StatelessWidget {
  final String label;

  const _LanguageBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
