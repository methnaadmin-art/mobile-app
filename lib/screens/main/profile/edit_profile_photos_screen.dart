import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:methna_app/app/controllers/profile_controller.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/data/services/permission_service.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_gradients.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/utils/cloudinary_url.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/app_card.dart';
import 'package:methna_app/core/widgets/app_modal_sheet.dart';
import 'package:methna_app/core/widgets/custom_button.dart';
import 'package:methna_app/core/widgets/datify_shell.dart';
import 'package:methna_app/core/widgets/discovery_flow.dart';
import 'package:methna_app/core/widgets/profile_flow.dart';

class EditProfilePhotosScreen extends StatefulWidget {
  const EditProfilePhotosScreen({super.key});

  @override
  State<EditProfilePhotosScreen> createState() =>
      _EditProfilePhotosScreenState();
}

class _EditProfilePhotosScreenState extends State<EditProfilePhotosScreen> {
  final ProfileController controller = Get.find<ProfileController>();
  final ImagePicker _imagePicker = ImagePicker();

  List<dynamic> _photos = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingPhotos();
  }

  void _loadExistingPhotos() {
    final user = controller.user.value;
    if (user?.photos == null) return;

    final existingPhotos = List<dynamic>.from(user!.photos!);
    existingPhotos.sort(
      (a, b) => (a as PhotoModel).order.compareTo((b as PhotoModel).order),
    );

    setState(() => _photos = existingPhotos);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: DatifyBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DiscoveryIconButton(
                            icon: LucideIcons.chevronLeft,
                            onTap: () => Get.back(),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DiscoveryHeroHeader(
                              eyebrow: 'PHOTOS',
                              title: 'Shape your first impression',
                              subtitle:
                                  'Choose the photos you want people to notice first.',
                              padding: EdgeInsets.zero,
                              trailing: _isUploading
                                  ? const SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  AppColors.primary,
                                                ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : DiscoveryIconButton(
                                      icon: LucideIcons.check,
                                      highlighted: true,
                                      onTap: _saveChanges,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        0,
                      ),
                      child: ProfileHighlightBanner(
                        title: _photos.isEmpty
                            ? 'Add photos to unlock your visual profile'
                            : 'Your first photo remains the main profile image',
                        subtitle: _photos.isEmpty
                            ? 'Aim for a clear portrait first, then build variety with lifestyle and full-length shots.'
                            : 'Tap any slot to preview, reorder, or replace a photo.',
                        icon: LucideIcons.image,
                        accent: AppColors.primary,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        0,
                      ),
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          ProfileMetricPill(
                            label: 'Slots used',
                            value: '${_photos.length}/6',
                            icon: LucideIcons.layoutGrid,
                            accent: AppColors.primary,
                          ),
                          ProfileMetricPill(
                            label: 'Main photo',
                            value: _photos.isEmpty ? 'Missing' : 'Ready',
                            icon: LucideIcons.star,
                            accent: _photos.isEmpty
                                ? AppColors.gold
                                : AppColors.online,
                          ),
                          ProfileMetricPill(
                            label: 'Sync status',
                            value: _isUploading ? 'Saving' : 'Local edits',
                            icon: _isUploading
                                ? LucideIcons.loader
                                : LucideIcons.cloud,
                            accent: _isUploading
                                ? AppColors.gold
                                : AppColors.like,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        0,
                      ),
                      child: _PrimaryPhotoPreview(
                        item: _photos.isEmpty ? null : _photos.first,
                        title: _photos.isEmpty
                            ? 'Main photo preview'
                            : 'Primary photo',
                        subtitle: _photos.isEmpty
                            ? 'Your first uploaded photo will appear here.'
                            : 'This is the image shown first across the app.',
                        onTap: _photos.isEmpty
                            ? _addPhoto
                            : () => _showPhotoOptions(0),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        0,
                      ),
                      child: ProfileSectionCard(
                        title: 'Your photo lineup',
                        subtitle:
                            'Keep your strongest images first and fill each slot with variety.',
                        icon: LucideIcons.layoutGrid,
                        accent: AppColors.like,
                        trailing: Text(
                          '${_photos.length}/6',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.like,
                          ),
                        ),
                        child: _PhotoGrid(
                          photos: _photos,
                          onTapSlot: _showPhotoOptions,
                          onAddPhoto: _addPhoto,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        0,
                      ),
                      child: ProfileSectionCard(
                        title: 'Photo guidance',
                        subtitle:
                            'A few simple tips to help your profile look its best.',
                        icon: LucideIcons.info,
                        accent: AppColors.gold,
                        child: const Column(
                          children: [
                            ProfileDetailRow(
                              label: 'Lead with clarity',
                              value:
                                  'Use a bright, front-facing photo in slot one for your main profile image.',
                              icon: LucideIcons.star,
                              accent: AppColors.primary,
                            ),
                            ProfileDetailRow(
                              label: 'Show variety',
                              value:
                                  'Mix portraits and lifestyle shots so the grid feels complete and trustworthy.',
                              icon: LucideIcons.image,
                              accent: AppColors.like,
                            ),
                            ProfileDetailRow(
                              label: 'Keep it respectful',
                              value:
                                  'Clear, high-quality photos help the review and matching experience stay smooth.',
                              icon: LucideIcons.shield,
                              accent: AppColors.gold,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Add photo',
                        icon: LucideIcons.plus,
                        variant: CustomButtonVariant.secondary,
                        onPressed: _photos.length >= 6 ? null : _addPhoto,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: CustomButton(
                        text: 'Save changes',
                        icon: LucideIcons.check,
                        isLoading: _isUploading,
                        onPressed: _isUploading ? null : _saveChanges,
                      ),
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

  Future<void> _addPhoto() async {
    if (_photos.length >= 6) {
      Helpers.showSnackbar(
        message: 'You can only have up to 6 photos',
        isError: true,
      );
      return;
    }

    try {
      if (Get.isRegistered<PermissionService>()) {
        final hasPhotosPermission = await Get.find<PermissionService>()
            .requestPhotos();
        if (!hasPhotosPermission) return;
      }

      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2560,
        maxHeight: 2560,
        imageQuality: 96,
      );

      if (picked == null) return;

      setState(() => _photos.add(File(picked.path)));
    } catch (e) {
      debugPrint('[EditPhotos] Error adding photo: $e');
      Helpers.showSnackbar(message: 'Failed to add photo', isError: true);
    }
  }

  Future<void> _showPhotoOptions(int index) async {
    if (index < 0 || index >= _photos.length) return;

    await showMethnaModalSheet<void>(
      context: context,
      title: 'Photo actions',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetAction(
            icon: LucideIcons.eye,
            label: 'Preview photo',
            onTap: () {
              Navigator.of(context).pop();
              _viewPhoto(index);
            },
          ),
          if (index > 0)
            _SheetAction(
              icon: LucideIcons.star,
              label: 'Set as main photo',
              onTap: () {
                Navigator.of(context).pop();
                _setAsMainPhoto(index);
              },
            ),
          if (index > 0)
            _SheetAction(
              icon: LucideIcons.arrowUp,
              label: 'Move earlier',
              onTap: () {
                Navigator.of(context).pop();
                _reorderPhotos(index, index - 1);
              },
            ),
          if (index < _photos.length - 1)
            _SheetAction(
              icon: LucideIcons.arrowDown,
              label: 'Move later',
              onTap: () {
                Navigator.of(context).pop();
                _reorderPhotos(index, index + 1);
              },
            ),
          if (index > 0)
            _SheetAction(
              icon: LucideIcons.trash2,
              label: 'Delete photo',
              destructive: true,
              onTap: () {
                Navigator.of(context).pop();
                _deletePhoto(index);
              },
            ),
        ],
      ),
    );
  }

  void _setAsMainPhoto(int index) {
    if (index <= 0 || index >= _photos.length) return;

    setState(() {
      final photo = _photos.removeAt(index);
      _photos.insert(0, photo);
    });
  }

  void _deletePhoto(int index) {
    if (index <= 0 || index >= _photos.length) return;
    setState(() => _photos.removeAt(index));
  }

  void _viewPhoto(int index) {
    if (index < 0 || index >= _photos.length) return;

    final item = _photos[index];

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.hero),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 0.72,
                child: item is File
                    ? Image.file(item, fit: BoxFit.cover)
                    : CachedNetworkImage(
                        imageUrl: CloudinaryUrl.full((item as PhotoModel).url),
                        fit: BoxFit.cover,
                      ),
              ),
              Positioned(
                top: AppSpacing.md,
                right: AppSpacing.md,
                child: DiscoveryIconButton(
                  icon: LucideIcons.x,
                  onTap: () => Navigator.of(dialogContext).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _reorderPhotos(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _photos.length ||
        newIndex < 0 ||
        newIndex >= _photos.length ||
        oldIndex == newIndex) {
      return;
    }

    setState(() {
      final photo = _photos.removeAt(oldIndex);
      _photos.insert(newIndex, photo);
    });
  }

  Future<void> _saveChanges() async {
    if (_isUploading) return;

    setState(() => _isUploading = true);

    try {
      final initialPhotos = controller.user.value?.photos ?? [];
      final currentPhotos = _photos;

      for (final initial in initialPhotos) {
        final stillExists = currentPhotos.any(
          (photo) => photo is PhotoModel && photo.id == initial.id,
        );
        if (!stillExists) {
          await controller.deletePhoto(initial.id, refresh: false);
        }
      }

      for (final item in currentPhotos) {
        if (item is File) {
          await controller.uploadPhoto(item, refresh: false);
        }
      }

      await controller.refreshProfile();
      final updatedUser = controller.user.value;

      if (currentPhotos.isNotEmpty) {
        final firstItem = currentPhotos.first;
        String? targetMainId;

        if (firstItem is PhotoModel) {
          targetMainId = firstItem.id;
        } else if (firstItem is File) {
          final newPhotos = updatedUser?.photos ?? [];
          final newlyUploaded = newPhotos
              .where(
                (photo) => !initialPhotos.any((item) => item.id == photo.id),
              )
              .toList();
          if (newlyUploaded.isNotEmpty) {
            targetMainId = newlyUploaded.first.id;
          }
        }

        if (targetMainId != null) {
          await controller.setMainPhoto(targetMainId, refresh: false);
        }
      }

      await controller.refreshProfile();

      if (!mounted) return;
      Get.back();
      Helpers.showSnackbar(message: 'Profile photos updated successfully!');
    } catch (e, stackTrace) {
      debugPrint('[EditPhotos] Error saving: $e');
      debugPrint('[EditPhotos] Stack: $stackTrace');
      Helpers.showSnackbar(message: 'Failed to update photos', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}

class _PrimaryPhotoPreview extends StatelessWidget {
  final dynamic item;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PrimaryPhotoPreview({
    required this.item,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      radius: AppRadii.hero,
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.02,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item == null)
              Container(
                decoration: const BoxDecoration(gradient: AppGradients.primary),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.imagePlus,
                  size: 44,
                  color: Colors.white,
                ),
              )
            else
              _PhotoVisual(item: item),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              child: const DiscoveryInfoPill(
                icon: LucideIcons.star,
                label: 'Main photo',
                color: AppColors.gold,
                filled: true,
              ),
            ),
            Positioned(
              right: AppSpacing.md,
              top: AppSpacing.md,
              child: const DiscoveryIconButton(
                icon: LucideIcons.expand,
                highlighted: true,
              ),
            ),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
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

class _PhotoGrid extends StatelessWidget {
  final List<dynamic> photos;
  final ValueChanged<int> onTapSlot;
  final VoidCallback onAddPhoto;

  const _PhotoGrid({
    required this.photos,
    required this.onTapSlot,
    required this.onAddPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (context, index) {
        if (index < photos.length) {
          return ProfilePhotoSlot(
            isPrimary: index == 0,
            badge: index == 0 ? 'MAIN' : '${index + 1}',
            onTap: () => onTapSlot(index),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _PhotoVisual(item: photos[index]),
                Positioned(
                  right: AppSpacing.xs,
                  bottom: AppSpacing.xs,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.48),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      LucideIcons.edit3,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return AppCard(
          variant: AppCardVariant.outlined,
          radius: AppRadii.xl,
          onTap: onAddPhoto,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      LucideIcons.plus,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Add',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text('Slot ${index + 1}', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PhotoVisual extends StatelessWidget {
  final dynamic item;

  const _PhotoVisual({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item is File) {
      return Image.file(
        item as File,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _PhotoFallback(),
      );
    }

    if (item is PhotoModel) {
      return CachedNetworkImage(
        imageUrl: CloudinaryUrl.large((item as PhotoModel).url),
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          color: Colors.black.withValues(alpha: 0.04),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
        errorWidget: (_, _, _) => const _PhotoFallback(),
      );
    }

    return const _PhotoFallback();
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.primary),
      alignment: Alignment.center,
      child: const Icon(LucideIcons.imageOff, color: Colors.white, size: 28),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (destructive ? AppColors.error : AppColors.primary)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 18,
                color: destructive ? AppColors.error : AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: destructive ? AppColors.error : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
