import 'package:flutter/services.dart';

/// Haptic and Sound Feedback Service for Premium Interactions
/// Provides subtle tactile and audio feedback for user actions
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  bool _hapticsEnabled = true;
  bool _soundEnabled = true;

  /// Initialize the service
  void initialize({bool hapticsEnabled = true, bool soundEnabled = true}) {
    _hapticsEnabled = hapticsEnabled;
    _soundEnabled = soundEnabled;
  }

  // ─── HAPTIC FEEDBACK ─────────────────────────────────────────────

  /// Light impact - for subtle interactions (hover, scroll)
  void lightImpact() {
    if (!_hapticsEnabled) return;
    HapticFeedback.lightImpact();
  }

  /// Medium impact - for standard button presses
  void mediumImpact() {
    if (!_hapticsEnabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact - for significant actions (swipe, match)
  void heavyImpact() {
    if (!_hapticsEnabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Selection click - for picker/selection changes
  void selectionClick() {
    if (!_hapticsEnabled) return;
    HapticFeedback.selectionClick();
  }

  /// Success vibration pattern - for successful actions (match, sent)
  void success() async {
    if (!_hapticsEnabled) return;
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    HapticFeedback.lightImpact();
  }

  /// Error vibration pattern - for errors or rejections
  void error() async {
    if (!_hapticsEnabled) return;
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.heavyImpact();
  }

  /// Match celebration - for successful matches
  void match() async {
    if (!_hapticsEnabled) return;
    // Pattern: medium-light-medium (celebration feel)
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    HapticFeedback.lightImpact();
  }

  /// Swipe feedback - direction based
  void swipeLeft() {
    if (!_hapticsEnabled) return;
    HapticFeedback.mediumImpact();
  }

  void swipeRight() {
    if (!_hapticsEnabled) return;
    success(); // Success pattern for likes
  }

  void swipeUp() {
    if (!_hapticsEnabled) return;
    heavyImpact(); // Strong feedback for super-like/compliment
  }

  // ─── SOUND FEEDBACK (Placeholder for sound implementation) ─────

  /// Button click sound
  void buttonClick() {
    if (!_soundEnabled) return;
    // Audio hooks can be wired in later; haptics keep the interaction responsive for now.
    selectionClick();
  }

  /// Like/match sound
  void likeSound() {
    if (!_soundEnabled) return;
    // Placeholder for pleasant chime
  }

  /// Pass/decline sound
  void passSound() {
    if (!_soundEnabled) return;
    // Placeholder for subtle whoosh
  }

  /// Super like/compliment sound
  void superLikeSound() {
    if (!_soundEnabled) return;
    // Placeholder for special chime
  }

  /// Message sent sound
  void messageSent() {
    if (!_soundEnabled) return;
    // Placeholder for gentle send sound
  }

  /// Match celebration sound
  void matchSound() {
    if (!_soundEnabled) return;
    // Placeholder for celebration sound
  }

  // ─── COMBINED FEEDBACK ───────────────────────────────────────────

  /// Button press with both haptic and sound
  void buttonPress() {
    mediumImpact();
    buttonClick();
  }

  /// Like action with celebration feedback
  void like() {
    success();
    likeSound();
  }

  /// Pass action with subtle feedback
  void pass() {
    swipeLeft();
    passSound();
  }

  /// Compliment/super like with strong feedback
  void compliment() {
    swipeUp();
    superLikeSound();
  }

  /// Match celebration with full feedback
  void onMatch() {
    match();
    matchSound();
  }

  // ─── SETTINGS ────────────────────────────────────────────────────

  void setHapticsEnabled(bool enabled) => _hapticsEnabled = enabled;
  void setSoundEnabled(bool enabled) => _soundEnabled = enabled;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get soundEnabled => _soundEnabled;
}

/// Global instance for easy access
final FeedbackService feedback = FeedbackService();
