import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class ResetPasswordController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();

  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final RxBool isLoading = false.obs;
  final RxBool obscureNew = true.obs;
  final RxBool obscureConfirm = true.obs;

  late String email;
  late String otpCode;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    email = args?['email'] ?? '';
    otpCode = args?['otpCode'] ?? '';
  }

  void toggleNewVisibility() => obscureNew.toggle();
  void toggleConfirmVisibility() => obscureConfirm.toggle();

  Future<void> resetPassword() async {
    if (!formKey.currentState!.validate()) return;

    if (newPasswordController.text != confirmPasswordController.text) {
      Helpers.showSnackbar(message: 'Passwords do not match', isError: true);
      return;
    }

    isLoading.value = true;
    try {
      await _auth.resetPassword(
        email,
        otpCode,
        newPasswordController.text,
      );
      isLoading.value = false;
      _showResetSuccess();
    } catch (e) {
      Helpers.showSnackbar(message: 'Failed to reset password', isError: true);
      isLoading.value = false;
    }
  }

  void _showResetSuccess() {
    Get.dialog(
      const _ResetSuccessDialog(),
      barrierDismissible: false,
      barrierColor: Colors.black54,
    );
    Future.delayed(const Duration(seconds: 2), () {
      Get.offAllNamed(AppRoutes.login);
    });
  }

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}

// ─── Reset password success dialog (Image 5) ─────────────────────────────
class _ResetSuccessDialog extends StatelessWidget {
  const _ResetSuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 48),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lock icon in circle
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.lock,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Reset Password\nSuccessful!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
                decoration: TextDecoration.none,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please wait.\nYou will be directed to the homepage.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w400,
                height: 1.5,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
