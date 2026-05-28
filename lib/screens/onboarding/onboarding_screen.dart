import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/onboarding_controller.dart';
import 'package:methna_app/core/utils/google_fonts_stub.dart';
import 'package:methna_app/screens/onboarding/widgets/onboarding_phone_previews.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final OnboardingController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<OnboardingController>()
        ? Get.find<OnboardingController>()
        : Get.put(OnboardingController());
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: const [SystemUiOverlay.bottom],
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Color(0xFF6E3DFB),
        body: _OnboardingPager(),
      ),
    );
  }
}

class _OnboardingPager extends GetView<OnboardingController> {
  const _OnboardingPager();

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller.pageController,
      itemCount: controller.pages.length,
      onPageChanged: controller.onPageChanged,
      itemBuilder: (context, index) {
        final page = controller.pages[index];
        return _OnboardingPage(
          page: page,
          isLast: index == controller.pages.length - 1,
          onNext: controller.nextPage,
          onSkip: controller.skipOnboarding,
        );
      },
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.page,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
  });

  final OnboardingPage page;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final phoneWidth = math.min(constraints.maxWidth * 0.78, 304.0);
        final phoneHeight = phoneWidth * 1.72;

        return Stack(
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6E3DFB), Color(0xFF8B5CF6)],
                ),
              ),
            ),
            Positioned(
              top: constraints.maxHeight * 0.075,
              left: 0,
              right: 0,
              child: Center(
                child: _PhonePreviewCard(
                  pageIndex: page.pageIndex,
                  width: phoneWidth,
                  height: phoneHeight,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomContentSheet(
                title: page.title,
                description: page.description,
                pageIndex: page.pageIndex,
                isLast: isLast,
                onNext: onNext,
                onSkip: onSkip,
                phoneHeight: phoneHeight,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BottomContentSheet extends StatelessWidget {
  const _BottomContentSheet({
    required this.title,
    required this.description,
    required this.pageIndex,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
    required this.phoneHeight,
  });

  final String title;
  final String description;
  final int pageIndex;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final double phoneHeight;

  @override
  Widget build(BuildContext context) {
    final topSpacer = phoneHeight * 0.22;

    return ClipPath(
      clipper: _OnboardingSheetClipper(),
      child: Container(
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: topSpacer),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: const Color(0xFF24212A),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    height: 1.7,
                    color: const Color(0xFF8F899B),
                  ),
                ),
                const SizedBox(height: 20),
                _OnboardingIndicator(currentIndex: pageIndex),
                const SizedBox(height: 26),
                isLast
                    ? _BottomPrimaryButton(
                        label: 'continue'.tr,
                        onTap: onNext,
                        isSecondary: false,
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _BottomPrimaryButton(
                              label: 'skip'.tr,
                              onTap: onSkip,
                              isSecondary: true,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _BottomPrimaryButton(
                              label: 'continue'.tr,
                              onTap: onNext,
                              isSecondary: false,
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomPrimaryButton extends StatelessWidget {
  const _BottomPrimaryButton({
    required this.label,
    required this.onTap,
    required this.isSecondary,
  });

  final String label;
  final VoidCallback onTap;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: isSecondary
              ? null
              : const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF6E3DFB), Color(0xFFA78BFA)],
                ),
          color: isSecondary ? const Color(0xFFF4F0FF) : null,
          boxShadow: isSecondary
              ? const []
              : [
                  BoxShadow(
                    color: const Color(0xFF6E3DFB).withValues(alpha: 0.24),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSecondary ? const Color(0xFFA78BFA) : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingIndicator extends StatelessWidget {
  const _OnboardingIndicator({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final active = currentIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
          width: active ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF6E3DFB) : const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _PhonePreviewCard extends StatelessWidget {
  const _PhonePreviewCard({
    required this.pageIndex,
    required this.width,
    required this.height,
  });

  final int pageIndex;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFFFFFAFB)),
            Positioned(
              top: 6,
              left: width * 0.24,
              right: width * 0.24,
              child: Container(
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            Positioned.fill(
              top: 36,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: switch (pageIndex) {
                  0 => const OnboardingAuthPhonePreview(),
                  1 => const OnboardingChatPhonePreview(),
                  _ => const OnboardingDiscoverPhonePreview(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _MatchesMockup extends StatelessWidget {
  const _MatchesMockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _MockTopBar(title: 'Methna'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6E3DFB), Color(0xFFA78BFA)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Interested (85)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EEF6),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Matches (24)',
                  style: TextStyle(
                    fontSize: 9.4,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF322C3B),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.72,
            children: const [
              _PhotoCardPlaceholder(name: 'Amina (24)'),
              _PhotoCardPlaceholder(
                name: 'Fatima (25)',
                tint: Color(0xFFFFD87A),
              ),
              _PhotoCardPlaceholder(
                name: 'Mariam (23)',
                tint: Color(0xFFD3E9FF),
              ),
              _PhotoCardPlaceholder(
                name: 'Khadija (22)',
                tint: Color(0xFFEDE9FE),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _ProfileMockup extends StatelessWidget {
  const _ProfileMockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _MockTopBar(title: 'Profile'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6E3DFB), Color(0xFFA78BFA)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  '15%',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'complete_your_profile'.tr,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFCEB18F),
                  Color(0xFFB48D74),
                  Color(0xFF8F6759),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 22,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6E3DFB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  left: 16,
                  right: 16,
                  bottom: 18,
                  child: Text(
                    'Youssef (27)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _MatchCardMockup extends StatelessWidget {
  const _MatchCardMockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _MockTopBar(title: 'Methna'),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6E3DFB).withValues(alpha: 0.14),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.favorite_border_rounded,
                        size: 84,
                        color: Color(0xFF6E3DFB),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          _AvatarBubble(color: Color(0xFFD7B493)),
                          SizedBox(width: 12),
                          _AvatarBubble(color: Color(0xFFE8A7B8)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'you_got_the_match'.tr,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6E3DFB),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'match_conversation_desc'.tr,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: const Color(0xFF8C8796),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MockTopBar extends StatelessWidget {
  const _MockTopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.circle_outlined, size: 18, color: Color(0xFF6E3DFB)),
        const Spacer(),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF232129),
          ),
        ),
        const Spacer(),
        const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF232129)),
      ],
    );
  }
}

class _PhotoCardPlaceholder extends StatelessWidget {
  const _PhotoCardPlaceholder({
    required this.name,
    this.tint = const Color(0xFFEAC2A5),
  });

  final String name;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tint, tint.withValues(alpha: 0.72), const Color(0xFF473B4E)],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  const _AvatarBubble({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
    );
  }
}

class _OnboardingSheetClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, 36);

    path.quadraticBezierTo(size.width * 0.18, 0, size.width * 0.5, 0);
    path.quadraticBezierTo(size.width * 0.82, 0, size.width, 36);

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
