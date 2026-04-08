import 'package:flutter/material.dart';

import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/widgets/app_card.dart';

Future<T?> showMethnaModalSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  List<Widget>? actions,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        MethnaModalSheet(title: title, actions: actions, child: child),
  );
}

class MethnaModalSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final List<Widget>? actions;

  const MethnaModalSheet({
    super.key,
    this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: AppCard(
        radius: AppRadii.xxl,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.handleDark : AppColors.handleLight,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
              if (title != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title!,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: titleColor),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              child,
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: actions!
                      .map((action) => Expanded(child: action))
                      .toList(growable: false),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
