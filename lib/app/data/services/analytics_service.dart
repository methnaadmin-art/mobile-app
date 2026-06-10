import 'package:get/get.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/app/data/services/api_service.dart';

/// Model for profile analytics data.
class ProfileAnalytics {
  final int totalViews;
  final int todayViews;
  final int totalLikes;
  final int totalMatches;
  final int totalSuperLikes;
  final double matchRate;
  final List<DailyViewData> weeklyViews;

  ProfileAnalytics({
    this.totalViews = 0,
    this.todayViews = 0,
    this.totalLikes = 0,
    this.totalMatches = 0,
    this.totalSuperLikes = 0,
    this.matchRate = 0,
    this.weeklyViews = const [],
  });

  factory ProfileAnalytics.fromJson(Map<String, dynamic> json) =>
      ProfileAnalytics(
        totalViews: json['totalViews'] ?? 0,
        todayViews: json['todayViews'] ?? 0,
        totalLikes: json['totalLikes'] ?? 0,
        totalMatches: json['totalMatches'] ?? 0,
        totalSuperLikes: json['totalSuperLikes'] ?? 0,
        matchRate: (json['matchRate'] ?? 0).toDouble(),
        weeklyViews: (json['weeklyViews'] as List?)
                ?.map((e) => DailyViewData.fromJson(e))
                .toList() ??
            [],
      );
}

/// Single day of view data.
class DailyViewData {
  final String day;
  final int views;

  DailyViewData({required this.day, required this.views});

  factory DailyViewData.fromJson(Map<String, dynamic> json) => DailyViewData(
        day: json['day'] ?? '',
        views: json['views'] ?? 0,
      );
}

/// Service for fetching and tracking user analytics.
class AnalyticsService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  final Rx<ProfileAnalytics> analytics = ProfileAnalytics().obs;
  final RxBool isLoading = false.obs;

  /// Fetch profile analytics from backend.
  Future<void> fetchAnalytics() async {
    try {
      isLoading.value = true;
      final response = await _api.get(ApiConstants.analytics);
      analytics.value = ProfileAnalytics.fromJson(response.data);
    } catch (_) {
      // Silently keep existing data
    } finally {
      isLoading.value = false;
    }
  }

  /// Track an app event (screen view, action, etc.).
  Future<void> trackEvent(String event, {Map<String, dynamic>? data}) async {
    try {
      await _api.post(ApiConstants.analyticsTrack, data: {
        'event': event,
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      });
    } catch (_) {
      // Non-blocking; analytics failures should not impact UX
    }
  }
}
