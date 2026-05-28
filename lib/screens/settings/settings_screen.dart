import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/app/utils/auth_navigation_resolver.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';
import 'package:methna_app/core/widgets/backend_wait_overlay.dart';
import 'package:methna_app/core/widgets/backend_wait_dots.dart';
import 'package:methna_app/core/widgets/custom_button.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/screens/settings/third_party_integrations_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  void _openVerificationEntry() {
    final currentUser = Get.find<AuthService>().currentUser.value;
    final restrictedStatus = resolveRestrictedAccountStatus(currentUser);
    final normalizedStatus =
        (restrictedStatus ?? currentUser?.status ?? 'active')
            .toString()
            .trim()
            .toLowerCase();

    if (normalizedStatus == 'active') {
      Get.toNamed(AppRoutes.verificationCenter);
      return;
    }

    Get.toNamed(AppRoutes.accountStatus, arguments: _accountStatusArgs());
  }

  Map<String, dynamic> _accountStatusArgs() {
    final currentUser = Get.find<AuthService>().currentUser.value;
    final fallbackStatus =
        resolveRestrictedAccountStatus(currentUser) ??
        (currentUser?.status.toLowerCase() ?? 'active');
    final baseArgs =
        buildRestrictedAccountArguments(
          currentUser,
          fallbackStatus: fallbackStatus,
        ) ??
        <String, dynamic>{'status': fallbackStatus};
    return <String, dynamic>{...baseArgs, 'allowBackNavigation': true};
  }

  Future<void> _launchExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    Helpers.showSnackbar(message: 'could_not_open_link'.tr, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final purchasesAvailable =
        Get.find<MonetizationService>().supportsInAppPurchases;

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
          if (purchasesAvailable) ...[
            SettingsPromoBanner(
              title: 'upgrade_membership_title'.tr,
              subtitle: 'upgrade_desc'.tr,
              onTap: () => Get.toNamed(AppRoutes.subscription),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
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
                title: 'account_status'.tr,
                subtitle: 'View verification and restriction status',
                onTap: _openVerificationEntry,
              ),
              SettingsPlainTile(
                title: 'subscription'.tr,
                onTap: () => Get.toNamed(AppRoutes.subscription),
              ),
              if (purchasesAvailable)
                SettingsPlainTile(
                  title: 'shop'.tr,
                  onTap: () => Get.toNamed(AppRoutes.shop),
                ),
              if (purchasesAvailable)
                SettingsPlainTile(
                  title: 'manage_subscription'.tr,
                  onTap: () {
                    Get.find<MonetizationService>()
                        .openManageSubscriptionCenter();
                  },
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
                title: 'clear_cache'.tr,
                onTap: () => Get.toNamed(AppRoutes.clearCacheInfo),
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
                title: 'rate_us'.tr,
                onTap: () => _launchExternal(
                  'https://play.google.com/store/apps/details?id=com.methnapp.app',
                ),
              ),
              SettingsPlainTile(
                title: 'visit_website'.tr,
                onTap: () => _launchExternal('https://methna.com'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Obx(
            () => _LogoutCard(
              isLoggingOut: controller.isLoggingOut.value,
              onTap: () => _confirmLogout(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    await Get.dialog(
      Obx(() {
        final isLoggingOut = controller.isLoggingOut.value;

        return AlertDialog(
          title: Text('logout'.tr),
          content: Text('logout_confirm'.tr),
          actions: [
            TextButton(
              onPressed: isLoggingOut ? null : () => Get.back(),
              child: Text('cancel'.tr),
            ),
            TextButton(
              onPressed: isLoggingOut ? null : controller.logout,
              child: isLoggingOut
                  ? SizedBox(
                      width: 28,
                      child: BackendWaitDots(
                        color: AppColors.error,
                        size: 5,
                        spacing: 3,
                      ),
                    )
                  : Text(
                      'logout'.tr,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.isLoggingOut, required this.onTap});

  final bool isLoggingOut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final detailColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF241B28), Color(0xFF17121C)]
              : const [Color(0xFFF3F6FF), Color(0xFFF0F4FF)],
        ),
        border: Border.all(
          color: isDark ? const Color(0xFF433141) : const Color(0xFFD7E0F2),
        ),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: const Color(0x1C617AA6),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(
                    alpha: isDark ? 0.18 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                ),
                child: const Icon(
                  LucideIcons.logOut,
                  color: AppColors.error,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log out securely',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Your account stays safe on this device and you can sign back in anytime.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: detailColor,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CustomButton(
            text: 'logout'.tr,
            icon: LucideIcons.logOut,
            isLoading: isLoggingOut,
            variant: CustomButtonVariant.destructive,
            onPressed: isLoggingOut ? null : onTap,
          ),
        ],
      ),
    );
  }
}
