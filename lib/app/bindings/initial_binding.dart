import 'package:get/get.dart';
import 'package:methna_app/app/data/services/apple_billing_service.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/data/services/app_update_service.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:methna_app/app/data/services/play_billing_service.dart';
import 'package:methna_app/app/data/services/verification_service.dart';
import 'package:methna_app/app/data/services/subscription_service.dart';
import 'package:methna_app/app/data/services/biometric_service.dart';
import 'package:methna_app/app/data/services/boost_service.dart';
import 'package:methna_app/app/data/services/analytics_service.dart';
import 'package:methna_app/app/data/services/cache_service.dart';
import 'package:methna_app/app/controllers/splash_controller.dart';
import 'package:methna_app/app/controllers/navigation_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Lazily create app-level services so splash can paint before less-critical
    // objects are instantiated.
    Get.lazyPut<CacheService>(() => CacheService(), fenix: true);
    Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    if (!Get.isRegistered<AppUpdateService>()) {
      Get.lazyPut<AppUpdateService>(() => AppUpdateService(), fenix: true);
    }
    Get.lazyPut<PlayBillingService>(() {
      final service = PlayBillingService();
      service.init();
      return service;
    }, fenix: true);
    Get.lazyPut<AppleBillingService>(() {
      final service = AppleBillingService();
      service.init();
      return service;
    }, fenix: true);
    Get.lazyPut<MonetizationService>(() => MonetizationService(), fenix: true);
    Get.lazyPut<VerificationService>(() => VerificationService(), fenix: true);
    Get.lazyPut<SubscriptionService>(() => SubscriptionService(), fenix: true);
    Get.lazyPut<BiometricService>(() => BiometricService(), fenix: true);
    Get.lazyPut<BoostService>(() => BoostService(), fenix: true);
    Get.lazyPut<AnalyticsService>(() => AnalyticsService(), fenix: true);

    // Global controllers
    Get.lazyPut<NavigationController>(
      () => NavigationController(),
      fenix: true,
    );

    // Splash
    Get.lazyPut(() => SplashController());
  }
}
