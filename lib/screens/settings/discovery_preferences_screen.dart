import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/signup_data.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/data/services/location_service.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:methna_app/app/controllers/home_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/widgets/app_card.dart';
import 'package:methna_app/core/widgets/custom_button.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class DiscoveryPreferencesScreen extends StatelessWidget {
  const DiscoveryPreferencesScreen({super.key});

  String _defaultCountryLabel() {
    final auth = Get.isRegistered<AuthService>()
        ? Get.find<AuthService>()
        : null;
    final location = Get.isRegistered<LocationService>()
        ? Get.find<LocationService>()
        : null;
    final profileCountry =
        auth?.currentUser.value?.profile?.country?.trim() ?? '';
    if (profileCountry.isNotEmpty) return profileCountry;
    final locationCountry = location?.currentCountry.value.trim() ?? '';
    if (locationCountry.isNotEmpty) return locationCountry;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return SettingsSimplePageScaffold(
      title: 'discovery_preferences'.tr,
      subtitle: 'discovery_preferences_subtitle'.tr,
      footer: Obx(() {
        final isApplying = controller.isApplyingFilters.value;

        return CustomButton(
          text: 'apply_preferences'.tr,
          icon: LucideIcons.check,
          isLoading: isApplying,
          onPressed: isApplying
              ? null
              : () => controller.applyFiltersAndRefresh(),
        );
      }),
      body: Obx(() {
        final defaultCountry = _defaultCountryLabel();

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
                  title: 'location'.tr,
                  subtitle: controller.locationGranted.value
                      ? 'location_on_desc'.tr
                      : 'location_off_desc'.tr,
                  value: controller.locationGranted.value ? 'on'.tr : 'off'.tr,
                  onTap: controller.requestLocationAndFetch,
                ),
                SettingsPlainSwitchTile(
                  title: 'go_global'.tr,
                  subtitle: 'go_global_desc'.tr,
                  value: controller.goGlobalFilter.value,
                  onChanged: (value) {
                    controller.goGlobalFilter.value = value;
                    controller.scheduleLiveFilterRefresh();
                  },
                ),
                SettingsPlainTile(
                  title: 'show_distance_in'.tr,
                  value: controller.useKm.value ? 'km'.tr : 'miles'.tr,
                  onTap: () => _showDistanceUnitSheet(context, controller),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _SliderCard(
              title: 'distance_radius'.tr,
              value:
                  '${controller.maxDistance.value.round()} ${controller.useKm.value ? 'km' : 'mi'}',
              slider: Slider(
                value: controller.maxDistance.value,
                min: 1,
                max: 400,
                divisions: 399,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.primary.withValues(alpha: 0.14),
                onChanged: controller.goGlobalFilter.value
                    ? null
                    : (value) => controller.maxDistance.value = value,
                onChangeEnd: controller.goGlobalFilter.value
                    ? null
                    : (_) => controller.scheduleLiveFilterRefresh(),
              ),
              helper: controller.goGlobalFilter.value
                  ? 'distance_ignored_global'.tr
                  : 'distance_helper'.tr,
            ),
            const SizedBox(height: AppSpacing.md),
            _SliderCard(
              title: 'age_range'.tr,
              value: '${controller.minAge.value} - ${controller.maxAge.value}',
              slider: RangeSlider(
                values: RangeValues(
                  controller.minAge.value.toDouble(),
                  controller.maxAge.value.toDouble(),
                ),
                min: 18,
                max: 90,
                divisions: 72,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.primary.withValues(alpha: 0.14),
                onChanged: (values) {
                  controller.minAge.value = values.start.round();
                  controller.maxAge.value = values.end.round();
                },
                onChangeEnd: (_) => controller.scheduleLiveFilterRefresh(),
              ),
              helper: 'age_range_helper'.tr,
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsPlainListCard(
              children: [
                SettingsPlainTile(
                  title: 'country'.tr,
                  subtitle: controller.countryFilter.value.isEmpty
                      ? (defaultCountry.isEmpty ? 'all'.tr : defaultCountry)
                      : controller.countryFilter.value,
                  value: controller.countryFilter.value.isEmpty
                      ? (defaultCountry.isEmpty ? 'all'.tr : defaultCountry)
                      : controller.countryFilter.value,
                  onTap: () => _showCountryPicker(context, controller),
                  trailing: controller.countryFilter.value.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: AppColors.textSecondaryLight,
                          ),
                          onPressed: () {
                            controller.clearCountryFilter();
                            controller.scheduleLiveFilterRefresh();
                          },
                        )
                      : null,
                ),
                SettingsPlainTile(
                  title: 'city'.tr,
                  subtitle: controller.cityFilter.value.isEmpty
                      ? (_resolvedCountry(controller, defaultCountry).isEmpty
                            ? 'select_country_first'.tr
                            : 'city_filter_all'.tr)
                      : controller.cityFilter.value,
                  value: controller.cityFilter.value.isEmpty
                      ? (_resolvedCountry(controller, defaultCountry).isEmpty
                            ? 'select_country_first'.tr
                            : 'all'.tr)
                      : controller.cityFilter.value,
                  onTap: () =>
                      _showCityPicker(context, controller, defaultCountry),
                  trailing: controller.cityFilter.value.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: AppColors.textSecondaryLight,
                          ),
                          onPressed: () {
                            controller.cityFilter.value = '';
                            controller.scheduleLiveFilterRefresh();
                          },
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsPlainListCard(
              children: [
                SettingsPlainSwitchTile(
                  title: 'verified_only'.tr,
                  subtitle: 'verified_only_desc'.tr,
                  value: controller.verifiedOnlyFilter.value,
                  onChanged: (value) {
                    controller.verifiedOnlyFilter.value = value;
                    controller.scheduleLiveFilterRefresh();
                  },
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Future<void> _showDistanceUnitSheet(
    BuildContext context,
    HomeController controller,
  ) async {
    final selection = await showSettingsChoiceSheet<bool>(
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

    if (selection != null) {
      controller.useKm.value = selection;
    }
  }

  void _showCountryPicker(BuildContext context, HomeController controller) {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        controller.setCountryFilter(
          country.name,
          countryCode: country.countryCode,
          isUserAction: true,
        );
        controller.scheduleLiveFilterRefresh();
      },
    );
  }

  Future<void> _showCityPicker(
    BuildContext context,
    HomeController controller,
    String defaultCountry,
  ) async {
    final resolvedCountry = _resolvedCountry(controller, defaultCountry);
    if (resolvedCountry.isEmpty) {
      Get.snackbar('country'.tr, 'select_country_first'.tr);
      return;
    }

    final cities =
        (SignupData.countryCities[resolvedCountry] ?? const <String>[])
            .map((city) => city.trim())
            .where((city) => city.isNotEmpty)
            .toList(growable: false);
    if (cities.isEmpty) {
      Get.snackbar('city'.tr, 'select_country_first'.tr);
      return;
    }

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('city'.tr, style: AppTextStyles.titleLarge),
                const SizedBox(height: 12),
                SizedBox(
                  height: MediaQuery.of(sheetContext).size.height * 0.45,
                  child: ListView.separated(
                    itemCount: cities.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (_, index) {
                      final city = cities[index];
                      final selected =
                          city == controller.cityFilter.value.trim();
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(sheetContext).pop(city),
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.borderLight,
                              ),
                              color: selected
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text(city)),
                                if (selected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null && result.trim().isNotEmpty) {
      if (controller.countryFilter.value.trim().isEmpty) {
        controller.setCountryFilter(
          resolvedCountry,
          countryCode: _countryCodeForName(resolvedCountry),
          isUserAction: false,
        );
      }
      controller.cityFilter.value = result;
      controller.scheduleLiveFilterRefresh();
    }
  }

  String _resolvedCountry(HomeController controller, String defaultCountry) {
    final explicit = controller.countryFilter.value.trim();
    if (explicit.isNotEmpty) return explicit;
    return defaultCountry.trim();
  }

  String _countryCodeForName(String country) {
    try {
      return CountryService().findByName(country)?.countryCode ?? '';
    } catch (_) {
      return '';
    }
  }
}

class _SliderCard extends StatelessWidget {
  final String title;
  final String value;
  final Widget slider;
  final String helper;

  const _SliderCard({
    required this.title,
    required this.value,
    required this.slider,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      radius: AppRadii.lg,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            helper,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          slider,
        ],
      ),
    );
  }
}
