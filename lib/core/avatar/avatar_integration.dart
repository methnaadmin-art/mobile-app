import 'package:get/get.dart';
import 'avatar_controller.dart';

mixin AvatarIntegrationMixin {
  AvatarController get avatar {
    try {
      return Get.find<AvatarController>();
    } catch (_) {
      return Get.put(AvatarController(), permanent: true);
    }
  }

  /// Call this in onInit to ensure avatar controller exists
  void setupAvatarIntegration() {
    avatar;
  }

  /// Trigger happy animation on successful action
  void avatarHappy() => avatar.onLike();

  /// Trigger sad animation on error
  void avatarSad() => avatar.onError();

  /// Trigger wave animation
  void avatarWave() => avatar.onLogin();

  /// Trigger swipe animation
  void avatarSwipe() => avatar.onSwipe();

  /// Set avatar to idle
  void avatarIdle() => avatar.idle();

  /// Show loading/thinking state
  void avatarLoading() => avatar.onLoading();

  /// Show success state
  void avatarSuccess() => avatar.onSuccess();
}

/// Extension methods for existing controllers
extension AvatarControllerExtension on GetxController {
  /// Get avatar controller (creates if not exists)
  AvatarController get withAvatar {
    try {
      return Get.find<AvatarController>();
    } catch (_) {
      return Get.put(AvatarController(), permanent: true);
    }
  }
}

/// Predefined avatar configurations for different screens
class AvatarConfigurations {
  /// For login screen - welcoming, friendly
  static const login = AvatarConfig(
    initialState: AvatarState.wave,
    size: 150,
    showGlow: true,
    showReflection: true,
  );

  /// For home screen - subtle, ambient
  static const home = AvatarConfig(
    initialState: AvatarState.idle,
    size: 80,
    showGlow: false,
    showReflection: false,
  );

  /// For profile/settings - friendly but compact
  static const profile = AvatarConfig(
    initialState: AvatarState.idle,
    size: 100,
    showGlow: true,
    showReflection: false,
  );

  /// For empty states - empathetic
  static const emptyState = AvatarConfig(
    initialState: AvatarState.sad,
    size: 120,
    showGlow: true,
    showReflection: true,
  );

  /// For loading states
  static const loading = AvatarConfig(
    initialState: AvatarState.thinking,
    size: 100,
    showGlow: false,
    showReflection: false,
  );

  /// For success/match states - celebratory
  static const success = AvatarConfig(
    initialState: AvatarState.happy,
    size: 180,
    showGlow: true,
    showReflection: true,
  );
}

/// Configuration class for avatar presets
class AvatarConfig {
  final AvatarState initialState;
  final double size;
  final bool showGlow;
  final bool showReflection;

  const AvatarConfig({
    required this.initialState,
    required this.size,
    required this.showGlow,
    required this.showReflection,
  });
}
