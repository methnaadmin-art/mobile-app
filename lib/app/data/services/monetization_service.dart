// ignore_for_file: use_null_aware_elements

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/data/services/apple_billing_service.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/data/services/play_billing_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/data/services/subscription_service.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/constants/app_constants.dart';
import 'package:methna_app/core/constants/play_billing_constants.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:url_launcher/url_launcher.dart';

class MonetizationService extends GetxService {
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static const String featureAdvancedFilters = 'advanced_filters';
  static const String featureBoost = 'boost';
  static const String featureLikes = 'likes';
  static const String featureCompliments = 'compliments';
  static const String featureRewind = 'rewind';
  static const String featureWhoLikedMe = 'who_liked_me';
  static const String featurePassport = 'passport_mode';
  static const String featureInvisibleMode = 'invisible_mode';
  static const String featureGhostMode = featureInvisibleMode;

  bool get supportsInAppPurchases =>
      !kIsWeb &&
      (GetPlatform.isAndroid || GetPlatform.isIOS || GetPlatform.isMacOS);

  bool get isIosPurchaseFallback =>
      !kIsWeb && (GetPlatform.isIOS || GetPlatform.isMacOS);

  String get platformPurchaseUnavailableMessage =>
      'Purchases are not currently offered on this device.';

  static const Map<String, List<String>> _featureAliases = {
    featureAdvancedFilters: [
      'advanced_filters',
      'advanced_filter',
      'filters_advanced',
      'premium_filters',
      'advanced_match_filters',
    ],
    featureBoost: [
      'boost',
      'boosts',
      'profile_boost',
      'profile_boosts',
      'boost_profile',
      'profileBoostPriority',
      'profileboostpriority',
      'priorityMatching',
      'prioritymatching',
    ],
    featureLikes: [
      'likes',
      'like',
      'unlimitedlikes',
      'unlimited_likes',
      'dailylikes',
      'daily_likes',
      'likeslimit',
      'likes_limit',
    ],
    featureCompliments: [
      'compliments',
      'compliment',
      'dailycompliments',
      'daily_compliments',
      'complimentslimit',
      'compliments_limit',
      'complimentcredits',
      'compliment_credits',
    ],
    featureRewind: [
      'rewind',
      'rewinds',
      'monthlyrewinds',
      'monthly_rewinds',
      'unlimitedrewinds',
      'unlimited_rewinds',
      'canrewind',
      'can_rewind',
    ],
    featureWhoLikedMe: [
      'who_liked_me',
      'who_likes_me',
      'see_who_liked_you',
      'whoLikedMe',
      'seeWhoLikesYou',
      'liked_you',
      'likes_received',
    ],
    featurePassport: [
      'passport',
      'passport_mode',
      'passportMode',
      'travel_mode',
      'global_mode',
    ],
    featureInvisibleMode: [
      'invisible',
      'invisible_mode',
      'ghost',
      'ghost_mode',
      'ghostMode',
      'incognito',
      'incognito_mode',
    ],
  };

  final ApiService _api = Get.find<ApiService>();
  PlayBillingService? get _playBillingService =>
      Get.isRegistered<PlayBillingService>()
      ? Get.find<PlayBillingService>()
      : null;
  AppleBillingService? get _appleBillingService =>
      Get.isRegistered<AppleBillingService>()
      ? Get.find<AppleBillingService>()
      : null;
  // Reactive state
  final RxString currentPlan = 'free'.obs;
  final RxString status = 'inactive'.obs;
  final Rx<DateTime?> expiresAt = Rx<DateTime?>(null);
  final RxBool isActive = false.obs;
  final RxList<String> features = <String>[].obs;
  final RxInt remainingLikes = 25.obs;
  final RxBool isUnlimitedLikes = false.obs;
  final RxBool isBoosted = false.obs;
  final RxBool isInvisible = false.obs;
  final RxBool canRewind = true.obs;
  final RxInt remainingCompliments = 0.obs;
  final RxString subscriptionPlanId = ''.obs;
  final RxList<Map<String, dynamic>> activePlans = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> statusPlanFeatures = <String, dynamic>{}.obs;

  // ─── Payment flow state ──────────────────────────────────
  final Rx<PaymentFlowState> paymentFlow = PaymentFlowState.idle.obs;
  final RxString paymentPlanName = ''.obs;

  Timer? _pollTimer;
  int _pollAttempts = 0;
  static const int _maxPollAttempts = 30; // 60s at 2s interval
  static const Duration _pollInterval = Duration(seconds: 2);

  // ─── Fetch full status ──────────────────────────────────
  Future<void> fetchStatus() async {
    try {
      final response = await _api.get(ApiConstants.mobileSubscriptionMe);
      final data = _extractRootMap(response.data);
      final normalizedData = Map<String, dynamic>.from(data);
      final planEntity = _asMap(normalizedData['planEntity']);
      if (!normalizedData.containsKey('planFeatures') &&
          planEntity['features'] != null) {
        normalizedData['planFeatures'] = planEntity['features'];
      }
      if (!normalizedData.containsKey('features') &&
          planEntity['features'] != null) {
        normalizedData['features'] = planEntity['features'];
      }
      if (!normalizedData.containsKey('limits') &&
          planEntity['limits'] != null) {
        normalizedData['limits'] = planEntity['limits'];
      }
      final planEntityCode = _readFirstString(planEntity, const ['code']);
      currentPlan.value =
          planEntityCode ??
          _readFirstString(normalizedData, const [
            'plan',
            'currentPlan',
            'subscriptionPlan',
          ]) ??
          'free';
      subscriptionPlanId.value =
          _readFirstString(normalizedData, const [
            'subscriptionPlanId',
            'planId',
          ]) ??
          _readFirstString(planEntity, const ['id']) ??
          subscriptionPlanId.value;

      status.value = (normalizedData['status'] ?? 'inactive').toString();
      final normalizedStatus = status.value.trim().toLowerCase();
      final expiryRaw =
          normalizedData['expiresAt'] ??
          normalizedData['endDate'] ??
          normalizedData['end_date'];
      if (expiryRaw != null) {
        expiresAt.value = DateTime.tryParse(expiryRaw.toString());
      } else {
        expiresAt.value = null;
      }

      _syncFeatureStateFromStatusPayload(normalizedData);
      _syncVisibilityStateFromStatusPayload(normalizedData);
      _syncSubscriptionServiceSnapshot(normalizedData, planEntity: planEntity);

      final isExpiredByDate =
          expiresAt.value != null && expiresAt.value!.isBefore(DateTime.now());
      final isTrialPlan = _isTrialPlan(_normalizePlanToken(currentPlan.value));

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
      return;
    } catch (e) {
      debugPrint('[Monetization] fetchStatus canonical fallback: $e');
    }

    try {
      final response = await _api.get(ApiConstants.monetizationStatus);
      final data = _extractRootMap(response.data);

      subscriptionPlanId.value =
          _readFirstString(data, const ['subscriptionPlanId', 'planId']) ??
          subscriptionPlanId.value;

      _syncFeatureStateFromStatusPayload(data);
      _syncVisibilityStateFromStatusPayload(data);
      _syncSubscriptionServiceSnapshot(data);

      final likes = _asMap(data['remainingLikes']);
      isUnlimitedLikes.value = likes['isUnlimited'] ?? false;
      remainingLikes.value = likes['remaining'] ?? 0;

      final boost = _asMap(data['boost']);
      isBoosted.value = boost['isActive'] ?? false;
    } catch (e) {
      debugPrint(
        '[Monetization] fetchStatus error (retaining current state): $e',
      );
    }
  }

  // ─── Fetch all limits ───────────────────────────────────
  void _syncSubscriptionServiceSnapshot(
    Map<String, dynamic> data, {
    Map<String, dynamic>? planEntity,
  }) {
    if (!Get.isRegistered<SubscriptionService>()) return;

    final entity = planEntity ?? _asMap(data['planEntity']);
    final planCode =
        _readFirstString(entity, const ['code']) ??
        _readFirstString(data, const ['plan', 'currentPlan', 'subscriptionPlan']) ??
        currentPlan.value;

    final payload = <String, dynamic>{
      'plan': planCode,
      'status': (data['status'] ?? status.value).toString(),
      'expiresAt':
          data['expiresAt'] ??
          data['endDate'] ??
          data['end_date'] ??
          expiresAt.value?.toIso8601String(),
    };

    Get.find<SubscriptionService>().applyFromLoginResponse(payload);
  }

  Future<Map<String, dynamic>> fetchAllLimits() async {
    try {
      final entitlementData = await fetchEntitlements();
      final entMap = _asMap(entitlementData['entitlements'] ?? entitlementData);
      if (entMap.isNotEmpty) {
        final rewinds = _readInt(entMap['monthlyRewinds']);
        canRewind.value =
            _hasRemainingOrUnlimited(rewinds) ||
            entMap['unlimitedRewinds'] == true;

        final likes = _readInt(entMap['dailyLikes'] ?? entMap['likesLimit']);
        if (likes != null) {
          isUnlimitedLikes.value = likes == -1;
        }

        // Do NOT overwrite remainingLikes / remainingCompliments here.
        // fetchEntitlements() already triggers fetchRemainingLikes() and
        // fetchRemainingCompliments() which hit the dedicated endpoints
        // that return the accurate server-side remaining counts.

        return entitlementData;
      }
    } catch (e) {
      debugPrint('[Monetization] fetchAllLimits canonical fallback: $e');
    }

    try {
      final response = await _api.get(ApiConstants.allLimits);
      final data = _extractRootMap(response.data);
      canRewind.value = data['canRewind'] ?? false;

      final compliments = _asMap(data['remainingCompliments']);
      remainingCompliments.value = compliments['remaining'] ?? 0;

      final likes = _asMap(data['remainingLikes']);
      isUnlimitedLikes.value = likes['isUnlimited'] ?? false;
      remainingLikes.value = likes['remaining'] ?? 0;
      return data;
    } catch (_) {
      return {};
    }
  }

  // ─── Features ───────────────────────────────────────────
  Future<List<String>> fetchFeatures() async {
    final entitlementData = await fetchEntitlements();
    if (features.isNotEmpty) {
      return features;
    }

    try {
      final response = await _api.get(ApiConstants.monetizationFeatures);
      final data = _extractRootMap(response.data);
      final raw = response.data is List ? response.data : data['features'];
      if (raw is List) {
        features.value = raw.map((f) => f.toString()).toList();
      } else if (raw is Map) {
        features.value = raw.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key.toString())
            .toList();
      } else {
        features.clear();
      }
      return features;
    } catch (_) {
      final fallbackFeatures =
          _asMap(entitlementData['entitlements'] ?? entitlementData).entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key)
              .toList();
      features.value = fallbackFeatures;
      return features;
    }
  }

  bool hasFeature(String feature) => hasEntitlement(feature);

  Map<String, dynamic>? get currentSubscribedPlanMetadata =>
      _resolveCurrentPlanData();

  bool hasEntitlement(
    String feature, {
    bool fallbackToPremiumOnUnknown = false,
  }) {
    final resolved = _resolveFeatureEntitlement(feature);
    if (resolved != null) {
      return resolved;
    }
    return fallbackToPremiumOnUnknown ? isPremium : false;
  }

  bool get hasAdvancedFiltersAccess =>
      hasEntitlement(featureAdvancedFilters, fallbackToPremiumOnUnknown: true);

  bool get hasBoostAccess =>
      hasEntitlement(featureBoost, fallbackToPremiumOnUnknown: true);

  bool get hasLikesFeatureAccess =>
      hasEntitlement(featureLikes, fallbackToPremiumOnUnknown: true);

  bool get hasComplimentsFeatureAccess =>
      hasEntitlement(featureCompliments, fallbackToPremiumOnUnknown: true);

  bool get hasRewindFeatureAccess =>
      hasEntitlement(featureRewind, fallbackToPremiumOnUnknown: true);

  bool get hasWhoLikedMeAccess =>
      hasEntitlement(featureWhoLikedMe, fallbackToPremiumOnUnknown: true);

  bool get hasPassportAccess =>
      hasEntitlement(featurePassport, fallbackToPremiumOnUnknown: true);

  bool get hasGhostModeAccess =>
      hasEntitlement(featureInvisibleMode, fallbackToPremiumOnUnknown: true);

  bool get canUseLikes =>
      isUnlimitedLikes.value ||
      remainingLikes.value > 0 ||
      hasLikesFeatureAccess;

  bool get canUseCompliments =>
      remainingCompliments.value > 0 || hasComplimentsFeatureAccess;

  bool get canUseRewind => canRewind.value || hasRewindFeatureAccess;

  bool get isPremium => _hasServerBackedPremium || _hasPlayBillingEntitlement;

  @override
  void onInit() {
    super.onInit();
    final playBilling = _playBillingService;
    if (playBilling != null) {
      unawaited(playBilling.init());
    }
    final appleBilling = _appleBillingService;
    if (appleBilling != null) {
      unawaited(appleBilling.init());
    }
  }

  // ─── Remaining Likes ────────────────────────────────────
  Future<void> fetchRemainingLikes() async {
    try {
      final response = await _api.get(ApiConstants.remainingLikes);
      isUnlimitedLikes.value = response.data['isUnlimited'] ?? false;
      remainingLikes.value = response.data['remaining'] ?? 0;
    } catch (e) {
      debugPrint('[Monetization] fetchRemainingLikes error: $e');
    }
  }

  // ─── Active Plans ───────────────────────────────────────
  Future<void> fetchActivePlans() async {
    try {
      final response = await _api.get(ApiConstants.activePlans);
      final data = _extractRootMap(response.data);
      final list = _extractList(response.data, data, const [
        'plans',
        'items',
        'results',
        'data',
      ]);
      final plans = List<Map<String, dynamic>>.from(list);
      activePlans.value = plans
          .where(_isPlanPurchasableOnCurrentPlatform)
          .toList(growable: false);
      final playBilling = _playBillingService;
      if (playBilling != null &&
          GetPlatform.isAndroid &&
          activePlans.isNotEmpty) {
        unawaited(playBilling.prefetchPlans(activePlans));
      }
      final appleBilling = _appleBillingService;
      if (appleBilling != null &&
          (GetPlatform.isIOS || GetPlatform.isMacOS) &&
          activePlans.isNotEmpty) {
        unawaited(appleBilling.prefetchPlans(activePlans));
      }
    } catch (e) {
      debugPrint('[Monetization] fetchActivePlans error: $e');
    }
  }

  bool _isPlanPurchasableOnCurrentPlatform(Map<String, dynamic> plan) {
    final priceRaw = plan['price'] ?? plan['amount'] ?? plan['cost'];
    final price = priceRaw is num
        ? priceRaw.toDouble()
        : double.tryParse(priceRaw?.toString() ?? '') ?? 0;
    if (price <= 0) {
      return true;
    }

    if (GetPlatform.isIOS || GetPlatform.isMacOS) {
      final appleProductId =
          _readFirstString(plan, const ['appleProductId', 'iosProductId']) ??
          '';
      return appleProductId.trim().isNotEmpty;
    }

    if (GetPlatform.isAndroid) {
      final googleProductId =
          _readFirstString(plan, const ['googleProductId', 'androidProductId']) ??
          '';
      final googleBasePlanId =
          _readFirstString(plan, const ['googleBasePlanId']) ?? '';
      return googleProductId.trim().isNotEmpty &&
          googleBasePlanId.trim().isNotEmpty;
    }

    return true;
  }

  /// Returns the store-localized price string (e.g. "US$4.99",
  /// "2,99 €") for the given plan, or `null` when the product isn't loaded
  /// from the active platform store yet (or platform is unsupported).
  ///
  /// The subscription screen should prefer this over the backend's numeric
  /// price so the user sees the actual price they'll be charged in their
  /// store account currency.
  String? localizedPriceForPlan(Map<String, dynamic> plan) {
    if (GetPlatform.isIOS || GetPlatform.isMacOS) {
      final appleBilling = _appleBillingService;
      if (appleBilling == null) return null;

      final planCode = (plan['code'] ?? plan['planCode'] ?? plan['id'] ?? '')
          .toString()
          .trim();
      final durationRaw = plan['durationDays'] ?? plan['duration_days'] ?? 30;
      final durationDays = durationRaw is num
          ? durationRaw.toInt()
          : int.tryParse(durationRaw.toString()) ?? 30;

      final product = appleBilling.productForPlan(
        planCode: planCode,
        durationDays: durationDays,
        planMetadata: plan,
      );
      final price = product?.price.trim();
      if (price == null || price.isEmpty) return null;
      return price;
    }

    final playBilling = _playBillingService;
    if (playBilling == null) return null;

    final planCode = (plan['code'] ?? plan['planCode'] ?? plan['id'] ?? '')
        .toString()
        .trim();
    final durationRaw = plan['durationDays'] ?? plan['duration_days'] ?? 30;
    final durationDays = durationRaw is num
        ? durationRaw.toInt()
        : int.tryParse(durationRaw.toString()) ?? 30;

    final product = playBilling.productForPlan(
      planCode: planCode,
      durationDays: durationDays,
      planMetadata: plan,
    );
    final price = product?.price.trim();
    if (price == null || price.isEmpty) return null;
    return price;
  }

  bool get isAppleStorePurchasePlatform =>
      !kIsWeb && (GetPlatform.isIOS || GetPlatform.isMacOS);

  bool isStoreProductReadyForPlan(Map<String, dynamic> plan) {
    final planCode = (plan['code'] ?? plan['planCode'] ?? plan['id'] ?? '')
        .toString()
        .trim();
    final durationRaw = plan['durationDays'] ?? plan['duration_days'] ?? 30;
    final durationDays = durationRaw is num
        ? durationRaw.toInt()
        : int.tryParse(durationRaw.toString()) ?? 30;

    if (isAppleStorePurchasePlatform) {
      final appleBilling = _appleBillingService;
      if (appleBilling == null) return false;
      return appleBilling.isStoreProductLoadedForPlan(
        planCode: planCode,
        durationDays: durationDays,
        planMetadata: plan,
      );
    }

    if (!kIsWeb && GetPlatform.isAndroid) {
      final playBilling = _playBillingService;
      if (playBilling == null) return false;
      return playBilling.productForPlan(
            planCode: planCode,
            durationDays: durationDays,
            planMetadata: plan,
          ) !=
          null;
    }

    return false;
  }

  String? get currentPurchaseFailureMessage {
    if (isAppleStorePurchasePlatform) {
      final message = _appleBillingService?.purchaseMessage.value.trim() ?? '';
      return message.isEmpty ? null : message;
    }

    if (!kIsWeb && GetPlatform.isAndroid) {
      final message = _playBillingService?.purchaseMessage.value.trim() ?? '';
      return message.isEmpty ? null : message;
    }

    return null;
  }

  /// Ensures ProductDetails for the current active plans are
  /// loaded. Safe to call repeatedly — `loadProducts` dedupes internally.
  Future<void> ensureStorePricesLoaded() async {
    if (GetPlatform.isIOS || GetPlatform.isMacOS) {
      final appleBilling = _appleBillingService;
      if (appleBilling == null || activePlans.isEmpty) return;
      await appleBilling.prefetchPlans(activePlans);
      return;
    }

    final playBilling = _playBillingService;
    if (playBilling == null || activePlans.isEmpty) return;
    await playBilling.prefetchPlans(activePlans);
  }

  // ─── Purchase Subscription ──────────────────────────────
  Future<bool> purchaseSubscription(
    String planCode,
    int durationDays, {
    Map<String, dynamic>? planMetadata,
  }) async {
    if (!supportsInAppPurchases) {
      paymentFlow.value = PaymentFlowState.failed;
      if (isIosPurchaseFallback) {
        Helpers.showSnackbar(
          message: platformPurchaseUnavailableMessage,
          isError: true,
        );
      }
      return false;
    }

    if (GetPlatform.isIOS || GetPlatform.isMacOS) {
      return _purchaseWithApple(
        planCode,
        durationDays,
        planMetadata: planMetadata,
      );
    }

    return _purchaseWithGooglePlay(
      planCode,
      durationDays,
      planMetadata: planMetadata,
    );
  }

  Future<bool> _purchaseWithApple(
    String planCode,
    int durationDays, {
    Map<String, dynamic>? planMetadata,
  }) async {
    final appleBilling = _appleBillingService;
    if (appleBilling == null) {
      paymentFlow.value = PaymentFlowState.failed;
      return false;
    }

    await appleBilling.init();
    paymentFlow.value = PaymentFlowState.creating;
    paymentPlanName.value = planCode;
    paymentFlow.value = PaymentFlowState.redirecting;

    final resolvedProductId = appleBilling.resolveProductIdForPlan(
      planCode: planCode,
      durationDays: durationDays,
      planMetadata: planMetadata,
    );
    debugPrint(
      '[Monetization] Apple purchase start planCode=$planCode '
      'durationDays=$durationDays '
      'resolvedProductId=${resolvedProductId ?? 'null'} '
      'storeProductReady=${planMetadata == null ? false : isStoreProductReadyForPlan(planMetadata)}',
    );

    final userId = Get.isRegistered<AuthService>()
        ? Get.find<AuthService>().currentUser.value?.id
        : null;
    final outcome = await appleBilling.purchaseSubscription(
      planCode: planCode,
      durationDays: durationDays,
      planMetadata: planMetadata,
      accountId: userId,
    );
    debugPrint(
      '[Monetization] Apple purchase outcome type=${outcome.type} '
      'productId=${outcome.productId ?? resolvedProductId ?? 'null'} '
      'message=${outcome.message ?? appleBilling.purchaseMessage.value}',
    );

    if (outcome.type == AppleBillingPurchaseOutcomeType.cancelled) {
      paymentFlow.value = PaymentFlowState.cancelled;
      return false;
    }

    if (outcome.type == AppleBillingPurchaseOutcomeType.error ||
        outcome.type == AppleBillingPurchaseOutcomeType.productNotFound ||
        outcome.type == AppleBillingPurchaseOutcomeType.unavailable) {
      paymentFlow.value = PaymentFlowState.failed;
      return false;
    }

    if (outcome.type == AppleBillingPurchaseOutcomeType.pending) {
      paymentFlow.value = PaymentFlowState.confirming;
      _startPolling();
      return true;
    }

    _applyImmediatePlanActivation(
      planCode: planCode,
      durationDays: durationDays,
      planMetadata: planMetadata,
    );

    await _refreshMonetizationState();
    if (isPremium) {
      paymentFlow.value = PaymentFlowState.success;
      return true;
    }

    paymentFlow.value = PaymentFlowState.confirming;
    _startPolling();
    return true;
  }

  Future<bool> _purchaseWithGooglePlay(
    String planCode,
    int durationDays, {
    Map<String, dynamic>? planMetadata,
  }) async {
    final playBilling = _playBillingService;
    if (playBilling == null) {
      paymentFlow.value = PaymentFlowState.failed;
      return false;
    }

    await playBilling.init();
    paymentFlow.value = PaymentFlowState.creating;
    paymentPlanName.value = planCode;

    // Show checkout handoff state while Google Play sheet is opening.
    paymentFlow.value = PaymentFlowState.redirecting;

    final outcome = await playBilling.purchaseSubscription(
      planCode: planCode,
      durationDays: durationDays,
      planMetadata: planMetadata,
    );

    if (outcome.type == PlayBillingPurchaseOutcomeType.cancelled) {
      paymentFlow.value = PaymentFlowState.cancelled;
      return false;
    }

    if (outcome.type == PlayBillingPurchaseOutcomeType.error ||
        outcome.type == PlayBillingPurchaseOutcomeType.productNotFound ||
        outcome.type == PlayBillingPurchaseOutcomeType.unavailable) {
      paymentFlow.value = PaymentFlowState.failed;
      return false;
    }

    if (outcome.type == PlayBillingPurchaseOutcomeType.pending) {
      paymentFlow.value = PaymentFlowState.confirming;
      _startPolling();
      return true;
    }

    final isCompletedPurchase =
        outcome.type == PlayBillingPurchaseOutcomeType.purchased ||
        outcome.type == PlayBillingPurchaseOutcomeType.restored ||
        outcome.type == PlayBillingPurchaseOutcomeType.alreadyOwned;
    if (isCompletedPurchase) {
      _applyImmediatePlanActivation(
        planCode: planCode,
        durationDays: durationDays,
        planMetadata: planMetadata,
      );
    }

    // Fast-path: apply entitlement from PlayBillingService local state immediately
    if (playBilling.hasActiveEntitlement.value) {
      final billingPlanCode = playBilling.activePlanCode.value.trim();
      if (billingPlanCode.isNotEmpty &&
          billingPlanCode.toLowerCase() != 'free') {
        currentPlan.value = billingPlanCode;
        status.value = 'active';
        isActive.value = true;
        // Keep SubscriptionService in sync so subscription screen matches
        if (Get.isRegistered<SubscriptionService>()) {
          final subService = Get.find<SubscriptionService>();
          subService.currentPlan.value = billingPlanCode;
          subService.status.value = 'active';
          subService.isActive.value = true;
        }
      }
    }

    await _refreshMonetizationState();
    if (isPremium) {
      paymentFlow.value = PaymentFlowState.success;
      return true;
    }

    paymentFlow.value = PaymentFlowState.confirming;
    _startPolling();
    return true;
  }

  /// Called when the app resumes from background.
  void onAppResumed() {
    final playBilling = _playBillingService;
    if (playBilling != null && GetPlatform.isAndroid) {
      unawaited(playBilling.syncOwnedPurchases(silent: true));
    }
    final appleBilling = _appleBillingService;
    if (appleBilling != null && (GetPlatform.isIOS || GetPlatform.isMacOS)) {
      unawaited(appleBilling.restorePurchases());
    }
  }

  /// Called when a deep link brings the user back (payment-success or payment-cancel).
  void onDeepLinkReturn(String path) {
    final normalizedPath = path.toLowerCase();
    final isCancel =
        normalizedPath.contains('payment-cancel') ||
        normalizedPath.contains('billing-cancel');
    final isSuccess =
        normalizedPath.contains('payment-success') ||
        normalizedPath.contains('billing-success');

    if (isCancel) {
      debugPrint('[Monetization] Billing cancelled via deep link');
      _resetPaymentFlow();
      paymentFlow.value = PaymentFlowState.cancelled;
      return;
    }

    if (isSuccess) {
      _ensureSubscriptionRouteOpen();
      if (paymentFlow.value == PaymentFlowState.idle ||
          paymentFlow.value == PaymentFlowState.failed ||
          paymentFlow.value == PaymentFlowState.timeout) {
        paymentFlow.value = PaymentFlowState.confirming;
      }
      debugPrint(
        '[Monetization] Billing success deep link received — starting entitlement polling',
      );
      _startPolling();
    }
  }

  /// Start polling for subscription activation.
  /// Retries every 2s for up to 60s. Stops immediately when subscription activates.
  void _startPolling() {
    _pollTimer?.cancel();
    _pollAttempts = 0;
    paymentFlow.value = PaymentFlowState.confirming;

    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      _pollAttempts++;
      debugPrint(
        '[Monetization] Polling attempt $_pollAttempts/$_maxPollAttempts',
      );

      try {
        await _refreshMonetizationState();
        if (isPremium) {
          debugPrint(
            '[Monetization] Subscription activated via webhook (attempt $_pollAttempts)',
          );
          _stopPolling();
          paymentFlow.value = PaymentFlowState.success;
          return;
        }
      } catch (e) {
        debugPrint('[Monetization] Poll refresh error: $e');
      }

      if (_pollAttempts >= _maxPollAttempts) {
        debugPrint(
          '[Monetization] Polling timed out — webhook may still activate subscription',
        );
        _stopPolling();
        paymentFlow.value = PaymentFlowState.timeout;
      }
    });
  }

  /// Stop the polling timer.
  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  bool isPlanCurrentlySubscribed(String planCode) {
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

  bool isExactPlanCurrent(Map<String, dynamic> plan) {
    if (!_hasAnyActiveSubscriptionEntitlement) {
      return false;
    }

    if (_isPlanMarkedCurrent(plan)) {
      return true;
    }

    final currentPlan = _resolveCurrentPlanData();
    if (currentPlan == null) {
      return false;
    }

    return _plansReferToSameCatalogPlan(currentPlan, plan);
  }

  void _ensureSubscriptionRouteOpen() {
    if (Get.currentRoute == AppRoutes.subscription) {
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 60), () async {
      if (Get.currentRoute == AppRoutes.subscription) {
        return;
      }
      try {
        await Get.toNamed(AppRoutes.subscription);
      } catch (e) {
        debugPrint('[Monetization] Unable to open subscription route: $e');
      }
    });
  }

  /// Reset payment flow state completely.
  void _resetPaymentFlow() {
    _stopPolling();
    _pollAttempts = 0;
    paymentFlow.value = PaymentFlowState.idle;
  }

  /// Manually retry polling after a timeout (user-initiated).
  Future<void> retryPolling() async {
    if (paymentFlow.value == PaymentFlowState.timeout ||
        paymentFlow.value == PaymentFlowState.failed) {
      _startPolling();
    }
  }

  /// Dismiss the payment flow overlay.
  void dismissPaymentFlow() {
    _resetPaymentFlow();
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  Future<bool> restoreSubscriptionState() async {
    try {
      final playBilling = _playBillingService;
      if (!kIsWeb && GetPlatform.isAndroid && playBilling != null) {
        await playBilling.init();
        await playBilling.restorePurchases();
      }
      final appleBilling = _appleBillingService;
      if (!kIsWeb &&
          (GetPlatform.isIOS || GetPlatform.isMacOS) &&
          appleBilling != null) {
        await appleBilling.init();
        await appleBilling.restorePurchases();
      }

      await _refreshMonetizationState();
      final hasPremiumViaSubscription =
          Get.isRegistered<SubscriptionService>() &&
          Get.find<SubscriptionService>().isPremium;
      return isPremium || hasPremiumViaSubscription;
    } catch (e) {
      debugPrint('[Monetization] restoreSubscriptionState error: $e');
      return false;
    }
  }

  // ─── Boost ──────────────────────────────────────────────
  Future<void> _refreshMonetizationState() async {
    await Future.wait([
      fetchStatus(),
      fetchAllLimits(),
      fetchActivePlans(),
      fetchRemainingLikes(),
      fetchRemainingCompliments(),
      fetchEntitlements(),
    ]);

    if (Get.isRegistered<SubscriptionService>()) {
      await Get.find<SubscriptionService>().fetchMySubscription();
    }
    if (Get.isRegistered<AuthService>()) {
      await Get.find<AuthService>().fetchMe();
    }
  }

  void _applyImmediatePlanActivation({
    required String planCode,
    required int durationDays,
    Map<String, dynamic>? planMetadata,
  }) {
    final normalizedPlan = _normalizePlanToken(planCode);
    if (normalizedPlan.isEmpty || normalizedPlan == 'free') {
      return;
    }

    currentPlan.value = planCode;
    status.value = 'active';
    isActive.value = true;

    if (durationDays > 0) {
      final candidateExpiry = DateTime.now().add(Duration(days: durationDays));
      if (expiresAt.value == null ||
          expiresAt.value!.isBefore(candidateExpiry)) {
        expiresAt.value = candidateExpiry;
      }
    }

    final metadata = _asMap(planMetadata);
    final planId = _readFirstString(metadata, const [
      'subscriptionPlanId',
      'planId',
      'id',
    ]);
    if (planId != null && planId.isNotEmpty) {
      subscriptionPlanId.value = planId;
    }

    final featureMatrix = _extractPlanFeatureMatrix(metadata);
    if (featureMatrix.isNotEmpty) {
      statusPlanFeatures
        ..clear()
        ..addAll(featureMatrix);
      _syncFeatureStateFromStatusPayload({
        'features': featureMatrix,
        'planFeatures': featureMatrix,
      });
      _applyInstantLimitsFromPlanMatrix(featureMatrix);
    }

    if (Get.isRegistered<SubscriptionService>()) {
      final subscription = Get.find<SubscriptionService>();
      subscription.currentPlan.value = planCode;
      subscription.status.value = 'active';
      subscription.isActive.value = true;
      if (expiresAt.value != null) {
        subscription.expiresAt.value = expiresAt.value;
      }
    }
  }

  Map<String, dynamic> _extractPlanFeatureMatrix(
    Map<String, dynamic> metadata,
  ) {
    if (metadata.isEmpty) {
      return <String, dynamic>{};
    }

    final matrix = <String, dynamic>{};

    void mergeMap(dynamic value) {
      final parsed = _asMap(value);
      if (parsed.isNotEmpty) {
        matrix.addAll(parsed);
      }
    }

    mergeMap(metadata['featureFlags']);
    mergeMap(metadata['limits']);
    mergeMap(metadata['entitlements']);

    final rawFeatures = metadata['features'];
    if (rawFeatures is List) {
      for (final feature in rawFeatures) {
        final token = feature.toString().trim();
        if (token.isNotEmpty) {
          matrix[token] = true;
        }
      }
    } else {
      mergeMap(rawFeatures);
    }

    const directFeatureKeys = [
      'advancedFilters',
      'seeWhoLikesYou',
      'whoLikedMe',
      'passportMode',
      'invisibleMode',
      'ghostMode',
      'boost',
      'likes',
      'compliments',
      'rewind',
      'dailyLikes',
      'likesLimit',
      'dailyCompliments',
      'complimentsLimit',
      'monthlyRewinds',
      'weeklyBoosts',
      'boostsLimit',
      'unlimitedLikes',
      'unlimitedRewinds',
      'canRewind',
    ];

    for (final key in directFeatureKeys) {
      if (metadata.containsKey(key)) {
        matrix[key] = metadata[key];
      }
    }

    final legacyDailyLikes = _readInt(metadata['dailyLikesLimit']);
    if (legacyDailyLikes != null && !matrix.containsKey('dailyLikes')) {
      matrix['dailyLikes'] = legacyDailyLikes;
    }

    final legacyDailyCompliments = _readInt(metadata['dailyComplimentsLimit']);
    if (legacyDailyCompliments != null &&
        !matrix.containsKey('dailyCompliments')) {
      matrix['dailyCompliments'] = legacyDailyCompliments;
    }

    final legacyMonthlyRewinds = _readInt(metadata['monthlyRewindsLimit']);
    if (legacyMonthlyRewinds != null && !matrix.containsKey('monthlyRewinds')) {
      matrix['monthlyRewinds'] = legacyMonthlyRewinds;
    }

    final legacyWeeklyBoosts = _readInt(metadata['weeklyBoostsLimit']);
    if (legacyWeeklyBoosts != null && !matrix.containsKey('weeklyBoosts')) {
      matrix['weeklyBoosts'] = legacyWeeklyBoosts;
    }

    return matrix;
  }

  void _applyInstantLimitsFromPlanMatrix(Map<String, dynamic> matrix) {
    final likesLimit = _readInt(matrix['dailyLikes'] ?? matrix['likesLimit']);
    if (likesLimit != null) {
      if (likesLimit == -1) {
        isUnlimitedLikes.value = true;
        if (remainingLikes.value < 999999) {
          remainingLikes.value = 999999;
        }
      } else if (likesLimit > 0) {
        isUnlimitedLikes.value = false;
        if (remainingLikes.value < likesLimit) {
          remainingLikes.value = likesLimit;
        }
      }
    }

    final complimentsLimit = _readInt(
      matrix['dailyCompliments'] ?? matrix['complimentsLimit'],
    );
    if (complimentsLimit != null) {
      if (complimentsLimit == -1) {
        if (remainingCompliments.value < 999999) {
          remainingCompliments.value = 999999;
        }
      } else if (complimentsLimit > 0 &&
          remainingCompliments.value < complimentsLimit) {
        remainingCompliments.value = complimentsLimit;
      }
    }

    final rewindsLimit = _readInt(matrix['monthlyRewinds']);
    if (_hasRemainingOrUnlimited(rewindsLimit) ||
        _isTruthy(matrix['unlimitedRewinds']) ||
        _isTruthy(matrix['canRewind'])) {
      canRewind.value = true;
    }
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  Map<String, dynamic> _extractRootMap(dynamic raw) {
    final map = _asMap(raw);
    final nested = _asMap(map['data']);
    if (nested.isNotEmpty) {
      return nested;
    }
    return map;
  }

  List<dynamic> _extractList(
    dynamic raw,
    Map<String, dynamic> root,
    List<String> keys,
  ) {
    if (raw is List) return raw;
    for (final key in keys) {
      final candidate = root[key];
      if (candidate is List) {
        return candidate;
      }
    }
    return const <dynamic>[];
  }

  void _syncFeatureStateFromStatusPayload(Map<String, dynamic> data) {
    final mergedFeatures = <String>{...features};

    final rawFeatures = data['features'];
    if (rawFeatures is List) {
      for (final feature in rawFeatures) {
        final token = feature.toString().trim();
        if (token.isNotEmpty) {
          mergedFeatures.add(token);
        }
      }
    } else if (rawFeatures is Map) {
      rawFeatures.forEach((key, value) {
        if (_isTruthy(value)) {
          mergedFeatures.add(key.toString());
        }
      });
    }

    if (data.containsKey('planFeatures')) {
      final planFeatureMap = _asMap(data['planFeatures']);
      statusPlanFeatures
        ..clear()
        ..addAll(planFeatureMap);

      if (planFeatureMap.isNotEmpty) {
        planFeatureMap.forEach((key, value) {
          if (_isTruthy(value)) {
            mergedFeatures.add(key.toString());
          }
        });

        final likesLimit = _readInt(
          planFeatureMap['likesLimit'] ?? planFeatureMap['dailyLikes'],
        );
        if (likesLimit != null) {
          isUnlimitedLikes.value = likesLimit == -1;
        }
      }
    }

    if (mergedFeatures.isNotEmpty) {
      features.value = mergedFeatures.toList(growable: false);
    }
  }

  void _syncVisibilityStateFromStatusPayload(Map<String, dynamic> data) {
    final visibility = _asMap(data['visibility']);

    final ghostRaw =
        visibility['isGhostModeEnabled'] ??
        visibility['isInvisible'] ??
        data['isGhostModeEnabled'] ??
        data['isInvisible'];
    if (ghostRaw != null) {
      isInvisible.value = _isTruthy(ghostRaw);
    }

    final passportActiveRaw =
        visibility['isPassportActive'] ?? data['isPassportActive'];
    final passport = _extractLocationPayload(
      visibility['passportLocation'] ?? data['passportLocation'],
    );

    if (passportActiveRaw != null && !_isTruthy(passportActiveRaw)) {
      passportLocation.value = null;
      return;
    }

    if (passport != null) {
      passportLocation.value = passport;
    }
  }

  Map<String, dynamic>? _extractLocationPayload(dynamic payload) {
    final root = _asMap(payload);
    if (root.isEmpty) {
      return null;
    }

    final nested = _asMap(root['location']);
    final source = nested.isNotEmpty ? nested : root;

    final latitude = _readDouble(source['latitude']);
    final longitude = _readDouble(source['longitude']);
    final city = _readFirstString(source, const [
      'city',
      'cityName',
      'city_name',
    ]);
    final country = _readFirstString(source, const [
      'country',
      'countryName',
      'country_name',
    ]);

    if (latitude == null &&
        longitude == null &&
        (city == null || city.isEmpty) &&
        (country == null || country.isEmpty)) {
      return null;
    }

    return {
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
    };
  }

  Future<void> openManageSubscriptionCenter() async {
    if (isIosPurchaseFallback) {
      const itunesUri = 'itms-apps://apps.apple.com/account/subscriptions';
      const httpsUri = 'https://apps.apple.com/account/subscriptions';
      if (await canLaunchUrl(Uri.parse(itunesUri))) {
        await launchUrl(
          Uri.parse(itunesUri),
          mode: LaunchMode.externalApplication,
        );
        return;
      }
      if (await canLaunchUrl(Uri.parse(httpsUri))) {
        await launchUrl(
          Uri.parse(httpsUri),
          mode: LaunchMode.externalApplication,
        );
        return;
      }
      Helpers.showSnackbar(message: 'could_not_open_link'.tr, isError: true);
      return;
    }

    if (!kIsWeb && GetPlatform.isAndroid) {
      final playBilling = _playBillingService;
      if (playBilling != null) {
        await playBilling.openManageSubscription();
        return;
      }
    }

    try {
      final response = await _api.get(ApiConstants.paymentManageUrl);
      final data = _extractRootMap(response.data);
      final backendUrl = _readFirstString(data, const ['url']);
      if (backendUrl != null && backendUrl.isNotEmpty) {
        final uri = Uri.parse(backendUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }
    } catch (e) {
      debugPrint(
        '[Monetization] Failed to resolve management URL from backend: $e',
      );
    }

    final fallbackUri = Uri.parse(
      'https://play.google.com/store/account/subscriptions',
    );
    if (await canLaunchUrl(fallbackUri)) {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      return;
    }

    final websiteFallback = Uri.parse(
      '${AppConstants.websiteUrl}/account/subscription',
    );
    if (await canLaunchUrl(websiteFallback)) {
      await launchUrl(websiteFallback, mode: LaunchMode.externalApplication);
      return;
    }

    Helpers.showSnackbar(message: 'could_not_open_link'.tr, isError: true);
  }

  String? _readFirstString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  /// Full reset for logout: downgrade to free, zero out counters and clear
  /// any cached Play Billing entitlement so the next user session starts clean.
  Future<void> resetForLogout() async {
    _applyFreePlanState();
    remainingLikes.value = 0;
    remainingCompliments.value = 0;
    canRewind.value = false;
    subscriptionPlanId.value = '';
    activePlans.clear();
    paymentFlow.value = PaymentFlowState.idle;
    paymentPlanName.value = '';
    try {
      final playBilling = _playBillingService;
      if (playBilling != null) {
        await playBilling.clearEntitlementsForLogout();
      }
    } catch (_) {}
  }

  void _applyFreePlanState() {
    currentPlan.value = 'free';
    status.value = 'inactive';
    isActive.value = false;
    expiresAt.value = null;
    features.clear();
    statusPlanFeatures.clear();
    isUnlimitedLikes.value = false;
    isBoosted.value = false;
    isInvisible.value = false;
  }

  bool get _hasPlayBillingEntitlement {
    final playBilling = _playBillingService;
    if (playBilling == null) return false;
    if (!playBilling.hasActiveEntitlement.value) return false;
    final planCode = playBilling.activePlanCode.value.trim().toLowerCase();
    return planCode.isNotEmpty && planCode != 'free';
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

  bool? _resolveFeatureEntitlement(String feature) {
    final aliases = _aliasesFor(feature);
    if (aliases.isEmpty) {
      return null;
    }

    final backendFeatures = _normalizedBackendFeatures();
    if (backendFeatures.any(aliases.contains)) {
      return true;
    }

    final statusFeatureResolution = _resolveFeatureFromMatrix(
      statusPlanFeatures,
      aliases,
    );
    if (statusFeatureResolution != null) {
      return statusFeatureResolution;
    }

    final currentPlanData = _resolveCurrentPlanData();
    if (currentPlanData == null) {
      return null;
    }

    final planFeatures = _normalizedPlanFeatures(currentPlanData);
    if (planFeatures.any(aliases.contains)) {
      return true;
    }

    final canonical = _canonicalFeature(feature);
    switch (canonical) {
      case featureAdvancedFilters:
        return _readFirstBool(currentPlanData, const [
          'advancedFiltersEnabled',
          'canUseAdvancedFilters',
          'hasAdvancedFilters',
          'advancedFilterAccess',
        ]);
      case featureBoost:
        return _readPositiveOrUnlimited(currentPlanData, const [
          'weeklyBoostsLimit',
          'boostsWeeklyLimit',
          'weeklyBoostLimit',
          'boostsPerWeek',
          'weeklyBoosts',
          'boosts',
        ]);
      case featureLikes:
        return _readPositiveOrUnlimited(currentPlanData, const [
          'dailyLikes',
          'likesLimit',
          'dailyLikesLimit',
          'dailySwipeLimit',
          'unlimitedLikes',
        ]);
      case featureCompliments:
        return _readPositiveOrUnlimited(currentPlanData, const [
          'dailyCompliments',
          'complimentsLimit',
          'dailyComplimentsLimit',
          'complimentCredits',
        ]);
      case featureRewind:
        return _readPositiveOrUnlimited(currentPlanData, const [
          'monthlyRewinds',
          'monthlyRewindsLimit',
          'rewindsLimit',
          'unlimitedRewinds',
          'canRewind',
        ]);
      case featureWhoLikedMe:
        return _readFirstBool(currentPlanData, const [
          'whoLikedMeEnabled',
          'canSeeWhoLikedMe',
          'showWhoLikedMe',
          'isWhoLikedMeEnabled',
          'whoLikedMe',
          'seeWhoLikesYou',
        ]);
      case featurePassport:
        return _readFirstBool(currentPlanData, const [
          'passportEnabled',
          'canUsePassport',
          'travelModeEnabled',
          'globalModeEnabled',
          'passportMode',
          'isPassportActive',
        ]);
      case featureInvisibleMode:
        return _readFirstBool(currentPlanData, const [
          'invisibleModeEnabled',
          'canUseInvisibleMode',
          'incognitoEnabled',
          'ghostMode',
          'isGhostModeEnabled',
        ]);
      default:
        return null;
    }
  }

  bool? _resolveFeatureFromMatrix(
    Map<String, dynamic> matrix,
    Set<String> aliases,
  ) {
    if (matrix.isEmpty) {
      return null;
    }

    var sawAlias = false;
    var enabled = false;

    matrix.forEach((key, value) {
      final normalizedKey = _normalizeFeatureToken(key.toString());
      if (!aliases.contains(normalizedKey)) {
        return;
      }

      sawAlias = true;
      if (_isTruthy(value)) {
        enabled = true;
      }
    });

    if (!sawAlias) {
      return null;
    }

    return enabled;
  }

  Set<String> _normalizedBackendFeatures() {
    return features
        .map((item) => _normalizeFeatureToken(item))
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  Set<String> _normalizedPlanFeatures(Map<String, dynamic> plan) {
    final raw = plan['features'];
    final values = <String>{};

    if (raw is List) {
      for (final item in raw) {
        final token = _normalizeFeatureToken(item.toString());
        if (token.isNotEmpty) {
          values.add(token);
        }
      }
      return values;
    }

    if (raw is Map) {
      raw.forEach((key, value) {
        if (_isTruthy(value)) {
          final token = _normalizeFeatureToken(key.toString());
          if (token.isNotEmpty) {
            values.add(token);
          }
        }
      });
    }

    return values;
  }

  Map<String, dynamic>? _resolveCurrentPlanData() {
    if (activePlans.isEmpty) {
      return null;
    }

    for (final plan in activePlans) {
      if (_isPlanMarkedCurrent(plan)) {
        return plan;
      }
    }

    final currentPlanId = subscriptionPlanId.value.trim();
    if (currentPlanId.isNotEmpty) {
      for (final plan in activePlans) {
        final planId = _planIdOf(plan);
        if (planId.isNotEmpty && planId == currentPlanId) {
          return plan;
        }
      }
    }

    final playBilling = _playBillingService;
    if (playBilling != null && playBilling.hasActiveEntitlement.value) {
      final activeProductId = playBilling.activeProductId.value.trim();
      final activeBasePlanId = playBilling.activeBasePlanId.value.trim();
      if (activeProductId.isNotEmpty) {
        for (final plan in activePlans) {
          final planProductId = _productIdOf(plan);
          if (planProductId.isEmpty || planProductId != activeProductId) {
            continue;
          }

          final planBasePlanId = _basePlanIdOf(plan);
          if (activeBasePlanId.isNotEmpty) {
            if (planBasePlanId.isEmpty || planBasePlanId != activeBasePlanId) {
              continue;
            }
          }

          return plan;
        }
      }
    }

    final normalizedCurrentPlan = _normalizePlanToken(currentPlan.value);
    if (normalizedCurrentPlan.isEmpty || normalizedCurrentPlan == 'free') {
      return null;
    }
    final normalizedBillingPlanCode = _normalizePlanToken(
      playBilling?.activePlanCode.value ?? '',
    );
    final normalizedCandidates = <String>{
      normalizedCurrentPlan,
      if (normalizedBillingPlanCode.isNotEmpty &&
          normalizedBillingPlanCode != 'free')
        normalizedBillingPlanCode,
    };

    for (final plan in activePlans) {
      final normalizedPlanCode = _normalizedPlanCodeOf(plan);
      if (normalizedPlanCode.isNotEmpty &&
          normalizedCandidates.contains(normalizedPlanCode)) {
        return plan;
      }
    }

    for (final plan in activePlans) {
      final planTokens = [
        plan['plan'],
        plan['code'],
        plan['slug'],
        plan['tier'],
        plan['name'],
      ];
      for (final token in planTokens) {
        final normalizedPlanToken = _normalizePlanToken(
          token?.toString() ?? '',
        );
        if (normalizedCandidates.contains(normalizedPlanToken) ||
            _plansRepresentSameSubscription(
              normalizedPlanToken,
              normalizedCurrentPlan,
            )) {
          return plan;
        }
      }
    }

    return null;
  }

  bool get _hasAnyActiveSubscriptionEntitlement {
    if (_hasServerBackedPremium) {
      return true;
    }

    final playBilling = _playBillingService;
    if (playBilling == null || !playBilling.hasActiveEntitlement.value) {
      return false;
    }

    final activePlanCode = playBilling.activePlanCode.value
        .trim()
        .toLowerCase();
    return activePlanCode.isNotEmpty && activePlanCode != 'free';
  }

  bool _isPlanMarkedCurrent(Map<String, dynamic> plan) {
    return _isTruthy(plan['isCurrent']) ||
        _isTruthy(plan['current']) ||
        _isTruthy(plan['isCurrentForUser']) ||
        _isTruthy(plan['currentForUser']) ||
        _isTruthy(plan['activeForUser']) ||
        _isTruthy(plan['isSubscribed']) ||
        _isTruthy(plan['subscribed']);
  }

  bool _plansReferToSameCatalogPlan(
    Map<String, dynamic> currentPlan,
    Map<String, dynamic> selectedPlan,
  ) {
    final currentPlanId = _planIdOf(currentPlan);
    final selectedPlanId = _planIdOf(selectedPlan);
    if (currentPlanId.isNotEmpty && selectedPlanId.isNotEmpty) {
      return currentPlanId == selectedPlanId;
    }

    final currentProductId = _productIdOf(currentPlan);
    final selectedProductId = _productIdOf(selectedPlan);
    if (currentProductId.isNotEmpty && selectedProductId.isNotEmpty) {
      if (currentProductId != selectedProductId) {
        return false;
      }

      final currentBasePlanId = _basePlanIdOf(currentPlan);
      final selectedBasePlanId = _basePlanIdOf(selectedPlan);
      if (currentBasePlanId.isNotEmpty || selectedBasePlanId.isNotEmpty) {
        return currentBasePlanId.isNotEmpty &&
            currentBasePlanId == selectedBasePlanId;
      }

      final currentCycle = _billingCycleTokenOf(currentPlan);
      final selectedCycle = _billingCycleTokenOf(selectedPlan);
      if (currentCycle.isNotEmpty || selectedCycle.isNotEmpty) {
        return currentCycle.isNotEmpty && currentCycle == selectedCycle;
      }

      final currentDuration = _durationDaysOf(currentPlan);
      final selectedDuration = _durationDaysOf(selectedPlan);
      if (currentDuration > 0 && selectedDuration > 0) {
        return currentDuration == selectedDuration;
      }

      return true;
    }

    final currentCode = _normalizedPlanCodeOf(currentPlan);
    final selectedCode = _normalizedPlanCodeOf(selectedPlan);
    if (currentCode.isEmpty ||
        selectedCode.isEmpty ||
        currentCode != selectedCode) {
      return false;
    }

    final currentCycle = _billingCycleTokenOf(currentPlan);
    final selectedCycle = _billingCycleTokenOf(selectedPlan);
    if (currentCycle.isNotEmpty || selectedCycle.isNotEmpty) {
      return currentCycle.isNotEmpty && currentCycle == selectedCycle;
    }

    final currentDuration = _durationDaysOf(currentPlan);
    final selectedDuration = _durationDaysOf(selectedPlan);
    if (currentDuration > 0 && selectedDuration > 0) {
      return currentDuration == selectedDuration;
    }

    return true;
  }

  String _planIdOf(Map<String, dynamic> plan) {
    return _readFirstString(plan, const [
          'id',
          'planId',
          'subscriptionPlanId',
        ]) ??
        '';
  }

  String _productIdOf(Map<String, dynamic> plan) {
    return PlayBillingConstants.extractProductId(plan)?.trim() ?? '';
  }

  String _basePlanIdOf(Map<String, dynamic> plan) {
    return PlayBillingConstants.extractBasePlanId(plan)?.trim() ?? '';
  }

  String _normalizedPlanCodeOf(Map<String, dynamic> plan) {
    final rawCode =
        _readFirstString(plan, const [
          'code',
          'planCode',
          'plan',
          'slug',
          'tier',
        ]) ??
        _readFirstString(plan, const ['name']) ??
        '';
    return _normalizePlanToken(rawCode);
  }

  String _billingCycleTokenOf(Map<String, dynamic> plan) {
    final rawCycle =
        _readFirstString(plan, const [
          'billingCycle',
          'billing_cycle',
          'cycle',
        ]) ??
        '';
    final normalizedCycle = _normalizePlanToken(rawCycle);
    if (normalizedCycle == 'annual' || normalizedCycle == 'annually') {
      return 'yearly';
    }
    if (normalizedCycle.isNotEmpty) {
      return normalizedCycle;
    }

    final durationDays = _durationDaysOf(plan);
    if (durationDays >= 300) return 'yearly';
    if (durationDays >= 25) return 'monthly';
    if (durationDays >= 6) return 'weekly';
    return '';
  }

  int _durationDaysOf(Map<String, dynamic> plan) {
    final rawDuration =
        plan['durationDays'] ?? plan['duration_days'] ?? plan['duration'] ?? 0;
    if (rawDuration is num) {
      return rawDuration.toInt();
    }
    return int.tryParse(rawDuration.toString()) ?? 0;
  }

  Set<String> _aliasesFor(String feature) {
    final normalized = _normalizeFeatureToken(feature);
    if (normalized.isEmpty) {
      return const <String>{};
    }

    final canonical = _canonicalFeature(normalized);
    final aliases = <String>{normalized, canonical};
    final mappedAliases = _featureAliases[canonical];
    if (mappedAliases != null) {
      aliases.addAll(
        mappedAliases
            .map((alias) => _normalizeFeatureToken(alias))
            .where((alias) => alias.isNotEmpty),
      );
    }
    return aliases;
  }

  String _canonicalFeature(String feature) {
    final normalized = _normalizeFeatureToken(feature);
    for (final entry in _featureAliases.entries) {
      final canonical = _normalizeFeatureToken(entry.key);
      if (canonical == normalized) {
        return entry.key;
      }

      for (final alias in entry.value) {
        if (_normalizeFeatureToken(alias) == normalized) {
          return entry.key;
        }
      }
    }
    return normalized;
  }

  String _normalizeFeatureToken(String raw) {
    final withWordBoundaries = raw.replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (match) => '${match.group(1)}_${match.group(2)}',
    );

    return withWordBoundaries
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  bool _isTruthy(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  bool? _readFirstBool(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      if (!source.containsKey(key)) {
        continue;
      }
      final value = source[key];
      if (value is bool) return value;
      if (value is num) return value != 0;

      final normalized = value?.toString().trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return null;
  }

  bool? _readPositiveOrUnlimited(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      if (!source.containsKey(key)) {
        continue;
      }
      final rawValue = source[key];
      if (rawValue is bool) {
        return rawValue;
      }

      final parsed = _readInt(rawValue);
      if (parsed != null) {
        return parsed == -1 || parsed > 0;
      }

      if (rawValue != null) {
        final normalized = rawValue.toString().trim().toLowerCase();
        if (normalized == 'true' || normalized == 'yes') {
          return true;
        }
        if (normalized == 'false' || normalized == 'no') {
          return false;
        }
      }
    }
    return null;
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    final asString = value?.toString();
    if (asString == null) return null;
    return int.tryParse(asString.trim());
  }

  double? _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    final asString = value?.toString();
    if (asString == null) return null;
    return double.tryParse(asString.trim());
  }

  bool _hasRemainingOrUnlimited(int? value) {
    if (value == null) return false;
    return value == -1 || value > 0;
  }

  int _remainingFromLimit(int value) {
    if (value == -1) return 999999;
    return value < 0 ? 0 : value;
  }

  Future<bool> purchaseBoost({int durationMinutes = 30}) async {
    try {
      await _api.post(
        ApiConstants.purchaseBoost,
        data: {'durationMinutes': durationMinutes},
      );
      isBoosted.value = true;
      unawaited(fetchBoostStatus());
      unawaited(fetchEntitlements());
      return true;
    } catch (e) {
      throw Exception(Helpers.extractErrorMessage(e));
    }
  }

  Future<void> fetchBoostStatus() async {
    try {
      final response = await _api.get(ApiConstants.boostStatus);
      isBoosted.value = response.data['isActive'] ?? false;
    } catch (_) {}
  }

  // ─── Rewind ─────────────────────────────────────────────
  Future<Map<String, dynamic>?> useRewind() async {
    try {
      final response = await _api.post(ApiConstants.swipeRewind);
      canRewind.value = true; // may still have rewinds
      unawaited(fetchEntitlements());
      return response.data;
    } catch (_) {
      canRewind.value = false;
      return null;
    }
  }

  Future<void> checkCanRewind() async {
    try {
      final response = await _api.get(ApiConstants.rewindCheck);
      canRewind.value = response.data['canRewind'] ?? false;
    } catch (_) {
      canRewind.value = false;
    }
  }

  // ─── Compliment Credits ─────────────────────────────────
  Future<void> fetchRemainingCompliments() async {
    try {
      final response = await _api.get(ApiConstants.complimentsRemaining);
      remainingCompliments.value = response.data['remaining'] ?? 0;
    } catch (_) {}
  }

  // ─── Invisible Mode ────────────────────────────────────
  Future<bool> toggleInvisibleMode(bool enabled) async {
    final previousValue = isInvisible.value;
    isInvisible.value = enabled;

    final payload = <String, dynamic>{
      'enabled': enabled,
      'isInvisible': enabled,
      'isGhostModeEnabled': enabled,
    };

    try {
      try {
        await _api.post(ApiConstants.ghostToggle, data: payload);
      } catch (_) {
        await _api.post(ApiConstants.invisibleToggle, data: payload);
      }
      await fetchInvisibleStatus();
      unawaited(fetchEntitlements());
      return true;
    } catch (_) {
      isInvisible.value = previousValue;
      return false;
    }
  }

  Future<void> fetchInvisibleStatus() async {
    try {
      dynamic raw;
      try {
        final response = await _api.get(ApiConstants.ghostStatus);
        raw = response.data;
      } catch (_) {
        final response = await _api.get(ApiConstants.invisibleStatus);
        raw = response.data;
      }

      final payload = _extractRootMap(raw);
      final visibility = _asMap(payload['visibility']);
      final enabled =
          payload['isGhostModeEnabled'] ??
          payload['isInvisible'] ??
          payload['enabled'] ??
          visibility['isGhostModeEnabled'] ??
          visibility['isInvisible'] ??
          visibility['enabled'];
      if (enabled != null) {
        isInvisible.value = _isTruthy(enabled);
      }
    } catch (_) {}
  }

  // ─── Passport Mode ───────────────────────────────────
  final Rx<Map<String, dynamic>?> passportLocation = Rx<Map<String, dynamic>?>(
    null,
  );

  Future<bool> setPassportLocation(
    double lat,
    double lng,
    String cityName, {
    String? countryName,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.setPassport,
        data: {
          'latitude': lat,
          'longitude': lng,
          'lat': lat,
          'lng': lng,
          'city': cityName,
          'cityName': cityName,
          if (countryName != null && countryName.trim().isNotEmpty)
            'country': countryName,
          if (countryName != null && countryName.trim().isNotEmpty)
            'countryName': countryName,
          'location': {
            'latitude': lat,
            'longitude': lng,
            'city': cityName,
            if (countryName != null && countryName.trim().isNotEmpty)
              'country': countryName,
          },
        },
      );

      final root = _extractRootMap(response.data);
      final location =
          _extractLocationPayload(root['location']) ??
          _extractLocationPayload(root) ??
          {
            'latitude': lat,
            'longitude': lng,
            'city': cityName,
            if (countryName != null && countryName.trim().isNotEmpty)
              'country': countryName,
          };
      passportLocation.value = location;
      unawaited(fetchEntitlements());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearPassportLocation() async {
    try {
      await _api.post(ApiConstants.clearPassport);
      passportLocation.value = null;
      unawaited(fetchEntitlements());
    } catch (_) {}
  }

  Future<void> fetchPassportLocation() async {
    try {
      final response = await _api.get(ApiConstants.getPassport);
      final root = _extractRootMap(response.data);
      final visibility = _asMap(root['visibility']);
      final isActive = root.containsKey('active')
          ? _isTruthy(root['active'])
          : _readFirstBool(visibility, const [
              'isPassportActive',
              'is_passport_active',
            ]);
      final location =
          _extractLocationPayload(root['location']) ??
          _extractLocationPayload(root['passportLocation']) ??
          _extractLocationPayload(root['passport_location']) ??
          _extractLocationPayload(visibility['passportLocation']) ??
          _extractLocationPayload(visibility['passport_location']) ??
          _extractLocationPayload(root);

      if (isActive == false) {
        passportLocation.value = null;
      } else if (location != null) {
        passportLocation.value = location;
      } else {
        passportLocation.value = null;
      }
    } catch (_) {
      passportLocation.value = null;
    }
  }

  // ─── Dynamic Entitlements ───────────────────────────────
  Future<Map<String, dynamic>> fetchEntitlements() async {
    try {
      final response = await _api.get(ApiConstants.myEntitlements);
      final data = _extractRootMap(response.data);

      final plan = _asMap(data['plan']);
      final planCode = _readFirstString(plan, const ['code']);
      if (planCode != null && planCode.isNotEmpty) {
        currentPlan.value = planCode;
      }
      subscriptionPlanId.value =
          _readFirstString(data, const ['subscriptionPlanId', 'planId']) ??
          _readFirstString(plan, const ['id']) ??
          subscriptionPlanId.value;

      _syncFeatureStateFromStatusPayload(data);
      _syncVisibilityStateFromStatusPayload(data);

      final subscription = _asMap(data['subscription']);
      if (subscription.isNotEmpty) {
        status.value = (subscription['status'] ?? status.value).toString();
        final expiryRaw =
            subscription['expiresAt'] ??
            subscription['endDate'] ??
            subscription['end_date'];
        if (expiryRaw != null) {
          expiresAt.value = DateTime.tryParse(expiryRaw.toString());
        }
      }

      // Update local feature state from structured entitlements/features/limits.
      final ent = data['entitlements'] ?? data;
      final featureMatrix = _asMap(data['features']);
      final limitsMatrix = _asMap(data['limits']);

      if (ent is Map || featureMatrix.isNotEmpty || limitsMatrix.isNotEmpty) {
        final entMap = <String, dynamic>{
          if (ent is Map) ...Map<String, dynamic>.from(ent),
          ...featureMatrix,
          ...limitsMatrix,
        };

        statusPlanFeatures
          ..clear()
          ..addAll(featureMatrix);

        // Sync boolean features
        final boolFeatures = <String>[
          'unlimitedLikes',
          'unlimitedRewinds',
          'advancedFilters',
          'seeWhoLikesYou',
          'whoLikedMe',
          'readReceipts',
          'typingIndicators',
          'invisibleMode',
          'ghostMode',
          'passportMode',
          'premiumBadge',
          'hideAds',
          'rematch',
          'videoChat',
          'superLike',
          'profileBoostPriority',
          'boost',
          'likes',
          'priorityMatching',
          'improvedVisits',
        ];
        final enabledFeatures = <String>{};
        for (final key in boolFeatures) {
          if (entMap[key] == true) {
            enabledFeatures.add(key);
          }
        }

        if (entMap['ghostMode'] == true) {
          enabledFeatures.add('invisibleMode');
        }
        if (entMap['whoLikedMe'] == true) {
          enabledFeatures.add(featureWhoLikedMe);
        }
        if (entMap['boost'] == true) {
          enabledFeatures.add(featureBoost);
        }
        if (entMap['likes'] == true) {
          enabledFeatures.add('unlimitedLikes');
        }

        final dailySuperLikes = _readInt(entMap['dailySuperLikes']);
        if (_hasRemainingOrUnlimited(dailySuperLikes)) {
          enabledFeatures.add('superLike');
        }

        final weeklyBoosts = _readInt(
          entMap['weeklyBoosts'] ?? entMap['boostsLimit'],
        );
        if (_hasRemainingOrUnlimited(weeklyBoosts)) {
          enabledFeatures.add('profileBoostPriority');
          enabledFeatures.add(featureBoost);
        }

        features.value = enabledFeatures.toList(growable: false);

        // Sync numeric limits — only set feature-access flags here.
        // Actual remaining counts come from dedicated endpoints
        // (fetchRemainingLikes / fetchRemainingCompliments) to avoid
        // overwriting accurate remaining with plan-total maximums.
        final dailyLikes = _readInt(
          entMap['dailyLikes'] ?? entMap['likesLimit'],
        );
        if (dailyLikes != null) {
          isUnlimitedLikes.value = dailyLikes == -1;
          // Only initialise remainingLikes when it hasn't been set yet
          // (i.e. still at the startup default). After that the dedicated
          // remaining-likes endpoint is the source of truth.
          if (remainingLikes.value == 25 && dailyLikes != 25) {
            remainingLikes.value = _remainingFromLimit(dailyLikes);
          }
        }

        // Only touch the flag, do not overwrite the remaining counter.
        // remainingCompliments is refreshed by fetchRemainingCompliments().

        final monthlyRewinds = _readInt(entMap['monthlyRewinds']);
        if (monthlyRewinds != null) {
          canRewind.value = _hasRemainingOrUnlimited(monthlyRewinds);
        } else if (entMap['unlimitedRewinds'] == true) {
          canRewind.value = true;
        }

        // Refresh actual remaining counts from dedicated endpoints
        unawaited(fetchRemainingLikes());
        unawaited(fetchRemainingCompliments());
      }
      return data;
    } catch (e) {
      debugPrint('[Monetization] fetchEntitlements error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>?> fetchPricing() async {
    try {
      final response = await _api.get(ApiConstants.paymentPricing);
      return response.data;
    } catch (e) {
      debugPrint('[Monetization] fetchPricing error: $e');
      return null;
    }
  }

  // ─── Rematch / Second Chance ─────────────────────────
  Future<bool> requestRematch(String targetUserId) async {
    try {
      await _api.post(ApiConstants.requestRematch(targetUserId));
      return true;
    } catch (e) {
      debugPrint('[Monetization] requestRematch error: $e');
      return false;
    }
  }

  Future<bool> acceptRematch(String requestId) async {
    try {
      await _api.post(ApiConstants.acceptRematch(requestId));
      return true;
    } catch (e) {
      debugPrint('[Monetization] acceptRematch error: $e');
      return false;
    }
  }

  Future<bool> rejectRematch(String requestId) async {
    try {
      await _api.post(ApiConstants.rejectRematch(requestId));
      return true;
    } catch (e) {
      debugPrint('[Monetization] rejectRematch error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchRematchRequests() async {
    try {
      final response = await _api.get(ApiConstants.myRematchRequests);
      final list = response.data is List ? response.data : [];
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      debugPrint('[Monetization] fetchRematchRequests error: $e');
      return [];
    }
  }

  // ─── Profile Views ──────────────────────────────────
  Future<void> recordProfileView(String viewedUserId) async {
    if (!_uuidPattern.hasMatch(viewedUserId.trim())) return;
    try {
      await _api.post(ApiConstants.recordProfileView(viewedUserId));
    } catch (e) {
      debugPrint('[Monetization] recordProfileView error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchProfileViews() async {
    try {
      final response = await _api.get(ApiConstants.profileViews);
      final list = response.data is List
          ? response.data
          : response.data['views'] ?? [];
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      debugPrint('[Monetization] fetchProfileViews error: $e');
      return [];
    }
  }

  // ─── Success Stories ─────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchSuccessStories() async {
    try {
      final response = await _api.get(
        ApiConstants.successStories,
        options: Options(
          extra: {'disable_retry': true},
          validateStatus: (status) => status != null && status < 600,
        ),
      );
      if ((response.statusCode ?? 500) >= 500) {
        return [];
      }
      final list = response.data is List
          ? response.data
          : response.data['stories'] ?? [];
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      debugPrint('[Monetization] fetchSuccessStories error: $e');
      return [];
    }
  }

  Future<bool> submitSuccessStory(
    String title,
    String story, {
    bool isAnonymous = false,
  }) async {
    try {
      await _api.post(
        ApiConstants.submitSuccessStory,
        data: {'title': title, 'story': story, 'isAnonymous': isAnonymous},
      );
      return true;
    } catch (e) {
      debugPrint('[Monetization] submitSuccessStory error: $e');
      return false;
    }
  }

  // ─── Background Check ────────────────────────────────
  Future<Map<String, dynamic>?> initiateBackgroundCheck({
    required String fullName,
    required String dateOfBirth,
    required bool consentGiven,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.backgroundCheck,
        data: {
          'fullName': fullName,
          'dateOfBirth': dateOfBirth,
          'consentGiven': consentGiven,
        },
      );
      return response.data;
    } catch (e) {
      debugPrint('[Monetization] initiateBackgroundCheck error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchBackgroundCheckStatus() async {
    try {
      final response = await _api.get(ApiConstants.backgroundCheckStatus);
      return response.data;
    } catch (e) {
      debugPrint('[Monetization] fetchBackgroundCheckStatus error: $e');
      return null;
    }
  }
}

/// Enum representing the current state of the payment flow.
enum PaymentFlowState {
  idle,
  creating, // Preparing a purchase transaction
  redirecting, // Handing off to store checkout UI
  awaitingPayment, // Waiting for user completion in store UI
  confirming, // Polling for entitlement activation
  success, // Subscription activated
  failed, // Something went wrong
  timeout, // Polling timed out
  cancelled, // User cancelled payment
}
