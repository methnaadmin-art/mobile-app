import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/widgets/app_card.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class NotificationSettingsScreen extends GetView<SettingsController> {
  const NotificationSettingsScreen({super.key});

  static const List<_NotificationItem> _realTimeItems = [
    _NotificationItem(
      key: 'messageNotifications',
      labelKey: 'new_messages',
      subtitle: 'Receive alerts the moment a message arrives.',
    ),
    _NotificationItem(
      key: 'matchNotifications',
      labelKey: 'new_matches',
      subtitle: 'Know instantly when a new match is created.',
    ),
    _NotificationItem(
      key: 'likeNotifications',
      labelKey: 'likes_notifications',
      subtitle: 'Get notified when someone likes your profile.',
    ),
    _NotificationItem(
      key: 'complimentNotifications',
      labelKey: 'compliments_label',
      subtitle: 'Stay informed about compliments and replies.',
    ),
    _NotificationItem(
      key: 'profileVisitorNotifications',
      labelKey: 'profile_visitors',
      subtitle: 'See when someone checks your profile.',
    ),
  ];

  static const List<_NotificationItem> _accountItems = [
    _NotificationItem(
      key: 'safetyAlertNotifications',
      labelKey: 'safety_alerts',
      subtitle: 'Critical security and account-related alerts.',
    ),
    _NotificationItem(
      key: 'connectionRequestNotifications',
      labelKey: 'connection_requests',
      subtitle: 'Updates on requests and important relationship actions.',
    ),
  ];

  static const List<_NotificationItem> _digestItems = [
    _NotificationItem(
      key: 'eventsNotifications',
      labelKey: 'events_activities',
      subtitle: 'Invites, events, and community activity updates.',
    ),
    _NotificationItem(
      key: 'promotionsNotifications',
      labelKey: 'promotions_news',
      subtitle: 'Product updates and premium promotions.',
    ),
    _NotificationItem(
      key: 'inAppRecommendationNotifications',
      labelKey: 'in_app_recommendations',
      subtitle: 'Suggestions to improve profile quality and visibility.',
    ),
    _NotificationItem(
      key: 'weeklySummaryNotifications',
      labelKey: 'weekly_activity_summary',
      subtitle: 'Weekly snapshot of likes, matches, and engagement.',
    ),
    _NotificationItem(
      key: 'surveyNotifications',
      labelKey: 'survey_feedback',
      subtitle: 'Occasional feedback requests to improve your experience.',
    ),
  ];

  int _pendingCount(SettingsController controller) {
    final allItems = [..._realTimeItems, ..._accountItems, ..._digestItems];
    return allItems
        .where(
          (item) => controller.getNotificationSyncStatus(item.key) == 'pending',
        )
        .length;
  }

  String _effectiveSubtitle(
    SettingsController controller,
    _NotificationItem item,
  ) {
    final status = controller.getNotificationSyncStatus(item.key);
    if (status == 'syncing') {
      return 'Saving your change...';
    }
    if (status == 'pending') {
      return 'Saved locally. It will sync automatically when possible.';
    }
    return item.subtitle;
  }

  Widget _buildSection(
    SettingsController controller, {
    required String title,
    required List<_NotificationItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SettingsPlainListCard(
          children: items
              .map(
                (item) => SettingsPlainSwitchTile(
                  title: item.labelKey.tr,
                  subtitle: _effectiveSubtitle(controller, item),
                  value: controller.notifSettings[item.key] ?? true,
                  onChanged: (value) =>
                      controller.updateNotifSetting(item.key, value),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSimplePageScaffold(
      title: 'notification'.tr,
      subtitle: 'notification_preferences_desc'.tr,
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
            else ...[
              _SettingsSummaryCard(
                isSyncing: controller.isSyncingNotifSettings.value,
                pendingCount: _pendingCount(controller),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                controller,
                title: 'Real-time activity',
                items: _realTimeItems,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                controller,
                title: 'Security & account',
                items: _accountItems,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSection(
                controller,
                title: 'Updates & digests',
                items: _digestItems,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsSummaryCard extends StatelessWidget {
  final bool isSyncing;
  final int pendingCount;

  const _SettingsSummaryCard({
    required this.isSyncing,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: AppRadii.xl,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'notification_preferences'.tr,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  isSyncing
                      ? 'Syncing your latest notification changes.'
                      : pendingCount > 0
                          ? '$pendingCount change(s) saved locally and queued for sync.'
                          : 'All notification preferences are synced.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem {
  final String key;
  final String labelKey;
  final String subtitle;

  const _NotificationItem({
    required this.key,
    required this.labelKey,
    required this.subtitle,
  });
}
