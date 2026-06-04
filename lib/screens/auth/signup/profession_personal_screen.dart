import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/controllers/signup_data.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/utils/profile_option_icons.dart';
import 'package:methna_app/core/widgets/signup_flow.dart';

class ProfessionPersonalScreen extends GetView<SignupController> {
  const ProfessionPersonalScreen({super.key});

  static const List<_MarriageTimelineOption> _marriageTimelineOptions = [
    _MarriageTimelineOption(
      key: '1-3 MONTHS',
      icon: Icons.flash_on_rounded,
      iconColor: AppColors.primaryDark,
      iconBackground: AppColors.primarySurface,
    ),
    _MarriageTimelineOption(
      key: '3-6 MONTHS',
      icon: Icons.schedule_rounded,
      iconColor: AppColors.primary,
      iconBackground: AppColors.primarySurface,
    ),
    _MarriageTimelineOption(
      key: 'UP TO 1 YEAR',
      icon: Icons.event_available_rounded,
      iconColor: AppColors.secondary,
      iconBackground: AppColors.primarySurface,
    ),
    _MarriageTimelineOption(
      key: '1-2 YEARS',
      icon: Icons.hourglass_bottom_rounded,
      iconColor: AppColors.primaryDark,
      iconBackground: AppColors.primarySurface,
    ),
    _MarriageTimelineOption(
      key: 'NOT SURE',
      icon: Icons.explore_rounded,
      iconColor: AppColors.primaryLight,
      iconBackground: AppColors.primarySurface,
    ),
  ];

  static const List<String> _skinComplexionOptions = [
    'very_fair',
    'fair',
    'medium',
    'olive',
    'dark',
    'prefer_not_to_say',
  ];

  static const List<String> _bodyBuildOptions = [
    'slim',
    'average',
    'athletic',
    'curvy',
    'prefer_not_to_say',
  ];

  @override
  Widget build(BuildContext context) {
    controller.syncStep(AppRoutes.signupProfession);

    return SignupStepScaffold(
      onBack: controller.goBack,
      progress: controller.progressPercent,
      footer: Obx(() {
        final busy =
            controller.isNavigatingStep.value || controller.isLoading.value;

        return SignupFooterActions(
          primaryLabel: 'continue_text'.tr,
          onPrimary: !busy ? controller.goToNextStep : null,
          isLoading: busy,
        );
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SignupHeroCard(
            badge: '09 / 12',
            icon: LucideIcons.briefcase,
            title: 'profession_personal'.tr,
            description: '',
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
                  hint: 'Short bio',
                  icon: LucideIcons.fileText,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: AppSpacing.lg),
                SignupInputField(
                  controller: controller.reasonToUseMethnaController,
                  label: 'reason_to_use_methna'.tr,
                  hint: 'reason_to_use_methna_hint'.tr,
                  icon: LucideIcons.messageCircle,
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: SignupInputField(
                        controller: controller.heightController,
                        label: 'height'.tr,
                        hint: 'enter_height'.tr,
                        keyboardType: TextInputType.number,
                        icon: Icons.height_rounded,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: SignupInputField(
                        controller: controller.weightController,
                        label: 'weight'.tr,
                        hint: 'enter_weight'.tr,
                        keyboardType: TextInputType.number,
                        icon: Icons.monitor_weight_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SignupSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () {
                    final selectedLanguages = controller.selectedLanguages
                        .toList(growable: false);
                    final languageSummary = selectedLanguages.isEmpty
                        ? null
                        : selectedLanguages.length == 1
                        ? selectedLanguages.first
                        : '${selectedLanguages.length} selected';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SignupPickerTile(
                          label: 'languages_label'.tr,
                          placeholder: 'Select languages',
                          icon: Icons.translate_rounded,
                          value: languageSummary,
                          translateValue: selectedLanguages.length == 1,
                          onTap: () => _showLanguageSheet(context),
                        ),
                        if (selectedLanguages.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: selectedLanguages
                                .map(
                                  (language) => SignupOptionChip(
                                    label: language,
                                    selected: true,
                                    translateLabel: true,
                                    onTap: () =>
                                        controller.toggleLanguage(language),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                Obx(() {
                  final primaryNationality = controller.primaryNationality;
                  final secondaryNationality = controller.secondaryNationality;
                  final secondaryOptions = primaryNationality == null
                      ? <String>[]
                      : SignupData.supportedCountries
                            .where((country) => country != primaryNationality)
                            .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SignupPickerTile(
                        label: 'first_nationality'.tr,
                        placeholder: 'select_first_nationality'.tr,
                        icon: identityFieldIcon('nationality'),
                        value: primaryNationality,
                        onTap: () => _showPickerSheet(
                          context,
                          title: 'first_nationality'.tr,
                          options: SignupData.supportedCountries,
                          onSelected: controller.setPrimaryNationality,
                          translateItems: true,
                        ),
                        translateValue: true,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SignupPickerTile(
                        label: 'secondary_nationality'.tr,
                        placeholder: 'select_secondary_nationality'.tr,
                        icon: identityFieldIcon('nationality'),
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
                    icon: identityFieldIcon('ethnicity'),
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
                const SizedBox(height: AppSpacing.xl),
                Obx(
                  () => SignupPickerTile(
                    label: 'skin_complexion'.tr,
                    placeholder: 'select_skin_complexion'.tr,
                    icon: Icons.face_retouching_natural_outlined,
                    value: controller.selectedSkinComplexion.value,
                    onTap: () => _showPickerSheet(
                      context,
                      title: 'skin_complexion'.tr,
                      options: _skinComplexionOptions,
                      onSelected: controller.setSkinComplexion,
                      translateItems: true,
                    ),
                    translateValue: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Obx(
                  () => SignupPickerTile(
                    label: 'body_build'.tr,
                    placeholder: 'select_body_build'.tr,
                    icon: Icons.accessibility_new_rounded,
                    value: controller.selectedBodyBuild.value,
                    onTap: () => _showPickerSheet(
                      context,
                      title: 'body_build'.tr,
                      options: _bodyBuildOptions,
                      onSelected: controller.setBodyBuild,
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
                SignupSectionLabel(text: 'willing_to_relocate'.tr),
                const SizedBox(height: AppSpacing.md),
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: SignupOptionChip(
                          label: 'yes'.tr,
                          selected: controller.willingToRelocate.value == true,
                          onTap: () => controller.setWillingToRelocate(true),
                          translateLabel: false,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: SignupOptionChip(
                          label: 'no'.tr,
                          selected: controller.willingToRelocate.value == false,
                          onTap: () => controller.setWillingToRelocate(false),
                          translateLabel: false,
                        ),
                      ),
                    ],
                  ),
                ),
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
                const SizedBox(height: AppSpacing.xl),
                SignupSectionLabel(text: 'marriage_timeline'.tr),
                const SizedBox(height: AppSpacing.md),
                Obx(() {
                  final selectedKey = controller.selectedMarriageTimeline.value;
                  final selectedIndex = _timelineIndexFor(selectedKey);
                  final selectedOption = _marriageTimelineOptions[selectedIndex];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0x1FFFFFFF)
                              : AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selectedOption.iconBackground,
                              ),
                              child: Icon(
                                selectedOption.icon,
                                color: selectedOption.iconColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedOption.key,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _timelineCaption(selectedOption.key),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Slider(
                        value: selectedIndex.toDouble(),
                        min: 0,
                        max: (_marriageTimelineOptions.length - 1).toDouble(),
                        divisions: _marriageTimelineOptions.length - 1,
                        label: selectedOption.key,
                        onChanged: (value) {
                          final index = value.round().clamp(
                            0,
                            _marriageTimelineOptions.length - 1,
                          ).toInt();
                          controller.setMarriageTimeline(
                            _marriageTimelineOptions[index].key,
                          );
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _marriageTimelineOptions.first.key,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          Text(
                            _marriageTimelineOptions.last.key,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  );
                }),
                const SizedBox(height: AppSpacing.xl),
                SignupInputField(
                  controller: controller.describeIdealSpouseController,
                  label: 'describe_ideal_spouse'.tr,
                  hint: 'describe_ideal_spouse_hint'.tr,
                  icon: Icons.favorite_border_rounded,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final draftSelection = controller.selectedLanguages.toSet();

    Get.bottomSheet<void>(
      StatefulBuilder(
        builder: (context, setModalState) {
          return SignupSurfaceCard(
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
                  'languages_label'.tr,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.md),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: SignupData.languagesList.map((language) {
                        final selected = draftSelection.contains(language);
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.sm,
                          ),
                          child: SignupChoiceTile(
                            title: language.tr,
                            selected: selected,
                            leading: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: selected ? 0.16 : 0.08,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.lg,
                                ),
                              ),
                              child: const Icon(
                                Icons.translate_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                            onTap: () {
                              setModalState(() {
                                if (selected) {
                                  draftSelection.remove(language);
                                } else {
                                  draftSelection.add(language);
                                }
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SignupFooterActions(
                  primaryLabel: 'done'.tr,
                  onPrimary: () {
                    controller.selectedLanguages.assignAll(
                      SignupData.languagesList
                          .where(draftSelection.contains)
                          .toList(),
                    );
                    Get.back<void>();
                  },
                ),
              ],
            ),
          );
        },
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
                                          : AppColors.primarySurface,
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

  static int _timelineIndexFor(String key) {
    final index = _marriageTimelineOptions.indexWhere(
      (option) => option.key == key,
    );
    return index >= 0 ? index : 1;
  }

  static String _timelineCaption(String key) {
    switch (key) {
      case '1-3 MONTHS':
        return 'Ready to move quickly with family involvement.';
      case '3-6 MONTHS':
        return 'Looking for a serious, near-term path.';
      case 'UP TO 1 YEAR':
        return 'Sincere intention with space to build trust.';
      case '1-2 YEARS':
        return 'Open to a thoughtful getting-to-know period.';
      default:
        return 'Still exploring the right time frame.';
    }
  }
}

class _MarriageTimelineOption {
  final String key;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const _MarriageTimelineOption({
    required this.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });
}
