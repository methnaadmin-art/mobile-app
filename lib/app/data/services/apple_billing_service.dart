import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/core/constants/api_constants.dart';

enum AppleBillingPurchaseState {
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

enum AppleBillingPurchaseOutcomeType {
  purchased,
  restored,
  pending,
  cancelled,
  error,
  unavailable,
  productNotFound,
}

class AppleBillingPurchaseOutcome {
  const AppleBillingPurchaseOutcome({
    required this.type,
    this.message,
    this.productId,
  });

  final AppleBillingPurchaseOutcomeType type;
  final String? message;
  final String? productId;

  bool get isSuccess =>
      type == AppleBillingPurchaseOutcomeType.purchased ||
      type == AppleBillingPurchaseOutcomeType.restored ||
      type == AppleBillingPurchaseOutcomeType.pending;
}

class AppleBillingService extends GetxService {
  AppleBillingService({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _inAppPurchase;
  final ApiService _api = Get.find<ApiService>();

  final RxBool storeAvailable = false.obs;
  final Rx<AppleBillingPurchaseState> purchaseState =
      AppleBillingPurchaseState.idle.obs;
  final RxString purchaseMessage = ''.obs;
  final RxMap<String, ProductDetails> products = <String, ProductDetails>{}.obs;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Completer<AppleBillingPurchaseOutcome>? _purchaseCompleter;
  String? _expectedPurchaseProductId;

  static const String _premiumProductId = String.fromEnvironment(
    'APPLE_BILLING_PREMIUM',
    defaultValue: 'com.methnapp.app.premium_monthly',
  );
  static const String _premiumMonthlyProductId = String.fromEnvironment(
    'APPLE_BILLING_PREMIUM_MONTHLY',
    defaultValue: 'com.methnapp.app.premium_monthly',
  );
  static const String _premiumYearlyProductId = String.fromEnvironment(
    'APPLE_BILLING_PREMIUM_YEARLY',
    defaultValue: 'com.methnapp.app.premium_yearly',
  );
  static const String _premiumWeeklyProductId = String.fromEnvironment(
    'APPLE_BILLING_PREMIUM_WEEKLY',
    defaultValue: '',
  );

  bool get supportsPlatform =>
      !kIsWeb && (GetPlatform.isIOS || GetPlatform.isMacOS);

  Future<AppleBillingService> init() async {
    if (!supportsPlatform) {
      storeAvailable.value = false;
      purchaseState.value = AppleBillingPurchaseState.idle;
      purchaseMessage.value = '';
      return this;
    }

    await refreshStoreAvailability();

    _purchaseSubscription?.cancel();
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        purchaseState.value = AppleBillingPurchaseState.error;
        purchaseMessage.value = 'Apple purchase stream failed.';
        _log('purchaseUpdatedStream error: $error');
        _completePurchase(
          const AppleBillingPurchaseOutcome(
            type: AppleBillingPurchaseOutcomeType.error,
            message: 'Apple purchase stream failed.',
          ),
        );
      },
      onDone: () => _purchaseSubscription = null,
    );

    purchaseState.value = AppleBillingPurchaseState.idle;
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
      _log('store availability=${storeAvailable.value}');
      if (!storeAvailable.value) {
        purchaseState.value = AppleBillingPurchaseState.unavailable;
        purchaseMessage.value = 'Apple in-app purchases are unavailable.';
      } else if (purchaseState.value == AppleBillingPurchaseState.unavailable) {
        purchaseState.value = AppleBillingPurchaseState.idle;
        purchaseMessage.value = '';
      }
    } catch (e) {
      storeAvailable.value = false;
      purchaseState.value = AppleBillingPurchaseState.unavailable;
      purchaseMessage.value = 'Apple in-app purchases are unavailable.';
      _log('isAvailable error: $e');
    }
  }

  String? resolveProductIdForPlan({
    required String planCode,
    required int durationDays,
    Map<String, dynamic>? planMetadata,
  }) {
    final candidates = resolveCandidateProductIdsForPlan(
      planCode: planCode,
      durationDays: durationDays,
      planMetadata: planMetadata,
    );
    if (candidates.isEmpty) return null;
    return candidates.first;
  }

  List<String> resolveCandidateProductIdsForPlan({
    required String planCode,
    required int durationDays,
    Map<String, dynamic>? planMetadata,
  }) {
    final metadata = planMetadata ?? const <String, dynamic>{};
    final candidates = <String>[];

    void addCandidate(String? value) {
      final normalized = _emptyToNull(value ?? '');
      if (normalized == null || candidates.contains(normalized)) return;
      candidates.add(normalized);
    }

    for (final appleProductId in _readAllStrings(metadata, const [
      'iosProductId',
      'appleProductId',
      'ios_product_id',
      'apple_product_id',
      'appStoreProductId',
      'app_store_product_id',
    ])) {
      addCandidate(appleProductId);
    }

    addCandidate(
      _fallbackProductIdForPlan(
        planCode: planCode,
        durationDays: durationDays,
        planMetadata: metadata,
      ),
    );

    return candidates;
  }

  ProductDetails? productForPlan({
    required String planCode,
    required int durationDays,
    Map<String, dynamic>? planMetadata,
  }) {
    final productIds = resolveCandidateProductIdsForPlan(
      planCode: planCode,
      durationDays: durationDays,
      planMetadata: planMetadata,
    );
    for (final productId in productIds) {
      final product = products[productId];
      if (product != null) return product;
    }
    return null;
  }

  bool isStoreProductLoadedForPlan({
    required String planCode,
    required int durationDays,
    Map<String, dynamic>? planMetadata,
  }) {
    return productForPlan(
          planCode: planCode,
          durationDays: durationDays,
          planMetadata: planMetadata,
        ) !=
        null;
  }

  Future<void> prefetchPlans(Iterable<Map<String, dynamic>> plans) async {
    if (!supportsPlatform) return;

    final productIds = plans
        .expand(
          (plan) => resolveCandidateProductIdsForPlan(
            planCode: (plan['code'] ?? plan['planCode'] ?? '').toString(),
            durationDays: _readDurationDays(plan),
            planMetadata: plan,
          ),
        )
        .where((id) => id.trim().isNotEmpty)
        .toSet();

    if (productIds.isEmpty) return;
    await loadProducts(productIds);
  }

  Future<void> loadProducts(Iterable<String> productIds) async {
    if (!supportsPlatform) return;

    final normalizedIds = productIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (normalizedIds.isEmpty) return;

    purchaseState.value = AppleBillingPurchaseState.loadingProducts;
    try {
      _log(
        'queryProductDetails request productIds=${normalizedIds.join(', ')}',
      );
      final response = await _inAppPurchase.queryProductDetails(normalizedIds);
      _log(
        'queryProductDetails response found=${response.productDetails.length} '
        'notFound=${response.notFoundIDs.length} '
        'error=${response.error?.message ?? 'none'}',
      );
      if (response.error != null) {
        purchaseState.value = AppleBillingPurchaseState.error;
        purchaseMessage.value =
            response.error?.message ?? 'Unable to load Apple products.';
        _log(
          'queryProductDetails failed message=${purchaseMessage.value} '
          'requested=${normalizedIds.join(', ')}',
        );
        return;
      }

      products.addAll({
        for (final product in response.productDetails) product.id: product,
      });
      for (final product in response.productDetails) {
        _log(
          'StoreKit product id=${product.id} price=${product.price} '
          'title="${_summarizeText(product.title, maxLength: 80)}"',
        );
      }

      if (response.notFoundIDs.isNotEmpty) {
        _log('StoreKit products not found: ${response.notFoundIDs.join(', ')}');
      }

      if (purchaseState.value == AppleBillingPurchaseState.loadingProducts) {
        purchaseState.value = AppleBillingPurchaseState.idle;
        purchaseMessage.value = '';
      }
    } catch (e) {
      purchaseState.value = AppleBillingPurchaseState.error;
      purchaseMessage.value = 'Unable to load Apple products.';
      _log('loadProducts error: $e');
    }
  }

  Future<AppleBillingPurchaseOutcome> purchaseSubscription({
    required String planCode,
    required int durationDays,
    Map<String, dynamic>? planMetadata,
    String? accountId,
  }) async {
    if (!supportsPlatform) {
      return const AppleBillingPurchaseOutcome(
        type: AppleBillingPurchaseOutcomeType.unavailable,
      );
    }

    await refreshStoreAvailability();
    if (!storeAvailable.value) {
      return const AppleBillingPurchaseOutcome(
        type: AppleBillingPurchaseOutcomeType.unavailable,
        message: 'Apple in-app purchases are unavailable.',
      );
    }

    final candidateProductIds = resolveCandidateProductIdsForPlan(
      planCode: planCode,
      durationDays: durationDays,
      planMetadata: planMetadata,
    );
    final productId = candidateProductIds.isEmpty
        ? null
        : candidateProductIds.first;
    _log(
      'purchase request planCode=$planCode durationDays=$durationDays '
      'candidateProductIds=${candidateProductIds.join(', ')} '
      'accountId=${accountId ?? 'null'}',
    );
    if (productId == null) {
      purchaseState.value = AppleBillingPurchaseState.error;
      purchaseMessage.value = 'This plan is not linked to App Store Connect.';
      return const AppleBillingPurchaseOutcome(
        type: AppleBillingPurchaseOutcomeType.productNotFound,
        message: 'This plan is not linked to App Store Connect.',
      );
    }

    await loadProducts(candidateProductIds);
    ProductDetails? product;
    var selectedProductId = productId;
    for (final candidateProductId in candidateProductIds) {
      final candidateProduct = products[candidateProductId];
      if (candidateProduct != null) {
        product = candidateProduct;
        selectedProductId = candidateProductId;
        break;
      }
    }
    if (product == null) {
      purchaseState.value = AppleBillingPurchaseState.error;
      purchaseMessage.value =
          'App Store did not return this subscription: ${candidateProductIds.join(', ')}. '
          'Check App Store Connect: the subscription must be attached to this app version, submitted with the build, available in this storefront, and ready for sandbox/TestFlight.';
      _log(
        'purchase aborted because StoreKit did not return '
        'candidateProductIds=${candidateProductIds.join(', ')} '
        'loadedProductIds=${products.keys.join(', ')}',
      );
      return AppleBillingPurchaseOutcome(
        type: AppleBillingPurchaseOutcomeType.productNotFound,
        message: purchaseMessage.value,
        productId: productId,
      );
    }
    if (selectedProductId != productId) {
      _log(
        'using fallback StoreKit productId=$selectedProductId '
        'after primary productId=$productId was unavailable',
      );
    }

    if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
      return const AppleBillingPurchaseOutcome(
        type: AppleBillingPurchaseOutcomeType.error,
        message: 'A purchase is already in progress.',
      );
    }

    _expectedPurchaseProductId = selectedProductId;
    _purchaseCompleter = Completer<AppleBillingPurchaseOutcome>();
    purchaseState.value = AppleBillingPurchaseState.purchasing;
    purchaseMessage.value = '';

    try {
      _log(
        'buyNonConsumable request productId=${product.id} '
        'price=${product.price} title="${_summarizeText(product.title, maxLength: 80)}"',
      );
      final started = await _inAppPurchase.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: product,
          applicationUserName: accountId,
        ),
      );
      _log('buyNonConsumable started=$started productId=$selectedProductId');
      if (!started) {
        _expectedPurchaseProductId = null;
        _purchaseCompleter = null;
        purchaseState.value = AppleBillingPurchaseState.error;
        purchaseMessage.value = 'Could not open App Store checkout.';
        return AppleBillingPurchaseOutcome(
          type: AppleBillingPurchaseOutcomeType.error,
          message: purchaseMessage.value,
          productId: selectedProductId,
        );
      }
    } catch (e) {
      _expectedPurchaseProductId = null;
      _purchaseCompleter = null;
      purchaseState.value = AppleBillingPurchaseState.error;
      purchaseMessage.value = 'App Store purchase failed to start.';
      _log('purchaseSubscription error: $e');
      return AppleBillingPurchaseOutcome(
        type: AppleBillingPurchaseOutcomeType.error,
        message: purchaseMessage.value,
        productId: selectedProductId,
      );
    }

    return _purchaseCompleter!.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        purchaseState.value = AppleBillingPurchaseState.pending;
        purchaseMessage.value =
            'Purchase is still processing in the App Store.';
        return AppleBillingPurchaseOutcome(
          type: AppleBillingPurchaseOutcomeType.pending,
          message: purchaseMessage.value,
          productId: selectedProductId,
        );
      },
    );
  }

  Future<void> restorePurchases() async {
    if (!supportsPlatform) return;
    await refreshStoreAvailability();
    if (!storeAvailable.value) return;
    try {
      _log('restorePurchases requested');
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      purchaseState.value = AppleBillingPurchaseState.error;
      purchaseMessage.value = 'Could not restore App Store purchases.';
      _log('restorePurchases error: $e');
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    _log('purchaseUpdatedStream batch size=${purchases.length}');
    for (final purchase in purchases) {
      final expected = _expectedPurchaseProductId;
      final isExpected = expected == null || expected == purchase.productID;

      _log(
        'purchaseUpdatedStream item productId=${purchase.productID} '
        'purchaseId=${purchase.purchaseID ?? 'null'} '
        'status=${purchase.status} '
        'pendingComplete=${purchase.pendingCompletePurchase} '
        'transactionDate=${purchase.transactionDate ?? 'null'} '
        'source=${purchase.verificationData.source}',
      );

      if (!isExpected && purchase.status != PurchaseStatus.restored) {
        _log(
          'purchaseUpdatedStream ignoring unexpected productId=${purchase.productID} '
          'expected=$expected',
        );
        continue;
      }

      if (purchase.status == PurchaseStatus.pending) {
        purchaseState.value = AppleBillingPurchaseState.pending;
        purchaseMessage.value = 'Purchase is pending in the App Store.';
        _log('purchase status pending productId=${purchase.productID}');
        _completePurchase(
          AppleBillingPurchaseOutcome(
            type: AppleBillingPurchaseOutcomeType.pending,
            message: purchaseMessage.value,
            productId: purchase.productID,
          ),
          keepExpected: true,
        );
        continue;
      }

      if (purchase.status == PurchaseStatus.canceled) {
        purchaseState.value = AppleBillingPurchaseState.cancelled;
        purchaseMessage.value = '';
        _log('purchase status cancelled productId=${purchase.productID}');
        await _completePurchaseIfNeeded(purchase);
        _completePurchase(
          AppleBillingPurchaseOutcome(
            type: AppleBillingPurchaseOutcomeType.cancelled,
            productId: purchase.productID,
          ),
        );
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        purchaseState.value = AppleBillingPurchaseState.error;
        purchaseMessage.value =
            purchase.error?.message ?? 'App Store purchase was not completed.';
        _log(
          'purchase status error productId=${purchase.productID} '
          'message=${purchase.error?.message ?? purchaseMessage.value}',
        );
        await _completePurchaseIfNeeded(purchase);
        _completePurchase(
          AppleBillingPurchaseOutcome(
            type: AppleBillingPurchaseOutcomeType.error,
            message: purchaseMessage.value,
            productId: purchase.productID,
          ),
        );
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _log(
          'purchase status ${purchase.status} entering backend verification '
          'productId=${purchase.productID}',
        );
        final verified = await _verifyWithBackend(purchase);
        if (verified) {
          await _completePurchaseIfNeeded(purchase);
          final restored = purchase.status == PurchaseStatus.restored;
          purchaseState.value = restored
              ? AppleBillingPurchaseState.restored
              : AppleBillingPurchaseState.purchased;
          purchaseMessage.value = '';
          _log(
            'backend verification succeeded productId=${purchase.productID} '
            'status=${purchase.status}',
          );
          _completePurchase(
            AppleBillingPurchaseOutcome(
              type: restored
                  ? AppleBillingPurchaseOutcomeType.restored
                  : AppleBillingPurchaseOutcomeType.purchased,
              productId: purchase.productID,
            ),
          );
          continue;
        }

        purchaseState.value = AppleBillingPurchaseState.error;
        if (purchaseMessage.value.trim().isEmpty) {
          purchaseMessage.value =
              'Purchase could not be verified. Your subscription was not changed.';
        }
        _log(
          'backend verification failed productId=${purchase.productID} '
          'message=${purchaseMessage.value}',
        );
        _completePurchase(
          AppleBillingPurchaseOutcome(
            type: AppleBillingPurchaseOutcomeType.error,
            message: purchaseMessage.value,
            productId: purchase.productID,
          ),
        );
      }
    }
  }

  Future<bool> _verifyWithBackend(PurchaseDetails purchase) async {
    final receiptData = purchase.verificationData.serverVerificationData.trim();
    final localVerificationData = purchase
        .verificationData
        .localVerificationData
        .trim();
    final verificationSource = purchase.verificationData.source;
    if (receiptData.isEmpty) {
      if (localVerificationData.isEmpty) {
        purchaseMessage.value = 'The App Store did not return a receipt.';
        _log('backend verify skipped because receipt data is empty');
        return false;
      }
      _log(
        'serverVerificationData empty; falling back to localVerificationData '
        'length=${localVerificationData.length}',
      );
    }

    final verificationToken = receiptData.isNotEmpty
        ? receiptData
        : localVerificationData;
    if (verificationToken.isEmpty) {
      return false;
    }

    purchaseState.value = AppleBillingPurchaseState.syncing;
    try {
      _log(
        'backend verify request path=${ApiConstants.appleVerifyPurchase} '
        'productId=${purchase.productID} '
        'transactionId=${purchase.purchaseID ?? 'null'} '
        'status=${purchase.status} '
        'receiptLength=${receiptData.length} '
        'localVerificationLength=${localVerificationData.length} '
        'source=$verificationSource '
        'restored=${purchase.status == PurchaseStatus.restored}',
      );
      final response = await _api.post(
        ApiConstants.appleVerifyPurchase,
        data: {
          'platform': 'ios',
          'provider': 'apple',
          'productId': purchase.productID,
          'transactionId': purchase.purchaseID,
          'purchaseToken': verificationToken,
          'serverVerificationData': verificationToken,
          'receiptData': verificationToken,
          'verificationData': {
            'serverVerificationData': verificationToken,
            'localVerificationData': localVerificationData,
            'source': verificationSource,
          },
          'localVerificationData': localVerificationData,
          'verificationSource': verificationSource,
          'transactionDate': purchase.transactionDate,
          'restored': purchase.status == PurchaseStatus.restored,
        },
      );
      _log(
        'backend verify response status=${response.statusCode ?? 'unknown'} '
        'body=${_summarizeValue(response.data, maxLength: 240)}',
      );
      return true;
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['message']?.toString().trim() ?? '')
          : '';
      purchaseMessage.value = message.isNotEmpty
          ? message
          : 'Apple purchase verification failed.';
      _log(
        'backend verify error status=${e.response?.statusCode ?? 'unknown'} '
        'message=${purchaseMessage.value} '
        'body=${_summarizeValue(e.response?.data, maxLength: 240)}',
      );
      return false;
    } catch (e) {
      purchaseMessage.value = 'Apple purchase verification failed.';
      _log('backend verify error: $e');
      return false;
    }
  }

  Future<void> _completePurchaseIfNeeded(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) return;
    try {
      await _inAppPurchase.completePurchase(purchase);
      _log('completePurchase finished productId=${purchase.productID}');
    } catch (e) {
      _log('completePurchase warning: $e');
    }
  }

  void _completePurchase(
    AppleBillingPurchaseOutcome outcome, {
    bool keepExpected = false,
  }) {
    final completer = _purchaseCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(outcome);
    }
    _purchaseCompleter = null;
    if (!keepExpected) {
      _expectedPurchaseProductId = null;
    }
  }

  void _log(String message) {
    debugPrint('[AppleBilling] $message');
  }

  static String _summarizeText(String? value, {int maxLength = 160}) {
    final normalized = (value ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return '';
    if (normalized.length <= maxLength) return normalized;
    return '${normalized.substring(0, maxLength - 3)}...';
  }

  static String _summarizeValue(Object? value, {int maxLength = 160}) {
    if (value == null) return 'null';
    return _summarizeText(value.toString(), maxLength: maxLength);
  }

  static int _readDurationDays(Map<String, dynamic> plan) {
    final value = plan['durationDays'] ?? plan['duration_days'] ?? 30;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 30;
  }

  static String? _fallbackProductIdForPlan({
    required String planCode,
    required int durationDays,
    required Map<String, dynamic> planMetadata,
  }) {
    final cycle =
        _readString(planMetadata, const [
          'billingCycle',
          'billing_cycle',
          'cycle',
          'interval',
        ])?.toLowerCase() ??
        '';
    final normalizedPlan = _normalizeToken(
      [
        planCode,
        planMetadata['code'],
        planMetadata['planCode'],
        planMetadata['slug'],
        planMetadata['name'],
      ].map((value) => value?.toString() ?? '').join(' '),
    );

    if (cycle.contains('week') || durationDays >= 6 && durationDays <= 10) {
      return _emptyToNull(_premiumWeeklyProductId);
    }

    if (cycle.contains('year') ||
        cycle.contains('annual') ||
        durationDays >= 300 ||
        normalizedPlan.contains('year')) {
      return _firstNonEmpty([_premiumYearlyProductId, _premiumProductId]);
    }

    if (cycle.contains('month') ||
        durationDays >= 25 && durationDays <= 35 ||
        normalizedPlan.contains('month') ||
        normalizedPlan.contains('premium')) {
      return _firstNonEmpty([_premiumMonthlyProductId, _premiumProductId]);
    }

    return _emptyToNull(_premiumProductId);
  }

  static String _normalizeToken(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static String? _firstNonEmpty(Iterable<String> values) {
    for (final value in values) {
      final normalized = _emptyToNull(value);
      if (normalized != null) return normalized;
    }
    return null;
  }

  static String? _emptyToNull(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  static String? _readString(Map<String, dynamic> data, Iterable<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }

    final metadata = data['metadata'];
    if (metadata is Map) {
      return _readString(Map<String, dynamic>.from(metadata), keys);
    }

    return null;
  }

  static List<String> _readAllStrings(
    Map<String, dynamic> data,
    Iterable<String> keys,
  ) {
    final values = <String>[];

    void addValue(String? value) {
      final normalized = value?.trim();
      if (normalized == null ||
          normalized.isEmpty ||
          normalized.toLowerCase() == 'null' ||
          values.contains(normalized)) {
        return;
      }
      values.add(normalized);
    }

    for (final key in keys) {
      addValue(data[key]?.toString());
    }

    final metadata = data['metadata'];
    if (metadata is Map) {
      for (final value in _readAllStrings(
        Map<String, dynamic>.from(metadata),
        keys,
      )) {
        addValue(value);
      }
    }

    return values;
  }

  @override
  void onClose() {
    _purchaseSubscription?.cancel();
    super.onClose();
  }
}
