import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:methna_app/app/controllers/home_controller.dart';
import 'package:methna_app/app/data/services/app_update_service.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/data/services/storage_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/utils/auth_navigation_resolver.dart';

class SplashController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final AuthService _auth = Get.find<AuthService>();
  LocalAuthentication? _localAuth;

  final RxDouble animationProgress = 0.0.obs;
  final RxBool showLogo = false.obs;
  final RxBool showTagline = false.obs;
  final RxBool requiresBiometric = false.obs;
  final RxBool biometricFailed = false.obs;
  bool _startupStarted = false;
  bool _sessionRestoreQueued = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_startupStarted) return;
      _startupStarted = true;
      unawaited(_startAnimation());
    });
    Future.delayed(const Duration(seconds: 8), _safetyNetNavigate);
  }

  bool _hasNavigated = false;

  void _safetyNetNavigate() {
    if (_hasNavigated) return;
    debugPrint('[Splash] Safety net triggered — forcing navigation');
    _hasNavigated = true;
    final hasSession = _storage.hasAuthSessionHint;
    if (hasSession) {
      _auth.markSessionRestorePending();
    }
    Get.offAllNamed(hasSession ? AppRoutes.main : AppRoutes.login);
    // Ensure HomeController init overlay clears after safety net navigation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (Get.isRegistered<HomeController>()) {
        final home = Get.find<HomeController>();
        if (home.isInitializing.value) {
          home.isInitializing.value = false;
        }
      }
    });
  }

  Future<void> _startAnimation() async {
    try {
      debugPrint('[Splash] Startup flow started');
      final routeFuture = _resolveDestinationFast();

      await Future.delayed(const Duration(milliseconds: 60));
      showLogo.value = true;
      animationProgress.value = 0.45;

      await Future.delayed(const Duration(milliseconds: 120));
      showTagline.value = true;
      animationProgress.value = 0.8;

      final results = await Future.wait<dynamic>([
        routeFuture,
        Future.delayed(const Duration(milliseconds: 450)),
      ]);
      final target = results.first as PostAuthNavigationTarget;
      final route = target.route;
      animationProgress.value = 1.0;
      debugPrint('[Splash] Navigating to: $route');

      if (route == AppRoutes.main) {
        final biometricEnabled =
            _storage.getBool('security_biometric') ??
            (_storage.getBool('biometric_enabled') ?? false);
        final faceIdEnabled = _storage.getBool('security_face_id') ?? false;

        if (biometricEnabled || faceIdEnabled) {
          requiresBiometric.value = true;
          final authState = await _authenticateWithBiometrics();
          if (authState == _BiometricAuthState.unavailable) {
            await _disableBiometricLockPreference();
            requiresBiometric.value = false;
          } else if (authState != _BiometricAuthState.success) {
            biometricFailed.value = true;
            debugPrint('[Splash] Biometric failed, staying on splash');
            return;
          }
          requiresBiometric.value = false;
        }
      }

      if (_hasNavigated) return;

      if (Get.isRegistered<AppUpdateService>()) {
        final hardBlocked = await Get.find<AppUpdateService>().checkForUpdate(
          force: true,
        );
        if (hardBlocked) {
          _hasNavigated = true;
          return;
        }
      }

      _hasNavigated = true;

      if (route == AppRoutes.main) {
        _auth.markSessionRestorePending();
      }

      if (Get.currentRoute != route) {
        Get.offAllNamed(route, arguments: target.arguments);

        _queueSessionRestore(route);
      } else {
        debugPrint('[Splash] Already at destination: $route');
        _queueSessionRestore(route);
      }
    } catch (e, stack) {
      debugPrint('[Splash] CRITICAL ERROR during startup: $e');
      debugPrint('[Splash] Stack: $stack');
      // Don't leave the user stuck — force to login
      if (!_hasNavigated) {
        _hasNavigated = true;
        Get.offAllNamed(AppRoutes.login);
      }
    }
  }

  Future<_BiometricAuthState> _authenticateWithBiometrics() async {
    try {
      final auth = _localAuth ??= LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();

      if (!canCheck || !isDeviceSupported) {
        debugPrint('[Splash] Biometric not available on device');
        return _BiometricAuthState.unavailable;
      }

      final availableBiometrics = await auth.getAvailableBiometrics();
      debugPrint('[Splash] Available biometrics: $availableBiometrics');
      if (availableBiometrics.isEmpty) {
        return _BiometricAuthState.unavailable;
      }

      final authenticated = await auth.authenticate(
        localizedReason: 'authenticate_to_access'.tr,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      debugPrint('[Splash] Biometric authentication result: $authenticated');
      return authenticated
          ? _BiometricAuthState.success
          : _BiometricAuthState.failed;
    } on PlatformException catch (e) {
      debugPrint('[Splash] Biometric error: ${e.message}');
      final code = e.code.toLowerCase();
      if (code.contains('notavailable') || code.contains('notenrolled')) {
        return _BiometricAuthState.unavailable;
      }
      return _BiometricAuthState.failed;
    }
  }

  Future<void> _disableBiometricLockPreference() async {
    await _storage.saveBool('security_biometric', false);
    await _storage.saveBool('biometric_enabled', false);
    await _storage.saveBool('security_face_id', false);
  }

  Future<void> retryBiometric() async {
    biometricFailed.value = false;
    final authState = await _authenticateWithBiometrics();
    if (authState == _BiometricAuthState.unavailable) {
      await _disableBiometricLockPreference();
      requiresBiometric.value = false;
      Get.offAllNamed(AppRoutes.main);
      _queueSessionRestore(AppRoutes.main);
      return;
    }

    if (authState == _BiometricAuthState.success) {
      requiresBiometric.value = false;
      Get.offAllNamed(AppRoutes.main);
      _queueSessionRestore(AppRoutes.main);
    } else {
      biometricFailed.value = true;
    }
  }

  void _queueSessionRestore(String route) {
    if (_sessionRestoreQueued ||
        route == AppRoutes.login ||
        route == AppRoutes.onboarding) {
      return;
    }

    _sessionRestoreQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 250), () async {
        try {
          await _auth.restoreSessionAfterLaunch();
        } finally {
          _sessionRestoreQueued = false;
        }
      });
    });
  }

  Future<PostAuthNavigationTarget> _resolveDestinationFast() async {
    final isFirst = _storage.isFirstLaunch;
    final isOnboardingDone = _storage.isOnboardingDone;
    debugPrint(
      '[Splash] isFirstLaunch=$isFirst, isOnboardingDone=$isOnboardingDone',
    );

    if (isFirst) {
      debugPrint('[Splash] First launch -> onboarding');
      return const PostAuthNavigationTarget(route: AppRoutes.onboarding);
    }

    if (!isOnboardingDone) {
      debugPrint('[Splash] Onboarding not complete -> onboarding');
      return const PostAuthNavigationTarget(route: AppRoutes.onboarding);
    }

    if (!_storage.hasAuthSessionHint) {
      return const PostAuthNavigationTarget(route: AppRoutes.login);
    }

    final cachedUser = _auth.hydrateCachedSession();
    if (cachedUser != null) {
      final draftRoute = _storage.getSignupDraftRoute();
      return resolvePostAuthNavigation(cachedUser, draftRoute: draftRoute);
    }

    debugPrint('[Splash] Token found without cached user -> main');
    return const PostAuthNavigationTarget(route: AppRoutes.main);
  }
}

enum _BiometricAuthState { success, failed, unavailable }
