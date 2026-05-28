import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/data/services/storage_service.dart';

class MatchFoundPresentationGuard {
  MatchFoundPresentationGuard._();

  static const Duration _dedupeWindow = Duration(minutes: 10);
  static final Map<String, DateTime> _recentPresentationKeys =
      <String, DateTime>{};
  static final Set<String> _activeDismissalKeys = <String>{};
  static bool _presentationActive = false;
  static Set<String>? _dismissedPresentationKeys;

  static StorageService? get _storage =>
      Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;

  static Set<String> _dedupeKeys({String? matchId, String? userId}) {
    final normalizedMatchId = (matchId ?? '').trim();
    final normalizedUserId = (userId ?? '').trim();
    return <String>{
      if (normalizedMatchId.isNotEmpty) 'match:$normalizedMatchId',
      if (normalizedUserId.isNotEmpty) 'user:$normalizedUserId',
    };
  }

  static Set<String> _dismissalKeys({String? matchId, String? userId}) {
    final normalizedMatchId = (matchId ?? '').trim();
    if (normalizedMatchId.isNotEmpty) {
      return <String>{'match:$normalizedMatchId'};
    }

    final normalizedUserId = (userId ?? '').trim();
    if (normalizedUserId.isNotEmpty) {
      return <String>{'user:$normalizedUserId'};
    }

    return const <String>{};
  }

  static Set<String> _loadDismissedKeys() {
    final cached = _dismissedPresentationKeys;
    if (cached != null) {
      return cached;
    }

    final loaded = _storage?.getDismissedMatchPopupKeys() ?? <String>{};
    _dismissedPresentationKeys = loaded;
    return loaded;
  }

  static void _persistDismissedKeys() {
    final storage = _storage;
    final keys = _dismissedPresentationKeys;
    if (storage == null || keys == null) return;
    unawaited(storage.saveDismissedMatchPopupKeys(keys));
  }

  static bool shouldPresent({String? matchId, String? userId}) {
    final keys = _dedupeKeys(matchId: matchId, userId: userId);
    if (keys.isEmpty) {
      return false;
    }

    final now = DateTime.now();
    _recentPresentationKeys.removeWhere(
      (_, presentedAt) => now.difference(presentedAt) > _dedupeWindow,
    );
    final dismissedKeys = _loadDismissedKeys();
    final persistentKeys = _dismissalKeys(matchId: matchId, userId: userId);

    for (final key in keys) {
      if (_recentPresentationKeys.containsKey(key)) {
        return false;
      }
    }
    for (final key in persistentKeys) {
      if (dismissedKeys.contains(key)) {
        return false;
      }
    }

    for (final key in keys) {
      _recentPresentationKeys[key] = now;
    }
    return true;
  }

  static bool beginPresentation({String? matchId, String? userId}) {
    if (_presentationActive) {
      return false;
    }
    final allowed = shouldPresent(matchId: matchId, userId: userId);
    if (!allowed) {
      return false;
    }
    _activeDismissalKeys
      ..clear()
      ..addAll(_dismissalKeys(matchId: matchId, userId: userId));
    _presentationActive = true;
    return true;
  }

  static void endPresentation({bool markDismissed = false}) {
    if (markDismissed && _activeDismissalKeys.isNotEmpty) {
      final dismissedKeys = _loadDismissedKeys();
      dismissedKeys.addAll(_activeDismissalKeys);
      _dismissedPresentationKeys = dismissedKeys;
      _persistDismissedKeys();
    }
    _activeDismissalKeys.clear();
    _presentationActive = false;
  }

  static bool get isPresentationActive => _presentationActive;

  static void clearDismissal({String? matchId, String? userId}) {
    final keys = _dismissalKeys(matchId: matchId, userId: userId);
    if (keys.isEmpty) return;
    final dismissedKeys = _loadDismissedKeys();
    final before = dismissedKeys.length;
    dismissedKeys.removeAll(keys);
    if (dismissedKeys.length == before) return;
    _dismissedPresentationKeys = dismissedKeys;
    _persistDismissedKeys();
  }

  static String? extractMatchId(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return _firstNonEmpty(<dynamic>[
        payload['matchId'],
        payload['match_id'],
        payload['id'],
        _asMap(payload['match'])?['id'],
        _asMap(payload['match'])?['matchId'],
        _asMap(payload['match'])?['match_id'],
        _asMap(payload['data'])?['matchId'],
        _asMap(payload['data'])?['match_id'],
        _asMap(payload['data'])?['id'],
        _asMap(_asMap(payload['data'])?['match'])?['id'],
        _asMap(_asMap(payload['data'])?['match'])?['matchId'],
        _asMap(_asMap(payload['data'])?['match'])?['match_id'],
      ]);
    }
    if (payload is Map) {
      return extractMatchId(Map<String, dynamic>.from(payload));
    }
    return null;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final normalized = value?.toString().trim() ?? '';
      if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
        return normalized;
      }
    }
    return null;
  }

  @visibleForTesting
  static void resetForTesting() {
    _recentPresentationKeys.clear();
    _activeDismissalKeys.clear();
    _dismissedPresentationKeys = null;
    _presentationActive = false;
  }

  static void resetRuntimeState() {
    _recentPresentationKeys.clear();
    _activeDismissalKeys.clear();
    _dismissedPresentationKeys = null;
    _presentationActive = false;
  }
}
