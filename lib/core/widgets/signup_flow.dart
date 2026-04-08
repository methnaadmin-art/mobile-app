import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_gradients.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_shadows.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/widgets/app_card.dart';
import 'package:methna_app/core/widgets/auth_flow.dart';
import 'package:methna_app/core/widgets/custom_button.dart';

class SignupStepScaffold extends StatelessWidget {
  final VoidCallback onBack;
  final double progress;
  final Widget child;
  final Widget? footer;
  final bool compact;
  final EdgeInsetsGeometry padding;

  const SignupStepScaffold({
    super.key,
    required this.onBack,
    required this.progress,
    required this.child,
    this.footer,
    this.compact = false,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.xl,
      AppSpacing.xl,
      AppSpacing.xl,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      compact: compact,
      child: Column(
        children: [
          AuthHeader(onBack: onBack, progress: progress),
          Expanded(
            child: SingleChildScrollView(padding: padding, child: child),
          ),
          if (footer != null) AuthBottomBar(child: footer!),
        ],
      ),
    );
  }
}

class SignupHeroCard extends StatelessWidget {
  final String title;
  final String description;
  final String? badge;
  final IconData? icon;
  final Widget? preview;
  final List<Color>? colors;

  const SignupHeroCard({
    super.key,
    required this.title,
    required this.description,
    this.badge,
    this.icon,
    this.preview,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final subtitleColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (badge != null || icon != null)
          Row(
            children: [
              if (badge != null)
                SignupInfoPill(icon: LucideIcons.badgeCheck, label: badge!),
              if (icon != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(icon, color: AppColors.primary, size: 18),
              ],
            ],
          ),
        if (badge != null || icon != null)
          const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          description,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: subtitleColor, height: 1.5),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (preview != null) ...[
          const SizedBox(height: AppSpacing.lg),
          preview!,
        ],
      ],
    );
  }
}

class SignupChoiceTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool selected;
  final VoidCallback? onTap;

  const SignupChoiceTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final background = selected
        ? null
        : (isDark ? AppColors.surfaceGlassDark : AppColors.surfaceGlassLight);
    final titleColor = selected
        ? Colors.white
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
    final subtitleColor = selected
        ? Colors.white.withValues(alpha: 0.72)
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: selected ? AppGradients.primary : null,
            color: background,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            boxShadow: selected
                ? AppShadows.buttonGlow()
                : AppShadows.surface(isDark),
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
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                        height: isRtl ? 1.35 : 1.22,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: subtitleColor,
                          height: isRtl ? 1.45 : 1.32,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? Colors.white
                        : (isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight),
                    width: 1.4,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 17,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignupSectionLabel extends StatelessWidget {
  final String text;

  const SignupSectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        letterSpacing: isRtl ? 0 : 1,
        fontWeight: FontWeight.w800,
        height: isRtl ? 1.3 : 1.2,
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
      ),
    );
  }
}

class SignupInfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? tint;

  const SignupInfoPill({
    super.key,
    required this.icon,
    required this.label,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final color = tint ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SignupOptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool translateLabel;

  const SignupOptionChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
    this.translateLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = selected
        ? Colors.white
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: selected ? AppGradients.primary : null,
            color: selected
                ? null
                : (isDark
                      ? AppColors.surfaceMutedDark
                      : AppColors.surfaceMutedLight),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            boxShadow: selected
                ? AppShadows.buttonGlow()
                : AppShadows.surface(isDark),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: foreground),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                translateLabel ? label.tr : label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignupPickerTile extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final IconData icon;
  final VoidCallback onTap;
  final bool translateValue;

  const SignupPickerTile({
    super.key,
    required this.label,
    required this.placeholder,
    required this.icon,
    required this.onTap,
    this.value,
    this.translateValue = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = value != null && value!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SignupSectionLabel(text: label),
        const SizedBox(height: AppSpacing.md),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark.withValues(alpha: 0.72)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                boxShadow: AppShadows.surface(isDark),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      hasValue
                          ? (translateValue ? value!.tr : value!)
                          : placeholder,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: hasValue
                            ? (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight)
                            : (isDark
                                  ? AppColors.textHintDark
                                  : AppColors.textHintLight),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isDark
                        ? AppColors.textHintDark
                        : AppColors.textHintLight,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SignupInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final String? label;
  final IconData? icon;
  final Widget? suffix;
  final int maxLines;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;

  const SignupInputField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.icon,
    this.suffix,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<SignupInputField> createState() => _SignupInputFieldState();
}

class _SignupInputFieldState extends State<SignupInputField> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  String _compactHint(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return value;
    return trimmed.split(RegExp(r'\s+')).first;
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!mounted) return;
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintText = _compactHint(widget.hint);
    final borderColor = _isFocused
        ? AppColors.primary
        : (isDark ? AppColors.borderDark : AppColors.borderLight);
    final iconColor = _isFocused
        ? AppColors.primary
        : (isDark ? AppColors.textHintDark : AppColors.textHintLight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          SignupSectionLabel(text: widget.label!),
          const SizedBox(height: AppSpacing.md),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withValues(alpha: 0.72)
                : Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: borderColor, width: _isFocused ? 1.4 : 1),
            boxShadow: AppShadows.surface(isDark),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            maxLines: widget.maxLines,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? AppColors.textHintDark
                    : AppColors.textHintLight,
              ),
              prefixIcon: widget.icon == null
                  ? null
                  : Align(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 14),
                        child: Icon(widget.icon, size: 16, color: iconColor),
                      ),
                    ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 42,
                maxWidth: 42,
                minHeight: 20,
              ),
              suffixIcon: widget.suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SignupFooterActions extends StatelessWidget {
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool isLoading;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Widget? helper;

  const SignupFooterActions({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.isLoading = false,
    this.secondaryLabel,
    this.onSecondary,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final hasSecondary = secondaryLabel != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!hasSecondary)
          CustomButton(
            text: primaryLabel,
            onPressed: onPrimary,
            isLoading: isLoading,
          )
        else
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: secondaryLabel!,
                  onPressed: onSecondary,
                  variant: CustomButtonVariant.secondary,
                  height: 50,
                  borderRadius: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: CustomButton(
                  text: primaryLabel,
                  onPressed: onPrimary,
                  isLoading: isLoading,
                  height: 50,
                  borderRadius: 16,
                ),
              ),
            ],
          ),
        if (helper != null) ...[const SizedBox(height: AppSpacing.sm), helper!],
      ],
    );
  }
}

class SignupSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SignupSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(padding: padding, radius: AppRadii.xxl, child: child);
  }
}
