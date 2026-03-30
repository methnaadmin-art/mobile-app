import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/screens/settings/static_content_screen.dart' as methna_app;
import 'package:lucide_icons/lucide_icons.dart';

class ProfilePrivacyScreen extends GetView<SettingsController> {
  const ProfilePrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : Colors.white;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final hintColor =
        isDark ? AppColors.textHintDark : AppColors.textHintLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(LucideIcons.chevronLeft,
                          size: 16, color: textColor),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'profile_privacy'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Content ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // ── Section: Your Public Profile ──
                  _SectionHeader(
                      title: 'your_public_profile'.tr,
                      hintColor: hintColor),
                  const SizedBox(height: 8),

                  // Username
                  Obx(() => _ValueRow(
                    title: 'change_username'.tr,
                    value: controller.username,
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                    onTap: () =>
                        Get.toNamed(AppRoutes.changeUsername),
                  )),
                  _divider(isDark),

                  // View Web Profile
                  _ChevronRow(
                    title: 'view_web_profile'.tr,
                    textColor: textColor,
                    onTap: () {
                      Get.to(() => const methna_app.StaticContentScreen(title: 'Web Profile', contentType: 'web_profile'));
                    },
                  ),
                  _divider(isDark),

                  // Share My Profile
                  _ChevronRow(
                    title: 'share_my_profile'.tr,
                    textColor: textColor,
                    onTap: () {
                      final username = controller.username;
                      final link = 'https://methna.app/profile/$username';
                      Clipboard.setData(ClipboardData(text: link));
                      Helpers.showSnackbar(message: 'Profile link copied to clipboard');
                    },
                  ),

                  const SizedBox(height: 24),

                  // ── Section: Privacy & Visibility ──
                  _SectionHeader(
                      title: 'privacy_visibility'.tr,
                      hintColor: hintColor),
                  const SizedBox(height: 8),

                  // Visibility
                  _ChevronRow(
                    title: 'visibility'.tr,
                    subtitle: 'visibility_desc'.tr,
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                    onTap: () =>
                        Get.toNamed(AppRoutes.visibility),
                  ),
                  _divider(isDark),

                  // Show Age
                  _buildPrivacyToggle(
                    title: 'show_age'.tr.isNotEmpty ? 'show_age'.tr : 'Show Age',
                    subtitle: 'show_age_desc'.tr.isNotEmpty ? 'show_age_desc'.tr : 'Show your age on your profile',
                    value: controller.showAge,
                    onChanged: (v) => controller.updatePrivacy(showAgeVal: v),
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                  ),
                  _divider(isDark),

                  // Show Distance
                  _buildPrivacyToggle(
                    title: 'show_distance'.tr.isNotEmpty ? 'show_distance'.tr : 'Show Distance',
                    subtitle: 'show_distance_desc'.tr.isNotEmpty ? 'show_distance_desc'.tr : 'Show your distance to other users',
                    value: controller.showDistance,
                    onChanged: (v) => controller.updatePrivacy(showDist: v),
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                  ),
                  _divider(isDark),

                  // Show Online Status
                  _buildPrivacyToggle(
                    title: 'show_online_status'.tr.isNotEmpty ? 'show_online_status'.tr : 'Show Online Status',
                    subtitle: 'show_online_status_desc'.tr.isNotEmpty ? 'show_online_status_desc'.tr : 'Show when you are online',
                    value: controller.showOnlineStatus,
                    onChanged: (v) => controller.updatePrivacy(showOnline: v),
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                  ),
                  _divider(isDark),

                  // Show Last Seen
                  _buildPrivacyToggle(
                    title: 'show_last_seen'.tr.isNotEmpty ? 'show_last_seen'.tr : 'Show Last Seen',
                    subtitle: 'show_last_seen_desc'.tr.isNotEmpty ? 'show_last_seen_desc'.tr : 'Show when you were last active',
                    value: controller.showLastSeen,
                    onChanged: (v) => controller.updatePrivacy(showLastSeenVal: v),
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                  ),
                  _divider(isDark),

                  // Privacy Mode
                  _buildPrivacyToggle(
                    title: 'privacy_mode'.tr,
                    subtitle: 'privacy_mode_desc'.tr,
                    value: controller.privacyMode,
                    onChanged: (v) => controller.updatePrivacy(privacyModeVal: v),
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                  ),
                  _divider(isDark),

                  // Profile Verification
                  _ChevronRow(
                    title: 'profile_verification'.tr,
                    subtitle:
                        'profile_verification_desc'.tr,
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                    onTap: () {
                      Helpers.showSnackbar(message: 'Profile verification coming soon');
                    },
                  ),
                  _divider(isDark),

                  // Blocked Users
                  Obx(() => _ChevronRow(
                    title: '${'blocked_users'.tr} (${controller.blockedUsers.length})',
                    subtitle:
                        'blocked_users_desc'.tr,
                    textColor: textColor,
                    secondaryColor: secondaryColor,
                    onTap: () =>
                        Get.toNamed(AppRoutes.blockedUsers),
                  )),

                  const SizedBox(height: 24),

                  // ── Section: Messages & Active Status ──
                  _SectionHeader(
                      title: 'messages_active_status'.tr,
                      hintColor: hintColor),
                  const SizedBox(height: 8),

                  // Manage Active Status
                  _ChevronRow(
                    title: 'manage_active_status'.tr,
                    textColor: textColor,
                    onTap: () =>
                        Get.toNamed(AppRoutes.manageActiveStatus),
                  ),
                  _divider(isDark),

                  // Manage Messages
                  _ChevronRow(
                    title: 'manage_messages'.tr,
                    textColor: textColor,
                    onTap: () =>
                        Get.toNamed(AppRoutes.manageMessages),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyToggle({
    required String title,
    required String subtitle,
    required RxBool value,
    required Function(bool) onChanged,
    required Color textColor,
    required Color? secondaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: secondaryColor),
                ),
              ],
            ),
          ),
          Obx(() => Switch(
                value: value.value,
                onChanged: onChanged,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
              )),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? AppColors.dividerDark : Colors.grey.shade200,
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final Color hintColor;
  const _SectionHeader({required this.title, required this.hintColor});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: hintColor,
      ),
    );
  }
}

// ─── Value row (title + value + chevron) ──────────────────────────────────
class _ValueRow extends StatelessWidget {
  final String title;
  final String value;
  final Color textColor;
  final Color secondaryColor;
  final VoidCallback onTap;

  const _ValueRow({
    required this.title,
    required this.value,
    required this.textColor,
    required this.secondaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(fontSize: 14, color: secondaryColor),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronRight,
                size: 22, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ─── Chevron row ──────────────────────────────────────────────────────────
class _ChevronRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color textColor;
  final Color? secondaryColor;
  final VoidCallback onTap;

  const _ChevronRow({
    required this.title,
    this.subtitle,
    required this.textColor,
    this.secondaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                          fontSize: 12, color: secondaryColor),
                    ),
                  ],
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 22, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
