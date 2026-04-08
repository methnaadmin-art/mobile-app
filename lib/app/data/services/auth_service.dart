import 'dart:async';
import 'package:dio/dio.dart';
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
      data: {
        'identifier': email,
        'email': email,
        'password': password,
      },
    );

    try {
      final data = response.data;
      debugPrint('[AuthService] Login response type: ${data.runtimeType}');
      debugPrint('[AuthService] Login response data: $data');

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
    required String idToken,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    final response = await _api.post(
      ApiConstants.googleSignIn,
      data: {
        'idToken': idToken,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
      },
    );

    final data = response.data;
    debugPrint('[AuthService] Google sign-in response data: $data');

    if (data == null) {
      throw Exception('Google sign-in response is null');
    }

    final accessToken = data['accessToken'];
    final refreshToken = data['refreshToken'];
    final userData = data['user'];

    if (accessToken == null) {
      throw Exception('No access token in Google sign-in response');
    }

    await _storage.saveToken(accessToken);
    if (refreshToken != null) {
      await _storage.saveRefreshToken(refreshToken);
    }
    await _storage.saveAuthProvider('google');

    if (userData == null) {
      throw Exception('No user data in Google sign-in response');
    }

    final user = UserModel.fromJson(userData);
    currentUser.value = user;
    await _storage.saveUser(userData);
    isLoggedIn.value = true;
    sessionRestorePending.value = false;

    // Hydrate user data to ensure all nested fields are synced
    try {
      await fetchMe();
    } catch (e) {
      debugPrint('[AuthService] Google sign-in hydration failed: $e');
    }

    scheduleAuthenticatedServicesBootstrap(force: true);
    return currentUser.value!;
  }

  // ─── Register ──────────────────────────────────────────────
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
    String? username,
    String? phone,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
      'firstName': firstName,
      'lastName': lastName,
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

        // Start 3-day free trial for new users
        try {
          final trialManager = Get.find<TrialManager>();
          trialManager.startTrial();
          debugPrint('[AuthService] Trial started for new user');
        } catch (e) {
          debugPrint('[AuthService] Failed to start trial: $e');
        }

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
    final user = UserModel.fromJson(payload);
    currentUser.value = user;
    await _storage.saveUser(payload);
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

  // ─── Logout ────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      Get.find<SocketService>().disconnect();
    } catch (_) {}
    try {
      await _api.post(ApiConstants.logout);
    } catch (_) {}
    currentUser.value = null;
    isLoggedIn.value = false;
    sessionRestorePending.value = false;
    _bootstrapScheduled = false;
    await _storage.clearAll();
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
    final restored = await tryRestoreSession();

    if (!restored) {
      if (Get.currentRoute != AppRoutes.login) {
        Get.offAllNamed(AppRoutes.login);
      }
      return;
    }

    final user = currentUser.value;
    if (user == null) return;

    final draftRoute = _storage.getSignupDraftRoute();
    final resolvedRoute = resolvePostAuthRoute(user, draftRoute: draftRoute);
    if (Get.currentRoute != resolvedRoute) {
      Get.offAllNamed(resolvedRoute);
    }
  }

  void scheduleAuthenticatedServicesBootstrap({bool force = false}) {
    if (_bootstrapScheduled) return;
    _bootstrapScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 700), () async {
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

      Future.delayed(const Duration(milliseconds: 250), () {
        socketService.connect();
      });

      unawaited(
        Future.delayed(const Duration(milliseconds: 900), () async {
          await notificationService.init();
          notificationService.fetchNotifications();
          notificationService.fetchUnreadCount();
        }),
      );

      unawaited(
        Future.delayed(const Duration(milliseconds: 1200), () async {
          await trialManager.init();
          await Future.wait([
            monetizationService.fetchStatus(),
            monetizationService.fetchAllLimits(),
            monetizationService.fetchFeatures(),
            monetizationService.fetchActivePlans(),
            subscriptionService.fetchMySubscription(),
          ]);
        }),
      );
    } catch (_) {}
  }

  String? get userId => currentUser.value?.id;
}
