import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/data/models/category_model.dart';
import 'package:methna_app/app/data/models/conversation_model.dart';
import 'package:methna_app/app/data/models/who_liked_me_item_model.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/core/constants/api_constants.dart';

import 'package:methna_app/app/data/models/success_story_model.dart';
import 'package:methna_app/app/data/services/storage_service.dart';

class UsersController extends GetxController {
  static const List<String> _likedInteractionGroupKeys = <String>[
    'liked',
    'likes',
    'likedUsers',
    'liked_users',
    'sentLikes',
    'sent_likes',
    'outgoingLikes',
    'outgoing_likes',
    'givenLikes',
    'given_likes',
    'myLikes',
    'my_likes',
    'youLiked',
    'you_liked',
    'sent',
    'outgoing',
  ];

  static const List<String> _passedInteractionGroupKeys = <String>[
    'passed',
    'passes',
    'passedUsers',
    'passed_users',
    'skipped',
    'skippedUsers',
    'skipped_users',
    'rejected',
    'rejectedUsers',
    'rejected_users',
    'disliked',
    'dislikedUsers',
    'disliked_users',
    'outgoingPasses',
    'outgoing_passes',
  ];

  final ApiService _api = Get.find<ApiService>();
  final AuthService _auth = Get.find<AuthService>();
  final StorageService _storage = Get.find<StorageService>();

  // â”€â”€â”€ Data lists â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final RxList<UserModel> allUsers = <UserModel>[].obs;
  final RxList<UserModel> nearbyUsers = <UserModel>[].obs;
  final RxList<UserModel> liveTodayUsers = <UserModel>[].obs;
  final RxList<CategoryModel> backendCategories = <CategoryModel>[].obs;
  final RxList<ConversationModel> recentConversations =
      <ConversationModel>[].obs;
  final RxList<UserModel> matches = <UserModel>[].obs;
  final RxList<UserModel> likedUsers = <UserModel>[].obs;
  final RxList<UserModel> passedUsers = <UserModel>[].obs;
  final RxList<WhoLikedMeItem> likesReceived = <WhoLikedMeItem>[].obs;
  final RxList<SuccessStoryModel> successStories = <SuccessStoryModel>[].obs;
  final RxInt whoLikedMeCount = 0.obs;
  final RxBool whoLikedMeRequiresPremium = false.obs;
  final RxBool isLoadingWhoLikedMe = false.obs;
  final RxMap<String, DateTime> interactionTimestamps =
      <String, DateTime>{}.obs;

  // Compatibility scores: userId -> score (0-100)
  final RxMap<String, int> compatibilityScores = <String, int>{}.obs;
  // â”€â”€â”€ UI state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final RxBool isLoading = false.obs;
  final RxBool isLoadingStories = false.obs;
  final RxBool hasError = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString selectedCategory = 'all'.obs;
  final RxInt page = 1.obs;
  final RxBool hasMore = true.obs;
  Worker? _currentUserWorker;
  bool _isFetchingUsersPage = false;
  final Set<String> _swipeInFlight = <String>{};
  final Set<String> _seenUserIds = <String>{};
  final Map<String, UserModel> _publicUserCache = <String, UserModel>{};
  final Map<String, Future<UserModel?>> _publicHydrationTasks =
      <String, Future<UserModel?>>{};

  // Built-in filter tabs (fixed + dynamic from backend)
  List<String> get categories {
    final base = ['all', 'nearby', 'new', 'online', 'verified'];
    return base;
  }

  @override
  void onInit() {
    super.onInit();
    _seenUserIds.addAll(_storage.getSeenDiscoverUserIds());
    _currentUserWorker = ever<UserModel?>(_auth.currentUser, (_) {
      allUsers.assignAll(_sanitizeUsers(allUsers));
      nearbyUsers.assignAll(_sanitizeUsers(nearbyUsers));
      _refreshLiveTodayUsers();
    });
    _loadCachedUsersInstantly();
    _loadAll();
  }

  @override
  void onClose() {
    _currentUserWorker?.dispose();
    super.onClose();
  }

  void _loadCachedUsersInstantly() {
    try {
      final cached = _storage.getCachedAllUsers();
      if (cached != null && cached.isNotEmpty) {
        final users = _sanitizeUsers(
          cached.map((json) => UserModel.fromJson(json)),
        );
        allUsers.assignAll(users);
        _refreshLiveTodayUsers();
        debugPrint(
          '[UsersController] Loaded ${users.length} cached users instantly',
        );
      }
    } catch (e) {
      debugPrint('[UsersController] Failed to load cached users: $e');
    }
  }

  Future<void> _loadSecondaryData() async {
    await Future.delayed(const Duration(milliseconds: 350));

    if (backendCategories.isEmpty) {
      await fetchBackendCategories().catchError((e) {
        debugPrint('[UsersController] fetchBackendCategories failed: $e');
      });
    }

    await Future.delayed(const Duration(milliseconds: 250));

    if (successStories.isEmpty) {
      await fetchSuccessStories().catchError((e) {
        debugPrint('[UsersController] fetchSuccessStories failed: $e');
      });
    }

    await Future.delayed(const Duration(milliseconds: 250));

    if (matches.isEmpty) {
      await fetchMatches().catchError((e) {
        debugPrint('[UsersController] fetchMatches failed: $e');
      });
    }

    await Future.delayed(const Duration(milliseconds: 250));

    if (likesReceived.isEmpty) {
      await fetchWhoLikedMe().catchError((e) {
        debugPrint('[UsersController] fetchWhoLikedMe failed: $e');
      });
    }

    await Future.delayed(const Duration(milliseconds: 200));

    if (likedUsers.isEmpty && passedUsers.isEmpty) {
      await fetchInteractions().catchError((e) {
        debugPrint('[UsersController] fetchInteractions failed: $e');
      });
    }
  }

  DateTime? _safeDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final asString = value.toString().trim();
    if (asString.isEmpty) return null;
    return DateTime.tryParse(asString);
  }

  String _normalizeInteractionAction(String raw) {
    final normalized = raw.trim().toLowerCase().replaceAll('-', '_');
    if (normalized.isEmpty) return '';

    if (normalized.contains('compliment')) return 'like';
    if (normalized.contains('favorite') || normalized.contains('favourite')) {
      return 'like';
    }
    if (normalized == 'right' || normalized == 'swipe_right') return 'like';
    if (normalized == 'left' || normalized == 'swipe_left') return 'pass';
    if (normalized.contains('pass') ||
        normalized.contains('reject') ||
        normalized.contains('skip')) {
      return 'pass';
    }
    if (normalized.contains('like') || normalized.contains('interested')) {
      return 'like';
    }
    if (normalized.contains('match')) return 'match';

    return normalized;
  }

  String _interactionActionFromRecord(Map<String, dynamic> record) {
    final swipe = _asMap(record['swipe']);
    final interaction = _asMap(record['interaction']);

    const keys = <String>[
      'action',
      'type',
      'interactionType',
      'interaction_type',
      'swipeAction',
      'swipe_action',
      'event',
      'status',
    ];

    for (final key in keys) {
      final value = record[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return _normalizeInteractionAction(value);
      }
      final swipeValue = swipe?[key]?.toString().trim();
      if (swipeValue != null && swipeValue.isNotEmpty) {
        return _normalizeInteractionAction(swipeValue);
      }
      final interactionValue = interaction?[key]?.toString().trim();
      if (interactionValue != null && interactionValue.isNotEmpty) {
        return _normalizeInteractionAction(interactionValue);
      }
    }

    return '';
  }

  DateTime? _interactionDateFromRecord(Map<String, dynamic> record) {
    final swipe = _asMap(record['swipe']);
    final interaction = _asMap(record['interaction']);

    const keys = <String>[
      'createdAt',
      'created_at',
      'timestamp',
      'updatedAt',
      'updated_at',
      'likedAt',
      'liked_at',
      'passedAt',
      'passed_at',
    ];

    for (final key in keys) {
      final direct = _safeDate(record[key]);
      if (direct != null) return direct;
      final swipeDate = _safeDate(swipe?[key]);
      if (swipeDate != null) return swipeDate;
      final interactionDate = _safeDate(interaction?[key]);
      if (interactionDate != null) return interactionDate;
    }

    return null;
  }

  List<dynamic> _extractInteractionRecordList(dynamic source) {
    if (source is List) return source;
    if (source is! Map) return const <dynamic>[];

    const keys = <String>[
      'interactions',
      'items',
      'results',
      'records',
      'history',
      'data',
      'swipes',
      'list',
    ];

    for (final key in keys) {
      final candidate = source[key];
      if (candidate is List) return candidate;
      if (candidate is Map) {
        final nested = _extractInteractionRecordList(candidate);
        if (nested.isNotEmpty) return nested;
      }
    }

    for (final value in source.values) {
      final nested = _extractInteractionRecordList(value);
      if (nested.isNotEmpty) return nested;
    }

    return const <dynamic>[];
  }

  List<UserModel> _usersFromInteractionGroup(dynamic payload) {
    if (payload == null) return const <UserModel>[];
    return _hydrateUsersFromKnownSources(_sanitizeUsers(_parseUsers(payload)));
  }

  List<UserModel> _collectInteractionUsers(
    Map<String, dynamic>? payload,
    List<String> keys,
  ) {
    if (payload == null) return const <UserModel>[];

    final collected = <UserModel>[];
    for (final key in keys) {
      collected.addAll(_usersFromInteractionGroup(payload[key]));
    }

    return _mergeUniqueUsers(collected);
  }

  void _rememberInteractionTimestamp(String userId, DateTime? value) {
    if (userId.trim().isEmpty || value == null) return;
    final existing = interactionTimestamps[userId];
    if (existing == null || value.isAfter(existing)) {
      interactionTimestamps[userId] = value;
    }
  }

  List<UserModel> _sortByInteractionRecency(Iterable<UserModel> users) {
    final list = _mergeUniqueUsers(users);
    list.sort((a, b) {
      final aDate = interactionTimestamps[a.id];
      final bDate = interactionTimestamps[b.id];
      if (aDate != null && bDate != null) {
        return bDate.compareTo(aDate);
      }
      if (bDate != null) return 1;
      if (aDate != null) return -1;

      final aLast = a.lastLoginAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bLast = b.lastLoginAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bLast.compareTo(aLast);
    });
    return list;
  }

  Future<void> fetchInteractions() async {
    try {
      final response = await _api.get(
        ApiConstants.interactions,
        queryParameters: const {'limit': 120},
      );

      final data = response.data;
      final interactionMap = data is Map<String, dynamic>
          ? data
          : (data is Map ? Map<String, dynamic>.from(data) : null);
      final groupedLiked = _collectInteractionUsers(
        interactionMap,
        _likedInteractionGroupKeys,
      );
      final groupedPassed = _collectInteractionUsers(
        interactionMap,
        _passedInteractionGroupKeys,
      );

      final recordList = _extractInteractionRecordList(data);
      final likedFromRecords = <UserModel>[];
      final passedFromRecords = <UserModel>[];

      for (final raw in recordList) {
        if (raw is! Map) continue;
        final record = Map<String, dynamic>.from(raw);
        final user = _extractUserFromMatchRecord(record);
        if (user == null || user.id.isEmpty || _isCurrentUser(user)) continue;

        final action = _interactionActionFromRecord(record);
        final occurredAt = _interactionDateFromRecord(record);
        _rememberInteractionTimestamp(user.id, occurredAt);

        if (action == 'like') {
          likedFromRecords.add(user);
        } else if (action == 'pass') {
          passedFromRecords.add(user);
        }
      }

      final resolvedLiked = _sortByInteractionRecency([
        ...groupedLiked,
        ...likedFromRecords,
      ]);
      final resolvedPassed = _sortByInteractionRecency([
        ...groupedPassed,
        ...passedFromRecords,
      ]);

      final hydratedLiked = await _hydrateMissingUsersWithPublicProfiles(
        resolvedLiked,
      );
      final hydratedPassed = await _hydrateMissingUsersWithPublicProfiles(
        resolvedPassed,
      );

      likedUsers.assignAll(
        _sanitizeUsers(_hydrateUsersFromKnownSources(hydratedLiked)),
      );
      passedUsers.assignAll(
        _sanitizeUsers(_hydrateUsersFromKnownSources(hydratedPassed)),
      );

      debugPrint(
        '[UsersController] interactions loaded: liked=${likedUsers.length}, passed=${passedUsers.length}',
      );
    } catch (e) {
      debugPrint('[UsersController] fetchInteractions error: $e');
    }
  }

  void registerOutgoingSwipe(
    UserModel user, {
    required String action,
    bool matched = false,
    DateTime? occurredAt,
  }) {
    if (user.id.trim().isEmpty || _isCurrentUser(user)) return;

    final hydratedUsers = _hydrateUsersFromKnownSources([
      _mergeUserWithPublicCache(user),
    ]);
    final normalizedUser = hydratedUsers.isNotEmpty ? hydratedUsers.first : user;
    final timestamp = occurredAt ?? DateTime.now();

    _rememberInteractionTimestamp(normalizedUser.id, timestamp);

    switch (action) {
      case 'pass':
        likedUsers.removeWhere((candidate) => candidate.id == normalizedUser.id);
        if (!passedUsers.any((candidate) => candidate.id == normalizedUser.id)) {
          passedUsers.insert(0, normalizedUser);
        }
        break;
      case 'compliment':
      case 'like':
        passedUsers.removeWhere((candidate) => candidate.id == normalizedUser.id);
        if (!likedUsers.any((candidate) => candidate.id == normalizedUser.id)) {
          likedUsers.insert(0, normalizedUser);
        }
        break;
      default:
        return;
    }

    if (matched) {
      if (!matches.any((candidate) => candidate.id == normalizedUser.id)) {
        matches.insert(0, normalizedUser);
      }

      final hadIncomingLike = likesReceived.any(
        (item) => item.user.id == normalizedUser.id,
      );
      likesReceived.removeWhere((item) => item.user.id == normalizedUser.id);
      if (hadIncomingLike && whoLikedMeCount.value > 0) {
        whoLikedMeCount.value -= 1;
      }
    }
  }

  DateTime? interactionDateFor(String userId) {
    if (userId.trim().isEmpty) return null;
    return interactionTimestamps[userId];
  }

  List<dynamic> _extractUserList(dynamic source) {
    if (source is List) return source;
    if (source is! Map) return const <dynamic>[];

    const candidateKeys = <String>[
      'users',
      'results',
      'items',
      'matches',
      'profiles',
      'data',
    ];

    for (final key in candidateKeys) {
      final candidate = source[key];
      if (candidate is List) return candidate;
    }

    for (final value in source.values) {
      final nested = _extractUserList(value);
      if (nested.isNotEmpty) return nested;
    }

    return const <dynamic>[];
  }

  List<UserModel> _parseUsers(dynamic payload) {
    final source = _extractUserList(payload);
    if (source.isEmpty) {
      return const <UserModel>[];
    }

    return source
        .whereType<Map>()
        .map(
          (entry) => UserModel.fromApiEntry(Map<String, dynamic>.from(entry)),
        )
        .where((user) => user.id.isNotEmpty)
        .toList(growable: false);
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  int _userRichnessScore(UserModel user) {
    var score = 0;
    if ((user.mainPhotoUrl ?? '').trim().isNotEmpty) score += 5;
    if (user.photos?.isNotEmpty == true) score += 3;
    if (user.fullName.trim().isNotEmpty || user.displayName.trim().isNotEmpty) {
      score += 3;
    }
    if (user.profile != null) score += 3;
    if ((user.profile?.city ?? '').trim().isNotEmpty) score += 1;
    if ((user.profile?.country ?? '').trim().isNotEmpty) score += 1;
    if ((user.profile?.bio ?? '').trim().isNotEmpty) score += 1;
    return score;
  }

  UserModel _preferRicherUser(UserModel primary, UserModel candidate) {
    final primaryScore = _userRichnessScore(primary);
    final candidateScore = _userRichnessScore(candidate);

    if (candidateScore > primaryScore) return candidate;
    if (candidateScore < primaryScore) return primary;

    if (candidate.isOnline && !primary.isOnline) {
      return candidate;
    }

    return primary;
  }

  void _storeKnownUser(Map<String, UserModel> knownById, UserModel? user) {
    if (user == null || user.id.isEmpty) return;
    final existing = knownById[user.id];
    if (existing == null) {
      knownById[user.id] = user;
      return;
    }
    knownById[user.id] = _preferRicherUser(existing, user);
  }

  List<UserModel> _hydrateUsersFromKnownSources(Iterable<UserModel> users) {
    final knownById = <String, UserModel>{};

    for (final user in allUsers) {
      _storeKnownUser(knownById, user);
    }
    for (final user in nearbyUsers) {
      _storeKnownUser(knownById, user);
    }
    for (final user in liveTodayUsers) {
      _storeKnownUser(knownById, user);
    }
    for (final user in matches) {
      _storeKnownUser(knownById, user);
    }
    for (final item in likesReceived) {
      _storeKnownUser(knownById, item.user);
    }
    for (final user in _publicUserCache.values) {
      _storeKnownUser(knownById, user);
    }

    return users
        .map((user) {
          final known = knownById[user.id];
          if (known == null) return user;
          return _preferRicherUser(user, known);
        })
        .toList(growable: false);
  }

  bool _needsPublicHydration(UserModel user) {
    final hasPhoto =
        (user.mainPhotoUrl ?? '').trim().isNotEmpty ||
        (user.photos?.any((photo) => photo.url.trim().isNotEmpty) ?? false);
    final hasProfileData =
        user.profile != null &&
        ((user.profile?.bio ?? '').trim().isNotEmpty ||
            (user.profile?.city ?? '').trim().isNotEmpty ||
            (user.profile?.country ?? '').trim().isNotEmpty ||
            user.profile!.age > 0 ||
            (user.profile?.interests?.isNotEmpty ?? false) ||
            (user.profile?.languages?.isNotEmpty ?? false));
    return !hasPhoto || !hasProfileData;
  }

  void _cachePublicUser(UserModel user) {
    if (user.id.trim().isEmpty) return;
    final existing = _publicUserCache[user.id];
    if (existing == null) {
      _publicUserCache[user.id] = user;
      return;
    }
    _publicUserCache[user.id] = _preferRicherUser(existing, user);
  }

  UserModel _mergeUserWithPublicCache(UserModel user) {
    final cached = _publicUserCache[user.id];
    if (cached == null) return user;
    return _preferRicherUser(user, cached);
  }

  UserModel? _parsePublicUserResponse(dynamic payload, {UserModel? seed}) {
    final root = _asMap(payload);
    if (root == null) return seed;

    final rootData = _asMap(root['data']);
    final nestedData = _asMap(rootData?['data']);
    final candidate = nestedData ?? rootData ?? root;

    final parsed = UserModel.fromApiEntry(candidate);
    if (parsed.id.isEmpty) {
      return seed;
    }

    final merged = seed == null ? parsed : _preferRicherUser(seed, parsed);
    _cachePublicUser(merged);
    return merged;
  }

  Future<UserModel?> _fetchPublicUserById(
    String userId, {
    UserModel? seed,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return seed;

    final cached = _publicUserCache[normalizedUserId];
    if (cached != null) {
      return seed == null ? cached : _preferRicherUser(seed, cached);
    }

    final pending = _publicHydrationTasks[normalizedUserId];
    if (pending != null) {
      final resolved = await pending;
      if (resolved == null) return seed;
      return seed == null ? resolved : _preferRicherUser(seed, resolved);
    }

    final task = () async {
      try {
        final response = await _api.get(
          ApiConstants.userById(normalizedUserId),
          options: Options(extra: {'disable_retry': true}),
        );
        return _parsePublicUserResponse(response.data, seed: seed);
      } catch (e) {
        debugPrint(
          '[UsersController] _fetchPublicUserById failed for $normalizedUserId: $e',
        );
        return seed;
      }
    }();

    _publicHydrationTasks[normalizedUserId] = task;
    try {
      return await task;
    } finally {
      _publicHydrationTasks.remove(normalizedUserId);
    }
  }

  Future<List<UserModel>> _hydrateMissingUsersWithPublicProfiles(
    Iterable<UserModel> users,
  ) async {
    final baseUsers = _hydrateUsersFromKnownSources(_sanitizeUsers(users));
    final hydrated = await Future.wait(
      baseUsers.map((user) async {
        final merged = _mergeUserWithPublicCache(user);
        if (!_needsPublicHydration(merged)) {
          _cachePublicUser(merged);
          return merged;
        }
        return await _fetchPublicUserById(merged.id, seed: merged) ?? merged;
      }),
    );

    return _sanitizeUsers(_mergeUniqueUsers(hydrated));
  }

  Future<List<WhoLikedMeItem>> _hydrateWhoLikedMeItems(
    Iterable<WhoLikedMeItem> items,
  ) async {
    return await Future.wait(
      items.map((item) async {
        final hydratedUser = await _fetchPublicUserById(
          item.user.id,
          seed: item.user,
        );
        return WhoLikedMeItem(
          user: hydratedUser ?? item.user,
          type: item.type,
          complimentMessage: item.complimentMessage,
          createdAt: item.createdAt,
        );
      }),
    );
  }

  List<dynamic> _extractMatchRecordList(dynamic source) {
    if (source is List) return source;
    if (source is! Map) return const <dynamic>[];

    const keys = <String>['matches', 'results', 'items', 'data', 'list'];

    for (final key in keys) {
      final candidate = source[key];
      if (candidate is List) return candidate;
      if (candidate is Map) {
        final nested = _extractMatchRecordList(candidate);
        if (nested.isNotEmpty) return nested;
      }
    }

    return const <dynamic>[];
  }

  UserModel? _extractUserFromMatchRecord(Map<String, dynamic> record) {
    final currentUserId = _currentUserId;

    UserModel? parseCandidate(dynamic candidate) {
      final map = _asMap(candidate);
      if (map != null) {
        final parsed = UserModel.fromApiEntry(map);
        if (parsed.id.isNotEmpty && !_isCurrentUser(parsed)) {
          return parsed;
        }
      }

      if (candidate is String && candidate.trim().isNotEmpty) {
        final parsed = UserModel.fromApiEntry({'id': candidate.trim()});
        if (parsed.id.isNotEmpty && !_isCurrentUser(parsed)) {
          return parsed;
        }
      }

      return null;
    }

    final directKeys = <dynamic>[
      record['otherUser'],
      record['other_user'],
      record['matchedUser'],
      record['matched_user'],
      record['targetUser'],
      record['target_user'],
      record['participant'],
      record['participant_user'],
      record['member'],
      record['user'],
    ];

    for (final candidate in directKeys) {
      final parsed = parseCandidate(candidate);
      if (parsed != null) return parsed;
    }

    final participants = <Map<String, dynamic>>[];
    if (record['participants'] is List) {
      participants.addAll(
        (record['participants'] as List)
            .map((entry) => _asMap(entry))
            .whereType<Map<String, dynamic>>(),
      );
    }
    if (record['users'] is List) {
      participants.addAll(
        (record['users'] as List)
            .map((entry) => _asMap(entry))
            .whereType<Map<String, dynamic>>(),
      );
    }

    for (final participant in participants) {
      final parsed = UserModel.fromApiEntry(participant);
      if (parsed.id.isEmpty) continue;
      if (currentUserId != null && parsed.id == currentUserId) continue;
      if (_isCurrentUser(parsed)) continue;
      return parsed;
    }

    final user1 = parseCandidate(record['user1']);
    final user2 = parseCandidate(record['user2']);
    if (currentUserId != null && currentUserId.isNotEmpty) {
      if (user1 != null && user1.id != currentUserId) return user1;
      if (user2 != null && user2.id != currentUserId) return user2;
    }

    final fallback = UserModel.fromApiEntry(record);
    final hasUserSignals =
        record['firstName'] != null ||
        record['first_name'] != null ||
        record['username'] != null ||
        record['email'] != null ||
        record['photo'] != null ||
        record['photoUrl'] != null ||
        record['mainPhotoUrl'] != null ||
        record['avatarUrl'] != null ||
        record['profile'] != null ||
        record['photos'] != null;

    if (hasUserSignals && fallback.id.isNotEmpty && !_isCurrentUser(fallback)) {
      return fallback;
    }

    return null;
  }

  List<UserModel> _extractMatchUsers(dynamic payload) {
    final records = _extractMatchRecordList(payload);
    if (records.isEmpty) {
      return _hydrateUsersFromKnownSources(
        _sanitizeUsers(_parseUsers(payload)),
      );
    }

    final users = <UserModel>[];
    for (final raw in records) {
      if (raw is! Map) continue;
      final parsed = _extractUserFromMatchRecord(
        Map<String, dynamic>.from(raw),
      );
      if (parsed != null) {
        users.add(parsed);
      }
    }

    return _hydrateUsersFromKnownSources(_sanitizeUsers(users));
  }

  List<UserModel> _mergeUniqueUsers(Iterable<UserModel> users) {
    final seenIds = <String>{};
    final merged = <UserModel>[];

    for (final user in users) {
      if (user.id.isEmpty || !seenIds.add(user.id)) {
        continue;
      }
      merged.add(user);
    }

    return merged;
  }

  String? get _currentUserId {
    final direct = _auth.userId;
    if (direct != null && direct.isNotEmpty) return direct;

    final current = _auth.currentUser.value?.id;
    if (current != null && current.isNotEmpty) return current;

    final cachedUser = _storage.getUser();
    final cachedId =
        (cachedUser?['id'] ?? cachedUser?['_id'] ?? cachedUser?['userId'])
            ?.toString();
    if (cachedId != null && cachedId.isNotEmpty) return cachedId;

    return null;
  }

  bool _isCurrentUser(UserModel user) {
    final currentUserId = _currentUserId;
    if (currentUserId != null &&
        currentUserId.isNotEmpty &&
        user.id == currentUserId) {
      return true;
    }
    final currentUser = _auth.currentUser.value;
    if (currentUser == null) return false;
    if (currentUser.id == user.id) return true;

    final currentEmail = currentUser.email.trim().toLowerCase();
    final candidateEmail = user.email.trim().toLowerCase();
    if (currentEmail.isNotEmpty &&
        candidateEmail.isNotEmpty &&
        candidateEmail == currentEmail) {
      return true;
    }

    final currentUsername = (currentUser.username ?? '').trim().toLowerCase();
    final candidateUsername = (user.username ?? '').trim().toLowerCase();
    if (currentUsername.isNotEmpty &&
        candidateUsername.isNotEmpty &&
        candidateUsername == currentUsername) {
      return true;
    }

    return false;
  }

  bool _isLiveToday(UserModel user) {
    if (_isCurrentUser(user)) return false;
    return user.wasLiveInLast24Hours;
  }

  List<UserModel> _sanitizeUsers(Iterable<UserModel> users) {
    return _mergeUniqueUsers(
      users.where((u) => u.id.isNotEmpty && !_isCurrentUser(u)),
    );
  }

  void _persistVisibleUsersCache() {
    unawaited(
      _storage
          .cacheAllUsers(allUsers.map((u) => u.toJson()).toList())
          .catchError((_) {}),
    );
  }

  void _rememberSeenUserId(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) return;
    _seenUserIds.add(normalized);
    unawaited(_storage.addSeenDiscoverUserIds([normalized]));
  }

  bool hasInteractedWith(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) return false;
    if (_seenUserIds.contains(normalized)) return true;

    final persistedSeen = _storage.getSeenDiscoverUserIds();
    if (persistedSeen.contains(normalized)) {
      _seenUserIds.add(normalized);
      return true;
    }

    return false;
  }

  void _refreshLiveTodayUsers() {
    final live = _sanitizeUsers(allUsers.where(_isLiveToday))
      ..sort((a, b) {
        final aSeen = a.lastLoginAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bSeen = b.lastLoginAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bSeen.compareTo(aSeen);
      });
    liveTodayUsers.assignAll(live.take(20).toList());
  }

  Future<void> _loadAll({bool isRefresh = false}) async {
    if (isLoading.value && !isRefresh) return; // Allow refresh to bypass guard
    isLoading.value = true;
    hasError.value = false;
    final usersLoaded = await fetchUsers(refresh: true)
        .then((_) => true)
        .catchError((e) {
          debugPrint('[UsersController] fetchUsers failed: $e');
          return false;
        });

    if (!usersLoaded && allUsers.isEmpty) {
      hasError.value = true;
    }
    isLoading.value = false;

    unawaited(_loadSecondaryData());
  }

  // â”€â”€â”€ All users (Primary Source: /search, Secondary: /matches/discover) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> fetchUsers({bool refresh = false}) async {
    if (_isFetchingUsersPage && !refresh) return;
    if (refresh) {
      page.value = 1;
      hasMore.value = true;
    }
    if (!hasMore.value && !refresh) return;
    _isFetchingUsersPage = true;
    final isPaginationLoad = !refresh && page.value > 1;
    if (isPaginationLoad) {
      isLoadingMore.value = true;
    }

    try {
      debugPrint(
        '[UsersController] fetchUsers: calling ${ApiConstants.search} (page: ${page.value})',
      );

      final searchResponse = await _api.get(
        ApiConstants.search,
        queryParameters: {'page': page.value, 'limit': 20},
      );

      final searchUsers = _parseUsers(searchResponse.data);
      debugPrint(
        '[UsersController] fetchUsers: parsed ${searchUsers.length} search users',
      );

      var mergedFirstPageUsers = <UserModel>[...searchUsers];

      if (refresh || page.value == 1) {
        if (searchUsers.isEmpty) {
          try {
            final suggestionsResponse = await _api.get(
              ApiConstants.suggestions,
              queryParameters: {'limit': 20},
            );
            final suggestionUsers = _parseUsers(suggestionsResponse.data);
            mergedFirstPageUsers = _mergeUniqueUsers([
              ...mergedFirstPageUsers,
              ...suggestionUsers,
            ]);
          } catch (e) {
            debugPrint('[UsersController] Suggestions fallback failed: $e');
          }
        }

        try {
          debugPrint(
            '[UsersController] fetchUsers: supplementing with ${ApiConstants.discoverCategories}',
          );
          final discoveryResponse = await _api.get(
            ApiConstants.discoverCategories,
          );
          final discoveryData = discoveryResponse.data;

          if (discoveryData is Map) {
            final parsedNearbyUsers = _parseUsers(discoveryData['nearby']);
            if (parsedNearbyUsers.isNotEmpty || nearbyUsers.isEmpty) {
              nearbyUsers.assignAll(parsedNearbyUsers);
            }

            final discoveryUsers = _parseUsers(discoveryData['users']);
            mergedFirstPageUsers = _mergeUniqueUsers([
              ...mergedFirstPageUsers,
              ...discoveryUsers,
              ...parsedNearbyUsers,
            ]);
          }
        } catch (e) {
          debugPrint('[UsersController] Supplementing discovery failed: $e');
        }
      }

      if (refresh || page.value == 1) {
        final sanitized = _sanitizeUsers(mergedFirstPageUsers);
        if (sanitized.isNotEmpty) {
          allUsers.assignAll(sanitized);
          _persistVisibleUsersCache();
        } else if (allUsers.isEmpty) {
          allUsers.clear();
          liveTodayUsers.clear();
        }
      } else if (searchUsers.isNotEmpty) {
        allUsers.assignAll(_sanitizeUsers([...allUsers, ...searchUsers]));
        _persistVisibleUsersCache();
      }

      _refreshLiveTodayUsers();

      // Fetch compatibility scores for loaded users
      if (allUsers.isNotEmpty) {
        await _fetchBulkCompatibility(
          allUsers.map((u) => u.id).toList(),
        ).catchError((_) {});
      }
      hasMore.value = searchUsers.length >= 20;
      page.value++;
    } catch (e, stackTrace) {
      if (refresh) hasError.value = true;
      debugPrint('[UsersController] fetchUsers CRITICAL ERROR: $e');
      debugPrint('[UsersController] stackTrace: $stackTrace');

      // Fallback: keep discovery usable even if /search is unavailable.
      if (refresh && allUsers.isEmpty) {
        try {
          final discoveryResponse = await _api.get(
            ApiConstants.discoverCategories,
          );
          final discoveryData = discoveryResponse.data;
          if (discoveryData is Map) {
            final fallbackUsers = _sanitizeUsers([
              ..._parseUsers(discoveryData['users']),
              ..._parseUsers(discoveryData['nearby']),
              ..._parseUsers(discoveryData['results']),
            ]);
            if (fallbackUsers.isNotEmpty) {
              allUsers.assignAll(fallbackUsers);
              _refreshLiveTodayUsers();
              hasError.value = false;
            }
          }
        } catch (fallbackError) {
          debugPrint(
            '[UsersController] fetchUsers fallback discover failed: $fallbackError',
          );
        }
      }

      // Show snackbar for visible feedback during debug
      if (kDebugMode) {
        Get.snackbar(
          'Load Error',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      _isFetchingUsersPage = false;
      if (isPaginationLoad) {
        isLoadingMore.value = false;
      }
    }
  }

  // â”€â”€â”€ Nearby users â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> fetchNearbyUsers() async {
    try {
      final response = await _api.get(ApiConstants.nearbyUsers);
      final users = _sanitizeUsers(_parseUsers(response.data));
      if (users.isNotEmpty) {
        nearbyUsers.assignAll(users);
      }
    } catch (e) {
      debugPrint('[UsersController] fetchNearbyUsers error: $e');
    }
  }

  // â”€â”€â”€ Backend categories â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> fetchBackendCategories() async {
    try {
      final response = await _api.get(
        ApiConstants.categories,
        options: Options(extra: {'disable_retry': true}),
      );
      final data = response.data;
      final list = (data is Map && data.containsKey('data'))
          ? data['data']
          : (data is List ? data : []);
      backendCategories.assignAll(
        (list as List).map((c) => CategoryModel.fromJson(c)).toList(),
      );
    } catch (_) {}
  }

  // â”€â”€â”€ Matches â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> fetchMatches() async {
    try {
      final response = await _api.get(ApiConstants.matches);
      final users = await _hydrateMissingUsersWithPublicProfiles(
        _extractMatchUsers(response.data),
      );
      matches.assignAll(users);
      debugPrint('[UsersController] Found ${matches.length} matches');
    } catch (e) {
      debugPrint('[UsersController] fetchMatches error: $e');
    }
  }

  // â”€â”€â”€ Who Liked Me â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> fetchWhoLikedMe() async {
    isLoadingWhoLikedMe.value = true;
    try {
      final response = await _api.get(ApiConstants.whoLikedMe);
      final data = response.data;
      final list = data is List
          ? data
          : (data is Map ? (data['users'] as List? ?? const []) : const []);

      final parsedItems = list
          .whereType<Map>()
          .map(
            (entry) =>
                WhoLikedMeItem.fromJson(Map<String, dynamic>.from(entry)),
          )
          .where(
            (item) => item.user.id.isNotEmpty && !_isCurrentUser(item.user),
          )
          .toList();

      final hydratedItems = await _hydrateWhoLikedMeItems(parsedItems);

      likesReceived.assignAll(hydratedItems);
      whoLikedMeCount.value = data is Map
          ? (data['count'] as num?)?.toInt() ?? hydratedItems.length
          : hydratedItems.length;
      whoLikedMeRequiresPremium.value =
          data is Map && data['isPremiumFeature'] == true;

      for (final item in hydratedItems) {
        _rememberInteractionTimestamp(item.user.id, item.createdAt);
      }

      debugPrint(
        '[UsersController] Found ${likesReceived.length} visible likes (${whoLikedMeCount.value} total)',
      );
    } catch (e) {
      debugPrint('[UsersController] fetchWhoLikedMe error: $e');
    } finally {
      isLoadingWhoLikedMe.value = false;
    }
  }

  Future<void> refreshWhoLikedMe() => fetchWhoLikedMe();

  // â”€â”€â”€ Success Stories â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> fetchSuccessStories() async {
    try {
      isLoadingStories.value = true;
      final response = await _api.get(
        ApiConstants.successStories,
        options: Options(
          extra: {'disable_retry': true},
          validateStatus: (status) => status != null && status < 600,
        ),
      );
      if ((response.statusCode ?? 500) >= 500) {
        successStories.clear();
        debugPrint(
          '[UsersController] fetchSuccessStories skipped due to server error ${response.statusCode}',
        );
        return;
      }
      final list = response.data is List
          ? response.data
          : response.data['stories'] ?? [];
      successStories.assignAll(
        (list as List).map((s) => SuccessStoryModel.fromJson(s)).toList(),
      );
    } catch (e) {
      debugPrint('[UsersController] fetchSuccessStories error: $e');
    } finally {
      isLoadingStories.value = false;
    }
  }

  // â”€â”€â”€ Filtered users for grid tabs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  List<UserModel> get filteredUsers {
    switch (selectedCategory.value) {
      case 'nearby':
        return _sanitizeUsers(nearbyUsers);
      case 'new':
        return _sanitizeUsers(
          allUsers.where(
            (u) => u.createdAt.isAfter(
              DateTime.now().subtract(const Duration(days: 7)),
            ),
          ),
        );
      case 'online':
        return _sanitizeUsers(allUsers.where((u) => u.isOnline));
      case 'verified':
        return _sanitizeUsers(allUsers.where((u) => u.selfieVerified));
      default:
        return _sanitizeUsers(allUsers);
    }
  }

  void selectCategory(String cat) {
    selectedCategory.value = cat;
    if (cat == 'nearby' && nearbyUsers.isEmpty) {
      fetchNearbyUsers();
    }
  }

  void openUserDetail(UserModel user) {
    if (_isCurrentUser(user)) return;

    final hydrated = _hydrateUsersFromKnownSources([user]);
    final selected = hydrated.isNotEmpty ? hydrated.first : user;
    if (selected.id.isEmpty) {
      Get.snackbar('error'.tr, 'user_not_found'.tr);
      return;
    }

    unawaited(openUserDetailById(selected.id, fallbackUser: selected));
  }

  /// Opens user detail by fetching the profile from backend.
  Future<void> openUserDetailById(
    String userId, {
    UserModel? fallbackUser,
  }) async {
    if (userId.trim().isEmpty) {
      if (fallbackUser != null && !_isCurrentUser(fallbackUser)) {
        Get.toNamed(AppRoutes.userDetail, arguments: {'user': fallbackUser});
        return;
      }
      Get.snackbar('error'.tr, 'user_not_found'.tr);
      return;
    }

    // Show loading
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    try {
      final hydratedUser = await _fetchPublicUserById(
        userId,
        seed: fallbackUser,
      );
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (hydratedUser != null &&
          hydratedUser.id.isNotEmpty &&
          !_isCurrentUser(hydratedUser)) {
        Get.toNamed(AppRoutes.userDetail, arguments: {'user': hydratedUser});
        return;
      }

      if (fallbackUser != null && !_isCurrentUser(fallbackUser)) {
        Get.toNamed(AppRoutes.userDetail, arguments: {'user': fallbackUser});
        return;
      }

      Get.snackbar('error'.tr, 'user_not_found'.tr);
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      debugPrint('[UsersController] openUserDetailById error: $e');

      if (fallbackUser != null && !_isCurrentUser(fallbackUser)) {
        Get.toNamed(AppRoutes.userDetail, arguments: {'user': fallbackUser});
        return;
      }

      Get.snackbar('error'.tr, 'user_not_found'.tr);
    }
  }

  void openCategory(CategoryModel cat) {
    Get.toNamed(AppRoutes.categoryUsers, arguments: {'category': cat});
  }

  void openWhoLikedMe() {
    Get.toNamed(AppRoutes.whoLikedMe);
  }

  UserModel? _removeUserFromLists(String userId) {
    UserModel? removed;
    final idx = allUsers.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      removed = allUsers[idx];
      allUsers.removeAt(idx);
    }
    nearbyUsers.removeWhere((u) => u.id == userId);
    liveTodayUsers.removeWhere((u) => u.id == userId);
    likesReceived.removeWhere((item) => item.user.id == userId);
    return removed;
  }

  void _restoreUserInLists(UserModel? user) {
    if (user == null || user.id.isEmpty) return;
    if (!allUsers.any((u) => u.id == user.id)) {
      allUsers.insert(0, user);
    }
    _refreshLiveTodayUsers();
    _persistVisibleUsersCache();
  }

  Future<void> _swipeUser(
    String userId,
    String action, {
    String? complimentMessage,
  }) async {
    if (userId.isEmpty || _swipeInFlight.contains(userId)) {
      return;
    }

    UserModel? target;
    for (final candidate in allUsers) {
      if (candidate.id == userId) {
        target = candidate;
        break;
      }
    }
    final isSelfTarget =
        (target != null && _isCurrentUser(target)) ||
        (_currentUserId != null && userId == _currentUserId);
    if (isSelfTarget) {
      Get.snackbar(
        'Error',
        'You cannot interact with your own profile.',
        snackPosition: SnackPosition.BOTTOM,
      );
      _removeUserFromLists(userId);
      return;
    }

    _swipeInFlight.add(userId);
    final removedUser = _removeUserFromLists(userId);

    try {
      final response = await _api.post(
        ApiConstants.swipe,
        data: {
          'targetUserId': userId,
          'action': action,
          if (complimentMessage != null && complimentMessage.trim().isNotEmpty)
            'complimentMessage': complimentMessage.trim(),
        },
      );

      final data = response.data;
      final matched =
          (data is Map && (data['matched'] == true || data['isMatch'] == true));
      _rememberSeenUserId(userId);
      if (removedUser != null) {
        _rememberInteractionTimestamp(userId, DateTime.now());
        if (action == 'like' || action == 'compliment') {
          passedUsers.removeWhere((u) => u.id == removedUser.id);
          if (!likedUsers.any((u) => u.id == removedUser.id)) {
            likedUsers.insert(0, removedUser);
          }
        } else if (action == 'pass') {
          likedUsers.removeWhere((u) => u.id == removedUser.id);
          if (!passedUsers.any((u) => u.id == removedUser.id)) {
            passedUsers.insert(0, removedUser);
          }
        }
      }
      _persistVisibleUsersCache();
      if (matched && removedUser != null) {
        if (!matches.any((u) => u.id == removedUser.id)) {
          matches.insert(0, removedUser);
        }
        Get.toNamed(AppRoutes.matchFound, arguments: {'user': removedUser});
      }
    } catch (e) {
      _restoreUserInLists(removedUser);
      Get.snackbar(
        'Swipe failed',
        'Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      debugPrint('[UsersController] _swipeUser($action) error: $e');
    } finally {
      _swipeInFlight.remove(userId);
    }
  }

  Future<void> likeUser(String userId) => _swipeUser(userId, 'like');

  Future<void> passUser(String userId) => _swipeUser(userId, 'pass');

  Future<void> complimentUser(
    String userId, {
    String message = 'Salam, I would like to know you better.',
  }) => _swipeUser(userId, 'compliment', complimentMessage: message);

  Future<void> refreshUsers() async {
    await _loadAll(isRefresh: true);
  }

  void loadMore() => fetchUsers();

  // ─── Compatibility Scores ──────────────────────────────
  Future<void> _fetchBulkCompatibility(List<String> userIds) async {
    try {
      final response = await _api.post(
        ApiConstants.compatibilityBulk,
        data: {'targetUserIds': userIds},
      );
      final data = response.data;
      if (data is Map) {
        for (final entry in data.entries) {
          compatibilityScores[entry.key.toString()] = (entry.value as num)
              .toInt();
        }
      }
    } catch (e) {
      debugPrint('[UsersController] _fetchBulkCompatibility error: $e');
    }
  }

  int getCompatibilityScore(String userId) {
    return compatibilityScores[userId] ?? 0;
  }
}
