import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/widgets/signup_flow.dart';

class HobbiesInterestsScreen extends StatefulWidget {
  const HobbiesInterestsScreen({super.key});

  @override
  State<HobbiesInterestsScreen> createState() => _HobbiesInterestsScreenState();
}

class _HobbiesInterestsScreenState extends State<HobbiesInterestsScreen> {
  final SignupController controller = Get.find<SignupController>();

  static const List<String> _options = [
    'Travel',
    'Cooking',
    'Hiking',
    'Yoga',
    'Gaming',
    'Movies',
    'Photography',
    'Music',
    'Pets',
    'Painting',
    'Art',
    'Fitness',
    'Reading',
    'Dancing',
    'Sports',
    'Board Games',
    'Technology',
    'Fashion',
    'Motorcycling',
  ];

  @override
  Widget build(BuildContext context) {
    controller.syncStep(AppRoutes.signupHobbies);

    return Obx(() {
      final busy =
          controller.isNavigatingStep.value || controller.isLoading.value;
      final selectedCount = controller.selectedHobbies.length;

      return SignupStepScaffold(
        onBack: controller.goBack,
        progress: controller.progressPercent,
        footer: SignupFooterActions(
          primaryLabel: selectedCount > 0
              ? '${'continue_text'.tr} ($selectedCount/${SignupController.maxHobbiesSelection})'
              : 'continue_text'.tr,
          onPrimary: selectedCount > 0 && !busy
              ? controller.goToNextStep
              : null,
          isLoading: busy,
          secondaryLabel: 'skip_for_now'.tr,
          onSecondary: busy ? null : controller.skipCurrentOptionalStep,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SignupHeroCard(
              badge: '08 / 12',
              icon: LucideIcons.sparkles,
              title: 'discover_like_minded'.tr,
              description: 'discover_like_minded_desc'.tr,
              preview: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SignupInfoPill(
                    icon: LucideIcons.heart,
                    label:
                        '${'select_hobbies'.tr} (${SignupController.maxHobbiesSelection})',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SignupSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SignupSectionLabel(text: 'hobbies_interests'.tr),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _options.map((interest) {
                      final selected = controller.selectedHobbies.contains(
                        interest,
                      );
                      return SignupOptionChip(
                        label: interest,
                        selected: selected,
                        icon: _iconForInterest(interest),
                        onTap: () => controller.toggleHobby(interest),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  IconData _iconForInterest(String interest) {
    switch (interest) {
      case 'Travel':
        return Icons.flight_takeoff_rounded;
      case 'Cooking':
        return Icons.restaurant_menu_rounded;
      case 'Hiking':
        return Icons.terrain_rounded;
      case 'Yoga':
        return Icons.self_improvement_rounded;
      case 'Gaming':
        return Icons.sports_esports_rounded;
      case 'Movies':
        return Icons.movie_creation_outlined;
      case 'Photography':
        return Icons.photo_camera_outlined;
      case 'Music':
        return Icons.music_note_rounded;
      case 'Pets':
        return Icons.pets_outlined;
      case 'Painting':
      case 'Art':
        return Icons.palette_outlined;
      case 'Fitness':
      case 'Sports':
        return Icons.fitness_center_rounded;
      case 'Reading':
        return Icons.menu_book_rounded;
      case 'Dancing':
        return Icons.nightlife_rounded;
      case 'Board Games':
        return Icons.casino_outlined;
      case 'Technology':
        return Icons.memory_rounded;
      case 'Fashion':
        return Icons.checkroom_rounded;
      case 'Motorcycling':
        return Icons.two_wheeler_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }
}
