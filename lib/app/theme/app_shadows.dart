import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  static List<BoxShadow> surface(bool isDark) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.045),
      blurRadius: isDark ? 18 : 14,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> floating(bool isDark) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.07),
      blurRadius: 22,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> buttonGlow([Color color = AppColors.primary]) => [
    BoxShadow(
      color: color.withValues(alpha: 0.16),
      blurRadius: 14,
      offset: const Offset(0, 7),
    ),
  ];

  static List<BoxShadow> subtleField(bool isDark, {bool focused = false}) => [
    BoxShadow(
      color: focused
          ? AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.14)
          : Colors.black.withValues(alpha: isDark ? 0.0 : 0.025),
      blurRadius: focused ? 16 : 10,
      offset: const Offset(0, 6),
    ),
  ];
}
