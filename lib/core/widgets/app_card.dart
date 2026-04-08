import 'package:flutter/material.dart';

import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_shadows.dart';
import 'package:methna_app/app/theme/app_spacing.dart';

enum AppCardVariant { surface, outlined, tinted }

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final AppCardVariant variant;
  final Color? tint;
  final VoidCallback? onTap;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.variant = AppCardVariant.surface,
    this.tint,
    this.onTap,
    this.radius = AppRadii.xl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color background;
    final BorderSide borderSide;
    final List<BoxShadow> shadows;

    switch (variant) {
      case AppCardVariant.surface:
        background = isDark
            ? AppColors.surfaceGlassDark
            : AppColors.surfaceGlassLight;
        borderSide = BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        );
        shadows = AppShadows.surface(isDark);
        break;
      case AppCardVariant.outlined:
        background = Colors.transparent;
        borderSide = BorderSide(
          color: isDark
              ? AppColors.borderDark.withValues(alpha: 0.95)
              : AppColors.borderLight,
        );
        shadows = const [];
        break;
      case AppCardVariant.tinted:
        background = (tint ?? AppColors.primary).withValues(
          alpha: isDark ? 0.16 : 0.1,
        );
        borderSide = BorderSide(
          color: (tint ?? AppColors.primary).withValues(
            alpha: isDark ? 0.3 : 0.16,
          ),
        );
        shadows = const [];
        break;
    }

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.fromBorderSide(borderSide),
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}
