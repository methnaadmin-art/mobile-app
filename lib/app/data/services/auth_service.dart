import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/data/services/storage_service.dart';
import 'package:methna_app/app/data/services/socket_service.dart';
import 'package:methna_app/app/data/services/notification_service.dart';
import 'package:methna_app/app/data/services/message_queue_service.dart';
import 'package:methna_app/app/data/services/connectivity_service.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:methna_app/app/data/services/subscription_service.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/utils/auth_navigation_resolver.dart';
import 'package:methna_app/core/services/trial_manager.dart';

class AuthService extends GetxService {
  final ApiService _api = Get.find<ApiService>();
  final StorageService _storage = Get.find<StorageService>();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoggedIn = false.obs;
  final RxBool isLoggingOut = false.obs;
  final RxBool sessionRestorePending = false.obs;
  bool _bootstrapScheduled = false;

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Map<String, dynamic> _extractUserPayload(dynamic raw) {
    final root = _asMap(raw);
    if (root.isEmpty) return root;

    final candidateMaps = <Map<String, dynamic>>[
      root,
      _asMap(root['user']),
      _asMap(root['data']),
      _asMap(_asMap(root['data'])['user']),
      _asMap(root['result']),
      _asMap(_asMap(root['result'])['user']),
    ];

    for (final candidate in candidateMaps) {
      if (candidate.isEmpty) continue;
      final hasIdentity =
          candidate['id'] != null ||
          candidate['_id'] != null ||
          candidate['userId'] != null ||
          candidate['email'] != null;
      if (hasIdentity) {
        return candidate;
      }
    }

    return root;
  }

  String? _firstNonEmptyString(Iterable<dynamic> values) {
    for (final value in values) {
      final normalized = value?.toString().trim() ?? '';
      if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
        return normalized;
      }
    }
    return null;
  }

  String? _extractAccessToken(dynamic raw) {
    final root = _asMap(raw);
    final data = _asMap(root['data']);
    final result = _asMap(root['result']);
    final tokens = _asMap(root['tokens']);
    final dataTokens = _asMap(data['tokens']);
    final resultTokens = _asMap(result['tokens']);

    return _firstNonEmptyString([
      root['accessToken'],
      root['access_token'],
      root['authToken'],
      root['token'],
      data['accessToken'],
      data['access_token'],
      data['authToken'],
      data['token'],
      result['accessToken'],
      result['access_token'],
      result['authToken'],
      result['token'],
      tokens['accessToken'],
      tokens['access_token'],
      tokens['token'],
      dataTokens['accessToken'],
      dataTokens['access_token'],
      dataTokens['token'],
      resultTokens['accessToken'],
      resultTokens['access_token'],
      resultTokens['token'],
    ]);
  }

  String? _extractRefreshToken(dynamic raw) {
    final root = _asMap(raw);
    final data = _asMap(root['data']);
    final result = _asMap(root['result']);
    final tokens = _asMap(root['tokens']);
    final dataTokens = _asMap(data['tokens']);
    final resultTokens = _asMap(result['tokens']);

    return _firstNonEmptyString([
      root['refreshToken'],
      root['refresh_token'],
      data['refreshToken'],
      data['refresh_token'],
      result['refreshToken'],
      result['refresh_token'],
      tokens['refreshToken'],
      tokens['refresh_token'],
      dataTokens['refreshToken'],
      dataTokens['refresh_token'],
      resultTokens['refreshToken'],
      resultTokens['refresh_token'],
    ]);
  }

  void markSessionRestorePending() {
    sessionRestorePending.value = true;
  }

  UserModel? hydrateCachedSession() {
    final cachedUser = _storage.getUser();
    if (cachedUser == null) return null;

    try {
      final user = UserModel.fromJson(cachedUser);
      currentUser.value = user;
      isLoggedIn.value = true;
      debugPrint('[AuthService] Hydrated user from cache for fast startup');
      return user;
    } catch (e) {
      debugPrint('[AuthService] Failed to hydrate cached user: $e');
      return null;
    }
  }

  // ─── Login ─────────────────────────────────────────────────
  Future<UserModel> login(String email, String password) async {
    // Let DioExceptions propagate naturally for proper error display
    final response = await _api.post(
      ApiConstants.login,
      data: {'identifier': email, 'email': email, 'password': password},
    );

    try {
      final data = response.data;
      if (kDebugMode) {
        debugPrint('[AuthService] Login response type: ${data.runtimeType}');
        debugPrint('[AuthService] Login response data: $data');
      }

      if (data == null) {
        throw Exception('Login response is null');
      }

      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];
      final userData = data['user'];

      debugPrint('[AuthService] accessToken present: ${accessToken != null}');
      debugPrint('[AuthService] userData present: ${userData != null}');

      if (accessToken == null) {
        throw Exception(
          'No access token in response. Keys: ${data is Map ? data.keys.toList() : 'not a map'}',
        );
      }

      await _storage.saveToken(accessToken);
      if (refreshToken != null) {
        await _storage.saveRefreshToken(refreshToken);
      }
      await _storage.saveAuthProvider('email');

      if (userData == null) {
        throw Exception(
          'No user data in response. Keys: ${data is Map ? data.keys.toList() : 'not a map'}',
        );
      }

      final user = UserModel.fromJson(userData);
      currentUser.value = user;
      await _storage.saveUser(userData);
      isLoggedIn.value = true;
      sessionRestorePending.value = false;

      // Immediately apply authoritative subscription state from server so
      // premium status is correct before any UI renders. This prevents stale
      // premium state leaking between accounts on the same device.
      _applySubscriptionFromResponse(data);

      // Hydrate user data to ensure all nested fields are synced
      try {
        await fetchMe();
      } catch (e) {
        debugPrint('[AuthService] Login hydration failed: $e');
      }

      scheduleAuthenticatedServicesBootstrap(force: true);
      return currentUser.value!;
    } catch (e) {
      debugPrint('[AuthService] Login post-response error: $e');
      rethrow;
    }
  }

  // ─── Google Sign-In ─────────────────────────────────────────
  Future<UserModel> googleSignIn({
    String? idToken,
    String? accessToken,
    String? serverAuthCode,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    final normalizedIdToken = idToken?.trim();
    final normalizedAccessToken = accessToken?.trim();
    final normalizedAuthCode = serverAuthCode?.trim();

    if ((normalizedIdToken == null || normalizedIdToken.isEmpty) &&
        (normalizedAuthCode == null || normalizedAuthCode.isEmpty)) {
      throw Exception('Google credentials missing (idToken/auth code).');
    }

    final response = await _api.post(
      ApiConstants.googleSignIn,
      data: {
        if (normalizedIdToken != null && normalizedIdToken.isNotEmpty)
          'idToken': normalizedIdToken,
        if (normalizedAccessToken != null && normalizedAccessToken.isNotEmpty)
          'accessToken': normalizedAccessToken,
        if (normalizedAuthCode != null && normalizedAuthCode.isNotEmpty)
          'serverAuthCode': normalizedAuthCode,
        if (normalizedAuthCode != null && normalizedAuthCode.isNotEmpty)
          'authCode': normalizedAuthCode,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
      },
    );

    final rawData = response.data;
    if (kDebugMode) debugPrint('[AuthService] Google sign-in response data: $rawData');

    if (rawData == null) {
      throw Exception('Google sign-in response is null');
    }

    final accessTokenValue = _extractAccessToken(rawData);
    final refreshTokenValue = _extractRefreshToken(rawData);
    final userData = _extractUserPayload(rawData);

    if (accessTokenValue == null || accessTokenValue.isEmpty) {
      throw Exception('No access token in Google sign-in response');
    }

    await _storage.saveToken(accessTokenValue);
    if (refreshTokenValue != null && refreshTokenValue.isNotEmpty) {
      await _storage.saveRefreshToken(refreshTokenValue);
    }
    await _storage.saveAuthProvider('google');

    UserModel? user;
    if (userData.isNotEmpty) {
      try {
        user = UserModel.fromJson(userData);
        currentUser.value = user;
        await _storage.saveUser(userData);
      } catch (e) {
        debugPrint('[AuthService] Google user parse fallback to fetchMe: $e');
      }
    }

    isLoggedIn.value = true;
    sessionRestorePending.value = false;

    // Immediately apply authoritative subscription state from server
    _applySubscriptionFromResponse(rawData);

    // Hydrate user data to ensure all nested fields are synced
    try {
      user = await fetchMe();
    } catch (e) {
      debugPrint('[AuthService] Google sign-in hydration failed: $e');
    }

    final resolvedUser = user ?? currentUser.value;
    if (resolvedUser == null) {
      throw Exception('Google sign-in succeeded but user profile is missing.');
    }

    scheduleAuthenticatedServicesBootstrap(force: true);
    return resolvedUser;
  }

  Future<UserModel> appleSignIn({
    required String identityToken,
    required String authorizationCode,
    String? userIdentifier,
    String? email,
    String? firstName,
    String? lastName,
    String? displayName,
  }) async {
    final normalizedIdentityToken = identityToken.trim();
    final normalizedAuthorizationCode = authorizationCode.trim();

    if (normalizedIdentityToken.isEmpty ||
        normalizedAuthorizationCode.isEmpty) {
      throw Exception('Apple credentials missing.');
    }

    final response = await _api.post(
      ApiConstants.appleSignIn,
      data: {
        'identityToken': normalizedIdentityToken,
        'authorizationCode': normalizedAuthorizationCode,
        if (userIdentifier != null && userIdentifier.trim().isNotEmpty)
          'userIdentifier': userIdentifier.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (firstName != null && firstName.trim().isNotEmpty)
          'firstName': firstName.trim(),
        if (lastName != null && lastName.trim().isNotEmpty)
          'lastName': lastName.trim(),
        if (displayName != null && displayName.trim().isNotEmpty)
          'displayName': displayName.trim(),
      },
    );

    final rawData = response.data;
    if (kDebugMode) debugPrint('[AuthService] Apple sign-in response data: $rawData');

    if (rawData == null) {
      throw Exception('Apple sign-in response is null');
    }

    final accessTokenValue = _extractAccessToken(rawData);
    final refreshTokenValue = _extractRefreshToken(rawData);
    final userData = _extractUserPayload(rawData);

    if (accessTokenValue == null || accessTokenValue.isEmpty) {
      throw Exception('No access token in Apple sign-in response');
    }

    await _storage.saveToken(accessTokenValue);
    if (refreshTokenValue != null && refreshTokenValue.isNotEmpty) {
      await _storage.saveRefreshToken(refreshTokenValue);
    }
    await _storage.saveAuthProvider('apple');

    UserModel? user;
    if (userData.isNotEmpty) {
      try {
        user = UserModel.fromJson(userData);
        currentUser.value = user;
        await _storage.saveUser(userData);
      } catch (e) {
        debugPrint('[AuthService] Apple user parse fallback to fetchMe: $e');
      }
    }

    isLoggedIn.value = true;
    sessionRestorePending.value = false;
    _applySubscriptionFromResponse(rawData);

    try {
      user = await fetchMe();
    } catch (e) {
      debugPrint('[AuthService] Apple sign-in hydration failed: $e');
    }

    final resolvedUser = user ?? currentUser.value;
    if (resolvedUser == null) {
      throw Exception('Apple sign-in succeeded but user profile is missing.');
    }

    scheduleAuthenticatedServicesBootstrap(force: true);
    return resolvedUser;
  }

  // ─── Register ──────────────────────────────────────────────
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    required bool agreeToTerms,
    required bool agreeToPrivacyPolicy,
    required bool oathAccepted,
    String? username,
    String? phone,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
      'firstName': firstName,
      'lastName': lastName,
      'agreeToTerms': agreeToTerms,
      'agreeToPrivacyPolicy': agreeToPrivacyPolicy,
      'oathAccepted': oathAccepted,
    };
    if (username != null && username.isNotEmpty) body['username'] = username;
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;

    final response = await _api.post(ApiConstants.register, data: body);
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
  }

  // ─── Forgot Password ──────────────────────────────────────
  Future<void> forgotPassword(String email) async {
    await _api.post(ApiConstants.forgotPassword, data: {'email': email});
  }

  // ─── Verify OTP (email verification after register) ────────
  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final response = await _api.post(
      ApiConstants.verifyOtp,
      data: {'email': email, 'otp': otp},
    );
    final data = response.data;
    // After successful OTP, backend returns tokens
    if (data['accessToken'] != null) {
      await _storage.saveToken(data['accessToken']);
      if (data['refreshToken'] != null) {
        await _storage.saveRefreshToken(data['refreshToken']);
      }
      await _storage.saveAuthProvider('email');
      if (data['user'] != null) {
        final user = UserModel.fromJson(data['user']);
        currentUser.value = user;
        await _storage.saveUser(data['user']);
        isLoggedIn.value = true;
        sessionRestorePending.value = false;

        // Hydrate user data to ensure all nested fields are synced
        try {
          await fetchMe();
        } catch (e) {
          debugPrint('[AuthService] OTP hydration failed: $e');
        }

        scheduleAuthenticatedServicesBootstrap(force: true);
      }
    }
    return data;
  }

  // ─── Resend OTP ────────────────────────────────────────────
  Future<void> resendOtp(String email) async {
    await _api.post(ApiConstants.resendOtp, data: {'email': email});
  }

  // ─── Verify Reset OTP ──────────────────────────────────────
  Future<Map<String, dynamic>> verifyResetOtp(String email, String otp) async {
    final response = await _api.post(
      ApiConstants.verifyResetOtp,
      data: {'email': email, 'otp': otp},
    );
    return response.data;
  }

  // ─── Reset Password ───────────────────────────────────────
  Future<void> resetPassword(
    String email,
    String otpCode,
    String newPassword,
  ) async {
    await _api.post(
      ApiConstants.resetPassword,
      data: {'email': email, 'otp': otpCode, 'newPassword': newPassword},
    );
  }

  // ─── Get Current User ─────────────────────────────────────
  Future<UserModel> fetchMe() async {
    final response = await _api.get(ApiConstants.usersMe);
    final payload = _extractUserPayload(response.data);
    final previousUser = currentUser.value;
    final user = UserModel.fromJson(payload);
    final selfieVerificationChanged =
        previousUser?.id == user.id &&
        previousUser?.selfieVerified != user.selfieVerified;
    currentUser.value = user;
    await _storage.saveUser(payload);
    if (selfieVerificationChanged) {
      debugPrint(
        '[AuthService] Viewer selfie verification changed; clearing cached discovery deck.',
      );
      await _storage.clearDiscoverCache();
    }
    return user;
  }

  // ─── Check Username Availability ──────────────────────────
  Future<bool> checkUsernameAvailability(String username) async {
    try {
      final response = await _api.get(
        ApiConstants.checkUsername,
        queryParameters: {'username': username},
      );
      return response.data['available'] == true;
    } catch (_) {
      return false;
    }
  }

  // ─── Apply subscription state from login response ────────
  void _applySubscriptionFromResponse(dynamic responseData) {
    try {
      final root = _asMap(responseData);
      final sub = _asMap(root['subscription']);
      if (sub.isEmpty) {
        debugPrint(
          '[AuthService] No subscription in login response — skipping',
        );
        return;
      }

      // Reset both services first so no stale state remains from a previous
      // account on the same device.
      if (Get.isRegistered<MonetizationService>()) {
        Get.find<MonetizationService>().resetForLogout();
      }
      if (Get.isRegistered<SubscriptionService>()) {
        final subscriptionService = Get.find<SubscriptionService>();
        subscriptionService.resetForLogout();
        subscriptionService.applyFromLoginResponse(sub);
      }

      if (kDebugMode) {
        debugPrint(
          '[AuthService] Applied subscription from login response: $sub',
        );
      }
    } catch (e) {
      debugPrint('[AuthService] _applySubscriptionFromResponse error: $e');
    }
  }

  // ─── Logout ────────────────────────────────────────────────
  Future<void> logout() async {
    if (isLoggingOut.value) return;

    isLoggingOut.value = true;
    isLoggedIn.value = false;
    sessionRestorePending.value = false;
    _bootstrapScheduled = false;

    try {
      Get.find<SocketService>().disconnect();
    } catch (_) {}

    try {
      await _api.post(ApiConstants.logout);
    } catch (_) {}

    try {
      // Reset all premium/subscription state BEFORE clearing storage so the
      // in-memory reactive flags (isPremium, hasActiveEntitlement, currentPlan
      // etc.) can never survive a logout. Otherwise a re-login as a different
      // user would still show premium features from the previous session.
      try {
        if (Get.isRegistered<MonetizationService>()) {
          await Get.find<MonetizationService>().resetForLogout();
        }
      } catch (e) {
        debugPrint(
          '[AuthService] MonetizationService.resetForLogout failed: $e',
        );
      }
      try {
        if (Get.isRegistered<SubscriptionService>()) {
          Get.find<SubscriptionService>().resetForLogout();
        }
      } catch (e) {
        debugPrint(
          '[AuthService] SubscriptionService.resetForLogout failed: $e',
        );
      }
      try {
        if (Get.isRegistered<TrialManager>()) {
          Get.find<TrialManager>().resetForLogout();
        }
      } catch (e) {
        debugPrint('[AuthService] TrialManager.resetForLogout failed: $e');
      }

      currentUser.value = null;
      await _storage.clearAll();
    } finally {
      isLoggingOut.value = false;
    }
  }

  // ─── Restore Session ──────────────────────────────────────
  Future<bool> tryRestoreSession() async {
    sessionRestorePending.value = true;
    final token = await _storage.getToken();
    if (token == null) {
      sessionRestorePending.value = false;
      return false;
    }

    // Instantly hydrate from local cache so UI has data while we fetch
    hydrateCachedSession();

    try {
      debugPrint('[AuthService] Restoring session via fetchMe...');
      await fetchMe();
      isLoggedIn.value = true;
      scheduleAuthenticatedServicesBootstrap();
      return true;
    } catch (e) {
      debugPrint('[AuthService] Session restoration failed: $e');
      // If it's a 401, the ApiService already tried to refresh.
      // If it's still failing, the session is dead.
      if (e is DioException && e.response?.statusCode == 401) {
        await _storage.clearTokens();
        currentUser.value = null;
        isLoggedIn.value = false;
        sessionRestorePending.value = false;
        return false;
      }
      // For non-401 errors (e.g. network), keep cached user and allow entry
      if (currentUser.value != null) {
        scheduleAuthenticatedServicesBootstrap();
        sessionRestorePending.value = false;
        return true;
      }
      sessionRestorePending.value = false;
      return false;
    } finally {
      sessionRestorePending.value = false;
    }
  }

  Future<void> restoreSessionAfterLaunch() async {
    try {
      final restored = await tryRestoreSession();

      if (!restored) {
        if (Get.currentRoute != AppRoutes.login &&
            Get.currentRoute != AppRoutes.onboarding) {
          Get.offAllNamed(AppRoutes.login);
        }
        return;
      }

      final user = currentUser.value;
      if (user == null) return;

      final draftRoute = _storage.getSignupDraftRoute();
      final target = resolvePostAuthNavigation(user, draftRoute: draftRoute);
      if (Get.currentRoute != target.route) {
        Get.offAllNamed(target.route, arguments: target.arguments);
      }
    } catch (e) {
      debugPrint('[AuthService] restoreSessionAfterLaunch error: $e');
      // Don't leave user stuck — fallback to login
      if (Get.currentRoute == AppRoutes.splash || Get.currentRoute.isEmpty) {
        Get.offAllNamed(AppRoutes.login);
      }
    }
  }

  void scheduleAuthenticatedServicesBootstrap({bool force = false}) {
    if (_bootstrapScheduled) return;
    _bootstrapScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Shortened from 700ms so subscription state is restored ASAP on
      // app restart (fixes premium-disappears-after-restart flicker).
      Future.delayed(const Duration(milliseconds: 100), () async {
        try {
          await bootstrapAuthenticatedServices(force: force);
        } finally {
          _bootstrapScheduled = false;
        }
      });
    });
  }

  // ─── Post-auth setup: socket, notifications, monetization ──
  Future<void> bootstrapAuthenticatedServices({bool force = false}) async {
    final route = Get.currentRoute;
    if (!force && (route.contains('signup') || route == AppRoutes.splash)) {
      debugPrint(
        '[AuthService] Deferring background services - currently in signup/splash',
      );
      return;
    }

    try {
      final socketService = Get.find<SocketService>();
      final messageQueueService = Get.find<MessageQueueService>();
      final connectivityService = Get.find<ConnectivityService>();
      final notificationService = Get.find<NotificationService>();
      final monetizationService = Get.find<MonetizationService>();
      final subscriptionService = Get.find<SubscriptionService>();
      final trialManager = Get.find<TrialManager>();

      await socketService.init();
      await messageQueueService.init();
      await connectivityService.init();

      // CRITICAL: Restore subscription/premium state IMMEDIATELY (no delay).
      // Previously this was inside Future.delayed(1200ms) + unawaited, which
      // caused a visible window where currentPlan='free' and isPremium=false
      // on app restart — making premium UI flicker to the free state. The
      // subscription fetch MUST win the race against any first render that
      // checks isPremium.
      unawaited(
        Future.wait([
          monetizationService.fetchStatus(),
          monetizationService.fetchEntitlements(),
          subscriptionService.fetchMySubscription(),
        ]).catchError((e) {
          debugPrint('[AuthService] subscription restore error: $e');
          return <dynamic>[];
        }),
      );

      Future.delayed(const Duration(milliseconds: 250), () {
        socketService.connect();
      });

      unawaited(
        Future.delayed(const Duration(milliseconds: 900), () async {
          await notificationService.init();
          await notificationService.ensurePushTokenSynced(force: true);
          notificationService.fetchNotifications();
          notificationService.fetchUnreadCount();
          notificationService.processPendingLaunchNavigation();
        }),
      );

      // Non-critical background refreshes follow. Premium state has already
      // been restored above, so these can be deferred without causing the
      // subscription-disappearance bug.
      unawaited(
        Future.delayed(const Duration(milliseconds: 1200), () async {
          await trialManager.init();
          await Future.wait([
            monetizationService.fetchAllLimits(),
            monetizationService.fetchFeatures(),
            monetizationService.fetchActivePlans(),
          ]);
        }),
      );
    } catch (_) {}
  }

  String? get userId => currentUser.value?.id;
}
