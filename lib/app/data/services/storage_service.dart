import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:methna_app/core/constants/app_constants.dart';

class StorageService extends GetxService {
  late final GetStorage _box;
  late final FlutterSecureStorage _secure;
  SharedPreferences? _prefs;

  static const String _secureUserSnapshotKey = 'secure_user_snapshot_v1';
  static const String _secureAuthProviderKey = 'secure_auth_provider_v1';

  String? _cachedToken;
  String? _cachedRefreshToken;
  String? _cachedUserJson;
  String? _cachedAuthProvider;
  bool _hasAuthSessionHintCache = false;

  Future<StorageService> init() async {
    _box = GetStorage();
    _secure = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: false, // Set to false to avoid Android ANR (Native thread Keystore lockup)
      ),
    );

    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      _prefs = null;
    }

    // Restore secure snapshots into memory and backfill from legacy box if needed.
    try {
      _cachedUserJson = await _secure.read(key: _secureUserSnapshotKey);
      _cachedAuthProvider = await _secure.read(key: _secureAuthProviderKey);

      final legacyUser = _box.read(AppConstants.userKey)?.toString();
      if ((_cachedUserJson == null || _cachedUserJson!.isEmpty) &&
          legacyUser != null &&
          legacyUser.isNotEmpty) {
        _cachedUserJson = legacyUser;
        await _secure.write(key: _secureUserSnapshotKey, value: legacyUser);
      }

      final legacyProvider = _box.read<String>(AppConstants.authProviderKey);
      if ((_cachedAuthProvider == null || _cachedAuthProvider!.isEmpty) &&
          legacyProvider != null &&
          legacyProvider.isNotEmpty) {
        _cachedAuthProvider = legacyProvider;
        await _secure.write(
          key: _secureAuthProviderKey,
          value: legacyProvider,
        );
      }
    } catch (_) {
      // Fallback to plain local cache if secure storage is unavailable.
    }

    _cachedToken = await _readSecure(AppConstants.tokenKey);
    _cachedRefreshToken = await _readSecure(AppConstants.refreshTokenKey);

    _cachedToken ??= _readPrefsString(AppConstants.tokenKey);
    _cachedRefreshToken ??= _readPrefsString(AppConstants.refreshTokenKey);

    _cachedToken ??= _readLegacyTokenFromBox(AppConstants.tokenKey);
    _cachedRefreshToken ??= _readLegacyTokenFromBox(
      AppConstants.refreshTokenKey,
    );

    if (_cachedToken?.isNotEmpty == true) {
      await _writeSecure(AppConstants.tokenKey, _cachedToken!);
      await _writePrefsString(AppConstants.tokenKey, _cachedToken!);
    }
    if (_cachedRefreshToken?.isNotEmpty == true) {
      await _writeSecure(AppConstants.refreshTokenKey, _cachedRefreshToken!);
      await _writePrefsString(
        AppConstants.refreshTokenKey,
        _cachedRefreshToken!,
      );
    }

    final boxHint = _box.read<bool>(AppConstants.authSessionHintKey) ?? false;
    final prefsHint = _prefs?.getBool(AppConstants.authSessionHintKey) ?? false;
    final hasToken =
        _cachedToken?.isNotEmpty == true ||
        _cachedRefreshToken?.isNotEmpty == true;
    _hasAuthSessionHintCache = boxHint || prefsHint || hasToken;
    if (_hasAuthSessionHintCache) {
      await _setAuthSessionHint(true);
    }

    return this;
  }

  Future<String?> _readSecure(String key) async {
    try {
      return await _secure.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeSecure(String key, String value) async {
    try {
      await _secure.write(key: key, value: value);
    } catch (_) {}
  }

  Future<void> _deleteSecure(String key) async {
    try {
      await _secure.delete(key: key);
    } catch (_) {}
  }

  String? _readPrefsString(String key) {
    try {
      return _prefs?.getString(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writePrefsString(String key, String value) async {
    try {
      await _prefs?.setString(key, value);
    } catch (_) {}
  }

  Future<void> _removePrefsKey(String key) async {
    try {
      await _prefs?.remove(key);
    } catch (_) {}
  }

  String? _readLegacyTokenFromBox(String key) {
    final raw = _box.read(key)?.toString();
    if (raw == null) return null;
    final value = raw.trim();
    if (value.isEmpty || value.toLowerCase() == 'null') {
      return null;
    }
    return value;
  }

  Future<void> _setAuthSessionHint(bool enabled) async {
    _hasAuthSessionHintCache = enabled;
    if (enabled) {
      await _box.write(AppConstants.authSessionHintKey, true);
      try {
        await _prefs?.setBool(AppConstants.authSessionHintKey, true);
      } catch (_) {}
      return;
    }

    await _box.remove(AppConstants.authSessionHintKey);
    try {
      await _prefs?.remove(AppConstants.authSessionHintKey);
    } catch (_) {}
  }

  // ─── Secure Storage (tokens) ───────────────────────────────
  Future<void> saveToken(String token) async {
    final normalized = token.trim();
    if (normalized.isEmpty) return;
    _cachedToken = normalized;
    await _setAuthSessionHint(true);
    await _writeSecure(AppConstants.tokenKey, normalized);
    await _writePrefsString(AppConstants.tokenKey, normalized);
  }

  Future<String?> getToken() async {
    if (_cachedToken?.isNotEmpty == true) return _cachedToken;

    _cachedToken = await _readSecure(AppConstants.tokenKey);
    _cachedToken ??= _readPrefsString(AppConstants.tokenKey);
    _cachedToken ??= _readLegacyTokenFromBox(AppConstants.tokenKey);

    if (_cachedToken?.isNotEmpty == true) {
      await _setAuthSessionHint(true);
      await _writeSecure(AppConstants.tokenKey, _cachedToken!);
      await _writePrefsString(AppConstants.tokenKey, _cachedToken!);
    }

    return _cachedToken;
  }

  Future<void> saveRefreshToken(String token) async {
    final normalized = token.trim();
    if (normalized.isEmpty) return;
    _cachedRefreshToken = normalized;
    await _setAuthSessionHint(true);
    await _writeSecure(AppConstants.refreshTokenKey, normalized);
    await _writePrefsString(AppConstants.refreshTokenKey, normalized);
  }

  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken?.isNotEmpty == true) return _cachedRefreshToken;

    _cachedRefreshToken = await _readSecure(AppConstants.refreshTokenKey);
    _cachedRefreshToken ??= _readPrefsString(AppConstants.refreshTokenKey);
    _cachedRefreshToken ??= _readLegacyTokenFromBox(
      AppConstants.refreshTokenKey,
    );

    if (_cachedRefreshToken?.isNotEmpty == true) {
      await _setAuthSessionHint(true);
      await _writeSecure(
        AppConstants.refreshTokenKey,
        _cachedRefreshToken!,
      );
      await _writePrefsString(
        AppConstants.refreshTokenKey,
        _cachedRefreshToken!,
      );
    }

    return _cachedRefreshToken;
  }

  Future<void> clearTokens() async {
    _cachedToken = null;
    _cachedRefreshToken = null;
    await _setAuthSessionHint(false);
    await _deleteSecure(AppConstants.tokenKey);
    await _deleteSecure(AppConstants.refreshTokenKey);
    await _removePrefsKey(AppConstants.tokenKey);
    await _removePrefsKey(AppConstants.refreshTokenKey);
    await _box.remove(AppConstants.tokenKey);
    await _box.remove(AppConstants.refreshTokenKey);
  }

  // ─── Regular Storage ───────────────────────────────────────
  Future<void> saveUser(Map<String, dynamic> user) async {
    final encoded = jsonEncode(user);
    _cachedUserJson = encoded;
    await _box.write(AppConstants.userKey, encoded);
    try {
      await _secure.write(key: _secureUserSnapshotKey, value: encoded);
    } catch (_) {}
  }

  Future<void> saveAuthProvider(String provider) async {
    _cachedAuthProvider = provider;
    await _box.write(AppConstants.authProviderKey, provider);
    try {
      await _secure.write(key: _secureAuthProviderKey, value: provider);
    } catch (_) {}
  }

  Map<String, dynamic>? getUser() {
    final data = _cachedUserJson ?? _box.read(AppConstants.userKey)?.toString();
    if (data == null || data.isEmpty) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String? getAuthProvider() =>
      _cachedAuthProvider ?? _box.read<String>(AppConstants.authProviderKey);
  bool get hasAuthSessionHint =>
      _hasAuthSessionHintCache ||
      (_box.read<bool>(AppConstants.authSessionHintKey) ?? false) ||
      (_prefs?.getBool(AppConstants.authSessionHintKey) ?? false);

  bool get isOnboardingDone => _box.read(AppConstants.onboardingKey) ?? false;
  Future<void> setOnboardingDone() async =>
      await _box.write(AppConstants.onboardingKey, true);

  String get themeMode => _box.read(AppConstants.themeKey) ?? 'dark';
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
  static const String _discoverSeenIdsKey = 'discover_seen_user_ids';

  String _scopedDiscoverSeenIdsKey() {
    final user = getUser();
    final userId =
        (user?['id'] ?? user?['_id'] ?? user?['userId'] ?? user?['user_id'])
            ?.toString()
            .trim();
    if (userId != null && userId.isNotEmpty) {
      return '$_discoverSeenIdsKey::$userId';
    }
    return _discoverSeenIdsKey;
  }

  // ─── All Users Cache ─────────────────────────────────────
  static const String _allUsersCacheKey = 'cached_all_users';

  // ─── Conversations Cache ─────────────────────────────────
  static const String _conversationsCacheKey = 'cached_conversations';

  Future<void> cacheDiscoverUsers(List<Map<String, dynamic>> users) async =>
      await _box.write(_discoverCacheKey, jsonEncode(users));

  Set<String> getSeenDiscoverUserIds() {
    final scopedKey = _scopedDiscoverSeenIdsKey();
    dynamic data = _box.read(scopedKey);

    // One-time migration from legacy global key to scoped key.
    if (data == null && scopedKey != _discoverSeenIdsKey) {
      final legacyData = _box.read(_discoverSeenIdsKey);
      if (legacyData != null) {
        data = legacyData;
        unawaited(_box.write(scopedKey, legacyData));
        unawaited(_box.remove(_discoverSeenIdsKey));
      }
    }

    if (data == null) return <String>{};
    try {
      final list = jsonDecode(data) as List;
      return list
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> saveSeenDiscoverUserIds(Set<String> userIds) async {
    final scopedKey = _scopedDiscoverSeenIdsKey();
    await _box.write(scopedKey, jsonEncode(userIds.toList()));
    if (scopedKey != _discoverSeenIdsKey) {
      await _box.remove(_discoverSeenIdsKey);
    }
  }

  Future<void> addSeenDiscoverUserIds(Iterable<String> userIds) async {
    final merged = getSeenDiscoverUserIds()
      ..addAll(
        userIds.map((id) => id.trim()).where((id) => id.isNotEmpty),
      );
    await saveSeenDiscoverUserIds(merged);
  }

  Future<void> removeSeenDiscoverUserId(String userId) async {
    final current = getSeenDiscoverUserIds()..remove(userId.trim());
    await saveSeenDiscoverUserIds(current);
  }
  Future<void> cacheAllUsers(List<Map<String, dynamic>> users) async =>
      await _box.write(_allUsersCacheKey, jsonEncode(users));
  Future<void> cacheConversations(List<Map<String, dynamic>> convos) async =>
      await _box.write(_conversationsCacheKey, jsonEncode(convos));

  List<Map<String, dynamic>>? getCachedDiscoverUsers() =>
      _parseCacheList(_discoverCacheKey);
  List<Map<String, dynamic>>? getCachedAllUsers() =>
      _parseCacheList(_allUsersCacheKey);
  List<Map<String, dynamic>>? getCachedConversations() =>
      _parseCacheList(_conversationsCacheKey);

  List<Map<String, dynamic>>? _parseCacheList(String key) {
    final data = _box.read(key);
    if (data == null) return null;
    try {
      final list = jsonDecode(data) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  Future<void> clearDiscoverCache() async =>
      await _box.remove(_discoverCacheKey);
  Future<void> clearSeenDiscoverUserIds() async =>
      await _box.remove(_scopedDiscoverSeenIdsKey());
  Future<void> clearAllUsersCache() async =>
      await _box.remove(_allUsersCacheKey);
  Future<void> clearConversationsCache() async =>
      await _box.remove(_conversationsCacheKey);

  // ─── Clear Auth Data (preserves user preferences) ──────────
  Future<void> clearAuthData() async {
    await clearTokens();
    _cachedUserJson = null;
    _cachedAuthProvider = null;
    await _box.remove(AppConstants.userKey);
    await _box.remove(AppConstants.authProviderKey);
    try {
      await _secure.delete(key: _secureUserSnapshotKey);
      await _secure.delete(key: _secureAuthProviderKey);
    } catch (_) {}
  }

  // ─── Clear ALL App Data (full reset) ──────────────────────
  Future<void> clearAll() async {
    await clearTokens();
    _cachedUserJson = null;
    _cachedAuthProvider = null;
    try {
      await _secure.delete(key: _secureUserSnapshotKey);
      await _secure.delete(key: _secureAuthProviderKey);
    } catch (_) {}
    await _box.erase();
  }

  // ─── Clear preferences only (keep auth) ──────────────────
  Future<void> clearPreferences() async {
    // Get keys to preserve
    final user = _box.read(AppConstants.userKey);
    final provider = _box.read(AppConstants.authProviderKey);
    final keepAuthHint = hasAuthSessionHint;

    // Clear all
    await _box.erase();

    // Restore user data if exists
    if (user != null) {
      await _box.write(AppConstants.userKey, user);
    }
    if (provider != null) {
      await _box.write(AppConstants.authProviderKey, provider);
    }
    if (keepAuthHint) {
      await _setAuthSessionHint(true);
    }
  }
}
