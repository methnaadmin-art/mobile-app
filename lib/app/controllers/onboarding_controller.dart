import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/data/services/storage_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';

class OnboardingController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  List<OnboardingPage> get pages => const [
    OnboardingPage(
      pageIndex: 0,
      title: 'Find Your Naseeb with Intention',
      description:
          'Methna connects Muslims who are serious about marriage. Browse profiles rooted in shared faith, values, and family goals.',
      accent: Color(0xFF8A22FF),
      softAccent: Color(0xFFF1E2FF),
      imageAsset: 'assets/images/references/onboarding_matches.png',
    ),
    OnboardingPage(
      pageIndex: 1,
      title: 'Show Who You Truly Are',
      description:
          'Share your deen, background, and what you seek in a spouse so the right person recognizes you for who you are.',
      accent: Color(0xFF9123FF),
      softAccent: Color(0xFFF5E9FF),
      imageAsset: 'assets/images/references/onboarding_profile.png',
    ),
    OnboardingPage(
      pageIndex: 2,
      title: 'Begin Your Journey to Marriage',
      description:
          'Receive thoughtful recommendations, connect with sincerity, and take the first step toward a blessed union, In Shaa Allah.',
      accent: Color(0xFF9022FF),
      softAccent: Color(0xFFF4E8FF),
      imageAsset: 'assets/images/references/onboarding_match.png',
    ),
  ];

  void nextPage() {
    if (currentPage.value < pages.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      return;
    }

    completeOnboarding();
  }

  void skipOnboarding() => completeOnboarding();

  Future<void> completeOnboarding() async {
    debugPrint('[Onboarding] completeOnboarding called');
    await _storage.setOnboardingDone();
    await _storage.setFirstLaunch(false);
    debugPrint(
      '[Onboarding] isFirstLaunch after set: ${_storage.isFirstLaunch}',
    );
    debugPrint(
      '[Onboarding] isOnboardingDone after set: ${_storage.isOnboardingDone}',
    );
    Get.offAllNamed(AppRoutes.login);
  }

  void onPageChanged(int index) => currentPage.value = index;

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

class OnboardingPage {
  final int pageIndex;
  final String title;
  final String description;
  final Color accent;
  final Color softAccent;
  final String imageAsset;

  const OnboardingPage({
    required this.pageIndex,
    required this.title,
    required this.description,
    required this.accent,
    required this.softAccent,
    required this.imageAsset,
  });
}
