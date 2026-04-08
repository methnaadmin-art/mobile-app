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
      final response = await _api.get(ApiConstants.subscriptionMe);
      final data = _extractRootMap(response.data);
      currentPlan.value =
          (data['plan'] ?? data['name'] ?? data['tier'] ?? 'free').toString();
      status.value = (data['status'] ?? 'inactive').toString();
      final normalizedPlan = _normalizePlanToken(currentPlan.value);
      final normalizedStatus = status.value.trim().toLowerCase();
      if (data['expiresAt'] != null) {
        expiresAt.value = DateTime.tryParse(data['expiresAt'].toString());
      } else {
        expiresAt.value = null;
      }

      final isExpiredByDate =
          expiresAt.value != null &&
          expiresAt.value!.isBefore(DateTime.now());
      final isTrialPlan = _isTrialPlan(normalizedPlan);

      if (isTrialPlan &&
          (isExpiredByDate ||
              normalizedStatus == 'expired' ||
              normalizedStatus == 'inactive' ||
              normalizedStatus == 'cancelled')) {
        _applyFreePlanState();
        return;
      }

      isActive.value = normalizedStatus == 'active' && !isExpiredByDate;
    } catch (_) {
      _applyFreePlanState();
    }
  }

  // ─── Fetch available plans ──────────────────────────────
  Future<List<Map<String, dynamic>>> fetchPlans() async {
    try {
      final response = await _api.get(ApiConstants.subscriptionPlans);
      final root = _extractRootMap(response.data);
      final list = response.data is List
          ? response.data
          : root['plans'] ?? root['items'] ?? root['results'] ?? [];
      availablePlans.value = List<Map<String, dynamic>>.from(list);
      return availablePlans;
    } catch (_) {
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
    } catch (_) {
      return false;
    }
  }

  // ─── Cancel subscription ────────────────────────────────
  Future<bool> cancelSubscription() async {
    try {
      await _api.delete(ApiConstants.subscriptionCancel);
      currentPlan.value = 'free';
      isActive.value = false;
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Computed ───────────────────────────────────────────
  bool get isPremium => currentPlan.value != 'free' && isActive.value;
  bool get isExpired =>
      expiresAt.value != null && expiresAt.value!.isBefore(DateTime.now());

  int get daysRemaining {
    if (expiresAt.value == null) return 0;
    final diff = expiresAt.value!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
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

  void _applyFreePlanState() {
    currentPlan.value = 'free';
    status.value = 'inactive';
    isActive.value = false;
    expiresAt.value = null;
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
}
