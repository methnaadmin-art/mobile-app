import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/core/utils/helpers.dart';

class LoginController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
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
  String _getDestinationRoute(UserModel user) {
    // Check profile basics (gender is set during signup)
    if (user.profile == null || user.profile!.gender == null || user.profile!.gender!.isEmpty) {
      debugPrint('[Login] User missing profile/gender → signup gender');
      return AppRoutes.signupGender;
    }

    // Check if profile details are filled (bio indicates "tell about us" step)
    if (user.profile!.bio == null || user.profile!.bio!.isEmpty) {
      debugPrint('[Login] User missing bio → signup profile details');
      return AppRoutes.signupProfileDetails;
    }

    // Check birthday
    if (user.profile!.dateOfBirth == null) {
      debugPrint('[Login] User missing birthday → signup birthday');
      return AppRoutes.signupBirthday;
    }

    // Check religious info (faith step)
    if (user.profile!.religiousLevel == null || user.profile!.religiousLevel!.isEmpty) {
      debugPrint('[Login] User missing religious info → signup faith');
      return AppRoutes.signupFaithReligion;
    }

    // Check interests/hobbies
    if (user.profile!.interests == null || user.profile!.interests!.isEmpty) {
      debugPrint('[Login] User missing interests → signup hobbies');
      return AppRoutes.signupHobbies;
    }

    // Check profession
    if (user.profile!.jobTitle == null || user.profile!.jobTitle!.isEmpty) {
      debugPrint('[Login] User missing profession → signup profession');
      return AppRoutes.signupProfession;
    }

    // Check photos (minimum 2 required)
    final photoCount = user.photos?.length ?? 0;
    if (photoCount < 2) {
      debugPrint('[Login] User missing photos ($photoCount) → signup photos');
      return AppRoutes.signupPhotos;
    }

    // Check selfie verification
    if (user.selfieUrl == null || user.selfieUrl!.isEmpty) {
      debugPrint('[Login] User missing selfie → signup selfie');
      return AppRoutes.signupSelfie;
    }

    // All signup steps complete
    debugPrint('[Login] User signup complete → main');
    return AppRoutes.main;
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;
    if (isLoading.value) return; // prevent double tap

    isLoading.value = true;
    debugPrint('[Login] login attempt: ${emailController.text.trim()}');
    try {
      final user = await _auth.login(
        emailController.text.trim(),
        passwordController.text,
      );
      debugPrint('[Login] login SUCCESS');
      
      // Determine where to navigate based on signup completion
      final destinationRoute = _getDestinationRoute(user);
      final isSignupIncomplete = destinationRoute != AppRoutes.main;
      
      // Keep isLoading true to block further taps during transition
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

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    if (isGoogleLoading.value || isLoading.value) return;

    isGoogleLoading.value = true;
    debugPrint('[Login] Google sign-in attempt');

    try {
      // Sign out first to ensure account picker shows
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('[Login] Google sign-in cancelled by user');
        isGoogleLoading.value = false;
        return;
      }

      debugPrint('[Login] Google user: ${googleUser.email}');
      
      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      
      if (idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      debugPrint('[Login] Got Google ID token, authenticating with backend...');
      
      // Send to backend for authentication
      final user = await _auth.googleSignIn(
        idToken: idToken,
        email: googleUser.email,
        displayName: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
      );

      debugPrint('[Login] Google sign-in SUCCESS');
      
      // Determine where to navigate based on signup completion
      final destinationRoute = _getDestinationRoute(user);
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
    if (e is DioException) {
      return Helpers.extractErrorMessage(e);
    }
    // For non-Dio errors (e.g. JSON parsing), show the real message
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

