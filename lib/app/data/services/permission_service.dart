import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

/// Centralized permission handling service.
/// Handles camera, gallery, microphone with proper UX flow.
class PermissionService extends GetxService {
  // Permission states
  final Rx<PermissionStatus> cameraStatus = PermissionStatus.denied.obs;
  final Rx<PermissionStatus> photosStatus = PermissionStatus.denied.obs;
  final Rx<PermissionStatus> microphoneStatus = PermissionStatus.denied.obs;
  final Rx<PermissionStatus> locationStatus = PermissionStatus.denied.obs;

  Future<PermissionService> init() async {
    await _checkAllPermissions();
    return this;
  }

  /// Check all permission statuses without requesting
  Future<void> _checkAllPermissions() async {
    cameraStatus.value = await Permission.camera.status;
    photosStatus.value = await Permission.photos.status;
    microphoneStatus.value = await Permission.microphone.status;
    locationStatus.value = await Permission.locationWhenInUse.status;
  }

  // ─── Camera Permission ─────────────────────────────────────

  /// Request camera permission with UX handling.
  /// Returns true if granted, false otherwise.
  Future<bool> requestCamera({String? reason}) async {
    return _requestPermission(
      permission: Permission.camera,
      statusRx: cameraStatus,
      title: 'Camera Access',
      reason: reason ?? 'We need camera access for profile photos and selfie verification.',
      icon: LucideIcons.camera,
    );
  }

  /// Check if camera is available
  bool get hasCameraPermission => cameraStatus.value.isGranted;

  // ─── Gallery/Photos Permission ─────────────────────────────

  /// Request photos/gallery permission with UX handling.
  Future<bool> requestPhotos({String? reason}) async {
    return _requestPermission(
      permission: Permission.photos,
      statusRx: photosStatus,
      title: 'Photo Library Access',
      reason: reason ?? 'We need photo library access to select your profile pictures.',
      icon: LucideIcons.image,
    );
  }

  /// Check if photos is available
  bool get hasPhotosPermission => photosStatus.value.isGranted;

  // ─── Microphone Permission ─────────────────────────────────

  /// Request microphone permission with UX handling.
  Future<bool> requestMicrophone({String? reason}) async {
    return _requestPermission(
      permission: Permission.microphone,
      statusRx: microphoneStatus,
      title: 'Microphone Access',
      reason: reason ?? 'We need microphone access for voice messages.',
      icon: LucideIcons.mic,
    );
  }

  /// Check if microphone is available
  bool get hasMicrophonePermission => microphoneStatus.value.isGranted;

  // ─── Location Permission ───────────────────────────────────

  /// Request location permission with UX handling.
  Future<bool> requestLocation({String? reason}) async {
    return _requestPermission(
      permission: Permission.locationWhenInUse,
      statusRx: locationStatus,
      title: 'Location Access',
      reason: reason ?? 'We need your location to find matches near you.',
      icon: LucideIcons.mapPin,
    );
  }

  /// Check if location is available
  bool get hasLocationPermission => locationStatus.value.isGranted;

  // ─── Combined Permissions ──────────────────────────────────

  /// Request camera + photos together (common for image picker)
  Future<bool> requestCameraAndPhotos() async {
    final camera = await requestCamera();
    final photos = await requestPhotos();
    return camera || photos; // At least one should work
  }

  // ─── Core Permission Handler ───────────────────────────────

  Future<bool> _requestPermission({
    required Permission permission,
    required Rx<PermissionStatus> statusRx,
    required String title,
    required String reason,
    required IconData icon,
  }) async {
    // 1. Check current status
    var status = await permission.status;
    statusRx.value = status;

    // 2. Already granted
    if (status.isGranted) {
      return true;
    }

    // 3. Permanently denied → show settings dialog
    if (status.isPermanentlyDenied) {
      final openSettings = await _showPermanentlyDeniedDialog(title, reason, icon);
      if (openSettings) {
        await openAppSettings();
        // Re-check after returning from settings
        await Future.delayed(const Duration(milliseconds: 500));
        status = await permission.status;
        statusRx.value = status;
        return status.isGranted;
      }
      return false;
    }

    // 4. Show rationale before requesting (for better UX)
    if (status.isDenied) {
      final proceed = await _showRationaleDialog(title, reason, icon);
      if (!proceed) return false;
    }

    // 5. Request the permission
    status = await permission.request();
    statusRx.value = status;

    // 6. Handle result
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      final openSettings = await _showPermanentlyDeniedDialog(title, reason, icon);
      if (openSettings) {
        await openAppSettings();
        await Future.delayed(const Duration(milliseconds: 500));
        status = await permission.status;
        statusRx.value = status;
        return status.isGranted;
      }
    }

    // 7. Denied
    _showDeniedSnackbar(title);
    return false;
  }

  // ─── UI Dialogs ────────────────────────────────────────────

  Future<bool> _showRationaleDialog(String title, String reason, IconData icon) async {
    final result = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                reason,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Not Now', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Allow', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
    return result ?? false;
  }

  Future<bool> _showPermanentlyDeniedDialog(String title, String reason, IconData icon) async {
    final result = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: AppColors.warning),
              ),
              const SizedBox(height: 20),
              Text(
                '$title Required',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '$reason\n\nPlease enable it in Settings to continue.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Open Settings', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
    return result ?? false;
  }

  void _showDeniedSnackbar(String permissionName) {
    Get.snackbar(
      'Permission Denied',
      '$permissionName was not granted. Some features may not work.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFF4F0FF),
      colorText: const Color(0xFF4F26D9),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }

  // ─── Utility ───────────────────────────────────────────────

  /// Refresh all permission statuses
  Future<void> refreshStatuses() async {
    await _checkAllPermissions();
  }

  /// Check if all essential permissions are granted
  bool get hasEssentialPermissions =>
      cameraStatus.value.isGranted && photosStatus.value.isGranted;
}
