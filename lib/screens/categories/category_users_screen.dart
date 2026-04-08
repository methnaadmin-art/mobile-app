import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:methna_app/app/controllers/categories_controller.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/animated_empty_state.dart';
import 'package:methna_app/core/widgets/datify_shell.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CategoryUsersScreen extends StatefulWidget {
  const CategoryUsersScreen({super.key});

  @override
  State<CategoryUsersScreen> createState() => _CategoryUsersScreenState();
}

class _CategoryUsersScreenState extends State<CategoryUsersScreen> {
  late final CategoriesController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CategoriesController>();

    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['category'] != null) {
      controller.selectCategory(args['category']);
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: DatifyBackground(
        child: Obx(() {
          final category = controller.selectedCategory.value;
          if (category == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── PREMIUM SLIVER APP BAR ──
              SliverAppBar(
                expandedHeight: 156,
                pinned: true,
                backgroundColor: category.color != null
                    ? Color(
                        int.parse(category.color!.replaceFirst('#', '0xFF')),
                      )
                    : AppColors.primary,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                  child: DatifyBackButton(onTap: () => Get.back()),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    category.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: false,
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 60,
                    bottom: 14,
                  ),
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 68, 20, 54),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (category.description != null)
                          SizedBox(
                            width: Get.width * 0.7,
                            child: Text(
                              category.description!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.users,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'members_count'.trParams({
                                  'count': '${category.userCount}',
                                }),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── USERS GRID ──
              if (controller.isLoadingUsers.value &&
                  controller.categoryUsers.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (controller.categoryUsers.isEmpty)
                SliverFillRemaining(
                  child: AnimatedEmptyState(
                    lottieAsset: 'assets/animations/no_users.json',
                    title: 'no_users_in_category'.tr,
                    subtitle: 'no_users_in_category_desc'.tr,
                    fallbackIcon: LucideIcons.userX,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= controller.categoryUsers.length) {
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }
                        final user = controller.categoryUsers[index];
                        return _ProUserCard(
                          user: user,
                          isDark: isDark,
                          onTap: () => Get.toNamed(
                            AppRoutes.userDetail,
                            arguments: {'user': user},
                          ),
                        );
                      },
                      childCount:
                          controller.categoryUsers.length +
                          (controller.hasMore.value ? 1 : 0),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 50)),
            ],
          );
        }),
      ),
    );
  }
}

class _ProUserCard extends StatelessWidget {
  final UserModel user;
  final bool isDark;
  final VoidCallback onTap;

  const _ProUserCard({
    required this.user,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // PHOTO
              Hero(
                tag: 'user_${user.id}',
                child: user.mainPhotoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: user.mainPhotoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(
                          color: isDark ? AppColors.cardDark : Colors.grey[200],
                        ),
                        errorWidget: (_, _, _) => _Placeholder(user: user),
                      )
                    : _Placeholder(user: user),
              ),

              // OVERLAYS
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // TOP CHIPS
              PositionedDirectional(
                top: 10,
                start: 10,
                end: 10,
                child: Row(
                  children: [
                    if (user.selfieVerified)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.verified,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.check,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    const Spacer(),
                    if (user.profile?.country != null)
                      Text(
                        Helpers.countryToEmoji(user.profile!.country!),
                        style: const TextStyle(fontSize: 18),
                      ),
                  ],
                ),
              ),

              // BOTTOM INFO
              PositionedDirectional(
                bottom: 12,
                start: 12,
                end: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.firstName ?? user.username ?? 'User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.profile?.age != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${user.profile!.age}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.mapPin,
                          size: 10,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            user.profile?.city ?? 'Somewhere',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final UserModel user;
  const _Placeholder({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          Helpers.getInitials(user.firstName, user.lastName),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
