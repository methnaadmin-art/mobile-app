import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppGradients {
  AppGradients._();

  static const LinearGradient primary = AppColors.primaryGradient;
  static const LinearGradient premium = AppColors.primaryGradient;

  static const LinearGradient pageLight = LinearGradient(
    colors: [AppColors.backgroundLight, AppColors.surfaceLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient pageDark = LinearGradient(
    colors: [AppColors.canvasDark, AppColors.surfaceDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static RadialGradient glow(Color color) =>
      RadialGradient(colors: [color, color.withValues(alpha: 0)]);
}
