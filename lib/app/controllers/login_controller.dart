import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/data/services/app_update_service.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/utils/auth_navigation_resolver.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginController extends GetxController {
  static const String _legacyGoogleWebClientId =
      '980830018700-cjjk2dk6g53j5a60bd2n0nec3kf4fpq1.apps.googleusercontent.com';
  static const String _legacyGoogleIosClientId =
      '980830018700-06on5f7bccfu2a2l8t7n7cklq9dtqqot.apps.googleusercontent.com';
  static const String _expectedAndroidPackageName = 'com.methnapp.app';

  static const String _googleWebClientIdFromEnv = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );
  static const String _googleIosClientIdFromEnv = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '',
  );

  static String? _resolveGoogleWebClientId() {
    final fromEnv = _googleWebClientIdFromEnv.trim();
    if (fromEnv.isNotEmpty) return fromEnv;

    return _legacyGoogleWebClientId;
  }

  static String? _resolveGooglePlatformClientId() {
    if (!(GetPlatform.isIOS || GetPlatform.isMacOS)) {
      // Android should not force iOS client IDs.
      return null;
    }

    final fromEnv = _googleIosClientIdFromEnv.trim();
    if (fromEnv.isNotEmpty) return fromEnv;
    return _legacyGoogleIosClientId;
  }

  final AuthService _auth = Get.find<AuthService>();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: _resolveGoogleWebClientId(),
    forceCodeForRefreshToken: true,
    clientId: GetPlatform.isAndroid ? null : _resolveGooglePlatformClientId(),
  );

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final RxBool isLoading = false.obs;
  final RxBool isGoogleLoading = false.obs;
  final RxBool isAppleLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxBool rememberMe = false.obs;

  bool _isDeveloperConfigIssue(PlatformException error) {
    final raw = '${error.message ?? ''} ${error.details ?? ''} ${error.code}'
        .toLowerCase();
    return raw.contains('apiexception: 10') ||
        raw.contains('developer_error') ||
        raw.contains('12500');
  }

  String _googleDeveloperErrorHelpText() {
    final webClientId = _resolveGoogleWebClientId() ?? 'missing';
    return 'Google Sign-In configuration mismatch (DEVELOPER_ERROR).\n'
        'Android package: $_expectedAndroidPackageName\n'
        'Web client ID: $webClientId\n'
        'Add SHA-1 and SHA-256 for all signing certificates used by this app: debug, upload/release, and Play App Signing (from Play Console > App Integrity). Then download and replace android/app/google-services.json.';
  }

  bool _shouldRetryGoogleSignIn(PlatformException error) {
    final code = error.code.trim().toLowerCase();
    final raw = '${error.message ?? ''} ${error.details ?? ''} ${error.code}'
        .toLowerCase();

    if (_isDeveloperConfigIssue(error)) {
      return false;
    }

    if (code.contains('sign_in_failed') || code.contains('network_error')) {
      return true;
    }

    return raw.contains('sign_in_failed') || raw.contains('network_error');
  }

  Future<GoogleSignInAccount?> _selectGoogleAccountWithRecovery() async {
    try {
      return await _googleSignIn.signIn();
    } on PlatformException catch (e) {
      if (!_shouldRetryGoogleSignIn(e)) {
        rethrow;
      }

      debugPrint('[Login] Google sign-in retry after recoverable error: $e');

      try {
        await _googleSignIn.disconnect();
      } catch (_) {}
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      return await _googleSignIn.signIn();
    }
  }

  void togglePasswordVisibility() => obscurePassword.toggle();

  /// Determines the correct route based on user's signup completion status
  String _getDestinationRoute(UserModel user) => resolvePostAuthRoute(user);

  Future<UserModel> _resolveFreshUser(UserModel fallback) async {
    try {
      return await _auth.fetchMe();
    } catch (e) {
      debugPrint('[Login] fetchMe after login failed, using cached user: $e');
      return _auth.currentUser.value ?? fallback;
    }
  }

  /// Federated users skip ONLY username and email-verification steps
  /// (the provider already verifies identity and we auto-generate a username).
  /// They must still complete gender, marital status, profile details,
  /// birthday, etc. — otherwise the backend detects incomplete profile
  /// and restoreSessionAfterLaunch keeps re-routing, causing a loop
  /// that makes the app appear stuck/loading.
  String _getFederatedDestinationRoute(UserModel user) {
    final resolved = _getDestinationRoute(user);
    if (resolved == AppRoutes.main) return resolved;

    // Only skip these two — the provider already provides email + identity.
    const federatedSkippableRoutes = {
      AppRoutes.signupUsername,
      AppRoutes.signupEmailVerification,
    };

    if (federatedSkippableRoutes.contains(resolved)) {
      return AppRoutes.signupGender;
    }

    return resolved;
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;
    if (isLoading.value) return;

    isLoading.value = true;
    debugPrint('[Login] login attempt: ${emailController.text.trim()}');
    try {
      final user = await _auth.login(
        emailController.text.trim(),
        passwordController.text,
      );
      debugPrint('[Login] login SUCCESS');

      final routedUser = await _resolveFreshUser(user);

      final destinationRoute = _getDestinationRoute(routedUser);
      final isSignupIncomplete = destinationRoute != AppRoutes.main;

      Helpers.showLoginSuccessDialog(
        title: 'login_success'.tr,
        message: isSignupIncomplete
            ? 'login_redirect_complete_profile'.tr
            : 'login_redirect_home'.tr,
        barrierDismissible: false,
      );

      Future.delayed(const Duration(seconds: 2), () async {
        if (Get.isDialogOpen ?? false) Get.back();
        if (Get.isRegistered<AppUpdateService>()) {
          final hardBlocked = await Get.find<AppUpdateService>().checkForUpdate(
            force: true,
          );
          if (hardBlocked) return;
        }
        Get.offAllNamed(destinationRoute);
      });
    } catch (e) {
      final restrictedArgs = _extractRestrictedAccountArgs(e);
      if (restrictedArgs != null) {
        debugPrint('[Login] Redirecting to account status from login error');
        isLoading.value = false;
        _navigateToRestrictedDestination(restrictedArgs);
        return;
      }

      final message = _extractError(e);
      debugPrint('[Login] login FAILED: $message');
      isLoading.value = false;

      Helpers.showLottieDialog(
        lottieAsset: 'assets/animations/error.json',
        title: 'Login Failed',
        message: message,
      );
    }
  }

  void goToForgotPassword() => Get.toNamed(AppRoutes.forgotPassword);

  void goToSignUp() => Get.toNamed(AppRoutes.signupUsername);

  Future<void> signInWithGoogle() async {
    if (isGoogleLoading.value || isLoading.value) return;
    if (GetPlatform.isIOS || GetPlatform.isMacOS) {
      Helpers.showSnackbar(
        message: 'Use email login on this device.',
        isError: true,
      );
      return;
    }

    isGoogleLoading.value = true;
    debugPrint('[Login] Google sign-in attempt');

    try {
      final GoogleSignInAccount? googleUser =
          await _selectGoogleAccountWithRecovery();

      if (googleUser == null) {
        debugPrint('[Login] Google sign-in cancelled by user');
        isGoogleLoading.value = false;
        return;
      }

      debugPrint('[Login] Google user: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final idToken = googleAuth.idToken?.trim();
      final accessToken = googleAuth.accessToken?.trim();
      final serverAuthCode = googleUser.serverAuthCode?.trim();

      if ((idToken == null || idToken.isEmpty) &&
          (serverAuthCode == null || serverAuthCode.isEmpty)) {
        throw Exception(_googleDeveloperErrorHelpText());
      }

      debugPrint('[Login] Authenticating Google account with backend...');

      final user = await _auth.googleSignIn(
        idToken: idToken,
        accessToken: (accessToken == null || accessToken.isEmpty)
            ? null
            : accessToken,
        serverAuthCode: serverAuthCode,
        email: googleUser.email,
        displayName: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
      );

      debugPrint('[Login] Google sign-in SUCCESS');

      final routedUser = await _resolveFreshUser(user);

      final destinationRoute = _getFederatedDestinationRoute(routedUser);
      final isSignupIncomplete = destinationRoute != AppRoutes.main;

      isGoogleLoading.value = false;

      Helpers.showLoginSuccessDialog(
        title: 'login_success'.tr,
        message: isSignupIncomplete
            ? 'login_redirect_complete_profile'.tr
            : 'login_redirect_home'.tr,
        barrierDismissible: false,
      );

      Future.delayed(const Duration(seconds: 2), () async {
        if (Get.isDialogOpen ?? false) Get.back();
        if (Get.isRegistered<AppUpdateService>()) {
          final hardBlocked = await Get.find<AppUpdateService>().checkForUpdate(
            force: true,
          );
          if (hardBlocked) return;
        }
        Get.offAllNamed(destinationRoute);
      });
    } catch (e) {
      final restrictedArgs = _extractRestrictedAccountArgs(e);
      if (restrictedArgs != null) {
        debugPrint(
          '[Login] Redirecting to account status from Google sign-in error',
        );
        isGoogleLoading.value = false;
        _navigateToRestrictedDestination(restrictedArgs);
        return;
      }

      final message = _extractError(e);
      debugPrint('[Login] Google sign-in FAILED: $message');
      isGoogleLoading.value = false;

      Helpers.showLottieDialog(
        lottieAsset: 'assets/animations/error.json',
        title: 'google_signin_failed'.tr,
        message: message,
      );
    }
  }

  Future<void> signInWithApple() async {
    if (isAppleLoading.value || isLoading.value) return;
    if (!(GetPlatform.isIOS || GetPlatform.isMacOS)) {
      Helpers.showSnackbar(
        message: 'Apple Sign-In is available on Apple devices only.',
        isError: true,
      );
      return;
    }

    isAppleLoading.value = true;
    debugPrint('[Login] Apple sign-in attempt');

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken?.trim();
      final authorizationCode = credential.authorizationCode.trim();

      if (identityToken == null || identityToken.isEmpty) {
        throw Exception('Apple identity token is missing.');
      }
      if (authorizationCode.isEmpty) {
        throw Exception('Apple authorization code is missing.');
      }

      final fullName = [
        credential.givenName,
        credential.familyName,
      ].where((part) => (part ?? '').trim().isNotEmpty).join(' ').trim();

      final user = await _auth.appleSignIn(
        identityToken: identityToken,
        authorizationCode: authorizationCode,
        userIdentifier: credential.userIdentifier,
        email: credential.email,
        firstName: credential.givenName,
        lastName: credential.familyName,
        displayName: fullName.isEmpty ? null : fullName,
      );

      debugPrint('[Login] Apple sign-in SUCCESS');

      final routedUser = await _resolveFreshUser(user);
      final destinationRoute = _getFederatedDestinationRoute(routedUser);
      final isSignupIncomplete = destinationRoute != AppRoutes.main;

      Helpers.showLoginSuccessDialog(
        title: 'login_success'.tr,
        message: isSignupIncomplete
            ? 'login_redirect_complete_profile'.tr
            : 'login_redirect_home'.tr,
        barrierDismissible: false,
      );

      Future.delayed(const Duration(seconds: 2), () async {
        if (Get.isDialogOpen ?? false) Get.back();
        if (Get.isRegistered<AppUpdateService>()) {
          final hardBlocked = await Get.find<AppUpdateService>().checkForUpdate(
            force: true,
          );
          if (hardBlocked) return;
        }
        Get.offAllNamed(destinationRoute);
      });
    } catch (e) {
      final restrictedArgs = _extractRestrictedAccountArgs(e);
      if (restrictedArgs != null) {
        debugPrint(
          '[Login] Redirecting to account status from Apple sign-in error',
        );
        isAppleLoading.value = false;
        _navigateToRestrictedDestination(restrictedArgs);
        return;
      }

      if (e is SignInWithAppleAuthorizationException &&
          e.code == AuthorizationErrorCode.canceled) {
        debugPrint('[Login] Apple sign-in cancelled by user');
        isAppleLoading.value = false;
        return;
      }

      final message = _extractError(e);
      debugPrint('[Login] Apple sign-in FAILED: $message');
      isAppleLoading.value = false;

      Helpers.showLottieDialog(
        lottieAsset: 'assets/animations/error.json',
        title: 'apple_signin_failed'.tr,
        message: message,
      );
    }
  }

  Map<String, dynamic>? _extractRestrictedAccountArgs(dynamic error) {
    if (error is! DioException) return null;

    final raw = error.response?.data;
    final restrictedStatus = extractRestrictedAccountStatus(raw);
    if (restrictedStatus == null) {
      return null;
    }

    return buildRestrictedAccountArguments(
      _auth.currentUser.value,
      fallbackStatus: restrictedStatus,
      fallbackReason: extractRestrictedAccountReason(raw),
      fallbackSupportMessage: extractRestrictedAccountSupportMessage(raw),
      fallbackActionRequired: extractRestrictedAccountActionRequired(raw),
      fallbackStaffMessage: extractRestrictedAccountStaffMessage(raw),
      fallbackExpiresAt: extractRestrictedAccountExpiresAt(raw),
    );
  }

  void _navigateToRestrictedDestination(Map<String, dynamic> args) {
    final status = (args['status']?.toString().trim().toLowerCase() ?? '');
    final route = status == 'banned'
        ? AppRoutes.contactSupport
        : AppRoutes.accountStatus;
    Get.offAllNamed(route, arguments: args);
  }

  String _extractError(dynamic e) {
    if (e is SignInWithAppleAuthorizationException) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return 'Apple Sign-In was cancelled.';
      }
      if (e.code == AuthorizationErrorCode.failed) {
        return 'Apple Sign-In failed. Check your Apple ID and network connection, then try again.';
      }
      return 'Apple Sign-In is not available right now. Please try again.';
    }

    if (e is PlatformException) {
      final raw = '${e.message ?? e.details ?? e.code}'.toLowerCase();
      if (raw.contains('sign_in_failed')) {
        return 'Google Sign-In failed. Check Google Play Services, internet connection, and OAuth setup, then try again.';
      }
      if (_isDeveloperConfigIssue(e)) {
        return _googleDeveloperErrorHelpText();
      }
    }

    if (e is DioException) {
      return Helpers.extractErrorMessage(e);
    }
    debugPrint('[Login] Non-Dio error type: ${e.runtimeType}');
    debugPrint('[Login] Non-Dio error: $e');
    return e.toString();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
