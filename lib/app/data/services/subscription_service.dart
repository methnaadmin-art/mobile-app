import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/core/constants/api_constants.dart';

class SubscriptionService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  // Reactive state
  final RxString currentPlan = 'free'.obs;
  final RxString status = 'inactive'.obs;
  final Rx<DateTime?> expiresAt = Rx<DateTime?>(null);
  final RxBool isActive = false.obs;
  final RxList<Map<String, dynamic>> availablePlans =
      <Map<String, dynamic>>[].obs;

  // ─── Fetch current subscription ─────────────────────────
  Future<void> fetchMySubscription() async {
    try {
      final response = await _api.get(ApiConstants.mobileSubscriptionMe);
      final data = _extractRootMap(response.data);
      final planEntity = data['planEntity'];
      final planEntityCode = planEntity is Map ? planEntity['code'] : null;
      currentPlan.value =
          (planEntityCode ??
                  data['plan'] ??
                  data['name'] ??
                  data['tier'] ??
                  'free')
              .toString();
      status.value = (data['status'] ?? 'inactive').toString();
      final normalizedPlan = _normalizePlanToken(currentPlan.value);
      final normalizedStatus = status.value.trim().toLowerCase();
      final expiryRaw =
          data['expiresAt'] ?? data['endDate'] ?? data['end_date'];
      if (expiryRaw != null) {
        expiresAt.value = DateTime.tryParse(expiryRaw.toString());
      } else {
        expiresAt.value = null;
      }

      final isExpiredByDate =
          expiresAt.value != null && expiresAt.value!.isBefore(DateTime.now());
      final isTrialPlan = _isTrialPlan(normalizedPlan);

      if (isTrialPlan &&
          (isExpiredByDate ||
              normalizedStatus == 'expired' ||
              normalizedStatus == 'inactive' ||
              normalizedStatus == 'cancelled')) {
        _applyFreePlanState();
        return;
      }

      isActive.value =
          (normalizedStatus == 'active' ||
              normalizedStatus == 'pending_cancellation' ||
              normalizedStatus == 'past_due' ||
              normalizedStatus == 'trial') &&
          !isExpiredByDate;
    } catch (e) {
      debugPrint('[SubscriptionService] fetchMySubscription error: $e');
      _applyFreePlanState();
    }
  }

  // ─── Fetch available plans ──────────────────────────────
  Future<List<Map<String, dynamic>>> fetchPlans() async {
    try {
      final response = await _api.get(ApiConstants.publicPlans);
      final root = _extractRootMap(response.data);
      final list = response.data is List
          ? response.data
          : root['plans'] ?? root['items'] ?? root['results'] ?? [];
      availablePlans.value = List<Map<String, dynamic>>.from(list);
      return availablePlans;
    } catch (e) {
      debugPrint('[SubscriptionService] fetchPlans error: $e');
      return [];
    }
  }

  // ─── Subscribe to a plan ────────────────────────────────
  Future<bool> subscribe(
    String plan, {
    int durationDays = 30,
    String? paymentReference,
  }) async {
    try {
      await fetchMySubscription();
      if (isCurrentPlanActive(plan)) {
        debugPrint(
          '[SubscriptionService] Skipping subscribe for active current plan: $plan',
        );
        return false;
      }

      final data = <String, dynamic>{
        'plan': plan,
        'durationDays': durationDays,
      };
      if (paymentReference != null) {
        data['paymentReference'] = paymentReference;
      }
      await _api.post(ApiConstants.subscriptionCreate, data: data);
      await fetchMySubscription();
      return true;
    } catch (e) {
      debugPrint('[SubscriptionService] subscribe error: $e');
      return false;
    }
  }

  // ─── Cancel subscription ────────────────────────────────
  Future<bool> cancelSubscription() async {
    try {
      await _api.delete(ApiConstants.subscriptionCancel);
      await fetchMySubscription();
      return true;
    } catch (e) {
      debugPrint('[SubscriptionService] cancelSubscription error: $e');
      return false;
    }
  }

  bool isCurrentPlanActive(String planCode) {
    final normalizedTarget = _normalizePlanToken(planCode);
    if (normalizedTarget.isEmpty || normalizedTarget == 'free') {
      return false;
    }

    final normalizedCurrent = _normalizePlanToken(currentPlan.value);
    if (normalizedCurrent.isEmpty || normalizedCurrent == 'free') {
      return false;
    }

    final samePlan = _plansRepresentSameSubscription(
      normalizedCurrent,
      normalizedTarget,
    );
    if (!samePlan) {
      return false;
    }

    final hasRemainingPeriod =
        expiresAt.value == null || expiresAt.value!.isAfter(DateTime.now());
    if (!hasRemainingPeriod) {
      return false;
    }

    return _hasActiveEntitlementStatus(status.value);
  }

  // ─── Computed ───────────────────────────────────────────
  bool get isPremium => _hasServerBackedPremium;
  bool get isExpired =>
      expiresAt.value != null && expiresAt.value!.isBefore(DateTime.now());

  int get daysRemaining {
    final expiry = expiresAt.value;
    if (expiry == null) return 0;
    final now = DateTime.now();
    if (!expiry.isAfter(now)) return 0;
    // Round UP so a fresh 7-day purchase consistently shows 7 (not 6 due to
    // sub-second drift between server/client clocks). Use minute precision
    // to avoid second-level truncation bugs.
    final diffMinutes = expiry.difference(now).inMinutes;
    final days = (diffMinutes / (60 * 24)).ceil();
    return days > 0 ? days : 1;
  }

  Map<String, dynamic> _extractRootMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final nested = raw['data'];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
      if (nested is Map) {
        return Map<String, dynamic>.from(nested);
      }
      return raw;
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final nested = map['data'];
      if (nested is Map) {
        return Map<String, dynamic>.from(nested);
      }
      return map;
    }
    return <String, dynamic>{};
  }

  /// Immediately apply subscription state from a login/Google sign-in response.
  /// This ensures the client has the correct premium state without waiting for
  /// a separate subscription fetch, preventing stale entitlement leaks between
  /// different user accounts on the same device.
  void applyFromLoginResponse(Map<String, dynamic> sub) {
    final plan = (sub['plan'] ?? 'free').toString();
    final subStatus = (sub['status'] ?? 'inactive').toString();
    final endDateRaw = sub['endDate'] ?? sub['expiresAt'] ?? sub['end_date'];

    currentPlan.value = plan;
    status.value = subStatus;
    if (endDateRaw != null) {
      expiresAt.value = DateTime.tryParse(endDateRaw.toString());
    } else {
      expiresAt.value = null;
    }

    final normalizedPlan = _normalizePlanToken(plan);
    final normalizedStatus = subStatus.trim().toLowerCase();
    final isExpiredByDate =
        expiresAt.value != null && expiresAt.value!.isBefore(DateTime.now());
    final isTrialPlan = _isTrialPlan(normalizedPlan);

    if (isTrialPlan &&
        (isExpiredByDate ||
            normalizedStatus == 'expired' ||
            normalizedStatus == 'inactive' ||
            normalizedStatus == 'cancelled')) {
      _applyFreePlanState();
      return;
    }

    isActive.value =
        (normalizedStatus == 'active' ||
            normalizedStatus == 'pending_cancellation' ||
            normalizedStatus == 'past_due' ||
            normalizedStatus == 'trial') &&
        !isExpiredByDate;

    debugPrint(
      '[SubscriptionService] applyFromLoginResponse: plan=$plan status=$subStatus active=${isActive.value}',
    );
  }

  /// Full reset for logout. Clears the available plans catalogue too so a
  /// new user session starts with a fresh fetch.
  void resetForLogout() {
    _applyFreePlanState();
    availablePlans.clear();
  }

  void _applyFreePlanState() {
    currentPlan.value = 'free';
    status.value = 'inactive';
    isActive.value = false;
    expiresAt.value = null;
  }

  bool get _hasServerBackedPremium {
    final normalizedPlan = _normalizePlanToken(currentPlan.value);
    if (normalizedPlan.isEmpty || normalizedPlan == 'free') {
      return false;
    }

    final hasRemainingPeriod =
        expiresAt.value == null || expiresAt.value!.isAfter(DateTime.now());
    if (!hasRemainingPeriod) {
      return false;
    }

    return _hasActiveEntitlementStatus(status.value);
  }

  bool _hasActiveEntitlementStatus(String rawStatus) {
    final normalizedStatus = rawStatus.trim().toLowerCase();
    return isActive.value ||
        normalizedStatus == 'active' ||
        normalizedStatus == 'pending_cancellation' ||
        normalizedStatus == 'past_due' ||
        normalizedStatus == 'trial';
  }

  String _normalizePlanToken(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  bool _isTrialPlan(String normalizedPlan) {
    if (normalizedPlan.isEmpty) return false;
    if (normalizedPlan == 'trial') return true;
    return normalizedPlan.contains('trial');
  }

  static String _extractTier(String normalizedPlan) {
    if (normalizedPlan.contains('gold')) return 'gold';
    if (normalizedPlan.contains('premium')) return 'premium';
    if (normalizedPlan.contains('elite')) return 'gold';
    return normalizedPlan;
  }

  static bool _plansRepresentSameSubscription(
    String normalizedCurrent,
    String normalizedTarget,
  ) {
    if (normalizedCurrent == normalizedTarget) {
      return true;
    }

    if (_extractTier(normalizedCurrent) != _extractTier(normalizedTarget)) {
      return false;
    }

    return _isGenericPlanToken(normalizedCurrent) ||
        _isGenericPlanToken(normalizedTarget);
  }

  static bool _isGenericPlanToken(String normalizedPlan) {
    return normalizedPlan == 'premium' ||
        normalizedPlan == 'gold' ||
        normalizedPlan == 'elite';
  }
}
