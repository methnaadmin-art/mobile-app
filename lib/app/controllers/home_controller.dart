import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:methna_app/app/data/services/notification_service.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/utils/helpers.dart';

import 'package:methna_app/app/data/services/location_service.dart';
import 'package:methna_app/app/data/services/storage_service.dart';
import 'package:methna_app/app/data/models/category_model.dart';
import 'package:methna_app/app/data/models/success_story_model.dart';

class HomeController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  final AuthService _auth = Get.find<AuthService>();
  final MonetizationService _monetization = Get.find<MonetizationService>();
  final LocationService _location = Get.find<LocationService>();
  final StorageService _storage = Get.find<StorageService>();
  final NotificationService _notificationService = Get.find<NotificationService>();

  final RxList<UserModel> discoverUsers = <UserModel>[].obs;
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxList<SuccessStoryModel> successStories = <SuccessStoryModel>[].obs;
  final RxString selectedCategoryId = ''.obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingCategories = false.obs;
  final RxBool isLoadingStories = false.obs;
  final RxBool isEmpty = false.obs;
  final RxBool hasError = false.obs;
  final RxInt currentCardIndex = 0.obs;
  final RxBool locationGranted = true.obs;

  // Filter state
  final RxInt minAge = 18.obs;
  final RxInt maxAge = 45.obs;
  final RxDouble maxDistance = 50.0.obs;
  final RxString genderFilter = 'all'.obs;
  final RxString educationFilter = ''.obs;
  final RxString religiousLevelFilter = ''.obs;
  final RxString prayerFrequencyFilter = ''.obs;
  final RxString marriageIntentionFilter = ''.obs;
  final RxString livingSituationFilter = ''.obs;
  final RxList<String> interestsFilter = <String>[].obs;
  final RxBool verifiedOnlyFilter = false.obs;
  final RxBool goGlobalFilter = false.obs;
  final RxBool useKm = true.obs;

  // Pagination
  final RxInt _page = 1.obs;
  final RxBool _hasMore = true.obs;
  final RxBool _isLoadingMore = false.obs;
  final Set<String> _seenUserIds = {};

  // Rewind tracking
  final Rx<UserModel?> lastSwipedUser = Rx<UserModel?>(null);

  // Baraka Meter scores: userId -> {score, level}
  final RxMap<String, Map<String, dynamic>> barakaScores = <String, Map<String, dynamic>>{}.obs;

  // Daily Insight
  final RxString dailyInsightContent = ''.obs;
  final RxString dailyInsightAuthor = ''.obs;
  final RxBool dailyInsightDismissed = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadFilters();
    _loadCachedUsersInstantly();
    fetchAllInitialData();
  }

  /// Load cached discover users from local storage for instant display
  void _loadCachedUsersInstantly() {
    try {
      final cached = _storage.getCachedDiscoverUsers();
      if (cached != null && cached.isNotEmpty) {
        final users = cached.map((json) => UserModel.fromJson(json)).toList();
        discoverUsers.value = users;
        isEmpty.value = false;
        debugPrint('[Home] Loaded ${users.length} cached users instantly');
      }
    } catch (e) {
      debugPrint('[Home] Failed to load cached users: $e');
    }
  }

  Future<void> fetchAllInitialData() async {
    // Fire all initial fetches in parallel — don't await individually
    Future.wait([
      fetchDiscoverUsers(),
      fetchCategories(),
      fetchSuccessStories(),
      _monetization.fetchStatus(),
      fetchDailyInsight(),
    ], eagerError: false);
  }

  void _loadFilters() {
    minAge.value = _storage.getString('filter_minAge') != null ? int.parse(_storage.getString('filter_minAge')!) : 18;
    maxAge.value = _storage.getString('filter_maxAge') != null ? int.parse(_storage.getString('filter_maxAge')!) : 45;
    maxDistance.value = _storage.getString('filter_maxDistance') != null ? double.parse(_storage.getString('filter_maxDistance')!) : 50.0;
    genderFilter.value = _storage.getString('filter_gender') ?? 'all';
    educationFilter.value = _storage.getString('filter_education') ?? '';
    religiousLevelFilter.value = _storage.getString('filter_religiousLevel') ?? '';
    prayerFrequencyFilter.value = _storage.getString('filter_prayerFrequency') ?? '';
    marriageIntentionFilter.value = _storage.getString('filter_marriageIntention') ?? '';
    livingSituationFilter.value = _storage.getString('filter_livingSituation') ?? '';
    verifiedOnlyFilter.value = _storage.getBool('filter_verifiedOnly') ?? false;
    goGlobalFilter.value = _storage.getBool('filter_goGlobal') ?? false;
    debugPrint('[Home] _loadFilters: loaded all filters from storage');
  }

  Future<void> saveFilters() async {
    await _storage.saveString('filter_minAge', minAge.value.toString());
    await _storage.saveString('filter_maxAge', maxAge.value.toString());
    await _storage.saveString('filter_maxDistance', maxDistance.value.toString());
    await _storage.saveString('filter_gender', genderFilter.value);
    await _storage.saveString('filter_education', educationFilter.value);
    await _storage.saveString('filter_religiousLevel', religiousLevelFilter.value);
    await _storage.saveString('filter_prayerFrequency', prayerFrequencyFilter.value);
    await _storage.saveString('filter_marriageIntention', marriageIntentionFilter.value);
    await _storage.saveString('filter_livingSituation', livingSituationFilter.value);
    await _storage.saveBool('filter_verifiedOnly', verifiedOnlyFilter.value);
    await _storage.saveBool('filter_goGlobal', goGlobalFilter.value);
    debugPrint('[Home] saveFilters: persisted all filters');
  }

  /// Called from the "Enable Location" button — requests permission with
  /// user feedback dialogs, then fetches discover users.
  Future<void> requestLocationAndFetch() async {
    final position = await _location.requestLocationWithFeedback();
    if (position != null) {
      locationGranted.value = true;
      fetchDiscoverUsers();
    }
  }

  Map<String, dynamic> get _filterParams => {
    'limit': 20,
    if (genderFilter.value != 'all') 'gender': genderFilter.value,
    'minAge': minAge.value,
    'maxAge': maxAge.value,
    if (!goGlobalFilter.value && locationGranted.value) 'maxDistance': maxDistance.value.round(),
    if (educationFilter.value.isNotEmpty) 'education': educationFilter.value,
    if (religiousLevelFilter.value.isNotEmpty) 'religiousLevel': religiousLevelFilter.value,
    if (prayerFrequencyFilter.value.isNotEmpty) 'prayerFrequency': prayerFrequencyFilter.value,
    if (marriageIntentionFilter.value.isNotEmpty) 'marriageIntention': marriageIntentionFilter.value,
    if (livingSituationFilter.value.isNotEmpty) 'livingSituation': livingSituationFilter.value,
    if (interestsFilter.isNotEmpty) 'interests': interestsFilter.toList(),
    if (verifiedOnlyFilter.value) 'verifiedOnly': true,
  };

  Future<void> refreshDiscoverUsers() => fetchDiscoverUsers(forceRefresh: true);

  Future<void> fetchDiscoverUsers({bool forceRefresh = false}) async {
    if (isLoading.value) return; // Prevent duplicate calls
    isLoading.value = true;
    hasError.value = false;
    _page.value = 1;
    _hasMore.value = true;
    _seenUserIds.clear();
    debugPrint('[Home] fetchDiscoverUsers: starting (forceRefresh=$forceRefresh)...');

    // Check location but do NOT block discovery — fetch users regardless
    final hasPerm = await _location.checkPermission();
    locationGranted.value = hasPerm;
    debugPrint('[Home] fetchDiscoverUsers: locationGranted=$hasPerm');

    try {
      // Add timeout to prevent hanging
      final users = await _fetchPage(1, forceRefresh: forceRefresh).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw TimeoutException('Request timeout while fetching users');
        },
      );
      
      discoverUsers.value = users;
      for (final u in users) {
        _seenUserIds.add(u.id);
      }
      isEmpty.value = discoverUsers.isEmpty;
      currentCardIndex.value = 0;
      debugPrint('[Home] fetchDiscoverUsers: loaded ${users.length} users');

      // Cache users locally for instant display on next app launch
      if (users.isNotEmpty) {
        _storage.cacheDiscoverUsers(users.map((u) => u.toJson()).toList()).catchError((_) {});
      }
      
      // Fetch Baraka scores for loaded users (with error handling)
      if (users.isNotEmpty) {
        _fetchBulkBaraka(users.map((u) => u.id).toList()).catchError((e) {
          debugPrint('[Home] Failed to fetch Baraka scores: $e');
        });
      }
    } catch (e, stackTrace) {
      debugPrint('[Home] fetchDiscoverUsers ERROR: $e');
      debugPrint('[Home] fetchDiscoverUsers STACK: $stackTrace');
      
      // Extract detailed error info from DioException
      if (e is DioException) {
        debugPrint('[Home] fetchDiscoverUsers HTTP STATUS: ${e.response?.statusCode}');
        debugPrint('[Home] fetchDiscoverUsers RESPONSE BODY: ${e.response?.data}');
        debugPrint('[Home] fetchDiscoverUsers REQUEST URL: ${e.requestOptions.uri}');
      }
      
      hasError.value = true;
      // Only show empty if we have no cached users displayed
      if (discoverUsers.isEmpty) {
        isEmpty.value = true;
      }
      // Silently log error — don't show snackbar on initial load
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<UserModel>> _fetchPage(int page, {bool forceRefresh = false}) async {
    debugPrint('[Home] _fetchPage($page): params=${_filterParams}');
    final response = await _api.get(ApiConstants.search, queryParameters: {
      ..._filterParams,
      'page': page,
      if (forceRefresh) 'forceRefresh': true,
    });
    final data = response.data;
    debugPrint('[Home] _fetchPage($page): response type=${data.runtimeType}');

    // Robustly extract the users list from various response shapes
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      list = (data['users'] ?? data['results'] ?? data['profiles'] ?? []) as List;
    } else {
      debugPrint('[Home] _fetchPage($page): unexpected data=$data');
      list = [];
    }

    final currentUser = _auth.currentUser.value;
    final users = list
        .whereType<Map<String, dynamic>>()
        .map((u) => UserModel.fromJson(u))
        .where((u) => u.id != currentUser?.id) // Filter out current user
        .toList();
    
    // Deduplicate and filter out already seen users
    users.removeWhere((u) => _seenUserIds.contains(u.id));
    if (users.isEmpty) _hasMore.value = false;
    debugPrint('[Home] _fetchPage($page): parsed ${users.length} users after filtering');
    return users;
  }

  Future<void> loadMoreUsers() async {
    if (_isLoadingMore.value || !_hasMore.value) return;
    _isLoadingMore.value = true;
    debugPrint('[Home] loadMoreUsers: page=${_page.value + 1}');
    try {
      _page.value++;
      final moreUsers = await _fetchPage(_page.value);
      for (final u in moreUsers) {
        _seenUserIds.add(u.id);
      }
      discoverUsers.addAll(moreUsers);
      debugPrint('[Home] loadMoreUsers: loaded ${moreUsers.length} more users');
      // Fetch Baraka for new users
      if (moreUsers.isNotEmpty) {
        _fetchBulkBaraka(moreUsers.map((u) => u.id).toList());
      }
    } catch (e) {
      debugPrint('[Home] loadMoreUsers ERROR: $e');
      // Revert page increment on failure so retry fetches the same page
      _page.value--;
    } finally {
      _isLoadingMore.value = false;
    }
  }

  Future<void> likeUser(String userId) async {
    debugPrint('[Home] likeUser: $userId');
    try {
      final response = await _api.post(ApiConstants.swipe, data: {
        'targetUserId': userId,
        'action': 'like',
      });
      final isMatch = response.data?['matched'] ?? false;
      debugPrint('[Home] likeUser response: matched=$isMatch');
      _removeCurrentCard();
      if (isMatch) {
        final matchedUser = discoverUsers.firstWhereOrNull((u) => u.id == userId)
            ?? lastSwipedUser.value;
        Get.toNamed(AppRoutes.matchFound, arguments: {
          'user': matchedUser,
        });
      }
    } catch (e) {
      debugPrint('[Home] likeUser ERROR: $e');
      Helpers.showSnackbar(message: Helpers.extractErrorMessage(e), isError: true);
    }
  }


  Future<void> passUser(String userId) async {
    debugPrint('[Home] passUser: $userId');
    try {
      await _api.post(ApiConstants.swipe, data: {
        'targetUserId': userId,
        'action': 'pass',
      });
      _removeCurrentCard();
    } catch (e) {
      debugPrint('[Home] passUser ERROR: $e');
      // Still remove the card — pass failures shouldn't block swiping
      _removeCurrentCard();
    }
  }

  Future<void> complimentUser(String userId, String message) async {
    debugPrint('[Home] complimentUser: $userId');
    try {
      final response = await _api.post(ApiConstants.swipe, data: {
        'targetUserId': userId,
        'action': 'compliment',
        'complimentMessage': message,
      });
      final isMatch = response.data?['matched'] ?? false;
      debugPrint('[Home] complimentUser response: matched=$isMatch');
      _removeCurrentCard();
      if (isMatch) {
        final matchedUser = discoverUsers.firstWhereOrNull((u) => u.id == userId)
            ?? lastSwipedUser.value;
        Get.toNamed(AppRoutes.matchFound, arguments: {
          'user': matchedUser,
        });
      }
    } catch (e) {
      debugPrint('[Home] complimentUser ERROR: $e');
      // Still remove on error
      _removeCurrentCard();
      Helpers.showSnackbar(message: Helpers.extractErrorMessage(e), isError: true);
    }
  }

  void _removeCurrentCard() {
    if (discoverUsers.isNotEmpty) {
      final idx = currentCardIndex.value.clamp(0, discoverUsers.length - 1);
      lastSwipedUser.value = discoverUsers[idx];
      discoverUsers.removeAt(idx);
      // Adjust index if we removed the last item in the list
      if (currentCardIndex.value >= discoverUsers.length && discoverUsers.isNotEmpty) {
        currentCardIndex.value = discoverUsers.length - 1;
      }
      if (discoverUsers.isEmpty) {
        isEmpty.value = true;
      }
      // Auto-load more users when running low
      if (discoverUsers.length < 5 && _hasMore.value) {
        loadMoreUsers();
      }
    }
  }


  Future<void> rewindLastSwipe() async {
    if (lastSwipedUser.value == null) {
      Helpers.showSnackbar(message: 'No swipe to undo');
      return;
    }
    try {
      final result = await _monetization.useRewind();
      if (result != null) {
        // Re-insert the user at the top of the stack
        discoverUsers.insert(0, lastSwipedUser.value!);
        isEmpty.value = false;
        lastSwipedUser.value = null;
        Helpers.showSnackbar(message: 'Swipe undone!');
      }
    } catch (e) {
      Helpers.showSnackbar(message: 'Cannot rewind right now', isError: true);
    }
  }

  // ─── Rematch / Second Chance ────────────────────────────
  Future<void> requestRematch(String targetUserId) async {
    try {
      final success = await _monetization.requestRematch(targetUserId);
      if (success) {
        Helpers.showSnackbar(message: 'Rematch request sent!');
      } else {
        Helpers.showSnackbar(message: 'Cannot send rematch request', isError: true);
      }
    } catch (e) {
      Helpers.showSnackbar(message: 'Failed to send rematch', isError: true);
    }
  }

  // ─── Fetch Recommendations ────────────────────────────
  final RxList<UserModel> recommendedUsers = <UserModel>[].obs;

  Future<void> fetchRecommendations() async {
    try {
      final response = await _api.get(ApiConstants.recommendedForYou);
      final list = response.data is List ? response.data : response.data['users'] ?? [];
      recommendedUsers.value = (list as List).map((u) => UserModel.fromJson(u)).toList();
    } catch (_) {}
  }

  // ─── Baraka Meter ───────────────────────────
  Future<void> _fetchBulkBaraka(List<String> userIds) async {
    if (userIds.isEmpty) return;
    try {
      final response = await _api.post(ApiConstants.barakaBulk, data: {
        'targetUserIds': userIds,
      });
      if (response.data is Map) {
        final map = response.data as Map<String, dynamic>;
        for (final entry in map.entries) {
          if (entry.value is Map) {
            barakaScores[entry.key] = Map<String, dynamic>.from(entry.value);
          }
        }
      }
    } catch (_) {}
  }

  int getBarakaScore(String userId) {
    return (barakaScores[userId]?['score'] as num?)?.toInt() ?? 0;
  }

  String getBarakaLevel(String userId) {
    return barakaScores[userId]?['level']?.toString() ?? 'low';
  }

  // ─── Daily Insight ──────────────────────────
  Future<void> fetchDailyInsight() async {
    try {
      final response = await _api.get(ApiConstants.dailyInsight);
      final data = response.data;
      if (data is Map) {
        dailyInsightContent.value = data['content']?.toString() ?? '';
        dailyInsightAuthor.value = data['author']?.toString() ?? '';
      }
    } catch (_) {}
  }

  // ─── Categories & Stories ───────────────────────────
  Future<void> fetchCategories() async {
    try {
      isLoadingCategories.value = true;
      final response = await _api.get(ApiConstants.categories);
      final list = response.data is List ? response.data : response.data['categories'] ?? [];
      categories.value = (list as List).map((c) => CategoryModel.fromJson(c)).toList();
    } catch (e) {
      debugPrint('[Home] fetchCategories error: $e');
    } finally {
      isLoadingCategories.value = false;
    }
  }

  Future<void> fetchSuccessStories() async {
    try {
      isLoadingStories.value = true;
      final response = await _api.get(ApiConstants.successStories);
      final list = response.data is List ? response.data : response.data['stories'] ?? [];
      successStories.value = (list as List).map((s) => SuccessStoryModel.fromJson(s)).toList();
    } catch (e) {
      debugPrint('[Home] fetchSuccessStories error: $e');
    } finally {
      isLoadingStories.value = false;
    }
  }

  Future<void> selectCategory(String categoryId) async {
    if (selectedCategoryId.value == categoryId) {
      selectedCategoryId.value = ''; // Deselect
      fetchDiscoverUsers();
      return;
    }
    selectedCategoryId.value = categoryId;
    fetchUsersByCategory(categoryId);
  }

  Future<void> fetchUsersByCategory(String categoryId) async {
    isLoading.value = true;
    _page.value = 1;
    _seenUserIds.clear();
    try {
      final response = await _api.get(ApiConstants.categoryUsers(categoryId));
      final list = response.data is List ? response.data : response.data['users'] ?? [];
      discoverUsers.value = (list as List).map((u) => UserModel.fromJson(u)).toList();
      isEmpty.value = discoverUsers.isEmpty;
    } catch (e) {
      debugPrint('[Home] fetchUsersByCategory error: $e');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  void dismissDailyInsight() {
    dailyInsightDismissed.value = true;
  }

  // ─── Profile View Recording ───────────────────────────
  Future<void> recordProfileView(String userId) async {
    try {
      await _api.post(ApiConstants.recordProfileView(userId));
    } catch (_) {}
  }

  void openFilter() => Get.toNamed(AppRoutes.filter);
  void openNotifications() => _notificationService.openNotifications();
  void openProfile() => Get.toNamed(AppRoutes.profile);

  bool get canRewind => _monetization.canRewind.value && lastSwipedUser.value != null;
  int get remainingLikes => _monetization.remainingLikes.value;
  bool get isUnlimitedLikes => _monetization.isUnlimitedLikes.value;
  bool get isPremium => _monetization.isPremium;
  UserModel? get currentUser => _auth.currentUser.value;
}
