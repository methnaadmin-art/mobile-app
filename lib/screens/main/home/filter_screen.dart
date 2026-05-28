import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:country_picker/country_picker.dart';
import 'package:methna_app/app/controllers/home_controller.dart';
import 'package:methna_app/app/controllers/signup_data.dart';
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
    return SettingsSimplePageScaffold(
      title: 'filter_and_show'.tr,
      footer: Obx(() {
        final isApplying = controller.isApplyingFilters.value;

        return Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'reset'.tr,
                variant: CustomButtonVariant.secondary,
                onPressed: isApplying ? null : _resetFilters,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: CustomButton(
                text: isApplying ? 'Applying...' : 'apply'.tr,
                icon: isApplying ? null : LucideIcons.check,
                onPressed: isApplying
                    ? null
                    : () => controller.applyFiltersAndRefresh(),
              ),
            ),
          ],
        );
      }),
      body: Obx(() {
        final hasAdvancedFiltersAccess = controller.hasAdvancedFilterAccess;
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
                  subtitle: 'country_filter_info'.tr,
                  value: _countryValueLabel(
                    controller.countryFilter.value,
                    controller.countryCodeFilter.value,
                  ),
                  onTap: () => _showCountryPicker(context),
                  trailing: controller.countryFilter.value.trim().isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: AppColors.textSecondaryLight,
                          ),
                          onPressed: () {
                            controller.clearCountryFilter();
                            _scheduleLiveApply();
                          },
                        )
                      : null,
                ),
                SettingsPlainTile(
                  title: 'city'.tr,
                  value: _cityValueLabel(
                    controller.cityFilter.value,
                    controller.countryFilter.value,
                  ),
                  onTap: () => _showCityPicker(context),
                ),
                SettingsPlainTile(
                  title: 'marital_status'.tr,
                  value: _AdvancedFilters.labelizeMapped(
                    controller.maritalStatusFilter.value,
                    _AdvancedFilters.maritalStatusLabels,
                    fallback: 'all',
                  ),
                  onTap: () => _AdvancedFilters.pickSingleLabeled(
                    context,
                    title: 'marital_status'.tr,
                    current: controller.maritalStatusFilter.value,
                    labels: _AdvancedFilters.maritalStatusLabels,
                    onSelected: (value) {
                      controller.maritalStatusFilter.value = value;
                      _scheduleLiveApply();
                    },
                  ),
                ),
                SettingsPlainTile(
                  title: 'Ethnicity',
                  value: controller.ethnicityFilter.value.trim().isEmpty
                      ? 'all'.tr
                      : controller.ethnicityFilter.value,
                  onTap: () => _AdvancedFilters.pickSingle(
                    context,
                    title: 'Ethnicity',
                    current: controller.ethnicityFilter.value,
                    values: <String>['', ...SignupData.ethnicities],
                    onSelected: (value) {
                      controller.ethnicityFilter.value = value;
                      _scheduleLiveApply();
                    },
                  ),
                ),
                hasAdvancedFiltersAccess
                    ? SettingsPlainSwitchTile(
                        title: 'go_global'.tr,
                        subtitle: 'go_global_desc'.tr,
                        value: controller.goGlobalFilter.value,
                        onChanged: (value) {
                          controller.goGlobalFilter.value = value;
                          _scheduleLiveApply();
                        },
                      )
                    : SettingsPlainTile(
                        title: 'go_global'.tr,
                        subtitle: 'go_global_desc'.tr,
                        value: 'premium_plan'.tr,
                        onTap: () => Get.toNamed(AppRoutes.subscription),
                        leading: const Icon(
                          LucideIcons.lock,
                          size: 18,
                          color: AppColors.premium,
                        ),
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
                  '${controller.maxDistance.value.round()} ${controller.useKm.value ? 'km' : 'mi'}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Slider(
                    value: controller.maxDistance.value,
                    min: HomeController.distanceFilterMinKm,
                    max: HomeController.distanceFilterUnlimitedKm,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.primary.withValues(alpha: 0.15),
                    onChanged: (value) => controller.maxDistance.value = value,
                    onChangeEnd: (_) {
                      controller.distanceFilterUserSet.value = true;
                      _scheduleLiveApply();
                    },
                  ),
                  Text(
                    controller.goGlobalFilter.value
                        ? 'distance_ignored_global'.tr
                        : 'distance_helper'.tr,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
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
                onChangeEnd: (_) => _scheduleLiveApply(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _RangeCard(
              title: 'time_frame'.tr,
              value: controller.timeFrameLabel,
              child: Slider(
                value: controller.timeFrameIndex.value.toDouble(),
                min: 0,
                max: 5,
                divisions: 5,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.primary.withValues(alpha: 0.15),
                onChanged: (value) =>
                    controller.onTimeFrameChanged(value.round()),
                onChangeEnd: (_) => _scheduleLiveApply(),
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
            SettingsPlainListCard(
              children: [
                SettingsPlainTile(
                  title: 'living_situation'.tr,
                  value: _AdvancedFilters.labelize(
                    controller.livingSituationFilter.value,
                    fallback: 'all',
                  ),
                  onTap: () => _AdvancedFilters.pickSingle(
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
                    onSelected: (value) {
                      controller.livingSituationFilter.value = value;
                      controller.scheduleLiveFilterRefresh();
                    },
                  ),
                ),
                SettingsPlainSwitchTile(
                  title: 'verified_only'.tr,
                  subtitle: 'verified_only_desc'.tr,
                  value: controller.verifiedOnlyFilter.value,
                  onChanged: (value) {
                    controller.verifiedOnlyFilter.value = value;
                    controller.scheduleLiveFilterRefresh();
                  },
                ),
                SettingsPlainSwitchTile(
                  title: 'background_check_only'.tr,
                  subtitle: 'background_check_only_desc'.tr,
                  value: controller.backgroundCheckOnlyFilter.value,
                  onChanged: (value) {
                    controller.backgroundCheckOnlyFilter.value = value;
                    controller.scheduleLiveFilterRefresh();
                  },
                ),
                SettingsPlainSwitchTile(
                  title: 'show_recently_active'.tr,
                  subtitle: 'show_recently_active_desc'.tr,
                  value: controller.recentlyActiveOnlyFilter.value,
                  onChanged: (value) {
                    controller.recentlyActiveOnlyFilter.value = value;
                    controller.scheduleLiveFilterRefresh();
                  },
                ),
                SettingsPlainSwitchTile(
                  title: 'profiles_with_photos_only'.tr,
                  subtitle: 'profiles_with_photos_only_desc'.tr,
                  value: controller.withPhotosOnlyFilter.value,
                  onChanged: (value) {
                    controller.withPhotosOnlyFilter.value = value;
                    controller.scheduleLiveFilterRefresh();
                  },
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
                onChangeEnd: (_) => controller.scheduleLiveFilterRefresh(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Premium filters are ALWAYS visible. For free users, they are
            // rendered disabled + blurred with an overlay CTA so the user
            // can see what's behind the paywall.
            hasAdvancedFiltersAccess
                ? _AdvancedFilters(controller: controller)
                : _LockedAdvancedFilters(controller: controller),
          ],
        );
      }),
    );
  }

  Future<void> _showCountryPicker(BuildContext context) async {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      onSelect: (Country country) {
        controller.setCountryFilter(
          country.name,
          countryCode: country.countryCode,
          isUserAction: true,
        );
        _scheduleLiveApply();
      },
    );
  }

  Future<void> _showCityPicker(BuildContext context) async {
    if (controller.countryFilter.value.trim().isEmpty) {
      Get.snackbar('country'.tr, 'select_country_first'.tr);
      return;
    }

    final cityController = TextEditingController(
      text: controller.cityFilter.value,
    );
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('enter_city'.tr),
        content: TextField(
          controller: cityController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'city_filter_hint'.tr,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, cityController.text.trim()),
            child: Text('apply'.tr),
          ),
        ],
      ),
    );

    if (selected != null) {
      controller.cityFilter.value = selected.trim();
      _scheduleLiveApply();
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
    controller.resetFiltersAndRefresh();
  }

  void _scheduleLiveApply() {
    controller.scheduleLiveFilterRefresh();
  }

  String _countryValueLabel(String value, String countryCode) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'all'.tr;
    final normalizedCode = countryCode.trim().toUpperCase();
    if (normalizedCode.isEmpty) return trimmed;
    return '$trimmed ($normalizedCode)';
  }

  String _cityValueLabel(String city, String country) {
    if (country.trim().isEmpty) return 'select_country_first'.tr;
    final trimmed = city.trim();
    if (trimmed.isEmpty) return 'all'.tr;
    return trimmed.tr;
  }
}

class _AdvancedFilters extends StatelessWidget {
  final HomeController controller;

  const _AdvancedFilters({required this.controller});

  static const Map<String, String> _educationLabels = {
    '': 'All',
    'high_school': 'High School',
    'bachelors': 'Bachelors',
    'masters': 'Masters',
    'phd': 'Doctorate',
    'doctorate': 'Doctorate',
    'islamic_studies': 'Islamic Studies',
    'other': 'Other',
  };

  static const Map<String, String> _religiousLevelLabels = {
    '': 'All',
    'very_practicing': 'Very Practicing',
    'practicing': 'Practicing',
    'moderate': 'Moderate',
    'liberal': 'Liberal',
  };

  static const Map<String, String> _prayerFrequencyLabels = {
    '': 'All',
    'actively_practicing': 'Actively Practicing',
    'occasionally': 'Occasionally',
    'not_practicing': 'Not Practicing',
  };

  static const Map<String, String> maritalStatusLabels = {
    '': 'All',
    'never_married': 'Never Married',
    'married': 'Married',
    'divorced': 'Divorced',
    'widowed': 'Widowed',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsPlainListCard(
          children: [
            SettingsPlainTile(
              title: 'education'.tr,
              value: labelizeMapped(
                controller.educationFilter.value,
                _educationLabels,
                fallback: 'all',
              ),
              onTap: () => pickSingleLabeled(
                context,
                title: 'education'.tr,
                current: controller.educationFilter.value,
                labels: _educationLabels,
                onSelected: (value) {
                  controller.educationFilter.value = value;
                  controller.scheduleLiveFilterRefresh();
                },
              ),
            ),
            SettingsPlainTile(
              title: 'religious_level'.tr,
              value: labelizeMapped(
                controller.religiousLevelFilter.value,
                _religiousLevelLabels,
                fallback: 'all',
              ),
              onTap: () => pickSingleLabeled(
                context,
                title: 'religious_level'.tr,
                current: controller.religiousLevelFilter.value,
                labels: _religiousLevelLabels,
                onSelected: (value) {
                  controller.religiousLevelFilter.value = value;
                  controller.scheduleLiveFilterRefresh();
                },
              ),
            ),
            SettingsPlainTile(
              title: 'prayer_frequency'.tr,
              value: labelizeMapped(
                controller.prayerFrequencyFilter.value,
                _prayerFrequencyLabels,
                fallback: 'all',
              ),
              onTap: () => pickSingleLabeled(
                context,
                title: 'prayer_frequency'.tr,
                current: controller.prayerFrequencyFilter.value,
                labels: _prayerFrequencyLabels,
                onSelected: (value) {
                  controller.prayerFrequencyFilter.value = value;
                  controller.scheduleLiveFilterRefresh();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _MultiSelectCard(
          title: 'interests'.tr,
          subtitle: 'filter_shared_interests'.tr,
          options: SignupData.hobbiesList,
          selected: controller.interestsFilter,
          onSelectionChanged: controller.scheduleLiveFilterRefresh,
        ),
        const SizedBox(height: AppSpacing.md),
        _MultiSelectCard(
          title: 'languages'.tr,
          subtitle: 'prioritize_preferred_languages'.tr,
          options: SignupData.languagesList,
          selected: controller.languagesFilter,
          onSelectionChanged: controller.scheduleLiveFilterRefresh,
        ),
        const SizedBox(height: AppSpacing.md),
        _MultiSelectCard(
          title: 'family_values'.tr,
          subtitle: 'match_family_values'.tr,
          options: SignupData.familyValuesOptions,
          selected: controller.familyValuesFilter,
          onSelectionChanged: controller.scheduleLiveFilterRefresh,
        ),
        const SizedBox(height: AppSpacing.md),
        _MultiSelectCard(
          title: 'communication_styles'.tr,
          subtitle: 'filter_communication_styles'.tr,
          options: SignupData.communicationStylesList,
          selected: controller.communicationStylesFilter,
          maxSelection: 2,
          onSelectionChanged: controller.scheduleLiveFilterRefresh,
        ),
      ],
    );
  }

  static Future<void> pickSingleLabeled(
    BuildContext context, {
    required String title,
    required String current,
    required Map<String, String> labels,
    required ValueChanged<String> onSelected,
  }) async {
    final selected = await showSettingsChoiceSheet<String>(
      context: context,
      title: title,
      options: labels.entries
          .map(
            (entry) => SettingsSheetOption(
              value: entry.key,
              title: entry.key.trim().isEmpty ? 'all'.tr : entry.value,
              selected: current == entry.key,
            ),
          )
          .toList(growable: false),
    );
    if (selected != null) onSelected(selected);
  }

  static Future<void> pickSingle(
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
              title: labelize(value, fallback: 'all'),
              selected: current == value,
            ),
          )
          .toList(growable: false),
    );
    if (selected != null) onSelected(selected);
  }

  static String labelizeMapped(
    String value,
    Map<String, String> labels, {
    String fallback = 'all',
  }) {
    if (value.trim().isEmpty) return fallback.tr;
    final direct = labels[value.trim()];
    if (direct != null && direct.trim().isNotEmpty) {
      return direct;
    }
    return labelize(value, fallback: fallback);
  }

  static String labelize(String value, {String fallback = 'all'}) {
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
  final int? maxSelection;
  final VoidCallback? onSelectionChanged;

  const _MultiSelectCard({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    this.maxSelection,
    this.onSelectionChanged,
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
                          selected.removeWhere((item) => item == option);
                        } else {
                          if (maxSelection != null &&
                              selected.length >= maxSelection!) {
                            Get.snackbar(
                              'communication_styles'.tr,
                              'max_communication_styles_selected'.tr,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            return;
                          }
                          selected.add(option);
                        }
                        selected.assignAll(
                          selected
                              .map((item) => item.trim())
                              .where((item) => item.isNotEmpty)
                              .toSet()
                              .toList(growable: false),
                        );
                        onSelectionChanged?.call();
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

class _LockedAdvancedFilters extends StatelessWidget {
  const _LockedAdvancedFilters({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Render the real advanced filters underneath, but non-interactive
        // and dimmed so free users can see what's behind the paywall.
        IgnorePointer(
          ignoring: true,
          child: Opacity(
            opacity: 0.45,
            child: _AdvancedFilters(controller: controller),
          ),
        ),
        // Overlay CTA on top.
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppCard(
                radius: 22,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.premium.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.lock,
                        color: AppColors.premium,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'unlock_advanced_filters'.tr,
                      style: Get.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'advanced_filters_premium_desc'.tr,
                      textAlign: TextAlign.center,
                      style: Get.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CustomButton(
                      text: 'upgrade_to_premium'.tr,
                      backgroundColor: AppColors.premium,
                      gradient: null,
                      onPressed: () => Get.toNamed(AppRoutes.subscription),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
        color: isDark
            ? AppColors.surfaceGlassDark
            : AppColors.surfaceMutedLight,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: const Color(0x1A6B7AB0),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
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
