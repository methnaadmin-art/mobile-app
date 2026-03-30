import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HobbiesInterestsScreen extends GetView<SignupController> {
  const HobbiesInterestsScreen({super.key});

  // Categorized hobbies with emojis
  static const _categories = <String, List<_HobbyItem>>{
    'SPORTS': [
      _HobbyItem('Gym', '🏋️'),
      _HobbyItem('Football', '⚽'),
      _HobbyItem('Horse Riding', '🏇'),
      _HobbyItem('Archery', '🏹'),
      _HobbyItem('Swimming', '🏊'),
    ],
    'LIFESTYLE': [
      _HobbyItem('Traveling', '✈️'),
      _HobbyItem('Coffee', '☕'),
      _HobbyItem('Reading', '📚'),
      _HobbyItem('Yoga', '🧘'),
      _HobbyItem('Camping', '🏕️'),
    ],
    'FOOD & ENTERTAINMENT': [
      _HobbyItem('Cooking', '🍳'),
      _HobbyItem('Anime', '🎌'),
      _HobbyItem('Pizza', '🍕'),
      _HobbyItem('Baking', '🧁'),
    ],
  };

  @override
  Widget build(BuildContext context) {
    controller.syncStep(AppRoutes.signupHobbies);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.backgroundDark : Colors.white;
    final secondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: back arrow + progress ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  _BackArrow(isDark: isDark),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() => _ProgressBar(
                          progress: controller.progressPercent,
                        )),
                  ),
                ],
              ),
            ),

            // ── Scrollable content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),

                    // Title
                    Text(
                      'hobbies_interests'.tr,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Category sections ──
                    ..._categories.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section header with decorative line
                          Row(
                            children: [
                              Container(
                                width: 20,
                                height: 1.5,
                                color: secondaryColor.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.key.tr,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: secondaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Chips wrap
                          Obx(() => Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children:
                                    entry.value.map((item) {
                                  final selected = controller
                                      .selectedHobbies
                                      .contains(item.name);
                                  return GestureDetector(
                                    onTap: () =>
                                        controller.toggleHobby(item.name),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppColors.primary
                                            : (isDark
                                                ? AppColors.cardDark
                                                : Colors.white),
                                        borderRadius:
                                            BorderRadius.circular(24),
                                        border: Border.all(
                                          color: selected
                                              ? AppColors.primary
                                              : (isDark
                                                  ? AppColors.borderDark
                                                  : AppColors.borderLight),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            item.emoji,
                                            style: const TextStyle(
                                                fontSize: 16),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            item.name.tr,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: selected
                                                  ? Colors.white
                                                  : (isDark
                                                      ? AppColors
                                                          .textPrimaryDark
                                                      : AppColors
                                                          .textPrimaryLight),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )),

                          const SizedBox(height: 24),
                        ],
                      );
                    }),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ── Bottom: Continue button ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Obx(() => SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: controller.selectedHobbies.length >= 3
                          ? controller.goToNextStep
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.4),
                        disabledForegroundColor: Colors.white70,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'continue_text'.tr,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hobby item model ─────────────────────────────────────────────────────
class _HobbyItem {
  final String name;
  final String emoji;
  const _HobbyItem(this.name, this.emoji);
}

// ─── Progress bar ─────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final double progress;
  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 6,
        backgroundColor: Colors.grey.shade200,
        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
      ),
    );
  }
}

// ─── Reusable back arrow ──────────────────────────────────────────────────
class _BackArrow extends StatelessWidget {
  final bool isDark;
  const _BackArrow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.find<SignupController>().goBack(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          LucideIcons.chevronLeft,
          size: 16,
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}
