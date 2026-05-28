import 'package:flutter/material.dart';

import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_gradients.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_shadows.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/widgets/app_card.dart';
import 'package:methna_app/core/widgets/custom_button.dart';
import 'package:methna_app/core/widgets/datify_shell.dart';

class AuthPageScaffold extends StatelessWidget {
  final Widget child;
  final bool compact;
  final Color? backgroundColor;

  const AuthPageScaffold({
    super.key,
    required this.child,
    this.compact = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: backgroundColor ??
          (isDark ? AppColors.canvasDark : Colors.white),
      body: DatifyBackground(
        compact: compact,
        child: SafeArea(child: child),
      ),
    );
  }
}

class AuthHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final double? progress;
  final Widget? trailing;

  const AuthHeader({
    super.key,
    this.onBack,
    this.progress,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        0,
      ),
      child: Row(
        children: [
          if (onBack != null) DatifyBackButton(onTap: onBack!),
          if (onBack != null && progress != null) const SizedBox(width: AppSpacing.md),
          if (progress != null)
            Expanded(
              child: DatifyProgressBar(progress: progress!),
            ),
          if (progress == null) const Spacer(),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class AuthTitleBlock extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? badge;
  final TextAlign textAlign;

  const AuthTitleBlock({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      crossAxisAlignment:
          textAlign == TextAlign.center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (badge != null) ...[
          DatifyHeaderBadge(text: badge!),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(
          title,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: titleColor,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            textAlign: textAlign,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: subtitleColor,
                ),
          ),
        ],
      ],
    );
  }
}

class AuthHeroPanel extends StatelessWidget {
  final Widget child;
  final List<Color>? gradientColors;
  final EdgeInsetsGeometry padding;
  final double radius;

  const AuthHeroPanel({
    super.key,
    required this.child,
    this.gradientColors,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.radius = AppRadii.hero,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? const [AppColors.primary, AppColors.primaryLight];

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.buttonGlow(colors.first),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -28,
            child: _GlowDisc(
              size: 132,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            left: -32,
            bottom: -44,
            child: _GlowDisc(
              size: 148,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class AuthSurfacePanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AuthSurfacePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      radius: AppRadii.xxl,
      child: child,
    );
  }
}

class AuthBottomBar extends StatelessWidget {
  final Widget child;

  const AuthBottomBar({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        bottomInset > 0 ? bottomInset + AppSpacing.md : AppSpacing.xl,
      ),
      child: child,
    );
  }
}

class AuthSocialButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuthSocialButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: label,
      variant: CustomButtonVariant.secondary,
      onPressed: isLoading ? null : onPressed,
      isLoading: isLoading,
      icon: null,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceMutedDark
          : AppColors.surfaceMutedLight,
    );
  }
}

class AuthOrDivider extends StatelessWidget {
  final String text;

  const AuthOrDivider({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Row(
      children: [
        Expanded(child: Divider(color: dividerColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                ),
          ),
        ),
        Expanded(child: Divider(color: dividerColor, thickness: 1)),
      ],
    );
  }
}

class AuthPrimaryButtonBar extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuthPrimaryButtonBar({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: label,
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }
}

class _GlowDisc extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowDisc({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppGradients.glow(color),
        ),
      ),
    );
  }
}
