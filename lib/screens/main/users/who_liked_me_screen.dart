import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
                          onTap: () =>
                              controller.openUserDetailById(item.user.id),
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
    final title = item.user.displayName.trim().isNotEmpty
        ? item.user.displayName
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
          const SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
          ),
        ],
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
                imageUrl: CloudinaryUrl.thumbnail(user.mainPhotoUrl),
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
