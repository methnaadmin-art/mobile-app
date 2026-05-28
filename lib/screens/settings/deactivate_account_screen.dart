import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/widgets/app_card.dart';
import 'package:methna_app/core/widgets/custom_button.dart';
import 'package:methna_app/core/widgets/custom_text_field.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class DeactivateAccountScreen extends StatefulWidget {
  const DeactivateAccountScreen({super.key});

  @override
  State<DeactivateAccountScreen> createState() => _DeactivateAccountScreenState();
}

class _DeactivateAccountScreenState extends State<DeactivateAccountScreen> {
  final SettingsController _controller = Get.find<SettingsController>();
  final TextEditingController _detailsController = TextEditingController();

  static const List<String> _reasons = [
    'I need a short break',
    'I am not finding relevant matches',
    'I have privacy concerns',
    'I met someone',
    'Other',
  ];

  String _selectedReason = _reasons.first;
  bool _confirmHidden = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_confirmHidden) {
      Get.snackbar(
        'error'.tr,
        'Please confirm that you understand your profile will be hidden.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final ok = await _controller.deactivateAccount(
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
      title: 'deactivate_account'.tr,
      subtitle: 'deactivate_account_desc'.tr,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.pauseCircle,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'What happens when you deactivate',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your profile will be hidden from discovery and new people will not see you until you sign in again.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your matches and chats stay safe and come back when you reactivate.',
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
                    'Help us improve',
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
                    hint: 'Optional details',
                    label: 'Additional details',
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
              child: CheckboxListTile(
                value: _confirmHidden,
                onChanged: (value) {
                  setState(() => _confirmHidden = value ?? false);
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'I understand my profile will be hidden until I sign in again.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
      footer: Obx(
        () => CustomButton(
          text: 'deactivate'.tr,
          variant: CustomButtonVariant.secondary,
          icon: LucideIcons.pause,
          isLoading: _controller.isDeactivatingAccount.value,
          onPressed: _controller.isDeactivatingAccount.value ? null : _submit,
        ),
      ),
    );
  }
}
