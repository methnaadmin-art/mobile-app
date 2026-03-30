import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:methna_app/core/constants/app_constants.dart';

class StorageService extends GetxService {
  late final GetStorage _box;
  late final FlutterSecureStorage _secure;

  Future<StorageService> init() async {
    _box = GetStorage();
    _secure = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    return this;
  }

  String? _cachedToken;
  String? _cachedRefreshToken;

  // ─── Secure Storage (tokens) ───────────────────────────────
  Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _secure.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await _secure.read(key: AppConstants.tokenKey);
    return _cachedToken;
  }

  Future<void> saveRefreshToken(String token) async {
    _cachedRefreshToken = token;
    await _secure.write(key: AppConstants.refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null) return _cachedRefreshToken;
    _cachedRefreshToken = await _secure.read(key: AppConstants.refreshTokenKey);
    return _cachedRefreshToken;
  }

  Future<void> clearTokens() async {
    _cachedToken = null;
    _cachedRefreshToken = null;
    await _secure.delete(key: AppConstants.tokenKey);
    await _secure.delete(key: AppConstants.refreshTokenKey);
  }

  // ─── Regular Storage ───────────────────────────────────────
  Future<void> saveUser(Map<String, dynamic> user) async =>
      await _box.write(AppConstants.userKey, jsonEncode(user));

  Map<String, dynamic>? getUser() {
    final data = _box.read(AppConstants.userKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  bool get isOnboardingDone => _box.read(AppConstants.onboardingKey) ?? false;
  Future<void> setOnboardingDone() async =>
      await _box.write(AppConstants.onboardingKey, true);

  String get themeMode => _box.read(AppConstants.themeKey) ?? 'system';
  Future<void> setThemeMode(String mode) async =>
      await _box.write(AppConstants.themeKey, mode);

  bool get isFirstLaunch => _box.read(AppConstants.firstLaunchKey) ?? true;
  Future<void> setFirstLaunch(bool value) async =>
      await _box.write(AppConstants.firstLaunchKey, value);

  // ─── Generic key-value helpers ─────────────────────────────
  bool? getBool(String key) => _box.read<bool>(key);
  Future<void> saveBool(String key, bool value) async =>
      await _box.write(key, value);

  String? getString(String key) => _box.read<String>(key);
  Future<void> saveString(String key, String value) async =>
      await _box.write(key, value);

  // ─── Signup Draft ──────────────────────────────────────────
  String? getSignupDraftRoute() {
    final draft = _box.read<Map<String, dynamic>>(AppConstants.signupDraftKey);
    return draft?['lastRoute'] as String?;
  }

  // ─── Discover Users Cache ─────────────────────────────────
  static const String _discoverCacheKey = 'cached_discover_users';

  Future<void> cacheDiscoverUsers(List<Map<String, dynamic>> users) async {
    await _box.write(_discoverCacheKey, jsonEncode(users));
  }

  List<Map<String, dynamic>>? getCachedDiscoverUsers() {
    final data = _box.read(_discoverCacheKey);
    if (data == null) return null;
    try {
      final list = jsonDecode(data) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  Future<void> clearDiscoverCache() async => await _box.remove(_discoverCacheKey);

  // ─── Clear Auth Data (preserves user preferences) ──────────
  Future<void> clearAuthData() async {
    await clearTokens();
    await _box.remove(AppConstants.userKey);
  }

  // ─── Clear ALL App Data (full reset) ──────────────────────
  Future<void> clearAll() async {
    await clearTokens();
    await _box.erase();
  }

  // ─── Clear preferences only (keep auth) ──────────────────
  Future<void> clearPreferences() async {
    // Get keys to preserve
    final user = _box.read(AppConstants.userKey);
    
    // Clear all
    await _box.erase();
    
    // Restore user data if exists
    if (user != null) {
      await _box.write(AppConstants.userKey, user);
    }
  }
}
