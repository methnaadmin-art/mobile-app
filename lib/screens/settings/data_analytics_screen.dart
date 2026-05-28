import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/analytics_controller.dart';
import 'package:methna_app/app/data/services/analytics_service.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class DataAnalyticsScreen extends GetView<AnalyticsController> {
  const DataAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSimplePageScaffold(
      title: 'data_analytics'.tr,
      trailing: IconButton(
        onPressed: controller.refresh,
        icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.refresh,
        child: Obx(() {
          final data = controller.data;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                    title: 'data_usage'.tr,
                    subtitle:
                        '${data.totalViews} views, ${data.totalLikes} likes, ${data.totalMatches} matches',
                    onTap: () => _showUsageSheet(context, data),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SettingsSectionLabel(text: 'profile_insights'.tr),
              _AnalyticsSummaryCard(data: data),
              const SizedBox(height: AppSpacing.md),
              SettingsPlainListCard(
                children: [
                  SettingsPlainTile(
                    title: 'how_this_works'.tr,
                    subtitle: 'insights_desc'.tr,
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _showUsageSheet(
    BuildContext context,
    ProfileAnalytics data,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.xl),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.handleDark : AppColors.handleLight,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
              Text(
                'profile_insights'.tr,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _UsageRow(label: 'total_views'.tr, value: '${data.totalViews}'),
              _UsageRow(label: 'total_likes'.tr, value: '${data.totalLikes}'),
              _UsageRow(label: 'total_matches'.tr, value: '${data.totalMatches}'),
              _UsageRow(
                label: 'match_rate'.tr,
                value: '${(data.matchRate * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnalyticsSummaryCard extends StatelessWidget {
  final ProfileAnalytics data;

  const _AnalyticsSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceGlassDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InsightCell(
                  label: 'total_views'.tr,
                  value: '${data.totalViews}',
                ),
              ),
              Expanded(
                child: _InsightCell(
                  label: 'total_likes'.tr,
                  value: '${data.totalLikes}',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _InsightCell(
                  label: 'total_matches'.tr,
                  value: '${data.totalMatches}',
                ),
              ),
              Expanded(
                child: _InsightCell(
                  label: 'match_rate'.tr,
                  value: '${(data.matchRate * 100).toStringAsFixed(1)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightCell extends StatelessWidget {
  final String label;
  final String value;

  const _InsightCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.headlineSmall.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _UsageRow extends StatelessWidget {
  final String label;
  final String value;

  const _UsageRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
