import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/controllers/signup_data.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/utils/profile_option_icons.dart';
import 'package:methna_app/core/widgets/signup_flow.dart';

class FaithReligionScreen extends GetView<SignupController> {
  const FaithReligionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller.syncStep(AppRoutes.signupFaithReligion);

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
          secondaryLabel: 'skip_for_now'.tr,
          onSecondary: busy ? null : controller.skipCurrentOptionalStep,
        );
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SignupHeroCard(
            badge: '07 / 12',
            icon: LucideIcons.bookOpen,
            title: 'faith_and_religion'.tr,
            description: '',
          ),
          const SizedBox(height: AppSpacing.xl),
          _SelectionSection(
            label: 'sect_label'.tr,
            helper: '',
            options: SignupData.sects,
            selectedValue: controller.selectedSect,
            icon: faithOptionIcon('sect'),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SelectionSection(
            label: 'religious_level_label'.tr,
            helper: '',
            options: SignupData.religiousLevels,
            selectedValue: controller.selectedReligiousLevel,
            icon: faithOptionIcon('religious level'),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SelectionSection(
            label: 'prayer_frequency_label'.tr,
            helper: '',
            options: SignupData.prayerFrequencies,
            selectedValue: controller.selectedPrayerFrequency,
            icon: faithOptionIcon('prayer frequency'),
          ),
          const SizedBox(height: AppSpacing.lg),
          SignupSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SignupSectionLabel(text: 'lifestyle_label'.tr),
                const SizedBox(height: AppSpacing.lg),
                _SelectionWrap(
                  label: 'dietary_label'.tr,
                  options: SignupData.dietaryPreferences,
                  selectedValue: controller.selectedDietary,
                  icon: faithOptionIcon('dietary'),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SelectionWrap(
                  label: 'alcohol_label'.tr,
                  options: SignupData.alcoholPreferences,
                  selectedValue: controller.selectedAlcohol,
                  icon: faithOptionIcon('alcohol'),
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
                        icon: faithOptionIcon('hijab'),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
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
    final hasHelper = helper.trim().isNotEmpty;

    return SignupSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SignupSectionLabel(text: label),
          if (hasHelper) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              helper,
              textAlign: TextAlign.start,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: isRtl ? 1.45 : 1.35),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Obx(
            () => Column(
              children: options
                  .map((option) {
                    final selected = selectedValue.value == option;
                    final visual = _faithVisualForOption(
                      option,
                      fallback: icon,
                    );
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: option == options.last ? 0 : AppSpacing.sm,
                      ),
                      child: SignupChoiceTile(
                        title: option.tr,
                        leading: _FaithOptionIcon(
                          icon: visual.icon,
                          accent: visual.accent,
                          selected: selected,
                        ),
                        selected: selected,
                        onTap: () =>
                            selectedValue.value = selected ? '' : option,
                      ),
                    );
                  })
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
                .map((option) {
                  final selected = selectedValue.value == option;
                  final visual = _faithVisualForOption(option, fallback: icon);
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: option == options.last ? 0 : AppSpacing.sm,
                    ),
                    child: SignupChoiceTile(
                      title: option.tr,
                      leading: _FaithOptionIcon(
                        icon: visual.icon,
                        accent: visual.accent,
                        selected: selected,
                      ),
                      selected: selected,
                      onTap: () => selectedValue.value = selected ? '' : option,
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _FaithOptionIcon extends StatelessWidget {
  const _FaithOptionIcon({
    required this.icon,
    required this.accent,
    required this.selected,
  });

  final IconData icon;
  final Color accent;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? Colors.white : accent;
    final borderColor = selected
        ? Colors.white.withValues(alpha: 0.36)
        : accent.withValues(alpha: 0.30);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: selected
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.22),
                  accent.withValues(alpha: 0.10),
                ],
              ),
        color: selected ? Colors.white.withValues(alpha: 0.20) : null,
        border: Border.all(color: borderColor),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: selected ? 0.24 : 0.14),
            blurRadius: selected ? 10 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, size: 17, color: iconColor),
    );
  }
}

class _FaithVisual {
  const _FaithVisual({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;
}

_FaithVisual _faithVisualForOption(
  String option, {
  required IconData fallback,
}) {
  final key = option
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();

  switch (key) {
    case 'sunni':
      return const _FaithVisual(
        icon: Icons.menu_book_rounded,
        accent: AppColors.primary,
      );
    case 'shia':
      return const _FaithVisual(
        icon: Icons.mosque_outlined,
        accent: AppColors.secondary,
      );
    case 'sufi':
      return const _FaithVisual(
        icon: Icons.self_improvement_rounded,
        accent: AppColors.primaryLight,
      );
    case 'other':
      return const _FaithVisual(
        icon: Icons.more_horiz_rounded,
        accent: AppColors.primaryDark,
      );
    case 'prefer not to say':
      return const _FaithVisual(
        icon: Icons.visibility_off_outlined,
        accent: AppColors.primaryDark,
      );
    case 'very practicing':
      return const _FaithVisual(
        icon: Icons.stars_rounded,
        accent: AppColors.secondary,
      );
    case 'practicing':
      return const _FaithVisual(
        icon: Icons.favorite_outline_rounded,
        accent: AppColors.primary,
      );
    case 'moderate':
      return const _FaithVisual(
        icon: Icons.tune_rounded,
        accent: AppColors.primaryLight,
      );
    case 'liberal':
      return const _FaithVisual(
        icon: Icons.explore_outlined,
        accent: AppColors.primaryDark,
      );
    case 'actively practicing':
      return const _FaithVisual(
        icon: Icons.schedule_rounded,
        accent: AppColors.primary,
      );
    case 'occasionally':
      return const _FaithVisual(
        icon: Icons.timelapse_rounded,
        accent: AppColors.primaryLight,
      );
    case 'not practicing':
      return const _FaithVisual(
        icon: Icons.pause_circle_outline_rounded,
        accent: AppColors.primaryDark,
      );
    case 'halal':
      return const _FaithVisual(
        icon: Icons.verified_rounded,
        accent: AppColors.secondary,
      );
    case 'non strict':
      return const _FaithVisual(
        icon: Icons.restaurant_menu_rounded,
        accent: AppColors.primaryLight,
      );
    case 'doesnt drink':
      return const _FaithVisual(
        icon: Icons.no_drinks_rounded,
        accent: AppColors.secondary,
      );
    case 'drinks':
      return const _FaithVisual(
        icon: Icons.local_bar_rounded,
        accent: AppColors.primaryDark,
      );
    case 'covered':
      return const _FaithVisual(
        icon: Icons.checkroom_rounded,
        accent: AppColors.primary,
      );
    case 'niqab':
      return const _FaithVisual(
        icon: Icons.shield_rounded,
        accent: AppColors.secondary,
      );
    case 'not covered':
      return const _FaithVisual(
        icon: Icons.person_outline_rounded,
        accent: AppColors.primaryDark,
      );
  }

  if (key.contains('sunni')) {
    return const _FaithVisual(
      icon: Icons.menu_book_rounded,
      accent: AppColors.primary,
    );
  }
  if (key.contains('shia')) {
    return const _FaithVisual(
      icon: Icons.mosque_outlined,
      accent: AppColors.secondary,
    );
  }
  if (key.contains('sufi')) {
    return const _FaithVisual(
      icon: Icons.self_improvement_rounded,
      accent: AppColors.primaryLight,
    );
  }
  if (key.contains('very')) {
    return const _FaithVisual(
      icon: LucideIcons.badgeCheck,
      accent: AppColors.secondary,
    );
  }
  if (key.contains('practicing')) {
    return const _FaithVisual(
      icon: LucideIcons.flame,
      accent: AppColors.primary,
    );
  }
  if (key.contains('moderate')) {
    return const _FaithVisual(
      icon: LucideIcons.scale,
      accent: AppColors.primaryLight,
    );
  }
  if (key.contains('liberal')) {
    return const _FaithVisual(
      icon: LucideIcons.sun,
      accent: AppColors.primaryDark,
    );
  }
  if (key.contains('actively')) {
    return const _FaithVisual(
      icon: LucideIcons.sunrise,
      accent: AppColors.primary,
    );
  }
  if (key.contains('occasionally')) {
    return const _FaithVisual(
      icon: LucideIcons.clock3,
      accent: AppColors.primaryLight,
    );
  }
  if (key.contains('not')) {
    return const _FaithVisual(
      icon: LucideIcons.moon,
      accent: AppColors.primaryDark,
    );
  }
  if (key.contains('halal')) {
    return const _FaithVisual(
      icon: LucideIcons.utensils,
      accent: AppColors.secondary,
    );
  }
  if (key.contains('strict')) {
    return const _FaithVisual(
      icon: LucideIcons.salad,
      accent: AppColors.primaryLight,
    );
  }
  if (key.contains('drink')) {
    return const _FaithVisual(
      icon: LucideIcons.cupSoda,
      accent: AppColors.primaryDark,
    );
  }
  if (key.contains('doesnt')) {
    return const _FaithVisual(
      icon: LucideIcons.shield,
      accent: AppColors.secondary,
    );
  }
  if (key.contains('niqab')) {
    return const _FaithVisual(
      icon: LucideIcons.shirt,
      accent: AppColors.secondary,
    );
  }
  if (key.contains('covered')) {
    return const _FaithVisual(
      icon: LucideIcons.shirt,
      accent: AppColors.primary,
    );
  }
  if (key.contains('other') || key.contains('prefer')) {
    return const _FaithVisual(
      icon: LucideIcons.circleEllipsis,
      accent: AppColors.primaryDark,
    );
  }

  return _FaithVisual(
    icon: fallback == Icons.auto_awesome_rounded
        ? Icons.menu_book_rounded
        : fallback,
    accent: AppColors.primary,
  );
}
