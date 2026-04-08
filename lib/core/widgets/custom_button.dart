import 'package:flutter/material.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_gradients.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_shadows.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';

enum CustomButtonVariant { primary, secondary, outline, ghost }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isFullWidth;
  final double height;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final Gradient? gradient;
  final CustomButtonVariant variant;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isFullWidth = true,
    this.height = 56,
    this.borderRadius = 20,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.gradient,
    this.variant = CustomButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onPressed != null && !isLoading;
    final effectiveVariant = isOutlined ? CustomButtonVariant.outline : variant;
    final radiusValue = borderRadius == 20 ? AppRadii.lg : borderRadius;

    Color foreground;
    Color fillColor;
    BorderSide borderSide;
    Gradient? fillGradient;
    List<BoxShadow> shadows;

    switch (effectiveVariant) {
      case CustomButtonVariant.primary:
        foreground = textColor ?? Colors.white;
        fillColor = enabled
            ? (backgroundColor ?? AppColors.primary)
            : Colors.grey.shade300;
        borderSide = BorderSide.none;
        fillGradient = enabled ? (gradient ?? AppGradients.primary) : null;
        shadows = enabled ? AppShadows.buttonGlow() : const [];
        break;
      case CustomButtonVariant.secondary:
        foreground =
            textColor ??
            (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
        fillColor = enabled
            ? (backgroundColor ??
                  (isDark
                      ? AppColors.surfaceMutedDark
                      : AppColors.surfaceMutedLight))
            : Colors.grey.shade200;
        borderSide = BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        );
        fillGradient = gradient;
        shadows = enabled ? AppShadows.surface(isDark) : const [];
        break;
      case CustomButtonVariant.outline:
        foreground = textColor ?? AppColors.primary;
        fillColor = Colors.transparent;
        borderSide = BorderSide(
          color: (textColor ?? AppColors.primary).withValues(alpha: 0.32),
          width: 1.2,
        );
        fillGradient = null;
        shadows = const [];
        break;
      case CustomButtonVariant.ghost:
        foreground = textColor ?? AppColors.primary;
        fillColor = Colors.transparent;
        borderSide = BorderSide.none;
        fillGradient = null;
        shadows = const [];
        break;
    }

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height == 56 ? AppSpacing.buttonHeight : height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: fillGradient,
          color: fillGradient == null ? fillColor : null,
          borderRadius: BorderRadius.circular(radiusValue),
          border: Border.fromBorderSide(borderSide),
          boxShadow: shadows,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(radiusValue),
            child: Center(child: _buildChild(foreground)),
          ),
        ),
      ),
    );
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(text, style: AppTextStyles.button.copyWith(color: color)),
        ],
      );
    }

    return Text(text, style: AppTextStyles.button.copyWith(color: color));
  }
}
