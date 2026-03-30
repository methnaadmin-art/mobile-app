import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/controllers/analytics_controller.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

class DataAnalyticsScreen extends GetView<AnalyticsController> {
  const DataAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : Colors.white;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: textColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'profile_insights'.tr,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.refreshCw, color: AppColors.primary, size: 20),
            onPressed: controller.refresh,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildShimmer(isDark);
        }
        final data = controller.data;
        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Summary Stats Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _StatCard(
                    title: 'total_views'.tr,
                    value: data.totalViews.toString(),
                    icon: LucideIcons.eye,
                    color: Colors.blue,
                    isDark: isDark,
                  ),
                  _StatCard(
                    title: 'total_likes'.tr,
                    value: data.totalLikes.toString(),
                    icon: LucideIcons.heart,
                    color: Colors.redAccent,
                    isDark: isDark,
                  ),
                  _StatCard(
                    title: 'total_matches'.tr,
                    value: data.totalMatches.toString(),
                    icon: LucideIcons.users,
                    color: AppColors.emerald,
                    isDark: isDark,
                  ),
                  _StatCard(
                    title: 'match_rate'.tr,
                    value: '${(data.matchRate * 100).toStringAsFixed(1)}%',
                    icon: LucideIcons.trendingUp,
                    color: AppColors.gold,
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Weekly Activity Chart Placeholder (or simple list)
              Text(
                'weekly_activity'.tr,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
                ),
                child: data.weeklyViews.isEmpty
                    ? Center(child: Text('no_data_available'.tr, style: TextStyle(color: secondaryColor)))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: data.weeklyViews.map((day) {
                          final heightFactor = (day.views / (data.totalViews > 0 ? data.totalViews : 1)).clamp(0.1, 1.0);
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: 24,
                                height: 120 * heightFactor,
                                decoration: BoxDecoration(
                                  gradient: AppColors.goldPremiumGradient,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ).animate().scaleY(begin: 0, end: 1, duration: 800.ms, curve: Curves.easeOutBack),
                              const SizedBox(height: 8),
                              Text(day.day, style: TextStyle(fontSize: 10, color: secondaryColor, fontWeight: FontWeight.bold)),
                            ],
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 32),

              // Data Settings Section
              Text(
                'data_privacy_settings'.tr,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 16),
              _SettingsToggle(
                title: 'share_usage_data'.tr,
                subtitle: 'share_usage_data_desc'.tr,
                value: true,
                onChanged: (v) {},
                isDark: isDark,
              ),
              _SettingsToggle(
                title: 'personalized_ads'.tr,
                subtitle: 'personalized_ads_desc'.tr,
                value: false,
                onChanged: (v) {},
                isDark: isDark,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: List.generate(4, (index) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
          ),
          const SizedBox(height: 32),
          Container(height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
          Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;
  final bool isDark;

  const _SettingsToggle({required this.title, required this.subtitle, required this.value, required this.onChanged, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: secondaryColor, height: 1.4)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
