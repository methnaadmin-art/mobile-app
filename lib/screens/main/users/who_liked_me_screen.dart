import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:methna_app/app/controllers/home_controller.dart';
import 'package:methna_app/app/controllers/users_controller.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/data/models/who_liked_me_item_model.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/utils/cloudinary_url.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/app_card.dart';
import 'package:methna_app/core/widgets/animated_empty_state.dart';
import 'package:methna_app/core/widgets/custom_button.dart';
import 'package:methna_app/core/widgets/datify_shell.dart';
import 'package:methna_app/core/widgets/discovery_flow.dart';

class WhoLikedMeScreen extends GetView<UsersController> {
  const WhoLikedMeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: DatifyBackground(
        compact: true,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                child: Row(
                  children: [
                    DiscoveryIconButton(
                      icon: LucideIcons.chevronLeft,
                      onTap: () => Get.back(),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Obx(
                        () => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WHO LIKED ME',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.gold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              controller.whoLikedMeCount.value == 1
                                  ? '1 person likes you'
                                  : '${controller.whoLikedMeCount.value} people like you',
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Obx(
                      () => DiscoveryInfoPill(
                        icon: LucideIcons.heart,
                        label: '${controller.whoLikedMeCount.value}',
                        color: AppColors.like,
                        filled: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: controller.refreshWhoLikedMe,
                  child: Obx(() {
                    if (controller.isLoadingWhoLikedMe.value &&
                        controller.likesReceived.isEmpty &&
                        controller.whoLikedMeCount.value == 0) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    if (controller.whoLikedMeRequiresPremium.value &&
                        controller.whoLikedMeCount.value > 0 &&
                        controller.likesReceived.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        children: [
                          _PremiumLockCard(
                            count: controller.whoLikedMeCount.value,
                          ),
                        ],
                      );
                    }

                    // Non-premium with blurred teaser cards
                    final hasBlurredItems = controller.likesReceived.any(
                      (item) => item.isBlurred,
                    );
                    if (hasBlurredItems) {
                      return ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        itemCount: controller.likesReceived.length + 1,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _PremiumLockCard(
                              count: controller.whoLikedMeCount.value,
                            );
                          }
                          final item = controller.likesReceived[index - 1];
                          return _WhoLikedMeCard(
                            item: item,
                            onTap: () => Get.toNamed(AppRoutes.subscription),
                          );
                        },
                      );
                    }

                    if (controller.likesReceived.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xl,
                        ),
                        children: [
                          AnimatedEmptyState(
                            lottieAsset: 'assets/animations/no_matches.json',
                            title: 'No likes yet',
                            subtitle:
                                'When someone likes your profile, they will appear here.',
                            fallbackIcon: LucideIcons.heartOff,
                            fallbackColor: AppColors.like,
                            primaryActionLabel: 'refresh'.tr,
                            onPrimaryAction: controller.refreshWhoLikedMe,
                            width: 190,
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      itemCount: controller.likesReceived.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final item = controller.likesReceived[index];
                        return _WhoLikedMeCard(
                          item: item,
                          onTap: () {
                            if (item.isBlurred ||
                                controller.isLockedLikedMePlaceholder(
                                  item.user.id,
                                )) {
                              Get.toNamed(AppRoutes.subscription);
                              return;
                            }
                            controller.openUserDetailById(
                              item.user.id,
                              sourceTab: 'liked_me',
                            );
                          },
                        );
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhoLikedMeCard extends StatelessWidget {
  final WhoLikedMeItem item;
  final VoidCallback onTap;

  const _WhoLikedMeCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (item.isBlurred) {
      return _buildBlurredCard(context, isDark);
    }

    final title = item.user.publicDisplayName.trim().isNotEmpty
        ? item.user.publicDisplayName
        : item.user.fullName.trim().isNotEmpty
        ? item.user.fullName
        : 'A member';

    return AppCard(
      onTap: onTap,
      radius: AppRadii.xl,
      child: Row(
        children: [
          _Avatar(user: item.user),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      Helpers.timeAgo(item.createdAt),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.textHintDark
                            : AppColors.textHintLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  item.complimentMessage ?? _typeDescription(item.type),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DiscoveryInfoPill(
                  icon: _typeIcon(item.type),
                  label: _typeLabel(item.type),
                  color: _typeColor(item.type),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionCircle(
                icon: LucideIcons.award,
                color: const Color(0xFF2D95FF),
                onTap: () => _handleComplimentTap(context),
              ),
              const SizedBox(height: AppSpacing.xs),
              _ActionCircle(
                icon: LucideIcons.heart,
                color: AppColors.like,
                onTap: () {
                  final controller = Get.find<UsersController>();
                  controller.likeUser(item.user.id);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleComplimentTap(BuildContext context) async {
    final usersController = Get.find<UsersController>();
    if (item.isBlurred || usersController.isLockedLikedMePlaceholder(item.user.id)) {
      Get.toNamed(AppRoutes.subscription);
      return;
    }

    final homeController = Get.find<HomeController>();
    if (!homeController.hasPaidPremiumPlan) {
      Get.toNamed(AppRoutes.subscription);
      return;
    }

    final textController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await Get.dialog<void>(
      AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        title: Text(
          'send_compliment'.tr,
          style: AppTextStyles.titleLarge.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: textController,
          maxLines: 3,
          maxLength: 200,
          autofocus: true,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: 'write_something_nice'.tr,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.textHintDark
                  : AppColors.textHintLight,
            ),
            filled: true,
            fillColor: isDark ? AppColors.cardDark : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () async {
              final message = textController.text.trim();
              if (message.isEmpty) return;
              final success = await homeController.complimentUser(
                item.user.id,
                message,
                fallbackUser: item.user,
              );
              if (success && (Get.isDialogOpen ?? false)) {
                Get.back();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('send'.tr),
          ),
        ],
      ),
    ).whenComplete(textController.dispose);
  }

  Widget _buildBlurredCard(BuildContext context, bool isDark) {
    return AppCard(
      onTap: onTap,
      radius: AppRadii.xl,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: Row(
          children: [
            // Blurred avatar placeholder
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: AppColors.primarySurface,
                    alignment: Alignment.center,
                    child: Icon(
                      LucideIcons.user,
                      color: AppColors.primary.withValues(alpha: 0.5),
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Someone likes you',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        Helpers.timeAgo(item.createdAt),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.textHintDark
                              : AppColors.textHintLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Upgrade to reveal their profile',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      DiscoveryInfoPill(
                        icon: _typeIcon(item.type),
                        label: _typeLabel(item.type),
                        color: _typeColor(item.type),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const DiscoveryInfoPill(
                        icon: LucideIcons.lock,
                        label: 'Premium',
                        color: AppColors.gold,
                        filled: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(LucideIcons.crown, color: AppColors.gold, size: 20),
          ],
        ),
      ),
    );
  }
}

class _PremiumLockCard extends StatelessWidget {
  final int count;

  const _PremiumLockCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: AppRadii.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DiscoveryInfoPill(
            icon: LucideIcons.sparkles,
            label: 'Premium feature',
            color: AppColors.gold,
            filled: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            count == 1
                ? '1 person already likes you'
                : '$count people already like you',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Upgrade to see who liked your profile and open the conversation with full context.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomButton(
            text: 'See premium plans',
            icon: LucideIcons.crown,
            onPressed: () => Get.toNamed(AppRoutes.subscription),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final UserModel user;

  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final initials = Helpers.getInitials(user.firstName, user.lastName);

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: user.mainPhotoUrl != null
            ? CachedNetworkImage(
                imageUrl: CloudinaryUrl.medium(user.mainPhotoUrl),
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _AvatarFallback(initials: initials),
              )
            : _AvatarFallback(initials: initials),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initials;

  const _AvatarFallback({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primarySurface,
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? 'M' : initials,
        style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
      ),
    );
  }
}

String _typeDescription(String rawType) {
  switch (rawType.toLowerCase()) {
    case 'super_like':
      return 'This member liked your profile.';
    case 'compliment':
      return 'This member sent a compliment with their like.';
    case 'like':
    default:
      return 'This member liked your profile.';
  }
}

String _typeLabel(String rawType) {
  switch (rawType.toLowerCase()) {
    case 'super_like':
      return 'Like';
    case 'compliment':
      return 'Compliment';
    case 'like':
    default:
      return 'Like';
  }
}

IconData _typeIcon(String rawType) {
  switch (rawType.toLowerCase()) {
    case 'super_like':
      return LucideIcons.heart;
    case 'compliment':
      return LucideIcons.sparkles;
    case 'like':
    default:
      return LucideIcons.heart;
  }
}

Color _typeColor(String rawType) {
  switch (rawType.toLowerCase()) {
    case 'super_like':
      return AppColors.like;
    case 'compliment':
      return AppColors.primary;
    case 'like':
    default:
      return AppColors.like;
  }
}

class _ActionCircle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCircle({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
