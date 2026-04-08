import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/widgets/signup_flow.dart';

class BirthdayScreen extends GetView<SignupController> {
  const BirthdayScreen({super.key});

  DateTime _maxBirthdayDate() {
    final now = DateTime.now();
    return DateTime(now.year - 18, now.month, now.day);
  }

  DateTime _defaultBirthday() {
    final max = _maxBirthdayDate();
    return DateTime(max.year - 4, max.month, max.day);
  }

  String _formatBirthday(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$month / $day / ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    controller.syncStep(AppRoutes.signupBirthday);

    return SignupStepScaffold(
      onBack: controller.goBack,
      progress: controller.progressPercent,
      footer: Obx(() {
        final busy = controller.isNavigatingStep.value;
        final canContinue = controller.dateOfBirth.value != null && !busy;
        final selectedBirthday = controller.dateOfBirth.value;

        return SignupFooterActions(
          primaryLabel: 'continue_text'.tr,
          isLoading: busy,
          onPrimary: canContinue ? controller.goToNextStep : null,
          helper: Text(
            selectedBirthday == null
                ? 'birthday_select_prompt'.tr
                : _formatBirthday(selectedBirthday),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      }),
      child: Obx(() {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final selectedBirthday = controller.dateOfBirth.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.md),
            const Text('🎂', style: TextStyle(fontSize: 38)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'birthday_title'.tr,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'birthday_desc'.tr,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF121C48), Color(0xFF0B1232)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2A356C)),
              ),
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: Brightness.dark,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                child: SizedBox(
                  height: 220,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    dateOrder: DatePickerDateOrder.mdy,
                    initialDateTime: selectedBirthday ?? _defaultBirthday(),
                    minimumDate: DateTime(1960),
                    maximumDate: _maxBirthdayDate(),
                    onDateTimeChanged: (picked) {
                      controller.dateOfBirth.value = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
