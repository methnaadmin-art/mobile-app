import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final SignupController controller = Get.find<SignupController>();
  final RxString _code = ''.obs;
  final RxInt _countdown = 42.obs;
  final RxBool _canResend = false.obs;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    controller.syncStep(AppRoutes.signupEmailVerification);
    _startCountdown();
  }

  void _startCountdown() {
    _countdown.value = 42;
    _canResend.value = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _countdown.value--;
      if (_countdown.value <= 0) {
        _canResend.value = true;
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onDigit(String d) {
    if (controller.isLoading.value) return;
    if (_code.value.length < 6) {
      _code.value += d;
      if (_code.value.length == 6) {
        controller.otpController.text = _code.value;
        _verifyAndHandleResult();
      }
    }
  }

  Future<void> _verifyAndHandleResult() async {
    try {
      await controller.verifyEmailOtp();
    } catch (_) {
      // Reset code on failure so user can retry
      _code.value = '';
      controller.otpController.clear();
    }
  }

  void _onDelete() {
    if (controller.isLoading.value) return;
    if (_code.value.isNotEmpty) {
      _code.value = _code.value.substring(0, _code.value.length - 1);
    }
  }

  // Colors for filled digit boxes (cycling pink/green/amber)
  static const _fillColors = [
    AppColors.primary,
    Color(0xFF4CAF50),
    Color(0xFFFFC107),
    AppColors.primaryDark,
    AppColors.primary,
    Color(0xFF4CAF50),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFFFF8F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Back arrow
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => controller.goBack(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            LucideIcons.chevronLeft,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Countdown timer
                    Obx(() {
                      final m = (_countdown.value ~/ 60)
                          .toString()
                          .padLeft(2, '0');
                      final s = (_countdown.value % 60)
                          .toString()
                          .padLeft(2, '0');
                      return Text(
                        '$m:$s',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      );
                    }),

                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      'verify_email_subtitle'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryColor,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Show target email
                    Text(
                      controller.emailController.text.trim(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Loading indicator
                    Obx(() => controller.isLoading.value
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation(AppColors.primary),
                              ),
                            ),
                          )
                        : const SizedBox.shrink()),

                    // ── 6 digit boxes ──
                    Obx(() {
                      final code = _code.value;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (i) {
                          final filled = i < code.length;
                          final char = filled ? code[i] : '';
                          return Container(
                            width: 44,
                            height: 52,
                            margin: EdgeInsets.only(right: i < 5 ? 8 : 0),
                            decoration: BoxDecoration(
                              color: filled
                                  ? _fillColors[i % _fillColors.length]
                                  : (isDark
                                      ? AppColors.cardDark
                                      : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(14),
                              border: filled
                                  ? null
                                  : Border.all(
                                      color: isDark
                                          ? AppColors.borderDark
                                          : AppColors.borderLight,
                                      width: 1.5,
                                    ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              char,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: filled
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight),
                              ),
                            ),
                          );
                        }),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ── Custom numpad ──
            _NumPad(
              onDigit: _onDigit,
              onDelete: _onDelete,
              isDark: isDark,
            ),

            // ── Send again ──
            Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 8),
              child: Obx(() => GestureDetector(
                    onTap: _canResend.value
                        ? () {
                            controller.resendOtp();
                            _startCountdown();
                          }
                        : null,
                    child: Text(
                      'resend_code'.tr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _canResend.value
                            ? AppColors.primary
                            : secondaryColor,
                      ),
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Custom number pad ─────────────────────────────────────────────────────
class _NumPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;
  final bool isDark;

  const _NumPad({
    required this.onDigit,
    required this.onDelete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          _row(['1', '2', '3'], textColor),
          const SizedBox(height: 6),
          _row(['4', '5', '6'], textColor),
          const SizedBox(height: 6),
          _row(['7', '8', '9'], textColor),
          const SizedBox(height: 6),
          Row(
            children: [
              _key('', textColor, enabled: false),
              _key('0', textColor),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 52,
                      child: Icon(LucideIcons.delete,
                          size: 22, color: textColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(List<String> digits, Color c) {
    return Row(
      children: digits.map((d) => _key(d, c)).toList(),
    );
  }

  Widget _key(String d, Color c, {bool enabled = true}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled && d.isNotEmpty ? () => onDigit(d) : null,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 52,
            child: Center(
              child: Text(
                d,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: enabled ? c : Colors.transparent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
