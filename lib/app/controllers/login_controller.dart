import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/utils/auth_navigation_resolver.dart';
import 'package:methna_app/core/utils/helpers.dart';

class LoginController extends GetxController {
  static const String _legacyGoogleWebClientId =
      '980830018700-cjjk2dk6g53j5a60bd2n0nec3kf4fpq1.apps.googleusercontent.com';
  static const String _legacyGoogleIosClientId =
      '980830018700-06on5f7bccfu2a2l8t7n7cklq9dtqqot.apps.googleusercontent.com';

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
    scopes: ['email', 'profile'],
    serverClientId: _resolveGoogleWebClientId(),
    clientId: _resolveGooglePlatformClientId(),
  );

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final RxBool isLoading = false.obs;
  final RxBool isGoogleLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxBool rememberMe = false.obs;

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

  /// Google users skip early auth/profile bootstrap screens and start from faith flow.
  String _getGoogleDestinationRoute(UserModel user) {
    final resolved = _getDestinationRoute(user);
    if (resolved == AppRoutes.main) return resolved;

    const earlySignupRoutes = {
      AppRoutes.signupUsername,
      AppRoutes.signupGender,
      AppRoutes.signupMaritalStatus,
      AppRoutes.signupProfileDetails,
      AppRoutes.signupBirthday,
      AppRoutes.signupEmailVerification,
    };

    if (earlySignupRoutes.contains(resolved)) {
      return AppRoutes.signupFaithReligion;
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

      Helpers.showLottieDialog(
        lottieAsset: 'assets/animations/success.json',
        title: 'login_success'.tr,
        message: isSignupIncomplete
            ? 'login_redirect_complete_profile'.tr
            : 'login_redirect_home'.tr,
        barrierDismissible: false,
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (Get.isDialogOpen ?? false) Get.back();
        Get.offAllNamed(destinationRoute);
      });
    } catch (e) {
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

    isGoogleLoading.value = true;
    debugPrint('[Login] Google sign-in attempt');

    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('[Login] Google sign-in cancelled by user');
        isGoogleLoading.value = false;
        return;
      }

      debugPrint('[Login] Google user: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        final serverAuthCode = googleUser.serverAuthCode;
        throw Exception(
          serverAuthCode != null && serverAuthCode.isNotEmpty
              ? 'Google ID token is missing, but auth code was returned. Verify backend /auth/google expects ID token and confirm web client ID configuration.'
              : 'Google ID token not available. Verify Google OAuth client IDs, SHA-1/SHA-256 fingerprints, and backend Google auth setup.',
        );
      }

      debugPrint('[Login] Got Google ID token, authenticating with backend...');

      final user = await _auth.googleSignIn(
        idToken: idToken,
        email: googleUser.email,
        displayName: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
      );

      debugPrint('[Login] Google sign-in SUCCESS');

      final routedUser = await _resolveFreshUser(user);

      final destinationRoute = _getGoogleDestinationRoute(routedUser);
      final isSignupIncomplete = destinationRoute != AppRoutes.main;

      Helpers.showLottieDialog(
        lottieAsset: 'assets/animations/success.json',
        title: 'login_success'.tr,
        message: isSignupIncomplete
            ? 'login_redirect_complete_profile'.tr
            : 'login_redirect_home'.tr,
        barrierDismissible: false,
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (Get.isDialogOpen ?? false) Get.back();
        Get.offAllNamed(destinationRoute);
      });
    } catch (e) {
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

  String _extractError(dynamic e) {
    if (e is PlatformException) {
      final raw = '${e.message ?? e.details ?? e.code}'.toLowerCase();
      if (raw.contains('apiexception: 10') || raw.contains('developer_error')) {
        return 'Google Sign-In configuration mismatch (DEVELOPER_ERROR). Check Android SHA-1/SHA-256 fingerprints, package name, and web client ID.';
      }
      if (raw.contains('12500')) {
        return 'Google Sign-In failed due to OAuth setup. Verify OAuth consent screen and signing certificate fingerprints.';
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
