import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:methna_app/app/data/services/storage_service.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';

class SplashController extends GetxController with GetTickerProviderStateMixin {
  final StorageService _storage = Get.find<StorageService>();
  final AuthService _auth = Get.find<AuthService>();
  final LocalAuthentication _localAuth = LocalAuthentication();

  final RxDouble animationProgress = 0.0.obs;
  final RxBool showLogo = false.obs;
  final RxBool showTagline = false.obs;
  final RxBool requiresBiometric = false.obs;
  final RxBool biometricFailed = false.obs;

  @override
  void onInit() {
    super.onInit();
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    // Start auth check in parallel with animation
    final navFuture = _resolveDestination();

    // Phase 1: Show logo with fade + scale
    await Future.delayed(const Duration(milliseconds: 200));
    showLogo.value = true;

    // Phase 2: Show tagline
    await Future.delayed(const Duration(milliseconds: 500));
    showTagline.value = true;

    // Phase 3: Progress bar animation
    await Future.delayed(const Duration(milliseconds: 200));
    for (int i = 0; i <= 100; i += 4) {
      animationProgress.value = i / 100;
      await Future.delayed(const Duration(milliseconds: 15));
    }

    // Phase 4: Wait for auth check to complete, then navigate
    final route = await navFuture;
    debugPrint('[Splash] Navigating to: $route');
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Check if biometric is required before navigating to main
    if (route == AppRoutes.main) {
      final biometricEnabled = _storage.getBool('security_biometric') ?? false;
      final faceIdEnabled = _storage.getBool('security_face_id') ?? false;
      
      if (biometricEnabled || faceIdEnabled) {
        requiresBiometric.value = true;
        final authenticated = await _authenticateWithBiometrics();
        if (!authenticated) {
          biometricFailed.value = true;
          debugPrint('[Splash] Biometric failed, staying on splash');
          return; // Don't navigate, wait for retry
        }
        requiresBiometric.value = false;
      }
    }
    
    // Check if we already redirected (e.g. by ApiService 401 safeguard)
    if (Get.currentRoute != route) {
      Get.offAllNamed(route);
    } else {
      debugPrint('[Splash] Already at destination: $route');
    }
  }

  Future<bool> _authenticateWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (!canCheck || !isDeviceSupported) {
        debugPrint('[Splash] Biometric not available on device');
        return true; // Allow access if biometric not available
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      debugPrint('[Splash] Available biometrics: $availableBiometrics');

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'authenticate_to_access'.tr,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      debugPrint('[Splash] Biometric authentication result: $authenticated');
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('[Splash] Biometric error: ${e.message}');
      return true; // Allow access on error
    }
  }

  Future<void> retryBiometric() async {
    biometricFailed.value = false;
    final authenticated = await _authenticateWithBiometrics();
    if (authenticated) {
      requiresBiometric.value = false;
      Get.offAllNamed(AppRoutes.main);
    } else {
      biometricFailed.value = true;
    }
  }

  Future<String> _resolveDestination() async {
    final isFirst = _storage.isFirstLaunch;
    final isOnboardingDone = _storage.isOnboardingDone;
    debugPrint('[Splash] isFirstLaunch=$isFirst, isOnboardingDone=$isOnboardingDone');
    
    // First launch: show onboarding
    if (isFirst) {
      debugPrint('[Splash] First launch → onboarding');
      return AppRoutes.onboarding;
    }
    
    // Not first launch but onboarding not done: show onboarding
    if (!isOnboardingDone) {
      debugPrint('[Splash] Onboarding not complete → onboarding');
      return AppRoutes.onboarding;
    }
    
    // Try to restore user session
    final restored = await _auth.tryRestoreSession();
    debugPrint('[Splash] Session restored=$restored');
    
    if (restored) {
      final user = _auth.currentUser.value;
      if (user != null) {
        // Check all signup steps in order
        
        // 1. Profile basics (gender)
        if (user.profile == null || user.profile!.gender == null || user.profile!.gender!.isEmpty) {
          debugPrint('[Splash] User missing profile/gender → signup gender');
          return AppRoutes.signupGender;
        }

        // 2. Profile details (bio - "tell about us" step)
        if (user.profile!.bio == null || user.profile!.bio!.isEmpty) {
          debugPrint('[Splash] User missing bio → signup profile details');
          return AppRoutes.signupProfileDetails;
        }

        // 3. Birthday
        if (user.profile!.dateOfBirth == null) {
          debugPrint('[Splash] User missing birthday → signup birthday');
          return AppRoutes.signupBirthday;
        }

        // 4. Religious info (faith step)
        if (user.profile!.religiousLevel == null || user.profile!.religiousLevel!.isEmpty) {
          debugPrint('[Splash] User missing religious info → signup faith');
          return AppRoutes.signupFaithReligion;
        }

        // 5. Interests/hobbies
        if (user.profile!.interests == null || user.profile!.interests!.isEmpty) {
          debugPrint('[Splash] User missing interests → signup hobbies');
          return AppRoutes.signupHobbies;
        }

        // 6. Profession
        if (user.profile!.jobTitle == null || user.profile!.jobTitle!.isEmpty) {
          debugPrint('[Splash] User missing profession → signup profession');
          return AppRoutes.signupProfession;
        }

        // 7. Mandatory Photos (Min 2)
        final photoCount = user.photos?.length ?? 0;
        if (photoCount < 2) {
          debugPrint('[Splash] User missing photos ($photoCount) → photos flow');
          return AppRoutes.signupPhotos;
        }

        // 8. Mandatory Face/Selfie Verification
        if (user.selfieUrl == null || user.selfieUrl!.isEmpty) {
          debugPrint('[Splash] User missing selfie → selfie flow');
          return AppRoutes.signupSelfie;
        }
      }
      return AppRoutes.main;
    }
    
    return AppRoutes.login;
  }

}
