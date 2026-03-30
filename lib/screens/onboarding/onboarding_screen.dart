import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:methna_app/app/controllers/onboarding_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final OnboardingController controller;
  late final AnimationController _floatingController;
  late final AnimationController _pulseController;
  late final List<_FloatingElement> _elements;

  @override
  void initState() {
    super.initState();
    controller = Get.put(OnboardingController());
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _elements = List.generate(18, (_) => _FloatingElement.random());
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.backgroundDark, AppColors.secondaryDark]
                : [Colors.white, const Color(0xFFFFF5F7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Skip button top right ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Obx(() {
                      final isLast = controller.currentPage.value ==
                          controller.pages.length - 1;
                      return AnimatedOpacity(
                        opacity: isLast ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: TextButton(
                          onPressed: isLast ? null : controller.skipOnboarding,
                          child: Text(
                            'skip'.tr,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // ── Page content ──
              Expanded(
                child: PageView.builder(
                  controller: controller.pageController,
                  onPageChanged: controller.onPageChanged,
                  itemCount: controller.pages.length,
                  itemBuilder: (context, index) {
                    final page = controller.pages[index];
                    return _OnboardingPage(
                      page: page,
                      isDark: isDark,
                      floatingController: _floatingController,
                      pulseController: _pulseController,
                      elements: _elements,
                    );
                  },
                ),
              ),

              // ── Bottom: indicator + button ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    // Custom dot indicator
                    SmoothPageIndicator(
                      controller: controller.pageController,
                      count: controller.pages.length,
                      effect: ExpandingDotsEffect(
                        activeDotColor: AppColors.primary,
                        dotColor: isDark
                            ? AppColors.borderDark
                            : AppColors.primary.withValues(alpha: 0.15),
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 3.5,
                        spacing: 6,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Full-width gradient button
                    Obx(() {
                      final isLast = controller.currentPage.value ==
                          controller.pages.length - 1;
                      return SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFE8396B),
                                Color(0xFFFF6B9D),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: controller.nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLast
                                      ? 'get_started'.tr
                                      : 'continue_text'.tr,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AnimatedRotation(
                                  turns: isLast ? 0.0 : 0.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    isLast
                                        ? LucideIcons.heart
                                        : LucideIcons.arrowRight,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Individual onboarding page ─────────────────────────────────────────
class _OnboardingPage extends StatelessWidget {
  final OnboardingPage page;
  final bool isDark;
  final AnimationController floatingController;
  final AnimationController pulseController;
  final List<_FloatingElement> elements;

  const _OnboardingPage({
    required this.page,
    required this.isDark,
    required this.floatingController,
    required this.pulseController,
    required this.elements,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // ── Illustration area ──
          Expanded(
            flex: 5,
            child: _IllustrationCard(
              page: page,
              floatingController: floatingController,
              pulseController: pulseController,
              elements: elements,
            ),
          ),

          // ── Text content ──
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 28, 8, 0),
              child: Column(
                children: [
                  // Title with gradient
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: page.gradient,
                      ).createShader(bounds),
                      child: Text(
                        page.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      page.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Illustration card with phone mockup ────────────────────────────────
class _IllustrationCard extends StatelessWidget {
  final OnboardingPage page;
  final AnimationController floatingController;
  final AnimationController pulseController;
  final List<_FloatingElement> elements;

  const _IllustrationCard({
    required this.page,
    required this.floatingController,
    required this.pulseController,
    required this.elements,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: page.gradient,
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: page.gradient.first.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Floating elements background
            AnimatedBuilder(
              animation: floatingController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _FloatingPainter(
                    elements: elements,
                    progress: floatingController.value,
                  ),
                );
              },
            ),

            // Large decorative circles
            Positioned(
              top: -40,
              right: -40,
              child: AnimatedBuilder(
                animation: pulseController,
                builder: (context, child) {
                  final scale = 1.0 + pulseController.value * 0.08;
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            // Phone mockup
            Positioned(
              top: 24,
              bottom: -16,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, 50 * (1 - value)),
                      child: Transform.scale(
                        scale: 0.85 + 0.15 * value,
                        child: child,
                      ),
                    ),
                  );
                },
                child: _PhoneMockup(page: page),
              ),
            ),

            // Floating accent badge
            Positioned(
              top: 40,
              left: 20,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: _FloatingBadge(
                  icon: page.accentIcon,
                  size: 48,
                ),
              ),
            ),

            // Second floating badge
            Positioned(
              bottom: 60,
              right: 16,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: _FloatingBadge(
                  icon: page.icon,
                  size: 42,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Floating badge widget ──────────────────────────────────────────────
class _FloatingBadge extends StatelessWidget {
  final IconData icon;
  final double size;

  const _FloatingBadge({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: AppColors.primary,
        size: size * 0.5,
      ),
    );
  }
}

// ─── Phone mockup widget ────────────────────────────────────────────────
class _PhoneMockup extends StatelessWidget {
  final OnboardingPage page;

  const _PhoneMockup({required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Notch / dynamic island
          Container(
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Center(
              child: Container(
                width: 72,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),

          // Screen content
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: page.bgGradient,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: _MockScreenContent(page: page),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mock screen content — unique per page ──────────────────────────────
class _MockScreenContent extends StatelessWidget {
  final OnboardingPage page;

  const _MockScreenContent({required this.page});

  @override
  Widget build(BuildContext context) {
    switch (page.pageIndex) {
      case 0:
        return _DiscoverMockup(gradient: page.gradient);
      case 1:
        return _ChatMockup(gradient: page.gradient);
      case 2:
        return _SafetyMockup(gradient: page.gradient);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Page 0: Discover — swipeable profile card with match % ──────────────
class _DiscoverMockup extends StatelessWidget {
  final List<Color> gradient;
  const _DiscoverMockup({required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Top bar with nav icons
          Row(
            children: [
              _circleIcon(LucideIcons.sliders, gradient.first, 22),
              const Spacer(),
              _circleIcon(LucideIcons.heart, gradient.first, 24),
              const Spacer(),
              _circleIcon(LucideIcons.bell, Colors.grey, 22),
            ],
          ),
          const SizedBox(height: 10),
          // Main profile card
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    gradient.first.withValues(alpha: 0.08),
                    gradient.last.withValues(alpha: 0.2),
                  ],
                ),
                border: Border.all(
                  color: gradient.first.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: gradient),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.first.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(LucideIcons.user,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 8),
                  // Name
                  Text('Sarah, 24',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800)),
                  const SizedBox(height: 2),
                  Text('Dubai, UAE',
                      style:
                          TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                  const SizedBox(height: 10),
                  // Match percentage badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('92% Match',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
                  const Spacer(),
                  // Action buttons row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _actionBtn(LucideIcons.x, Colors.grey.shade400, 32),
                        _actionBtn(LucideIcons.heart, gradient.first, 40),
                        _actionBtn(LucideIcons.star, Colors.amber, 32),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
      ),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }

  Widget _actionBtn(IconData icon, Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

// ── Page 1: Connect — chat conversation mockup ──────────────────────────
class _ChatMockup extends StatelessWidget {
  final List<Color> gradient;
  const _ChatMockup({required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Chat header
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: gradient),
                ),
                child: const Icon(LucideIcons.user, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amina',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800)),
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text('Online',
                          style: TextStyle(
                              fontSize: 7, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Icon(LucideIcons.video,
                  size: 16, color: gradient.first),
              const SizedBox(width: 8),
              Icon(LucideIcons.phone,
                  size: 14, color: gradient.first),
            ],
          ),
          const SizedBox(height: 14),
          // Chat bubbles
          Expanded(
            child: Column(
              children: [
                _chatBubble('Assalamu Alaikum! 👋', false, gradient),
                const SizedBox(height: 6),
                _chatBubble('Wa Alaikum Assalam! How are you?', true, gradient),
                const SizedBox(height: 6),
                _chatBubble(
                    'Alhamdulillah! I loved your profile 💕', false, gradient),
                const SizedBox(height: 6),
                _chatBubble(
                    'Thank you! Would love to chat more', true, gradient),
                const Spacer(),
              ],
            ),
          ),
          // Message input
          Container(
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Text('Type a message...',
                    style: TextStyle(
                        fontSize: 8, color: Colors.grey.shade400)),
                const Spacer(),
                Icon(LucideIcons.send,
                    size: 13, color: gradient.first),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  static Widget _chatBubble(
      String text, bool isMine, List<Color> gradient) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 145),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: isMine ? LinearGradient(colors: gradient) : null,
          color: isMine ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMine ? 12 : 2),
            bottomRight: Radius.circular(isMine ? 2 : 12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 8,
            color: isMine ? Colors.white : Colors.grey.shade800,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

// ── Page 2: Safety — verified profile mockup ────────────────────────────
class _SafetyMockup extends StatelessWidget {
  final List<Color> gradient;
  const _SafetyMockup({required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Icon(LucideIcons.shield, size: 18, color: gradient.first),
              const SizedBox(width: 6),
              Text('Trust & Safety',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800)),
            ],
          ),
          const SizedBox(height: 8),
          // Trust score ring
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: gradient.first, width: 3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('100',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: gradient.first)),
                Text('Trust',
                    style: TextStyle(
                        fontSize: 6, color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Verification checklist
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _verifyRow(LucideIcons.mail, 'Email Verified', true, gradient),
                const SizedBox(height: 5),
                _verifyRow(LucideIcons.phone, 'Phone Verified', true, gradient),
                const SizedBox(height: 5),
                _verifyRow(
                    LucideIcons.camera, 'Photo Verified', true, gradient),
                const SizedBox(height: 5),
                _verifyRow(LucideIcons.badge, 'ID Verified', false, gradient),
              ],
            ),
          ),
          // Bottom badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.badgeCheck,
                    color: Colors.white, size: 11),
                const SizedBox(width: 4),
                const Text('Fully Protected',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  static Widget _verifyRow(
      IconData icon, String label, bool done, List<Color> gradient) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: done
            ? gradient.first.withValues(alpha: 0.06)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: done
              ? gradient.first.withValues(alpha: 0.15)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 12,
              color: done ? gradient.first : Colors.grey.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
          ),
          Icon(
            done ? LucideIcons.checkCircle : LucideIcons.circle,
            size: 14,
            color: done ? gradient.first : Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}

// ─── Floating elements ──────────────────────────────────────────────────
class _FloatingElement {
  final double x;
  final double startY;
  final double size;
  final double speed;
  final double opacity;
  final int type; // 0 = heart, 1 = circle, 2 = star

  _FloatingElement({
    required this.x,
    required this.startY,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.type,
  });

  factory _FloatingElement.random() {
    final rng = Random();
    return _FloatingElement(
      x: rng.nextDouble(),
      startY: rng.nextDouble(),
      size: 6 + rng.nextDouble() * 14,
      speed: 0.2 + rng.nextDouble() * 0.6,
      opacity: 0.04 + rng.nextDouble() * 0.1,
      type: rng.nextInt(3),
    );
  }
}

class _FloatingPainter extends CustomPainter {
  final List<_FloatingElement> elements;
  final double progress;

  _FloatingPainter({required this.elements, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in elements) {
      final y = ((e.startY + progress * e.speed) % 1.2) * size.height;
      final x = e.x * size.width +
          sin(progress * 2 * pi + e.startY * 6) * 15;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: e.opacity)
        ..style = PaintingStyle.fill;

      if (e.type == 0) {
        _drawHeart(canvas, Offset(x, y), e.size, paint);
      } else if (e.type == 1) {
        canvas.drawCircle(Offset(x, y), e.size / 2, paint);
      } else {
        _drawStar(canvas, Offset(x, y), e.size, paint);
      }
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double s, Paint paint) {
    final path = Path();
    final x = center.dx - s / 2;
    final y = center.dy - s / 2;
    path.moveTo(x + s / 2, y + s);
    path.cubicTo(x + s / 2, y + s, x, y + s * 0.65, x, y + s * 0.35);
    path.cubicTo(x, y + s * 0.1, x + s * 0.25, y, x + s / 2, y + s * 0.2);
    path.cubicTo(x + s * 0.75, y, x + s, y + s * 0.1, x + s, y + s * 0.35);
    path.cubicTo(x + s, y + s * 0.65, x + s / 2, y + s, x + s / 2, y + s);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double s, Paint paint) {
    final path = Path();
    final r = s / 2;
    final ir = r * 0.4;
    for (int i = 0; i < 5; i++) {
      final outerAngle = -pi / 2 + (2 * pi * i) / 5;
      final innerAngle = outerAngle + pi / 5;
      if (i == 0) {
        path.moveTo(
            center.dx + r * cos(outerAngle), center.dy + r * sin(outerAngle));
      } else {
        path.lineTo(
            center.dx + r * cos(outerAngle), center.dy + r * sin(outerAngle));
      }
      path.lineTo(
          center.dx + ir * cos(innerAngle), center.dy + ir * sin(innerAngle));
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FloatingPainter old) =>
      old.progress != progress;
}
