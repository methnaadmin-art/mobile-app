import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
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
  final RxBool _isValid = true.obs;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SettingsController>();
    _usernameController = TextEditingController(text: controller.username);
    _validate(_usernameController.text);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _validate(String value) {
    _isValid.value = value.trim().length >= 3 && !value.contains(' ');
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
          onPressed: controller.isSavingUsername.value || !_isValid.value
              ? null
              : () async {
                  final success = await controller.changeUsername(
                    _usernameController.text,
                  );
                  if (success) {
                    Get.back();
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
            onChanged: _validate,
          ),
          const SizedBox(height: AppSpacing.xs),
          Obx(
            () => Text(
              _isValid.value
                  ? 'username_hint'.tr
                  : 'username_invalid'.tr,
              style: AppTextStyles.bodySmall.copyWith(
                color: _isValid.value ? const Color(0xFF8D879F) : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
