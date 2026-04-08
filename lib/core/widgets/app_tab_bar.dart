import 'package:flutter/material.dart';

import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';

class MethnaTabBar extends StatelessWidget {
  final TabController? controller;
  final List<Tab> tabs;
  final bool isScrollable;

  const MethnaTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: isDark ? AppColors.chipDark : AppColors.chipLight,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: isScrollable,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
        labelStyle: Theme.of(context).textTheme.titleSmall,
        tabs: tabs,
      ),
    );
  }
}
