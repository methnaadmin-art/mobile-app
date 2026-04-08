import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/app_card.dart';
import 'package:methna_app/core/widgets/custom_button.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class BlockedUsersScreen extends GetView<SettingsController> {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SettingsSimplePageScaffold(
        title: '${'blocked_users'.tr} (${controller.blockedUsers.length})',
        body: () {
          if (controller.isLoadingBlocked.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (controller.blockedUsers.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: [
                AppCard(
                  radius: 22,
                  child: Text(
                    'blocked_users_empty'.tr,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.72,
            ),
            itemCount: controller.blockedUsers.length,
            itemBuilder: (context, index) {
              final user = controller.blockedUsers[index];
              return _BlockedUserTile(
                user: user,
                onUnblock: () => _confirmUnblock(context, user),
              );
            },
          );
        }(),
      ),
    );
  }

  void _confirmUnblock(BuildContext context, UserModel user) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: AppCard(
          radius: 22,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('unblock_user'.tr, style: Get.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${'unblock_confirm'.tr} ${user.firstName ?? user.username ?? 'this user'}?',
                textAlign: TextAlign.center,
                style: Get.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'cancel'.tr,
                      variant: CustomButtonVariant.outline,
                      onPressed: () => Get.back(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: CustomButton(
                      text: 'unblock'.tr,
                      onPressed: () {
                        Get.back();
                        controller.unblockUser(user.id);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onUnblock;

  const _BlockedUserTile({required this.user, required this.onUnblock});

  @override
  Widget build(BuildContext context) {
    final photo = user.mainPhotoUrl;
    final name = user.firstName?.trim().isNotEmpty == true
        ? user.firstName!
        : (user.username ?? 'User');
    final age = user.profile?.age != null ? ' (${user.profile!.age})' : '';

    return GestureDetector(
      onTap: onUnblock,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photo != null && photo.isNotEmpty)
              Image.network(
                photo,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _FallbackAvatar(name: name),
              )
            else
              _FallbackAvatar(name: name),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.02),
                    Colors.black.withValues(alpha: 0.14),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$name$age',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'tap_to_unblock'.tr,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  final String name;

  const _FallbackAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        Helpers.getInitials(name, ''),
        style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary),
      ),
    );
  }
}
