import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:methna_app/app/controllers/otp_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/widgets/auth_flow.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late final OtpController controller;
  final FocusNode _otpFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller = Get.put(OtpController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _otpFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _onOtpChanged(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly != value) {
      controller.otpController.value = TextEditingValue(
        text: digitsOnly,
        selection: TextSelection.collapsed(offset: digitsOnly.length),
      );
      return;
    }

    if (digitsOnly.length == 6 && !controller.isLoading.value) {
      _otpFocusNode.unfocus();
      controller.verifyOtp();
    }
  }

  String _maskEmail(String email) {
    if (!email.contains('@')) return email;
    final parts = email.split('@');
    final name = parts[0];
    final masked = name.length > 2
        ? '${name.substring(0, 2)}${'*' * (name.length - 2)}'
        : name;
    return '$masked@${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      compact: true,
      child: Column(
        children: [
          AuthHeader(onBack: Get.back),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  const _OtpHero(),
                  const SizedBox(height: AppSpacing.xl),
                  AuthTitleBlock(
                    title: 'otp_verification'.tr,
                    subtitle:
                        '${'otp_body_prefix'.tr}${_maskEmail(controller.email)}${'otp_body_suffix'.tr}',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AuthSurfacePanel(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _otpFocusNode.requestFocus,
                          child: Obx(
                            () => LayoutBuilder(
                              builder: (context, constraints) {
                                const spacing = 8.0;
                                final boxWidth =
                                    ((constraints.maxWidth - (spacing * 5)) / 6)
                                        .clamp(38.0, 54.0)
                                        .toDouble();

                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: List.generate(6, (index) {
                                    final code = controller.otpText.value;
                                    final char = index < code.length
                                        ? code[index]
                                        : '';
                                    final isActive =
                                        index == code.length && code.length < 6;

                                    return _OtpDigitBox(
                                      digit: char,
                                      active: isActive,
                                      filled: char.isNotEmpty,
                                      width: boxWidth,
                                    );
                                  }),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Obx(
                          () => SizedBox(
                            width: 1,
                            height: 1,
                            child: TextField(
                              controller: controller.otpController,
                              focusNode: _otpFocusNode,
                              enabled: !controller.isLoading.value,
                              autofocus: true,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              maxLength: 6,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              onChanged: _onOtpChanged,
                              style: const TextStyle(
                                fontSize: 1,
                                color: Colors.transparent,
                              ),
                              cursorColor: Colors.transparent,
                              decoration: const InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Obx(
                          () => GestureDetector(
                            onTap: controller.canResend.value
                                ? () {
                                    controller.resendCode();
                                    controller.otpController.clear();
                                    _otpFocusNode.requestFocus();
                                  }
                                : null,
                            child: Text(
                              controller.canResend.value
                                  ? 'didnt_receive_email'.tr
                                  : '${'resend_code_in'.tr} ${controller.countdown.value}s',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: controller.canResend.value
                                    ? AppColors.primary
                                    : AppColors.textSecondaryLight,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Obx(
                          () => AuthPrimaryButtonBar(
                            label: 'continue_text'.tr,
                            onPressed: controller.isLoading.value
                                ? null
                                : () {
                                    _otpFocusNode.unfocus();
                                    controller.verifyOtp();
                                  },
                            isLoading: controller.isLoading.value,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpHero extends StatelessWidget {
  const _OtpHero();

  @override
  Widget build(BuildContext context) {
    return AuthHeroPanel(
      gradientColors: const [AppColors.primary, AppColors.like],
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
            child: const Icon(
              LucideIcons.badgeCheck,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'verification_code'.tr,
                  style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'otp_hero_desc'.tr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
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

class _OtpDigitBox extends StatelessWidget {
  final String digit;
  final bool active;
  final bool filled;
  final double width;

  const _OtpDigitBox({
    required this.digit,
    required this.active,
    required this.filled,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxHeight = (width * 1.25).clamp(48.0, 62.0).toDouble();
    final borderColor = active
        ? AppColors.primary
        : (filled
              ? AppColors.primary.withValues(alpha: 0.36)
              : (isDark ? AppColors.borderDark : AppColors.borderLight));

    return Container(
      width: width,
      height: boxHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceMutedDark
            : AppColors.surfaceMutedLight,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: borderColor, width: active ? 1.8 : 1.2),
      ),
      child: Text(
        digit,
        style: AppTextStyles.headlineSmall.copyWith(
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}
