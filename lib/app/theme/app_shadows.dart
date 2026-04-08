import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  static List<BoxShadow> surface(bool isDark) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
      blurRadius: isDark ? 26 : 22,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> floating(bool isDark) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
      blurRadius: 30,
      offset: const Offset(0, 16),
    ),
  ];

  static List<BoxShadow> buttonGlow([Color color = AppColors.primary]) => [
    BoxShadow(
      color: color.withValues(alpha: 0.24),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> subtleField(bool isDark, {bool focused = false}) => [
    BoxShadow(
      color: focused
          ? AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.18)
          : Colors.black.withValues(alpha: isDark ? 0.0 : 0.04),
      blurRadius: focused ? 24 : 14,
      offset: const Offset(0, 8),
    ),
  ];
}
