import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/signup_flow.dart';
import 'package:permission_handler/permission_handler.dart';

class AddPhotosScreen extends StatefulWidget {
  const AddPhotosScreen({super.key});

  @override
  State<AddPhotosScreen> createState() => _AddPhotosScreenState();
}

class _AddPhotosScreenState extends State<AddPhotosScreen> {
  final controller = Get.find<SignupController>();
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    controller.syncStep(AppRoutes.signupPhotos);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() => _isReady = true);
      }
    });
  }

  Future<bool> _ensureMediaPermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isGranted) return true;
      Helpers.showSnackbar(
        message: 'Camera permission is required to take a photo.',
        isError: true,
      );
      if (status.isPermanentlyDenied || status.isRestricted) {
        await openAppSettings();
      }
      return false;
    }

    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) return true;
      Helpers.showSnackbar(
        message: 'Photo library permission is required to choose images.',
        isError: true,
      );
      if (status.isPermanentlyDenied || status.isRestricted) {
        await openAppSettings();
      }
      return false;
    }

    if (Platform.isAndroid) {
      final photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted || photosStatus.isLimited) return true;

      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) return true;

      Helpers.showSnackbar(
        message: 'Media permission is required to choose images.',
        isError: true,
      );
      if (photosStatus.isPermanentlyDenied ||
          storageStatus.isPermanentlyDenied) {
        await openAppSettings();
      }
      return false;
    }

    return true;
  }

  Future<void> _pickImage(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final source = await Get.bottomSheet<ImageSource>(
      SignupSurfaceCard(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'choose_source'.tr,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            _SourceTile(
              icon: LucideIcons.camera,
              title: 'camera'.tr,
              onTap: () => Get.back(result: ImageSource.camera),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SourceTile(
              icon: LucideIcons.image,
              title: 'gallery'.tr,
              onTap: () => Get.back(result: ImageSource.gallery),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );

    if (source == null) {
      return;
    }

    if (!await _ensureMediaPermission(source)) {
      return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 72,
      );

      if (picked != null) {
        controller.addPhoto(File(picked.path));
      }
    } catch (error) {
      debugPrint('[AddPhotos] Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SignupStepScaffold(
      onBack: controller.goBack,
      progress: controller.progressPercent,
      footer: Obx(() {
        final hasEnoughPhotos = controller.selectedPhotos.length >= 2;
        final busy =
            controller.isNavigatingStep.value ||
            controller.isLoading.value ||
            controller.isProcessing.value;
        return SignupFooterActions(
          primaryLabel: 'continue_text'.tr,
          onPrimary: hasEnoughPhotos && !busy ? controller.goToNextStep : null,
          isLoading: busy,
          helper: hasEnoughPhotos
              ? null
              : Text(
                  'min_photos_hint'.trParams({'count': '2'}),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
        );
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SignupHeroCard(
            badge: '10 / 12',
            icon: LucideIcons.image,
            title: 'add_photos'.tr,
            description:
                'add_photos_desc'.tr,
            preview: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                SignupInfoPill(icon: LucideIcons.star, label: '2_minimum'.tr),
                SignupInfoPill(icon: LucideIcons.imagePlus, label: '6_maximum'.tr),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          !_isReady
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.section),
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                )
              : Obx(
                  () => Column(
                    children: [
                      _buildMainPhoto(),
                      const SizedBox(height: AppSpacing.md),
                      _buildPhotoGrid(),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildMainPhoto() {
    final hasMain = controller.selectedPhotos.isNotEmpty;
    final isMain = controller.mainPhotoIndex.value == 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: hasMain
          ? () => controller.setMainPhoto(0)
          : () => _pickImage(context),
      borderRadius: BorderRadius.circular(AppRadii.xxl),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 272,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceMutedDark
              : AppColors.surfaceMutedLight,
          borderRadius: BorderRadius.circular(AppRadii.xxl),
          border: Border.all(
            color: hasMain && isMain
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: hasMain && isMain ? 2 : 1.2,
          ),
        ),
        child: hasMain
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.xxl - 2),
                    child: Image.file(
                      controller.selectedPhotos[0],
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: SignupInfoPill(
                      icon: LucideIcons.sparkles,
                      label: isMain ? 'main_photo'.tr : 'tap_to_make_primary'.tr,
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.md,
                    right: AppSpacing.md,
                    child: _DeletePhotoButton(
                      onTap: () => controller.removePhoto(0),
                    ),
                  ),
                ],
              )
            : _EmptyPhotoState(onTap: () => _pickImage(context)),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildPhotoSlot(1)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildPhotoSlot(2)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _buildPhotoSlot(3)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildPhotoSlot(4)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildPhotoSlot(5)),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoSlot(int index) {
    final hasPhoto = index < controller.selectedPhotos.length;
    final isMain = controller.mainPhotoIndex.value == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AspectRatio(
      aspectRatio: 0.78,
      child: InkWell(
        onTap: hasPhoto
            ? () => controller.setMainPhoto(index)
            : () => _pickImage(context),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceMutedDark
                : AppColors.surfaceMutedLight,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hasPhoto && isMain
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: hasPhoto && isMain ? 2 : 1.2,
            ),
          ),
          child: hasPhoto
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.file(
                        controller.selectedPhotos[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (isMain)
                      Positioned(
                        left: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                        child: SignupInfoPill(
                          icon: LucideIcons.star,
                          label: 'main'.tr,
                        ),
                      ),
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: _DeletePhotoButton(
                        onTap: () => controller.removePhoto(index),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Icon(
                    LucideIcons.plus,
                    color: isDark
                        ? AppColors.textHintDark
                        : AppColors.textHintLight,
                  ),
                ),
        ),
      ),
    );
  }
}

class _EmptyPhotoState extends StatelessWidget {
  final VoidCallback onTap;

  const _EmptyPhotoState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: const Icon(
              LucideIcons.camera,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'main_photo'.tr,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'add_photos_subtitle'.tr,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(LucideIcons.imagePlus, size: 18),
            label: Text('choose_source'.tr),
          ),
        ],
      ),
    );
  }
}

class _DeletePhotoButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DeletePhotoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
          shape: BoxShape.circle,
        ),
        child: const Icon(LucideIcons.x, color: Colors.white, size: 16),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceMutedDark
              : AppColors.surfaceMutedLight,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
