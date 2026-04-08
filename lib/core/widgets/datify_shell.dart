import 'package:flutter/material.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_gradients.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_shadows.dart';
import 'package:methna_app/app/theme/app_spacing.dart';

class DatifyBackground extends StatelessWidget {
  final Widget child;
  final bool compact;

  const DatifyBackground({
    super.key,
    required this.child,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppGradients.pageDark : AppGradients.pageLight,
      ),
      child: Stack(
        children: [
          Positioned(
            top: compact ? -80 : -120,
            right: compact ? -60 : -90,
            child: _GlowOrb(
              size: compact ? 180 : 240,
              color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.14),
            ),
          ),
          Positioned(
            top: compact ? 90 : 130,
            left: compact ? -55 : -70,
            child: _GlowOrb(
              size: compact ? 140 : 180,
              color: AppColors.like.withValues(alpha: isDark ? 0.09 : 0.1),
            ),
          ),
          Positioned(
            bottom: compact ? -70 : -90,
            left: compact ? 30 : 50,
            child: _GlowOrb(
              size: compact ? 170 : 220,
              color: AppColors.primaryLight.withValues(
                alpha: isDark ? 0.1 : 0.08,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class DatifyBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const DatifyBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceGlassDark
              : AppColors.surfaceGlassLight,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: AppShadows.surface(isDark),
        ),
        child: Icon(
          Icons.chevron_left_rounded,
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
          size: 24,
        ),
      ),
    );
  }
}

class DatifyProgressBar extends StatelessWidget {
  final double progress;

  const DatifyProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              boxShadow: AppShadows.buttonGlow(),
            ),
          ),
        ),
      ),
    );
  }
}

class DatifySurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  const DatifySurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = AppRadii.xl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceGlassDark
            : AppColors.surfaceGlassLight,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: AppShadows.surface(isDark),
      ),
      child: child,
    );
  }
}

class DatifyHeaderBadge extends StatelessWidget {
  final String text;

  const DatifyHeaderBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

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
