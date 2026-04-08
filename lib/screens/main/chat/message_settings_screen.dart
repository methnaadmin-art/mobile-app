import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/widgets/app_card.dart';
import 'package:methna_app/core/widgets/datify_shell.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class MessageSettingsScreen extends StatelessWidget {
  const MessageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final receiveMessages = true.obs;
    final readReceipts = true.obs;
    final typingIndicators = true.obs;
    final messagePreview = true.obs;
    final notifications = true.obs;
    final sound = true.obs;
    final vibration = false.obs;
    final blockLinks = false.obs;
    final autoDownload = true.obs;
    final selectedFont = 'Medium'.obs;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: DatifyBackground(
        compact: true,
        child: SafeArea(
          child: Obx(
            () => ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: [
                Row(
                  children: [
                    DatifyBackButton(onTap: () => Get.back()),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Manage Messages',
                          style: AppTextStyles.headlineMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _SectionTitle(
                  title: 'Primary Controls',
                  subtitle:
                      'Choose who can reach you and what they can see.',
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  radius: AppRadii.xxl,
                  child: Column(
                    children: [
                      _ToggleRow(
                        title: 'Receive Direct Messages',
                        subtitle:
                            'If turned off, people can no longer start new chats with you.',
                        value: receiveMessages.value,
                        onChanged: (value) => receiveMessages.value = value,
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? AppColors.dividerDark
                            : AppColors.dividerLight,
                      ),
                      _ToggleRow(
                        title: 'Read Receipts',
                        subtitle:
                            'Let people know when you have seen their messages.',
                        value: readReceipts.value,
                        onChanged: (value) => readReceipts.value = value,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _SectionTitle(
                  title: 'Notifications',
                  subtitle:
                      'Adjust how message alerts appear on your device.',
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  radius: AppRadii.xxl,
                  child: Column(
                    children: [
                      _ToggleRow(
                        title: 'Typing Indicators',
                        subtitle: 'Show when you are typing a reply.',
                        value: typingIndicators.value,
                        onChanged: (value) => typingIndicators.value = value,
                      ),
                      _Divider(isDark: isDark),
                      _ToggleRow(
                        title: 'Message Preview',
                        subtitle: 'Show message content in push notifications.',
                        value: messagePreview.value,
                        onChanged: (value) => messagePreview.value = value,
                      ),
                      _Divider(isDark: isDark),
                      _ToggleRow(
                        title: 'Message Notifications',
                        subtitle: 'Receive alerts when a new message arrives.',
                        value: notifications.value,
                        onChanged: (value) => notifications.value = value,
                      ),
                      _Divider(isDark: isDark),
                      _ToggleRow(
                        title: 'Message Sound',
                        subtitle: 'Play a sound for incoming messages.',
                        value: sound.value,
                        onChanged: (value) => sound.value = value,
                      ),
                      _Divider(isDark: isDark),
                      _ToggleRow(
                        title: 'Vibration',
                        subtitle: 'Vibrate on incoming messages.',
                        value: vibration.value,
                        onChanged: (value) => vibration.value = value,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _SectionTitle(
                  title: 'Media & Privacy',
                  subtitle:
                      'Control media downloads and a few extra chat preferences.',
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  radius: AppRadii.xxl,
                  child: Column(
                    children: [
                      _ToggleRow(
                        title: 'Block Links',
                        subtitle:
                            'Prevent receiving messages containing links.',
                        value: blockLinks.value,
                        onChanged: (value) => blockLinks.value = value,
                      ),
                      _Divider(isDark: isDark),
                      _ToggleRow(
                        title: 'Auto-Download Media',
                        subtitle:
                            'Automatically download shared photos and voice notes.',
                        value: autoDownload.value,
                        onChanged: (value) => autoDownload.value = value,
                      ),
                      _Divider(isDark: isDark),
                      _ValueRow(
                        title: 'Chat Font Size',
                        subtitle: 'Adjust text size inside conversations.',
                        value: selectedFont.value,
                        onTap: () => _showFontSizeDialog(context, selectedFont),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showFontSizeDialog(
    BuildContext context,
    RxString selectedFont,
  ) async {
    final selected = await showSettingsChoiceSheet<String>(
      context: context,
      title: 'Chat Font Size',
      options: [
        SettingsSheetOption(
          value: 'Small',
          title: 'Small',
          selected: selectedFont.value == 'Small',
        ),
        SettingsSheetOption(
          value: 'Medium',
          title: 'Medium',
          selected: selectedFont.value == 'Medium',
        ),
        SettingsSheetOption(
          value: 'Large',
          title: 'Large',
          selected: selectedFont.value == 'Large',
        ),
        SettingsSheetOption(
          value: 'Extra Large',
          title: 'Extra Large',
          selected: selectedFont.value == 'Extra Large',
        ),
      ],
    );

    if (selected != null) {
      selectedFont.value = selected;
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback onTap;

  const _ValueRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.textHintLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;

  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: AppSpacing.md,
      endIndent: AppSpacing.md,
      color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
    );
  }
}
