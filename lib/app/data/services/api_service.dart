import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/app/data/services/storage_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';

class ApiService extends GetxService {
  late final Dio _dio;
  final StorageService _storage = Get.find<StorageService>();
  bool _isRedirecting = false;

  Future<ApiService> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('[API RESPONSE] ${response.requestOptions.method} ${response.requestOptions.path}');
        // Unwrap the backend's { success, data, timestamp } envelope
        if (response.data is Map && response.data['success'] == true && response.data.containsKey('data')) {
          response.data = response.data['data'];
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        // Log full error details for debugging
        debugPrint('[API ERROR] ${error.requestOptions.method} ${error.requestOptions.path}');
        debugPrint('[API ERROR] Type: ${error.type}');
        debugPrint('[API ERROR] Status: ${error.response?.statusCode}');
        
        if (error.response?.statusCode == 401) {
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
        if (_shouldRetry(error)) {
          final route = Get.currentRoute;
          if (route.contains('signup') || route == AppRoutes.splash) {
             return handler.next(error); // Critical: Don't retry during signup/splash to avoid event loop congestion
          }

          final retryCount = error.requestOptions.extra['retry_count'] ?? 0;
          if (retryCount < 3) {
            final nextRetry = retryCount + 1;
            error.requestOptions.extra['retry_count'] = nextRetry;
            
            // Exponential Backoff: 1s, 4s, 9s
            final delay = Duration(seconds: nextRetry * nextRetry);
            debugPrint('[API RETRY] Attempt $nextRetry in ${delay.inSeconds}s (Non-blocking)...');
            
            // Non-blocking wait using Future.delayed outside of the main interceptor flow if possible
            // but Dio requires handler.resolve/next. We use Future.delayed and then call it.
            Future.delayed(delay, () async {
              try {
                final response = await _dio.fetch(error.requestOptions);
                handler.resolve(response);
              } catch (e) {
                handler.next(error);
              }
            });
            return; // Exit interceptor immediately to unblock the thread
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

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return false;

      // Use a dedicated Dio instance for refresh to avoid interceptor recursion/loops
      final refreshDio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
      ));

      debugPrint('[API REFRESH] Attempting token renewal...');
      final response = await refreshDio.post(
        ApiConstants.refreshToken, 
        data: {'refreshToken': refreshToken}
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
            
        await _storage.saveToken(data['accessToken']);
        if (data['refreshToken'] != null) {
          await _storage.saveRefreshToken(data['refreshToken']);
        }
        debugPrint('[API REFRESH] Success');
        return true;
      }
    } catch (e) {
      debugPrint('[API REFRESH] Failed: $e');
    }
    return false;
  }

  // ─── HTTP Methods ──────────────────────────────────────────
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) =>
      _dio.post(path, data: data, queryParameters: queryParameters);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path, {dynamic data}) =>
      _dio.delete(path, data: data);

  Future<Response> upload(String path, FormData formData) =>
      _dio.post(path, data: formData, options: Options(
        contentType: 'multipart/form-data',
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ));
}
