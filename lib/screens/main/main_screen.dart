import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/home_controller.dart';
import 'package:methna_app/app/controllers/navigation_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/widgets/bottom_nav_bar.dart';
import 'package:methna_app/screens/main/home/home_screen.dart';
import 'package:methna_app/screens/main/users/users_screen.dart';
import 'package:methna_app/screens/main/chat/chat_list_screen.dart';
import 'package:methna_app/screens/main/profile/profile_screen.dart';
import 'package:methna_app/core/widgets/moderation_overlays.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final NavigationController controller = Get.find<NavigationController>();
  final Set<int> _loadedIndexes = <int>{0};
  late final AnimationController _transitionController;
  late final Animation<double> _transitionAnimation;
  late final Worker _navWorker;
  int _previousIndex = 0;
  int _transitionDirection = 1;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _transitionAnimation = CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeOutCubic,
    );
    _previousIndex = controller.currentIndex.value;
    _navWorker = ever<int>(controller.currentIndex, (index) {
      if (index == _previousIndex) return;
      _transitionDirection = index > _previousIndex ? 1 : -1;
      _transitionController.forward(from: 0);
      _previousIndex = index;
    });
  }

  @override
  void dispose() {
    _navWorker.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const UsersScreen();
      case 2:
        return const ChatListScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentIndex = controller.currentIndex.value;
      _loadedIndexes.add(currentIndex);
      final isHome = currentIndex == 0;
        final hideBottomNav =
          isHome &&
          Get.isRegistered<HomeController>() &&
          (Get.find<HomeController>().showStartupRadar.value ||
           Get.find<HomeController>().isInitializing.value ||
           Get.find<HomeController>().showLocationGate.value);
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final overlayStyle = isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark;

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          extendBody: true,
          body: ModerationGuardWrapper(
            child: Stack(
              children: [
                IndexedStack(
                  index: currentIndex,
                  children: List<Widget>.generate(
                    4,
                    (index) => _loadedIndexes.contains(index)
                        ? _buildPage(index)
                        : const SizedBox.shrink(),
                  ),
                ),
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _transitionAnimation,
                    builder: (context, child) {
                      if (_transitionAnimation.value == 0) {
                        return const SizedBox.shrink();
                      }
                      return _NavTransitionOverlay(
                        progress: _transitionAnimation.value,
                        direction: _transitionDirection,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: hideBottomNav
                ? const SizedBox.shrink(key: ValueKey('hidden_bottom_nav'))
                : const AppBottomNavBar(key: ValueKey('visible_bottom_nav')),
          ),
        ),
      );
    });
  }
}

class _NavTransitionOverlay extends StatelessWidget {
  final double progress;
  final int direction;

  const _NavTransitionOverlay({
    required this.progress,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = AppColors.primary;
    final glow = Color.lerp(AppColors.primaryLight, Colors.white, 0.2) ??
        AppColors.primaryLight;
    final intensity = math.pow(math.sin(progress * math.pi), 0.7).toDouble();

    return CustomPaint(
      painter: _NavTransitionPainter(
        progress: progress,
        direction: direction,
        base: base,
        glow: glow,
        isDark: isDark,
        intensity: intensity,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _NavTransitionPainter extends CustomPainter {
  final double progress;
  final int direction;
  final Color base;
  final Color glow;
  final bool isDark;
  final double intensity;

  _NavTransitionPainter({
    required this.progress,
    required this.direction,
    required this.base,
    required this.glow,
    required this.isDark,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final width = size.width;
    final height = size.height;
    final dir = direction >= 0 ? 1.0 : -1.0;
    final centerX = width * (dir > 0 ? progress : (1 - progress));
    final waveWidth = width * 0.28;

    final path = Path()
      ..moveTo(centerX, 0)
      ..quadraticBezierTo(
        centerX + (waveWidth * 0.2 * dir),
        height * 0.25,
        centerX - (waveWidth * 0.1 * dir),
        height * 0.5,
      )
      ..quadraticBezierTo(
        centerX - (waveWidth * 0.3 * dir),
        height * 0.72,
        centerX + (waveWidth * 0.05 * dir),
        height,
      )
      ..lineTo(dir > 0 ? width : 0, height)
      ..lineTo(dir > 0 ? width : 0, 0)
      ..close();

    final shader = LinearGradient(
      begin: dir > 0 ? Alignment.centerLeft : Alignment.centerRight,
      end: dir > 0 ? Alignment.centerRight : Alignment.centerLeft,
      colors: [
        base.withValues(alpha: 0.05 * intensity),
        glow.withValues(alpha: 0.16 * intensity),
        base.withValues(alpha: 0.08 * intensity),
        Colors.transparent,
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, width, height));

    final paint = Paint()..shader = shader;
    canvas.drawPath(path, paint);

    final orbPaint = Paint()
      ..color = glow.withValues(alpha: (isDark ? 0.22 : 0.28) * intensity);
    final orbRadius = 14 + (intensity * 8);
    final orbY = height * (0.35 + 0.3 * math.sin(progress * math.pi));
    canvas.drawCircle(Offset(centerX + (dir * 24), orbY), orbRadius, orbPaint);
  }

  @override
  bool shouldRepaint(covariant _NavTransitionPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.direction != direction ||
        oldDelegate.base != base ||
        oldDelegate.glow != glow ||
        oldDelegate.isDark != isDark;
  }
}
