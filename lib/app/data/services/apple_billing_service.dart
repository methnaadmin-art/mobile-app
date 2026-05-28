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
        debugPrint('[AppleBilling] purchase stream error: $error');
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
      debugPrint('[AppleBilling] isAvailable error: $e');
    }
  }

  String? resolveProductIdForPlan({
    required String planCode,
    required int durationDays,
    Map<String, dynamic>? planMetadata,
  }) {
    final metadata = planMetadata ?? const <String, dynamic>{};
    return _readString(metadata, const [
      'iosProductId',
      'appleProductId',
      'ios_product_id',
      'apple_product_id',
      'appStoreProductId',
    ]);
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
    if (productId == null) return null;
    return products[productId];
  }

  Future<void> prefetchPlans(Iterable<Map<String, dynamic>> plans) async {
    if (!supportsPlatform) return;

    final productIds = plans
        .map(
          (plan) => resolveProductIdForPlan(
            planCode: (plan['code'] ?? plan['planCode'] ?? '').toString(),
            durationDays: _readDurationDays(plan),
            planMetadata: plan,
          ),
        )
        .whereType<String>()
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
      final response = await _inAppPurchase.queryProductDetails(normalizedIds);
      if (response.error != null) {
        purchaseState.value = AppleBillingPurchaseState.error;
        purchaseMessage.value =
            response.error?.message ?? 'Unable to load Apple products.';
        return;
      }

      products.addAll({
        for (final product in response.productDetails) product.id: product,
      });

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
          '[AppleBilling] products not found: ${response.notFoundIDs.join(', ')}',
        );
      }

      if (purchaseState.value == AppleBillingPurchaseState.loadingProducts) {
        purchaseState.value = AppleBillingPurchaseState.idle;
        purchaseMessage.value = '';
      }
    } catch (e) {
      purchaseState.value = AppleBillingPurchaseState.error;
      purchaseMessage.value = 'Unable to load Apple products.';
      debugPrint('[AppleBilling] loadProducts error: $e');
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

    final productId = resolveProductIdForPlan(
      planCode: planCode,
      durationDays: durationDays,
      planMetadata: planMetadata,
    );
    if (productId == null) {
      purchaseState.value = AppleBillingPurchaseState.error;
      purchaseMessage.value = 'This plan is not linked to App Store Connect.';
      return const AppleBillingPurchaseOutcome(
        type: AppleBillingPurchaseOutcomeType.productNotFound,
        message: 'This plan is not linked to App Store Connect.',
      );
    }

    await loadProducts([productId]);
    final product = products[productId];
    if (product == null) {
      purchaseState.value = AppleBillingPurchaseState.error;
      purchaseMessage.value = 'This plan is not available in the App Store.';
      return AppleBillingPurchaseOutcome(
        type: AppleBillingPurchaseOutcomeType.productNotFound,
        message: purchaseMessage.value,
        productId: productId,
      );
    }

    if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
      return const AppleBillingPurchaseOutcome(
        type: AppleBillingPurchaseOutcomeType.error,
        message: 'A purchase is already in progress.',
      );
    }

    _expectedPurchaseProductId = productId;
    _purchaseCompleter = Completer<AppleBillingPurchaseOutcome>();
    purchaseState.value = AppleBillingPurchaseState.purchasing;
    purchaseMessage.value = '';

    try {
      final started = await _inAppPurchase.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: product,
          applicationUserName: accountId,
        ),
      );
      if (!started) {
        _expectedPurchaseProductId = null;
        _purchaseCompleter = null;
        purchaseState.value = AppleBillingPurchaseState.error;
        purchaseMessage.value = 'Could not open App Store checkout.';
        return AppleBillingPurchaseOutcome(
          type: AppleBillingPurchaseOutcomeType.error,
          message: purchaseMessage.value,
          productId: productId,
        );
      }
    } catch (e) {
      _expectedPurchaseProductId = null;
      _purchaseCompleter = null;
      purchaseState.value = AppleBillingPurchaseState.error;
      purchaseMessage.value = 'App Store purchase failed to start.';
      debugPrint('[AppleBilling] purchaseSubscription error: $e');
      return AppleBillingPurchaseOutcome(
        type: AppleBillingPurchaseOutcomeType.error,
        message: purchaseMessage.value,
        productId: productId,
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
          productId: productId,
        );
      },
    );
  }

  Future<void> restorePurchases() async {
    if (!supportsPlatform) return;
    await refreshStoreAvailability();
    if (!storeAvailable.value) return;
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      purchaseState.value = AppleBillingPurchaseState.error;
      purchaseMessage.value = 'Could not restore App Store purchases.';
      debugPrint('[AppleBilling] restorePurchases error: $e');
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final expected = _expectedPurchaseProductId;
      final isExpected = expected == null || expected == purchase.productID;

      if (!isExpected && purchase.status != PurchaseStatus.restored) {
        continue;
      }

      if (purchase.status == PurchaseStatus.pending) {
        purchaseState.value = AppleBillingPurchaseState.pending;
        purchaseMessage.value = 'Purchase is pending in the App Store.';
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
        final verified = await _verifyWithBackend(purchase);
        if (verified) {
          await _completePurchaseIfNeeded(purchase);
          final restored = purchase.status == PurchaseStatus.restored;
          purchaseState.value = restored
              ? AppleBillingPurchaseState.restored
              : AppleBillingPurchaseState.purchased;
          purchaseMessage.value = '';
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
    if (receiptData.isEmpty) {
      purchaseMessage.value = 'The App Store did not return a receipt.';
      return false;
    }

    purchaseState.value = AppleBillingPurchaseState.syncing;
    try {
      await _api.post(
        ApiConstants.appleVerifyPurchase,
        data: {
          'platform': 'ios',
          'provider': 'apple',
          'productId': purchase.productID,
          'transactionId': purchase.purchaseID,
          'receiptData': receiptData,
          'localVerificationData':
              purchase.verificationData.localVerificationData,
          'verificationSource': purchase.verificationData.source,
          'transactionDate': purchase.transactionDate,
          'restored': purchase.status == PurchaseStatus.restored,
        },
      );
      return true;
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['message']?.toString().trim() ?? '')
          : '';
      purchaseMessage.value = message.isNotEmpty
          ? message
          : 'Apple purchase verification failed.';
      debugPrint('[AppleBilling] backend verification error: $e');
      return false;
    } catch (e) {
      purchaseMessage.value = 'Apple purchase verification failed.';
      debugPrint('[AppleBilling] backend verification error: $e');
      return false;
    }
  }

  Future<void> _completePurchaseIfNeeded(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) return;
    try {
      await _inAppPurchase.completePurchase(purchase);
    } catch (e) {
      debugPrint('[AppleBilling] completePurchase warning: $e');
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

  static int _readDurationDays(Map<String, dynamic> plan) {
    final value = plan['durationDays'] ?? plan['duration_days'] ?? 30;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 30;
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

  @override
  void onClose() {
    _purchaseSubscription?.cancel();
    super.onClose();
  }
}
