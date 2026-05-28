import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/utils/validators.dart';
import 'package:methna_app/core/widgets/app_card.dart';
import 'package:methna_app/core/widgets/custom_button.dart';
import 'package:methna_app/core/widgets/custom_text_field.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final SettingsController _controller = Get.find<SettingsController>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _showStatusCard({
    required bool success,
    required String title,
    String? subtitle,
  }) async {
    await Get.dialog<void>(
      Dialog(
        backgroundColor: Colors.transparent,
        child: AppCard(
          radius: AppRadii.xl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
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
      barrierDismissible: true,
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (currentPassword == newPassword) {
      await _showStatusCard(
        success: false,
        title: 'error'.tr,
        subtitle: 'New password must be different from current password.',
      );
      return;
    }

    final ok = await _controller.changePassword(
      currentPassword,
      newPassword,
      showFeedback: false,
    );

    if (!mounted) return;

    if (ok) {
      await _showStatusCard(
        success: true,
        title: 'password_changed_success'.tr,
      );
      if (mounted) {
        Get.back();
      }
    } else {
      await _showStatusCard(
        success: false,
        title: 'error'.tr,
        subtitle: 'try_again'.tr,
      );
    }
  }

  Widget _requirementTile(String text, bool met) {
    return Row(
      children: [
        Icon(
          met ? LucideIcons.checkCircle2 : LucideIcons.circle,
          size: 16,
          color: met ? AppColors.success : AppColors.textHintLight,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final newPassword = _newPasswordController.text;

    return SettingsSimplePageScaffold(
      title: 'change_password'.tr,
      subtitle: 'create_password_body'.tr,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppCard(
                radius: AppRadii.xl,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _currentPasswordController,
                      label: 'current_password'.tr,
                      hint: 'current_password'.tr,
                      obscureText: _obscureCurrent,
                      prefixIcon: LucideIcons.lock,
                      suffix: IconButton(
                        onPressed: () {
                          setState(() => _obscureCurrent = !_obscureCurrent);
                        },
                        icon: Icon(
                          _obscureCurrent ? LucideIcons.eyeOff : LucideIcons.eye,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'fill_all_fields'.tr;
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CustomTextField(
                      controller: _newPasswordController,
                      label: 'new_password'.tr,
                      hint: 'new_password'.tr,
                      obscureText: _obscureNew,
                      prefixIcon: LucideIcons.key,
                      suffix: IconButton(
                        onPressed: () {
                          setState(() => _obscureNew = !_obscureNew);
                        },
                        icon: Icon(
                          _obscureNew ? LucideIcons.eyeOff : LucideIcons.eye,
                        ),
                      ),
                      validator: Validators.password,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'confirm_new_password'.tr,
                      hint: 'confirm_new_password'.tr,
                      obscureText: _obscureConfirm,
                      prefixIcon: LucideIcons.key,
                      suffix: IconButton(
                        onPressed: () {
                          setState(() => _obscureConfirm = !_obscureConfirm);
                        },
                        icon: Icon(
                          _obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye,
                        ),
                      ),
                      validator: Validators.confirmPassword(
                        () => _newPasswordController.text.trim(),
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                radius: AppRadii.xl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'password_requirements_title'.tr,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _requirementTile(
                      'password_req_length'.tr,
                      newPassword.length >= 8,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _requirementTile(
                      'password_req_uppercase'.tr,
                      RegExp(r'[A-Z]').hasMatch(newPassword),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _requirementTile(
                      'password_req_lowercase'.tr,
                      RegExp(r'[a-z]').hasMatch(newPassword),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _requirementTile(
                      'password_req_number'.tr,
                      RegExp(r'[0-9]').hasMatch(newPassword),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      footer: Obx(
        () => CustomButton(
          text: 'save'.tr,
          icon: LucideIcons.check,
          isLoading: _controller.isChangingPassword.value,
          onPressed: _controller.isChangingPassword.value ? null : _submit,
        ),
      ),
    );
  }
}
