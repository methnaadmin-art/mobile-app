import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
    // Senior Performance Fix: Defer heavy photo rendering until after route transition
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isReady = true);
      }
    });
  }

  Future<void> _pickImage(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final source = await Get.bottomSheet<ImageSource>(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('choose_source'.tr, 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(LucideIcons.camera, color: AppColors.primary),
              title: Text('camera'.tr),
              onTap: () => Get.back(result: ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(LucideIcons.image, color: AppColors.primary),
              title: Text('gallery'.tr),
              onTap: () => Get.back(result: ImageSource.gallery),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (source == null) return;

    if (Platform.isAndroid) {
      if (source == ImageSource.camera) {
        await Permission.camera.request();
      } else {
        await Permission.photos.request();
        await Permission.storage.request();
      }
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1080,
        imageQuality: 85,
      );
      
      if (picked != null) {
        controller.addPhoto(File(picked.path));
      }
    } catch (e) {
      debugPrint('[AddPhotos] Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final bgColor = isDark ? AppColors.backgroundDark : Colors.white;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHintLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Scrollable content ──
            Expanded(
              child: _isReady 
                ? RepaintBoundary(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          // ── Main photo area ──
                          Obx(() => _buildMainPhoto(isDark, borderColor, hintColor)),
                          const SizedBox(height: 16),
                          // ── Photo Grid slots ──
                          Obx(() => _buildPhotoGrid(isDark, borderColor, hintColor)),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),

            // ── Bottom: Continue button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Obx(() => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: controller.selectedPhotos.length >= 2 ? controller.goToNextStep : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                        disabledForegroundColor: Colors.white70,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      child: Text('continue_text'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  if (controller.selectedPhotos.length < 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'min_photos_hint'.trParams({'count': '2'}),
                        style: TextStyle(fontSize: 12, color: AppColors.error.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainPhoto(bool isDark, Color borderColor, Color hintColor) {
    final hasMain = controller.selectedPhotos.isNotEmpty;
    final isMain = controller.mainPhotoIndex.value == 0;
    
    return GestureDetector(
      onTap: hasMain ? () => controller.setMainPhoto(0) : () => _pickImage(context),
      child: Container(
        width: double.infinity,
        height: 240,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (hasMain && isMain) ? AppColors.primary : borderColor, 
            width: (hasMain && isMain) ? 2.5 : 1.5),
        ),
        child: hasMain
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(
                      controller.selectedPhotos[0],
                      fit: BoxFit.cover,
                      cacheWidth: 800,
                    ),
                  ),
                  if (isMain)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'main'.tr.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => controller.removePhoto(0),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.x, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.camera, size: 36, color: hintColor),
                  const SizedBox(height: 14),
                  Text('main_photo'.tr, 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                  const SizedBox(height: 4),
                  Text('add_photos_subtitle'.tr, style: TextStyle(fontSize: 13, color: hintColor)),
                ],
              ),
      ),
    );
  }

  Widget _buildPhotoGrid(bool isDark, Color borderColor, Color hintColor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildPhotoSlot(1, isDark, borderColor, hintColor)),
            const SizedBox(width: 14),
            Expanded(child: _buildPhotoSlot(2, isDark, borderColor, hintColor)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildPhotoSlot(3, isDark, borderColor, hintColor)),
            const SizedBox(width: 14),
            Expanded(child: _buildPhotoSlot(4, isDark, borderColor, hintColor)),
            const SizedBox(width: 14),
            Expanded(child: _buildPhotoSlot(5, isDark, borderColor, hintColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoSlot(int photoIndex, bool isDark, Color borderColor, Color hintColor) {
    final hasPhoto = photoIndex < controller.selectedPhotos.length;
    final isMain = controller.mainPhotoIndex.value == photoIndex;

    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: hasPhoto ? () => controller.setMainPhoto(photoIndex) : () => _pickImage(context),
        child: hasPhoto 
          ? Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isMain ? AppColors.primary : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13.5),
                    child: Image.file(
                      controller.selectedPhotos[photoIndex],
                      fit: BoxFit.cover,
                      cacheWidth: 400,
                    ),
                  ),
                ),
                if (isMain)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'main'.tr.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => controller.removePhoto(photoIndex),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.x, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            )
          : Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Center(
                child: Icon(LucideIcons.plus, size: 28, color: hintColor),
              ),
            ),
      ),
    );
  }
}
