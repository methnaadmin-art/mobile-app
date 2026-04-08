import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:methna_app/core/constants/app_constants.dart';

/// TrialManager - Manages 3-day free trial for new users
/// - Tracks trial start time persistently
/// - Checks trial expiration
/// - Provides trial status to UI components
/// - Handles trial-to-paid transitions
class TrialManager extends GetxService {
  static final TrialManager _instance = TrialManager._internal();
  factory TrialManager() => _instance;
  TrialManager._internal();

  final _storage = GetStorage();
  final RxBool _isTrialActive = false.obs;
  final Rx<Duration> _trialTimeRemaining = Duration.zero.obs;
  final RxBool _hasTrialBeenShown = false.obs;
  final RxBool _isPremiumPurchased = false.obs;

  Timer? _countdownTimer;
  bool _initialized = false;

  // Constants
  static const String _trialStartKey = 'trial_start_date';
  static const String _trialShownKey = 'trial_welcome_shown';
  static const String _premiumPurchasedKey = 'premium_purchased';
  static const Duration trialDuration = Duration(days: 3);

  /// Initialize trial manager
  Future<TrialManager> init() async {
    if (_initialized) return this;
    _initialized = true;
    await _loadTrialState();
    _startCountdownTimer();
    return this;
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    super.onClose();
  }

  // ─── PUBLIC GETTERS ─────────────────────────────────────────────────

  /// Is user currently in active trial period
  bool get isTrialActive => _isTrialActive.value;

  /// Time remaining in trial
  Duration get trialTimeRemaining => _trialTimeRemaining.value;

  /// Has trial welcome been shown to user
  bool get hasTrialBeenShown => _hasTrialBeenShown.value;

  /// Has user purchased premium (ending trial early)
  bool get isPremiumPurchased => _isPremiumPurchased.value;

  /// Is user effectively premium (trial OR purchased)
  bool get isEffectivePremium => isTrialActive || isPremiumPurchased;

  /// Trial expiration date
  DateTime? get trialExpirationDate {
    final startDate = _getTrialStartDate();
    if (startDate == null) return null;
    return startDate.add(trialDuration);
  }

  /// Is trial expired (was active but now ended)
  bool get isTrialExpired {
    final startDate = _getTrialStartDate();
    if (startDate == null) return false; // Never had trial
    final isExpired = DateTime.now().difference(startDate) >= trialDuration;
    return isExpired && !isPremiumPurchased;
  }

  /// Hours remaining in trial
  int get hoursRemaining => trialTimeRemaining.inHours;

  /// Minutes remaining in trial (for display)
  String get formattedTimeRemaining {
    final remaining = trialTimeRemaining;
    if (remaining.inDays > 0) {
      return '${remaining.inDays}d ${remaining.inHours % 24}h';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    } else {
      return '${remaining.inMinutes}m';
    }
  }

  /// Stream for trial status changes
  Stream<bool> get trialStatusStream => _isTrialActive.stream;

  // ─── TRIAL INITIALIZATION ───────────────────────────────────────────

  /// Start trial for new user (called on signup)
  void startTrial() {
    final now = DateTime.now();
    _storage.write(_trialStartKey, now.toIso8601String());
    _storage.write(_trialShownKey, false);
    _isTrialActive.value = true;
    _trialTimeRemaining.value = trialDuration;
    _hasTrialBeenShown.value = false;

    debugPrint('[TrialManager] Trial started at: $now');
    _startCountdownTimer();
  }

  /// Mark trial welcome as shown
  void markTrialWelcomeShown() {
    _storage.write(_trialShownKey, true);
    _hasTrialBeenShown.value = true;
  }

  /// Mark premium as purchased (ends trial, enables premium)
  void markPremiumPurchased() {
    _storage.write(_premiumPurchasedKey, true);
    _isPremiumPurchased.value = true;
    _isTrialActive.value = false; // Trial ends when premium purchased
    _countdownTimer?.cancel();
    debugPrint('[TrialManager] Premium purchased - trial ended');
  }

  // ─── PRIVATE METHODS ─────────────────────────────────────────────────

  DateTime? _getTrialStartDate() {
    final stored = _storage.read<String>(_trialStartKey);
    if (stored == null) return null;
    try {
      return DateTime.parse(stored);
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadTrialState() async {
    // Check if premium was purchased
    _isPremiumPurchased.value =
        _storage.read<bool>(_premiumPurchasedKey) ?? false;

    // Check trial state
    final startDate = _getTrialStartDate();
    if (startDate != null) {
      final elapsed = DateTime.now().difference(startDate);
      final remaining = trialDuration - elapsed;

      _isTrialActive.value =
          remaining.isNegative == false && !isPremiumPurchased;
      _trialTimeRemaining.value = remaining.isNegative
          ? Duration.zero
          : remaining;
      _hasTrialBeenShown.value = _storage.read<bool>(_trialShownKey) ?? false;

      debugPrint(
        '[TrialManager] Loaded trial state: active=$_isTrialActive, remaining=${_trialTimeRemaining.value}',
      );
    } else {
      // No trial started yet - check if user exists in auth
      _checkAndStartTrialForExistingUser();
    }
  }

  void _checkAndStartTrialForExistingUser() {
    final rawUser = _storage.read<String>(AppConstants.userKey);
    if (rawUser == null || rawUser.isEmpty || _getTrialStartDate() != null) {
      return;
    }

    try {
      final parsed = jsonDecode(rawUser);
      if (parsed is! Map<String, dynamic>) return;
      final createdAtRaw = parsed['createdAt']?.toString();
      if (createdAtRaw == null || createdAtRaw.isEmpty) return;

      final userCreatedAt = DateTime.tryParse(createdAtRaw);
      if (userCreatedAt == null) return;

      final elapsed = DateTime.now().difference(userCreatedAt);
      if (elapsed < trialDuration) {
        _storage.write(_trialStartKey, userCreatedAt.toIso8601String());
        _isTrialActive.value = true;
        _trialTimeRemaining.value = trialDuration - elapsed;
        debugPrint('[TrialManager] Auto-started trial from cached user data');
      }
    } catch (_) {
      // Ignore malformed cached user payloads.
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    if (!isTrialActive) return;

    // Update every minute
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateTrialStatus();
    });

    // Also update immediately
    _updateTrialStatus();
  }

  void _updateTrialStatus() {
    final startDate = _getTrialStartDate();
    if (startDate == null) return;

    final elapsed = DateTime.now().difference(startDate);
    final remaining = trialDuration - elapsed;

    if (remaining.isNegative || remaining == Duration.zero) {
      // Trial ended
      _isTrialActive.value = false;
      _trialTimeRemaining.value = Duration.zero;
      _countdownTimer?.cancel();
      debugPrint('[TrialManager] Trial expired');

      // Notify listeners
      _onTrialExpired();
    } else {
      _trialTimeRemaining.value = remaining;
    }
  }

  void _onTrialExpired() {
    // Could trigger notifications, analytics, etc.
    debugPrint('[TrialManager] Trial expired - premium features blocked');
  }

  // ─── UTILITY METHODS ─────────────────────────────────────────────────

  /// Check if a specific premium feature is available
  bool canAccessPremiumFeature(String featureName) {
    return isEffectivePremium;
  }

  /// Get trial status for analytics
  Map<String, dynamic> get analyticsPayload => {
    'trial_active': isTrialActive,
    'trial_hours_remaining': hoursRemaining,
    'trial_expired': isTrialExpired,
    'premium_purchased': isPremiumPurchased,
  };

  /// Reset trial (for testing only)
  @visibleForTesting
  void resetTrial() {
    _storage.remove(_trialStartKey);
    _storage.remove(_trialShownKey);
    _storage.remove(_premiumPurchasedKey);
    _isTrialActive.value = false;
    _trialTimeRemaining.value = Duration.zero;
    _hasTrialBeenShown.value = false;
    _isPremiumPurchased.value = false;
    _countdownTimer?.cancel();
    debugPrint('[TrialManager] Trial reset');
  }

  /// Set trial remaining time (for testing only)
  @visibleForTesting
  void setTrialRemaining(Duration remaining) {
    final startTime = DateTime.now().subtract(trialDuration - remaining);
    _storage.write(_trialStartKey, startTime.toIso8601String());
    _isTrialActive.value = remaining.isNegative == false;
    _trialTimeRemaining.value = remaining.isNegative
        ? Duration.zero
        : remaining;
    _startCountdownTimer();
  }
}

/// Global instance
final TrialManager trialManager = TrialManager();
