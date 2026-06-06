import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/core/constants/api_constants.dart';

/// Model for a consumable product returned by the backend.
class ConsumableProduct {
  final String id;
  final String code;
  final String title;
  final String? description;
  final String type; // likes_pack, compliments_pack, boosts_pack
  final int quantity;
  final double price;
  final String currency;
  final String? googleProductId;
  final String? iosProductId;
  final int sortOrder;

  ConsumableProduct({
    required this.id,
    required this.code,
    required this.title,
    this.description,
    required this.type,
    required this.quantity,
    required this.price,
    required this.currency,
    this.googleProductId,
    this.iosProductId,
    required this.sortOrder,
  });

  factory ConsumableProduct.fromJson(Map<String, dynamic> json) {
    return ConsumableProduct(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      type: json['type'] ?? 'likes_pack',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      currency: json['currency'] ?? 'usd',
      googleProductId: json['googleProductId'] ?? json['androidProductId'],
      iosProductId: json['iosProductId'] ?? json['appleProductId'],
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  String get typeLabel {
    switch (type) {
      case 'likes_pack':
        return 'Likes';
      case 'compliments_pack':
        return 'Compliments';
      case 'boosts_pack':
        return 'Boosts';
      default:
        return type;
    }
  }

  String get emoji {
    switch (type) {
      case 'likes_pack':
        return '❤️';
      case 'compliments_pack':
        return '💬';
      case 'boosts_pack':
        return '⚡';
      default:
        return '🛒';
    }
  }
}

/// User consumable balances.
class UserConsumableBalances {
  final int likes;
  final int compliments;
  final int boosts;

  UserConsumableBalances({
    required this.likes,
    required this.compliments,
    required this.boosts,
  });

  factory UserConsumableBalances.fromJson(Map<String, dynamic> json) {
    return UserConsumableBalances(
      likes: json['likes'] ?? 0,
      compliments: json['compliments'] ?? 0,
      boosts: json['boosts'] ?? 0,
    );
  }

  int get total => likes + compliments + boosts;
}

enum _PurchaseVerificationStatus {
  verified,
  retryableFailure,
  permanentFailure,
}

class _PurchaseVerificationResult {
  final _PurchaseVerificationStatus status;

  const _PurchaseVerificationResult(this.status);

  bool get isVerified => status == _PurchaseVerificationStatus.verified;
  bool get isRetryable =>
      status == _PurchaseVerificationStatus.retryableFailure;
}

class ConsumableService extends GetxService {
  static const int maxDailyConsumablePurchases = 10;

  final ApiService _api = Get.find<ApiService>();
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  // Reactive state
  final RxList<ConsumableProduct> products = <ConsumableProduct>[].obs;
  final Rx<UserConsumableBalances> balances = UserConsumableBalances(
    likes: 0,
    compliments: 0,
    boosts: 0,
  ).obs;
  final RxBool isLoading = false.obs;
  final RxBool isVerifying = false.obs;
  final RxBool storeAvailable = false.obs;
  final RxString purchaseMessage = ''.obs;
  final RxMap<String, ProductDetails> storeProducts =
      <String, ProductDetails>{}.obs;
  final Map<String, Completer<bool>> _pendingConsumablePurchases = {};
  bool _isRestoringPurchases = false;
  DateTime? _surfaceRestoreVerificationErrorsUntil;

  @override
  void onInit() {
    super.onInit();
    if (!(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      storeAvailable.value = false;
      storeProducts.clear();
      return;
    }

    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        purchaseMessage.value = Platform.isAndroid
            ? 'Google Play purchase failed.'
            : 'App Store purchase failed.';
        debugPrint('[ConsumableService] purchase stream error: $error');
        _completePendingPurchases(false);
      },
    );
    // Restore past purchases so any consumable bought but not consumed (e.g.
    // killed app mid-verify, offline at purchase time) gets delivered and
    // consumed on the next launch. Without this, Google Play returns
    // "item already owned" the next time the user tries to buy it.
    unawaited(_restoreOrphanPurchases());
  }

  Future<void> _restoreOrphanPurchases({bool surfaceErrors = false}) async {
    if (surfaceErrors) {
      _surfaceRestoreVerificationErrorsUntil = DateTime.now().add(
        const Duration(seconds: 10),
      );
    }
    if (_isRestoringPurchases) {
      return;
    }

    _isRestoringPurchases = true;
    try {
      if (!(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) return;
      if (!await _inAppPurchase.isAvailable()) return;
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('[ConsumableService] restorePurchases warning: $e');
    } finally {
      _isRestoringPurchases = false;
    }
  }

  @override
  void onClose() {
    _purchaseSubscription?.cancel();
    super.onClose();
  }

  // ─── Fetch consumable product catalog ────────────────────
  Future<void> fetchProducts() async {
    isLoading.value = true;
    try {
      final response = await _api.get(ApiConstants.consumableProducts);
      final list = _extractList(response.data);
      products.value = list
          .whereType<Map>()
          .map(
            (item) =>
                ConsumableProduct.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
      await _syncStoreProductsForCatalog();
    } catch (e) {
      debugPrint('[ConsumableService] fetchProducts error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Fetch user balances ──────────────────────────────────
  Future<void> fetchBalances() async {
    try {
      final response = await _api.get(ApiConstants.consumableBalances);
      final data = _extractRootMap(response.data);
      balances.value = UserConsumableBalances.fromJson(data);
    } catch (e) {
      debugPrint('[ConsumableService] fetchBalances error: $e');
    }
  }

  // ─── Verify Google Play consumable purchase ──────────────
  Future<_PurchaseVerificationResult> _verifyGooglePlayPurchase({
    required String productId,
    required String purchaseToken,
    String? orderId,
    String? transactionDate,
    bool surfaceErrors = true,
  }) async {
    isVerifying.value = true;
    try {
      await _api.post(
        ApiConstants.consumableVerifyGooglePlay,
        data: {
          'productId': productId,
          'purchaseToken': purchaseToken,
          if (orderId != null && orderId.trim().isNotEmpty) 'orderId': orderId,
          if (transactionDate != null && transactionDate.trim().isNotEmpty)
            'transactionDate': transactionDate,
        },
      );
      // Refresh balances after successful verification
      await fetchBalances();
      return const _PurchaseVerificationResult(
        _PurchaseVerificationStatus.verified,
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      final payload = _extractRootMap(e.response?.data);
      final reason = payload['reason']?.toString().trim();
      final backendMessage = payload['message']?.toString().trim() ?? '';

      if (_isRetryableVerificationFailure(statusCode, reason)) {
        if (surfaceErrors) {
          purchaseMessage.value =
              'Purchase verification is temporarily unavailable. Please wait a moment and try again.';
        }
        return const _PurchaseVerificationResult(
          _PurchaseVerificationStatus.retryableFailure,
        );
      } else if (_isDailyPurchaseLimitMessage(backendMessage)) {
        if (surfaceErrors) {
          purchaseMessage.value =
              'You reached the maximum of 10 consumable purchases for today.';
        }
      } else if (surfaceErrors && backendMessage.isNotEmpty) {
        purchaseMessage.value = backendMessage;
      }

      debugPrint(
        '[ConsumableService] verifyGooglePlayPurchase dio error: status=$statusCode reason=$reason error=$e',
      );
      return const _PurchaseVerificationResult(
        _PurchaseVerificationStatus.permanentFailure,
      );
    } catch (e) {
      if (surfaceErrors) {
        purchaseMessage.value =
            'Purchase verification is temporarily unavailable. Please wait a moment and try again.';
      }
      debugPrint('[ConsumableService] verifyGooglePlayPurchase error: $e');
      return const _PurchaseVerificationResult(
        _PurchaseVerificationStatus.retryableFailure,
      );
    } finally {
      isVerifying.value = false;
    }
  }

  Future<_PurchaseVerificationResult> _verifyApplePurchase({
    required String productId,
    required String receiptData,
    String? transactionId,
    String? transactionDate,
    bool surfaceErrors = true,
  }) async {
    isVerifying.value = true;
    try {
      await _api.post(
        ApiConstants.consumableVerifyApple,
        data: {
          'platform': 'ios',
          'provider': 'apple',
          'productId': productId,
          'receiptData': receiptData,
          if (transactionId != null && transactionId.trim().isNotEmpty)
            'transactionId': transactionId,
          if (transactionDate != null && transactionDate.trim().isNotEmpty)
            'transactionDate': transactionDate,
        },
      );
      await fetchBalances();
      return const _PurchaseVerificationResult(
        _PurchaseVerificationStatus.verified,
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      final payload = _extractRootMap(e.response?.data);
      final reason = payload['reason']?.toString().trim();
      final backendMessage = payload['message']?.toString().trim() ?? '';

      if (_isRetryableVerificationFailure(statusCode, reason)) {
        if (surfaceErrors) {
          purchaseMessage.value =
              'Purchase verification is temporarily unavailable. Please wait a moment and try again.';
        }
        return const _PurchaseVerificationResult(
          _PurchaseVerificationStatus.retryableFailure,
        );
      }
      if (_isDailyPurchaseLimitMessage(backendMessage)) {
        if (surfaceErrors) {
          purchaseMessage.value =
              'You reached the maximum of 10 consumable purchases for today.';
        }
      } else if (surfaceErrors && backendMessage.isNotEmpty) {
        purchaseMessage.value = backendMessage;
      }

      debugPrint(
        '[ConsumableService] verifyApplePurchase dio error: status=$statusCode reason=$reason error=$e',
      );
      return const _PurchaseVerificationResult(
        _PurchaseVerificationStatus.permanentFailure,
      );
    } catch (e) {
      if (surfaceErrors) {
        purchaseMessage.value =
            'Purchase verification is temporarily unavailable. Please wait a moment and try again.';
      }
      debugPrint('[ConsumableService] verifyApplePurchase error: $e');
      return const _PurchaseVerificationResult(
        _PurchaseVerificationStatus.retryableFailure,
      );
    } finally {
      isVerifying.value = false;
    }
  }

  Future<void> refreshStoreProducts() => _syncStoreProductsForCatalog();

  Future<void> retryPendingPurchaseVerification() async {
    purchaseMessage.value = '';
    await _restoreOrphanPurchases(surfaceErrors: true);
  }

  String storeProductIdFor(ConsumableProduct product) {
    final isApplePlatform = Platform.isIOS || Platform.isMacOS;
    return isApplePlatform
        ? (product.iosProductId?.trim() ?? '')
        : (product.googleProductId?.trim() ?? '');
  }

  List<ConsumableProduct> visibleProductsByType(String type) {
    final typedProducts = getProductsByType(type);
    final configuredProducts = typedProducts
        .where((product) => storeProductIdFor(product).isNotEmpty)
        .toList(growable: false);

    if (configuredProducts.isEmpty) {
      return typedProducts;
    }

    final storeResolvedProducts = configuredProducts
        .where((product) => storeProducts.containsKey(storeProductIdFor(product)))
        .toList(growable: false);

    if (storeResolvedProducts.isNotEmpty) {
      return storeResolvedProducts;
    }

    return configuredProducts;
  }

  Future<bool> buyConsumable(ConsumableProduct product) async {
    final reachedDailyLimit = await _hasReachedDailyPurchaseLimit();
    if (reachedDailyLimit) {
      purchaseMessage.value =
          'You reached the maximum of $maxDailyConsumablePurchases consumable purchases for today.';
      return false;
    }

    final isApplePlatform = Platform.isIOS || Platform.isMacOS;
    final storeProductId = isApplePlatform
        ? (product.iosProductId?.trim() ?? '')
        : (product.googleProductId?.trim() ?? '');

    if (storeProductId.isEmpty) {
      purchaseMessage.value = isApplePlatform
          ? 'This product is not configured for the App Store.'
          : 'This product is not configured for Google Play.';
      return false;
    }

    if (!(Platform.isAndroid || isApplePlatform)) {
      purchaseMessage.value = 'Consumables are not available on this device.';
      return false;
    }

    if (!storeProducts.containsKey(storeProductId)) {
      await _syncStoreProductsForCatalog();
    }

    final productDetails = storeProducts[storeProductId];
    if (productDetails == null) {
      purchaseMessage.value = isApplePlatform
          ? 'This App Store product is not available for this build.'
          : 'This Google Play product is not available for this build.';
      return false;
    }

    if (_pendingConsumablePurchases.containsKey(storeProductId)) {
      purchaseMessage.value = 'A purchase is already in progress.';
      return false;
    }

    final completer = Completer<bool>();
    _pendingConsumablePurchases[storeProductId] = completer;
    purchaseMessage.value = '';

    try {
      final launched = await _inAppPurchase.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: productDetails),
        autoConsume: isApplePlatform,
      );
      if (!launched) {
        _pendingConsumablePurchases.remove(storeProductId);
        purchaseMessage.value = isApplePlatform
            ? 'Could not open App Store checkout.'
            : 'Could not open Google Play checkout.';
        return false;
      }

      return await completer.future.timeout(
        const Duration(minutes: 4),
        onTimeout: () {
          _pendingConsumablePurchases.remove(storeProductId);
          purchaseMessage.value = isApplePlatform
              ? 'Purchase is still processing in the App Store.'
              : 'Purchase is still processing in Google Play.';
          return false;
        },
      );
    } catch (e) {
      _pendingConsumablePurchases.remove(storeProductId);
      purchaseMessage.value = isApplePlatform
          ? 'App Store purchase failed to start.'
          : 'Google Play purchase failed to start.';
      debugPrint('[ConsumableService] buyConsumable error: $e');
      return false;
    }
  }

  Future<void> _syncStoreProductsForCatalog() async {
    try {
      final isApplePlatform = Platform.isIOS || Platform.isMacOS;
      if (!(Platform.isAndroid || isApplePlatform)) {
        storeAvailable.value = false;
        storeProducts.clear();
        return;
      }

      final ids = products
          .map(
            (product) => isApplePlatform
                ? (product.iosProductId?.trim() ?? '')
                : (product.googleProductId?.trim() ?? ''),
          )
          .where((id) => id.isNotEmpty)
          .toSet();
      if (ids.isEmpty) {
        storeProducts.clear();
        purchaseMessage.value = isApplePlatform
            ? 'No App Store product IDs were returned for consumables.'
            : 'No Google Play product IDs were returned for consumables.';
        return;
      }

      final available = await _inAppPurchase.isAvailable();
      storeAvailable.value = available;
      if (!available) {
        storeProducts.clear();
        purchaseMessage.value = isApplePlatform
            ? 'App Store purchases are unavailable.'
            : 'Google Play Billing is unavailable.';
        return;
      }

      final response = await _inAppPurchase.queryProductDetails(ids);
      if (response.error != null) {
        purchaseMessage.value =
            response.error?.message ??
            (isApplePlatform
                ? 'Could not load App Store products.'
                : 'Could not load Google Play products.');
        debugPrint(
          '[ConsumableService] queryProductDetails error: ${response.error}',
        );
      }
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
          '[ConsumableService] store products not found: ${response.notFoundIDs.join(', ')}',
        );
        if (isApplePlatform && response.productDetails.isEmpty) {
          purchaseMessage.value =
              'App Store did not return these products: ${response.notFoundIDs.join(', ')}';
        }
      }

      storeProducts.assignAll({
        for (final product in response.productDetails) product.id: product,
      });
    } catch (e) {
      storeProducts.clear();
      debugPrint('[ConsumableService] _syncStoreProductsForCatalog error: $e');
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final isApplePlatform = Platform.isIOS || Platform.isMacOS;
      final isKnownConsumable =
          storeProducts.containsKey(purchase.productID) ||
          products.any((product) {
            final expectedId = isApplePlatform
                ? product.iosProductId?.trim()
                : product.googleProductId?.trim();
            return expectedId == purchase.productID;
          });
      if (!isKnownConsumable) {
        // Subscriptions and any other non-pack products are handled by the
        // dedicated subscription billing services. The consumables stream must
        // never try to verify or consume them against pack APIs.
        debugPrint(
          '[ConsumableService] ignoring non-consumable purchase update for ${purchase.productID}',
        );
        continue;
      }
      final isActive = _pendingConsumablePurchases.containsKey(
        purchase.productID,
      );
      final shouldSurfaceErrors = isActive || _shouldSurfaceRestoreErrors;

      if (purchase.status == PurchaseStatus.pending) {
        if (isActive) {
          purchaseMessage.value = isApplePlatform
              ? 'Purchase is pending in the App Store.'
              : 'Purchase is pending in Google Play.';
        }
        continue;
      }

      if (purchase.status == PurchaseStatus.error ||
          purchase.status == PurchaseStatus.canceled) {
        if (isActive) {
          purchaseMessage.value =
              purchase.error?.message ??
              (isApplePlatform
                  ? 'App Store purchase was not completed.'
                  : 'Google Play purchase was not completed.');
        }
        await _completePurchaseIfNeeded(purchase);
        _completePendingPurchase(purchase.productID, false);
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Always verify + consume + complete, even for orphan purchases
        // delivered by `restorePurchases()` on startup. If we don't, Google
        // Play keeps returning ITEM_ALREADY_OWNED on subsequent buys and
        // the user can never purchase this consumable again.
        final token = purchase.verificationData.serverVerificationData.trim();
        if (token.isEmpty) {
          if (shouldSurfaceErrors) {
            purchaseMessage.value = isApplePlatform
                ? 'The App Store did not return a receipt.'
                : 'Google Play did not return a purchase token.';
          }
          if (Platform.isAndroid) {
            await _consumeAndroidPurchase(purchase);
          }
          await _completePurchaseIfNeeded(purchase);
          _completePendingPurchase(purchase.productID, false);
          continue;
        }

        final verification = isApplePlatform
            ? await _verifyApplePurchase(
                productId: purchase.productID,
                receiptData: token,
                transactionId: purchase.purchaseID,
                transactionDate: purchase.transactionDate,
                surfaceErrors: shouldSurfaceErrors,
              )
            : await _verifyGooglePlayPurchase(
                productId: purchase.productID,
                purchaseToken: token,
                orderId: purchase.purchaseID,
                transactionDate: purchase.transactionDate,
                surfaceErrors: shouldSurfaceErrors,
              );

        // Retryable verification failures stay pending so the purchase can be
        // restored and verified later instead of being burned locally.
        // credited the balance; if it failed permanently (bad token, duplicate,
        // banned), the purchase is dead anyway — leaving it un-consumed would
        // only block the user from buying again with no possible recovery.
        if (verification.isVerified) {
          if (Platform.isAndroid) {
            await _consumeAndroidPurchase(purchase);
          }
          await _completePurchaseIfNeeded(purchase);
          if (shouldSurfaceErrors) purchaseMessage.value = '';
          _completePendingPurchase(purchase.productID, true);
          continue;
        }

        if (verification.isRetryable) {
          if (shouldSurfaceErrors && purchaseMessage.value.trim().isEmpty) {
            purchaseMessage.value =
                'Purchase verification is temporarily unavailable. Please wait a moment and try again.';
          }
          _completePendingPurchase(purchase.productID, false);
          continue;
        }

        if (Platform.isAndroid) {
          await _consumeAndroidPurchase(purchase);
        }
        await _completePurchaseIfNeeded(purchase);
        if (shouldSurfaceErrors && purchaseMessage.value.trim().isEmpty) {
          purchaseMessage.value =
              'Purchase could not be verified. Your balance was not changed.';
        }
        _completePendingPurchase(purchase.productID, false);
      }
    }
  }

  Future<void> _consumeAndroidPurchase(PurchaseDetails purchase) async {
    if (!Platform.isAndroid) return;

    try {
      final androidAddition = _inAppPurchase
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      await androidAddition.consumePurchase(purchase);
    } catch (e) {
      debugPrint('[ConsumableService] consumePurchase warning: $e');
    }
  }

  Future<void> _completePurchaseIfNeeded(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) return;

    try {
      await _inAppPurchase.completePurchase(purchase);
    } catch (e) {
      debugPrint('[ConsumableService] completePurchase warning: $e');
    }
  }

  void _completePendingPurchase(String productId, bool success) {
    final completer = _pendingConsumablePurchases.remove(productId);
    if (completer != null && !completer.isCompleted) {
      completer.complete(success);
    }
  }

  void _completePendingPurchases(bool success) {
    final productIds = _pendingConsumablePurchases.keys.toList(growable: false);
    for (final productId in productIds) {
      _completePendingPurchase(productId, success);
    }
  }

  // ─── Fetch purchase history ───────────────────────────────
  Future<List<Map<String, dynamic>>> fetchPurchaseHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.get(
        ApiConstants.consumablePurchaseHistory,
        queryParameters: {'page': page, 'limit': limit},
      );
      final root = _extractRootMap(response.data);
      final items = _extractList(
        response.data,
        root: root,
        keys: const ['items', 'purchases', 'results', 'data'],
      );
      return items
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    } catch (e) {
      debugPrint('[ConsumableService] fetchPurchaseHistory error: $e');
      return [];
    }
  }

  // ─── Get products filtered by type ────────────────────────
  List<ConsumableProduct> getProductsByType(String type) {
    final normalizedType = _normalizeProductType(type);
    return products
        .where((p) => _normalizeProductType(p.type) == normalizedType)
        .toList(growable: false);
  }

  String _normalizeProductType(String raw) {
    final token = raw.trim().toLowerCase();
    switch (token) {
      case 'likes':
      case 'like':
      case 'likes_pack':
      case 'like_pack':
        return 'likes_pack';
      case 'compliments':
      case 'compliment':
      case 'compliments_pack':
      case 'compliment_pack':
        return 'compliments_pack';
      case 'boosts':
      case 'boost':
      case 'boosts_pack':
      case 'boost_pack':
        return 'boosts_pack';
      default:
        return token;
    }
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

  Map<String, dynamic> _extractRootMap(dynamic raw) {
    final map = _asMap(raw);
    final nested = _asMap(map['data']);
    if (nested.isNotEmpty) {
      return nested;
    }
    return map;
  }

  List<dynamic> _extractList(
    dynamic raw, {
    Map<String, dynamic>? root,
    List<String> keys = const ['items', 'products', 'results', 'data'],
  }) {
    if (raw is List) {
      return raw;
    }

    final map = _asMap(raw);
    final rawDataList = map['data'];
    if (rawDataList is List) {
      return rawDataList;
    }

    final source = root ?? _extractRootMap(raw);
    for (final key in keys) {
      final value = source[key];
      if (value is List) {
        return value;
      }
    }

    return const <dynamic>[];
  }

  bool _isRetryableVerificationFailure(int statusCode, String? reason) {
    if (statusCode >= 500) {
      return true;
    }

    if (reason == null || reason.isEmpty) {
      return false;
    }

    return const {
      'google_play_api_access_or_service_account',
      'package_product_or_token_not_found',
      'google_play_api_unavailable',
    }.contains(reason);
  }

  bool _isDailyPurchaseLimitMessage(String message) {
    final normalized = message.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }

    return normalized.contains('daily') &&
        normalized.contains('limit') &&
        normalized.contains('purchase');
  }

  Future<bool> _hasReachedDailyPurchaseLimit() async {
    try {
      final purchases = await fetchPurchaseHistory(
        page: 1,
        limit: maxDailyConsumablePurchases * 2,
      );
      final now = DateTime.now();

      final countToday = purchases.where((purchase) {
        final createdAtRaw =
            purchase['createdAt'] ??
            purchase['transactionDate'] ??
            purchase['date'];
        if (createdAtRaw == null) {
          return false;
        }

        final parsed = DateTime.tryParse(createdAtRaw.toString());
        if (parsed == null) {
          return false;
        }

        final local = parsed.toLocal();
        return local.year == now.year &&
            local.month == now.month &&
            local.day == now.day;
      }).length;

      return countToday >= maxDailyConsumablePurchases;
    } catch (_) {
      return false;
    }
  }

  bool get _shouldSurfaceRestoreErrors {
    final until = _surfaceRestoreVerificationErrorsUntil;
    if (until == null) {
      return false;
    }
    if (DateTime.now().isAfter(until)) {
      _surfaceRestoreVerificationErrorsUntil = null;
      return false;
    }
    return true;
  }

  List<ConsumableProduct> get likesPacks => getProductsByType('likes_pack');
  List<ConsumableProduct> get visibleLikesPacks =>
      visibleProductsByType('likes_pack');
  List<ConsumableProduct> get complimentsPacks =>
      getProductsByType('compliments_pack');
  List<ConsumableProduct> get visibleComplimentsPacks =>
      visibleProductsByType('compliments_pack');
  List<ConsumableProduct> get boostsPacks => getProductsByType('boosts_pack');
  List<ConsumableProduct> get visibleBoostsPacks =>
      visibleProductsByType('boosts_pack');
}
