import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/widgets/custom_button.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class ClearCacheInfoScreen extends StatefulWidget {
  const ClearCacheInfoScreen({super.key});

  @override
  State<ClearCacheInfoScreen> createState() => _ClearCacheInfoScreenState();
}

class _ClearCacheInfoScreenState extends State<ClearCacheInfoScreen> {
  bool _isRunning = false;

  SettingsController get controller => Get.find<SettingsController>();

  Future<void> _runClearCache() async {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    try {
      await controller.clearCache();
    } finally {
      if (mounted) {
        setState(() => _isRunning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSimplePageScaffold(
      title: 'clear_cache'.tr,
      subtitle: 'clear_cache_info_subtitle'.tr,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          _ActionInfoCard(
            title: 'clear_cache_clears_title'.tr,
            icon: LucideIcons.trash2,
            iconColor: const Color(0xFF2F9BFF),
            items: [
              'clear_cache_item_images'.tr,
              'clear_cache_item_temp'.tr,
              'clear_cache_item_memory'.tr,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ActionInfoCard(
            title: 'clear_cache_keeps_title'.tr,
            icon: LucideIcons.shieldCheck,
            iconColor: const Color(0xFF25A766),
            items: [
              'clear_cache_safe_account'.tr,
              'clear_cache_safe_chats'.tr,
              'clear_cache_safe_subscription'.tr,
            ],
          ),
        ],
      ),
      footer: CustomButton(
        text: _isRunning ? 'loading'.tr : 'clear_cache_now'.tr,
        onPressed: _isRunning ? null : _runClearCache,
      ),
    );
  }
}

class ResetAppDataInfoScreen extends GetView<SettingsController> {
  const ResetAppDataInfoScreen({super.key});

  Future<void> _confirmAndReset() async {
    final approved = await Get.dialog<bool>(
      AlertDialog(
        title: Text('reset_data_confirm_title'.tr),
        content: Text('reset_app_data_warning'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'reset'.tr,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (approved == true) {
      await controller.resetAppData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSimplePageScaffold(
      title: 'reset_app_data'.tr,
      subtitle: 'reset_app_data_info_subtitle'.tr,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          _ActionInfoCard(
            title: 'reset_app_data_will_reset_title'.tr,
            icon: LucideIcons.rotateCcw,
            iconColor: const Color(0xFFFF9D1F),
            items: [
              'reset_app_data_item_filters'.tr,
              'reset_app_data_item_privacy'.tr,
              'reset_app_data_item_local'.tr,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ActionInfoCard(
            title: 'reset_app_data_will_keep_title'.tr,
            icon: LucideIcons.shieldCheck,
            iconColor: const Color(0xFF25A766),
            items: [
              'reset_app_data_keep_account'.tr,
              'reset_app_data_keep_server'.tr,
              'reset_app_data_keep_subscription'.tr,
            ],
          ),
        ],
      ),
      footer: Obx(
        () => CustomButton(
          text: controller.isResettingData.value
              ? 'loading'.tr
              : 'reset_app_data_now'.tr,
          onPressed: controller.isResettingData.value ? null : _confirmAndReset,
        ),
      ),
    );
  }
}

class _ActionInfoCard extends StatelessWidget {
  const _ActionInfoCard({
    required this.title,
    required this.items,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE8E8EF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.6,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF232129),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.8)
                          : const Color(0xFF4A4F57),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 12.4,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.88)
                            : const Color(0xFF525865),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
