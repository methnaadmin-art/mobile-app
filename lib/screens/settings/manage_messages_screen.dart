import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class ManageMessagesScreen extends GetView<SettingsController> {
  const ManageMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSimplePageScaffold(
      title: 'manage_messages'.tr,
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            SettingsPlainListCard(
              children: [
                SettingsPlainSwitchTile(
                  title: 'receive_direct_messages'.tr,
                  subtitle: 'receive_direct_messages_desc'.tr,
                  value: controller.receiveDMs.value,
                  onChanged: (value) =>
                      controller.updateChatSetting('receiveDMs', value),
                ),
                SettingsPlainSwitchTile(
                  title: 'read_receipts'.tr,
                  subtitle: 'read_receipts_desc'.tr,
                  value: controller.readReceipts.value,
                  onChanged: (value) =>
                      controller.updateChatSetting('readReceipts', value),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsSectionLabel(text: 'additional_controls'.tr),
            SettingsPlainListCard(
              children: [
                SettingsPlainSwitchTile(
                  title: 'typing_indicator'.tr,
                  subtitle: 'typing_indicator_desc'.tr,
                  value: controller.typingIndicator.value,
                  onChanged: (value) =>
                      controller.updateChatSetting('typingIndicator', value),
                ),
                SettingsPlainSwitchTile(
                  title: 'message_notifications'.tr,
                  subtitle: 'message_notifications_desc'.tr,
                  value:
                      controller.notifSettings['messageNotifications'] ?? true,
                  onChanged: (value) => controller.updateNotifSetting(
                    'messageNotifications',
                    value,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
