import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_gradients.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/utils/cloudinary_url.dart';
import 'package:methna_app/core/widgets/app_card.dart';

class ChatAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallback;
  final double size;
  final bool online;
  final List<Color>? gradientColors;
  final bool showGradientRing;
  final Color? borderColor;
  final double borderWidth;

  const ChatAvatar({
    super.key,
    this.imageUrl,
    required this.fallback,
    this.size = 60,
    this.online = false,
    this.gradientColors,
    this.showGradientRing = true,
    this.borderColor,
    this.borderWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    final outerInset = showGradientRing
        ? 2.0
        : borderColor != null
        ? borderWidth
        : 0.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(outerInset),
            decoration: BoxDecoration(
              gradient: showGradientRing
                  ? (gradientColors == null
                        ? AppGradients.primary
                        : LinearGradient(colors: gradientColors!))
                  : null,
              color: showGradientRing ? null : borderColor,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: ClipOval(
                child: imageUrl != null && imageUrl!.trim().isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: CloudinaryUrl.medium(imageUrl),
                        fit: BoxFit.cover,
                        width: size,
                        height: size,
                      )
                    : Container(
                        width: size,
                        height: size,
                        color: AppColors.primary.withValues(alpha: 0.1),
                        alignment: Alignment.center,
                        child: Text(
                          fallback,
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          if (online)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.online,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ChatConversationCard extends StatelessWidget {
  final Widget avatar;
  final String title;
  final String subtitle;
  final String? meta;
  final Widget? badge;
  final VoidCallback? onTap;
  final bool highlighted;

  const ChatConversationCard({
    super.key,
    required this.avatar,
    required this.title,
    required this.subtitle,
    this.meta,
    this.badge,
    this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return AppCard(
      onTap: onTap,
      radius: AppRadii.hero,
      variant: highlighted ? AppCardVariant.tinted : AppCardVariant.surface,
      tint: AppColors.primary,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatar,
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headlineSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(color: subtitleColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (meta != null && meta!.trim().isNotEmpty)
                Text(
                  meta!,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: subtitleColor,
                  ),
                ),
              if (badge != null) ...[
                const SizedBox(height: AppSpacing.sm),
                badge!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class ChatDateBadge extends StatelessWidget {
  final String label;

  const ChatDateBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceMutedDark
            : AppColors.surfaceMutedLight,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Text(label, style: AppTextStyles.labelSmall),
    );
  }
}

class ChatUnreadBadge extends StatelessWidget {
  final String label;

  const ChatUnreadBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
      ),
    );
  }
}

class ChatComposerCard extends StatelessWidget {
  final Widget child;

  const ChatComposerCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AppCard(radius: AppRadii.hero, child: child);
  }
}

class ChatMediaView extends StatelessWidget {
  final dynamic item;

  const ChatMediaView({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    if (item is File) {
      return Image.file(item as File, fit: BoxFit.cover);
    }

    if (item is String && (item as String).trim().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: CloudinaryUrl.large(item as String),
        fit: BoxFit.cover,
      );
    }

    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.primary),
    );
  }
}
