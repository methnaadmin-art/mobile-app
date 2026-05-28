import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'avatar_controller.dart';

/// AvatarWidget - Premium animated avatar component
///
/// Usage:
/// ```dart
/// AvatarWidget(
///   size: 120,
///   showGlow: true,
///   onTap: () => avatar.onLike(),
/// )
/// ```
class AvatarWidget extends StatelessWidget {
  /// Avatar size in pixels
  final double size;

  /// Show ambient glow effect
  final bool showGlow;

  /// Show reflection/shadow
  final bool showReflection;

  /// Background color (default: transparent)
  final Color? backgroundColor;

  /// Border color for avatar container
  final Color? borderColor;

  /// On tap callback
  final VoidCallback? onTap;

  /// Custom positioning (default: center)
  final Alignment alignment;

  /// Animation repeat mode
  final bool repeat;

  /// Animation frame rate (default: 60)
  final double frameRate;

  const AvatarWidget({
    super.key,
    this.size = 120,
    this.showGlow = true,
    this.showReflection = false,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.alignment = Alignment.center,
    this.repeat = true,
    this.frameRate = 60,
  });

  @override
  Widget build(BuildContext context) {
    // Find or create controller
    late AvatarController controller;
    try {
      controller = Get.find<AvatarController>();
    } catch (_) {
      controller = Get.put(AvatarController(), permanent: true);
    }

    return Obx(() {
      // Don't render if hidden
      if (!controller.isVisible.value) {
        return const SizedBox.shrink();
      }

      return AnimatedOpacity(
        opacity: controller.isTransitioning.value ? 0.8 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            alignment: alignment,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(size / 2),
              border: borderColor != null
                  ? Border.all(color: borderColor!, width: 2)
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ambient glow effect
                if (showGlow) _buildGlowEffect(controller.currentState.value),

                // Main Lottie animation
                _buildLottieAnimation(controller),

                // Reflection overlay
                if (showReflection) _buildReflection(),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildLottieAnimation(AvatarController controller) {
    final animationPath = controller.animationPath;

    return Lottie.asset(
      animationPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: repeat,
      frameRate: FrameRate(frameRate),
      errorBuilder: (context, error, stackTrace) {
        // Fallback to simple animated container if Lottie fails
        return _buildFallbackAvatar(controller.currentState.value);
      },
    );
  }

  Widget _buildGlowEffect(AvatarState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: size * 1.1,
      height: size * 1.1,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.1), Colors.transparent],
          stops: const [0.3, 0.6, 1.0],
        ),
      ),
    );
  }

  Widget _buildReflection() {
    return Positioned(
      bottom: 0,
      child: Container(
        width: size * 0.8,
        height: size * 0.2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withValues(alpha: 0.1), Colors.transparent],
          ),
          borderRadius: BorderRadius.circular(size / 2),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(AvatarState state) {
    // Simple animated fallback when Lottie files aren't available
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.05),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _getFallbackColors(state),
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getGlowColor(state).withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _getFallbackIcon(state),
                size: size * 0.35,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getGlowColor(AvatarState state) {
    switch (state) {
      case AvatarState.idle:
        return AppColors.primary;
      case AvatarState.wave:
        return AppColors.primaryLight;
      case AvatarState.happy:
      case AvatarState.success:
        return AppColors.secondary;
      case AvatarState.sad:
        return AppColors.primaryDark;
      case AvatarState.look:
        return AppColors.primary;
      case AvatarState.thinking:
      case AvatarState.loading:
        return AppColors.primaryDark;
      case AvatarState.welcome:
        return AppColors.primaryLight;
      case AvatarState.sleeping:
        return AppColors.secondary;
    }
  }

  List<Color> _getFallbackColors(AvatarState state) {
    switch (state) {
      case AvatarState.idle:
        return const [AppColors.primary, AppColors.primaryDark];
      case AvatarState.wave:
        return const [AppColors.primaryLight, AppColors.secondary];
      case AvatarState.happy:
      case AvatarState.success:
        return const [AppColors.primary, AppColors.secondary];
      case AvatarState.sad:
        return const [AppColors.primaryDark, AppColors.secondary];
      case AvatarState.look:
        return const [AppColors.primaryLight, AppColors.primary];
      case AvatarState.thinking:
      case AvatarState.loading:
        return const [AppColors.primary, AppColors.primaryDark];
      case AvatarState.welcome:
        return const [AppColors.primaryLight, AppColors.secondary];
      case AvatarState.sleeping:
        return const [AppColors.secondary, AppColors.primaryDark];
    }
  }

  IconData _getFallbackIcon(AvatarState state) {
    switch (state) {
      case AvatarState.idle:
        return Icons.person_outline;
      case AvatarState.wave:
        return Icons.waving_hand_outlined;
      case AvatarState.happy:
        return Icons.sentiment_very_satisfied_outlined;
      case AvatarState.sad:
        return Icons.sentiment_dissatisfied_outlined;
      case AvatarState.look:
        return Icons.visibility_outlined;
      case AvatarState.thinking:
        return Icons.psychology_outlined;
      case AvatarState.welcome:
        return Icons.celebration_outlined;
      case AvatarState.success:
        return Icons.check_circle_outline;
      case AvatarState.loading:
        return Icons.refresh;
      case AvatarState.sleeping:
        return Icons.nightlight_outlined;
    }
  }
}

/// Compact avatar for small spaces (app bar, etc.)
class AvatarCompact extends StatelessWidget {
  final double size;
  final bool showGlow;
  final VoidCallback? onTap;

  const AvatarCompact({
    super.key,
    this.size = 40,
    this.showGlow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AvatarWidget(
      size: size,
      showGlow: showGlow,
      showReflection: false,
      onTap: onTap,
      repeat: true,
    );
  }
}

/// Avatar with label for instructional UI
class AvatarWithLabel extends StatelessWidget {
  final String label;
  final double avatarSize;
  final TextStyle? labelStyle;

  const AvatarWithLabel({
    super.key,
    required this.label,
    this.avatarSize = 100,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AvatarWidget(size: avatarSize),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            label,
            key: ValueKey(label),
            style:
                labelStyle ??
                Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

