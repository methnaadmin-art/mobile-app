import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radii.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';

class AppDecorations {
  AppDecorations._();

  // Card Decorations
  static BoxDecoration cardLight = BoxDecoration(
    color: AppColors.surfaceGlassLight,
    borderRadius: BorderRadius.circular(AppRadii.xl),
    boxShadow: AppShadows.surface(false),
  );

  static BoxDecoration cardDark = BoxDecoration(
    color: AppColors.surfaceGlassDark,
    borderRadius: BorderRadius.circular(AppRadii.xl),
    boxShadow: AppShadows.surface(true),
  );

  // Gradient Card (Gold)
  static BoxDecoration gradientCard = BoxDecoration(
    gradient: AppColors.goldGradient,
    borderRadius: BorderRadius.circular(AppRadii.xl),
    boxShadow: AppShadows.buttonGlow(),
  );

  // Gold Button Decoration
  static BoxDecoration goldButton = BoxDecoration(
    gradient: AppColors.goldButtonGradient,
    borderRadius: BorderRadius.circular(AppRadii.lg),
    boxShadow: AppShadows.buttonGlow(),
  );

  // Input Decoration
  static InputDecoration inputDecoration({
    required String hint,
    IconData? prefixIcon,
    Widget? suffix,
    bool isDark = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
        fontSize: 14,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              size: 20,
              color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
            )
          : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: isDark
          ? AppColors.surfaceMutedDark
          : AppColors.surfaceMutedLight,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  // Bottom Sheet
  static BoxDecoration bottomSheet(bool isDark) => BoxDecoration(
    color: isDark ? AppColors.surfaceGlassDark : AppColors.surfaceGlassLight,
    borderRadius: const BorderRadius.vertical(
      top: Radius.circular(AppRadii.xxl),
    ),
    boxShadow: AppShadows.surface(isDark),
  );

  // Avatar Decoration (Gold ring)
  static BoxDecoration avatarBorder({Color color = AppColors.primary}) =>
      BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.5),
      );

  // Online Indicator
  static BoxDecoration onlineIndicator = BoxDecoration(
    color: AppColors.online,
    shape: BoxShape.circle,
    border: Border.all(color: Colors.white, width: 2),
  );
}
