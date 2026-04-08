import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/controllers/signup_data.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/widgets/signup_flow.dart';

class ProfessionPersonalScreen extends GetView<SignupController> {
  const ProfessionPersonalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller.syncStep(AppRoutes.signupProfession);

    return SignupStepScaffold(
      onBack: controller.goBack,
      progress: controller.progressPercent,
      footer: Obx(() {
        final hasLiveFormState = controller.formChangeTick >= 0;
        final hasChildren = controller.hasChildren.value;
        final ready =
            hasLiveFormState &&
            controller.selectedEducation.value.isNotEmpty &&
            controller.jobTitleController.text.trim().isNotEmpty &&
            controller.selectedLanguages.isNotEmpty &&
            controller.selectedNationalities.isNotEmpty &&
            controller.selectedEthnicity.value.isNotEmpty &&
            hasChildren != null &&
            (!hasChildren ||
                controller.numberOfChildrenController.text.trim().isNotEmpty) &&
            controller.selectedFamilyValues.isNotEmpty;
        final busy =
            controller.isNavigatingStep.value || controller.isLoading.value;

        return SignupFooterActions(
          primaryLabel: 'continue_text'.tr,
          onPrimary: ready && !busy ? controller.goToNextStep : null,
          isLoading: busy,
          secondaryLabel: 'skip_for_now'.tr,
          onSecondary: busy ? null : controller.skipCurrentOptionalStep,
          helper: Text(
            'add_extra_details_optional'.tr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SignupHeroCard(
            badge: '09 / 12',
            icon: LucideIcons.briefcase,
            title: 'profession_personal'.tr,
            description: 'profession_personal_desc'.tr,
            preview: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                SignupInfoPill(
                  icon: LucideIcons.briefcase,
                  label: 'work_education'.tr,
                ),
                SignupInfoPill(
                  icon: LucideIcons.users,
                  label: 'family_details'.tr,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SignupSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => SignupPickerTile(
                    label: 'education_label'.tr,
                    placeholder: 'select_education'.tr,
                    icon: LucideIcons.graduationCap,
                    value: controller.selectedEducation.value,
                    onTap: () => _showPickerSheet(
                      context,
                      title: 'education'.tr,
                      options: SignupData.educationLevels,
                      onSelected: (value) =>
                          controller.selectedEducation.value = value,
                      translateItems: true,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SignupInputField(
                  controller: controller.jobTitleController,
                  label: 'job_title'.tr,
                  hint: 'enter_profession'.tr,
                  icon: LucideIcons.briefcase,
                ),
                const SizedBox(height: AppSpacing.lg),
                SignupInputField(
                  controller: controller.bioController,
                  label: 'about_me_header'.tr,
                  hint: 'write_about_yourself'.tr,
                  icon: LucideIcons.fileText,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SignupSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SignupSectionLabel(text: 'languages_label'.tr),
                const SizedBox(height: AppSpacing.md),
                Obx(
                  () => Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: SignupData.languagesList
                        .map(
                          (language) => SignupOptionChip(
                            label: language,
                            selected: controller.selectedLanguages.contains(
                              language,
                            ),
                            onTap: () => controller.toggleLanguage(language),
                            translateLabel: true,
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Obx(() {
                  final primaryNationality = controller.primaryNationality;
                  final secondaryNationality = controller.secondaryNationality;
                  final secondaryOptions = primaryNationality == null
                      ? <String>[]
                      : SignupData.arabicCountries
                            .where((country) => country != primaryNationality)
                            .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SignupPickerTile(
                        label: 'first_nationality'.tr,
                        placeholder: 'select_first_nationality'.tr,
                        icon: LucideIcons.flag,
                        value: primaryNationality,
                        onTap: () => _showPickerSheet(
                          context,
                          title: 'first_nationality'.tr,
                          options: SignupData.arabicCountries,
                          onSelected: controller.setPrimaryNationality,
                          translateItems: true,
                        ),
                        translateValue: true,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SignupPickerTile(
                        label: 'secondary_nationality'.tr,
                        placeholder: 'select_secondary_nationality'.tr,
                        icon: LucideIcons.flag,
                        value: secondaryNationality,
                        onTap: () => _showPickerSheet(
                          context,
                          title: 'secondary_nationality'.tr,
                          options: secondaryOptions,
                          onSelected: (value) =>
                              controller.setSecondaryNationality(value),
                          translateItems: true,
                          clearLabel: secondaryNationality == null
                              ? null
                              : 'clear'.tr,
                          onClear: secondaryNationality == null
                              ? null
                              : () => controller.setSecondaryNationality(null),
                        ),
                        translateValue: true,
                      ),
                    ],
                  );
                }),
                const SizedBox(height: AppSpacing.xl),
                Obx(
                  () => SignupPickerTile(
                    label: 'ethnicity_label'.tr,
                    placeholder: 'select_ethnicity'.tr,
                    icon: LucideIcons.flag,
                    value: controller.selectedEthnicity.value,
                    onTap: () => _showPickerSheet(
                      context,
                      title: 'ethnicity'.tr,
                      options: SignupData.ethnicities,
                      onSelected: controller.setEthnicity,
                      translateItems: true,
                    ),
                    translateValue: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SignupSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SignupSectionLabel(text: 'children_label'.tr),
                const SizedBox(height: AppSpacing.md),
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: SignupOptionChip(
                          label: 'no_children'.tr,
                          selected: controller.hasChildren.value == false,
                          onTap: () => controller.setHasChildren(false),
                          translateLabel: false,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: SignupOptionChip(
                          label: 'has_children'.tr,
                          selected: controller.hasChildren.value == true,
                          onTap: () => controller.setHasChildren(true),
                          translateLabel: false,
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(() {
                  if (controller.hasChildren.value != true) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: SignupInputField(
                      controller: controller.numberOfChildrenController,
                      label: 'number_of_children'.tr,
                      hint: 'enter_number_children'.tr,
                      keyboardType: TextInputType.number,
                      icon: LucideIcons.baby,
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.xl),
                SignupSectionLabel(text: 'family_future'.tr),
                const SizedBox(height: AppSpacing.md),
                Obx(
                  () => Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: SignupData.familyValuesOptions
                        .map(
                          (value) => SignupOptionChip(
                            label: value,
                            selected: controller.selectedFamilyValues.contains(
                              value,
                            ),
                            onTap: () => controller.toggleFamilyValue(value),
                            translateLabel: true,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPickerSheet(
    BuildContext context, {
    required String title,
    required List<String> options,
    required ValueChanged<String> onSelected,
    required bool translateItems,
    String? clearLabel,
    VoidCallback? onClear,
  }) {
    Get.bottomSheet<void>(
      SignupSurfaceCard(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (onClear != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    onClear();
                    Get.back<void>();
                  },
                  child: Text(clearLabel ?? 'clear'.tr),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: options.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          'select_first_nationality'.tr,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : Column(
                        children: options
                            .map(
                              (value) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    onSelected(value);
                                    Get.back<void>();
                                  },
                                  borderRadius: BorderRadius.circular(22),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(
                                      AppSpacing.lg,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0x1FFFFFFF)
                                          : const Color(0xFFF7F3FD),
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: Text(
                                      translateItems ? value.tr : value,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }
}
