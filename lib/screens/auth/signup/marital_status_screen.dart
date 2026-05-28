import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/controllers/signup_data.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/widgets/signup_flow.dart';

class MaritalStatusScreen extends GetView<SignupController> {
  const MaritalStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller.syncStep(AppRoutes.signupMaritalStatus);

    return Obx(() {
      final isFemale =
          controller.selectedGender.value.toLowerCase() == 'female';
      final maleOrder = const [
        'Never Married',
        'Married',
        'Divorced',
        'Widowed',
      ];
      final femaleOrder = const ['Never Married', 'Divorced', 'Widowed'];
      final source = SignupData.maritalStatuses.toSet();
      final statuses = (isFemale ? femaleOrder : maleOrder)
          .where(source.contains)
          .toList(growable: false);

      if (isFemale && controller.selectedMaritalStatus.value == 'Married') {
        controller.selectedMaritalStatus.value = '';
      }

      return SignupStepScaffold(
        progress: controller.progressPercent,
        onBack: controller.goBack,
        footer: SignupFooterActions(
          primaryLabel: 'continue'.tr,
          onPrimary: controller.selectedMaritalStatus.value.isNotEmpty
              ? controller.goToNextStep
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SignupHeroCard(
              badge: '03 / 12',
              icon: Icons.favorite_outline_rounded,
              title: 'marital_status'.tr,
              description: '',
            ),
            const SizedBox(height: AppSpacing.xl),
            SignupSurfaceCard(
              child: Column(
                children: statuses.map((status) {
                  final selected =
                      controller.selectedMaritalStatus.value == status;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: status == statuses.last ? 0 : AppSpacing.md,
                    ),
                    child: SignupChoiceTile(
                      title: status.tr,
                      selected: selected,
                      leading: _StatusBadge(
                        icon: _iconForStatus(status),
                        selected: selected,
                      ),
                      onTap: () => controller.selectedMaritalStatus.value =
                          selected ? '' : status,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    });
  }

  IconData _iconForStatus(String status) {
    switch (status) {
      case 'Married':
        return Icons.favorite_rounded;
      case 'Divorced':
        return Icons.change_circle_outlined;
      case 'Widowed':
        return Icons.hourglass_bottom_rounded;
      case 'Never Married':
      default:
        return Icons.auto_awesome_rounded;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.icon, required this.selected});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.12)
            : (isDark
                  ? AppColors.surfaceGlassDark
                  : AppColors.primary.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.22)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Icon(
        icon,
        size: 18,
        color: selected
            ? AppColors.primary
            : (isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
      ),
    );
  }
}
