import 'package:get/get.dart';
import 'package:methna_app/app/data/services/analytics_service.dart';

/// Controller for the Analytics / Insights screen.
class AnalyticsController extends GetxController {
  final AnalyticsService _analyticsService = Get.find<AnalyticsService>();

  ProfileAnalytics get data => _analyticsService.analytics.value;
  RxBool get isLoading => _analyticsService.isLoading;

  @override
  void onInit() {
    super.onInit();
    _analyticsService.fetchAnalytics();
  }

  /// Refresh analytics data.
  @override
  Future<void> refresh() => _analyticsService.fetchAnalytics();

  /// Track a screen view event.
  void trackScreenView(String screenName) {
    _analyticsService.trackEvent('screen_view', data: {'screen': screenName});
  }

  /// Track a user action event.
  void trackAction(String action, {Map<String, dynamic>? extra}) {
    _analyticsService.trackEvent('user_action', data: {
      'action': action,
      ...?extra,
    });
  }
}
