class PlayBillingConstants {
  PlayBillingConstants._();

  static const String premium = String.fromEnvironment(
    'PLAY_BILLING_PREMIUM',
    defaultValue: 'com.methnapp.app.premium_monthly',
  );
  static const String premiumMonthly = String.fromEnvironment(
    'PLAY_BILLING_PREMIUM_MONTHLY',
    defaultValue: 'com.methnapp.app.premium_monthly',
  );
  static const String premiumYearly = String.fromEnvironment(
    'PLAY_BILLING_PREMIUM_YEARLY',
    defaultValue: 'com.methnapp.app.premium_yearly',
  );
  static const String gold = String.fromEnvironment(
    'PLAY_BILLING_GOLD',
    defaultValue: 'com.methnapp.app.gold',
  );

  static Set<String> get configuredProductIds => {
    for (final id in [premium, premiumMonthly, premiumYearly, gold])
      if (id.trim().isNotEmpty) id.trim(),
  };

  static String? resolveProductId({
    required String planCode,
    required int durationDays,
    Map<String, dynamic>? planMetadata,
  }) {
    final metadataProductId = extractProductId(planMetadata);
    if (metadataProductId != null) {
      return metadataProductId;
    }

    if (
        _requiresExplicitGoogleProductId(
          planCode: planCode,
          durationDays: durationDays,
          planMetadata: planMetadata,
        )) {
      return null;
    }

    final normalizedPlan = normalize(planCode);
    if (normalizedPlan.isEmpty) {
      return _singleConfiguredFallback();
    }

    if (normalizedPlan.contains('gold')) {
      return _firstNonEmpty([gold, premiumYearly, premiumMonthly, premium]);
    }

    if (normalizedPlan.contains('year')) {
      return _firstNonEmpty([premiumYearly, premium, premiumMonthly]);
    }

    if (normalizedPlan.contains('month')) {
      return _firstNonEmpty([premiumMonthly, premium, premiumYearly]);
    }

    if (normalizedPlan.contains('premium')) {
      if (durationDays >= 365) {
        return _firstNonEmpty([premiumYearly, premium, premiumMonthly]);
      }
      if (durationDays >= 30) {
        return _firstNonEmpty([premiumMonthly, premium, premiumYearly]);
      }
      return _firstNonEmpty([premium, premiumMonthly, premiumYearly]);
    }

    return _singleConfiguredFallback();
  }

  static String inferPlanCode(String productId, {String fallback = 'premium'}) {
    final normalizedProductId = normalize(productId);
    if (normalizedProductId == normalize(gold)) {
      return 'gold';
    }
    if (normalizedProductId == normalize(premiumYearly)) {
      return 'premium_yearly';
    }
    if (normalizedProductId == normalize(premiumMonthly)) {
      return 'premium_monthly';
    }
    if (normalizedProductId == normalize(premium)) {
      return 'premium';
    }
    return fallback;
  }

  static Set<String> productIdsForPlans(Iterable<Map<String, dynamic>> plans) {
    final ids = <String>{...configuredProductIds};
    for (final plan in plans) {
      final productId = resolveProductId(
        planCode: _planCode(plan),
        durationDays: _durationDays(plan),
        planMetadata: plan,
      );
      if (productId != null && productId.trim().isNotEmpty) {
        ids.add(productId.trim());
      }
    }
    return ids;
  }

  static String? extractProductId(Map<String, dynamic>? planMetadata) {
    if (planMetadata == null || planMetadata.isEmpty) {
      return null;
    }

    final root = Map<String, dynamic>.from(planMetadata);
    final nestedMaps = <Map<String, dynamic>>[
      root,
      _asMap(root['metadata']),
      _asMap(root['store']),
      _asMap(root['android']),
      _asMap(root['googlePlay']),
      _asMap(root['google_play']),
    ];

    const candidateKeys = [
      'googleProductId',
      'google_product_id',
      'googlePlayProductId',
      'google_play_product_id',
      'androidProductId',
      'android_product_id',
      'productId',
      'product_id',
      'storeProductId',
      'store_product_id',
      'playProductId',
      'play_product_id',
      'sku',
    ];

    for (final map in nestedMaps) {
      for (final key in candidateKeys) {
        final value = map[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) {
          return value;
        }
      }
    }

    return null;
  }

  static String? extractBasePlanId(Map<String, dynamic>? planMetadata) {
    if (planMetadata == null || planMetadata.isEmpty) {
      return null;
    }

    final root = Map<String, dynamic>.from(planMetadata);
    final nestedMaps = <Map<String, dynamic>>[
      root,
      _asMap(root['metadata']),
      _asMap(root['store']),
      _asMap(root['android']),
      _asMap(root['googlePlay']),
      _asMap(root['google_play']),
    ];

    const candidateKeys = [
      'googleBasePlanId',
      'google_base_plan_id',
      'basePlanId',
      'base_plan_id',
      'playBasePlanId',
      'play_base_plan_id',
    ];

    for (final map in nestedMaps) {
      for (final key in candidateKeys) {
        final value = map[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) {
          return value;
        }
      }
    }

    return null;
  }

  static String normalize(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  static String _planCode(Map<String, dynamic> plan) {
    const keys = [
      'code',
      'slug',
      'plan',
      'tier',
      'name',
    ];
    for (final key in keys) {
      final value = plan[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  static int _durationDays(Map<String, dynamic> plan) {
    final rawDuration =
        plan['durationDays'] ?? plan['duration'] ?? plan['days'];
    if (rawDuration is int) {
      return rawDuration;
    }
    return int.tryParse(rawDuration?.toString() ?? '') ?? 30;
  }

  static String? _singleConfiguredFallback() {
    if (configuredProductIds.length == 1) {
      return configuredProductIds.first;
    }
    return null;
  }

  static String? _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return null;
  }

  static bool _requiresExplicitGoogleProductId({
    required String planCode,
    required int durationDays,
    Map<String, dynamic>? planMetadata,
  }) {
    if (planMetadata == null || planMetadata.isEmpty) {
      return false;
    }

    final normalizedPlan = normalize(
      planCode.trim().isNotEmpty ? planCode : _planCode(planMetadata),
    );

    if (normalizedPlan == 'free' || normalizedPlan.startsWith('free_')) {
      return false;
    }

    final price = _extractPlanPrice(planMetadata);
    if (price != null) {
      return price > 0;
    }

    if (normalizedPlan == 'trial' || normalizedPlan.contains('trial')) {
      return durationDays > 3;
    }

    return true;
  }

  static double? _extractPlanPrice(Map<String, dynamic> planMetadata) {
    final root = Map<String, dynamic>.from(planMetadata);
    final nestedMaps = <Map<String, dynamic>>[
      root,
      _asMap(root['metadata']),
      _asMap(root['pricing']),
      _asMap(root['price']),
      _asMap(root['plan']),
    ];

    for (final map in nestedMaps) {
      for (final key in const ['price', 'amount', 'monthlyPrice', 'value']) {
        final parsed = _parseNumericValue(map[key]);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }

  static double? _parseNumericValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final sanitized = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
    if (sanitized.isEmpty || sanitized == '-' || sanitized == '.') {
      return null;
    }

    return double.tryParse(sanitized);
  }
}
