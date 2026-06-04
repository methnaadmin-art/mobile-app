import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/constants/app_constants.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';
import 'package:methna_app/screens/settings/static_content_screen.dart'
    as methna_app;

class HelpSupportScreen extends GetView<SettingsController> {
  const HelpSupportScreen({super.key});

  String _rateUsUrl() {
    if (GetPlatform.isIOS || GetPlatform.isMacOS) {
      return AppConstants.iosAppStoreUrl;
    }
    return AppConstants.androidPlayStoreUrl;
  }

  Future<void> _launchExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Helpers.showSnackbar(message: 'could_not_open_link'.tr, isError: true);
    }
  }

  void _openContent(String title, String contentType) {
    Get.to(
      () => methna_app.StaticContentScreen(
        title: title,
        contentType: contentType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monetization = Get.find<MonetizationService>();

    return SettingsSimplePageScaffold(
      title: 'help_support'.tr,
      body: ListView(
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
                title: 'faq'.tr,
                onTap: () => Get.toNamed(AppRoutes.faq),
              ),
              if (monetization.isPremium)
                SettingsPlainTile(
                  title: 'contact_support'.tr,
                  onTap: () => Get.toNamed(AppRoutes.contactSupport),
                ),
              SettingsPlainTile(
                title: 'report_request'.tr,
                onTap: () => Get.toNamed(AppRoutes.reportRequest),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SettingsSectionLabel(text: 'more_help'.tr),
          SettingsPlainListCard(
            children: [
              SettingsPlainTile(
                title: 'terms_conditions'.tr,
                onTap: () => Get.toNamed(AppRoutes.termsConditions),
              ),
              SettingsPlainTile(
                title: 'privacy_policy'.tr,
                onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
              ),
              SettingsPlainTile(
                title: 'community_guidelines'.tr,
                onTap: () => _openContent(
                  'community_guidelines'.tr,
                  'community_guidelines',
                ),
              ),
              SettingsPlainTile(
                title: 'safety_tips'.tr,
                onTap: () => _openContent('safety_tips'.tr, 'safety_tips'),
              ),
              SettingsPlainTile(
                title: 'partner_with_us'.tr,
                onTap: () => _openContent('partner_with_us'.tr, 'partners'),
              ),
              SettingsPlainTile(
                title: 'job_vacancies'.tr,
                onTap: () => _openContent('job_vacancies'.tr, 'jobs'),
              ),
              SettingsPlainTile(
                title: 'accessibility'.tr,
                onTap: () => _openContent('accessibility'.tr, 'accessibility'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SettingsSectionLabel(text: 'extra'.tr),
          SettingsPlainListCard(
            children: [
              SettingsPlainTile(
                title: 'report_request'.tr,
                onTap: () => Get.toNamed(AppRoutes.reportRequest),
              ),
              SettingsPlainTile(
                title: 'about_us'.tr,
                onTap: () => _openContent('about_us'.tr, 'about'),
              ),
              SettingsPlainTile(
                title: 'rate_us'.tr,
                onTap: () => _launchExternal(_rateUsUrl()),
              ),
              SettingsPlainTile(
                title: 'visit_website'.tr,
                onTap: () => _launchExternal(AppConstants.websiteUrl),
              ),
              SettingsPlainTile(
                title: 'follow_social'.tr,
                onTap: () => _launchExternal('https://linktr.ee/methnaapp'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
