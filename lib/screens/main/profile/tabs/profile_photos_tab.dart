import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:methna_app/app/controllers/profile_controller.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

/// Photos Tab with photo grid, upload, and management
class ProfilePhotosTab extends GetView<ProfileController> {
  final UserModel user;

  const ProfilePhotosTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Upload button
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(LucideIcons.plus, size: 20),
              label: Text('add_photos'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Photos grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: 6, // Max 6 photos
              itemBuilder: (context, index) {
                return _PhotoSlot(
                  index: index,
                  user: user,
                  cardBg: cardBg,
                  borderColor: borderColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    // Navigate to the comprehensive photo editing screen
    Get.toNamed(AppRoutes.editProfilePhotos);
  }
}

class _PhotoSlot extends StatelessWidget {
  final int index;
  final UserModel user;
  final Color cardBg;
  final Color borderColor;

  const _PhotoSlot({
    required this.index,
    required this.user,
    required this.cardBg,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final photos =
        user.photos
            ?.map((photo) => photo.url)
            .where((url) => url.trim().isNotEmpty)
            .toList() ??
        const <String>[];
    final photoPool = photos.isNotEmpty
        ? photos
        : (user.mainPhotoUrl?.isNotEmpty == true ? [user.mainPhotoUrl!] : []);
    final photoUrl = index < photoPool.length ? photoPool[index] : null;
    final hasPhoto = photoUrl != null;

    return GestureDetector(
      onTap: () {
        // Always navigate to edit screen for better UX
        Get.toNamed(AppRoutes.editProfilePhotos);
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: hasPhoto
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _LoadingPlaceholder(),
                      errorWidget: (context, url, error) => _ErrorPlaceholder(),
                    ),
                    // Verified badge for main photo
                    if (index == 0 && user.selfieVerified)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.verified,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : _EmptySlot(index: index),
      ),
    );
  }

  // ignore: unused_element
  void _showPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'photo_options'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(LucideIcons.eye),
              title: Text('view_fullscreen'.tr),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(AppRoutes.editProfilePhotos);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.star),
              title: Text('set_as_main_photo'.tr),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(AppRoutes.editProfilePhotos);
              },
            ),
            if (index > 0)
              ListTile(
                leading: const Icon(
                  LucideIcons.trash2,
                  color: AppColors.primaryDark,
                ),
                title: Text(
                  'delete_photo'.tr,
                  style: const TextStyle(color: AppColors.primaryDark),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_photo'.tr),
        content: Text('delete_photo_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Get.toNamed(AppRoutes.editProfilePhotos);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
            ),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final int index;

  const _EmptySlot({required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHintLight;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          index == 0 ? LucideIcons.camera : LucideIcons.plus,
          size: 32,
          color: hintColor.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 8),
        Text(
          index == 0 ? 'main'.tr : 'add'.tr,
          style: TextStyle(
            fontSize: 12,
            color: hintColor.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.withValues(alpha: 0.2),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          LucideIcons.imageOff,
          size: 32,
          color: Colors.grey.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
