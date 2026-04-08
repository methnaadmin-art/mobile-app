import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class StaticContentScreen extends GetView<SettingsController> {
  final String title;
  final String contentType;

  const StaticContentScreen({
    super.key,
    required this.title,
    required this.contentType,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSimplePageScaffold(
      title: title,
      body: FutureBuilder<String?>(
        future: controller.fetchAppContent(contentType),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final isDark = Theme.of(context).brightness == Brightness.dark;

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
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
                      title: 'content_unavailable'.tr,
                    ),
                  ],
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceGlassDark : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                child: Text(
                  snapshot.data!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.65,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
