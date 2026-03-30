import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : const Color(0xFFF8F5FA);
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtitleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor),
                      ),
                      child: Icon(LucideIcons.chevronLeft, size: 18, color: textColor),
                    ),
                  ),
                  const Spacer(),
                  Text('settings'.tr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Content ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // ── Upgrade banner ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(LucideIcons.crown, size: 20, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('upgrade_membership'.tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                              const SizedBox(height: 2),
                              Text('upgrade_membership_desc'.tr, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight, size: 20, color: Colors.white70),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Account Section ──
                  _SectionLabel(label: 'Account', isDark: isDark),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    isDark: isDark, cardBg: cardBg, borderColor: borderColor,
                    children: [
                      _SettingsRow(icon: LucideIcons.compass, iconColor: const Color(0xFFFF6B6B), title: 'discovery_preferences'.tr, textColor: textColor, onTap: () => Get.toNamed(AppRoutes.discoveryPreferences)),
                      _Divider(isDark: isDark),
                      _SettingsRow(icon: LucideIcons.shieldCheck, iconColor: const Color(0xFF4ECDC4), title: 'profile_privacy'.tr, textColor: textColor, onTap: () => Get.toNamed(AppRoutes.profilePrivacy)),
                      _Divider(isDark: isDark),
                      _SettingsRow(icon: LucideIcons.lock, iconColor: AppColors.primary, title: 'account_security'.tr, textColor: textColor, onTap: () => Get.toNamed(AppRoutes.accountSecurity)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Communication Section ──
                  _SectionLabel(label: 'Communication', isDark: isDark),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    isDark: isDark, cardBg: cardBg, borderColor: borderColor,
                    children: [
                      _SettingsRow(icon: LucideIcons.bellRing, iconColor: const Color(0xFFFFBE0B), title: 'notification'.tr, textColor: textColor, onTap: () => Get.toNamed(AppRoutes.notificationSettings)),
                      _Divider(isDark: isDark),
                      _SettingsRow(icon: LucideIcons.messageSquare, iconColor: const Color(0xFF2196F3), title: 'chat_settings'.tr, textColor: textColor, onTap: () => Get.toNamed(AppRoutes.manageMessages)),
                      _Divider(isDark: isDark),
                      _SettingsRow(icon: LucideIcons.shieldOff, iconColor: const Color(0xFFEF5350), title: 'blocked_users'.tr, textColor: textColor, onTap: () => Get.toNamed(AppRoutes.blockedUsers)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Security Section ──
                  _SectionLabel(label: 'security'.tr, isDark: isDark),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    isDark: isDark, cardBg: cardBg, borderColor: borderColor,
                    children: [
                      // Biometric Authentication Toggle
                      Obx(() => _SettingsToggleRow(
                        icon: LucideIcons.fingerprint,
                        iconColor: const Color(0xFF9C27B0),
                        title: 'biometric_lock'.tr,
                        subtitle: 'biometric_lock_desc'.tr,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        value: controller.biometricId.value,
                        onChanged: (val) => controller.toggleBiometric(val),
                      )),
                      _Divider(isDark: isDark),
                      // Face ID Toggle
                      Obx(() => _SettingsToggleRow(
                        icon: LucideIcons.scanFace,
                        iconColor: const Color(0xFF2196F3),
                        title: 'face_id'.tr,
                        subtitle: 'face_id_desc'.tr,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        value: controller.faceId.value,
                        onChanged: (val) => controller.toggleFaceId(val),
                      )),
                      _Divider(isDark: isDark),
                      // Remember Me Toggle
                      Obx(() => _SettingsToggleRow(
                        icon: LucideIcons.userCheck,
                        iconColor: const Color(0xFF4CAF50),
                        title: 'remember_me'.tr,
                        subtitle: 'remember_me_desc'.tr,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        value: controller.rememberMe.value,
                        onChanged: (val) => controller.toggleRememberMe(val),
                      )),
                      _Divider(isDark: isDark),
                      _SettingsRow(icon: LucideIcons.keyRound, iconColor: const Color(0xFFFF9800), title: 'change_password'.tr, textColor: textColor, onTap: () => _showChangePasswordDialog(context)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Preferences Section ──
                  _SectionLabel(label: 'Preferences', isDark: isDark),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    isDark: isDark, cardBg: cardBg, borderColor: borderColor,
                    children: [
                      _SettingsRow(icon: LucideIcons.sparkles, iconColor: const Color(0xFFFF8C42), title: 'subscription'.tr, textColor: textColor, onTap: () => Get.toNamed(AppRoutes.subscription)),
                      _Divider(isDark: isDark),
                      _SettingsRow(icon: LucideIcons.paintbrush, iconColor: AppColors.primary, title: 'app_appearance'.tr, textColor: textColor, onTap: () => Get.toNamed(AppRoutes.appAppearance)),
                      _Divider(isDark: isDark),
                      _SettingsRow(icon: LucideIcons.languages, iconColor: const Color(0xFF00BCD4), title: 'app_language'.tr, textColor: textColor, onTap: () => Get.toNamed(AppRoutes.appLanguage)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Data & Storage Section ──
                  _SectionLabel(label: 'data_storage'.tr, isDark: isDark),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    isDark: isDark, cardBg: cardBg, borderColor: borderColor,
                    children: [
                      _SettingsRow(icon: LucideIcons.hardDrive, iconColor: const Color(0xFF607D8B), title: 'clear_cache'.tr, textColor: textColor, onTap: () => _showClearCacheDialog(context)),
                      _Divider(isDark: isDark),
                      _SettingsRow(icon: LucideIcons.download, iconColor: const Color(0xFF009688), title: 'download_my_data'.tr, textColor: textColor, onTap: () => _showDownloadDataDialog(context)),
                      _Divider(isDark: isDark),
                      _SettingsRow(icon: LucideIcons.refreshCw, iconColor: const Color(0xFFFF5722), title: 'reset_app_data'.tr, textColor: textColor, onTap: () => _showResetDataDialog(context)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── More Section ──
                  _SectionLabel(label: 'more'.tr, isDark: isDark),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    isDark: isDark, cardBg: cardBg, borderColor: borderColor,
                    children: [
                      _SettingsRow(icon: LucideIcons.barChart3, iconColor: const Color(0xFF4CAF50), title: 'data_analytics'.tr, textColor: textColor, onTap: () => Get.toNamed(AppRoutes.dataAnalytics)),
                      _Divider(isDark: isDark),
                      _SettingsRow(icon: LucideIcons.fileWarning, iconColor: AppColors.error, title: 'report_request'.tr, textColor: textColor, onTap: () => Get.toNamed(AppRoutes.reportRequest)),
                      _Divider(isDark: isDark),
                      _SettingsRow(icon: LucideIcons.lifeBuoy, iconColor: const Color(0xFF9C27B0), title: 'help_support'.tr, textColor: textColor, onTap: () => Get.toNamed(AppRoutes.helpSupport)),
                      _Divider(isDark: isDark),
                      _SettingsRow(icon: LucideIcons.info, iconColor: const Color(0xFF3F51B5), title: 'about_app'.tr, textColor: textColor, onTap: () => _showAboutDialog(context)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Legal Section ──
                  _SectionLabel(label: 'Legal', isDark: isDark),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    isDark: isDark, cardBg: cardBg, borderColor: borderColor,
                    children: [
                      _SettingsRow(icon: LucideIcons.fileText, iconColor: const Color(0xFF607D8B), title: 'Terms & Conditions', textColor: textColor, onTap: () => Get.toNamed(AppRoutes.termsConditions)),
                      _Divider(isDark: isDark),
                      _SettingsRow(icon: LucideIcons.shieldAlert, iconColor: const Color(0xFF607D8B), title: 'Privacy Policy', textColor: textColor, onTap: () => Get.toNamed(AppRoutes.privacyPolicy)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Logout ──
                  GestureDetector(
                    onTap: () => _showLogoutDialog(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.logOut, size: 18, color: AppColors.error),
                          const SizedBox(width: 8),
                          Text('logout'.tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.error)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Center(
                    child: Text('Methna v1.0.0', style: TextStyle(fontSize: 12, color: subtitleColor)),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.logOut, size: 28, color: AppColors.error),
              ),
              const SizedBox(height: 20),
              Text('logout'.tr, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              const SizedBox(height: 8),
              Text('logout_confirm'.tr, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('cancel'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () { Get.back(); controller.logout(); },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('logout'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
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

  void _showChangePasswordDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.keyRound, size: 28, color: Color(0xFFFF9800)),
              ),
              const SizedBox(height: 20),
              Text('change_password'.tr, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              const SizedBox(height: 16),
              TextField(
                controller: oldPassController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'current_password'.tr,
                  filled: true,
                  fillColor: isDark ? AppColors.backgroundDark : const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPassController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'new_password'.tr,
                  filled: true,
                  fillColor: isDark ? AppColors.backgroundDark : const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'confirm_password'.tr,
                  filled: true,
                  fillColor: isDark ? AppColors.backgroundDark : const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('cancel'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (newPassController.text != confirmPassController.text) {
                          Get.snackbar('Error', 'passwords_dont_match'.tr, snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        Get.back();
                        await controller.changePassword(oldPassController.text, newPassController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('change'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
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

  void _showClearCacheDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF607D8B).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.hardDrive, size: 28, color: Color(0xFF607D8B)),
              ),
              const SizedBox(height: 20),
              Text('clear_cache'.tr, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              const SizedBox(height: 8),
              Text(
                'clear_cache_desc'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('cancel'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back();
                        await controller.clearCache();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF607D8B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('clear'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
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

  void _showDownloadDataDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF009688).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.download, size: 28, color: Color(0xFF009688)),
              ),
              const SizedBox(height: 20),
              Text('download_my_data'.tr, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              const SizedBox(height: 8),
              Text(
                'download_data_desc'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('cancel'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back();
                        await controller.requestDataDownload();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('request'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
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

  void _showAboutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(LucideIcons.heart, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text('Methna', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              const SizedBox(height: 4),
              Text('v1.0.0', style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              const SizedBox(height: 16),
              Text(
                'about_app_desc'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('close'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetDataDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.refreshCw, size: 28, color: Color(0xFFFF5722)),
              ),
              const SizedBox(height: 20),
              Text('Reset App Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              const SizedBox(height: 8),
              Text(
                'This will clear all local data including preferences and cached content. You will remain logged in.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('cancel'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back();
                        await controller.resetAppData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w700)),
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

// ─── Section Label ────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: isDark ? AppColors.textHintDark : AppColors.textHintLight)),
    );
  }
}

// ─── Settings Card ────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final List<Widget> children;
  const _SettingsCard({required this.isDark, required this.cardBg, required this.borderColor, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 0.5),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }
}

// ─── Divider ──────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 60),
      child: Divider(height: 0.5, thickness: 0.5, color: isDark ? AppColors.borderDark : AppColors.dividerLight),
    );
  }
}

// ─── Settings Row ─────────────────────────────────────────────────────────
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color textColor;
  final VoidCallback onTap;

  const _SettingsRow({required this.icon, required this.iconColor, required this.title, required this.textColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor))),
              Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Settings Toggle Row ───────────────────────────────────────────────────
class _SettingsToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color textColor;
  final Color subtitleColor;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.subtitleColor,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: subtitleColor)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
