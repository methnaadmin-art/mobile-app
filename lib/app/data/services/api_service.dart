import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/app/data/services/storage_service.dart';
import 'package:methna_app/app/data/services/socket_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';

class ApiService extends GetxService {
  late final Dio _dio;
  final StorageService _storage = Get.find<StorageService>();
  bool _isRedirecting = false;
  Future<bool>? _refreshFuture;
  static const Set<String> _publicAuthPaths = {
    ApiConstants.login,
    ApiConstants.register,
    ApiConstants.verifyOtp,
    ApiConstants.resendOtp,
    ApiConstants.refreshToken,
    ApiConstants.forgotPassword,
    ApiConstants.verifyResetOtp,
    ApiConstants.resetPassword,
    ApiConstants.checkUsername,
    ApiConstants.googleSignIn,
  };
  static const Duration _defaultConnectTimeout = Duration(seconds: 20);
  static const Duration _defaultReceiveTimeout = Duration(seconds: 35);
  static const Duration _defaultSendTimeout = Duration(seconds: 20);
  static const Duration _writeReceiveTimeout = Duration(seconds: 60);

  bool _isPublicAuthRequest(RequestOptions options) {
    final rawPath = options.path;
    final normalized = rawPath.contains('://')
        ? Uri.parse(rawPath).path
        : rawPath;
    return _publicAuthPaths.any(
      (publicPath) =>
          normalized == publicPath || normalized.endsWith(publicPath),
    );
  }

  Future<ApiService> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: _defaultConnectTimeout,
      receiveTimeout: _defaultReceiveTimeout,
      sendTimeout: _defaultSendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final skipAuth =
            options.extra['skip_auth'] == true || _isPublicAuthRequest(options);
        if (skipAuth) {
          options.headers.remove('Authorization');
        } else {
          final token = await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('[API RESPONSE] ${response.requestOptions.method} ${response.requestOptions.path}');
        // Unwrap the backend's { success, data } or { statusCode, data } envelope safely
        if (response.data is Map && response.data.containsKey('data') && 
           (response.data['success'] == true || response.data.containsKey('statusCode'))) {
          // Verify we aren't un-wrapping an object that happens to simply contain 'data' as a property (like a user model)
          // The envelope usually has very few keys, e.g. success/statusCode/message/timestamp.
          final keys = (response.data as Map).keys.toList();
          if (keys.length <= 5 && !keys.contains('id') && !keys.contains('email')) {
             response.data = response.data['data'];
          }
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        // Log full error details for debugging
        debugPrint('[API ERROR] ${error.requestOptions.method} ${error.requestOptions.path}');
        debugPrint('[API ERROR] Type: ${error.type}');
        debugPrint('[API ERROR] Status: ${error.response?.statusCode}');
        
        if (error.response?.statusCode == 401) {
          final requestOptions = error.requestOptions;
          final isPublicRequest = _isPublicAuthRequest(requestOptions);
          final alreadyRetried = requestOptions.extra['auth_retry'] == true;
          final skipRefresh =
              requestOptions.extra['skip_auth_refresh'] == true ||
              isPublicRequest;

          if (skipRefresh || alreadyRetried) {
            return handler.next(error);
          }

          // If we're on the login page, don't try to refresh — just forward the error
          final currentRoute = Get.currentRoute;
          if (currentRoute == AppRoutes.login) {
            return handler.next(error);
          }

          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            final opts = error.requestOptions;
            final token = await _storage.getToken();
            opts.headers['Authorization'] = 'Bearer $token';
            opts.extra['auth_retry'] = true;
            try {
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          } else {
            // Refresh failed or no refresh token
            final route = Get.currentRoute;
            final inTransition = route.contains('signup');
            
            if (!inTransition) {
              await _storage.clearAll();
              if (!_isRedirecting && route != AppRoutes.login) {
                _isRedirecting = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (Get.context != null && Get.currentRoute != AppRoutes.login) {
                    debugPrint('[API 401] Redirecting to login...');
                    Get.offAllNamed(AppRoutes.login);
                  }
                  Future.delayed(const Duration(seconds: 2), () => _isRedirecting = false);
                });
              }
            } else {
              debugPrint('[API 401] Token expired during signup and refresh failed.');
            }
            // Always forward the error so callers can handle it
            return handler.next(error);
          }
        }

        // 2. Handle Network Retries (Connection issues)
        if (_shouldRetry(error) && _isRetryableRequest(error.requestOptions)) {
          final route = Get.currentRoute;
          if (route.contains('signup') || route == AppRoutes.splash) {
             return handler.next(error); // Critical: Don't retry during signup/splash to avoid event loop congestion
          }

          final retryCount = error.requestOptions.extra['retry_count'] ?? 0;
          if (retryCount < 1) {
            final nextRetry = retryCount + 1;
            error.requestOptions.extra['retry_count'] = nextRetry;
            
            // Exponential backoff: 1s, 4s
            final delay = Duration(seconds: nextRetry * nextRetry);
            debugPrint('[API RETRY] Attempt $nextRetry in ${delay.inSeconds}s...');

            try {
              await Future.delayed(delay);
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } on DioException catch (retryError) {
              return handler.next(retryError);
            } catch (_) {
              return handler.next(error);
            }
          }
        }

        return handler.next(error);
      },
    ));

    return this;
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionError ||
           error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.sendTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           (error.error != null && error.error.toString().contains('SocketException'));
  }

  bool _isRetryableRequest(RequestOptions options) {
    if (options.extra['disable_retry'] == true) {
      return false;
    }
    final method = options.method.toUpperCase();
    return method == 'GET' || method == 'HEAD' || method == 'OPTIONS';
  }

  Future<bool> _tryRefreshToken() {
    if (_refreshFuture != null) return _refreshFuture!;

    final completer = Completer<bool>();
    _refreshFuture = completer.future;

    () async {
      bool success = false;
      try {
        final refreshToken = await _storage.getRefreshToken();
        if (refreshToken == null) {
          success = false;
          return;
        }

        // Use a dedicated Dio instance for refresh to avoid interceptor recursion/loops
        final refreshDio = Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: _defaultConnectTimeout,
          receiveTimeout: _defaultReceiveTimeout,
          sendTimeout: _defaultSendTimeout,
        ));

        debugPrint('[API REFRESH] Attempting token renewal...');
        final response = await refreshDio.post(
          ApiConstants.refreshToken,
          data: {'refreshToken': refreshToken},
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data is Map && response.data.containsKey('data')
              ? response.data['data']
              : response.data;

          await _storage.saveToken(data['accessToken']);
          if (data['refreshToken'] != null) {
            await _storage.saveRefreshToken(data['refreshToken']);
          }

          if (Get.isRegistered<SocketService>()) {
            try {
              Get.find<SocketService>().forceReconnect();
            } catch (_) {}
          }

          debugPrint('[API REFRESH] Success');
          success = true;
        }
      } catch (e) {
        debugPrint('[API REFRESH] Failed: $e');
      } finally {
        completer.complete(success);
        _refreshFuture = null;
      }
    }();

    return _refreshFuture!;
  }

  // ─── HTTP Methods ──────────────────────────────────────────
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.get(
        path,
        queryParameters: queryParameters,
        options: (options ?? Options()).copyWith(
          connectTimeout: options?.connectTimeout ?? _defaultConnectTimeout,
          receiveTimeout: options?.receiveTimeout ?? _defaultReceiveTimeout,
        ),
      );

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) =>
      _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          connectTimeout: _defaultConnectTimeout,
          sendTimeout: _defaultSendTimeout,
          receiveTimeout: _writeReceiveTimeout,
        ),
      );

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(
        path,
        data: data,
        options: Options(
          connectTimeout: _defaultConnectTimeout,
          sendTimeout: _defaultSendTimeout,
          receiveTimeout: _writeReceiveTimeout,
        ),
      );

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(
        path,
        data: data,
        options: Options(
          connectTimeout: _defaultConnectTimeout,
          sendTimeout: _defaultSendTimeout,
          receiveTimeout: _writeReceiveTimeout,
        ),
      );

  Future<Response> delete(String path, {dynamic data}) =>
      _dio.delete(
        path,
        data: data,
        options: Options(
          connectTimeout: _defaultConnectTimeout,
          receiveTimeout: _defaultReceiveTimeout,
        ),
      );

  Future<Response> upload(String path, FormData formData) =>
      _dio.post(path, data: formData, options: Options(
        contentType: 'multipart/form-data',
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ));
}
