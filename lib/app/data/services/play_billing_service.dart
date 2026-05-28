// ignore_for_file: unused_element

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/data/services/storage_service.dart';
import 'package:methna_app/core/constants/app_constants.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/constants/play_billing_constants.dart';
import 'package:url_launcher/url_launcher.dart';

enum PlayBillingPurchaseState {
  idle,
  unavailable,
  loadingProducts,
  purchasing,
  pending,
  syncing,
  purchased,
  restored,
  cancelled,
  error,
}

enum PlayBillingPurchaseOutcomeType {
  purchased,
  restored,
  pending,
  cancelled,
  error,
  unavailable,
  productNotFound,
  alreadyOwned,
}

enum _BackendSyncResult { verified, invalid, retryableFailure }

class PlayBillingPurchaseOutcome {
  const PlayBillingPurchaseOutcome({
    required this.type,
    this.message,
    this.productId,
  });

  final PlayBillingPurchaseOutcomeType type;
  final String? message;
  final String? productId;

  bool get isSuccess =>
      type == PlayBillingPurchaseOutcomeType.purchased ||
      type == PlayBillingPurchaseOutcomeType.restored ||
      type == PlayBillingPurchaseOutcomeType.pending;
}

class PlayBillingService extends GetxService {
  PlayBillingService({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  static const String _entitlementKey = 'play_billing_entitlement_active';
  static const String _productIdKey = 'play_billing_active_product_id';
  static const String _planCodeKey = 'play_billing_active_plan_code';
  static const String _purchaseTokenKey = 'play_billing_purchase_token';
  static const String _basePlanIdKey = 'play_billing_base_plan_id';
  static const String _lastSyncKey = 'play_billing_last_sync_at';
  static const String _pendingVerificationKey =
      'play_billing_pending_verification';

  final InAppPurchase _inAppPurchase;
  final StorageService _storage = Get.find<StorageService>();
  final ApiService _api = Get.find<ApiService>();

  final RxBool storeAvailable = false.obs;
  final RxBool hasActiveEntitlement = false.obs;
  final RxString activeProductId = ''.obs;
  final RxString activePlanCode = 'free'.obs;
  final RxString purchaseToken = ''.obs;
  final RxString activeBasePlanId = ''.obs;
  final Rx<DateTime?> lastSyncedAt = Rx<DateTime?>(null);
  final Rx<PlayBillingPurchaseState> purchaseState =
      PlayBillingPurchaseState.idle.obs;
  final RxString purchaseMessage = ''.obs;
  final RxMap<String, ProductDetails> products = <String, ProductDetails>{}.obs;
  final RxBool pendingVerification = false.obs;
  final Map<String, List<ProductDetails>> _productVariantsById =
      <String, List<ProductDetails>>{};

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Completer<PlayBillingPurchaseOutcome>? _purchaseCompleter;
  String? _expectedPurchaseProductId;
  String? _expectedBasePlanId;
  final Map<String, String> _knownBasePlansByProductId = <String, String>{};
  Timer? _retryTimer;

  bool get supportsPlatform => !kIsWeb && GetPlatform.isAndroid;

  Future<PlayBillingService> init() async {
    _restorePersistedEntitlement();
    _restorePendingVerificationState();

    if (!supportsPlatform) {
      storeAvailable.value = false;
      purchaseState.value = PlayBillingPurchaseState.idle;
      purchaseMessage.value = '';
      return this;
    }

    await refreshStoreAvailability();

    _purchaseSubscription?.cancel();
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        purchaseState.value = PlayBillingPurchaseState.error;
        purchaseMessage.value = 'Google Play purchase stream failed.';
        debugPrint('[PlayBilling] purchase stream error: $error');
      },
      onDone: () {
        _purchaseSubscription = null;
      },
    );

    if (storeAvailable.value) {
      await _verifyBackendEntitlement();
      await syncOwnedPurchases(silent: true);
      if (pendingVerification.value) {
        _schedulePendingRetry();
      }
    }

    purchaseState.value = PlayBillingPurchaseState.idle;
    purchaseMessage.value = '';
    return this;
  }

  Future<void> refreshStoreAvailability() async {
    if (!supportsPlatform) {
      storeAvailable.value = false;
      return;
    }
    try {
      storeAvailable.value = await _inAppPurchase.isAvailable();
      if (!storeAvailable.value) {
        purchaseState.value = PlayBillingPurchaseState.unavailable;
        purchaseMessage.value = 'Google Play Billing is unavailable.';
      } else if (purchaseState.value == PlayBillingPurchaseState.unavailable) {
        purchaseState.value = PlayBillingPurchaseState.idle;
        purchaseMessage.value = '';
      }
    } catch (e) {
      storeAvailable.value = false;
      purchaseState.value = PlayBillingPurchaseState.unavailable;
      purchaseMessage.value = 'Google Play Billing is unavailable.';
      debugPrint('[PlayBilling] isAvailable error: $e');
    }
  }

  String? resolveProductIdForPlan({
    required String planCode,
    required int durationDays,
    Map<String, dynamic>? planMetadata,
  }) {
    return PlayBillingConstants.resolveProductId(
      planCode: planCode,
      durationDays: durationDays,
      planMetadata: planMetadata,
    );
  }

  bool canPurchasePlan({
    required String planCode,
    required int durationDays,
    Map<String, dynamic>? planMetadata,
  }) {
    return supportsPlatform &&
        resolveProductIdForPlan(
              planCode: planCode,
              durationDays: durationDays,
              planMetadata: planMetadata,
            ) !=
            null;
  }

  ProductDetails? productForPlan({
    required String planCode,
    required int durationDays,
    Map<String, dynamic>? planMetadata,
  }) {
    final productId = resolveProductIdForPlan(
      planCode: planCode,
      durationDays: durationDays,
      planMetadata: planMetadata,
    );
    if (productId == null) {
      return null;
    }
    return _resolveProductDetails(
      productId: productId,
      basePlanId: PlayBillingConstants.extractBasePlanId(planMetadata),
    );
  }

  Future<void> prefetchPlans(Iterable<Map<String, dynamic>> plans) async {
    if (!supportsPlatform) {
      return;
    }
    final productIds = PlayBillingConstants.productIdsForPlans(plans);
    if (productIds.isEmpty) {
      return;
    }
    await loadProducts(productIds);
  }

  Future<void> loadProducts(Iterable<String> productIds) async {
    if (!supportsPlatform) {
      return;
    }

    final normalizedIds = productIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (normalizedIds.isEmpty) {
      return;
    }

    purchaseState.value = PlayBillingPurchaseState.loadingProducts;
    try {
      final response = await _inAppPurchase.queryProductDetails(normalizedIds);
      if (response.error != null) {
        purchaseState.value = PlayBillingPurchaseState.error;
        purchaseMessage.value =
            response.error?.message ?? 'Unable to load Google Play products.';
        return;
      }

      final groupedProducts = <String, List<ProductDetails>>{};
      for (final product in response.productDetails) {
        groupedProducts.putIfAbsent(product.id, () => <ProductDetails>[]).add(
          product,
        );
      }

      for (final entry in groupedProducts.entries) {
        _productVariantsById[entry.key] = List<ProductDetails>.unmodifiable(
          entry.value,
        );
        products[entry.key] = _pickCatalogProduct(entry.value);
      }

      if (purchaseState.value == PlayBillingPurchaseState.loadingProducts) {
        purchaseState.value = PlayBillingPurchaseState.idle;
        purchaseMessage.value = '';
      }
    } catch (e) {
      purchaseState.value = PlayBillingPurchaseState.error;
      purchaseMessage.value = 'Unable to load Google Play products.';
      debugPrint('[PlayBilling] loadProducts error: $e');
    }
  }

  Future<PlayBillingPurchaseOutcome> purchaseSubscription({
    required String planCode,
    required int durationDays,
    Map<String, dynamic>? planMetadata,
    String? accountId,
  }) async {
    if (!supportsPlatform) {
      return const PlayBillingPurchaseOutcome(
        type: PlayBillingPurchaseOutcomeType.unavailable,
      );
    }

    await refreshStoreAvailability();
    if (!storeAvailable.value) {
      return const PlayBillingPurchaseOutcome(
        type: PlayBillingPurchaseOutcomeType.unavailable,
        message: 'Google Play Billing is unavailable.',
      );
    }

    final productId = resolveProductIdForPlan(
      planCode: planCode,
      durationDays: durationDays,
      planMetadata: planMetadata,
    );
    if (productId == null) {
      purchaseState.value = PlayBillingPurchaseState.error;
      purchaseMessage.value = 'This plan is not linked to Google Play yet.';
      return const PlayBillingPurchaseOutcome(
        type: PlayBillingPurchaseOutcomeType.productNotFound,
        message: 'This plan is not linked to Google Play yet.',
      );
    }

    await loadProducts([productId]);
    final requestedBasePlanId =
        PlayBillingConstants.extractBasePlanId(planMetadata);
    final product = _resolveProductDetails(
      productId: productId,
      basePlanId: requestedBasePlanId,
    );
    if (product == null) {
      purchaseState.value = PlayBillingPurchaseState.error;
      purchaseMessage.value =
          requestedBasePlanId == null || requestedBasePlanId.trim().isEmpty
          ? 'This plan is not available in Google Play.'
          : 'This Google Play plan is missing its configured base plan.';
      return PlayBillingPurchaseOutcome(
        type: PlayBillingPurchaseOutcomeType.productNotFound,
        message: purchaseMessage.value,
        productId: productId,
      );
    }

    await syncOwnedPurchases(silent: true, expectedProductIds: {productId});
    if (hasActiveEntitlement.value && activeProductId.value == productId) {
      return PlayBillingPurchaseOutcome(
        type: PlayBillingPurchaseOutcomeType.alreadyOwned,
        message: 'This Google Play subscription is already active.',
        productId: productId,
      );
    }

    _expectedPurchaseProductId = productId;
    final basePlanId =
        requestedBasePlanId ?? _extractBasePlanIdFromProduct(product);
    _expectedBasePlanId = basePlanId;
    if (basePlanId != null && basePlanId.trim().isNotEmpty) {
      _knownBasePlansByProductId[productId] = basePlanId.trim();
    }
    _purchaseCompleter = Completer<PlayBillingPurchaseOutcome>();
    purchaseState.value = PlayBillingPurchaseState.purchasing;
    purchaseMessage.value = '';

    GooglePlayPurchaseDetails? existingSubscription;
    final activeOwnedProductId = activeProductId.value.trim();
    if (hasActiveEntitlement.value &&
        activeOwnedProductId.isNotEmpty &&
        activeOwnedProductId != productId) {
      existingSubscription = await _findExistingSubscriptionForUpgrade(
        excludeProductId: productId,
        preferredProductId: activeOwnedProductId,
      );
    }

    final purchaseParam = product is GooglePlayProductDetails
        ? GooglePlayPurchaseParam(
            productDetails: product,
            applicationUserName: accountId,
            changeSubscriptionParam: existingSubscription == null
                ? null
                : ChangeSubscriptionParam(
                    oldPurchaseDetails: existingSubscription,
                  ),
          )
        : PurchaseParam(
            productDetails: product,
            applicationUserName: accountId,
          );

    try {
      final launched = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      if (!launched) {
        purchaseState.value = PlayBillingPurchaseState.error;
        purchaseMessage.value = 'Could not open Google Play checkout.';
        _clearPendingPurchaseContext();
        return PlayBillingPurchaseOutcome(
          type: PlayBillingPurchaseOutcomeType.error,
          message: purchaseMessage.value,
          productId: productId,
        );
      }

      return await _purchaseCompleter!.future.timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          purchaseState.value = PlayBillingPurchaseState.error;
          purchaseMessage.value =
              'Google Play did not confirm the purchase. Please try again.';
          _clearPendingPurchaseContext();
          return PlayBillingPurchaseOutcome(
            type: PlayBillingPurchaseOutcomeType.error,
            message: purchaseMessage.value,
            productId: productId,
          );
        },
      );
    } catch (e) {
      purchaseState.value = PlayBillingPurchaseState.error;
      purchaseMessage.value = 'Google Play purchase failed to start.';
      debugPrint('[PlayBilling] buyNonConsumable error: $e');
      _clearPendingPurchaseContext();
      return PlayBillingPurchaseOutcome(
        type: PlayBillingPurchaseOutcomeType.error,
        message: purchaseMessage.value,
        productId: productId,
      );
    }
  }

  Future<bool> restorePurchases() async {
    if (!supportsPlatform) {
      return false;
    }

    await refreshStoreAvailability();
    if (!storeAvailable.value) {
      return false;
    }

    purchaseState.value = PlayBillingPurchaseState.syncing;
    purchaseMessage.value = '';

    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('[PlayBilling] restorePurchases error: $e');
    }

    final restored = await syncOwnedPurchases(silent: false);
    if (restored) {
      purchaseState.value = PlayBillingPurchaseState.restored;
      purchaseMessage.value = '';
    } else {
      purchaseState.value = PlayBillingPurchaseState.idle;
      purchaseMessage.value = '';
    }
    return restored;
  }

  Future<bool> syncOwnedPurchases({
    bool silent = false,
    Set<String>? expectedProductIds,
  }) async {
    if (!supportsPlatform) {
      return false;
    }

    try {
      final addition = _inAppPurchase
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await addition.queryPastPurchases();

      if (response.error != null) {
        debugPrint(
          '[PlayBilling] queryPastPurchases error: ${response.error?.message}',
        );
        if (!silent) {
          purchaseState.value = PlayBillingPurchaseState.error;
          purchaseMessage.value =
              response.error?.message ??
              'Could not sync Google Play purchases.';
        }
        return false;
      }

      final purchase = _selectActivePurchase(
        response.pastPurchases,
        expectedProductIds: expectedProductIds,
      );
      if (purchase == null) {
        if (expectedProductIds == null || expectedProductIds.isNotEmpty) {
          await _clearPersistedEntitlement();
        }
        return false;
      }

      await _applyEntitlementFromPurchase(purchase, restored: true);
      if (purchase.pendingCompletePurchase) {
        await _completePurchaseSafely(purchase);
      }
      return true;
    } catch (e) {
      debugPrint('[PlayBilling] syncOwnedPurchases exception: $e');
      if (!silent) {
        purchaseState.value = PlayBillingPurchaseState.error;
        purchaseMessage.value = 'Could not sync Google Play purchases.';
      }
      return false;
    }
  }

  Future<void> openManageSubscription() async {
    try {
      final response = await _api.get(ApiConstants.paymentManageUrl);
      final root = _asMap(response.data);
      final backendUrl = root['url']?.toString().trim() ?? '';
      if (backendUrl.isNotEmpty) {
        final uri = Uri.parse(backendUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }
    } catch (e) {
      debugPrint('[PlayBilling] Failed to resolve backend manage URL: $e');
    }

    final storeUri = Uri.parse(
      'https://play.google.com/store/account/subscriptions',
    );
    if (await canLaunchUrl(storeUri)) {
      await launchUrl(storeUri, mode: LaunchMode.externalApplication);
      return;
    }

    final websiteUri = Uri.parse(
      '${AppConstants.websiteUrl}/account/subscription',
    );
    if (await canLaunchUrl(websiteUri)) {
      await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
    }
  }

  void resetTransientState() {
    if (purchaseState.value == PlayBillingPurchaseState.pending) {
      return;
    }
    purchaseState.value = PlayBillingPurchaseState.idle;
    purchaseMessage.value = '';
    _expectedPurchaseProductId = null;
    _expectedBasePlanId = null;
  }

  @override
  void onClose() {
    _purchaseSubscription?.cancel();
    _retryTimer?.cancel();
    super.onClose();
  }

  void _restorePersistedEntitlement() {
    hasActiveEntitlement.value = _storage.getBool(_entitlementKey) ?? false;
    activeProductId.value = _storage.getString(_productIdKey) ?? '';
    activePlanCode.value = _storage.getString(_planCodeKey) ?? 'free';
    purchaseToken.value = _storage.getString(_purchaseTokenKey) ?? '';
    activeBasePlanId.value = _storage.getString(_basePlanIdKey) ?? '';

    final rawTimestamp = _storage.getString(_lastSyncKey);
    if (rawTimestamp != null && rawTimestamp.trim().isNotEmpty) {
      lastSyncedAt.value = DateTime.tryParse(rawTimestamp);
    }

    if (!hasActiveEntitlement.value) {
      activePlanCode.value = 'free';
      activeProductId.value = '';
    }

    if (activeProductId.value.trim().isNotEmpty &&
        activeBasePlanId.value.trim().isNotEmpty) {
      _knownBasePlansByProductId[activeProductId.value.trim()] =
          activeBasePlanId.value.trim();
    }
  }

  void _restorePendingVerificationState() {
    final pending = _storage.getBool(_pendingVerificationKey) ?? false;
    pendingVerification.value = pending;
  }

  Future<void> _savePendingVerification(bool pending) async {
    pendingVerification.value = pending;
    await _storage.saveBool(_pendingVerificationKey, pending);
  }

  Future<void> _verifyBackendEntitlement() async {
    try {
      final response = await _api.get(ApiConstants.myEntitlements);
      final data = _asMap(response.data);
      final plan = _asMap(data['plan']);
      final subscription = _asMap(data['subscription']);

      final planCode = plan['code']?.toString().trim().toLowerCase() ?? 'free';
      final status =
          subscription['status']?.toString().trim().toLowerCase() ?? 'inactive';
      final expiryRaw =
          subscription['endDate'] ??
          subscription['expiresAt'] ??
          subscription['end_date'];
      final expiryDate = expiryRaw != null
          ? DateTime.tryParse(expiryRaw.toString())
          : null;

      final isStatusActive =
          status == 'active' || status == 'pending_cancellation' || status == 'past_due' || status == 'trial';
      final notExpired =
          expiryDate == null || expiryDate.isAfter(DateTime.now());
      final backendActive =
          planCode.isNotEmpty &&
          planCode != 'free' &&
          isStatusActive &&
          notExpired;

      if (!backendActive) {
        if (hasActiveEntitlement.value || activePlanCode.value != 'free') {
          debugPrint(
            '[PlayBilling] Backend says no entitlement; clearing local cache.',
          );
          await _clearPersistedEntitlement();
        }
        return;
      }

      hasActiveEntitlement.value = true;
      activePlanCode.value = planCode;
      await _storage.saveBool(_entitlementKey, true);
      await _storage.saveString(_planCodeKey, activePlanCode.value);

      final now = DateTime.now().toUtc();
      lastSyncedAt.value = now;
      await _storage.saveString(_lastSyncKey, now.toIso8601String());
    } catch (e) {
      debugPrint(
        '[PlayBilling] Backend entitlement check failed (will keep cached state): $e',
      );
    }
  }

  void _schedulePendingRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(minutes: 5), () async {
      if (!pendingVerification.value) return;
      await _retryPendingVerification();
    });
  }

  Future<void> _retryPendingVerification() async {
    final token = _storage.getString(_purchaseTokenKey) ?? '';
    final productId = _storage.getString(_productIdKey) ?? '';
    final basePlanId = _storage.getString(_basePlanIdKey) ?? '';
    if (token.isEmpty || productId.isEmpty) {
      await _savePendingVerification(false);
      return;
    }

    try {
      await _api.post(
        ApiConstants.googlePlayVerifyPurchase,
        data: {
          'platform': 'android',
          'provider': 'google_play',
          'productId': productId,
          if (basePlanId.trim().isNotEmpty) 'basePlanId': basePlanId,
          'purchaseToken': token,
          'restored': true,
        },
      );
      await _savePendingVerification(false);
      await _verifyBackendEntitlement();
      await syncOwnedPurchases(silent: true, expectedProductIds: {productId});
      debugPrint('[PlayBilling] Pending verification succeeded on retry.');
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      final reason = _extractVerificationReason(e.response?.data);
      if (_isInvalidVerificationFailure(statusCode, reason)) {
        debugPrint(
          '[PlayBilling] Pending verification rejected by backend (invalid purchase); clearing.',
        );
        await _savePendingVerification(false);
        await _clearPersistedEntitlement();
        return;
      }
      debugPrint('[PlayBilling] Pending verification retry failed: $e');
      _schedulePendingRetry();
    } catch (e) {
      debugPrint('[PlayBilling] Pending verification retry failed: $e');
      _schedulePendingRetry();
    }
  }

  PurchaseDetails? _selectActivePurchase(
    List<PurchaseDetails> purchases, {
    Set<String>? expectedProductIds,
  }) {
    final knownProductIds = <String>{
      ...PlayBillingConstants.configuredProductIds,
      ...products.keys,
      if (activeProductId.value.trim().isNotEmpty) activeProductId.value.trim(),
      if (_expectedPurchaseProductId?.trim().isNotEmpty ?? false)
        _expectedPurchaseProductId!.trim(),
      ...?expectedProductIds,
    };

    final filtered = purchases.where((purchase) {
      if (purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored) {
        return false;
      }
      if (knownProductIds.isEmpty) {
        return true;
      }
      return knownProductIds.contains(purchase.productID);
    }).toList();

    if (filtered.isEmpty) {
      return null;
    }

    filtered.sort((a, b) {
      final aDate = int.tryParse(a.transactionDate ?? '') ?? 0;
      final bDate = int.tryParse(b.transactionDate ?? '') ?? 0;
      return bDate.compareTo(aDate);
    });
    return filtered.first;
  }

  ProductDetails? _resolveProductDetails({
    required String productId,
    String? basePlanId,
  }) {
    final normalizedProductId = productId.trim();
    if (normalizedProductId.isEmpty) {
      return null;
    }

    final candidates =
        _productVariantsById[normalizedProductId] ??
        (products.containsKey(normalizedProductId)
            ? <ProductDetails>[products[normalizedProductId]!]
            : const <ProductDetails>[]);
    if (candidates.isEmpty) {
      return null;
    }

    final normalizedBasePlanId = basePlanId?.trim() ?? '';
    if (normalizedBasePlanId.isNotEmpty) {
      for (final candidate in candidates) {
        if (_extractBasePlanIdFromProduct(candidate) == normalizedBasePlanId) {
          return candidate;
        }
      }

      debugPrint(
        '[PlayBilling] No exact base plan match for $normalizedProductId/$normalizedBasePlanId. '
        'Available: ${candidates.map(_extractBasePlanIdFromProduct).whereType<String>().join(', ')}',
      );
    }

    final activeBasePlan = activeBasePlanId.value.trim();
    if (activeBasePlan.isNotEmpty) {
      for (final candidate in candidates) {
        if (_extractBasePlanIdFromProduct(candidate) == activeBasePlan) {
          return candidate;
        }
      }
    }

    return _pickCatalogProduct(candidates);
  }

  ProductDetails _pickCatalogProduct(List<ProductDetails> candidates) {
    if (candidates.length == 1) {
      return candidates.first;
    }

    final activeBasePlan = activeBasePlanId.value.trim();
    if (activeBasePlan.isNotEmpty) {
      for (final candidate in candidates) {
        if (_extractBasePlanIdFromProduct(candidate) == activeBasePlan) {
          return candidate;
        }
      }
    }

    final sortedCandidates = List<ProductDetails>.from(candidates)
      ..sort((a, b) {
      final aIndex = a is GooglePlayProductDetails ? a.subscriptionIndex ?? -1 : -1;
      final bIndex = b is GooglePlayProductDetails ? b.subscriptionIndex ?? -1 : -1;
      return aIndex.compareTo(bIndex);
    });
    return sortedCandidates.first;
  }

  String? _extractBasePlanIdFromProduct(ProductDetails product) {
    if (product is! GooglePlayProductDetails) {
      return null;
    }

    final subscriptionIndex = product.subscriptionIndex;
    final offers = product.productDetails.subscriptionOfferDetails;
    if (subscriptionIndex == null ||
        offers == null ||
        subscriptionIndex < 0 ||
        subscriptionIndex >= offers.length) {
      return null;
    }

    final basePlanId = offers[subscriptionIndex].basePlanId.trim();
    return basePlanId.isEmpty ? null : basePlanId;
  }

  Future<GooglePlayPurchaseDetails?> _findExistingSubscriptionForUpgrade({
    required String excludeProductId,
    String? preferredProductId,
  }) async {
    if (!supportsPlatform) {
      return null;
    }

    try {
      final addition = _inAppPurchase
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await addition.queryPastPurchases();
      if (response.error != null) {
        return null;
      }

      GooglePlayPurchaseDetails? fallback;
      final preferred = preferredProductId?.trim() ?? '';

      for (final purchase in response.pastPurchases) {
        if (purchase.productID == excludeProductId) {
          continue;
        }

        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          if (preferred.isNotEmpty && purchase.productID == preferred) {
            return purchase;
          }
          fallback ??= purchase;
        }
      }

      return fallback;
    } catch (e) {
      debugPrint('[PlayBilling] existing subscription lookup failed: $e');
    }

    return null;
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (_expectedPurchaseProductId != null &&
          purchase.productID != _expectedPurchaseProductId &&
          !PlayBillingConstants.configuredProductIds.contains(
            purchase.productID,
          )) {
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          purchaseState.value = PlayBillingPurchaseState.pending;
          purchaseMessage.value = '';
          _completePurchaseOutcome(
            PlayBillingPurchaseOutcome(
              type: PlayBillingPurchaseOutcomeType.pending,
              productId: purchase.productID,
            ),
          );
          break;
        case PurchaseStatus.purchased:
          await _finalizeCompletedPurchase(purchase, restored: false);
          break;
        case PurchaseStatus.restored:
          await _finalizeCompletedPurchase(purchase, restored: true);
          break;
        case PurchaseStatus.canceled:
          purchaseState.value = PlayBillingPurchaseState.cancelled;
          purchaseMessage.value = '';
          _completePurchaseOutcome(
            PlayBillingPurchaseOutcome(
              type: PlayBillingPurchaseOutcomeType.cancelled,
              productId: purchase.productID,
            ),
          );
          break;
        case PurchaseStatus.error:
          purchaseState.value = PlayBillingPurchaseState.error;
          purchaseMessage.value =
              purchase.error?.message ?? 'Google Play purchase failed.';
          _completePurchaseOutcome(
            PlayBillingPurchaseOutcome(
              type: PlayBillingPurchaseOutcomeType.error,
              message: purchaseMessage.value,
              productId: purchase.productID,
            ),
          );
          break;
      }
    }
  }

  Future<void> _finalizeCompletedPurchase(
    PurchaseDetails purchase, {
    required bool restored,
  }) async {
    purchaseState.value = PlayBillingPurchaseState.syncing;
    purchaseMessage.value = '';

    final verificationToken = purchase.verificationData.serverVerificationData
        .trim();
    if (verificationToken.isEmpty) {
      purchaseState.value = PlayBillingPurchaseState.error;
      purchaseMessage.value = 'Google Play verification data is missing.';
      _completePurchaseOutcome(
        PlayBillingPurchaseOutcome(
          type: PlayBillingPurchaseOutcomeType.error,
          message: purchaseMessage.value,
          productId: purchase.productID,
        ),
      );
      return;
    }

    final syncResult = await _attemptBackendSync(purchase, restored: restored);

    if (syncResult == _BackendSyncResult.verified) {
      await _applyEntitlementFromPurchase(purchase, restored: restored);
      await _savePendingVerification(false);
    } else if (syncResult == _BackendSyncResult.invalid) {
      await _savePendingVerification(false);
      await _clearPersistedEntitlement();

      if (purchase.pendingCompletePurchase) {
        await _completePurchaseSafely(purchase);
      }

      purchaseState.value = PlayBillingPurchaseState.error;
      purchaseMessage.value =
          'Purchase is invalid or expired according to backend verification.';
      _completePurchaseOutcome(
        PlayBillingPurchaseOutcome(
          type: PlayBillingPurchaseOutcomeType.error,
          message: purchaseMessage.value,
          productId: purchase.productID,
        ),
      );
      return;
    } else {
      await _applyPendingEntitlement(purchase, restored: restored);
      await _savePendingVerification(true);
      _schedulePendingRetry();
    }

    if (purchase.pendingCompletePurchase) {
      await _completePurchaseSafely(purchase);
    }

    if (syncResult == _BackendSyncResult.verified) {
      purchaseState.value = restored
          ? PlayBillingPurchaseState.restored
          : PlayBillingPurchaseState.purchased;
      purchaseMessage.value = '';
      _completePurchaseOutcome(
        PlayBillingPurchaseOutcome(
          type: restored
              ? PlayBillingPurchaseOutcomeType.restored
              : PlayBillingPurchaseOutcomeType.purchased,
          productId: purchase.productID,
        ),
      );
    } else {
      purchaseState.value = PlayBillingPurchaseState.pending;
      purchaseMessage.value =
          'Verification pending. Your purchase will be confirmed shortly.';
      _completePurchaseOutcome(
        PlayBillingPurchaseOutcome(
          type: PlayBillingPurchaseOutcomeType.pending,
          message: purchaseMessage.value,
          productId: purchase.productID,
        ),
      );
    }
  }

  Future<void> _applyEntitlementFromPurchase(
    PurchaseDetails purchase, {
    required bool restored,
  }) async {
    final now = DateTime.now().toUtc();
    final planCode = PlayBillingConstants.inferPlanCode(
      purchase.productID,
      fallback: activePlanCode.value == 'free'
          ? 'premium'
          : activePlanCode.value,
    );

    hasActiveEntitlement.value = true;
    activeProductId.value = purchase.productID;
    activePlanCode.value = planCode;
    purchaseToken.value = purchase.verificationData.serverVerificationData;
    final basePlanId = _resolveBasePlanIdForProduct(purchase.productID);
    if (basePlanId != null && basePlanId.isNotEmpty) {
      activeBasePlanId.value = basePlanId;
      _knownBasePlansByProductId[purchase.productID] = basePlanId;
    }
    lastSyncedAt.value = now;

    await _storage.saveBool(_entitlementKey, true);
    await _storage.saveString(_productIdKey, purchase.productID);
    await _storage.saveString(_planCodeKey, planCode);
    await _storage.saveString(
      _purchaseTokenKey,
      purchase.verificationData.serverVerificationData,
    );
    await _storage.saveString(_basePlanIdKey, activeBasePlanId.value);
    await _storage.saveString(_lastSyncKey, now.toIso8601String());

    if (restored) {
      debugPrint(
        '[PlayBilling] Restored entitlement for ${purchase.productID}',
      );
    } else {
      debugPrint(
        '[PlayBilling] Activated entitlement for ${purchase.productID}',
      );
    }
  }

  Future<void> _applyPendingEntitlement(
    PurchaseDetails purchase, {
    required bool restored,
  }) async {
    final now = DateTime.now().toUtc();
    purchaseToken.value = purchase.verificationData.serverVerificationData;
    final basePlanId = _resolveBasePlanIdForProduct(purchase.productID);
    if (basePlanId != null && basePlanId.isNotEmpty) {
      activeBasePlanId.value = basePlanId;
      _knownBasePlansByProductId[purchase.productID] = basePlanId;
    }
    lastSyncedAt.value = now;

    await _storage.saveString(_productIdKey, purchase.productID);
    await _storage.saveString(
      _purchaseTokenKey,
      purchase.verificationData.serverVerificationData,
    );
    await _storage.saveString(_basePlanIdKey, activeBasePlanId.value);
    await _storage.saveString(_lastSyncKey, now.toIso8601String());

    debugPrint(
      '[PlayBilling] Purchase pending backend verification for ${purchase.productID} (restored=$restored)',
    );
  }

  /// Public entry used by AuthService.logout(): drops every cached entitlement
  /// from memory and device storage so a re-login cannot leak premium state
  /// from a previous user.
  Future<void> clearEntitlementsForLogout() async {
    await _clearPersistedEntitlement();
    resetTransientState();
  }

  Future<void> _clearPersistedEntitlement() async {
    hasActiveEntitlement.value = false;
    activeProductId.value = '';
    activePlanCode.value = 'free';
    purchaseToken.value = '';
    activeBasePlanId.value = '';
    lastSyncedAt.value = null;
    _expectedPurchaseProductId = null;
    _expectedBasePlanId = null;
    _knownBasePlansByProductId.clear();

    await _storage.saveBool(_entitlementKey, false);
    await _storage.saveString(_productIdKey, '');
    await _storage.saveString(_planCodeKey, 'free');
    await _storage.saveString(_purchaseTokenKey, '');
    await _storage.saveString(_basePlanIdKey, '');
    await _storage.saveString(_lastSyncKey, '');
  }

  Future<_BackendSyncResult> _attemptBackendSync(
    PurchaseDetails purchase, {
    required bool restored,
  }) async {
    try {
      final basePlanId = _resolveBasePlanIdForProduct(purchase.productID);
      await _api.post(
        ApiConstants.googlePlayVerifyPurchase,
        data: {
          'platform': 'android',
          'provider': 'google_play',
          'productId': purchase.productID,
          if (basePlanId != null && basePlanId.isNotEmpty)
            'basePlanId': basePlanId,
          'purchaseId': purchase.purchaseID,
          'purchaseToken': purchase.verificationData.serverVerificationData,
          'verificationData': purchase.verificationData.localVerificationData,
          'verificationSource': purchase.verificationData.source,
          'transactionDate': purchase.transactionDate,
          'restored': restored,
        },
      );
      return _BackendSyncResult.verified;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      final reason = _extractVerificationReason(e.response?.data);
      if (_isInvalidVerificationFailure(statusCode, reason)) {
        debugPrint(
          '[PlayBilling] Backend rejected purchase as invalid. reason=$reason',
        );
        return _BackendSyncResult.invalid;
      }
      debugPrint(
        '[PlayBilling] Backend verification temporarily unavailable (will retry). status=$statusCode reason=$reason',
      );
      return _BackendSyncResult.retryableFailure;
    } catch (e) {
      debugPrint('[PlayBilling] Backend verification failed (will retry): $e');
      return _BackendSyncResult.retryableFailure;
    }
  }

  String? _extractVerificationReason(dynamic raw) {
    final map = _asMap(raw);
    final nested = _asMap(map['data']);
    final source = nested.isNotEmpty ? nested : map;
    final reason = source['reason']?.toString().trim();
    if (reason == null || reason.isEmpty) {
      return null;
    }
    return reason;
  }

  bool _isInvalidVerificationFailure(int statusCode, String? reason) {
    if (statusCode != 400) {
      return false;
    }

    return reason == 'invalid_purchase_token';
  }

  String? _resolveBasePlanIdForProduct(String productId) {
    final normalized = productId.trim();
    if (normalized.isEmpty) {
      return null;
    }

    if (_expectedPurchaseProductId == normalized &&
        _expectedBasePlanId != null &&
        _expectedBasePlanId!.trim().isNotEmpty) {
      return _expectedBasePlanId!.trim();
    }

    final known = _knownBasePlansByProductId[normalized];
    if (known != null && known.trim().isNotEmpty) {
      return known.trim();
    }

    final activeProduct = activeProductId.value.trim();
    if (activeProduct == normalized &&
        activeBasePlanId.value.trim().isNotEmpty) {
      return activeBasePlanId.value.trim();
    }

    return null;
  }

  Future<void> _completePurchaseSafely(PurchaseDetails purchase) async {
    try {
      await _inAppPurchase.completePurchase(purchase);
    } catch (e) {
      debugPrint('[PlayBilling] completePurchase failed: $e');
    }
  }

  void _completePurchaseOutcome(PlayBillingPurchaseOutcome outcome) {
    final completer = _purchaseCompleter;
    if (completer == null || completer.isCompleted) {
      return;
    }
    completer.complete(outcome);
    _purchaseCompleter = null;
    _expectedPurchaseProductId = null;
    _expectedBasePlanId = null;
  }

  void _clearPendingPurchaseContext() {
    _purchaseCompleter = null;
    _expectedPurchaseProductId = null;
    _expectedBasePlanId = null;
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }
}
