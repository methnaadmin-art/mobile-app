import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NotificationSettingsScreen extends GetView<SettingsController> {
  const NotificationSettingsScreen({super.key});

  static const _icons = [
    LucideIcons.heart, LucideIcons.messageCircle, LucideIcons.star,
    LucideIcons.eye, LucideIcons.calendar, LucideIcons.shieldCheck,
    LucideIcons.megaphone, LucideIcons.lightbulb, LucideIcons.barChart3,
    LucideIcons.userPlus, LucideIcons.clipboardList,
  ];

  static const _iconColors = [
    Color(0xFFE91E63), Color(0xFF2196F3), Color(0xFFFF9800),
    Color(0xFF9C27B0), Color(0xFF4CAF50), Color(0xFF00BCD4),
    Color(0xFFFF6B6B), Color(0xFFFFC107), Color(0xFF3F51B5),
    Color(0xFF4ECDC4), Color(0xFF795548),
  ];

  static const _settingKeys = [
    'matchNotifications', 'messageNotifications', 'likeNotifications', 'profileVisitorNotifications',
    'eventsNotifications', 'safetyAlertNotifications', 'promotionsNotifications',
    'inAppRecommendationNotifications', 'weeklySummaryNotifications', 'connectionRequestNotifications', 'surveyNotifications',
  ];

  static const _settingLabels = [
    'new_matches', 'new_messages', 'likes_notifications', 'profile_visitors',
    'events_activities', 'safety_alerts', 'promotions_news',
    'in_app_recommendations', 'weekly_activity_summary', 'connection_requests', 'survey_feedback',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : const Color(0xFFF8F5FA);
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final selectedTab = 0.obs;

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
                      decoration: BoxDecoration(color: cardBg, shape: BoxShape.circle, border: Border.all(color: borderColor)),
                      child: Icon(LucideIcons.chevronLeft, size: 18, color: textColor),
                    ),
                  ),
                  const Spacer(),
                  Text('notification'.tr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Tab bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(() => Container(
                height: 46,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: List.generate(2, (i) {
                    final active = selectedTab.value == i;
                    final labels = ['push_notifications'.tr, 'email_notifications'.tr];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => selectedTab.value = i,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: active ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
                          ),
                          child: Text(labels[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? Colors.white : textColor)),
                        ),
                      ),
                    );
                  }),
                ),
              )),
            ),

            const SizedBox(height: 16),

            // ── Toggle list ──
            Expanded(
              child: Obx(() {
                if (controller.isLoadingNotifSettings.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor, width: 0.5),
                        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        children: List.generate(_settingKeys.length, (index) {
                          final key = _settingKeys[index];
                          final label = _settingLabels[index].tr;
                          final value = controller.notifSettings[key] ?? false;
                          final icon = _icons[index];
                          final iconColor = _iconColors[index];

                          return Column(
                            children: [
                              Padding(
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
                                    Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor))),
                                    Switch.adaptive(
                                      value: value,
                                      onChanged: (v) => controller.updateNotifSetting(key, v),
                                      activeTrackColor: AppColors.primary,
                                      activeThumbColor: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                              if (index < _settingKeys.length - 1)
                                Padding(
                                  padding: const EdgeInsets.only(left: 64),
                                  child: Divider(height: 0.5, thickness: 0.5, color: isDark ? AppColors.borderDark : AppColors.dividerLight),
                                ),
                            ],
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
