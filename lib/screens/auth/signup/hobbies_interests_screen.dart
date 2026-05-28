import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
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
          onPrimary: !busy
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
              description: '',
            ),
            const SizedBox(height: AppSpacing.xl),
            SignupSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SignupSectionLabel(text: 'hobbies_interests'.tr),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$selectedCount/${SignupController.maxHobbiesSelection}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                    ),
                  ),
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
                          icon: _interestIcon(interest),
                          translateLabel: false,
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

  IconData _interestIcon(String value) {
    switch (value.trim().toLowerCase()) {
      case 'travel':
        return Icons.flight_takeoff_rounded;
      case 'cooking':
        return Icons.restaurant_menu_rounded;
      case 'hiking':
        return Icons.terrain_rounded;
      case 'yoga':
        return Icons.self_improvement_rounded;
      case 'gaming':
        return Icons.sports_esports_rounded;
      case 'movies':
        return Icons.movie_creation_outlined;
      case 'photography':
        return Icons.photo_camera_outlined;
      case 'music':
        return Icons.music_note_rounded;
      case 'pets':
        return Icons.pets_outlined;
      case 'art':
      case 'painting':
        return Icons.palette_outlined;
      case 'fitness':
      case 'sports':
        return Icons.fitness_center_rounded;
      case 'reading':
        return Icons.menu_book_rounded;
      case 'dancing':
        return Icons.theater_comedy_outlined;
      case 'technology':
        return Icons.memory_rounded;
      case 'fashion':
        return Icons.checkroom_rounded;
      case 'motorcycling':
        return Icons.two_wheeler_rounded;
      case 'board games':
        return Icons.casino_outlined;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  String _interestEmoji(String value) {
    switch (value.trim().toLowerCase()) {
      case 'travel':
        return '✈️';
      case 'cooking':
        return '🍳';
      case 'hiking':
        return '🥾';
      case 'yoga':
        return '🧘';
      case 'gaming':
        return '🎮';
      case 'movies':
        return '🎬';
      case 'photography':
        return '📸';
      case 'music':
        return '🎵';
      case 'pets':
        return '🐾';
      case 'art':
      case 'painting':
        return '🎨';
      case 'fitness':
      case 'sports':
        return '🏃';
      case 'reading':
        return '📚';
      case 'dancing':
        return '💃';
      case 'technology':
        return '💻';
      default:
        return '✨';
    }
  }

}
