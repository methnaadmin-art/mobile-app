import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/widgets/signup_flow.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final SignupController controller = Get.find<SignupController>();
  final RxString _code = ''.obs;
  final RxBool _isVerifying = false.obs;
  final RxInt _countdown = 42.obs;
  final RxBool _canResend = false.obs;
  final TextEditingController _otpInputController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    controller.syncStep(AppRoutes.signupEmailVerification);
    _startCountdown();
    _otpInputController.addListener(_onOtpTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _otpFocusNode.requestFocus();
      }
    });
  }

  void _onOtpTextChanged() {
    final digitsOnly = _otpInputController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly != _otpInputController.text) {
      _otpInputController.value = TextEditingValue(
        text: digitsOnly,
        selection: TextSelection.collapsed(offset: digitsOnly.length),
      );
      return;
    }

    if (_code.value != digitsOnly) {
      _code.value = digitsOnly;
    }
    controller.otpController.text = digitsOnly;

    if (digitsOnly.length == 6 && !_isVerifying.value) {
      _verifyAndHandleResult(digitsOnly);
    }
  }

  void _startCountdown() {
    _countdown.value = 42;
    _canResend.value = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdown.value--;
      if (_countdown.value <= 0) {
        _canResend.value = true;
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpInputController.removeListener(_onOtpTextChanged);
    _otpFocusNode.dispose();
    _otpInputController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndHandleResult([String? rawCode]) async {
    if (_isVerifying.value) return;
    final otp = (rawCode ?? _otpInputController.text).trim();
    if (otp.length != 6) return;

    _isVerifying.value = true;
    controller.otpController.text = otp;
    try {
      await controller.verifyEmailOtp();
    } catch (_) {
      _otpInputController.clear();
      controller.otpController.clear();
      if (mounted) {
        Future.microtask(() => _otpFocusNode.requestFocus());
      }
    } finally {
      _isVerifying.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SignupStepScaffold(
      onBack: controller.goBack,
      progress: controller.progressPercent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SignupHeroCard(
            badge: '06 / 12',
            icon: LucideIcons.mailCheck,
            title: 'verify_email'.tr,
            description: 'verify_email_subtitle'.tr,
            preview: Text(
              controller.emailController.text.trim(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SignupSurfaceCard(
            child: Column(
              children: [
                Obx(() {
                  final minutes = (_countdown.value ~/ 60).toString().padLeft(
                    2,
                    '0',
                  );
                  final seconds = (_countdown.value % 60).toString().padLeft(
                    2,
                    '0',
                  );

                  return Column(
                    children: [
                      Text(
                        '$minutes:$seconds',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'enter_6_digit_code'.tr,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: AppSpacing.xl),
                Obx(
                  () => TextField(
                    controller: _otpInputController,
                    focusNode: _otpFocusNode,
                    enabled: !_isVerifying.value,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: 6,
                    onSubmitted: (_) => _verifyAndHandleResult(),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 8,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '000000',
                      hintStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 8,
                            color: isDark
                                ? AppColors.textHintDark
                                : AppColors.textHintLight,
                          ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.surfaceMutedDark
                          : AppColors.surfaceMutedLight,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                        horizontal: AppSpacing.lg,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.8,
                        ),
                      ),
                    ),
                  ),
                ),
                Obx(
                  () => _isVerifying.value
                      ? const Padding(
                          padding: EdgeInsets.only(top: AppSpacing.md),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        )
                      : const SizedBox(height: AppSpacing.md),
                ),
                Obx(
                  () => TextButton(
                    onPressed: _canResend.value && !_isVerifying.value
                        ? () {
                            controller.resendOtp();
                          _otpInputController.clear();
                          controller.otpController.clear();
                            _startCountdown();
                          _otpFocusNode.requestFocus();
                          }
                        : null,
                    child: Text('resend_code'.tr),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
