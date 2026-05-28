import 'package:get/get.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/app/data/services/api_service.dart';

/// Model representing an active profile boost.
class BoostStatus {
  final bool isActive;
  final DateTime? expiresAt;
  final int remainingBoosts;
  final int totalViews;

  BoostStatus({
    this.isActive = false,
    this.expiresAt,
    this.remainingBoosts = 0,
    this.totalViews = 0,
  });

  factory BoostStatus.fromJson(Map<String, dynamic> json) => BoostStatus(
        isActive: json['isActive'] ?? false,
        expiresAt: json['expiresAt'] != null
            ? DateTime.tryParse(json['expiresAt'])
            : null,
        remainingBoosts: json['remainingBoosts'] ?? 0,
        totalViews: json['totalViews'] ?? 0,
      );

  /// Minutes left until boost expires; 0 if inactive.
  int get minutesRemaining {
    if (!isActive || expiresAt == null) return 0;
    final diff = expiresAt!.difference(DateTime.now()).inMinutes;
    return diff > 0 ? diff : 0;
  }
}

/// Service for managing profile boosts.
class BoostService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  final Rx<BoostStatus> status = BoostStatus().obs;
  final RxBool isLoading = false.obs;

  /// Fetch current boost status from backend.
  Future<void> fetchStatus() async {
    try {
      isLoading.value = true;
      final response = await _api.get(ApiConstants.boostStatus);
      final raw = response.data;
      if (raw is Map) {
        final root = Map<String, dynamic>.from(raw);
        final boost = raw['boost'] is Map
            ? Map<String, dynamic>.from(raw['boost'] as Map)
            : <String, dynamic>{};
        status.value = BoostStatus.fromJson({
          ...boost,
          'isActive': root['isActive'] ?? boost['isActive'] ?? false,
        });
      }
    } catch (_) {
      // Keep current status on error
    } finally {
      isLoading.value = false;
    }
  }

  /// Activate a new boost.
  Future<bool> activateBoost() async {
    try {
      isLoading.value = true;
      await _api.post(
        ApiConstants.boostActivate,
        data: const {'durationMinutes': 30},
      );
      await fetchStatus();
      return true;
    } catch (_) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Purchase boost package (returns payment intent or success flag).
  Future<Map<String, dynamic>?> purchaseBoost(String packageId) async {
    try {
      final response = await _api.post(
        ApiConstants.boostPurchase,
        data: {'packageId': packageId, 'durationMinutes': 30},
      );
      await fetchStatus();
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return <String, dynamic>{'success': true};
    } catch (_) {
      return null;
    }
  }
}
