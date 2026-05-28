import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/chat_controller.dart';
import 'package:methna_app/app/controllers/home_controller.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/data/models/category_model.dart';
import 'package:methna_app/app/data/models/conversation_model.dart';
import 'package:methna_app/app/data/models/who_liked_me_item_model.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/utils/match_found_presentation_guard.dart';
import 'package:methna_app/screens/main/home/match_found_screen.dart';

import 'package:methna_app/app/data/models/success_story_model.dart';
import 'package:methna_app/app/data/services/storage_service.dart';

class UsersController extends GetxController {
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

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
  final RxBool isLoadingInteractions = false.obs;
  final RxBool isLoadingMatches = false.obs;
  final RxMap<String, DateTime> interactionTimestamps =
      <String, DateTime>{}.obs;
  static const Duration _bucketStaleAfter = Duration(seconds: 45);
  static const int _discoverPrefetchThreshold = 6;
  DateTime? _interactionsFetchedAt;
  DateTime? _whoLikedMeFetchedAt;
  DateTime? _matchesFetchedAt;
  bool _hasFetchedMatchesOnce = false;

  // Compatibility scores: userId -> score (0-100)
  final RxMap<String, int> compatibilityScores = <String, int>{}.obs;
  final RxnInt requestedUsersTabIndex = RxnInt();

  int normalizeUsersTabIndex(int index) => index.clamp(0, 3).toInt();

  void requestUsersTab(int tabIndex, {bool forceRefresh = false}) {
    final normalized = normalizeUsersTabIndex(tabIndex);
    requestedUsersTabIndex.value = normalized;
    if (forceRefresh) {
      unawaited(ensureUsersTabData(force: true, tabIndex: normalized));
    }
  }

  void clearRequestedUsersTab() {
    requestedUsersTabIndex.value = null;
  }

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
  int _discoverFeedGeneration = 0;
  final Set<String> _swipeInFlight = <String>{};
  final Set<String> _seenUserIds = <String>{};
  final Map<String, String> _matchIdByUserId = <String, String>{};
  final Map<String, UserModel> _publicUserCache = <String, UserModel>{};
  final Map<String, Future<UserModel?>> _publicHydrationTasks =
      <String, Future<UserModel?>>{};

  void _presentMatchFound(UserModel? matchedUser, {String? matchId}) {
    if (matchedUser == null || matchedUser.id.isEmpty) return;
    if (!MatchFoundPresentationGuard.beginPresentation(
      matchId: matchId,
      userId: matchedUser.id,
    )) {
      return;
    }
    debugPrint(
      '[UsersController] Presenting match overlay for ${matchedUser.id} (matchId=${matchId ?? 'unknown'})',
    );
    unawaited(
      MatchFoundScreen.showOverlay(matchedUser).then(
        (displayed) => MatchFoundPresentationGuard.endPresentation(
          markDismissed: displayed,
        ),
      ),
    );
  }

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
        final users = _sanitizeDiscoverFeedUsers(
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

    // Restore liked users from local cache
    try {
      final cachedLiked = _storage.getCachedLikedUsers();
      if (cachedLiked != null && cachedLiked.isNotEmpty && likedUsers.isEmpty) {
        final users = _sanitizeUsers(
          cachedLiked.map((json) => UserModel.fromJson(json)),
        );
        likedUsers.assignAll(users);
        debugPrint(
          '[UsersController] Restored ${users.length} cached liked users',
        );
      }
    } catch (e) {
      debugPrint('[UsersController] Failed to load cached liked users: $e');
    }

    // Restore passed users from local cache
    try {
      final cachedPassed = _storage.getCachedPassedUsers();
      if (cachedPassed != null &&
          cachedPassed.isNotEmpty &&
          passedUsers.isEmpty) {
        final users = _sanitizeUsers(
          cachedPassed.map((json) => UserModel.fromJson(json)),
        );
        passedUsers.assignAll(users);
        debugPrint(
          '[UsersController] Restored ${users.length} cached passed users',
        );
      }
    } catch (e) {
      debugPrint('[UsersController] Failed to load cached passed users: $e');
    }

    if (allUsers.isNotEmpty) {
      allUsers.assignAll(_sanitizeDiscoverFeedUsers(allUsers));
      _refreshLiveTodayUsers();
    }
  }

  List<UserModel> _sanitizeDiscoverFeedUsers(Iterable<UserModel> users) {
    final seenIds = <String>{
      ..._seenUserIds,
      ..._storage.getSeenDiscoverUserIds(),
      ...likedUsers.map((user) => user.id.trim()),
      ...passedUsers.map((user) => user.id.trim()),
      ...matches.map((user) => user.id.trim()),
    }..removeWhere((id) => id.isEmpty);

    return _sanitizeUsers(users)
        .where((user) => !seenIds.contains(user.id.trim()))
        .toList(growable: false);
  }

  void _prefetchDiscoverFeedIfNeeded() {
    if (_isFetchingUsersPage || isLoadingMore.value || !hasMore.value) {
      return;
    }
    if (allUsers.length > _discoverPrefetchThreshold) {
      return;
    }
    unawaited(fetchUsers());
  }

  void _refreshRelationshipSurfaces({bool includeChat = false}) {
    unawaited(fetchInteractions());
    unawaited(fetchWhoLikedMe());
    unawaited(fetchMatches());

    if (includeChat && Get.isRegistered<ChatController>()) {
      unawaited(Get.find<ChatController>().fetchConversations());
    }
  }

  Future<void> _loadSecondaryData() async {
    final jobs = <Future<void>>[];

    if (backendCategories.isEmpty) {
      jobs.add(
        fetchBackendCategories().catchError((e) {
          debugPrint('[UsersController] fetchBackendCategories failed: $e');
        }),
      );
    }

    if (successStories.isEmpty) {
      jobs.add(
        fetchSuccessStories().catchError((e) {
          debugPrint('[UsersController] fetchSuccessStories failed: $e');
        }),
      );
    }

    if (matches.isEmpty) {
      jobs.add(
        fetchMatches().catchError((e) {
          debugPrint('[UsersController] fetchMatches failed: $e');
        }),
      );
    }

    if (likesReceived.isEmpty) {
      jobs.add(
        fetchWhoLikedMe().catchError((e) {
          debugPrint('[UsersController] fetchWhoLikedMe failed: $e');
        }),
      );
    }

    if (likedUsers.isEmpty && passedUsers.isEmpty) {
      jobs.add(
        fetchInteractions().catchError((e) {
          debugPrint('[UsersController] fetchInteractions failed: $e');
        }),
      );
    }

    if (jobs.isNotEmpty) {
      await Future.wait(jobs);
    }
  }

  bool _isBucketStale(DateTime? fetchedAt) {
    if (fetchedAt == null) return true;
    return DateTime.now().difference(fetchedAt) >= _bucketStaleAfter;
  }

  Future<void> ensureUsersTabData({bool force = false, int? tabIndex}) async {
    if (tabIndex == null) {
      await Future.wait([
        if (force || _isBucketStale(_interactionsFetchedAt))
          fetchInteractions(),
        if (force || _isBucketStale(_whoLikedMeFetchedAt)) fetchWhoLikedMe(),
        if (force || _isBucketStale(_matchesFetchedAt)) fetchMatches(),
      ]);
      return;
    }

    switch (tabIndex) {
      case 0:
      case 2:
        if (force || _isBucketStale(_interactionsFetchedAt)) {
          await fetchInteractions();
        }
        return;
      case 1:
        if (force || _isBucketStale(_whoLikedMeFetchedAt)) {
          await fetchWhoLikedMe();
        }
        return;
      case 3:
        if (force || _isBucketStale(_matchesFetchedAt)) {
          await fetchMatches();
        }
        return;
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

  String? _interactionParticipantId(
    Map<String, dynamic> record,
    List<String> keys,
  ) {
    final swipe = _asMap(record['swipe']);
    final interaction = _asMap(record['interaction']);

    for (final key in keys) {
      final direct = record[key]?.toString().trim();
      if (direct != null &&
          direct.isNotEmpty &&
          direct.toLowerCase() != 'null') {
        return direct;
      }

      final fromSwipe = swipe?[key]?.toString().trim();
      if (fromSwipe != null &&
          fromSwipe.isNotEmpty &&
          fromSwipe.toLowerCase() != 'null') {
        return fromSwipe;
      }

      final fromInteraction = interaction?[key]?.toString().trim();
      if (fromInteraction != null &&
          fromInteraction.isNotEmpty &&
          fromInteraction.toLowerCase() != 'null') {
        return fromInteraction;
      }
    }

    return null;
  }

  String? _interactionActorId(Map<String, dynamic> record) {
    return _interactionParticipantId(record, const <String>[
      'actorId',
      'actor_id',
      'sourceUserId',
      'source_user_id',
      'swiperId',
      'swiper_id',
      'fromUserId',
      'from_user_id',
      'initiatorId',
      'initiator_id',
      'userId',
      'user_id',
    ]);
  }

  String? _interactionTargetId(Map<String, dynamic> record) {
    return _interactionParticipantId(record, const <String>[
      'targetUserId',
      'target_user_id',
      'toUserId',
      'to_user_id',
      'recipientId',
      'recipient_id',
      'likedUserId',
      'liked_user_id',
      'passedUserId',
      'passed_user_id',
      'profileUserId',
      'profile_user_id',
    ]);
  }

  bool _isOutgoingInteractionRecord(Map<String, dynamic> record) {
    final currentUserId = _currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      return true;
    }

    final actorId = _interactionActorId(record);
    if (actorId != null && actorId.isNotEmpty) {
      return actorId == currentUserId;
    }

    final targetId = _interactionTargetId(record);
    if (targetId != null && targetId.isNotEmpty) {
      return targetId != currentUserId;
    }

    return true;
  }

  bool _isPositiveLikeType(String rawType) {
    final normalized = _normalizeInteractionAction(rawType);
    return normalized == 'like' || normalized == 'compliment';
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
    isLoadingInteractions.value = true;
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
        if (!_isOutgoingInteractionRecord(record)) {
          continue;
        }
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
      _interactionsFetchedAt = DateTime.now();
      _normalizeRelationshipBuckets();

      debugPrint(
        '[UsersController] interactions loaded: liked=${likedUsers.length}, passed=${passedUsers.length}',
      );
      _persistInteractionsCache();
    } catch (e) {
      debugPrint('[UsersController] fetchInteractions error: $e');
    } finally {
      isLoadingInteractions.value = false;
    }
  }

  List<WhoLikedMeItem> _dedupeWhoLikedMeItems(Iterable<WhoLikedMeItem> items) {
    final blockedIds = _storage.getBlockedUserIds();
    final sorted = items.toList(growable: false)
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    final seen = <String>{};
    final deduped = <WhoLikedMeItem>[];

    for (final item in sorted) {
      final userId = item.user.id.trim();
      if (userId.isEmpty ||
          blockedIds.contains(userId) ||
          _isCurrentUser(item.user) ||
          !seen.add(userId)) {
        continue;
      }
      deduped.add(item);
    }

    return deduped;
  }

  int _removeIncomingLikeStateForIds(Iterable<String> userIds) {
    final normalizedIds = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (normalizedIds.isEmpty) return 0;

    final before = likesReceived.length;
    likesReceived.removeWhere(
      (item) => normalizedIds.contains(item.user.id.trim()),
    );
    final removedCount = before - likesReceived.length;
    if (removedCount > 0 && whoLikedMeCount.value > 0) {
      whoLikedMeCount.value = math.max(0, whoLikedMeCount.value - removedCount);
    }
    return removedCount;
  }

  void _removeOutgoingInteractionStateForIds(Iterable<String> userIds) {
    final normalizedIds = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (normalizedIds.isEmpty) return;

    likedUsers.removeWhere((candidate) => normalizedIds.contains(candidate.id));
    passedUsers.removeWhere(
      (candidate) => normalizedIds.contains(candidate.id),
    );
  }

  void _normalizeRelationshipBuckets() {
    final matchedIds = matches
        .map((user) => user.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (matchedIds.isNotEmpty) {
      _removeOutgoingInteractionStateForIds(matchedIds);
      _removeIncomingLikeStateForIds(matchedIds);
    }

    final passedIds = passedUsers
        .map((user) => user.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (passedIds.isNotEmpty) {
      likedUsers.removeWhere((candidate) => passedIds.contains(candidate.id));
      _removeIncomingLikeStateForIds(passedIds);
    }

    final likedIds = likedUsers
        .map((user) => user.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (likedIds.isNotEmpty) {
      passedUsers.removeWhere((candidate) => likedIds.contains(candidate.id));
    }

    matches.assignAll(_sanitizeUsers(_mergeUniqueUsers(matches)));
    likedUsers.assignAll(
      _sortByInteractionRecency(_sanitizeUsers(_mergeUniqueUsers(likedUsers))),
    );
    passedUsers.assignAll(
      _sortByInteractionRecency(_sanitizeUsers(_mergeUniqueUsers(passedUsers))),
    );
    likesReceived.assignAll(_dedupeWhoLikedMeItems(likesReceived));
    _persistInteractionsCache();
  }

  void _promoteUserToMatch(
    UserModel user, {
    String? matchId,
    DateTime? occurredAt,
  }) {
    if (user.id.trim().isEmpty || _isCurrentUser(user)) return;

    final hydratedUsers = _hydrateUsersFromKnownSources([
      _mergeUserWithPublicCache(user),
    ]);
    final normalizedUser = hydratedUsers.isNotEmpty
        ? hydratedUsers.first
        : user;
    final timestamp = occurredAt ?? DateTime.now();

    _rememberMatchIdForUser(normalizedUser.id, matchId);
    _rememberInteractionTimestamp(normalizedUser.id, timestamp);
    _removeOutgoingInteractionStateForIds(<String>[normalizedUser.id]);
    _removeIncomingLikeStateForIds(<String>[normalizedUser.id]);

    if (!matches.any((candidate) => candidate.id == normalizedUser.id)) {
      matches.insert(0, normalizedUser);
    }

    _matchesFetchedAt = DateTime.now();
    _interactionsFetchedAt = DateTime.now();
    _whoLikedMeFetchedAt = DateTime.now();
    _normalizeRelationshipBuckets();
  }

  void registerOutgoingSwipe(
    UserModel user, {
    required String action,
    bool matched = false,
    String? matchId,
    DateTime? occurredAt,
  }) {
    if (user.id.trim().isEmpty || _isCurrentUser(user)) return;

    final hydratedUsers = _hydrateUsersFromKnownSources([
      _mergeUserWithPublicCache(user),
    ]);
    final normalizedUser = hydratedUsers.isNotEmpty
        ? hydratedUsers.first
        : user;
    final timestamp = occurredAt ?? DateTime.now();

    _rememberInteractionTimestamp(normalizedUser.id, timestamp);

    switch (action) {
      case 'pass':
        likedUsers.removeWhere(
          (candidate) => candidate.id == normalizedUser.id,
        );
        if (!passedUsers.any(
          (candidate) => candidate.id == normalizedUser.id,
        )) {
          passedUsers.insert(0, normalizedUser);
        }
        break;
      case 'compliment':
      case 'like':
        passedUsers.removeWhere(
          (candidate) => candidate.id == normalizedUser.id,
        );
        if (!likedUsers.any((candidate) => candidate.id == normalizedUser.id)) {
          likedUsers.insert(0, normalizedUser);
        }
        break;
      default:
        return;
    }

    _interactionsFetchedAt = DateTime.now();

    if (matched) {
      _promoteUserToMatch(
        normalizedUser,
        matchId: matchId ?? _resolveMatchIdForUser(normalizedUser.id),
        occurredAt: timestamp,
      );
      return;
    }

    if (action == 'pass') {
      _removeIncomingLikeStateForIds(<String>[normalizedUser.id]);
    }

    _normalizeRelationshipBuckets();
    _persistInteractionsCache();
  }

  void undoOutgoingSwipe(String userId) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;

    likedUsers.removeWhere((candidate) => candidate.id == normalizedUserId);
    passedUsers.removeWhere((candidate) => candidate.id == normalizedUserId);
    interactionTimestamps.remove(normalizedUserId);
    _persistInteractionsCache();
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
    if (!_isRouteableUserId(normalizedUserId)) return seed;

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
        if (item.isBlurred) {
          // Blurred liked-me entries are server-locked placeholders. Never
          // hydrate them through the public profile endpoint.
          return item;
        }
        final hydratedUser = await _fetchPublicUserById(
          item.user.id,
          seed: item.user,
        );
        return WhoLikedMeItem(
          user: hydratedUser ?? item.user,
          type: item.type,
          complimentMessage: item.complimentMessage,
          createdAt: item.createdAt,
          isBlurred: item.isBlurred,
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

  List<MapEntry<String?, UserModel>> _extractMatchEvents(dynamic payload) {
    final records = _extractMatchRecordList(payload);
    final events = <MapEntry<String?, UserModel>>[];

    for (final raw in records) {
      if (raw is! Map) continue;
      final record = Map<String, dynamic>.from(raw);
      final parsedUser = _extractUserFromMatchRecord(record);
      if (parsedUser == null) continue;
      events.add(
        MapEntry<String?, UserModel>(
          MatchFoundPresentationGuard.extractMatchId(record),
          parsedUser,
        ),
      );
    }

    return events;
  }

  void _rememberMatchIdForUser(String userId, String? matchId) {
    final normalizedUserId = userId.trim();
    final normalizedMatchId = (matchId ?? '').trim();
    if (normalizedUserId.isEmpty || normalizedMatchId.isEmpty) {
      return;
    }
    _matchIdByUserId[normalizedUserId] = normalizedMatchId;
  }

  String? _resolveMatchIdForUser(String userId) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return null;
    final matchId = _matchIdByUserId[normalizedUserId]?.trim();
    if (matchId == null || matchId.isEmpty) return null;
    return matchId;
  }

  void _pruneMatchIdMappings(Iterable<UserModel> users) {
    final activeUserIds = users
        .map((user) => user.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    _matchIdByUserId.removeWhere(
      (userId, _) => !activeUserIds.contains(userId),
    );
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
    final blockedIds = _storage.getBlockedUserIds();
    return _mergeUniqueUsers(
      users.where(
        (u) =>
            u.id.isNotEmpty &&
            !_isCurrentUser(u) &&
            !blockedIds.contains(u.id.trim()) &&
            u.status.trim().toLowerCase() != 'blocked',
      ),
    );
  }

  void evictUsersByIds(Iterable<String> userIds) {
    final blockedIds = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (blockedIds.isEmpty) return;

    allUsers.removeWhere((user) => blockedIds.contains(user.id));
    nearbyUsers.removeWhere((user) => blockedIds.contains(user.id));
    liveTodayUsers.removeWhere((user) => blockedIds.contains(user.id));
    matches.removeWhere((user) => blockedIds.contains(user.id));
    likedUsers.removeWhere((user) => blockedIds.contains(user.id));
    passedUsers.removeWhere((user) => blockedIds.contains(user.id));
    likesReceived.removeWhere((item) => blockedIds.contains(item.user.id));
    if (whoLikedMeCount.value > likesReceived.length) {
      whoLikedMeCount.value = likesReceived.length;
    }
    recentConversations.removeWhere(
      (conversation) => blockedIds.contains(conversation.otherUser?.id ?? ''),
    );
    for (final userId in blockedIds) {
      _publicUserCache.remove(userId);
      _publicHydrationTasks.remove(userId);
      _matchIdByUserId.remove(userId);
    }
    _refreshLiveTodayUsers();
    _persistVisibleUsersCache();
  }

  void registerIncomingMatch(
    UserModel user, {
    String? matchId,
    DateTime? occurredAt,
    bool presentPopup = false,
  }) {
    if (user.id.trim().isEmpty || _isCurrentUser(user)) return;
    if (Get.isRegistered<ChatController>()) {
      Get.find<ChatController>().restoreConversationVisibilityForUser(user.id);
    }
    final hydratedUsers = _hydrateUsersFromKnownSources([
      _mergeUserWithPublicCache(user),
    ]);
    final normalizedUser = hydratedUsers.isNotEmpty
        ? hydratedUsers.first
        : user;
    final timestamp = occurredAt ?? DateTime.now();
    _promoteUserToMatch(
      normalizedUser,
      matchId: matchId,
      occurredAt: timestamp,
    );

    if (presentPopup) {
      _presentMatchFound(normalizedUser, matchId: matchId);
    }
  }

  void resetForLogout() {
    allUsers.clear();
    nearbyUsers.clear();
    liveTodayUsers.clear();
    backendCategories.clear();
    recentConversations.clear();
    matches.clear();
    likedUsers.clear();
    passedUsers.clear();
    likesReceived.clear();
    successStories.clear();
    whoLikedMeCount.value = 0;
    whoLikedMeRequiresPremium.value = false;
    interactionTimestamps.clear();
    compatibilityScores.clear();
    hasError.value = false;
    isLoading.value = false;
    isLoadingInteractions.value = false;
    isLoadingMatches.value = false;
    isLoadingWhoLikedMe.value = false;
    _interactionsFetchedAt = null;
    _whoLikedMeFetchedAt = null;
    _matchesFetchedAt = null;
    _hasFetchedMatchesOnce = false;
    _matchIdByUserId.clear();
    _publicUserCache.clear();
    _publicHydrationTasks.clear();
    MatchFoundPresentationGuard.resetRuntimeState();
  }

  Future<void> resetDiscoveryFeedForFilterRefresh({
    bool clearSeenHistory = false,
  }) async {
    _discoverFeedGeneration++;
    page.value = 1;
    hasMore.value = true;
    hasError.value = false;
    isLoadingMore.value = false;
    selectedCategory.value = 'all';
    allUsers.clear();
    nearbyUsers.clear();
    liveTodayUsers.clear();

    if (clearSeenHistory) {
      _seenUserIds.clear();
      await _storage.clearSeenDiscoverUserIds();
    }

    await _storage.clearAllUsersCache();
    isLoading.value = true;
    try {
      await fetchUsers(refresh: true);
    } finally {
      isLoading.value = false;
    }
  }

  void _persistVisibleUsersCache() {
    unawaited(
      _storage
          .cacheAllUsers(allUsers.map((u) => u.toJson()).toList())
          .catchError((_) {}),
    );
  }

  void _persistInteractionsCache() {
    unawaited(
      _storage
          .cacheLikedUsers(likedUsers.map((u) => u.toJson()).toList())
          .catchError((_) {}),
    );
    unawaited(
      _storage
          .cachePassedUsers(passedUsers.map((u) => u.toJson()).toList())
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

  bool isMatchedWithUser(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) return false;
    return matches.any((candidate) => candidate.id == normalized);
  }

  bool hasLikedUser(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) return false;
    return likedUsers.any((candidate) => candidate.id == normalized);
  }

  bool hasPassedUser(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) return false;
    return passedUsers.any((candidate) => candidate.id == normalized);
  }

  bool isSwipeInFlight(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) return false;
    return _swipeInFlight.contains(normalized);
  }

  bool isLikedByUser(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) return false;
    return likesReceived.any((item) => item.user.id == normalized);
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

  Map<String, dynamic> _buildSearchQueryParameters() {
    if (Get.isRegistered<HomeController>()) {
      return Get.find<HomeController>().buildDiscoverSearchParams(
        page: page.value,
        limit: 20,
      );
    }

    return {'page': page.value, 'limit': 20};
  }

  // â”€â”€â”€ All users (Primary Source: /search, Secondary: /matches/discover) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> fetchUsers({bool refresh = false}) async {
    if (_isFetchingUsersPage && !refresh) return;
    if (refresh) {
      page.value = 1;
      hasMore.value = true;
    }
    if (!hasMore.value && !refresh) return;
    final requestGeneration = _discoverFeedGeneration;
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
        queryParameters: _buildSearchQueryParameters(),
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

      if (requestGeneration != _discoverFeedGeneration) {
        debugPrint('[UsersController] Ignoring stale discover feed response');
        return;
      }

      if (refresh || page.value == 1) {
        final sanitized = _sanitizeDiscoverFeedUsers(mergedFirstPageUsers);
        if (sanitized.isNotEmpty) {
          allUsers.assignAll(sanitized);
          _persistVisibleUsersCache();
        } else if (allUsers.isEmpty) {
          allUsers.clear();
          liveTodayUsers.clear();
        }
      } else if (searchUsers.isNotEmpty) {
        allUsers.assignAll(
          _sanitizeDiscoverFeedUsers([...allUsers, ...searchUsers]),
        );
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
      _prefetchDiscoverFeedIfNeeded();
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
            final fallbackUsers = _sanitizeDiscoverFeedUsers([
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
    isLoadingMatches.value = true;
    try {
      final previousMatchIds = matches.map((user) => user.id).toSet();
      final response = await _api.get(ApiConstants.matches);
      final matchEvents = _extractMatchEvents(response.data);
      final extractedUsers = matchEvents.isNotEmpty
          ? matchEvents.map((event) => event.value).toList(growable: false)
          : _extractMatchUsers(response.data);
      final users = await _hydrateMissingUsersWithPublicProfiles(
        extractedUsers,
      );
      matches.assignAll(users);
      for (final event in matchEvents) {
        _rememberMatchIdForUser(event.value.id, event.key);
      }
      _pruneMatchIdMappings(users);
      _matchesFetchedAt = DateTime.now();
      _normalizeRelationshipBuckets();

      if (_hasFetchedMatchesOnce) {
        final newlyDetectedUsers = users
            .where((user) => !previousMatchIds.contains(user.id))
            .toList(growable: false);
        if (newlyDetectedUsers.isNotEmpty) {
          final firstNewUser = newlyDetectedUsers.first;
          final matchingEvent = matchEvents.firstWhereOrNull(
            (event) => event.value.id == firstNewUser.id,
          );
          _presentMatchFound(firstNewUser, matchId: matchingEvent?.key);
        }
      }

      _hasFetchedMatchesOnce = true;
      debugPrint('[UsersController] Found ${matches.length} matches');
    } catch (e) {
      debugPrint('[UsersController] fetchMatches error: $e');
    } finally {
      isLoadingMatches.value = false;
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
      final requiresPremium = data is Map && data['isPremiumFeature'] == true;

      final parsedItems = list
          .whereType<Map>()
          .map((entry) {
            final item = WhoLikedMeItem.fromJson(
              Map<String, dynamic>.from(entry),
            );
            if (!requiresPremium || item.isBlurred) return item;
            return WhoLikedMeItem(
              user: item.user,
              type: item.type,
              complimentMessage: null,
              createdAt: item.createdAt,
              isBlurred: true,
            );
          })
          .where(
            (item) =>
                item.user.id.isNotEmpty &&
                !_isCurrentUser(item.user) &&
                _isPositiveLikeType(item.type),
          )
          .toList();

      final hydratedItems = await _hydrateWhoLikedMeItems(parsedItems);
      final blockedIds = _storage.getBlockedUserIds();
      final visibleItems = hydratedItems
          .where((item) => !blockedIds.contains(item.user.id.trim()))
          .toList(growable: false);

      likesReceived.assignAll(visibleItems);
      whoLikedMeCount.value = data is Map
          ? (data['count'] as num?)?.toInt() ?? visibleItems.length
          : visibleItems.length;
      whoLikedMeRequiresPremium.value = requiresPremium;
      _whoLikedMeFetchedAt = DateTime.now();
      _normalizeRelationshipBuckets();

      for (final item in visibleItems) {
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

  void openUserDetail(UserModel user, {String? sourceTab}) {
    if (_isCurrentUser(user)) return;
    if (_isLockedPlaceholderUserId(user.id)) {
      _openLockedLikedMePaywall();
      return;
    }

    final hydrated = _hydrateUsersFromKnownSources([user]);
    final selected = hydrated.isNotEmpty ? hydrated.first : user;
    if (selected.id.isEmpty) {
      Get.snackbar('error'.tr, 'user_not_found'.tr);
      return;
    }
    if (_isLockedPlaceholderUserId(selected.id)) {
      _openLockedLikedMePaywall();
      return;
    }
    if (!_isRouteableUserId(selected.id)) {
      Get.snackbar('error'.tr, 'user_not_found'.tr);
      return;
    }

    unawaited(
      openUserDetailById(
        selected.id,
        fallbackUser: selected,
        showLoader: false,
        sourceTab: sourceTab,
      ),
    );
  }

  /// Opens user detail by fetching the profile from backend.
  Future<void> openUserDetailById(
    String userId, {
    UserModel? fallbackUser,
    bool showLoader = false,
    String? sourceTab,
  }) async {
    final normalizedSourceTab = sourceTab?.trim();
    final normalizedUserId = userId.trim();
    Map<String, dynamic> detailArguments(UserModel user) => {
      'user': user,
      if (normalizedSourceTab != null && normalizedSourceTab.isNotEmpty)
        'sourceTab': normalizedSourceTab,
    };

    if (_isLockedPlaceholderUserId(normalizedUserId)) {
      _openLockedLikedMePaywall();
      return;
    }
    if (!_isRouteableUserId(normalizedUserId)) {
      Get.snackbar('error'.tr, 'user_not_found'.tr);
      return;
    }

    if (_storage.getBlockedUserIds().contains(normalizedUserId)) {
      Get.snackbar('profile'.tr, 'This profile is unavailable.');
      return;
    }
    if (normalizedUserId.isEmpty) {
      if (fallbackUser != null && !_isCurrentUser(fallbackUser)) {
        Get.toNamed(
          AppRoutes.userDetail,
          arguments: detailArguments(fallbackUser),
        );
        return;
      }
      Get.snackbar('error'.tr, 'user_not_found'.tr);
      return;
    }

    var loaderShown = false;
    if (showLoader) {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      loaderShown = true;
    }
    try {
      final hydratedUser = await _fetchPublicUserById(
        normalizedUserId,
        seed: fallbackUser,
      );
      if (loaderShown && (Get.isDialogOpen ?? false)) {
        Get.back();
      }

      if (hydratedUser != null &&
          hydratedUser.id.isNotEmpty &&
          !_isCurrentUser(hydratedUser)) {
        Get.toNamed(
          AppRoutes.userDetail,
          arguments: detailArguments(hydratedUser),
        );
        return;
      }

      if (fallbackUser != null && !_isCurrentUser(fallbackUser)) {
        Get.toNamed(
          AppRoutes.userDetail,
          arguments: detailArguments(fallbackUser),
        );
        return;
      }

      Get.snackbar('error'.tr, 'user_not_found'.tr);
    } catch (e) {
      if (loaderShown && (Get.isDialogOpen ?? false)) {
        Get.back();
      }
      debugPrint('[UsersController] openUserDetailById error: $e');

      if (fallbackUser != null && !_isCurrentUser(fallbackUser)) {
        Get.toNamed(
          AppRoutes.userDetail,
          arguments: detailArguments(fallbackUser),
        );
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

  bool isLockedLikedMePlaceholder(String userId) =>
      _isLockedPlaceholderUserId(userId);

  bool _isRouteableUserId(String userId) =>
      _uuidPattern.hasMatch(userId.trim());

  bool _isLockedPlaceholderUserId(String userId) {
    final normalized = userId.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return normalized.startsWith('locked_like_') ||
        normalized.startsWith('locked_liked_me_') ||
        normalized.startsWith('placeholder_like_') ||
        (!_uuidPattern.hasMatch(normalized) && normalized.contains('locked'));
  }

  void _openLockedLikedMePaywall() {
    if (Get.currentRoute == AppRoutes.subscription) return;
    Get.toNamed(AppRoutes.subscription);
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
      _prefetchDiscoverFeedIfNeeded();
      if (matched && removedUser != null) {
        final matchId = MatchFoundPresentationGuard.extractMatchId(data);
        _promoteUserToMatch(
          removedUser,
          matchId: matchId,
          occurredAt: DateTime.now(),
        );
        _presentMatchFound(removedUser, matchId: matchId);
      } else if (removedUser != null) {
        _interactionsFetchedAt = DateTime.now();
        _normalizeRelationshipBuckets();
      }
      _refreshRelationshipSurfaces(includeChat: matched);
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

  Future<void> _deleteMatchWithFallback(
    String userId, {
    String? matchId,
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedMatchId = (matchId ?? '').trim();
    if (normalizedUserId.isEmpty) return;

    if (normalizedMatchId.isNotEmpty && normalizedMatchId != normalizedUserId) {
      try {
        await _api.delete(ApiConstants.unmatch(normalizedMatchId));
        return;
      } catch (e) {
        debugPrint(
          '[UsersController] unmatch via matchId failed for $normalizedUserId (matchId=$normalizedMatchId): $e',
        );
      }
    }

    await _api.delete(ApiConstants.unmatch(normalizedUserId));
  }

  Future<bool> unmatchUser(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return false;

    final chatController = Get.isRegistered<ChatController>()
        ? Get.find<ChatController>()
        : null;

    var resolvedMatchId = _resolveMatchIdForUser(normalizedUserId);
    if (resolvedMatchId == null || resolvedMatchId.isEmpty) {
      await fetchMatches();
      resolvedMatchId = _resolveMatchIdForUser(normalizedUserId);
    }

    evictUsersByIds({normalizedUserId});
    if (chatController != null) {
      await chatController.deleteConversationForUser(
        normalizedUserId,
        remoteDelete: true,
      );
    }

    try {
      await _deleteMatchWithFallback(
        normalizedUserId,
        matchId: resolvedMatchId,
      );
      MatchFoundPresentationGuard.clearDismissal(
        matchId: resolvedMatchId,
        userId: normalizedUserId,
      );
      _matchIdByUserId.remove(normalizedUserId);
      await Future.wait([
        fetchMatches(),
        fetchInteractions(),
        fetchWhoLikedMe(),
      ]);
      return true;
    } catch (e) {
      debugPrint('[UsersController] unmatchUser error: $e');
      await Future.wait([
        fetchMatches(),
        fetchInteractions(),
        fetchWhoLikedMe(),
      ]);
      Get.snackbar('error'.tr, 'Unable to remove this match right now.');
      return false;
    }
  }

  Future<void> refreshUsers() async {
    await ensureUsersTabData(force: true);
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
