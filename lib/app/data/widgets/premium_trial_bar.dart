import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class PremiumTrialBar extends StatelessWidget {
  const PremiumTrialBar({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Get.find<AuthService>();

    return Obx(() {
      final user = authService.currentUser.value;
      if (user == null || !user.isTrialActive) return const SizedBox.shrink();

      final remaining = user.trialTimeRemaining;
      final totalTrial = const Duration(days: 3);

      String timeLeftText;
      if (remaining.inDays >= 1) {
        timeLeftText = 'days_left'.trParams({
          'count': remaining.inDays.toString(),
        });
      } else if (remaining.inHours >= 1) {
        timeLeftText = 'hours_left'.trParams({
          'count': remaining.inHours.toString(),
        });
      } else {
        timeLeftText = 'minutes_left'.trParams({
          'count': remaining.inMinutes.toString(),
        });
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppColors.goldPremiumGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.sparkles,
                  color: AppColors.secondary,
                  size: 12,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'premium_trial_active'.tr,
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeLeftText,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (remaining.inSeconds / totalTrial.inSeconds).clamp(
                  0.0,
                  1.0,
                ),
                backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.secondary,
                ),
                minHeight: 3,
              ),
            ),
          ],
        ),
      );
    });
  }
}
