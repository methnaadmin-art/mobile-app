import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/controllers/home_controller.dart';
import 'package:methna_app/app/controllers/users_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/utils/upload_image_optimizer.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:methna_app/app/data/services/verification_service.dart';

class ProfileController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  final AuthService _auth = Get.find<AuthService>();

  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;
  bool _statsBootstrapDone = false;

  @override
  void onInit() {
    super.onInit();
    user.value = _auth.currentUser.value;
    _auth.currentUser.listen((u) => user.value = u);
    // If user is null at init time, fetch it
    if (user.value == null) {
      debugPrint('[ProfileController] user is null at init, fetching...');
      refreshProfile();
    }
    unawaited(refreshEngagementStats(force: false));
  }

  void ensureEngagementStatsBootstrap() {
    if (_statsBootstrapDone) return;
    _statsBootstrapDone = true;
    unawaited(refreshEngagementStats(force: false));
  }

  Future<void> refreshEngagementStats({bool force = false}) async {
    if (!Get.isRegistered<UsersController>()) return;
    try {
      await Get.find<UsersController>().ensureUsersTabData(force: force);
    } catch (e) {
      debugPrint('[ProfileController] refreshEngagementStats error: $e');
    }
  }

  Future<void> refreshProfile() async {
    if (isLoading.value) return; // Prevent duplicate calls
    isLoading.value = true;
    try {
      await _auth.fetchMe();
      try {
        await Get.find<VerificationService>().fetchVerificationStatus();
      } catch (_) {}
      user.value = _auth.currentUser.value;
      unawaited(refreshEngagementStats(force: true));
    } catch (e) {
      debugPrint('[ProfileController] refreshProfile error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    isLoading.value = true;
    debugPrint(
      '[Profile] updateProfile called with ${data.length} fields: ${data.keys.toList()}',
    );
    debugPrint('[Profile] Full data: $data');

    try {
      final userData = <String, dynamic>{};
      final profileData = <String, dynamic>{};

      data.forEach((key, value) {
        // Filter out null values. Empty strings are allowed (to clear fields).
        if (value == null) {
          debugPrint('[Profile] Skipping null field: $key');
          return;
        }

        if (['firstName', 'lastName', 'phone'].contains(key)) {
          userData[key] = value;
        } else {
          profileData[key] = value;
        }
      });

      debugPrint(
        '[ProfileController] userData to update: ${userData.keys.toList()}',
      );
      debugPrint(
        '[ProfileController] profileData to update: ${profileData.keys.toList()}',
      );

      bool hasChanges = false;

      // 1. Update User Account Data
      if (userData.isNotEmpty) {
        debugPrint('[ProfileController] PATCH /users/me starting...');
        final res = await _api.patch(ApiConstants.usersMe, data: userData);
        debugPrint(
          '[ProfileController] PATCH /users/me completed with status: ${res.statusCode}',
        );
        hasChanges = true;
      }

      // 2. Update Profile Details
      if (profileData.isNotEmpty) {
        debugPrint('[ProfileController] POST /profiles starting...');
        final res = await _api.post(
          ApiConstants.createOrUpdateProfile,
          data: profileData,
        );
        debugPrint(
          '[ProfileController] POST /profiles completed with status: ${res.statusCode}',
        );
        hasChanges = true;
      }

      if (!hasChanges) {
        debugPrint('[ProfileController] No changes to save');
        Helpers.showSnackbar(message: 'No changes to save');
        return true;
      }

      // 3. Force refresh from server
      debugPrint('[ProfileController] Forcing fresh fetch from server...');
      final updatedUser = await _auth.fetchMe();
      user.value = updatedUser;
      debugPrint(
        '[ProfileController] Local state synchronized. Completion: $profileCompletion%',
      );

      Helpers.showSnackbar(message: 'Profile updated successfully');
      return true;
    } catch (e) {
      debugPrint('[ProfileController] CRITICAL ERROR during updateProfile: $e');
      if (e is DioException) {
        debugPrint('[ProfileController] Dio Error Data: ${e.response?.data}');
        debugPrint(
          '[ProfileController] Dio Error Status: ${e.response?.statusCode}',
        );
      }
      final msg = Helpers.extractErrorMessage(e);
      Helpers.showSnackbar(
        message: 'Failed to save changes: $msg',
        isError: true,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Photo Management ───────────────────────────────────
  Future<bool> uploadPhoto(
    File file, {
    bool isMain = false,
    bool refresh = true,
  }) async {
    isUploading.value = true;
    try {
      final optimized = await UploadImageOptimizer.optimizeProfilePhoto(file);
      final subtype = _imageSubtypeFromPath(optimized.path);
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          optimized.path,
          filename:
              'photo_${DateTime.now().millisecondsSinceEpoch}.${_fileExtensionForSubtype(subtype)}',
          contentType: MediaType('image', subtype),
        ),
        'isMain': isMain,
      });
      await _api.upload(ApiConstants.uploadPhoto, formData);
      if (refresh) {
        await _auth.fetchMe();
        user.value = _auth.currentUser.value;
      }
      return true;
    } catch (e) {
      debugPrint('[ProfileController] uploadPhoto error: $e');
      if (e is DioException) {
        debugPrint('[ProfileController] Dio error data: ${e.response?.data}');
      }
      Helpers.showSnackbar(message: 'Failed to upload photo', isError: true);
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  String _imageSubtypeFromPath(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
      case '.jpe':
        return 'jpeg';
      case '.png':
        return 'png';
      case '.webp':
        return 'webp';
      case '.heic':
        return 'heic';
      case '.heif':
        return 'heif';
      default:
        return 'jpeg';
    }
  }

  String _fileExtensionForSubtype(String subtype) {
    switch (subtype) {
      case 'jpeg':
        return 'jpg';
      case 'png':
      case 'webp':
      case 'heic':
      case 'heif':
        return subtype;
      default:
        return 'jpg';
    }
  }

  Future<bool> deletePhoto(String photoId, {bool refresh = true}) async {
    try {
      await _api.delete(ApiConstants.deletePhoto(photoId));
      if (refresh) {
        await _auth.fetchMe();
        user.value = _auth.currentUser.value;
      }
      return true;
    } catch (e) {
      Helpers.showSnackbar(message: 'Failed to delete photo', isError: true);
      return false;
    }
  }

  Future<bool> setMainPhoto(String photoId, {bool refresh = true}) async {
    try {
      await _api.patch(ApiConstants.setMainPhoto(photoId));
      if (refresh) {
        await _auth.fetchMe();
        user.value = _auth.currentUser.value;
      }
      return true;
    } catch (e) {
      Helpers.showSnackbar(message: 'Failed to set main photo', isError: true);
      return false;
    }
  }

  void openSettings() => Get.toNamed(AppRoutes.settings);
  Future<void> openEditProfile() async {
    final saved = await Get.toNamed(AppRoutes.editProfile);
    if (saved == true) {
      await refreshProfile();
    }
  }
  void openEditPhotos() => Get.toNamed(AppRoutes.editProfilePhotos);

  bool _hasBoostInventory(int? rawCount) {
    final count = rawCount ?? 0;
    return count == -1 || count > 0;
  }

  Future<void> _openBoostShop() async {
    if (Get.currentRoute == AppRoutes.shop) return;
    await Get.toNamed(
      AppRoutes.shop,
      arguments: const {'initialType': 'boosts_pack'},
    );
  }

  Future<void> _showBoostZeroStateDialog() async {
    if (Get.isDialogOpen ?? false) {
      Helpers.showSnackbar(
        message: 'You have 0 boosts remaining. Open the Shop to buy a boost pack.',
        isError: true,
      );
      return;
    }

    await Get.defaultDialog<void>(
      title: '0 boosts remaining',
      middleText:
          'You have 0 boosts remaining. Open the Shop to buy a boost pack and activate your profile again.',
      textCancel: 'Later',
      textConfirm: 'Open Shop',
      onConfirm: () {
        Get.back<void>();
        unawaited(_openBoostShop());
      },
    );
  }

  bool _shouldOpenBoostUpgrade(String message) {
    final normalized = message.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return normalized.contains('no boosts remaining') ||
        normalized.contains('insufficient boosts') ||
        normalized.contains('not available on your current plan');
  }

  Future<void> triggerProfileBoost() async {
    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().boostProfile();
      return;
    }

    var remainingBoosts = user.value?.profileBoostsCount ?? 0;
    if (!_hasBoostInventory(remainingBoosts)) {
      try {
        await _auth.fetchMe();
        user.value = _auth.currentUser.value;
      } catch (_) {}

      remainingBoosts = user.value?.profileBoostsCount ?? 0;
      if (!_hasBoostInventory(remainingBoosts)) {
        await _showBoostZeroStateDialog();
        return;
      }
    }

    final monetization = Get.isRegistered<MonetizationService>()
        ? Get.find<MonetizationService>()
        : null;

    try {
      final activated =
          await monetization?.purchaseBoost(durationMinutes: 30) ?? false;

      if (!activated) {
        Helpers.showSnackbar(message: 'something_went_wrong'.tr, isError: true);
        return;
      }

      if (monetization != null) {
        monetization.isBoosted.value = true;
        unawaited(monetization.fetchBoostStatus());
        unawaited(monetization.fetchEntitlements());
      }
      unawaited(refreshProfile());
      Helpers.showSnackbar(message: 'profile_boosted_msg'.tr);
    } catch (e) {
      debugPrint('[ProfileController] triggerProfileBoost error: $e');
      final message = Helpers.extractErrorMessage(e);
      if (_shouldOpenBoostUpgrade(message)) {
        final normalized = message.toLowerCase();
        if (normalized.contains('no boosts remaining') ||
            normalized.contains('insufficient boosts')) {
          await _showBoostZeroStateDialog();
        } else {
          unawaited(Get.toNamed(AppRoutes.subscription));
        }
        return;
      }
      Helpers.showSnackbar(
        message: message.isNotEmpty ? message : 'something_went_wrong'.tr,
        isError: true,
      );
    }
  }

  String get fullName => user.value?.fullName ?? '';
  String? get mainPhoto => user.value?.mainPhotoUrl;

  /// Get the real completion percentage calculated on-the-fly
  int get profileCompletion => calculateCompletionPercentage(user.value);

  /// Centralized logic to calculate profile completion (real account completion score)
  int calculateCompletionPercentage(UserModel? user) {
    if (user == null) return 0;
    final profile = user.profile;

    int filled = 0;
    int total = 15;

    if (user.firstName?.isNotEmpty == true) filled++;
    if (user.lastName?.isNotEmpty == true) filled++;
    if (profile?.bio?.isNotEmpty == true) filled++;
    if (profile?.gender != null) filled++;
    if (profile?.dateOfBirth != null) filled++;
    if (profile?.maritalStatus != null) filled++;
    if (profile?.education != null) filled++;
    if (profile?.jobTitle?.isNotEmpty == true) filled++;
    if (profile?.height != null) filled++;
    if (profile?.city?.isNotEmpty == true) filled++;
    if (profile?.religiousLevel != null) filled++;
    if (profile?.prayerFrequency != null) filled++;
    if (profile?.sect != null) filled++;
    if (profile?.dietary != null) filled++;
    if (user.photos?.isNotEmpty == true) {
      filled++; // Replaced interests with photos as it's more critical
    }

    return ((filled / total) * 100).round();
  }

  bool get isVerified => user.value?.selfieVerified ?? false;
  bool get isPremium {
    try {
      return Get.find<MonetizationService>().isPremium ||
          (user.value?.isPremium ?? false);
    } catch (_) {
      return user.value?.isPremium ?? false;
    }
  }

  /// Calculate Baraka Meter score based on Islamic values and religious commitment
  int get barakaScore {
    final profile = user.value?.profile;
    if (profile == null) return 0;

    int score = 0;

    // Prayer & Faith (40 points max)
    // Prayer frequency (20 points)
    switch (profile.prayerFrequency) {
      case 'actively_practicing':
        score += 20;
        break;
      case 'occasionally':
        score += 15;
        break;
      case 'not_practicing':
        score += 5;
        break;
    }

    // Religious level (15 points)
    switch (profile.religiousLevel) {
      case 'very_practicing':
        score += 15;
        break;
      case 'practicing':
        score += 12;
        break;
      case 'moderate':
        score += 8;
        break;
      case 'liberal':
        score += 4;
        break;
    }

    // Sect (5 points)
    if (profile.sect != null && profile.sect!.isNotEmpty) {
      score += 5;
    }

    // Intentions & Marriage (25 points max)
    // Marriage intention (15 points)
    switch (profile.marriageIntention) {
      case 'within_months':
        score += 15;
        break;
      case 'within_year':
        score += 12;
        break;
      case 'one_to_two_years':
        score += 8;
        break;
      case 'not_sure':
        score += 4;
        break;
      case 'just_exploring':
        score += 2;
        break;
    }

    // Family values (10 points)
    if (profile.familyValues != null && profile.familyValues!.isNotEmpty) {
      score += 10;
    }

    // Lifestyle (20 points max)
    // Dietary habits (10 points)
    if (profile.dietary == 'halal') {
      score += 10;
    } else if (profile.dietary == 'non_strict') {
      score += 5;
    }

    // Alcohol (10 points)
    if (profile.alcohol == 'doesnt_drink') {
      score += 10;
    } else if (profile.alcohol == 'drinks') {
      score += 5;
    }

    // Verification bonus (5 points)
    if (isVerified) {
      score += 5;
    }

    // Profile completion bonus (up to 10 points)
    score += (profileCompletion / 10).clamp(0, 10).round();

    return score.clamp(0, 100);
  }

  /// Get Baraka level based on score
  String get barakaLevel {
    final score = barakaScore;
    if (score >= 75) return 'high';
    if (score >= 45) return 'medium';
    return 'low';
  }
}
