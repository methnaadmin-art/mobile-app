import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/categories_controller.dart';
import 'package:methna_app/app/data/models/category_model.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/utils/icon_helper.dart';
import 'package:methna_app/core/widgets/animated_empty_state.dart';
import 'package:methna_app/core/widgets/datify_shell.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CategoriesController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 76,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6),
          child: DatifyBackButton(onTap: () => Get.back()),
        ),
        title: Text(
          'categories'.tr,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: DatifyBackground(
        compact: true,
        child: Obx(() {
          if (controller.isLoading.value && controller.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.hasError.value && controller.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.wifiOff, size: 48, color: secondaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'failed_load_categories'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'check_connection_retry'.tr,
                    style: TextStyle(fontSize: 13, color: secondaryColor),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: controller.fetchCategories,
                    icon: const Icon(LucideIcons.refreshCw, size: 16),
                    label: Text('retry'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (controller.categories.isEmpty) {
            return AnimatedEmptyState(
              lottieAsset: 'assets/animations/no_categories.json',
              title: 'no_categories'.tr,
              subtitle: 'no_categories_desc'.tr,
              fallbackIcon: LucideIcons.layoutGrid,
            );
          }

          return RefreshIndicator(
            onRefresh: controller.fetchCategories,
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: controller.categories.length,
              itemBuilder: (context, index) {
                final category = controller.categories[index];
                return _CategoryCard(
                  category: category,
                  isDark: isDark,
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                  onTap: () {
                    controller.selectCategory(category);
                    Get.toNamed(
                      AppRoutes.categoryUsers,
                      arguments: {'category': category},
                    );
                  },
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final bool isDark;
  final Color textColor;
  final Color secondaryColor;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.isDark,
    required this.textColor,
    required this.secondaryColor,
    required this.onTap,
  });

  Color get _cardColor {
    if (category.color != null && category.color!.isNotEmpty) {
      try {
        final hex = category.color!.replaceFirst('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isDark ? Border.all(color: AppColors.borderDark) : null,
            ),
            child: Row(
              children: [
                // Icon circle
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _cardColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    IconHelper.getIcon(category.icon),
                    color: _cardColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Name + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      if (category.description != null &&
                          category.description!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          category.description!,
                          style: TextStyle(fontSize: 12, color: secondaryColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // User count + arrow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${category.userCount}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _cardColor,
                      ),
                    ),
                    Text(
                      'users'.tr,
                      style: TextStyle(fontSize: 10, color: secondaryColor),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(LucideIcons.chevronRight, size: 18, color: secondaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
