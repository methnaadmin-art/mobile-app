import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/controllers/signup_data.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/widgets/signup_flow.dart';

class FaithReligionScreen extends GetView<SignupController> {
  const FaithReligionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller.syncStep(AppRoutes.signupFaithReligion);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return SignupStepScaffold(
      onBack: controller.goBack,
      progress: controller.progressPercent,
      footer: Obx(() {
        final isFemale =
            controller.selectedGender.value.toLowerCase() == 'female';
        final ready =
            controller.selectedSect.value.isNotEmpty &&
            controller.selectedReligiousLevel.value.isNotEmpty &&
            controller.selectedDietary.value.isNotEmpty &&
            controller.selectedAlcohol.value.isNotEmpty &&
            (!isFemale || controller.selectedHijab.value.isNotEmpty);
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
            badge: '07 / 12',
            icon: LucideIcons.moonStar,
            title: 'faith_and_religion'.tr,
            description: 'tell_us_about_your_faith'.tr,
            preview: Wrap(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                SignupInfoPill(
                  icon: LucideIcons.shieldCheck,
                  label: 'private_profile_context'.tr,
                ),
                SignupInfoPill(
                  icon: LucideIcons.sparkles,
                  label: 'used_for_better_matching'.tr,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SelectionSection(
            label: 'sect_label'.tr,
            helper: 'sect_helper'.tr,
            options: SignupData.sects,
            selectedValue: controller.selectedSect,
            icon: LucideIcons.moonStar,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SelectionSection(
            label: 'religious_level_label'.tr,
            helper: 'religious_level_helper'.tr,
            options: SignupData.religiousLevels,
            selectedValue: controller.selectedReligiousLevel,
            icon: LucideIcons.sparkles,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SelectionSection(
            label: 'prayer_frequency_label'.tr,
            helper: 'prayer_frequency_helper'.tr,
            options: SignupData.prayerFrequencies,
            selectedValue: controller.selectedPrayerFrequency,
            icon: LucideIcons.badgeCheck,
          ),
          const SizedBox(height: AppSpacing.lg),
          SignupSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SignupSectionLabel(text: 'lifestyle_label'.tr),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'lifestyle_helper'.tr,
                  textAlign: TextAlign.start,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(height: isRtl ? 1.45 : 1.35),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SelectionWrap(
                  label: 'dietary_label'.tr,
                  options: SignupData.dietaryPreferences,
                  selectedValue: controller.selectedDietary,
                  icon: LucideIcons.utensils,
                ),
                const SizedBox(height: AppSpacing.lg),
                _SelectionWrap(
                  label: 'alcohol_label'.tr,
                  options: SignupData.alcoholPreferences,
                  selectedValue: controller.selectedAlcohol,
                  icon: LucideIcons.wineOff,
                ),
                Obx(() {
                  if (controller.selectedGender.value.toLowerCase() !=
                      'female') {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      _SelectionWrap(
                        label: 'hijab_label'.tr,
                        options: SignupData.hijabStatuses,
                        selectedValue: controller.selectedHijab,
                        icon: LucideIcons.shieldCheck,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionSection extends StatelessWidget {
  final String label;
  final String helper;
  final List<String> options;
  final RxString selectedValue;
  final IconData icon;

  const _SelectionSection({
    required this.label,
    required this.helper,
    required this.options,
    required this.selectedValue,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return SignupSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SignupSectionLabel(text: label),
          const SizedBox(height: AppSpacing.sm),
          Text(
            helper,
            textAlign: TextAlign.start,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(height: isRtl ? 1.45 : 1.35),
          ),
          const SizedBox(height: AppSpacing.lg),
          Obx(
            () => Column(
              children: options
                  .map(
                    (option) => Padding(
                      padding: EdgeInsets.only(
                        bottom: option == options.last ? 0 : AppSpacing.sm,
                      ),
                      child: SignupChoiceTile(
                        title: option.tr,
                        leading: _FaithOptionIcon(icon: icon),
                        selected: selectedValue.value == option,
                        onTap: () => selectedValue.value = option,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionWrap extends StatelessWidget {
  final String label;
  final List<String> options;
  final RxString selectedValue;
  final IconData icon;

  const _SelectionWrap({
    required this.label,
    required this.options,
    required this.selectedValue,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SignupSectionLabel(text: label),
        const SizedBox(height: AppSpacing.md),
        Obx(
          () => Column(
            children: options
                .map(
                  (option) => Padding(
                    padding: EdgeInsets.only(
                      bottom: option == options.last ? 0 : AppSpacing.sm,
                    ),
                    child: SignupChoiceTile(
                      title: option.tr,
                      leading: _FaithOptionIcon(icon: icon),
                      selected: selectedValue.value == option,
                      onTap: () => selectedValue.value = option,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _FaithOptionIcon extends StatelessWidget {
  const _FaithOptionIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: AppColors.primary),
    );
  }
}
