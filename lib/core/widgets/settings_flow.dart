import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/widgets/app_card.dart';
import 'package:methna_app/core/widgets/app_modal_sheet.dart';

class SettingsSimplePageScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? footer;
  final Widget? trailing;
  final String? subtitle;
  final VoidCallback? onBack;

  const SettingsSimplePageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.footer,
    this.trailing,
    this.subtitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  _SettingsNavButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: onBack ?? () => Get.back(),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        if (subtitle != null && subtitle!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(
                              subtitle!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: trailing ?? const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(child: body),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: footer!,
              ),
          ],
        ),
      ),
    );
  }
}

class SettingsPageScaffold extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? footer;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool expandBody;

  const SettingsPageScaffold({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.body,
    this.subtitle,
    this.footer,
    this.actions,
    this.onBack,
    this.expandBody = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SettingsNavButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: onBack ?? () => Get.back(),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      children: [
                        if (eyebrow.trim().isNotEmpty)
                          Text(
                            eyebrow,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        if (eyebrow.trim().isNotEmpty)
                          const SizedBox(height: AppSpacing.xxs),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        if (subtitle != null && subtitle!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(
                              subtitle!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: actions == null || actions!.isEmpty
                        ? const SizedBox.shrink()
                        : Align(
                            alignment: Alignment.centerRight,
                            child: actions!.length == 1
                                ? actions!.first
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: actions!
                                        .map(
                                          (action) => Padding(
                                            padding: const EdgeInsets.only(
                                              left: AppSpacing.xs,
                                            ),
                                            child: action,
                                          ),
                                        )
                                        .toList(growable: false),
                                  ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (expandBody) Expanded(child: body) else body,
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: footer!,
              ),
          ],
        ),
      ),
    );
  }
}

class SettingsPlainListCard extends StatelessWidget {
  final List<Widget> children;

  const SettingsPlainListCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      radius: 22,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
          ],
        ],
      ),
    );
  }
}

class SettingsPlainTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool destructive;

  const SettingsPlainTile({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.leading,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = destructive
        ? AppColors.error
        : isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 15,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  flex: 0,
                  child: Text(
                    value!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ] else if (onTap != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? AppColors.textHintDark
                      : AppColors.textHintLight,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPlainSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SettingsPlainSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsPlainTile(
      title: title,
      subtitle: subtitle,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      trailing: Transform.scale(
        scale: 0.9,
        child: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
          activeThumbColor: Colors.white,
        ),
      ),
    );
  }
}

class SettingsRadioTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const SettingsRadioTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsPlainTile(
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.textHintLight,
            width: 1.8,
          ),
        ),
        child: selected
            ? Container(
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              )
            : null,
      ),
    );
  }
}

class SettingsSegmentedControl extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const SettingsSegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceMutedDark
            : AppColors.surfaceMutedLight,
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[index],
                  style: AppTextStyles.bodySmall.copyWith(
                    color: active
                        ? Colors.white
                        : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class SettingsPromoBanner extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const SettingsPromoBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF7F38FF), Color(0xFFB44CFF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.sparkles,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onTap,
        splashRadius: 22,
        icon: Icon(
          icon,
          size: 18,
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}

class SettingsGroupCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const SettingsGroupCard({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      radius: AppRadii.hero,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: padding,
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 56),
                  child: Divider(
                    height: 0.5,
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class SettingsSectionLabel extends StatelessWidget {
  final String text;

  const SettingsSectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: AppTextStyles.labelMedium.copyWith(
            color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = destructive
        ? AppColors.error
        : isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final subtitleColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: titleColor,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark
                        ? AppColors.textHintDark
                        : AppColors.textHintLight,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsValueTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;

  const SettingsValueTile({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.value,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      accent: accent,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: Text(
        value,
        style: AppTextStyles.titleSmall.copyWith(color: accent),
      ),
    );
  }
}

class SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SettingsToggleTile({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      accent: accent,
      title: title,
      subtitle: subtitle,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary,
      ),
    );
  }
}

class SettingsChoiceCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const SettingsChoiceCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      onTap: onTap,
      variant: selected ? AppCardVariant.tinted : AppCardVariant.surface,
      tint: AppColors.primary,
      radius: AppRadii.xl,
      child: Row(
        children: [
          Expanded(
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
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.textHintLight,
                width: 2,
              ),
            ),
            child: selected
                ? Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class SettingsStatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  const SettingsStatPill({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(color: accent),
              ),
              Text(
                value,
                style: AppTextStyles.titleSmall.copyWith(color: accent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<T?> showSettingsChoiceSheet<T>({
  required BuildContext context,
  required String title,
  required List<SettingsSheetOption<T>> options,
}) {
  return showMethnaModalSheet<T>(
    context: context,
    title: title,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 460),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, index) {
          final option = options[index];
          return SettingsChoiceCard(
            title: option.title,
            subtitle: option.subtitle,
            selected: option.selected,
            onTap: () => Navigator.of(context).pop(option.value),
          );
        },
      ),
    ),
  );
}

class SettingsSheetOption<T> {
  final T value;
  final String title;
  final String? subtitle;
  final bool selected;

  const SettingsSheetOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.selected = false,
  });
}
