import 'package:flutter/material.dart';

import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/widgets/datify_shell.dart';

class MethnaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget? leading;
  final Widget? badge;
  final bool centerTitle;

  const MethnaAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions = const [],
    this.leading,
    this.badge,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            leading ??
                (onBack != null
                    ? DatifyBackButton(onTap: onBack!)
                    : const SizedBox(width: 44, height: 44)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: centerTitle
                  ? Center(
                      child: _TitleText(
                        title: title,
                        badge: badge,
                        color: titleColor,
                      ),
                    )
                  : _TitleText(title: title, badge: badge, color: titleColor),
            ),
            ...actions,
            if (actions.isEmpty) const SizedBox(width: 44, height: 44),
          ],
        ),
      ),
    );
  }
}

class _TitleText extends StatelessWidget {
  final String title;
  final Widget? badge;
  final Color color;

  const _TitleText({
    required this.title,
    required this.badge,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: color),
          ),
        ),
        if (badge != null) ...[const SizedBox(width: AppSpacing.sm), badge!],
      ],
    );
  }
}
