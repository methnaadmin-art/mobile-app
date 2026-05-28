import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/utils/validators.dart';
import 'package:methna_app/core/widgets/app_card.dart';
import 'package:methna_app/core/widgets/custom_button.dart';
import 'package:methna_app/core/widgets/custom_text_field.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class ChangeUsernameScreen extends StatefulWidget {
  const ChangeUsernameScreen({super.key});

  @override
  State<ChangeUsernameScreen> createState() => _ChangeUsernameScreenState();
}

class _ChangeUsernameScreenState extends State<ChangeUsernameScreen> {
  late final SettingsController controller;
  late final TextEditingController _usernameController;
  final RxBool _isValid = false.obs;
  final RxBool _isCheckingAvailability = false.obs;
  final RxnBool _isUsernameAvailable = RxnBool();
  Timer? _availabilityDebounce;
  int _availabilityRequestId = 0;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SettingsController>();
    _usernameController = TextEditingController(text: controller.username);
    _validateAndCheck(_usernameController.text, immediate: true);
  }

  @override
  void dispose() {
    _availabilityDebounce?.cancel();
    _usernameController.dispose();
    super.dispose();
  }

  String _normalizeUsername(String value) {
    return value.trim().replaceFirst('@', '');
  }

  bool _isCurrentUsername(String value) {
    final current = _normalizeUsername(controller.username);
    return current.toLowerCase() == _normalizeUsername(value).toLowerCase();
  }

  void _validateAndCheck(String value, {bool immediate = false}) {
    final normalized = _normalizeUsername(value);
    final validationError = Validators.username(normalized);
    _isValid.value = validationError == null;

    _availabilityDebounce?.cancel();
    if (!_isValid.value) {
      _availabilityRequestId++;
      _isCheckingAvailability.value = false;
      _isUsernameAvailable.value = null;
      return;
    }

    if (_isCurrentUsername(normalized)) {
      _availabilityRequestId++;
      _isCheckingAvailability.value = false;
      _isUsernameAvailable.value = true;
      return;
    }

    if (immediate) {
      unawaited(_checkAvailability(normalized));
      return;
    }

    _availabilityDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_checkAvailability(normalized));
    });
  }

  Future<void> _checkAvailability(String normalizedUsername) async {
    final requestId = ++_availabilityRequestId;
    _isCheckingAvailability.value = true;
    _isUsernameAvailable.value = null;

    final available = await controller.checkUsernameAvailability(normalizedUsername);

    if (!mounted || requestId != _availabilityRequestId) {
      return;
    }

    final latestInput = _normalizeUsername(_usernameController.text);
    if (latestInput.toLowerCase() != normalizedUsername.toLowerCase()) {
      return;
    }

    _isCheckingAvailability.value = false;
    _isUsernameAvailable.value = available;
  }

  String _availabilityMessage() {
    if (!_isValid.value) return 'username_invalid'.tr;
    if (_isCheckingAvailability.value) return 'checking_username'.tr;

    final available = _isUsernameAvailable.value;
    if (available == true) {
      return _isCurrentUsername(_usernameController.text)
          ? 'username_hint'.tr
          : 'available'.tr;
    }
    if (available == false) {
      return 'username_not_available'.tr;
    }
    return 'username_hint'.tr;
  }

  Color _availabilityColor() {
    if (!_isValid.value) return AppColors.error;
    if (_isCheckingAvailability.value) return const Color(0xFF8D879F);

    final available = _isUsernameAvailable.value;
    if (available == true && !_isCurrentUsername(_usernameController.text)) {
      return AppColors.success;
    }
    if (available == false) {
      return AppColors.error;
    }
    return const Color(0xFF8D879F);
  }

  Future<void> _showStatusCard({
    required bool success,
    required String title,
    String? subtitle,
  }) async {
    await Get.dialog<void>(
      Dialog(
        backgroundColor: Colors.transparent,
        child: AppCard(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.82, end: 1),
            duration: const Duration(milliseconds: 340),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: (success ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    success ? LucideIcons.check : LucideIcons.x,
                    color: success ? AppColors.success : AppColors.error,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                if ((subtitle ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSimplePageScaffold(
      title: 'username'.tr,
      footer: Obx(
        () => CustomButton(
          text: 'save'.tr,
          icon: LucideIcons.check,
          isLoading: controller.isSavingUsername.value,
          onPressed:
              controller.isSavingUsername.value ||
                  !_isValid.value ||
                  _isCheckingAvailability.value ||
                  _isUsernameAvailable.value != true
              ? null
              : () async {
                  final normalized = _normalizeUsername(_usernameController.text);
                  final availability = await controller.checkUsernameAvailability(normalized);
                  if (!mounted) return;

                  if (availability != true) {
                    await _showStatusCard(
                      success: false,
                      title: 'username_updated_failed'.tr,
                      subtitle: availability == null
                          ? 'username_check_fail'.tr
                          : 'username_not_available'.tr,
                    );
                    return;
                  }

                  final success = await controller.changeUsername(
                    normalized,
                    showFeedback: false,
                  );

                  if (!mounted) return;

                  if (success) {
                    await _showStatusCard(
                      success: true,
                      title: 'username_updated'.tr,
                      subtitle:
                          '@${_usernameController.text.trim().replaceFirst('@', '')}',
                    );
                    if (mounted) {
                      Get.back();
                    }
                  } else {
                    await _showStatusCard(
                      success: false,
                      title: 'username_updated_failed'.tr,
                      subtitle: 'try_again'.tr,
                    );
                  }
                },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          CustomTextField(
            controller: _usernameController,
            hint: 'username',
            label: 'username'.tr,
            prefixIcon: LucideIcons.atSign,
            suffix: Obx(() {
              if (_isCheckingAvailability.value) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              final available = _isUsernameAvailable.value;
              if (available == true && !_isCurrentUsername(_usernameController.text)) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    LucideIcons.check,
                    size: 16,
                    color: AppColors.success,
                  ),
                );
              }

              if (available == false) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    LucideIcons.x,
                    size: 16,
                    color: AppColors.error,
                  ),
                );
              }

              return const SizedBox.shrink();
            }),
            onChanged: _validateAndCheck,
          ),
          const SizedBox(height: AppSpacing.xs),
          Obx(
            () => Text(
              _availabilityMessage(),
              style: AppTextStyles.bodySmall.copyWith(
                color: _availabilityColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
