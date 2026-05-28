import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/constants/app_constants.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdatePolicy {
  const AppUpdatePolicy({
    required this.isActive,
    required this.hardRequired,
    required this.softUpdateAvailable,
    required this.title,
    required this.message,
    required this.storeUrl,
    required this.latestVersion,
    required this.minimumSupportedVersion,
  });

  final bool isActive;
  final bool hardRequired;
  final bool softUpdateAvailable;
  final String title;
  final String message;
  final String? storeUrl;
  final String? latestVersion;
  final String? minimumSupportedVersion;

  factory AppUpdatePolicy.fromJson(Map<String, dynamic> json) {
    return AppUpdatePolicy(
      isActive: json['isActive'] == true,
      hardRequired: json['hardRequired'] == true,
      softUpdateAvailable: json['softUpdateAvailable'] == true,
      title: (json['title'] ?? 'Update available').toString(),
      message: (json['message'] ?? 'A newer version of Methna is available.')
          .toString(),
      storeUrl: _stringOrNull(json['storeUrl']),
      latestVersion: _stringOrNull(json['latestVersion']),
      minimumSupportedVersion: _stringOrNull(json['minimumSupportedVersion']),
    );
  }

  static String? _stringOrNull(dynamic value) {
    final normalized = value?.toString().trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }
}

class AppUpdateService extends GetxService {
  ApiService get _api => Get.find<ApiService>();

  DateTime? _lastCheckAt;
  bool _dialogOpen = false;

  Future<bool> checkForUpdate({bool force = false}) async {
    if (!force && _lastCheckAt != null) {
      final elapsed = DateTime.now().difference(_lastCheckAt!);
      if (elapsed < const Duration(minutes: 30)) {
        return false;
      }
    }

    _lastCheckAt = DateTime.now();

    try {
      final response = await _api.get(
        ApiConstants.mobileUpdatePolicy,
        queryParameters: {
          'platform': _platform,
          'version': await _getAppVersion(),
        },
        showLoader: false,
      );

      final raw = response.data;
      if (raw is! Map) return false;

      final policy = AppUpdatePolicy.fromJson(Map<String, dynamic>.from(raw));
      if (!policy.isActive ||
          (!policy.hardRequired && !policy.softUpdateAvailable)) {
        return false;
      }

      if (_platform == 'ios' && !_isUsableIosStoreUrl(policy.storeUrl)) {
        debugPrint(
          '[AppUpdate] Ignoring iOS update policy without a real App Store URL.',
        );
        return false;
      }

      await _showUpdateDialog(policy);
      return policy.hardRequired;
    } catch (error) {
      debugPrint('[AppUpdate] Policy check failed: $error');
      return false;
    }
  }

  Future<void> _showUpdateDialog(AppUpdatePolicy policy) async {
    if (_dialogOpen || Get.context == null) return;
    _dialogOpen = true;

    final isHard = policy.hardRequired;
    final dialogFuture = Get.dialog<void>(
      PopScope(
        canPop: !isHard,
        child: AlertDialog(
          title: Text(policy.title),
          content: Text(policy.message),
          actions: [
            if (!isHard)
              TextButton(
                onPressed: () => Get.back<void>(),
                child: const Text('Later'),
              ),
            FilledButton(
              onPressed: () => _openStore(policy.storeUrl),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
      barrierDismissible: !isHard,
    );

    if (isHard) {
      unawaited(dialogFuture.whenComplete(() => _dialogOpen = false));
      return;
    }

    await dialogFuture;
    _dialogOpen = false;
  }

  Future<void> _openStore(String? url) async {
    final fallback = _defaultStoreUrl;
    final rawTarget = (url == null || url.trim().isEmpty) ? fallback : url;
    if (rawTarget == null || rawTarget.trim().isEmpty || rawTarget.contains('idYOUR_APP_ID')) {
      debugPrint('[AppUpdate] Store URL is not configured.');
      Get.snackbar(
        'Update Available',
        'Please search for "Methna" on the App Store to update.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
      return;
    }

    final target = Uri.tryParse(rawTarget);
    if (target == null) return;
    await launchUrl(target, mode: LaunchMode.externalApplication);
  }

  bool _isUsableIosStoreUrl(String? url) {
    final value = url?.trim() ?? '';
    if (value.isEmpty) return false;
    if (value.contains('id0000000000')) return false;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return false;
    return uri.host == 'apps.apple.com' || uri.host.endsWith('.apple.com');
  }

  String get _platform {
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'android';
  }

  Future<String> _getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final v = info.version.trim();
      return v.isNotEmpty ? v : AppConstants.appVersion;
    } catch (_) {
      return AppConstants.appVersion;
    }
  }

  String? get _defaultStoreUrl {
    if (_platform == 'ios') {
      final url = AppConstants.iosAppStoreUrl.trim();
      return (url.isEmpty || url.contains('idYOUR_APP_ID')) ? null : url;
    }
    return 'https://play.google.com/store/apps/details?id=${AppConstants.androidPackageName}';
  }
}
