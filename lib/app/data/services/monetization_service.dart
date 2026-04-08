import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/data/services/subscription_service.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/services/trial_manager.dart';

class MonetizationService extends GetxService {
  static const String featureAdvancedFilters = 'advanced_filters';
  static const String featureBoost = 'boost';
  static const String featureWhoLikedMe = 'who_liked_me';
  static const String featurePassport = 'passport_mode';
  static const String featureInvisibleMode = 'invisible_mode';

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
    ],
    featureWhoLikedMe: [
      'who_liked_me',
      'who_likes_me',
      'see_who_liked_you',
      'liked_you',
      'likes_received',
    ],
    featurePassport: [
      'passport',
      'passport_mode',
      'travel_mode',
      'global_mode',
    ],
    featureInvisibleMode: [
      'invisible',
      'invisible_mode',
      'incognito',
      'incognito_mode',
    ],
  };

  final ApiService _api = Get.find<ApiService>();
  bool _isStripeConfigured = false;

  bool get _isStripeTestMode {
    final key = ApiConstants.stripePublishableKey.trim();
    return ApiConstants.stripeForceTestMode || key.startsWith('pk_test_');
  }

  String get _stripeMerchantCountryCode {
    final raw = ApiConstants.stripeMerchantCountryCode.trim().toUpperCase();
    if (raw.length == 2) {
      return raw;
    }
    return 'US';
  }

  String get _stripeCurrencyCode {
    final raw = ApiConstants.stripeCurrencyCode.trim().toUpperCase();
    if (raw.length == 3) {
      return raw;
    }
    return 'USD';
  }

  // Reactive state
  final RxString currentPlan = 'free'.obs;
  final RxList<String> features = <String>[].obs;
  final RxInt remainingLikes = 10.obs;
  final RxBool isUnlimitedLikes = false.obs;
  final RxBool isBoosted = false.obs;
  final RxBool isInvisible = false.obs;
  final RxBool canRewind = true.obs;
  final RxInt remainingCompliments = 0.obs;
  final RxList<Map<String, dynamic>> activePlans = <Map<String, dynamic>>[].obs;

  // ─── Fetch full status ──────────────────────────────────
  Future<void> fetchStatus() async {
    try {
      final response = await _api.get(ApiConstants.monetizationStatus);
      final data = _extractRootMap(response.data);
      currentPlan.value =
          _readFirstString(data, const [
            'plan',
            'currentPlan',
            'subscriptionPlan',
          ]) ??
          'free';

      final rawFeatures = data['features'];
      if (rawFeatures is List) {
        features.value = rawFeatures.map((f) => f.toString()).toList();
      } else if (rawFeatures is Map) {
        features.value = rawFeatures.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key.toString())
            .toList();
      }

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
  Future<Map<String, dynamic>> fetchAllLimits() async {
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
      return [];
    }
  }

  bool hasFeature(String feature) => hasEntitlement(feature);

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

  bool get isPremium => currentPlan.value != 'free';

  // ─── Remaining Likes ────────────────────────────────────
  Future<void> fetchRemainingLikes() async {
    try {
      final response = await _api.get(ApiConstants.remainingLikes);
      isUnlimitedLikes.value = response.data['isUnlimited'] ?? false;
      remainingLikes.value = response.data['remaining'] ?? 0;
    } catch (_) {}
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
      activePlans.value = List<Map<String, dynamic>>.from(list);
    } catch (_) {}
  }

  // ─── Purchase Subscription ──────────────────────────────
  Future<bool> purchaseSubscription(
    String plan,
    int durationDays,
    String paymentRef,
  ) async {
    try {
      await _ensureStripeConfigured();

      // 1) Create Stripe payment intent on backend
      final response = await _api.post(
        ApiConstants.paymentCreateIntent,
        data: {
          'plan': plan,
          'durationDays': durationDays,
          'paymentReference': paymentRef,
          'provider': 'stripe',
        },
      );

      final data = _asMap(response.data);
      final clientSecret = _readFirstString(data, const [
        'clientSecret',
        'client_secret',
        'paymentIntentClientSecret',
      ]);
      if (clientSecret == null || clientSecret.isEmpty) {
        debugPrint('[Monetization] Payment intent missing clientSecret');
        return false;
      }

      final customerId = _readFirstString(data, const [
        'customerId',
        'customer_id',
      ]);
      final ephemeralKey = _readFirstString(data, const [
        'ephemeralKey',
        'ephemeral_key',
        'customerEphemeralKeySecret',
      ]);

      // 2) Present native payment sheet
      final hasCustomerContext =
          customerId != null &&
          customerId.isNotEmpty &&
          ephemeralKey != null &&
          ephemeralKey.isNotEmpty;
      final merchantCountryCode = _stripeMerchantCountryCode;
      final currencyCode = _stripeCurrencyCode;
      final returnUrl = ApiConstants.stripeReturnUrl.trim();
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          customerEphemeralKeySecret: hasCustomerContext ? ephemeralKey : null,
          customerId: hasCustomerContext ? customerId : null,
          merchantDisplayName: 'Methna',
          applePay: PaymentSheetApplePay(
            merchantCountryCode: merchantCountryCode,
          ),
          googlePay: PaymentSheetGooglePay(
            merchantCountryCode: merchantCountryCode,
            testEnv: _isStripeTestMode,
            currencyCode: currencyCode,
          ),
          style: ThemeMode.system,
          allowsDelayedPaymentMethods: true,
          returnURL: returnUrl.isEmpty ? null : returnUrl,
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      // 3) Activate subscription in backend.
      final activated = await _activatePurchasedPlan(
        plan: plan,
        durationDays: durationDays,
        paymentReference: paymentRef,
        paymentIntentId: _readFirstString(data, const [
          'paymentIntentId',
          'payment_intent_id',
          'id',
        ]),
      );

      // 4) Refresh state so all paid features unlock instantly.
      await _refreshMonetizationState(markPremiumPurchased: true);
      if (!activated && !isPremium) {
        debugPrint(
          '[Monetization] Payment succeeded but subscription activation did not confirm.',
        );
        return false;
      }
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        debugPrint('[Monetization] Payment sheet canceled by user.');
        return false;
      }
      debugPrint('[Monetization] Stripe Error: ${e.error.localizedMessage}');
      return false;
    } catch (e) {
      debugPrint('[Monetization] Purchase Error: $e');
      return false;
    }
  }

  Future<void> _ensureStripeConfigured() async {
    if (_isStripeConfigured) return;

    final stripeKey = ApiConstants.stripePublishableKey.trim();
    if (stripeKey.isEmpty) {
      throw StateError(
        'Missing Stripe publishable key. Pass STRIPE_PUBLISHABLE_KEY via --dart-define.',
      );
    }
    if (!stripeKey.startsWith('pk_')) {
      throw StateError(
        'Invalid Stripe publishable key format. Expected a key starting with pk_.',
      );
    }
    if (kReleaseMode && _isStripeTestMode) {
      throw StateError(
        'Release build cannot run with Stripe test mode. Provide a live STRIPE_PUBLISHABLE_KEY and disable STRIPE_TEST_MODE.',
      );
    }

    Stripe.publishableKey = stripeKey;
    Stripe.merchantIdentifier = ApiConstants.stripeMerchantIdentifier;
    await Stripe.instance.applySettings();
    _isStripeConfigured = true;
  }

  Future<bool> restoreSubscriptionState() async {
    try {
      await _refreshMonetizationState(markPremiumPurchased: false);
      final hasPremiumViaSubscription =
          Get.isRegistered<SubscriptionService>() &&
          Get.find<SubscriptionService>().isPremium;
      final restored = isPremium || hasPremiumViaSubscription;
      if (restored) {
        trialManager.markPremiumPurchased();
      }
      return restored;
    } catch (e) {
      debugPrint('[Monetization] restoreSubscriptionState error: $e');
      return false;
    }
  }

  // ─── Boost ──────────────────────────────────────────────
  Future<bool> _activatePurchasedPlan({
    required String plan,
    required int durationDays,
    required String paymentReference,
    String? paymentIntentId,
  }) async {
    final payload = <String, dynamic>{
      'plan': plan,
      'durationDays': durationDays,
      'paymentReference': paymentReference,
      'provider': 'stripe',
      if (paymentIntentId != null && paymentIntentId.isNotEmpty)
        'paymentIntentId': paymentIntentId,
    };

    try {
      await _api.post(ApiConstants.purchaseSubscription, data: payload);
      return true;
    } catch (e) {
      debugPrint(
        '[Monetization] /monetization/subscribe activation failed, trying /subscriptions fallback: $e',
      );
    }

    try {
      await _api.post(
        ApiConstants.subscriptionCreate,
        data: <String, dynamic>{
          'plan': plan,
          'durationDays': durationDays,
          'paymentReference': paymentReference,
        },
      );
      return true;
    } catch (e) {
      debugPrint('[Monetization] Subscription activation fallback failed: $e');
      return false;
    }
  }

  Future<void> _refreshMonetizationState({
    required bool markPremiumPurchased,
  }) async {
    await Future.wait([
      fetchStatus(),
      fetchAllLimits(),
      fetchFeatures(),
      fetchActivePlans(),
      fetchRemainingLikes(),
      fetchRemainingCompliments(),
    ]);

    if (Get.isRegistered<SubscriptionService>()) {
      await Get.find<SubscriptionService>().fetchMySubscription();
    }

    if (markPremiumPurchased) {
      // End trial gating when a paid subscription is purchased.
      trialManager.markPremiumPurchased();
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

  String? _readFirstString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
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

    final currentPlanData = _resolveCurrentPlanData();
    if (currentPlanData == null) {
      return null;
    }

    final planFeatures = _normalizedPlanFeatures(currentPlanData);
    if (planFeatures.isNotEmpty) {
      if (planFeatures.any(aliases.contains)) {
        return true;
      }
      return false;
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
        ]);
      case featureWhoLikedMe:
        return _readFirstBool(currentPlanData, const [
          'whoLikedMeEnabled',
          'canSeeWhoLikedMe',
          'showWhoLikedMe',
          'isWhoLikedMeEnabled',
        ]);
      case featurePassport:
        return _readFirstBool(currentPlanData, const [
          'passportEnabled',
          'canUsePassport',
          'travelModeEnabled',
          'globalModeEnabled',
        ]);
      case featureInvisibleMode:
        return _readFirstBool(currentPlanData, const [
          'invisibleModeEnabled',
          'canUseInvisibleMode',
          'incognitoEnabled',
        ]);
      default:
        return null;
    }
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
      if (_isTruthy(plan['isCurrent']) ||
          _isTruthy(plan['isActive']) ||
          _isTruthy(plan['active'])) {
        return plan;
      }
    }

    final normalizedCurrentPlan = _normalizeFeatureToken(currentPlan.value);
    if (normalizedCurrentPlan.isEmpty || normalizedCurrentPlan == 'free') {
      return null;
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
        if (_normalizeFeatureToken(token?.toString() ?? '') ==
            normalizedCurrentPlan) {
          return plan;
        }
      }
    }

    return null;
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
    return raw
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
      final parsed = _readInt(source[key]);
      if (parsed != null) {
        return parsed == -1 || parsed > 0;
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

  Future<bool> purchaseBoost({int durationMinutes = 30}) async {
    try {
      await _api.post(
        ApiConstants.purchaseBoost,
        data: {'durationMinutes': durationMinutes},
      );
      isBoosted.value = true;
      return true;
    } catch (_) {
      return false;
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
    try {
      await _api.post(ApiConstants.invisibleToggle, data: {'enabled': enabled});
      isInvisible.value = enabled;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> fetchInvisibleStatus() async {
    try {
      final response = await _api.get(ApiConstants.invisibleStatus);
      isInvisible.value = response.data['isInvisible'] ?? false;
    } catch (_) {}
  }

  // ─── Passport Mode ───────────────────────────────────
  final Rx<Map<String, dynamic>?> passportLocation = Rx<Map<String, dynamic>?>(
    null,
  );

  Future<bool> setPassportLocation(
    double lat,
    double lng,
    String cityName,
  ) async {
    try {
      await _api.post(
        ApiConstants.setPassport,
        data: {'latitude': lat, 'longitude': lng, 'cityName': cityName},
      );
      passportLocation.value = {
        'latitude': lat,
        'longitude': lng,
        'cityName': cityName,
      };
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearPassportLocation() async {
    try {
      await _api.post(ApiConstants.clearPassport);
      passportLocation.value = null;
    } catch (_) {}
  }

  Future<void> fetchPassportLocation() async {
    try {
      final response = await _api.get(ApiConstants.getPassport);
      if (response.data != null && response.data['latitude'] != null) {
        passportLocation.value = response.data;
      } else {
        passportLocation.value = null;
      }
    } catch (_) {
      passportLocation.value = null;
    }
  }

  // ─── Payment Intent ──────────────────────────────────
  Future<Map<String, dynamic>?> createPaymentIntent(
    String plan,
    int durationDays,
    String provider,
  ) async {
    try {
      final response = await _api.post(
        ApiConstants.paymentCreateIntent,
        data: {
          'plan': plan,
          'durationDays': durationDays,
          'provider': provider,
        },
      );
      return response.data;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchPricing() async {
    try {
      final response = await _api.get(ApiConstants.paymentPricing);
      return response.data;
    } catch (_) {
      return null;
    }
  }

  // ─── Rematch / Second Chance ─────────────────────────
  Future<bool> requestRematch(String targetUserId) async {
    try {
      await _api.post(ApiConstants.requestRematch(targetUserId));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> acceptRematch(String requestId) async {
    try {
      await _api.post(ApiConstants.acceptRematch(requestId));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectRematch(String requestId) async {
    try {
      await _api.post(ApiConstants.rejectRematch(requestId));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchRematchRequests() async {
    try {
      final response = await _api.get(ApiConstants.myRematchRequests);
      final list = response.data is List ? response.data : [];
      return List<Map<String, dynamic>>.from(list);
    } catch (_) {
      return [];
    }
  }

  // ─── Profile Views ──────────────────────────────────
  Future<void> recordProfileView(String viewedUserId) async {
    try {
      await _api.post(ApiConstants.recordProfileView(viewedUserId));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> fetchProfileViews() async {
    try {
      final response = await _api.get(ApiConstants.profileViews);
      final list = response.data is List
          ? response.data
          : response.data['views'] ?? [];
      return List<Map<String, dynamic>>.from(list);
    } catch (_) {
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
    } catch (_) {
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
    } catch (_) {
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
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchBackgroundCheckStatus() async {
    try {
      final response = await _api.get(ApiConstants.backgroundCheckStatus);
      return response.data;
    } catch (_) {
      return null;
    }
  }
}
