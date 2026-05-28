import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/widgets/app_card.dart';
import 'package:methna_app/core/widgets/custom_button.dart';
import 'package:methna_app/core/widgets/custom_text_field.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final SettingsController _controller = Get.find<SettingsController>();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _confirmWordController = TextEditingController();

  static const List<String> _reasons = [
    'Privacy concerns',
    'Too many notifications',
    'I met someone',
    'Not enough quality matches',
    'Other',
  ];

  String _selectedReason = _reasons.first;
  bool _confirmPermanent = false;

  @override
  void dispose() {
    _detailsController.dispose();
    _confirmWordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_confirmPermanent) {
      Get.snackbar(
        'error'.tr,
        'Please confirm that account deletion is permanent.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_confirmWordController.text.trim().toUpperCase() != 'DELETE') {
      Get.snackbar(
        'error'.tr,
        'Type DELETE to confirm account deletion.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final ok = await _controller.deleteAccount(
      reason: _selectedReason,
      details: _detailsController.text.trim(),
    );

    if (ok && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSimplePageScaffold(
      title: 'delete_account'.tr,
      subtitle: 'delete_account_desc'.tr,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          children: [
            AppCard(
              radius: AppRadii.xl,
              variant: AppCardVariant.tinted,
              tint: AppColors.error,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.alertTriangle,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'delete_account_confirm'.tr,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'delete_account_second_confirm'.tr,
                    style: Theme.of(context).textTheme.bodyMedium,
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
                    'Reason for leaving',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedReason,
                    items: _reasons
                        .map(
                          (reason) => DropdownMenuItem<String>(
                            value: reason,
                            child: Text(reason),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedReason = value);
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    controller: _detailsController,
                    label: 'Additional details',
                    hint: 'Optional details',
                    maxLines: 4,
                    maxLength: 280,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
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
                  CustomTextField(
                    controller: _confirmWordController,
                    label: 'Type DELETE to confirm',
                    hint: 'DELETE',
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CheckboxListTile(
                    value: _confirmPermanent,
                    onChanged: (value) {
                      setState(() => _confirmPermanent = value ?? false);
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      'I understand this action is permanent and cannot be undone.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      footer: Obx(
        () => CustomButton(
          text: 'delete_account'.tr,
          variant: CustomButtonVariant.destructive,
          icon: LucideIcons.trash2,
          isLoading: _controller.isDeletingAccount.value,
          onPressed: _controller.isDeletingAccount.value ? null : _submit,
        ),
      ),
    );
  }
}
