import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premium = LinearGradient(
    colors: [AppColors.primary, AppColors.like],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pageLight = LinearGradient(
    colors: [AppColors.canvasLight, AppColors.primarySurface],
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
