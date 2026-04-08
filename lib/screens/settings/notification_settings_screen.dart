import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class NotificationSettingsScreen extends GetView<SettingsController> {
  const NotificationSettingsScreen({super.key});

  static const _settingKeys = [
    'matchNotifications',
    'messageNotifications',
    'likeNotifications',
    'profileVisitorNotifications',
    'eventsNotifications',
    'safetyAlertNotifications',
    'promotionsNotifications',
    'inAppRecommendationNotifications',
    'weeklySummaryNotifications',
    'connectionRequestNotifications',
    'surveyNotifications',
  ];

  static const _settingLabels = [
    'new_matches',
    'new_messages',
    'likes_notifications',
    'profile_visitors',
    'events_activities',
    'safety_alerts',
    'promotions_news',
    'in_app_recommendations',
    'weekly_activity_summary',
    'connection_requests',
    'survey_feedback',
  ];

  @override
  Widget build(BuildContext context) {
    return SettingsSimplePageScaffold(
      title: 'notification'.tr,
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            if (controller.isLoadingNotifSettings.value)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else
              _SettingsNoteCard(
                title: 'notification_preferences'.tr,
                body:
                    'notification_preferences_desc'.tr,
              ),
            if (!controller.isLoadingNotifSettings.value) ...[
              const SizedBox(height: AppSpacing.md),
              SettingsPlainListCard(
                children: List.generate(_settingKeys.length, (index) {
                  final key = _settingKeys[index];
                  return SettingsPlainSwitchTile(
                    title: _settingLabels[index].tr,
                    value: controller.notifSettings[key] ?? false,
                    onChanged: (value) =>
                        controller.updateNotifSetting(key, value),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsNoteCard extends StatelessWidget {
  final String title;
  final String body;

  const _SettingsNoteCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceGlassDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
