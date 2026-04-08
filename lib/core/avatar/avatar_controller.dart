import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// AvatarState - Enum for all possible avatar states
enum AvatarState {
  idle,
  wave,
  happy,
  sad,
  look,
  thinking,
  welcome,
  success,
  loading,
  sleeping,
}

/// AvatarController - Manages the companion avatar state and animations
/// 
/// Usage:
/// ```dart
/// final avatar = Get.find<AvatarController>();
/// avatar.onLogin(); // Triggers wave animation
/// avatar.onLike();  // Triggers happy animation
/// ```
class AvatarController extends GetxController {
  // ─── STATE ───────────────────────────────────────────────────────────
  
  /// Current avatar state (observable)
  final Rx<AvatarState> currentState = AvatarState.idle.obs;
  
  /// Previous state (for transition handling)
  AvatarState? _previousState;
  
  /// Is avatar visible (can be toggled)
  final RxBool isVisible = true.obs;
  
  /// Is animation currently transitioning
  final RxBool isTransitioning = false.obs;
  
  /// Auto-return to idle timer
  Timer? _idleTimer;
  
  /// Last interaction timestamp
  DateTime _lastInteraction = DateTime.now();
  
  // ─── CONFIGURATION ───────────────────────────────────────────────────
  
  /// Duration before auto-returning to idle (default: 3 seconds)
  final Duration idleTimeout;
  
  /// Animation transition duration
  final Duration transitionDuration;
  
  /// Enable auto-idle behavior
  final bool autoIdle;
  
  AvatarController({
    this.idleTimeout = const Duration(seconds: 3),
    this.transitionDuration = const Duration(milliseconds: 300),
    this.autoIdle = true,
  });

  @override
  void onClose() {
    _idleTimer?.cancel();
    super.onClose();
  }

  // ─── PUBLIC METHODS ──────────────────────────────────────────────────

  /// Set avatar state directly (with transition handling)
  void setState(AvatarState state) {
    if (currentState.value == state) return;
    
    _previousState = currentState.value;
    isTransitioning.value = true;
    currentState.value = state;
    _lastInteraction = DateTime.now();
    
    debugPrint('[AvatarController] State: ${_previousState?.name} → ${state.name}');
    
    // Clear any existing idle timer
    _idleTimer?.cancel();
    
    // End transition after duration
    Future.delayed(transitionDuration, () {
      isTransitioning.value = false;
    });
    
    // Auto-return to idle for temporary states
    if (autoIdle && state != AvatarState.idle && state != AvatarState.sleeping) {
      _idleTimer = Timer(idleTimeout, () {
        if (currentState.value == state) {
          idle();
        }
      });
    }
  }

  /// Return to idle state
  void idle() => setState(AvatarState.idle);

  /// Wave/greet animation - for login, welcome, tap interactions
  void onWave() => setState(AvatarState.wave);

  /// Wave/greet animation - for login, welcome (alias for onWave)
  void onLogin() => onWave();

  /// Happy animation - for likes, matches, success
  void onLike() => setState(AvatarState.happy);
  void onMatch() => setState(AvatarState.happy);
  void onSuccess() => setState(AvatarState.success);

  /// Sad animation - for errors, rejections
  void onError() => setState(AvatarState.sad);
  void onPass() => setState(AvatarState.sad);

  /// Look/follow animation - for swipes, user attention
  void onSwipe() => setState(AvatarState.look);
  void onSwipeLeft() => setState(AvatarState.look);
  void onSwipeRight() => setState(AvatarState.look);

  /// Thinking animation - for loading, processing
  void onLoading() => setState(AvatarState.loading);
  void onThinking() => setState(AvatarState.thinking);

  /// Welcome animation - for first-time users
  void onWelcome() => setState(AvatarState.welcome);

  /// Sleeping animation - for inactivity
  void onSleep() => setState(AvatarState.sleeping);

  /// Toggle avatar visibility
  void toggleVisibility() => isVisible.value = !isVisible.value;
  void show() => isVisible.value = true;
  void hide() => isVisible.value = false;

  // ─── GETTERS ─────────────────────────────────────────────────────────

  /// Get current state name (for debugging)
  String get currentStateName => currentState.value.name;

  /// Check if avatar is in idle state
  bool get isIdle => currentState.value == AvatarState.idle;

  /// Check if avatar is sleeping (long inactivity)
  bool get isSleeping => currentState.value == AvatarState.sleeping;

  /// Time since last interaction
  Duration get timeSinceLastInteraction => 
    DateTime.now().difference(_lastInteraction);

  /// Get Lottie animation path based on current state
  String get animationPath => _getAnimationPath(currentState.value);

  /// Get animation URL for remote loading (optional)
  String? get animationUrl => _getAnimationUrl(currentState.value);

  // ─── PRIVATE METHODS ─────────────────────────────────────────────────

  String _getAnimationPath(AvatarState state) {
    const basePath = 'assets/animations/avatar';
    switch (state) {
      case AvatarState.idle:
        return '$basePath/idle.json';
      case AvatarState.wave:
        return '$basePath/wave.json';
      case AvatarState.happy:
        return '$basePath/happy.json';
      case AvatarState.sad:
        return '$basePath/sad.json';
      case AvatarState.look:
        return '$basePath/look.json';
      case AvatarState.thinking:
        return '$basePath/thinking.json';
      case AvatarState.welcome:
        return '$basePath/welcome.json';
      case AvatarState.success:
        return '$basePath/success.json';
      case AvatarState.loading:
        return '$basePath/loading.json';
      case AvatarState.sleeping:
        return '$basePath/sleeping.json';
    }
  }

  String? _getAnimationUrl(AvatarState state) {
    // Optional: Remote Lottie files from CDN
    // Return null to use local assets
    return null;
  }

  // ─── ANALYTICS & DEBUGGING ───────────────────────────────────────────

  /// Get full state report
  Map<String, dynamic> get debugReport => {
    'current_state': currentStateName,
    'previous_state': _previousState?.name,
    'is_visible': isVisible.value,
    'is_transitioning': isTransitioning.value,
    'time_since_interaction': timeSinceLastInteraction.inSeconds,
    'animation_path': animationPath,
  };
}

/// Global instance for easy access
final AvatarController avatar = AvatarController();
