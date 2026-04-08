import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:methna_app/app/data/services/storage_service.dart';
import 'package:methna_app/app/data/services/subscription_service.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class ThirdPartyIntegrationsScreen extends StatefulWidget {
  const ThirdPartyIntegrationsScreen({super.key});

  @override
  State<ThirdPartyIntegrationsScreen> createState() =>
      _ThirdPartyIntegrationsScreenState();
}

class _ThirdPartyIntegrationsScreenState
    extends State<ThirdPartyIntegrationsScreen> {
  final RxInt _selectedTab = 0.obs;
  late final StorageService _storage;
  late final MonetizationService _monetization;
  late final SubscriptionService _subscription;

  @override
  void initState() {
    super.initState();
    _storage = Get.find<StorageService>();
    _monetization = Get.find<MonetizationService>();
    _subscription = Get.find<SubscriptionService>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        _monetization.fetchStatus(),
        _subscription.fetchMySubscription(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSimplePageScaffold(
      title: 'integrations'.tr,
      subtitle: 'integrations_desc'.tr,
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            SettingsSegmentedControl(
              labels: ['account_access'.tr, 'billing'.tr],
              selectedIndex: _selectedTab.value,
              onSelected: (index) => _selectedTab.value = index,
            ),
            const SizedBox(height: AppSpacing.md),
            if (_selectedTab.value == 0) ...[
              _buildAccountAccessCard(),
              const SizedBox(height: AppSpacing.md),
              _InfoCard(
                title: 'supported_today'.tr,
                body:
                    'supported_today_desc'.tr,
              ),
            ] else ...[
              _buildBillingCard(),
              const SizedBox(height: AppSpacing.md),
              _InfoCard(
                title: 'billing_privacy'.tr,
                body:
                    'billing_privacy_desc'.tr,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountAccessCard() {
    final provider = (_storage.getAuthProvider() ?? 'email').toLowerCase();
    final usingGoogle = provider == 'google';

    return SettingsPlainListCard(
      children: [
        _IntegrationRow(
          label: usingGoogle ? 'google_sign_in'.tr : 'email_password'.tr,
          accent: usingGoogle ? const Color(0xFF4285F4) : AppColors.primary,
          initials: usingGoogle ? 'G' : 'E',
          statusLabel: 'active'.tr,
          statusTint: AppColors.primary,
          subtitle: usingGoogle
              ? 'auth_with_google'.tr
              : 'auth_with_methna'.tr,
        ),
        _IntegrationRow(
          label: usingGoogle ? 'email_password'.tr : 'google_sign_in'.tr,
          accent: usingGoogle ? AppColors.primary : const Color(0xFF4285F4),
          initials: usingGoogle ? 'E' : 'G',
          statusLabel: 'available'.tr,
          subtitle: usingGoogle
              ? 'methna_password_available'.tr
              : 'google_signin_available'.tr,
        ),
      ],
    );
  }

  Widget _buildBillingCard() {
    final hasPremium = _subscription.isPremium;
    final likesStatus = _monetization.isUnlimitedLikes.value
        ? 'unlimited_likes_active'.tr
        : '${_monetization.remainingLikes.value} ${'likes_left_today'.tr}';
    final isAppleDevice =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    final isAndroidDevice =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    return SettingsPlainListCard(
      children: [
        _IntegrationRow(
          label: 'stripe_billing'.tr,
          accent: const Color(0xFF635BFF),
          initials: 'S',
          statusLabel: hasPremium ? 'active'.tr : 'ready'.tr,
          statusTint: hasPremium ? AppColors.primary : null,
          subtitle: hasPremium
              ? 'stripe_active_desc'.tr
              : 'stripe_ready_desc'.tr,
        ),
        _IntegrationRow(
          label: 'google_pay'.tr,
          accent: const Color(0xFF34A853),
          initials: 'G',
          statusLabel: isAndroidDevice ? 'supported'.tr : 'device_dependent'.tr,
          subtitle:
              'google_pay_desc'.tr,
        ),
        _IntegrationRow(
          label: 'apple_pay'.tr,
          accent: const Color(0xFF111111),
          initials: 'A',
          statusLabel: isAppleDevice ? 'supported'.tr : 'device_dependent'.tr,
          subtitle:
              'apple_pay_desc'.tr,
        ),
        _IntegrationRow(
          label: 'premium_access'.tr,
          accent: const Color(0xFFE2559C),
          initials: 'P',
          statusLabel: hasPremium ? 'unlocked'.tr : 'free_plan'.tr,
          statusTint: hasPremium ? AppColors.primary : null,
          subtitle: likesStatus,
        ),
      ],
    );
  }
}

class _IntegrationRow extends StatelessWidget {
  final String label;
  final Color accent;
  final String initials;
  final String subtitle;
  final String statusLabel;
  final Color? statusTint;

  const _IntegrationRow({
    required this.label,
    required this.accent,
    required this.initials,
    required this.subtitle,
    required this.statusLabel,
    this.statusTint,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = statusTint;

    return SettingsPlainTile(
      title: label,
      subtitle: subtitle,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: AppTextStyles.titleMedium.copyWith(
            color: accent,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: tint != null
              ? tint.withValues(alpha: 0.12)
              : (isDark
                    ? AppColors.surfaceMutedDark
                    : AppColors.surfaceMutedLight),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          statusLabel,
          style: AppTextStyles.labelSmall.copyWith(
            color:
                tint ??
                (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;

  const _InfoCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return SettingsPlainListCard(
      children: [SettingsPlainTile(title: title, subtitle: body)],
    );
  }
}
