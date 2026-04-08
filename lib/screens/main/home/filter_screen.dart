import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/home_controller.dart';
import 'package:methna_app/app/controllers/signup_data.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/widgets/app_card.dart';
import 'package:methna_app/core/widgets/app_chip.dart';
import 'package:methna_app/core/widgets/custom_button.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class FilterScreen extends GetView<HomeController> {
  const FilterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final monetization = Get.find<MonetizationService>();

    return SettingsSimplePageScaffold(
      title: 'filter_and_show'.tr,
      footer: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'reset'.tr,
              variant: CustomButtonVariant.secondary,
              onPressed: _resetFilters,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: CustomButton(
              text: 'apply'.tr,
              icon: LucideIcons.check,
              onPressed: () {
                controller.saveFilters();
                controller.fetchDiscoverUsers();
                Get.back();
              },
            ),
          ),
        ],
      ),
      body: Obx(() {
        final hasAdvancedFiltersAccess = monetization.hasAdvancedFiltersAccess;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            SettingsPlainListCard(
              children: [
                SettingsPlainTile(
                  title: 'country'.tr,
                  value: _countryValueLabel(controller.countryFilter.value),
                  onTap: () => _showCountryPicker(context),
                ),
                SettingsPlainTile(
                  title: 'city'.tr,
                  value: _cityValueLabel(
                    controller.cityFilter.value,
                    controller.countryFilter.value,
                  ),
                  onTap: () => _showCityPicker(context),
                ),
                SettingsPlainSwitchTile(
                  title: 'go_global'.tr,
                  value: controller.goGlobalFilter.value,
                  onChanged: (value) => controller.goGlobalFilter.value = value,
                ),
                SettingsPlainTile(
                  title: 'show_distance_in'.tr,
                  value: controller.useKm.value ? 'km'.tr : 'miles'.tr,
                  onTap: () => _showUnitPicker(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _RangeCard(
              title: 'distance_range'.tr,
              value:
                  controller.maxDistance.value >=
                      HomeController.distanceFilterUnlimitedKm
                  ? 'unlimited'.tr
                  : '${controller.maxDistance.value.round()} ${controller.useKm.value ? 'km' : 'mi'}',
              child: Slider(
                value: controller.maxDistance.value,
                min: HomeController.distanceFilterMinKm,
                max: HomeController.distanceFilterUnlimitedKm,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.primary.withValues(alpha: 0.15),
                onChanged: (value) => controller.maxDistance.value = value,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _RangeCard(
              title: 'age_range'.tr,
              value: '${controller.minAge.value} - ${controller.maxAge.value}',
              child: RangeSlider(
                values: RangeValues(
                  controller.minAge.value.toDouble(),
                  controller.maxAge.value.toDouble(),
                ),
                min: 18,
                max: 90,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.primary.withValues(alpha: 0.15),
                onChanged: (values) {
                  controller.minAge.value = values.start.round();
                  controller.maxAge.value = values.end.round();
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'lifestyle_tab'.tr,
              style: AppTextStyles.titleMedium.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            hasAdvancedFiltersAccess
                ? _AdvancedFilters(controller: controller)
                : _PremiumGate(),
          ],
        );
      }),
    );
  }

  Future<void> _showCountryPicker(BuildContext context) async {
    final selected = await showSettingsChoiceSheet<String>(
      context: context,
      title: 'country'.tr,
      options: [
        SettingsSheetOption(
          value: '',
          title: 'any'.tr,
          selected: controller.countryFilter.value.trim().isEmpty,
        ),
        ...SignupData.arabicCountries.map(
          (country) => SettingsSheetOption(
            value: country,
            title: country.tr,
            selected: controller.countryFilter.value == country,
          ),
        ),
      ],
    );

    if (selected == null) return;
    controller.countryFilter.value = selected;
    if (selected.isEmpty) {
      controller.cityFilter.value = '';
      return;
    }

    final cities = SignupData.countryCities[selected] ?? const <String>[];
    if (!cities.contains(controller.cityFilter.value)) {
      controller.cityFilter.value = '';
    }
  }

  Future<void> _showCityPicker(BuildContext context) async {
    final selectedCountry = controller.countryFilter.value.trim();
    if (selectedCountry.isEmpty) {
      Get.snackbar('country'.tr, 'select_country_first'.tr);
      return;
    }

    final cities =
        SignupData.countryCities[selectedCountry] ?? const <String>[];
    if (cities.isEmpty) {
      Get.snackbar('city'.tr, 'content_unavailable'.tr);
      return;
    }

    final selected = await showSettingsChoiceSheet<String>(
      context: context,
      title: 'city'.tr,
      options: [
        SettingsSheetOption(
          value: '',
          title: 'any'.tr,
          selected: controller.cityFilter.value.trim().isEmpty,
        ),
        ...cities.map(
          (city) => SettingsSheetOption(
            value: city,
            title: city.tr,
            selected: controller.cityFilter.value == city,
          ),
        ),
      ],
    );

    if (selected != null) {
      controller.cityFilter.value = selected;
    }
  }

  Future<void> _showUnitPicker(BuildContext context) async {
    final selected = await showSettingsChoiceSheet<bool>(
      context: context,
      title: 'show_distance_in'.tr,
      options: [
        SettingsSheetOption(
          value: true,
          title: 'km'.tr,
          selected: controller.useKm.value,
        ),
        SettingsSheetOption(
          value: false,
          title: 'miles'.tr,
          selected: !controller.useKm.value,
        ),
      ],
    );
    if (selected != null) {
      controller.useKm.value = selected;
    }
  }

  void _resetFilters() {
    controller.genderFilter.value = 'all';
    controller.minAge.value = 18;
    controller.maxAge.value = 90;
    controller.maxDistance.value = HomeController.distanceFilterMinKm;
    controller.countryFilter.value = '';
    controller.cityFilter.value = '';
    controller.educationFilter.value = '';
    controller.religiousLevelFilter.value = '';
    controller.prayerFrequencyFilter.value = '';
    controller.marriageIntentionFilter.value = '';
    controller.livingSituationFilter.value = '';
    controller.interestsFilter.clear();
    controller.languagesFilter.clear();
    controller.familyValuesFilter.clear();
    controller.verifiedOnlyFilter.value = false;
    controller.goGlobalFilter.value = false;
    controller.recentlyActiveOnlyFilter.value = false;
    controller.withPhotosOnlyFilter.value = false;
    controller.minTrustScoreFilter.value = 0;
    controller.backgroundCheckOnlyFilter.value = false;
  }

  String _countryValueLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'any'.tr;
    return trimmed.tr;
  }

  String _cityValueLabel(String city, String country) {
    if (country.trim().isEmpty) return 'select_country_first'.tr;
    final trimmed = city.trim();
    if (trimmed.isEmpty) return 'any'.tr;
    return trimmed.tr;
  }
}

class _AdvancedFilters extends StatelessWidget {
  final HomeController controller;

  const _AdvancedFilters({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsPlainListCard(
          children: [
            SettingsPlainTile(
              title: 'education'.tr,
              value: _labelize(
                controller.educationFilter.value,
                fallback: 'any',
              ),
              onTap: () => _pickSingle(
                context,
                title: 'education'.tr,
                current: controller.educationFilter.value,
                values: const [
                  '',
                  'high_school',
                  'bachelors',
                  'masters',
                  'phd',
                ],
                onSelected: (value) => controller.educationFilter.value = value,
              ),
            ),
            SettingsPlainTile(
              title: 'religious_level'.tr,
              value: _labelize(
                controller.religiousLevelFilter.value,
                fallback: 'any',
              ),
              onTap: () => _pickSingle(
                context,
                title: 'religious_level'.tr,
                current: controller.religiousLevelFilter.value,
                values: const [
                  '',
                  'very_practicing',
                  'practicing',
                  'moderate',
                  'liberal',
                ],
                onSelected: (value) =>
                    controller.religiousLevelFilter.value = value,
              ),
            ),
            SettingsPlainTile(
              title: 'prayer_frequency'.tr,
              value: _labelize(
                controller.prayerFrequencyFilter.value,
                fallback: 'any',
              ),
              onTap: () => _pickSingle(
                context,
                title: 'prayer_frequency'.tr,
                current: controller.prayerFrequencyFilter.value,
                values: const [
                  '',
                  'actively_practicing',
                  'occasionally',
                  'not_practicing',
                ],
                onSelected: (value) =>
                    controller.prayerFrequencyFilter.value = value,
              ),
            ),
            SettingsPlainTile(
              title: 'marriage_intention'.tr,
              value: _labelize(
                controller.marriageIntentionFilter.value,
                fallback: 'any',
              ),
              onTap: () => _pickSingle(
                context,
                title: 'marriage_intention'.tr,
                current: controller.marriageIntentionFilter.value,
                values: const [
                  '',
                  'within_months',
                  'within_year',
                  'one_to_two_years',
                  'not_sure',
                  'just_exploring',
                ],
                onSelected: (value) =>
                    controller.marriageIntentionFilter.value = value,
              ),
            ),
            SettingsPlainTile(
              title: 'living_situation'.tr,
              value: _labelize(
                controller.livingSituationFilter.value,
                fallback: 'any',
              ),
              onTap: () => _pickSingle(
                context,
                title: 'living_situation'.tr,
                current: controller.livingSituationFilter.value,
                values: const [
                  '',
                  'alone',
                  'with_family',
                  'with_roommates',
                  'with_spouse',
                ],
                onSelected: (value) =>
                    controller.livingSituationFilter.value = value,
              ),
            ),
            SettingsPlainSwitchTile(
              title: 'verified_only'.tr,
              subtitle: 'verified_only_desc'.tr,
              value: controller.verifiedOnlyFilter.value,
              onChanged: (value) => controller.verifiedOnlyFilter.value = value,
            ),
            SettingsPlainSwitchTile(
              title: 'background_check_only'.tr,
              subtitle: 'background_check_only_desc'.tr,
              value: controller.backgroundCheckOnlyFilter.value,
              onChanged: (value) =>
                  controller.backgroundCheckOnlyFilter.value = value,
            ),
            SettingsPlainSwitchTile(
              title: 'show_recently_active'.tr,
              subtitle: 'show_recently_active_desc'.tr,
              value: controller.recentlyActiveOnlyFilter.value,
              onChanged: (value) =>
                  controller.recentlyActiveOnlyFilter.value = value,
            ),
            SettingsPlainSwitchTile(
              title: 'profiles_with_photos_only'.tr,
              subtitle: 'profiles_with_photos_only_desc'.tr,
              value: controller.withPhotosOnlyFilter.value,
              onChanged: (value) =>
                  controller.withPhotosOnlyFilter.value = value,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _RangeCard(
          title: 'min_trust_score'.tr,
          value: '${controller.minTrustScoreFilter.value}',
          child: Slider(
            value: controller.minTrustScoreFilter.value.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primary.withValues(alpha: 0.15),
            onChanged: (value) =>
                controller.minTrustScoreFilter.value = value.round(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _MultiSelectCard(
          title: 'interests'.tr,
          subtitle: 'filter_shared_interests'.tr,
          options: SignupData.hobbiesList,
          selected: controller.interestsFilter,
        ),
        const SizedBox(height: AppSpacing.md),
        _MultiSelectCard(
          title: 'languages'.tr,
          subtitle: 'prioritize_preferred_languages'.tr,
          options: SignupData.languagesList,
          selected: controller.languagesFilter,
        ),
        const SizedBox(height: AppSpacing.md),
        _MultiSelectCard(
          title: 'family_values'.tr,
          subtitle: 'match_family_values'.tr,
          options: SignupData.familyValuesOptions,
          selected: controller.familyValuesFilter,
        ),
      ],
    );
  }

  static Future<void> _pickSingle(
    BuildContext context, {
    required String title,
    required String current,
    required List<String> values,
    required ValueChanged<String> onSelected,
  }) async {
    final selected = await showSettingsChoiceSheet<String>(
      context: context,
      title: title,
      options: values
          .map(
            (value) => SettingsSheetOption(
              value: value,
              title: _labelize(value, fallback: 'any'),
              selected: current == value,
            ),
          )
          .toList(growable: false),
    );
    if (selected != null) onSelected(selected);
  }

  static String _labelize(String value, {String fallback = 'any'}) {
    if (value.trim().isEmpty) return fallback.tr;
    final translated = value.tr;
    if (translated != value) return translated;
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}

class _MultiSelectCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> options;
  final RxList<String> selected;

  const _MultiSelectCard({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Get.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(subtitle, style: Get.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Obx(
            () => Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: options
                  .map((option) {
                    final isSelected = selected.contains(option);
                    return MethnaChip(
                      label: option,
                      selected: isSelected,
                      icon: isSelected ? LucideIcons.check : null,
                      onTap: () {
                        if (isSelected) {
                          selected.remove(option);
                        } else {
                          selected.add(option);
                        }
                      },
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

class _PremiumGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 22,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.premium.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.lock,
              color: AppColors.premium,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'unlock_advanced_filters'.tr,
            style: Get.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'advanced_filters_premium_desc'.tr,
            textAlign: TextAlign.center,
            style: Get.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomButton(
            text: 'upgrade_to_premium'.tr,
            backgroundColor: AppColors.premium,
            gradient: null,
            onPressed: () => Get.toNamed(AppRoutes.subscription),
          ),
        ],
      ),
    );
  }
}

class _RangeCard extends StatelessWidget {
  final String title;
  final String value;
  final Widget child;

  const _RangeCard({
    required this.title,
    required this.value,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceGlassDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              Text(
                value,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}
