import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/home_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/widgets/custom_button.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class DiscoveryPreferencesScreen extends StatelessWidget {
  const DiscoveryPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return SettingsSimplePageScaffold(
      title: 'discovery_preferences'.tr,
      footer: CustomButton(
        text: 'apply_preferences'.tr,
        icon: LucideIcons.check,
        onPressed: () {
          controller.saveFilters();
          controller.fetchDiscoverUsers();
          Get.back();
        },
      ),
      body: Obx(
        () => ListView(
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
                  onChanged: (value) => controller.goGlobalFilter.value = value,
                ),
                SettingsPlainTile(
                  title: 'show_me'.tr,
                  value: _genderLabel(controller.genderFilter.value),
                  onTap: () => _showGenderSheet(context, controller),
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
                max: 200,
                divisions: 199,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.primary.withValues(alpha: 0.14),
                onChanged: controller.goGlobalFilter.value
                    ? null
                    : (value) => controller.maxDistance.value = value,
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
                max: 70,
                divisions: 52,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.primary.withValues(alpha: 0.14),
                onChanged: (values) {
                  controller.minAge.value = values.start.round();
                  controller.maxAge.value = values.end.round();
                },
              ),
              helper: 'age_range_helper'.tr,
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsPlainListCard(
              children: [
                SettingsPlainSwitchTile(
                  title: 'verified_only'.tr,
                  subtitle: 'verified_only_desc'.tr,
                  value: controller.verifiedOnlyFilter.value,
                  onChanged: (value) =>
                      controller.verifiedOnlyFilter.value = value,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGenderSheet(
    BuildContext context,
    HomeController controller,
  ) async {
    final selection = await showSettingsChoiceSheet<String>(
      context: context,
      title: 'show_me'.tr,
      options: [
        SettingsSheetOption(
          value: 'all',
          title: 'everyone'.tr,
          selected: controller.genderFilter.value == 'all',
        ),
        SettingsSheetOption(
          value: 'male',
          title: 'men'.tr,
          selected: controller.genderFilter.value == 'male',
        ),
        SettingsSheetOption(
          value: 'female',
          title: 'women'.tr,
          selected: controller.genderFilter.value == 'female',
        ),
      ],
    );

    if (selection != null) {
      controller.genderFilter.value = selection;
    }
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

  String _genderLabel(String value) {
    switch (value) {
      case 'male':
        return 'men'.tr;
      case 'female':
        return 'women'.tr;
      default:
        return 'everyone'.tr;
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
