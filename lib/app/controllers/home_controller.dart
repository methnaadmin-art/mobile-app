import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/controllers/chat_controller.dart';
import 'package:methna_app/app/controllers/navigation_controller.dart';
import 'package:methna_app/app/controllers/users_controller.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:methna_app/app/data/services/notification_service.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/utils/auth_navigation_resolver.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/constants/app_constants.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/utils/match_found_presentation_guard.dart';
import 'package:methna_app/core/services/trial_manager.dart';
import 'package:methna_app/screens/main/home/match_found_screen.dart';

import 'package:methna_app/app/data/services/location_service.dart';
import 'package:methna_app/app/data/services/storage_service.dart';
import 'package:methna_app/app/data/models/category_model.dart';
import 'package:methna_app/app/data/models/success_story_model.dart';

class _RemovedSwipeCard {
  const _RemovedSwipeCard({
    required this.user,
    required this.originalIndex,
    this.nextUserId,
    this.nextUser,
  });

  final UserModel user;
  final int originalIndex;
  final String? nextUserId;
  final UserModel? nextUser;
}

class _SwipeHistoryEntry {
  const _SwipeHistoryEntry({
    required this.user,
    required this.action,
    required this.originalIndex,
    required this.occurredAt,
    this.nextUserId,
    this.nextUser,
    this.matchId,
    this.matched = false,
  });

  final UserModel user;
  final String action;
  final int originalIndex;
  final DateTime occurredAt;
  final String? nextUserId;
  final UserModel? nextUser;
  final String? matchId;
  final bool matched;
}

class HomeController extends GetxController with WidgetsBindingObserver {
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static const double distanceFilterMinKm = 20.0;
  static const double defaultDistanceFilterKm = 50.0;
  static const double distanceFilterUnlimitedKm = 400.0;
  static const int defaultMinAgeFilter = 18;
  static const int defaultMaxAgeFilter = 90;
  static const int _discoverInitialBufferSize = 20;
  static const int _discoverPrefetchThreshold = 7;
  static const int _discoverMaxEnsureAttempts = 2;
  static const int _maxDiscoverExcludeIds = 300;
  static const int _maxSwipeHistoryEntries = 60;
  static const Duration _discoverRequestTimeout = Duration(seconds: 8);
  static const String _discoverCurrentIndexStorageKey =
      'discover_current_index_v1';
  static const String _discoverNextCursorStorageKey = 'discover_next_cursor_v1';
  static const String _discoverHasMoreStorageKey = 'discover_has_more_v1';
  static const String _countryFilterUserSetKey = 'filter_country_user_set';
  static const String _distanceFilterUserSetKey = 'filter_distance_user_set';
  static const List<String> _timeFrameValues = <String>[
    '',
    'within_months',
    'within_year',
    'one_to_two_years',
    'not_sure',
    'just_exploring',
  ];
  static const Map<String, int> _legacyIntentToTimeFrameIndex = <String, int>{
    'family_introduction': 1,
    'serious_marriage': 2,
    'exploring': 5,
  };

  final ApiService _api = Get.find<ApiService>();
  final AuthService _auth = Get.find<AuthService>();
  final MonetizationService _monetization = Get.find<MonetizationService>();
  final LocationService _location = Get.find<LocationService>();
  final StorageService _storage = Get.find<StorageService>();
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  void _presentMatchFound(UserModel? matchedUser, {String? matchId}) {
    if (matchedUser == null || matchedUser.id.isEmpty) return;
    if (!MatchFoundPresentationGuard.beginPresentation(
      matchId: matchId,
      userId: matchedUser.id,
    )) {
      return;
    }
    debugPrint(
      '[Home] Presenting match overlay for ${matchedUser.id} (matchId=${matchId ?? 'unknown'})',
    );
    // Preload the next batch of cards while the match overlay is visible,
    // so the user never sees an empty deck when they dismiss the overlay.
    unawaited(ensureDiscoverBufferReady());
    unawaited(
      MatchFoundScreen.showOverlay(matchedUser).then((displayed) async {
        MatchFoundPresentationGuard.endPresentation(markDismissed: displayed);
        // Safety net: refill again if the preload did not complete in time.
        await ensureDiscoverBufferReady();
      }),
    );
  }

  final TrialManager trialManager = Get.find<TrialManager>();

  final CardSwiperController swiperController = CardSwiperController();

  final RxList<UserModel> discoverUsers = <UserModel>[].obs;
  final Rx<Map<String, dynamic>?> featuredAd = Rx<Map<String, dynamic>?>(null);
  final RxBool isLoadingFeaturedAd = false.obs;
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxList<SuccessStoryModel> successStories = <SuccessStoryModel>[].obs;
  final RxString selectedCategoryId = ''.obs;

  final RxBool isLoading = false.obs;
  final RxBool isInitializing = false.obs;
  final RxBool isLoadingCategories = false.obs;
  final RxBool isLoadingStories = false.obs;
  final RxBool isEmpty = false.obs;
  final RxBool hasError = false.obs;
  final RxInt currentCardIndex = 0.obs;
  final RxBool locationGranted = false.obs;
  final RxBool showLocationGate = false.obs;
  final RxBool showStartupRadar = false.obs;
  final RxBool showSwipeTutorial = false.obs;
  final RxString swipeButtonCue = ''.obs;
  final RxMap<String, int> cardPhotoIndices = <String, int>{}.obs;
  final RxMap<String, bool> cardDetailsExpanded = <String, bool>{}.obs;

  // Filter state
  final RxInt minAge = defaultMinAgeFilter.obs;
  final RxInt maxAge = defaultMaxAgeFilter.obs;
  final RxDouble maxDistance = defaultDistanceFilterKm.obs;
  final RxBool distanceFilterUserSet = false.obs;
  final RxString genderFilter = 'all'.obs;
  final RxString countryFilter = ''.obs;
  final RxString countryCodeFilter = ''.obs;
  final RxBool countryFilterUserSet = false.obs;
  final RxString cityFilter = ''.obs;
  final RxString maritalStatusFilter = ''.obs;
  final RxString ethnicityFilter = ''.obs;
  final RxString educationFilter = ''.obs;
  final RxString religiousLevelFilter = ''.obs;
  final RxString prayerFrequencyFilter = ''.obs;
  final RxString marriageIntentionFilter = ''.obs;
  final RxInt timeFrameIndex = 0.obs;
  final RxString livingSituationFilter = ''.obs;
  final RxList<String> interestsFilter = <String>[].obs;
  final RxList<String> languagesFilter = <String>[].obs;
  final RxList<String> familyValuesFilter = <String>[].obs;
  final RxList<String> communicationStylesFilter = <String>[].obs;
  final RxBool verifiedOnlyFilter = false.obs;
  final RxBool goGlobalFilter = false.obs;
  final RxBool useKm = true.obs;
  final RxBool recentlyActiveOnlyFilter = false.obs;
  final RxBool withPhotosOnlyFilter = false.obs;
  final RxInt minTrustScoreFilter = 0.obs;
  final RxBool backgroundCheckOnlyFilter = false.obs;
  final RxBool isApplyingFilters = false.obs;

  // Pagination
  final RxInt _page = 1.obs;
  final RxBool _hasMore = true.obs;
  final RxBool _isLoadingMore = false.obs;
  final Set<String> _seenUserIds = {};
  String? _discoverNextCursor;
  bool _pendingForceRefreshAfterLoad = false;
  Timer? _liveFilterRefreshTimer;

  // Rewind tracking
  final Rx<UserModel?> lastSwipedUser = Rx<UserModel?>(null);
  final List<_SwipeHistoryEntry> _swipeHistoryStack = <_SwipeHistoryEntry>[];
  Future<void> _swipeMutationQueue = Future<void>.value();
  bool _isRewindInFlight = false;

  // Baraka Meter scores: userId -> {score, level}
  final RxMap<String, Map<String, dynamic>> barakaScores =
      <String, Map<String, dynamic>>{}.obs;

  // Compatibility scores: userId -> score (0-100)
  final RxMap<String, int> compatibilityScores = <String, int>{}.obs;
  // Daily Insight
  final RxString dailyInsightContent = ''.obs;
  final RxString dailyInsightAuthor = ''.obs;
  final RxBool dailyInsightDismissed = false.obs;
  Worker? _currentUserWorker;
  Worker? _passportLocationWorker;
  Timer? _startupRadarTimer;
  Timer? _swipeTutorialTimer;
  DateTime? _startupRadarStartedAt;
  bool _startupFlowHandled = false;
  bool _startupRadarDismissScheduled = false;
  String? _lastViewerVerificationUserId;
  bool? _lastViewerSelfieVerified;
  String? _lastPassportDiscoverySignature;

  // Behavior-based recommendation signals (client-side learning)
  static const String _behaviorSignalsStorageKey =
      'matching_behavior_signals_v1';
  static bool _startupRadarShownThisLaunch = false;
  final Map<String, double> _likedInterestWeights = <String, double>{};
  final Map<String, double> _passedInterestWeights = <String, double>{};
  final Set<String> _trackedAdImpressions = <String>{};
  double _preferredAgeCenter = 0;
  double _preferredDistanceKm = 0;
  int _positiveSignalCount = 0;
  int _negativeSignalCount = 0;
  int _swipeButtonCueVersion = 0;
  int _swipeCount = 0;
  final RxBool showAdOverlay = false.obs;

  /// Call after each user swipe. Returns true if an ad should be shown.
  bool incrementSwipeCount() {
    _swipeCount++;
    // Show ad after 1st swipe, then every 4 swipes
    final shouldShow = _swipeCount == 1 || (_swipeCount - 1) % 4 == 0;
    if (shouldShow) {
      showAdOverlay.value = true;
    }
    return shouldShow;
  }

  void dismissAdOverlay() {
    showAdOverlay.value = false;
  }

  void triggerSwipeButtonCue(String action) {
    final normalized = action.trim().toLowerCase();
    if (normalized.isEmpty) return;

    swipeButtonCue.value = normalized;
    final cueVersion = ++_swipeButtonCueVersion;

    Future.delayed(const Duration(milliseconds: 720), () {
      if (_swipeButtonCueVersion != cueVersion) return;
      if (swipeButtonCue.value == normalized) {
        swipeButtonCue.value = '';
      }
    });
  }

  int cardPhotoIndexFor(String userId, int photoCount) {
    if (photoCount <= 0) return 0;
    final raw = cardPhotoIndices[userId] ?? 0;
    final normalized = raw.clamp(0, photoCount - 1).toInt();
    if (raw != normalized) {
      cardPhotoIndices[userId] = normalized;
    }
    return normalized;
  }

  void nextCardPhoto(String userId, int photoCount) {
    if (photoCount <= 1) return;
    final current = cardPhotoIndexFor(userId, photoCount);
    cardPhotoIndices[userId] = (current + 1) % photoCount;
  }

  void previousCardPhoto(String userId, int photoCount) {
    if (photoCount <= 1) return;
    final current = cardPhotoIndexFor(userId, photoCount);
    cardPhotoIndices[userId] = (current - 1 + photoCount) % photoCount;
  }

  bool isCardDetailsExpanded(String userId) {
    return cardDetailsExpanded[userId] ?? false;
  }

  void setCardDetailsExpanded(String userId, bool expanded) {
    cardDetailsExpanded[userId] = expanded;
  }

  @override
  void onInit() {
    super.onInit();
    debugPrint('[Home] onInit');
    WidgetsBinding.instance.addObserver(this);
    _seenUserIds.addAll(_storage.getSeenDiscoverUserIds());
    _restorePersistedDiscoverDeckMeta();
    _loadCachedUsersInstantly();
    final initialViewer = _auth.currentUser.value;
    _lastViewerVerificationUserId = initialViewer?.id.trim();
    _lastViewerSelfieVerified = initialViewer?.selfieVerified;
    _currentUserWorker = ever<UserModel?>(_auth.currentUser, (user) {
      final normalizedViewerId = user?.id.trim();
      final normalizedSelfieVerified = user?.selfieVerified ?? false;
      final selfieVerificationChanged =
          normalizedViewerId != null &&
          normalizedViewerId.isNotEmpty &&
          _lastViewerVerificationUserId == normalizedViewerId &&
          _lastViewerSelfieVerified != null &&
          _lastViewerSelfieVerified != normalizedSelfieVerified;

      _lastViewerVerificationUserId = normalizedViewerId;
      _lastViewerSelfieVerified = normalizedSelfieVerified;

      final sanitizedUsers = _sanitizeDiscoverUsers(discoverUsers);
      if (sanitizedUsers.length != discoverUsers.length) {
        discoverUsers.assignAll(sanitizedUsers);
        isEmpty.value = discoverUsers.isEmpty;
      }

      if (selfieVerificationChanged) {
        unawaited(_refreshDiscoveryForViewerVerificationChange());
        return;
      }

      if (discoverUsers.isEmpty && !isLoading.value) {
        unawaited(fetchDiscoverUsers());
      }
    });
    _lastPassportDiscoverySignature = _passportDiscoverySignature(
      _monetization.passportLocation.value,
    );
    _passportLocationWorker = ever<Map<String, dynamic>?>(
      _monetization.passportLocation,
      (location) {
        final nextSignature = _passportDiscoverySignature(location);
        if (_lastPassportDiscoverySignature == nextSignature) {
          return;
        }
        _lastPassportDiscoverySignature = nextSignature;
        unawaited(_refreshDiscoveryForPassportLocationChange());
      },
    );
    _loadFilters();
    _loadBehaviorSignals();
    unawaited(fetchFeaturedAd());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapAfterAuthRestore());
    });
  }

  @override
  void onReady() {
    super.onReady();
    if (_startupFlowHandled) return;
    _startupFlowHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_handleStartupEntryFlow());
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _liveFilterRefreshTimer?.cancel();
    _startupRadarTimer?.cancel();
    _swipeTutorialTimer?.cancel();
    _currentUserWorker?.dispose();
    _passportLocationWorker?.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_recheckLocationAvailabilityOnResume());
  }

  bool _consumePendingSwipeTutorialFlag() {
    final pending =
        _storage.getBool(AppConstants.swipeTutorialPendingKey) ?? false;
    if (pending) {
      unawaited(_storage.saveBool(AppConstants.swipeTutorialPendingKey, false));
    }
    return pending;
  }

  void _showSwipeTutorialOverlay() {
    // Avoid a swipe tutorial so onboarding stays focused on profile review.
    showSwipeTutorial.value = false;
    _swipeTutorialTimer?.cancel();
  }

  void dismissSwipeTutorial() {
    _swipeTutorialTimer?.cancel();
    showSwipeTutorial.value = false;
    unawaited(_storage.saveBool(AppConstants.swipeTutorialPendingKey, false));
  }

  /// Load cached discover users from local storage for instant display
  void _loadCachedUsersInstantly() {
    try {
      final cached = _storage.getCachedDiscoverUsers();
      if (cached != null && cached.isNotEmpty) {
        final users = _rankDiscoverUsers(
          _sanitizeDiscoverUsers(
            cached.map((json) => UserModel.fromJson(json)),
          ),
        );
        discoverUsers.assignAll(users);
        final persistedIndex =
            int.tryParse(
              _storage.getString(_discoverCurrentIndexStorageKey) ?? '',
            ) ??
            0;
        currentCardIndex.value = persistedIndex.clamp(
          0,
          users.isEmpty ? 0 : users.length - 1,
        );
        isEmpty.value = users.isEmpty;
        debugPrint(
          '[Home] Loaded ${users.length} cached users instantly (index=${currentCardIndex.value})',
        );
      }
    } catch (e) {
      debugPrint('[Home] Failed to load cached users: $e');
    }
  }

  Future<void> _persistDiscoverDeckState() async {
    try {
      await _storage.cacheDiscoverUsers(
        discoverUsers.map((user) => user.toJson()).toList(),
      );
      await _storage.saveString(
        _discoverCurrentIndexStorageKey,
        currentCardIndex.value.toString(),
      );
      await _storage.saveString(
        _discoverNextCursorStorageKey,
        _discoverNextCursor ?? '',
      );
      await _storage.saveString(
        _discoverHasMoreStorageKey,
        _hasMore.value ? '1' : '0',
      );
    } catch (e) {
      debugPrint('[Home] Failed to persist discover deck state: $e');
    }
  }

  bool? _parseStoredBool(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return null;
    if (normalized == '1' || normalized == 'true' || normalized == 'yes') {
      return true;
    }
    if (normalized == '0' || normalized == 'false' || normalized == 'no') {
      return false;
    }
    return null;
  }

  void _restorePersistedDiscoverDeckMeta() {
    final savedCursor =
        (_storage.getString(_discoverNextCursorStorageKey) ?? '').trim();
    _discoverNextCursor = savedCursor.isEmpty ? null : savedCursor;

    final savedHasMore = _parseStoredBool(
      _storage.getString(_discoverHasMoreStorageKey),
    );
    if (savedHasMore != null) {
      _hasMore.value = savedHasMore;
    }
  }

  Future<void> ensureDiscoverBufferReady({bool forceRefresh = false}) async {
    if (discoverUsers.isEmpty) {
      isEmpty.value = true;
      if (!_hasMore.value && !forceRefresh) {
        unawaited(_persistDiscoverDeckState());
        return;
      }
      if (!isLoading.value) {
        debugPrint(
          '[Home] Discover buffer empty after popup/navigation. Fetching a fresh page...',
        );
        await fetchDiscoverUsers(forceRefresh: forceRefresh);
      }
      return;
    }

    _prefetchDiscoverBufferIfNeeded();
    unawaited(_persistDiscoverDeckState());
  }

  Future<void> _waitForSessionRestoreIfNeeded() async {
    if (!_auth.sessionRestorePending.value) return;

    final completer = Completer<void>();
    late Worker worker;
    worker = ever<bool>(_auth.sessionRestorePending, (pending) {
      if (!pending && !completer.isCompleted) {
        worker.dispose();
        completer.complete();
      }
    });

    try {
      await completer.future.timeout(const Duration(seconds: 3));
    } catch (_) {
      worker.dispose();
    }
  }

  Future<void> _bootstrapAfterAuthRestore() async {
    await _waitForSessionRestoreIfNeeded();
    if (Get.currentRoute != AppRoutes.main) return;
    await _bootstrapHomeData();
  }

  Future<void> _handleStartupEntryFlow() async {
    final pendingSwipeTutorial = _consumePendingSwipeTutorialFlag();
    if (pendingSwipeTutorial) {
      showLocationGate.value = false;
      showStartupRadar.value = false;
      if (discoverUsers.isEmpty && !isLoading.value) {
        unawaited(fetchDiscoverUsers());
      }
      _showSwipeTutorialOverlay();
      return;
    }

    final ready = await _location.isLocationReady();
    locationGranted.value = ready;
    await _storage.saveBool('location_permission_granted', ready);

    if (!ready) {
      showLocationGate.value = true;
      showStartupRadar.value = false;
      if (discoverUsers.isEmpty && !isLoading.value) {
        unawaited(fetchDiscoverUsers());
      }
      return;
    }

    if (_startupRadarShownThisLaunch) {
      showLocationGate.value = false;
      showStartupRadar.value = false;
      if (discoverUsers.isEmpty && !isLoading.value) {
        unawaited(fetchDiscoverUsers());
      }
      return;
    }

    await _waitForSessionRestoreIfNeeded();
    if (Get.currentRoute != AppRoutes.main) return;
    await _startStartupRadarFlow();
  }

  Future<void> _startStartupRadarFlow() async {
    _startupRadarShownThisLaunch = true;
    showLocationGate.value = false;
    showStartupRadar.value = false;
    _startupRadarDismissScheduled = false;
    _startupRadarStartedAt = null;

    _startupRadarTimer?.cancel();

    if (!isLoading.value) {
      if (discoverUsers.isEmpty) {
        await fetchDiscoverUsers();
      } else {
        _prefetchDiscoverBufferIfNeeded();
      }
    }
  }

  Future<void> enableLocationFromGate() async {
    showLocationGate.value = false;
    final position = await _location.requestLocationWithFeedback();
    if (position == null) {
      locationGranted.value = false;
      await _storage.saveBool('location_permission_granted', false);
      showLocationGate.value = true;
      return;
    }

    locationGranted.value = true;
    await _storage.saveBool('location_permission_granted', true);
    if (_startupRadarShownThisLaunch) {
      if (discoverUsers.isEmpty && !isLoading.value) {
        await fetchDiscoverUsers(forceRefresh: true);
      }
      return;
    }
    await _startStartupRadarFlow();
  }

  void dismissLocationGate() {
    showLocationGate.value = false;
  }

  Future<void> _recheckLocationAvailabilityOnResume() async {
    final ready = await _location.isLocationReady();
    locationGranted.value = ready;
    await _storage.saveBool('location_permission_granted', ready);

    if (!ready) {
      showStartupRadar.value = false;
      if (Get.currentRoute == AppRoutes.main &&
          Get.isRegistered<NavigationController>()) {
        final navigation = Get.find<NavigationController>();
        if (navigation.currentIndex.value != 0) {
          navigation.goToHome();
        }
      }
      showLocationGate.value = true;
      return;
    }

    showLocationGate.value = false;

    if (discoverUsers.isEmpty && !isLoading.value) {
      await fetchDiscoverUsers(forceRefresh: true);
      return;
    }

    if (discoverUsers.isNotEmpty) {
      _prefetchDiscoverBufferIfNeeded();
    }
  }

  void _dismissStartupRadarIfReady() {
    if (!showStartupRadar.value ||
        discoverUsers.isEmpty ||
        _startupRadarDismissScheduled) {
      return;
    }

    _startupRadarDismissScheduled = true;
    final startedAt = _startupRadarStartedAt ?? DateTime.now();
    final elapsed = DateTime.now().difference(startedAt);
    final remaining = const Duration(milliseconds: 1200) - elapsed;
    Future.delayed(remaining.isNegative ? Duration.zero : remaining, () {
      _startupRadarDismissScheduled = false;
      if (!showStartupRadar.value) return;
      if (discoverUsers.isNotEmpty) {
        _startupRadarTimer?.cancel();
        showStartupRadar.value = false;
      }
    });
  }

  Future<void> fetchAllInitialData() async {
    // Fire all initial fetches in parallel ط£آ¢أ¢â€ڑآ¬أ¢â‚¬â€Œ don't await individually
    try {
      await Future.wait([
        fetchDiscoverUsers().catchError((e) {
          debugPrint('[Home] fetchDiscoverUsers failed in init: $e');
        }),
        fetchCategories().catchError((e) {
          debugPrint('[Home] fetchCategories failed in init: $e');
        }),
        fetchSuccessStories().catchError((e) {
          debugPrint('[Home] fetchSuccessStories failed in init: $e');
        }),
        _monetization.fetchStatus().catchError((e) {
          debugPrint('[Home] fetchStatus (monetization) failed in init: $e');
        }),
        _monetization.fetchAllLimits().then((_) {}).catchError((e) {
          debugPrint('[Home] fetchAllLimits (monetization) failed in init: $e');
        }),
        _monetization.fetchFeatures().catchError((e) {
          debugPrint('[Home] fetchFeatures (monetization) failed in init: $e');
          return <String>[];
        }),
        _monetization.fetchActivePlans().catchError((e) {
          debugPrint(
            '[Home] fetchActivePlans (monetization) failed in init: $e',
          );
        }),
        fetchDailyInsight().catchError((e) {
          debugPrint('[Home] fetchDailyInsight failed in init: $e');
        }),
      ]);
    } catch (e) {
      debugPrint('[Home] fetchAllInitialData unexpected error: $e');
    }
  }

  Future<void> _bootstrapHomeData() async {
    final shouldDeferDiscoverFetch =
        locationGranted.value &&
        !_startupRadarShownThisLaunch &&
        !_startupFlowHandled;
    if (!shouldDeferDiscoverFetch) {
      unawaited(
        fetchDiscoverUsers().catchError((e) {
          debugPrint('[Home] fetchDiscoverUsers failed in init: $e');
        }),
      );
    }
    unawaited(
      _monetization.fetchStatus().catchError((e) {
        debugPrint('[Home] fetchStatus (monetization) failed in init: $e');
      }),
    );
    unawaited(
      _monetization.fetchAllLimits().catchError((e) {
        debugPrint('[Home] fetchAllLimits (monetization) failed in init: $e');
        return <String, dynamic>{};
      }),
    );
    unawaited(
      _monetization.fetchFeatures().catchError((e) {
        debugPrint('[Home] fetchFeatures (monetization) failed in init: $e');
        return <String>[];
      }),
    );
    unawaited(
      _monetization.fetchActivePlans().catchError((e) {
        debugPrint('[Home] fetchActivePlans (monetization) failed in init: $e');
      }),
    );

    await Future.delayed(const Duration(milliseconds: 450));

    unawaited(
      trialManager.init().catchError((e) {
        debugPrint('[Home] trialManager init failed in init: $e');
        return trialManager;
      }),
    );

    unawaited(_loadSecondaryHomeContent());
  }

  Future<void> _loadSecondaryHomeContent() async {
    await Future.delayed(const Duration(milliseconds: 650));

    if (categories.isEmpty) {
      await fetchCategories().catchError((e) {
        debugPrint('[Home] fetchCategories failed in init: $e');
      });
    }

    await Future.delayed(const Duration(milliseconds: 250));

    if (successStories.isEmpty) {
      await fetchSuccessStories().catchError((e) {
        debugPrint('[Home] fetchSuccessStories failed in init: $e');
      });
    }

    await Future.delayed(const Duration(milliseconds: 250));

    await fetchDailyInsight().catchError((e) {
      debugPrint('[Home] fetchDailyInsight failed in init: $e');
    });
  }

  List<String> _readStoredList(String key) {
    final raw = _storage.getString(key) ?? '';
    if (raw.trim().isEmpty) return const <String>[];
    return raw
        .split('||')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  int _resolveTimeFrameIndex({
    required String savedTimeFrame,
    required String savedMarriageIntention,
    required String legacyIntentMode,
  }) {
    final normalizedTimeFrame = savedTimeFrame.trim().toLowerCase();
    if (normalizedTimeFrame.isNotEmpty) {
      final parsedIndex = int.tryParse(normalizedTimeFrame);
      if (parsedIndex != null) {
        return parsedIndex.clamp(0, _timeFrameValues.length - 1).toInt();
      }

      final timeFrameIndex = _timeFrameValues.indexOf(normalizedTimeFrame);
      if (timeFrameIndex >= 0) {
        return timeFrameIndex;
      }
    }

    final normalizedMarriage = savedMarriageIntention.trim().toLowerCase();
    if (normalizedMarriage.isNotEmpty) {
      final marriageIndex = _timeFrameValues.indexOf(normalizedMarriage);
      if (marriageIndex >= 0) {
        return marriageIndex;
      }
    }

    return _legacyIntentToTimeFrameIndex[legacyIntentMode
            .trim()
            .toLowerCase()] ??
        0;
  }

  void _loadFilters() {
    final loadedMinAge = _storage.getString('filter_minAge') != null
        ? int.tryParse(_storage.getString('filter_minAge')!)
        : null;
    final loadedMaxAge = _storage.getString('filter_maxAge') != null
        ? int.tryParse(_storage.getString('filter_maxAge')!)
        : null;
    final normalizedMin = (loadedMinAge ?? defaultMinAgeFilter)
        .clamp(defaultMinAgeFilter, defaultMaxAgeFilter)
        .toInt();
    final normalizedMax = (loadedMaxAge ?? defaultMaxAgeFilter)
        .clamp(defaultMinAgeFilter, defaultMaxAgeFilter)
        .toInt();
    minAge.value = math.min(normalizedMin, normalizedMax);
    maxAge.value = math.max(normalizedMin, normalizedMax);

    final loadedDistance = _storage.getString('filter_maxDistance') != null
        ? double.tryParse(_storage.getString('filter_maxDistance')!)
        : null;
    maxDistance.value = (loadedDistance ?? defaultDistanceFilterKm).clamp(
      distanceFilterMinKm,
      distanceFilterUnlimitedKm,
    );
    distanceFilterUserSet.value =
        _storage.getBool(_distanceFilterUserSetKey) ?? false;
    final fallbackGender = defaultDiscoveryGender;
    genderFilter.value = fallbackGender;
    countryFilter.value = (_storage.getString('filter_country') ?? '').trim();
    countryCodeFilter.value = (_storage.getString('filter_countryCode') ?? '')
        .trim()
        .toUpperCase();
    countryFilterUserSet.value =
        _storage.getBool(_countryFilterUserSetKey) ?? false;
    if (!countryFilterUserSet.value && countryFilter.value.trim().isNotEmpty) {
      countryFilter.value = '';
      countryCodeFilter.value = '';
      unawaited(_storage.saveString('filter_country', ''));
      unawaited(_storage.saveString('filter_countryCode', ''));
    }
    cityFilter.value = _storage.getString('filter_city') ?? '';
    maritalStatusFilter.value =
        _storage.getString('filter_maritalStatus') ?? '';
    ethnicityFilter.value = _storage.getString('filter_ethnicity') ?? '';
    educationFilter.value = _storage.getString('filter_education') ?? '';
    religiousLevelFilter.value =
        _storage.getString('filter_religiousLevel') ?? '';
    prayerFrequencyFilter.value =
        _storage.getString('filter_prayerFrequency') ?? '';
    final savedMarriageIntention =
        (_storage.getString('filter_marriageIntention') ?? '').trim();
    final savedTimeFrame = (_storage.getString('filter_timeFrame') ?? '')
        .trim();
    final legacyIntentMode = (_storage.getString('filter_intentMode') ?? '')
        .trim();
    final resolvedTimeFrameIndex = _resolveTimeFrameIndex(
      savedTimeFrame: savedTimeFrame,
      savedMarriageIntention: savedMarriageIntention,
      legacyIntentMode: legacyIntentMode,
    );
    timeFrameIndex.value = resolvedTimeFrameIndex;
    final resolvedTimeFrameValue = _timeFrameValues[resolvedTimeFrameIndex];
    marriageIntentionFilter.value = resolvedTimeFrameValue.isNotEmpty
        ? resolvedTimeFrameValue
        : savedMarriageIntention;
    livingSituationFilter.value =
        _storage.getString('filter_livingSituation') ?? '';
    interestsFilter.assignAll(_readStoredList('filter_interests'));
    languagesFilter.assignAll(_readStoredList('filter_languages'));
    familyValuesFilter.assignAll(_readStoredList('filter_familyValues'));
    communicationStylesFilter.assignAll(
      _readStoredList(
        'filter_communicationStyles',
      ).map(_toCommunicationStyleEnum),
    );
    verifiedOnlyFilter.value = _storage.getBool('filter_verifiedOnly') ?? false;
    goGlobalFilter.value = _storage.getBool('filter_goGlobal') ?? false;
    recentlyActiveOnlyFilter.value =
        _storage.getBool('filter_recentlyActiveOnly') ?? false;
    withPhotosOnlyFilter.value =
        _storage.getBool('filter_withPhotosOnly') ?? false;
    minTrustScoreFilter.value =
        int.tryParse(_storage.getString('filter_minTrustScore') ?? '') ?? 0;
    backgroundCheckOnlyFilter.value =
        _storage.getBool('filter_backgroundCheckOnly') ?? false;
    locationGranted.value =
        _storage.getBool('location_permission_granted') ?? false;
    _enforceFreeTierFilterPolicy();
    debugPrint('[Home] _loadFilters: loaded all filters from storage');
  }

  Future<void> saveFilters() async {
    _enforceFreeTierFilterPolicy();
    final normalizedCommunicationStyles = communicationStylesFilter
        .map(_toCommunicationStyleEnum)
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final selectedTimeFrame = timeFrameValue;
    final effectiveMarriageIntention = selectedTimeFrame.isNotEmpty
        ? selectedTimeFrame
        : marriageIntentionFilter.value.trim();

    await _storage.saveString('filter_minAge', minAge.value.toString());
    await _storage.saveString('filter_maxAge', maxAge.value.toString());
    await _storage.saveString(
      'filter_maxDistance',
      maxDistance.value.toString(),
    );
    await _storage.saveBool(
      _distanceFilterUserSetKey,
      distanceFilterUserSet.value,
    );
    await _storage.saveString(
      'filter_gender',
      defaultDiscoveryGender,
    );
    await _storage.saveString('filter_country', countryFilter.value.trim());
    await _storage.saveString('filter_countryCode', countryCodeFilter.value);
    await _storage.saveBool(
      _countryFilterUserSetKey,
      countryFilterUserSet.value,
    );
    await _storage.saveString('filter_city', cityFilter.value);
    await _storage.saveString(
      'filter_maritalStatus',
      maritalStatusFilter.value,
    );
    await _storage.saveString('filter_ethnicity', ethnicityFilter.value);
    await _storage.saveString('filter_education', educationFilter.value);
    await _storage.saveString(
      'filter_religiousLevel',
      religiousLevelFilter.value,
    );
    await _storage.saveString(
      'filter_prayerFrequency',
      prayerFrequencyFilter.value,
    );
    await _storage.saveString('filter_timeFrame', selectedTimeFrame);
    await _storage.saveString(
      'filter_marriageIntention',
      effectiveMarriageIntention,
    );
    await _storage.saveString(
      'filter_intentMode',
      _legacyIntentForTimeFrame(effectiveMarriageIntention) ?? '',
    );
    await _storage.saveString(
      'filter_livingSituation',
      livingSituationFilter.value,
    );
    await _storage.saveString('filter_interests', interestsFilter.join('||'));
    await _storage.saveString('filter_languages', languagesFilter.join('||'));
    await _storage.saveString(
      'filter_familyValues',
      familyValuesFilter.join('||'),
    );
    await _storage.saveString(
      'filter_communicationStyles',
      normalizedCommunicationStyles.join('||'),
    );
    await _storage.saveBool('filter_verifiedOnly', verifiedOnlyFilter.value);
    await _storage.saveBool('filter_goGlobal', goGlobalFilter.value);
    await _storage.saveBool(
      'filter_recentlyActiveOnly',
      recentlyActiveOnlyFilter.value,
    );
    await _storage.saveBool(
      'filter_withPhotosOnly',
      withPhotosOnlyFilter.value,
    );
    await _storage.saveString(
      'filter_minTrustScore',
      minTrustScoreFilter.value.toString(),
    );
    await _storage.saveBool(
      'filter_backgroundCheckOnly',
      backgroundCheckOnlyFilter.value,
    );
    debugPrint('[Home] saveFilters: persisted all filters');
  }

  String get timeFrameValue {
    final normalizedIndex = timeFrameIndex.value
        .clamp(0, _timeFrameValues.length - 1)
        .toInt();
    return _timeFrameValues[normalizedIndex];
  }

  String get timeFrameLabel {
    final value = timeFrameValue;
    return value.isEmpty ? 'all'.tr : value.tr;
  }

  void onTimeFrameChanged(int index) {
    final normalizedIndex = index.clamp(0, _timeFrameValues.length - 1).toInt();
    timeFrameIndex.value = normalizedIndex;
    marriageIntentionFilter.value = _timeFrameValues[normalizedIndex];
  }

  String? _legacyIntentForTimeFrame(String timeFrame) {
    switch (timeFrame.trim().toLowerCase()) {
      case 'within_months':
        return 'family_introduction';
      case 'within_year':
      case 'one_to_two_years':
        return 'serious_marriage';
      case 'just_exploring':
        return 'exploring';
      default:
        return null;
    }
  }

  void setCountryFilter(
    String country, {
    String? countryCode,
    bool isUserAction = true,
  }) {
    final normalizedCountry = country.trim();
    countryFilter.value = normalizedCountry;
    countryCodeFilter.value = (countryCode ?? countryCodeFilter.value)
        .trim()
        .toUpperCase();

    if (normalizedCountry.isEmpty) {
      cityFilter.value = '';
      countryCodeFilter.value = '';
    }

    countryFilterUserSet.value = isUserAction;
  }

  void clearCountryFilter({bool isUserAction = true}) {
    setCountryFilter('', isUserAction: isUserAction);
  }

  bool get _hasAdvancedFilterAccess =>
      _monetization.hasAdvancedFiltersAccess || hasPaidPremiumPlan;

  bool get hasAdvancedFilterAccess => _hasAdvancedFilterAccess;

  bool _hasAdvancedFiltersSelected() {
    return goGlobalFilter.value ||
        educationFilter.value.trim().isNotEmpty ||
        religiousLevelFilter.value.trim().isNotEmpty ||
        prayerFrequencyFilter.value.trim().isNotEmpty ||
        interestsFilter.isNotEmpty ||
        languagesFilter.isNotEmpty ||
        familyValuesFilter.isNotEmpty ||
        communicationStylesFilter.isNotEmpty;
  }

  void _clearAdvancedFilterState() {
    educationFilter.value = '';
    religiousLevelFilter.value = '';
    prayerFrequencyFilter.value = '';
    interestsFilter.clear();
    languagesFilter.clear();
    familyValuesFilter.clear();
    communicationStylesFilter.clear();
    goGlobalFilter.value = false;
  }

  void _enforceFreeTierFilterPolicy({bool showNotice = false}) {
    if (_hasAdvancedFilterAccess) return;

    final hadAdvancedFilters = _hasAdvancedFiltersSelected();
    _clearAdvancedFilterState();

    if (showNotice && hadAdvancedFilters) {
      Helpers.showSnackbar(
        message:
            'Free users can only use basic filters. Upgrade to unlock advanced filters.',
      );
    }
  }

  void _resetFilterStateToDefaults() {
    genderFilter.value = defaultDiscoveryGender;
    minAge.value = defaultMinAgeFilter;
    maxAge.value = defaultMaxAgeFilter;
    maxDistance.value = defaultDistanceFilterKm;
    distanceFilterUserSet.value = false;
    clearCountryFilter(isUserAction: false);
    cityFilter.value = '';
    maritalStatusFilter.value = '';
    ethnicityFilter.value = '';
    educationFilter.value = '';
    religiousLevelFilter.value = '';
    prayerFrequencyFilter.value = '';
    marriageIntentionFilter.value = '';
    onTimeFrameChanged(0);
    livingSituationFilter.value = '';
    interestsFilter.clear();
    languagesFilter.clear();
    familyValuesFilter.clear();
    communicationStylesFilter.clear();
    verifiedOnlyFilter.value = false;
    goGlobalFilter.value = false;
    recentlyActiveOnlyFilter.value = false;
    withPhotosOnlyFilter.value = false;
    minTrustScoreFilter.value = 0;
    backgroundCheckOnlyFilter.value = false;
  }

  Future<void> _clearDiscoverDeckForFilterRefresh({
    bool clearSeenHistory = true,
  }) async {
    discoverUsers.clear();
    cardPhotoIndices.clear();
    cardDetailsExpanded.clear();
    currentCardIndex.value = 0;
    lastSwipedUser.value = null;
    _swipeHistoryStack.clear();
    _discoverNextCursor = null;
    _page.value = 1;
    _hasMore.value = true;
    isEmpty.value = false;
    _pendingForceRefreshAfterLoad = false;
    if (clearSeenHistory) {
      _seenUserIds.clear();
      await _storage.clearSeenDiscoverUserIds();
    }
    await _storage.clearDiscoverCache();
    await _persistDiscoverDeckState();
  }

  Future<void> _refreshDiscoveryForViewerVerificationChange() async {
    debugPrint(
      '[Home] Viewer selfie verification changed. Refreshing discovery deck so photo lock state updates immediately.',
    );
    if (isLoading.value) {
      _pendingForceRefreshAfterLoad = true;
      return;
    }

    await _clearDiscoverDeckForFilterRefresh(clearSeenHistory: false);
    await fetchDiscoverUsers(forceRefresh: true);
  }

  Future<void> _refreshDiscoveryForPassportLocationChange() async {
    debugPrint(
      '[Home] Passport location changed. Refreshing discovery deck for the updated discovery scope.',
    );
    if (isLoading.value) {
      _pendingForceRefreshAfterLoad = true;
      return;
    }

    await _clearDiscoverDeckForFilterRefresh(clearSeenHistory: false);
    await fetchDiscoverUsers(forceRefresh: true);
  }

  Future<void> _clearSeenDiscoverHistory() async {
    _seenUserIds.clear();
    await _storage.clearSeenDiscoverUserIds();
  }

  bool get _canUseIncomingLikesAsDiscoverFallback {
    final hasExplicitCountry =
        countryFilterUserSet.value && countryFilter.value.trim().isNotEmpty;
    return !hasExplicitCountry &&
        !distanceFilterUserSet.value &&
        cityFilter.value.trim().isEmpty &&
        maritalStatusFilter.value.trim().isEmpty &&
        ethnicityFilter.value.trim().isEmpty &&
        educationFilter.value.trim().isEmpty &&
        religiousLevelFilter.value.trim().isEmpty &&
        prayerFrequencyFilter.value.trim().isEmpty &&
        timeFrameValue.isEmpty &&
        livingSituationFilter.value.trim().isEmpty &&
        interestsFilter.isEmpty &&
        languagesFilter.isEmpty &&
        familyValuesFilter.isEmpty &&
        communicationStylesFilter.isEmpty &&
        !verifiedOnlyFilter.value &&
        !goGlobalFilter.value &&
        !recentlyActiveOnlyFilter.value &&
        !withPhotosOnlyFilter.value &&
        !backgroundCheckOnlyFilter.value &&
        minTrustScoreFilter.value <= 0 &&
        maxDistance.value <= defaultDistanceFilterKm &&
        minAge.value <= 18 &&
        maxAge.value >= 90;
  }

  String? get _effectiveDiscoveryCountry {
    final passportCountry =
        _monetization.passportLocation.value?['country']?.toString().trim() ??
        '';
    if (passportCountry.isNotEmpty) {
      return passportCountry;
    }

    final profileCountry = currentUser?.profile?.country?.trim() ?? '';
    return profileCountry.isEmpty ? null : profileCountry;
  }

  double? get _effectiveDiscoveryLatitude {
    final passportLatitude = _safeLocationCoordinate(
      _monetization.passportLocation.value?['latitude'],
    );
    if (passportLatitude != null) {
      return passportLatitude;
    }
    return currentUser?.profile?.latitude;
  }

  double? get _effectiveDiscoveryLongitude {
    final passportLongitude = _safeLocationCoordinate(
      _monetization.passportLocation.value?['longitude'],
    );
    if (passportLongitude != null) {
      return passportLongitude;
    }
    return currentUser?.profile?.longitude;
  }

  double? _safeLocationCoordinate(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String? _passportDiscoverySignature(Map<String, dynamic>? location) {
    if (location == null) return null;
    final latitude = _safeLocationCoordinate(location['latitude']);
    final longitude = _safeLocationCoordinate(location['longitude']);
    final city = location['city']?.toString().trim() ?? '';
    final country = location['country']?.toString().trim() ?? '';
    return '$latitude|$longitude|$city|$country';
  }

  double? _distanceKmFromEffectiveDiscoveryLocation(UserModel candidate) {
    final viewerLat = _effectiveDiscoveryLatitude;
    final viewerLon = _effectiveDiscoveryLongitude;
    final candidateLat = candidate.profile?.latitude;
    final candidateLon = candidate.profile?.longitude;
    if (viewerLat == null ||
        viewerLon == null ||
        candidateLat == null ||
        candidateLon == null) {
      return null;
    }

    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(candidateLat - viewerLat);
    final dLon = _toRadians(candidateLon - viewerLon);
    final originLat = _toRadians(viewerLat);
    final targetLat = _toRadians(candidateLat);

    final hav =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(originLat) *
            math.cos(targetLat) *
            math.pow(math.sin(dLon / 2), 2);
    final c = 2 * math.atan2(math.sqrt(hav), math.sqrt(1 - hav));
    return earthRadiusKm * c;
  }

  bool _matchesFallbackDiscoveryScope(UserModel candidate) {
    if (goGlobalFilter.value) {
      return true;
    }

    final targetCountry = _effectiveDiscoveryCountry?.trim().toLowerCase() ?? '';
    final candidateCountry =
        candidate.profile?.country?.trim().toLowerCase() ?? '';
    if (targetCountry.isNotEmpty &&
        candidateCountry.isNotEmpty &&
        candidateCountry != targetCountry) {
      return false;
    }

    if (!locationGranted.value) {
      if (targetCountry.isEmpty) {
        return false;
      }
      return candidateCountry == targetCountry;
    }

    final distanceKm = _distanceKmFromEffectiveDiscoveryLocation(candidate);
    if (distanceKm == null) {
      return false;
    }

    return distanceKm <= maxDistance.value;
  }

  Future<List<UserModel>> _recoverDiscoverUsersAfterEmptyFetch() async {
    final persistedSeenIds = _storage.getSeenDiscoverUserIds();
    final hadSeenHistory =
        _seenUserIds.isNotEmpty || persistedSeenIds.isNotEmpty;

    if (hadSeenHistory) {
      debugPrint(
        '[Home] Empty discover deck after fetch. Clearing stale seen history and retrying.',
      );
      await _clearSeenDiscoverHistory();
      _discoverNextCursor = null;
      _page.value = 1;
      _hasMore.value = true;

      var retriedUsers = await _fetchPage(1, forceRefresh: true).timeout(
        _discoverRequestTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Request timeout while recovering discover users',
          );
        },
      );

      var attempts = 1;
      while (retriedUsers.isEmpty &&
          _hasMore.value &&
          attempts < _discoverMaxEnsureAttempts) {
        attempts++;
        retriedUsers = await _fetchPage(attempts, forceRefresh: false).timeout(
          _discoverRequestTimeout,
          onTimeout: () {
            throw TimeoutException(
              'Request timeout while recovering discover users',
            );
          },
        );
      }

      if (retriedUsers.isNotEmpty) {
        return retriedUsers;
      }
    }

    if (!_canUseIncomingLikesAsDiscoverFallback ||
        !Get.isRegistered<UsersController>()) {
      return const <UserModel>[];
    }

    final usersController = Get.find<UsersController>();
    await usersController.fetchWhoLikedMe();

    final actionableLikedUsers = usersController.likesReceived
        .where((item) => !item.isBlurred)
        .map((item) => item.user)
        .where((candidate) => candidate.id.trim().isNotEmpty)
        .toList(growable: false);

    if (actionableLikedUsers.isEmpty) {
      return const <UserModel>[];
    }

    final likerIds = actionableLikedUsers
        .map((user) => user.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    if (likerIds.isNotEmpty) {
      _seenUserIds.removeWhere(likerIds.contains);
      final remainingSeenIds = _storage.getSeenDiscoverUserIds()
        ..removeAll(likerIds);
      await _storage.saveSeenDiscoverUserIds(remainingSeenIds);
    }

    final fallbackUsers = _sanitizeDiscoverUsers(
      actionableLikedUsers.where(_matchesFallbackDiscoveryScope).toList(),
    );
    if (fallbackUsers.isNotEmpty) {
      debugPrint(
        '[Home] Using ${fallbackUsers.length} incoming-like users as discover fallback.',
      );
    }
    return fallbackUsers;
  }

  Future<void> applyFiltersAndRefresh({bool closeAfterApply = true}) async {
    if (isApplyingFilters.value) return;

    _liveFilterRefreshTimer?.cancel();
    isApplyingFilters.value = true;
    try {
      _enforceFreeTierFilterPolicy(showNotice: true);
      await saveFilters();
      await _clearDiscoverDeckForFilterRefresh();
      await fetchDiscoverUsers(forceRefresh: true);
      if (closeAfterApply) {
        Get.back();
      }
    } finally {
      isApplyingFilters.value = false;
    }
  }

  Future<void> resetFiltersAndRefresh({bool closeAfterApply = false}) async {
    if (isApplyingFilters.value) return;

    _liveFilterRefreshTimer?.cancel();
    isApplyingFilters.value = true;
    try {
      _resetFilterStateToDefaults();
      _enforceFreeTierFilterPolicy();
      await saveFilters();
      await _clearDiscoverDeckForFilterRefresh();

      final refreshTasks = <Future<void>>[
        fetchDiscoverUsers(forceRefresh: true),
      ];

      if (Get.isRegistered<UsersController>()) {
        refreshTasks.add(
          Get.find<UsersController>().resetDiscoveryFeedForFilterRefresh(
            clearSeenHistory: true,
          ),
        );
      }

      await Future.wait(refreshTasks);

      if (closeAfterApply) {
        Get.back();
      }
    } finally {
      isApplyingFilters.value = false;
    }
  }

  void scheduleLiveFilterRefresh({
    Duration delay = const Duration(milliseconds: 320),
  }) {
    _liveFilterRefreshTimer?.cancel();
    _liveFilterRefreshTimer = Timer(delay, () {
      if (isApplyingFilters.value) {
        scheduleLiveFilterRefresh(delay: delay);
        return;
      }
      unawaited(applyFiltersAndRefresh(closeAfterApply: false));
    });
  }

  /// Called from the "Enable Location" button ط£آ¢أ¢â€ڑآ¬أ¢â‚¬â€Œ requests permission with
  /// user feedback dialogs, then fetches discover users.
  Future<void> requestLocationAndFetch() async {
    final position = await _location.requestLocationWithFeedback();
    if (position != null) {
      locationGranted.value = true;
      await _storage.saveBool('location_permission_granted', true);
      await fetchDiscoverUsers(forceRefresh: true);
      return;
    }
    locationGranted.value = false;
    await _storage.saveBool('location_permission_granted', false);
  }

  Map<String, dynamic> get _filterParams {
    final requiredOppositeGender = _requiredOppositeGender;
    final allowAdvancedFilters = _hasAdvancedFilterAccess;
    final effectiveTimeFrame = timeFrameValue.isNotEmpty
        ? timeFrameValue
        : marriageIntentionFilter.value.trim();
    final legacyIntentMode = allowAdvancedFilters
        ? _legacyIntentForTimeFrame(effectiveTimeFrame)
        : null;
    final normalizedCountry = countryFilter.value.trim();
    final normalizedCity = cityFilter.value.trim();
    final resolvedGender =
        requiredOppositeGender ?? _normalizeBinaryGender(genderFilter.value);
    final hasExplicitNonDistanceFilters =
        (countryFilterUserSet.value && normalizedCountry.isNotEmpty) ||
        normalizedCity.isNotEmpty ||
        maritalStatusFilter.value.trim().isNotEmpty ||
        ethnicityFilter.value.trim().isNotEmpty ||
        educationFilter.value.trim().isNotEmpty ||
        religiousLevelFilter.value.trim().isNotEmpty ||
        prayerFrequencyFilter.value.trim().isNotEmpty ||
        effectiveTimeFrame.isNotEmpty ||
        livingSituationFilter.value.trim().isNotEmpty ||
        interestsFilter.isNotEmpty ||
        languagesFilter.isNotEmpty ||
        familyValuesFilter.isNotEmpty ||
        communicationStylesFilter.isNotEmpty ||
        verifiedOnlyFilter.value ||
        recentlyActiveOnlyFilter.value ||
        withPhotosOnlyFilter.value ||
        backgroundCheckOnlyFilter.value ||
        minTrustScoreFilter.value > 0 ||
        minAge.value > defaultMinAgeFilter ||
        maxAge.value < defaultMaxAgeFilter;
    final shouldApplyDistanceFilter =
        !(allowAdvancedFilters && goGlobalFilter.value) &&
        locationGranted.value &&
        (distanceFilterUserSet.value || !hasExplicitNonDistanceFilters);
    final shouldApplyCountryFilter =
        normalizedCountry.isNotEmpty &&
        (countryFilterUserSet.value ||
            !(allowAdvancedFilters && goGlobalFilter.value));
    final normalizedCommunicationStyles = allowAdvancedFilters
        ? communicationStylesFilter
              .map(_toCommunicationStyleEnum)
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList(growable: false)
        : const <String>[];
    return {
      'limit': _discoverInitialBufferSize,
      'gender': ?resolvedGender,
      'minAge': minAge.value,
      'maxAge': maxAge.value,
      if (allowAdvancedFilters && goGlobalFilter.value) 'goGlobal': true,
      if (shouldApplyDistanceFilter) 'maxDistance': maxDistance.value.round(),
      if (distanceFilterUserSet.value) 'distanceUserSet': true,
      if (shouldApplyCountryFilter) 'country': normalizedCountry,
      if (normalizedCity.isNotEmpty && shouldApplyCountryFilter)
        'city': normalizedCity,
      if (maritalStatusFilter.value.isNotEmpty)
        'maritalStatus': maritalStatusFilter.value,
      if (ethnicityFilter.value.isNotEmpty) 'ethnicity': ethnicityFilter.value,
      if (allowAdvancedFilters && educationFilter.value.isNotEmpty)
        'education': educationFilter.value,
      if (allowAdvancedFilters && religiousLevelFilter.value.isNotEmpty)
        'religiousLevel': religiousLevelFilter.value,
      if (allowAdvancedFilters && prayerFrequencyFilter.value.isNotEmpty)
        'prayerFrequency': prayerFrequencyFilter.value,
      if (effectiveTimeFrame.isNotEmpty)
        'timeFrame': effectiveTimeFrame,
      if (effectiveTimeFrame.isNotEmpty)
        'marriageIntention': effectiveTimeFrame,
      ...?legacyIntentMode == null ? null : {'intentMode': legacyIntentMode},
      if (livingSituationFilter.value.isNotEmpty)
        'livingSituation': livingSituationFilter.value,
      if (allowAdvancedFilters && interestsFilter.isNotEmpty)
        'interests': interestsFilter.toList(),
      if (allowAdvancedFilters && languagesFilter.isNotEmpty)
        'languages': languagesFilter.toList(),
      if (allowAdvancedFilters && familyValuesFilter.isNotEmpty)
        'familyValues': familyValuesFilter.map(_toBackendEnumValue).toList(),
      if (allowAdvancedFilters && normalizedCommunicationStyles.isNotEmpty)
        'communicationStyles': normalizedCommunicationStyles,
      if (verifiedOnlyFilter.value) 'verifiedOnly': true,
      if (recentlyActiveOnlyFilter.value) 'recentlyActiveOnly': true,
      if (withPhotosOnlyFilter.value) 'withPhotosOnly': true,
      if (minTrustScoreFilter.value > 0)
        'minTrustScore': minTrustScoreFilter.value,
      if (backgroundCheckOnlyFilter.value) 'backgroundCheckStatus': 'cleared',
    };
  }

  Map<String, dynamic> buildDiscoverSearchParams({int? page, int? limit}) {
    return _buildDiscoverQueryParameters(
      page: page,
      limit: limit,
      forceRefresh: false,
      cursor: page == null ? _discoverNextCursor : null,
      includeDeckMeta: true,
    );
  }

  List<String> _discoverExcludeIdsForQuery() {
    final exclusions = _discoverExclusionIds().toList(growable: false);
    if (exclusions.length <= _maxDiscoverExcludeIds) {
      return exclusions;
    }

    // Keep the most recently inserted IDs to minimize payload size while
    // preserving strict exclusion for recently seen cards.
    return exclusions.sublist(exclusions.length - _maxDiscoverExcludeIds);
  }

  Map<String, dynamic> _buildDiscoverQueryParameters({
    int? page,
    int? limit,
    bool forceRefresh = false,
    String? cursor,
    bool includeDeckMeta = false,
  }) {
    final params = Map<String, dynamic>.from(_filterParams);

    if (limit != null) {
      params['limit'] = limit;
    }

    final normalizedCursor = cursor?.trim();
    if (!forceRefresh &&
        normalizedCursor != null &&
        normalizedCursor.isNotEmpty) {
      params['cursor'] = normalizedCursor;
    } else if (page != null) {
      params['page'] = page;
    }

    if (forceRefresh) {
      params['forceRefresh'] = true;
    }

    if (includeDeckMeta) {
      params['includeDeckMeta'] = true;
    }

    final excludeIds = _discoverExcludeIdsForQuery();
    if (excludeIds.isNotEmpty) {
      params['excludeIds'] = excludeIds;
    }

    return params;
  }

  bool? _parseDynamicBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return null;
  }

  String _toBackendEnumValue(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r"[^a-z0-9]+"), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  String _toCommunicationStyleEnum(String value) {
    final normalized = _toBackendEnumValue(value);
    switch (normalized) {
      case 'chatty_cathy':
      case 'storyteller':
      case 'expressive':
        return 'expressive';
      case 'listener':
      case 'deep_thinker':
      case 'reserved':
        return 'reserved';
      case 'joker':
      case 'sarcastic_wit':
      case 'humorous':
        return 'humorous';
      case 'easygoing':
      case 'gentle':
        return 'gentle';
      case 'straight_shooter':
      case 'direct':
        return 'direct';
      default:
        return normalized;
    }
  }

  String? _normalizeBinaryGender(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return null;

    switch (normalized) {
      case 'male':
      case 'man':
      case 'm':
        return 'male';
      case 'female':
      case 'woman':
      case 'f':
        return 'female';
      default:
        return null;
    }
  }

  String? _resolveCurrentUserGender() {
    final liveGender = _normalizeBinaryGender(
      _auth.currentUser.value?.profile?.gender,
    );
    if (liveGender != null) return liveGender;

    final cachedUser = _storage.getUser();
    final cachedProfile = cachedUser?['profile'];
    if (cachedProfile is Map) {
      final profileGender = _normalizeBinaryGender(
        cachedProfile['gender']?.toString(),
      );
      if (profileGender != null) return profileGender;
    }

    return _normalizeBinaryGender(cachedUser?['gender']?.toString());
  }

  String? get _requiredOppositeGender {
    final mine = _resolveCurrentUserGender();
    if (mine == 'male') return 'female';
    if (mine == 'female') return 'male';
    return null;
  }

  String get defaultDiscoveryGender {
    final requiredGender = _requiredOppositeGender;
    if (requiredGender != null) return requiredGender;

    final savedGender = _normalizeBinaryGender(
      _storage.getString('filter_gender'),
    );
    if (savedGender != null) return savedGender;

    // Keep the default narrow rather than falling back to "all" when a legacy
    // account is missing gender metadata.
    return 'female';
  }

  bool _isOppositeGenderUser(UserModel user) {
    final requiredGender = _requiredOppositeGender;
    if (requiredGender == null) return true;
    final candidateGender = _normalizeBinaryGender(user.profile?.gender);
    return candidateGender == requiredGender;
  }

  bool _isCurrentUserId(String? userId) {
    String? resolvedCurrentUserId = _auth.userId;
    resolvedCurrentUserId ??= _auth.currentUser.value?.id;

    if (resolvedCurrentUserId == null || resolvedCurrentUserId.isEmpty) {
      final cachedUser = _storage.getUser();
      resolvedCurrentUserId =
          (cachedUser?['id'] ?? cachedUser?['_id'] ?? cachedUser?['userId'])
              ?.toString();
    }

    if (resolvedCurrentUserId != null &&
        resolvedCurrentUserId.isNotEmpty &&
        userId != null &&
        userId == resolvedCurrentUserId) {
      return true;
    }
    final current = _auth.currentUser.value;
    return current != null && userId != null && userId == current.id;
  }

  bool _isCurrentUser(UserModel user) {
    if (_isCurrentUserId(user.id)) return true;

    final current = _auth.currentUser.value;
    if (current == null) return false;

    final currentEmail = current.email.trim().toLowerCase();
    final candidateEmail = user.email.trim().toLowerCase();
    if (currentEmail.isNotEmpty &&
        candidateEmail.isNotEmpty &&
        candidateEmail == currentEmail) {
      return true;
    }

    final currentUsername = (current.username ?? '').trim().toLowerCase();
    final candidateUsername = (user.username ?? '').trim().toLowerCase();
    if (currentUsername.isNotEmpty &&
        candidateUsername.isNotEmpty &&
        candidateUsername == currentUsername) {
      return true;
    }

    return false;
  }

  Set<String> _discoverExclusionIds() {
    final excluded = <String>{}
      ..addAll(_seenUserIds)
      ..addAll(_storage.getSeenDiscoverUserIds().map((id) => id.trim()));

    if (Get.isRegistered<UsersController>()) {
      final usersController = Get.find<UsersController>();
      excluded.addAll(usersController.likedUsers.map((user) => user.id.trim()));
      excluded.addAll(
        usersController.passedUsers.map((user) => user.id.trim()),
      );
      excluded.addAll(usersController.matches.map((user) => user.id.trim()));
    }

    excluded.removeWhere((id) => id.isEmpty);
    return excluded;
  }

  List<UserModel> _sanitizeDiscoverUsers(Iterable<UserModel> users) {
    final exclusionIds = _discoverExclusionIds();
    final blockedIds = _storage.getBlockedUserIds();
    final seen = <String>{};
    return users.where((u) {
      final normalizedId = u.id.trim();
      if (normalizedId.isEmpty) return false;
      if (_isCurrentUser(u)) return false;
      if (_isStatusExcluded(u)) return false;
      if (!_isOppositeGenderUser(u)) return false;
      if (blockedIds.contains(normalizedId)) return false;
      if (exclusionIds.contains(normalizedId)) return false;
      return seen.add(normalizedId);
    }).toList();
  }

  void evictUsersByIds(Iterable<String> userIds) {
    final blockedIds = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (blockedIds.isEmpty) return;

    final removedBeforeCurrent = discoverUsers
        .take(currentCardIndex.value)
        .where((user) => blockedIds.contains(user.id))
        .length;

    discoverUsers.removeWhere((user) => blockedIds.contains(user.id));
    cardPhotoIndices.removeWhere((key, _) => blockedIds.contains(key));
    cardDetailsExpanded.removeWhere((key, _) => blockedIds.contains(key));

    if (lastSwipedUser.value != null &&
        blockedIds.contains(lastSwipedUser.value!.id)) {
      lastSwipedUser.value = null;
    }

    _swipeHistoryStack.removeWhere(
      (entry) => blockedIds.contains(entry.user.id),
    );
    _updateLastSwipedUserFromHistory();

    if (removedBeforeCurrent > 0) {
      currentCardIndex.value = math.max(
        0,
        currentCardIndex.value - removedBeforeCurrent,
      );
    }

    if (currentCardIndex.value >= discoverUsers.length) {
      currentCardIndex.value = discoverUsers.isEmpty
          ? 0
          : discoverUsers.length - 1;
    }
    isEmpty.value = discoverUsers.isEmpty;
    unawaited(_persistDiscoverDeckState());
  }

  void resetForLogout() {
    discoverUsers.clear();
    featuredAd.value = null;
    _trackedAdImpressions.clear();
    categories.clear();
    successStories.clear();
    recommendedUsers.clear();
    selectedCategoryId.value = '';
    currentCardIndex.value = 0;
    isEmpty.value = true;
    hasError.value = false;
    lastSwipedUser.value = null;
    showLocationGate.value = false;
    showStartupRadar.value = false;
    showSwipeTutorial.value = false;
    swipeButtonCue.value = '';
    cardPhotoIndices.clear();
    cardDetailsExpanded.clear();
    _seenUserIds.clear();
    _discoverNextCursor = null;
    _page.value = 1;
    _hasMore.value = true;
    _swipeHistoryStack.clear();
    _swipeMutationQueue = Future<void>.value();
    _isRewindInFlight = false;
    unawaited(_persistDiscoverDeckState());
  }

  Set<String> _normalizedTokenSet(List<String>? values) {
    if (values == null || values.isEmpty) return <String>{};
    return values
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  int _sharedCount(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    return a.intersection(b).length;
  }

  int _religiousLevelRank(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'very_practicing':
        return 4;
      case 'practicing':
      case 'actively_practicing':
        return 3;
      case 'moderate':
      case 'occasionally':
        return 2;
      case 'liberal':
      case 'not_practicing':
        return 1;
      default:
        return 0;
    }
  }

  int _educationLevelRank(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'high_school':
      case 'school':
        return 1;
      case 'bachelors':
      case 'university':
        return 2;
      case 'masters':
        return 3;
      case 'phd':
        return 4;
      default:
        return 0;
    }
  }

  double _toRadians(double deg) => deg * (math.pi / 180.0);

  double? _distanceKm(UserModel a, UserModel b) {
    final aLat = a.profile?.latitude;
    final aLon = a.profile?.longitude;
    final bLat = b.profile?.latitude;
    final bLon = b.profile?.longitude;
    if (aLat == null || aLon == null || bLat == null || bLon == null) {
      return null;
    }

    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(bLat - aLat);
    final dLon = _toRadians(bLon - aLon);
    final originLat = _toRadians(aLat);
    final targetLat = _toRadians(bLat);

    final hav =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(originLat) *
            math.cos(targetLat) *
            math.pow(math.sin(dLon / 2), 2);
    final c = 2 * math.atan2(math.sqrt(hav), math.sqrt(1 - hav));
    return earthRadiusKm * c;
  }

  int _interestCompatibilityScore(UserModel candidate) {
    final me = currentUser;
    if (me == null) return 8;

    final mine = _normalizedTokenSet(me.profile?.interests);
    final theirs = _normalizedTokenSet(candidate.profile?.interests);
    final shared = _sharedCount(mine, theirs);

    if (shared >= 5) return 25;
    if (shared >= 3) return 20;
    if (shared == 2) return 14;
    if (shared == 1) return 8;
    return 0;
  }

  int _distanceCompatibilityScore(UserModel candidate) {
    final me = currentUser;
    if (me == null) return 10;

    final distance = _distanceKm(me, candidate);
    if (distance == null) return 10;

    if (distance <= 10) return 20;
    if (distance <= 50) return 15;
    if (distance <= 100) return 10;
    return 5;
  }

  int _religiousCompatibilityScore(UserModel candidate) {
    final me = currentUser;
    if (me == null) return 8;

    final mine = _religiousLevelRank(me.profile?.religiousLevel);
    final theirs = _religiousLevelRank(candidate.profile?.religiousLevel);

    if (mine == 0 || theirs == 0) return 8;
    if (mine == theirs) return 20;
    if ((mine - theirs).abs() <= 1) return 12;
    return 6;
  }

  int _culturalCompatibilityScore(UserModel candidate) {
    final me = currentUser;
    if (me == null) return 7;

    final myNationality = (me.profile?.nationality ?? '').trim().toLowerCase();
    final theirNationality = (candidate.profile?.nationality ?? '')
        .trim()
        .toLowerCase();
    final myEthnicity = (me.profile?.ethnicity ?? '').trim().toLowerCase();
    final theirEthnicity = (candidate.profile?.ethnicity ?? '')
        .trim()
        .toLowerCase();

    if (myNationality.isNotEmpty && myNationality == theirNationality) {
      return 15;
    }
    if (myEthnicity.isNotEmpty && myEthnicity == theirEthnicity) return 15;

    final sharedLanguages = _sharedCount(
      _normalizedTokenSet(me.profile?.languages),
      _normalizedTokenSet(candidate.profile?.languages),
    );
    if (sharedLanguages >= 2) return 10;
    return 5;
  }

  int _familyCompatibilityScore(UserModel candidate) {
    final me = currentUser;
    if (me == null) return 5;

    final mine = _normalizedTokenSet(me.profile?.familyValues);
    final theirs = _normalizedTokenSet(candidate.profile?.familyValues);
    if (mine.isEmpty || theirs.isEmpty) return 5;

    final shared = _sharedCount(mine, theirs);
    final ratio = shared / math.max(1, math.min(mine.length, theirs.length));
    return (ratio * 10).round().clamp(0, 10);
  }

  int _educationCompatibilityScore(UserModel candidate) {
    final me = currentUser;
    if (me == null) return 2;

    final mine = _educationLevelRank(me.profile?.education);
    final theirs = _educationLevelRank(candidate.profile?.education);
    if (mine == 0 || theirs == 0) return 2;
    if (mine == theirs) return 5;
    if ((mine - theirs).abs() <= 1) return 3;
    return 2;
  }

  int _lifestyleCompatibilityScore(UserModel candidate) {
    final me = currentUser;
    if (me == null) return 3;

    int matchingTraits = 0;
    int comparableTraits = 0;
    final myDietary = (me.profile?.dietary ?? '').trim().toLowerCase();
    final theirDietary = (candidate.profile?.dietary ?? '')
        .trim()
        .toLowerCase();
    if (myDietary.isNotEmpty && theirDietary.isNotEmpty) {
      comparableTraits++;
      if (myDietary == theirDietary) matchingTraits++;
    }

    final myAlcohol = (me.profile?.alcohol ?? '').trim().toLowerCase();
    final theirAlcohol = (candidate.profile?.alcohol ?? '')
        .trim()
        .toLowerCase();
    if (myAlcohol.isNotEmpty && theirAlcohol.isNotEmpty) {
      comparableTraits++;
      if (myAlcohol == theirAlcohol) matchingTraits++;
    }

    final myLiving = (me.profile?.livingSituation ?? '').trim().toLowerCase();
    final theirLiving = (candidate.profile?.livingSituation ?? '')
        .trim()
        .toLowerCase();
    if (myLiving.isNotEmpty && theirLiving.isNotEmpty) {
      comparableTraits++;
      if (myLiving == theirLiving) matchingTraits++;
    }

    if (comparableTraits == 0) return 3;
    if (matchingTraits >= 2) return 5;
    if (matchingTraits == 1) return 3;
    return 2;
  }

  int _computeClientCompatibilityScore(UserModel candidate) {
    final me = currentUser;
    if (me == null) {
      final fallback =
          (candidate.profileQualityScore * 0.45) +
          (candidate.activityRankingScore * 0.25) +
          (candidate.trustScore.clamp(0, 100) * 0.30);
      return fallback.round().clamp(0, 100);
    }

    final baseScore =
        _interestCompatibilityScore(candidate) +
        _distanceCompatibilityScore(candidate) +
        _religiousCompatibilityScore(candidate) +
        _culturalCompatibilityScore(candidate) +
        _familyCompatibilityScore(candidate) +
        _educationCompatibilityScore(candidate) +
        _lifestyleCompatibilityScore(candidate);

    double bonusMultiplier = 1.0;
    final bothVerified = me.selfieVerified && candidate.selfieVerified;
    if (bothVerified) bonusMultiplier += 0.05;

    final bothComplete =
        me.profileCompletenessScore >= 80 &&
        candidate.profileCompletenessScore >= 80;
    if (bothComplete) bonusMultiplier += 0.03;

    return (baseScore * bonusMultiplier).round().clamp(0, 100);
  }

  int _effectiveCompatibilityScore(UserModel candidate) {
    final serverScore = compatibilityScores[candidate.id] ?? 0;
    final clientScore = _computeClientCompatibilityScore(candidate);
    if (serverScore <= 0) {
      compatibilityScores[candidate.id] = clientScore;
      return clientScore;
    }

    final blended = ((serverScore * 0.70) + (clientScore * 0.30)).round().clamp(
      0,
      100,
    );
    compatibilityScores[candidate.id] = blended;
    return blended;
  }

  int _mutualInterestsPercent(UserModel candidate) {
    final me = currentUser;
    if (me == null) return 50;

    final mine = _normalizedTokenSet(me.profile?.interests);
    final theirs = _normalizedTokenSet(candidate.profile?.interests);
    if (mine.isEmpty || theirs.isEmpty) return 0;
    final shared = _sharedCount(mine, theirs);
    final ratio = shared / math.max(1, math.min(mine.length, theirs.length));
    return (ratio * 100).round().clamp(0, 100);
  }

  int _responseRateProxy(UserModel candidate) {
    return candidate.trustScore.clamp(0, 100);
  }

  double _safeDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _trimBehaviorWeights(Map<String, double> source, {int maxSize = 120}) {
    if (source.length <= maxSize) return;
    final top = source.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    source
      ..clear()
      ..addEntries(top.take(maxSize));
  }

  void _loadBehaviorSignals() {
    final raw = _storage.getString(_behaviorSignalsStorageKey);
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;

      _likedInterestWeights.clear();
      final liked = decoded['likedInterests'];
      if (liked is Map) {
        for (final entry in liked.entries) {
          final key = entry.key.toString().trim().toLowerCase();
          final value = _safeDouble(entry.value);
          if (key.isNotEmpty && value > 0) {
            _likedInterestWeights[key] = value;
          }
        }
      }

      _passedInterestWeights.clear();
      final passed = decoded['passedInterests'];
      if (passed is Map) {
        for (final entry in passed.entries) {
          final key = entry.key.toString().trim().toLowerCase();
          final value = _safeDouble(entry.value);
          if (key.isNotEmpty && value > 0) {
            _passedInterestWeights[key] = value;
          }
        }
      }

      _preferredAgeCenter = _safeDouble(decoded['preferredAgeCenter']);
      _preferredDistanceKm = _safeDouble(decoded['preferredDistanceKm']);
      _positiveSignalCount = _safeInt(decoded['positiveSignals']);
      _negativeSignalCount = _safeInt(decoded['negativeSignals']);

      _trimBehaviorWeights(_likedInterestWeights);
      _trimBehaviorWeights(_passedInterestWeights);
    } catch (e) {
      debugPrint('[Home] _loadBehaviorSignals failed: $e');
    }
  }

  Future<void> _saveBehaviorSignals() async {
    try {
      final payload = {
        'likedInterests': _likedInterestWeights,
        'passedInterests': _passedInterestWeights,
        'preferredAgeCenter': _preferredAgeCenter,
        'preferredDistanceKm': _preferredDistanceKm,
        'positiveSignals': _positiveSignalCount,
        'negativeSignals': _negativeSignalCount,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await _storage.saveString(
        _behaviorSignalsStorageKey,
        jsonEncode(payload),
      );
    } catch (e) {
      debugPrint('[Home] _saveBehaviorSignals failed: $e');
    }
  }

  void _recordSwipeBehavior(UserModel user, {required bool positive}) {
    final interestTokens = _normalizedTokenSet(user.profile?.interests);
    if (interestTokens.isNotEmpty) {
      final targetMap = positive
          ? _likedInterestWeights
          : _passedInterestWeights;
      final oppositeMap = positive
          ? _passedInterestWeights
          : _likedInterestWeights;
      final delta = positive ? 1.0 : 0.75;

      for (final token in interestTokens) {
        targetMap[token] = (targetMap[token] ?? 0) + delta;
        final opposite = oppositeMap[token] ?? 0;
        if (opposite > 0) {
          oppositeMap[token] = math.max(0, opposite - (positive ? 0.15 : 0.10));
        }
      }
    }

    final age = user.age;
    if (age > 0) {
      if (_preferredAgeCenter <= 0) {
        _preferredAgeCenter = age.toDouble();
      } else {
        final alpha = positive ? 0.22 : 0.04;
        _preferredAgeCenter =
            (_preferredAgeCenter * (1 - alpha)) + (age.toDouble() * alpha);
      }
    }

    final me = currentUser;
    if (me != null) {
      final distance = _distanceKm(me, user);
      if (distance != null) {
        if (_preferredDistanceKm <= 0) {
          _preferredDistanceKm = distance;
        } else {
          final alpha = positive ? 0.20 : 0.05;
          _preferredDistanceKm =
              (_preferredDistanceKm * (1 - alpha)) + (distance * alpha);
        }
      }
    }

    if (positive) {
      _positiveSignalCount++;
    } else {
      _negativeSignalCount++;
    }

    _trimBehaviorWeights(_likedInterestWeights);
    _trimBehaviorWeights(_passedInterestWeights);
    unawaited(_saveBehaviorSignals());
  }

  int _behaviorPreferenceScore(UserModel candidate) {
    final totalSignals = _positiveSignalCount + _negativeSignalCount;
    if (totalSignals < 3) return 50;

    final confidence = (totalSignals / 30).clamp(0.2, 1.0).toDouble();

    double interestScore = 50;
    final interests = _normalizedTokenSet(candidate.profile?.interests);
    if (interests.isNotEmpty) {
      double liked = 0;
      double passed = 0;
      for (final interest in interests) {
        liked += _likedInterestWeights[interest] ?? 0;
        passed += _passedInterestWeights[interest] ?? 0;
      }
      final centered = 50 + ((liked - passed) * 12 * confidence);
      interestScore = centered.clamp(0, 100).toDouble();
    }

    double ageScore = 50;
    if (_preferredAgeCenter > 0 && candidate.age > 0) {
      final ageDiff = (candidate.age - _preferredAgeCenter).abs();
      ageScore = (100 - (ageDiff * 5)).clamp(0, 100).toDouble();
    }

    double distanceScore = 50;
    final me = currentUser;
    if (me != null) {
      final distance = _distanceKm(me, candidate);
      if (distance != null) {
        final targetDistance = _preferredDistanceKm > 0
            ? _preferredDistanceKm
            : maxDistance.value;
        if (distance <= targetDistance) {
          distanceScore =
              (100 - ((distance / math.max(1, targetDistance)) * 25))
                  .clamp(0, 100)
                  .toDouble();
        } else {
          final overshoot =
              (distance - targetDistance) / math.max(1, targetDistance);
          distanceScore = (75 - (overshoot * 50)).clamp(0, 100).toDouble();
        }
      }
    }

    final blended =
        (interestScore * 0.55) + (ageScore * 0.30) + (distanceScore * 0.15);
    return blended.round().clamp(0, 100);
  }

  bool _isBackgroundRejected(UserModel user) {
    final status = user.backgroundCheckStatus.trim().toLowerCase();
    const rejectedStates = <String>{
      'rejected',
      'failed',
      'denied',
      'suspended',
      'blacklisted',
    };
    return rejectedStates.contains(status);
  }

  bool _isStatusExcluded(UserModel user) {
    const disallowed = <String>{
      'deactivated',
      'suspended',
      'banned',
      'blocked',
      'deleted',
    };
    return disallowed.contains(user.status.trim().toLowerCase());
  }

  bool _passesQualityGate(UserModel user) {
    if (_isStatusExcluded(user)) return false;
    if (user.isShadowBanned) return false;
    if (_isBackgroundRejected(user)) return false;

    if (user.lastLoginAt != null) {
      final inactiveForDays = DateTime.now()
          .difference(user.lastLoginAt!)
          .inDays;
      if (inactiveForDays >= 60) return false;
    }

    if (minTrustScoreFilter.value > 0 &&
        user.trustScore < minTrustScoreFilter.value) {
      return false;
    }
    if (withPhotosOnlyFilter.value && !user.hasProfilePhoto) return false;
    if (recentlyActiveOnlyFilter.value && !user.wasLiveInLast24Hours) {
      return false;
    }
    if (backgroundCheckOnlyFilter.value && !user.isBackgroundCheckCleared) {
      return false;
    }

    return true;
  }

  double _rankingScore(UserModel candidate) {
    final compatibility = _effectiveCompatibilityScore(candidate);
    final quality = candidate.profileQualityScore;
    final activity = candidate.activityRankingScore;
    final mutualInterests = _mutualInterestsPercent(candidate);
    final responseRate = _responseRateProxy(candidate);
    final baraka = getBarakaScore(candidate.id).clamp(0, 100);
    final behaviorPreference = _behaviorPreferenceScore(candidate);

    return (compatibility * 0.34) +
        (quality * 0.20) +
        (activity * 0.15) +
        (mutualInterests * 0.10) +
        (responseRate * 0.05) +
        (behaviorPreference * 0.11) +
        (baraka * 0.05);
  }

  String _cityKey(UserModel user) =>
      (user.profile?.city ?? '').trim().toLowerCase();

  String _professionKey(UserModel user) =>
      (user.profile?.jobTitle ?? '').trim().toLowerCase();

  String _ageBracket(UserModel user) {
    final age = user.age;
    if (age <= 0) return '';
    if (age <= 24) return '18_24';
    if (age <= 29) return '25_29';
    if (age <= 34) return '30_34';
    if (age <= 39) return '35_39';
    return '40_plus';
  }

  int _consecutiveTraitCount(
    List<UserModel> ordered,
    String trait,
    String Function(UserModel) selector,
  ) {
    if (trait.isEmpty) return 0;
    var count = 0;
    for (var i = ordered.length - 1; i >= 0; i--) {
      if (selector(ordered[i]) != trait) break;
      count++;
    }
    return count;
  }

  bool _canAppendWithDiversity(List<UserModel> ordered, UserModel candidate) {
    final city = _cityKey(candidate);
    final ageBracket = _ageBracket(candidate);
    final profession = _professionKey(candidate);

    if (city.isNotEmpty &&
        _consecutiveTraitCount(ordered, city, _cityKey) >= 3) {
      return false;
    }
    if (ageBracket.isNotEmpty &&
        _consecutiveTraitCount(ordered, ageBracket, _ageBracket) >= 2) {
      return false;
    }
    if (profession.isNotEmpty &&
        _consecutiveTraitCount(ordered, profession, _professionKey) >= 2) {
      return false;
    }

    return true;
  }

  List<UserModel> _applyDiversityOrdering(List<UserModel> ranked) {
    final remaining = List<UserModel>.from(ranked);
    final output = <UserModel>[];

    while (remaining.isNotEmpty) {
      UserModel? picked;
      for (final candidate in remaining) {
        if (_canAppendWithDiversity(output, candidate)) {
          picked = candidate;
          break;
        }
      }

      picked ??= remaining.first;
      output.add(picked);
      remaining.remove(picked);
    }

    return output;
  }

  List<UserModel> _rankDiscoverUsers(List<UserModel> users) {
    final filtered = users.where(_passesQualityGate).toList(growable: false);

    final scored = List<UserModel>.from(filtered)
      ..sort((a, b) {
        final diff = _rankingScore(b).compareTo(_rankingScore(a));
        if (diff != 0) return diff;

        final aLast = a.lastLoginAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bLast = b.lastLoginAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bLast.compareTo(aLast);
      });

    return _applyDiversityOrdering(scored);
  }

  void _trimSwipeHistory() {
    if (_swipeHistoryStack.length <= _maxSwipeHistoryEntries) return;
    final removeCount = _swipeHistoryStack.length - _maxSwipeHistoryEntries;
    _swipeHistoryStack.removeRange(0, removeCount);
  }

  void _updateLastSwipedUserFromHistory() {
    lastSwipedUser.value = _swipeHistoryStack.isEmpty
        ? null
        : _swipeHistoryStack.last.user;
  }

  void _pushSwipeHistoryEntry(
    UserModel user,
    String action, {
    required int originalIndex,
    String? nextUserId,
    UserModel? nextUser,
    bool matched = false,
    String? matchId,
  }) {
    _swipeHistoryStack.add(
      _SwipeHistoryEntry(
        user: user,
        action: action,
        originalIndex: originalIndex,
        occurredAt: DateTime.now(),
        nextUserId: nextUserId,
        nextUser: nextUser,
        matched: matched,
        matchId: matchId,
      ),
    );
    _trimSwipeHistory();
    _updateLastSwipedUserFromHistory();
  }

  _SwipeHistoryEntry? _popHistoryEntryForRewind({String? targetUserId}) {
    if (_swipeHistoryStack.isEmpty) return null;

    final normalizedTarget = (targetUserId ?? '').trim();
    if (normalizedTarget.isNotEmpty) {
      for (var index = _swipeHistoryStack.length - 1; index >= 0; index--) {
        final candidate = _swipeHistoryStack[index];
        if (candidate.user.id == normalizedTarget) {
          final removed = _swipeHistoryStack.removeAt(index);
          _updateLastSwipedUserFromHistory();
          return removed;
        }
      }
    }

    final removed = _swipeHistoryStack.removeLast();
    _updateLastSwipedUserFromHistory();
    return removed;
  }

  Future<T> _enqueueSwipeMutation<T>(Future<T> Function() task) {
    final completer = Completer<T>();

    _swipeMutationQueue = _swipeMutationQueue
        .catchError((_) {
          // Keep the queue alive after a previous failure.
        })
        .then((_) async {
          try {
            final result = await task();
            completer.complete(result);
          } catch (error, stackTrace) {
            completer.completeError(error, stackTrace);
          }
        });

    return completer.future;
  }

  Future<void> _waitForSwipeMutations() async {
    await _swipeMutationQueue.catchError((_) {
      // Ignore previous mutation errors when draining queue.
    });
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
    final exclusionIds = _discoverExclusionIds();
    if (exclusionIds.contains(normalized)) {
      _seenUserIds.add(normalized);
      return true;
    }

    return false;
  }

  Future<void> fetchFeaturedAd({bool forceRefresh = false}) async {
    if (isLoadingFeaturedAd.value) return;
    if (!forceRefresh && featuredAd.value != null) return;

    isLoadingFeaturedAd.value = true;
    try {
      final response = await _api.get(
        ApiConstants.adsFeed,
        queryParameters: {'limit': 1},
      );
      final resolvedAd = _extractFeaturedAd(response.data);
      if (resolvedAd != null) {
        featuredAd.value = resolvedAd;
        final adId = (resolvedAd['id'] ?? '').toString().trim();
        if (adId.isNotEmpty) {
          unawaited(trackAdImpression(adId));
        }
      }
    } catch (e) {
      debugPrint('[Home] fetchFeaturedAd error: $e');
    } finally {
      isLoadingFeaturedAd.value = false;
    }
  }

  Future<void> trackAdImpression(String adId) async {
    final normalized = adId.trim();
    if (normalized.isEmpty || _trackedAdImpressions.contains(normalized)) {
      return;
    }

    _trackedAdImpressions.add(normalized);
    try {
      await _api.post(ApiConstants.adImpression(normalized));
    } catch (e) {
      debugPrint('[Home] trackAdImpression error: $e');
      _trackedAdImpressions.remove(normalized);
    }
  }

  Future<void> trackAdClick(String adId) async {
    final normalized = adId.trim();
    if (normalized.isEmpty) return;

    try {
      await _api.post(ApiConstants.adClick(normalized));
    } catch (e) {
      debugPrint('[Home] trackAdClick error: $e');
    }
  }

  Map<String, dynamic>? _extractFeaturedAd(dynamic raw) {
    final root = _mapOrEmpty(raw);
    final data = _mapOrEmpty(root['data']);

    final listCandidates = <dynamic>[
      root['items'],
      root['results'],
      root['ads'],
      root['data'],
      data['items'],
      data['results'],
      data['ads'],
      data['data'],
      raw,
    ];

    for (final candidate in listCandidates) {
      if (candidate is! List || candidate.isEmpty) {
        continue;
      }
      for (final item in candidate) {
        final normalized = _normalizeAdPayload(item);
        if (normalized != null) {
          return normalized;
        }
      }
    }

    final singleCandidates = <dynamic>[
      root['ad'],
      data['ad'],
      root['item'],
      data['item'],
    ];

    for (final candidate in singleCandidates) {
      final normalized = _normalizeAdPayload(candidate);
      if (normalized != null) {
        return normalized;
      }
    }

    return null;
  }

  Map<String, dynamic>? _normalizeAdPayload(dynamic raw) {
    final map = _mapOrEmpty(raw);
    if (map.isEmpty) return null;

    final id = _firstAdString(map, const ['id', '_id', 'adId', 'ad_id']);
    if (id == null || id.isEmpty) return null;

    final title =
        _firstAdString(map, const ['title', 'headline', 'name']) ?? 'Sponsored';
    final description = _firstAdString(map, const [
      'description',
      'subtitle',
      'body',
      'text',
    ]);
    final imageUrl = _firstAdString(map, const [
      'imageUrl',
      'image_url',
      'image',
      'thumbnail',
      'cover',
    ]);
    final link = _firstAdString(map, const [
      'link',
      'url',
      'buttonLink',
      'button_link',
      'ctaUrl',
    ]);
    final buttonText =
        _firstAdString(map, const ['buttonText', 'ctaText', 'ctaLabel']) ??
        'Learn more';

    if (title.trim().isEmpty && (imageUrl == null || imageUrl.trim().isEmpty)) {
      return null;
    }

    return {
      'id': id,
      'title': title,
      'description': ?description,
      'imageUrl': ?imageUrl,
      'link': ?link,
      if (buttonText.trim().isNotEmpty) 'buttonText': buttonText,
    };
  }

  Map<String, dynamic> _mapOrEmpty(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  String? _firstAdString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return null;
  }

  Future<void> refreshDiscoverUsers() => fetchDiscoverUsers(forceRefresh: true);

  bool get isLoadingMoreUsers => _isLoadingMore.value;

  Future<void> fetchDiscoverUsers({bool forceRefresh = false}) async {
    if (isLoading.value) {
      if (forceRefresh) {
        _pendingForceRefreshAfterLoad = true;
      }
      return;
    }
    final hasVisibleDeck = discoverUsers.isNotEmpty;
    final shouldBlockUi = !hasVisibleDeck;
    if (shouldBlockUi) {
      isLoading.value = true;
    }
    hasError.value = false;

    if (!forceRefresh && discoverUsers.isNotEmpty) {
      debugPrint(
        '[Home] fetchDiscoverUsers: deck already hydrated locally, skipping hard reload',
      );
      isEmpty.value = false;
      _prefetchDiscoverBufferIfNeeded();
      unawaited(_persistDiscoverDeckState());
      isLoading.value = false;
      return;
    }

    _page.value = 1;
    if (forceRefresh) {
      _hasMore.value = true;
      _discoverNextCursor = null;
      currentCardIndex.value = 0;
    }
    debugPrint(
      '[Home] fetchDiscoverUsers: starting (forceRefresh=$forceRefresh)...',
    );

    // Verify we have a valid auth token
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) {
      debugPrint(
        '[Home] fetchDiscoverUsers: NO AUTH TOKEN - user not logged in',
      );
      hasError.value = true;
      isEmpty.value = true;
      isLoading.value = false;
      return;
    }
    debugPrint('[Home] fetchDiscoverUsers: auth token present');
    unawaited(fetchFeaturedAd(forceRefresh: forceRefresh));

    // Check location but do NOT block discovery ط£آ¢أ¢â€ڑآ¬أ¢â‚¬â€Œ fetch users regardless
    debugPrint(
      '[Home] fetchDiscoverUsers: using cached locationGranted=${locationGranted.value}',
    );

    try {
      final initialForceRefresh =
          forceRefresh ||
          (_discoverNextCursor == null && discoverUsers.isEmpty);

      // Add timeout to prevent hanging
      var users = await _fetchPage(1, forceRefresh: initialForceRefresh)
          .timeout(
            _discoverRequestTimeout,
            onTimeout: () {
              throw TimeoutException('Request timeout while fetching users');
            },
          );

      var attempts = 1;
      while (users.isEmpty &&
          _hasMore.value &&
          attempts < _discoverMaxEnsureAttempts) {
        attempts++;
        users = await _fetchPage(attempts, forceRefresh: false).timeout(
          _discoverRequestTimeout,
          onTimeout: () {
            throw TimeoutException('Request timeout while fetching users');
          },
        );
      }

      var deckUsers = users;
      if (deckUsers.isEmpty) {
        deckUsers = await _recoverDiscoverUsersAfterEmptyFetch();
      }

      discoverUsers.assignAll(_rankDiscoverUsers(deckUsers));
      currentCardIndex.value = 0;

      isEmpty.value = discoverUsers.isEmpty;
      _dismissStartupRadarIfReady();
      debugPrint(
        '[Home] fetchDiscoverUsers: loaded ${deckUsers.length} users, total on screen: ${discoverUsers.length}',
      );

      if (discoverUsers.isNotEmpty) {
        final userIds = discoverUsers.map((u) => u.id).toList(growable: false);
        // Keep first paint responsive: score hydration and reranking happen in background.
        unawaited(
          _storage
              .cacheDiscoverUsers(discoverUsers.map((u) => u.toJson()).toList())
              .catchError((_) {}),
        );
        _prefetchDiscoverBufferIfNeeded();
        unawaited(_persistDiscoverDeckState());
        unawaited(_hydrateDiscoverScores(userIds));
      } else if (_hasMore.value) {
        // Keep filling in the background when the first server slice is fully
        // filtered by local seen/exclusion constraints.
        unawaited(_loadMoreUsersAppended(reason: 'initial_empty_retry'));
      }
    } catch (e, stackTrace) {
      debugPrint('[Home] fetchDiscoverUsers ERROR: $e');
      debugPrint('[Home] fetchDiscoverUsers STACK: $stackTrace');

      // Extract detailed error info from DioException
      if (e is DioException) {
        debugPrint(
          '[Home] fetchDiscoverUsers HTTP STATUS: ${e.response?.statusCode}',
        );
        debugPrint(
          '[Home] fetchDiscoverUsers RESPONSE BODY: ${e.response?.data}',
        );
        debugPrint(
          '[Home] fetchDiscoverUsers REQUEST URL: ${e.requestOptions.uri}',
        );

        // Show user-friendly error message
        if (e.response?.statusCode == 401) {
          final onAuthRoute =
              Get.currentRoute == AppRoutes.login ||
              Get.currentRoute == AppRoutes.onboarding ||
              Get.currentRoute == AppRoutes.splash;
          final shouldShowSessionExpired =
              _auth.isLoggedIn.value &&
              !_auth.isLoggingOut.value &&
              !onAuthRoute;

          if (shouldShowSessionExpired) {
            Helpers.showSnackbar(
              message: 'Session expired. Please login again.',
              isError: true,
            );
          }
        } else if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout) {
          Helpers.showSnackbar(
            message: 'Connection error. Check your internet.',
            isError: true,
          );
        }
      }

      hasError.value = true;
      // Only show empty if we have no cached users displayed
      if (discoverUsers.isEmpty) {
        isEmpty.value = true;
      }
    } finally {
      if (shouldBlockUi) {
        isLoading.value = false;
      }

      if (_pendingForceRefreshAfterLoad) {
        _pendingForceRefreshAfterLoad = false;
        unawaited(fetchDiscoverUsers(forceRefresh: true));
      }
    }
  }

  Future<void> _hydrateDiscoverScores(List<String> userIds) async {
    if (userIds.isEmpty) return;

    try {
      await Future.wait([
        _fetchBulkBaraka(userIds),
        _fetchBulkCompatibility(userIds),
      ]);

      discoverUsers.assignAll(
        _rankDiscoverUsers(
          _sanitizeDiscoverUsers(discoverUsers.toList(growable: false)),
        ),
      );

      if (currentCardIndex.value >= discoverUsers.length) {
        currentCardIndex.value = discoverUsers.isEmpty
            ? 0
            : discoverUsers.length - 1;
      }
      isEmpty.value = discoverUsers.isEmpty;
      _prefetchDiscoverBufferIfNeeded();
      unawaited(_persistDiscoverDeckState());
    } catch (e) {
      debugPrint('[Home] score hydration failed: $e');
    }
  }

  Future<List<UserModel>> _fetchPage(
    int page, {
    bool forceRefresh = false,
  }) async {
    final requestCursor = forceRefresh
        ? null
        : (_discoverNextCursor?.trim().isNotEmpty == true
              ? _discoverNextCursor!.trim()
              : null);
    final usesCursor = requestCursor != null && requestCursor.isNotEmpty;
    final queryParameters = _buildDiscoverQueryParameters(
      page: usesCursor ? null : page,
      limit: _discoverInitialBufferSize,
      forceRefresh: forceRefresh,
      cursor: requestCursor,
      includeDeckMeta: true,
    );
    debugPrint('[Home] _fetchPage($page): params=$queryParameters');
    final response = await _api.get(
      ApiConstants.search,
      queryParameters: queryParameters,
    );
    final data = response.data;
    debugPrint('[Home] _fetchPage($page): response type=${data.runtimeType}');

    // Robustly extract the users list from various response shapes
    List<dynamic> list;
    Map<String, dynamic>? rootMap;
    Map<String, dynamic>? nestedMap;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      rootMap = data.map((key, value) => MapEntry(key.toString(), value));

      final nested = rootMap['data'];
      if (nested is Map) {
        nestedMap = nested.map((key, value) => MapEntry(key.toString(), value));
      }

      final candidate =
          rootMap['users'] ??
          rootMap['results'] ??
          rootMap['profiles'] ??
          nestedMap?['users'] ??
          nestedMap?['results'] ??
          nestedMap?['profiles'] ??
          (nested is List ? nested : (nestedMap?['users'])) ??
          <dynamic>[];
      list = candidate is List ? candidate : <dynamic>[];
    } else {
      debugPrint('[Home] _fetchPage($page): unexpected data=$data');
      list = [];
    }

    final users = _sanitizeDiscoverUsers(
      list.whereType<Map>().map(UserModel.fromApiEntry).toList(),
    );

    final parsedHasMore = _parseDynamicBool(
      rootMap?['hasMore'] ?? nestedMap?['hasMore'],
    );
    final nextCursorRaw = rootMap?['nextCursor'] ?? nestedMap?['nextCursor'];
    final normalizedNextCursor = (nextCursorRaw is String)
        ? nextCursorRaw.trim().isEmpty
              ? null
              : nextCursorRaw.trim()
        : null;

    final expectsDeckMeta =
        queryParameters['includeDeckMeta'] == true ||
        usesCursor ||
        forceRefresh;
    if (parsedHasMore != null || nextCursorRaw != null || expectsDeckMeta) {
      _discoverNextCursor = normalizedNextCursor;
      if (parsedHasMore != null) {
        _hasMore.value = parsedHasMore;
      } else if (normalizedNextCursor != null) {
        _hasMore.value = true;
      } else {
        _hasMore.value = users.isNotEmpty;
      }
    } else if (users.isEmpty) {
      _hasMore.value = false;
    }

    debugPrint(
      '[Home] _fetchPage($page): parsed ${users.length} users after filtering, hasMore=${_hasMore.value}, nextCursor=${_discoverNextCursor ?? 'null'}',
    );
    return users;
  }

  Future<void> loadMoreUsers() async {
    await _loadMoreUsersAppended(reason: 'manual_load_more');
  }

  bool _redirectToAccountStatusIfRestricted(dynamic error) {
    if (error is! DioException) {
      return false;
    }

    final raw = error.response?.data;
    final restrictedStatus = extractRestrictedAccountStatus(raw);
    if (restrictedStatus == null) {
      return false;
    }

    // Suspended users are allowed to use the app and see non-blocking UI.
    if (restrictedStatus == 'suspended') {
      return false;
    }

    final args = buildRestrictedAccountArguments(
      _auth.currentUser.value,
      fallbackStatus: restrictedStatus,
      fallbackReason: extractRestrictedAccountReason(raw),
      fallbackSupportMessage: extractRestrictedAccountSupportMessage(raw),
      fallbackActionRequired: extractRestrictedAccountActionRequired(raw),
      fallbackStaffMessage: extractRestrictedAccountStaffMessage(raw),
      fallbackExpiresAt: extractRestrictedAccountExpiresAt(raw),
    );

    if (args == null) {
      return false;
    }

    final targetRoute = restrictedStatus == 'banned'
        ? AppRoutes.contactSupport
        : AppRoutes.accountStatus;

    if (Get.currentRoute != targetRoute) {
      Get.offAllNamed(targetRoute, arguments: args);
    }
    return true;
  }

  Future<bool> likeUser(
    String userId, {
    int? swiperCurrentIndex,
    UserModel? fallbackUser,
  }) async {
    debugPrint('[Home] likeUser: $userId');
    if (userId.isEmpty) {
      return false;
    }
    triggerSwipeButtonCue('like');
    final discoverUser = discoverUsers.firstWhereOrNull((u) => u.id == userId);
    final effectiveUser = discoverUser ?? fallbackUser;
    if ((effectiveUser != null && _isCurrentUser(effectiveUser)) ||
        _isCurrentUserId(userId)) {
      Helpers.showSnackbar(
        message: 'You cannot like your own profile.',
        isError: true,
      );
      if (discoverUser != null) {
        _processSwipedUser(userId, swiperCurrentIndex: swiperCurrentIndex);
      }
      return false;
    }
    if (effectiveUser != null && !_isOppositeGenderUser(effectiveUser)) {
      if (discoverUser != null) {
        _processSwipedUser(userId, swiperCurrentIndex: swiperCurrentIndex);
      }
      return false;
    }

    final hasUnlimitedLikes = _monetization.isUnlimitedLikes.value;
    final canUseLike = _monetization.canUseLikes || hasPaidPremiumPlan;
    if (!canUseLike) {
      Helpers.showSnackbar(
        message: 'No likes remaining for today. Upgrade for unlimited likes.',
        isError: true,
      );
      Get.toNamed(AppRoutes.subscription);
      return false;
    }

    final removedSwipe = discoverUser == null
        ? null
        : _processSwipedUser(userId, swiperCurrentIndex: swiperCurrentIndex);
    final swipedUser = removedSwipe?.user ?? effectiveUser;
    try {
      final response = await _enqueueSwipeMutation(
        () => _api.post(
          ApiConstants.swipe,
          data: {'targetUserId': userId, 'action': 'like'},
        ),
      );
      if (effectiveUser != null) {
        _recordSwipeBehavior(effectiveUser, positive: true);
      }
      if (!hasUnlimitedLikes && _monetization.remainingLikes.value > 0) {
        _monetization.remainingLikes.value--;
      }
      unawaited(_monetization.fetchEntitlements());
      final isMatch = response.data?['matched'] ?? false;
      final matchId = MatchFoundPresentationGuard.extractMatchId(response.data);
      if (swipedUser != null) {
        if (removedSwipe != null) {
          _pushSwipeHistoryEntry(
            swipedUser,
            'like',
            originalIndex: removedSwipe.originalIndex,
            nextUserId: removedSwipe.nextUserId,
            nextUser: removedSwipe.nextUser,
            matched: isMatch == true,
            matchId: matchId,
          );
        }
        _syncUsersInteractions(
          swipedUser,
          action: 'like',
          matched: isMatch,
          matchId: matchId,
        );
      }
      debugPrint('[Home] likeUser response: matched=$isMatch');
      if (isMatch) {
        final matchedUser = swipedUser ?? lastSwipedUser.value;
        _presentMatchFound(matchedUser, matchId: matchId);
      }
      _refreshRelationshipSurfaces(includeChat: isMatch == true);
      unawaited(ensureDiscoverBufferReady());
      return true;
    } catch (e) {
      _restoreSwipedUser(removedSwipe);
      debugPrint('[Home] likeUser ERROR: $e');
      if (_redirectToAccountStatusIfRestricted(e)) {
        return false;
      }
      Helpers.showSnackbar(
        message: Helpers.extractErrorMessage(e),
        isError: true,
      );
      return false;
    }
  }

  Future<bool> passUser(
    String userId, {
    int? swiperCurrentIndex,
    UserModel? fallbackUser,
  }) async {
    debugPrint('[Home] passUser: $userId');
    if (userId.isNotEmpty) {
      triggerSwipeButtonCue('pass');
    }
    final discoverUser = discoverUsers.firstWhereOrNull((u) => u.id == userId);
    final effectiveUser = discoverUser ?? fallbackUser;
    if (userId.isEmpty ||
        _isCurrentUserId(userId) ||
        (effectiveUser != null && _isCurrentUser(effectiveUser))) {
      if (discoverUser != null) {
        _processSwipedUser(userId, swiperCurrentIndex: swiperCurrentIndex);
      }
      return false;
    }
    if (effectiveUser != null && !_isOppositeGenderUser(effectiveUser)) {
      if (discoverUser != null) {
        _processSwipedUser(userId, swiperCurrentIndex: swiperCurrentIndex);
      }
      return false;
    }

    final removedSwipe = discoverUser == null
        ? null
        : _processSwipedUser(userId, swiperCurrentIndex: swiperCurrentIndex);
    final swipedUser = removedSwipe?.user ?? effectiveUser;
    try {
      await _enqueueSwipeMutation(
        () => _api.post(
          ApiConstants.swipe,
          data: {'targetUserId': userId, 'action': 'pass'},
        ),
      );
      if (effectiveUser != null) {
        _recordSwipeBehavior(effectiveUser, positive: false);
      }
      if (swipedUser != null) {
        if (removedSwipe != null) {
          _pushSwipeHistoryEntry(
            swipedUser,
            'pass',
            originalIndex: removedSwipe.originalIndex,
            nextUserId: removedSwipe.nextUserId,
            nextUser: removedSwipe.nextUser,
          );
        }
        _syncUsersInteractions(swipedUser, action: 'pass');
      }
      unawaited(_monetization.fetchEntitlements());
      unawaited(ensureDiscoverBufferReady());
      return true;
    } catch (e) {
      _restoreSwipedUser(removedSwipe);
      debugPrint('[Home] passUser ERROR: $e');
      if (_redirectToAccountStatusIfRestricted(e)) {
        return false;
      }
      Helpers.showSnackbar(
        message: Helpers.extractErrorMessage(e),
        isError: true,
      );
      return false;
    }
  }

  Future<bool> complimentUser(
    String userId,
    String message, {
    int? swiperCurrentIndex,
    UserModel? fallbackUser,
  }) async {
    debugPrint('[Home] complimentUser: $userId');
    if (userId.isEmpty) {
      return false;
    }
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) {
      Helpers.showSnackbar(
        message: 'compliment_message_required'.tr,
        isError: true,
      );
      return false;
    }
    triggerSwipeButtonCue('compliment');
    final discoverUser = discoverUsers.firstWhereOrNull((u) => u.id == userId);
    final effectiveUser = discoverUser ?? fallbackUser;
    if ((effectiveUser != null && _isCurrentUser(effectiveUser)) ||
        _isCurrentUserId(userId)) {
      Helpers.showSnackbar(
        message: 'You cannot send a compliment to your own profile.',
        isError: true,
      );
      if (discoverUser != null) {
        _processSwipedUser(userId, swiperCurrentIndex: swiperCurrentIndex);
      }
      return false;
    }
    if (effectiveUser != null && !_isOppositeGenderUser(effectiveUser)) {
      if (discoverUser != null) {
        _processSwipedUser(userId, swiperCurrentIndex: swiperCurrentIndex);
      }
      return false;
    }

    final hasComplimentAccess =
        _monetization.canUseCompliments || hasPaidPremiumPlan;
    if (!hasComplimentAccess) {
      await _showComplimentsExhaustedDialog();
      return false;
    }

    final removedSwipe = discoverUser == null
        ? null
        : _processSwipedUser(userId, swiperCurrentIndex: swiperCurrentIndex);
    final swipedUser = removedSwipe?.user ?? effectiveUser;
    try {
      final response = await _enqueueSwipeMutation(
        () => _api.post(
          ApiConstants.swipe,
          data: {
            'targetUserId': userId,
            'action': 'compliment',
            'complimentMessage': normalizedMessage,
          },
        ),
      );
      if (effectiveUser != null) {
        _recordSwipeBehavior(effectiveUser, positive: true);
      }
      if (_monetization.remainingCompliments.value > 0) {
        _monetization.remainingCompliments.value--;
      }
      unawaited(_monetization.fetchEntitlements());
      final isMatch = response.data?['matched'] ?? false;
      final matchId = MatchFoundPresentationGuard.extractMatchId(response.data);
      if (swipedUser != null) {
        if (removedSwipe != null) {
          _pushSwipeHistoryEntry(
            swipedUser,
            'compliment',
            originalIndex: removedSwipe.originalIndex,
            nextUserId: removedSwipe.nextUserId,
            nextUser: removedSwipe.nextUser,
            matched: isMatch == true,
            matchId: matchId,
          );
        }
        _syncUsersInteractions(
          swipedUser,
          action: 'compliment',
          matched: isMatch,
          matchId: matchId,
        );
      }
      debugPrint('[Home] complimentUser response: matched=$isMatch');
      if (isMatch) {
        final matchedUser = swipedUser ?? lastSwipedUser.value;
        _presentMatchFound(matchedUser, matchId: matchId);
      }
      _refreshRelationshipSurfaces(includeChat: isMatch == true);
      unawaited(ensureDiscoverBufferReady());
      return true;
    } catch (e) {
      _restoreSwipedUser(removedSwipe);
      debugPrint('[Home] complimentUser ERROR: $e');
      if (_redirectToAccountStatusIfRestricted(e)) {
        return false;
      }
      final message = Helpers.extractErrorMessage(e);
      if (_shouldOpenComplimentShop(message)) {
        await _showComplimentsExhaustedDialog();
        return false;
      }
      Helpers.showSnackbar(message: message, isError: true);
      return false;
    }
  }

  _RemovedSwipeCard? _processSwipedUser(
    String userId, {
    int? swiperCurrentIndex,
  }) {
    if (discoverUsers.isEmpty) return null;

    final idx = discoverUsers.indexWhere((u) => u.id == userId);
    if (idx == -1) return null;

    final swipedUser = discoverUsers.removeAt(idx);
    final nextUser = discoverUsers.isNotEmpty ? discoverUsers.first : null;
    final nextUserId = nextUser?.id;
    _rememberSeenUserId(swipedUser.id);
    cardPhotoIndices.remove(swipedUser.id);
    cardDetailsExpanded.remove(swipedUser.id);
    currentCardIndex.value = 0;
    isEmpty.value = discoverUsers.isEmpty;

    if (discoverUsers.length <= _discoverPrefetchThreshold) {
      if (_hasMore.value && !_isLoadingMore.value) {
        unawaited(_loadMoreUsersAppended(reason: 'swipe_threshold_prefetch'));
      } else if (!_hasMore.value && discoverUsers.isEmpty) {
        isEmpty.value = true;
      }
    }

    debugPrint(
      '[Home] swipe processed: user=${swipedUser.id}, remainingDeck=${discoverUsers.length}, nextIndex=${currentCardIndex.value}',
    );
    unawaited(_persistDiscoverDeckState());
    return _RemovedSwipeCard(
      user: swipedUser,
      originalIndex: idx,
      nextUserId: nextUserId,
      nextUser: nextUser,
    );
  }

  void _restoreSwipedUser(_RemovedSwipeCard? removedSwipe) {
    if (removedSwipe == null) return;

    final userId = removedSwipe.user.id.trim();
    if (userId.isEmpty) return;

    if (!discoverUsers.any((candidate) => candidate.id == userId)) {
      final anchorId = removedSwipe.nextUserId?.trim() ?? '';
      var anchorResolved = false;
      var insertionIndex = removedSwipe.originalIndex.clamp(
        0,
        discoverUsers.length,
      );
      if (anchorId.isNotEmpty) {
        final anchorIndex = discoverUsers.indexWhere(
          (candidate) => candidate.id == anchorId,
        );
        if (anchorIndex >= 0) {
          insertionIndex = anchorIndex;
          anchorResolved = true;
        }
      }
      discoverUsers.insert(insertionIndex, removedSwipe.user);

      final fallbackAnchor = removedSwipe.nextUser;
      final fallbackAnchorId = fallbackAnchor?.id.trim() ?? '';
      if (anchorResolved ||
          fallbackAnchor == null ||
          fallbackAnchorId.isEmpty ||
          fallbackAnchorId == userId) {
        // Explicit anchor already restored or no valid fallback snapshot available.
      } else if (!discoverUsers.any(
        (candidate) => candidate.id == fallbackAnchorId,
      )) {
        discoverUsers.insert(
          (insertionIndex + 1).clamp(0, discoverUsers.length),
          fallbackAnchor,
        );
      }
    }

    _seenUserIds.remove(userId);
    currentCardIndex.value = 0;
    isEmpty.value = false;
    unawaited(_storage.removeSeenDiscoverUserId(userId));
    unawaited(_persistDiscoverDeckState());
  }

  void _restoreRewoundUserAsActive(
    UserModel rewoundUser,
    _SwipeHistoryEntry? rewoundEntry,
  ) {
    final rewoundUserId = rewoundUser.id.trim();
    if (rewoundUserId.isEmpty) return;

    discoverUsers.removeWhere((candidate) => candidate.id == rewoundUserId);

    final anchorId = rewoundEntry?.nextUserId?.trim() ?? '';
    UserModel? anchorUser;
    if (anchorId.isNotEmpty && anchorId != rewoundUserId) {
      final anchorIndex = discoverUsers.indexWhere(
        (candidate) => candidate.id == anchorId,
      );
      if (anchorIndex >= 0) {
        anchorUser = discoverUsers.removeAt(anchorIndex);
      }
    }

    if (anchorUser == null) {
      final fallbackAnchor = rewoundEntry?.nextUser;
      final fallbackAnchorId = fallbackAnchor?.id.trim() ?? '';
      if (fallbackAnchor != null &&
          fallbackAnchorId.isNotEmpty &&
          fallbackAnchorId != rewoundUserId) {
        final existingFallbackIndex = discoverUsers.indexWhere(
          (candidate) => candidate.id == fallbackAnchorId,
        );
        if (existingFallbackIndex >= 0) {
          anchorUser = discoverUsers.removeAt(existingFallbackIndex);
        } else {
          anchorUser = fallbackAnchor;
        }
      }
    }

    discoverUsers.insert(0, rewoundUser);
    if (anchorUser != null && anchorUser.id != rewoundUserId) {
      discoverUsers.insert(1, anchorUser);
    }

    currentCardIndex.value = 0;
    isEmpty.value = false;
  }

  Future<void> _loadMoreUsersAppended({String reason = 'prefetch'}) async {
    if (_isLoadingMore.value || !_hasMore.value) return;
    _isLoadingMore.value = true;
    debugPrint(
      '[Home] _loadMoreUsersAppended($reason): page=${_page.value + 1}, cursor=${_discoverNextCursor ?? 'null'}',
    );
    try {
      var attempts = 0;
      var appendedAny = false;

      while (attempts < _discoverMaxEnsureAttempts && _hasMore.value) {
        attempts++;
        _page.value++;
        final moreUsers = await _fetchPage(_page.value);
        final existingIds = discoverUsers.map((u) => u.id).toSet();
        final uniqueMoreUsers = moreUsers
            .where((u) => !existingIds.contains(u.id))
            .toList(growable: false);

        if (uniqueMoreUsers.isEmpty) {
          if (!_hasMore.value) {
            break;
          }
          continue;
        }

        appendedAny = true;

        // APPEND ONLY. Do NOT call assignAll() or rank over the entire active array
        // as that forces Obx to instantly rebuild the Swiper, destroying animation states.
        discoverUsers.addAll(uniqueMoreUsers);

        // Fetch scores silently in the background
        final ids = uniqueMoreUsers.map((u) => u.id).toList(growable: false);
        unawaited(
          Future.wait([_fetchBulkBaraka(ids), _fetchBulkCompatibility(ids)]),
        );

        unawaited(_persistDiscoverDeckState());
        break;
      }

      if (!appendedAny && !_hasMore.value && discoverUsers.isEmpty) {
        isEmpty.value = true;
      }
    } catch (e) {
      debugPrint('[Home] _loadMoreUsersAppended ERROR: $e');
      _page.value--;
    } finally {
      _isLoadingMore.value = false;
    }
  }

  void _prefetchDiscoverBufferIfNeeded() {
    if (_isLoadingMore.value || !_hasMore.value) return;
    if (discoverUsers.length > _discoverPrefetchThreshold) {
      return;
    }
    unawaited(_loadMoreUsersAppended(reason: 'threshold_prefetch'));
  }

  void _syncUsersInteractions(
    UserModel user, {
    required String action,
    bool matched = false,
    String? matchId,
  }) {
    if (!Get.isRegistered<UsersController>()) return;

    Get.find<UsersController>().registerOutgoingSwipe(
      user,
      action: action,
      matched: matched,
      matchId: matchId,
      occurredAt: DateTime.now(),
    );
  }

  void _refreshRelationshipSurfaces({bool includeChat = false}) {
    if (Get.isRegistered<UsersController>()) {
      unawaited(Get.find<UsersController>().ensureUsersTabData(force: true));
    }

    if (includeChat && Get.isRegistered<ChatController>()) {
      unawaited(Get.find<ChatController>().fetchConversations());
    }
  }

  Future<void> rewindLastSwipe() async {
    if (_isRewindInFlight) {
      return;
    }

    if (_swipeHistoryStack.isEmpty && lastSwipedUser.value == null) {
      Helpers.showSnackbar(message: 'No swipe to undo');
      return;
    }

    _isRewindInFlight = true;
    try {
      // Ensure rewind always targets the latest persisted swipe on the backend.
      await _waitForSwipeMutations();

      final result = await _monetization.useRewind();
      if (result != null) {
        final undoneSwipe = result['undoneSwipe'] is Map<String, dynamic>
            ? result['undoneSwipe'] as Map<String, dynamic>
            : null;
        final undoneTargetId = (undoneSwipe?['targetUserId'] ?? '')
            .toString()
            .trim();

        final rewoundEntry = _popHistoryEntryForRewind(
          targetUserId: undoneTargetId,
        );
        final rewoundUser = rewoundEntry?.user ?? lastSwipedUser.value;
        if (rewoundUser == null) {
          Helpers.showSnackbar(message: 'No swipe to undo');
          return;
        }

        _seenUserIds.remove(rewoundUser.id);
        unawaited(_storage.removeSeenDiscoverUserId(rewoundUser.id));

        if (Get.isRegistered<UsersController>()) {
          final usersController = Get.find<UsersController>();
          usersController.undoOutgoingSwipe(rewoundUser.id);
          unawaited(usersController.fetchInteractions());
          unawaited(usersController.fetchMatches());
        }

        // Tinder-style rewind: the restored profile must become the active card,
        // and its prior successor must remain directly behind it.
        _restoreRewoundUserAsActive(rewoundUser, rewoundEntry);
        _updateLastSwipedUserFromHistory();
        unawaited(_monetization.fetchEntitlements());
        unawaited(ensureDiscoverBufferReady());
        unawaited(_persistDiscoverDeckState());
        Helpers.showSnackbar(message: 'Swipe undone!');
      }
    } catch (e) {
      Helpers.showSnackbar(message: 'Cannot rewind right now', isError: true);
    } finally {
      _isRewindInFlight = false;
    }
  }

  // ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ Rematch / Second Chance ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬
  Future<void> requestRematch(String targetUserId) async {
    try {
      final success = await _monetization.requestRematch(targetUserId);
      if (success) {
        Helpers.showSnackbar(message: 'Rematch request sent!');
      } else {
        Helpers.showSnackbar(
          message: 'Cannot send rematch request',
          isError: true,
        );
      }
    } catch (e) {
      Helpers.showSnackbar(message: 'Failed to send rematch', isError: true);
    }
  }

  // ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ Fetch Recommendations ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬
  final RxList<UserModel> recommendedUsers = <UserModel>[].obs;

  Future<void> fetchRecommendations() async {
    try {
      final response = await _api.get(ApiConstants.recommendedForYou);
      final list = response.data is List
          ? response.data
          : response.data['users'] ?? [];
      recommendedUsers.value = _rankDiscoverUsers(
        _sanitizeDiscoverUsers(
          (list as List).map(UserModel.fromApiEntry).toList(),
        ),
      );
    } catch (_) {}
  }

  // ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ Baraka Meter ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬
  Future<void> _fetchBulkBaraka(List<String> userIds) async {
    if (userIds.isEmpty) return;
    try {
      final response = await _api.post(
        ApiConstants.barakaBulk,
        data: {'targetUserIds': userIds},
      );
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

  // أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬ Compatibility Scores أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬
  int _normalizeCompatibilityScore(int raw) {
    if (raw < 0) return 0;
    if (raw > 100) return 100;
    return raw;
  }

  int? _parseCompatibilityScore(dynamic value) {
    if (value is num) {
      return _normalizeCompatibilityScore(value.round());
    }

    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) {
        return _normalizeCompatibilityScore(parsed.round());
      }
      return null;
    }

    if (value is Map) {
      final raw =
          value['score'] ??
          value['compatibilityScore'] ??
          value['compatibility'] ??
          value['matchScore'] ??
          value['value'] ??
          value['percent'];
      final direct = _parseCompatibilityScore(raw);
      if (direct != null) {
        return direct;
      }

      return _parseCompatibilityScore(value['data'] ?? value['result']);
    }

    return null;
  }

  bool _isCompatibilityWrapperKey(String key) {
    switch (key) {
      case 'data':
      case 'scores':
      case 'items':
      case 'results':
      case 'compatibility':
      case 'payload':
      case 'result':
      case 'meta':
      case 'message':
      case 'status':
      case 'success':
      case 'error':
        return true;
      default:
        return false;
    }
  }

  void _storeCompatibilityById(String userId, dynamic scorePayload) {
    final normalizedId = userId.trim();
    if (normalizedId.isEmpty) return;
    final parsed = _parseCompatibilityScore(scorePayload);
    if (parsed != null) {
      compatibilityScores[normalizedId] = parsed;
    }
  }

  void _extractCompatibilityPayload(dynamic payload) {
    if (payload is List) {
      for (final item in payload) {
        _extractCompatibilityPayload(item);
      }
      return;
    }

    if (payload is! Map) return;

    final candidateId =
        payload['targetUserId'] ??
        payload['userId'] ??
        payload['_id'] ??
        payload['id'];
    final candidateScore =
        payload['score'] ??
        payload['compatibilityScore'] ??
        payload['compatibility'] ??
        payload['matchScore'] ??
        payload['value'] ??
        payload['percent'];
    if (candidateId != null && candidateScore != null) {
      _storeCompatibilityById(candidateId.toString(), candidateScore);
    }

    for (final entry in payload.entries) {
      final key = entry.key.toString();
      if (_isCompatibilityWrapperKey(key)) {
        _extractCompatibilityPayload(entry.value);
        continue;
      }

      final direct = _parseCompatibilityScore(entry.value);
      if (direct != null) {
        compatibilityScores[key] = direct;
        continue;
      }

      if (entry.value is Map) {
        final nestedMap = entry.value as Map;
        final nestedId =
            nestedMap['targetUserId'] ?? nestedMap['userId'] ?? nestedMap['id'];
        if (nestedId != null) {
          _storeCompatibilityById(
            nestedId.toString(),
            nestedMap['score'] ?? nestedMap,
          );
        }
      }
    }
  }

  Future<void> _fetchBulkCompatibility(List<String> userIds) async {
    if (userIds.isEmpty) return;
    try {
      final response = await _api.post(
        ApiConstants.compatibilityBulk,
        data: {'targetUserIds': userIds},
      );
      _extractCompatibilityPayload(response.data);
    } catch (e) {
      debugPrint('[Home] _fetchBulkCompatibility error: \'$e\'');
    }
  }

  int getCompatibilityScore(String userId) {
    return compatibilityScores[userId] ?? 0;
  }

  int estimateCompatibilityScore(UserModel candidate) {
    return _computeClientCompatibilityScore(candidate);
  }

  // ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ Daily Insight ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬
  Future<void> fetchDailyInsight() async {
    try {
      final response = await _api.get(
        ApiConstants.dailyInsight,
        options: Options(extra: {'disable_retry': true}),
      );
      final data = response.data;
      if (data is Map) {
        dailyInsightContent.value = data['content']?.toString() ?? '';
        dailyInsightAuthor.value = data['author']?.toString() ?? '';
      }
    } catch (_) {}
  }

  // ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ Categories & Stories ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬
  Future<void> fetchCategories() async {
    try {
      isLoadingCategories.value = true;
      final response = await _api.get(
        ApiConstants.categories,
        options: Options(extra: {'disable_retry': true}),
      );
      final list = response.data is List
          ? response.data
          : response.data['categories'] ?? [];
      categories.assignAll(
        (list as List).map((c) => CategoryModel.fromJson(c)).toList(),
      );
    } catch (e) {
      debugPrint('[Home] fetchCategories error: $e');
    } finally {
      isLoadingCategories.value = false;
    }
  }

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
          '[Home] fetchSuccessStories skipped due to server error ${response.statusCode}',
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
    final hadDeck = discoverUsers.isNotEmpty;
    if (!hadDeck) {
      isLoading.value = true;
    }
    _page.value = 1;
    try {
      final response = await _api.get(ApiConstants.categoryUsers(categoryId));
      final list = response.data is List
          ? response.data
          : response.data['users'] ?? [];
      final users = _sanitizeDiscoverUsers(
        (list as List).map(UserModel.fromApiEntry).toList(),
      )..removeWhere((user) => _seenUserIds.contains(user.id));

      final ids = users.map((u) => u.id).toList(growable: false);
      if (ids.isNotEmpty) {
        await Future.wait([
          _fetchBulkBaraka(ids),
          _fetchBulkCompatibility(ids),
        ]);
      }

      discoverUsers.value = _rankDiscoverUsers(users);
      isEmpty.value = discoverUsers.isEmpty;
    } catch (e) {
      debugPrint('[Home] fetchUsersByCategory error: $e');
      hasError.value = true;
    } finally {
      if (!hadDeck) {
        isLoading.value = false;
      }
    }
  }

  void dismissDailyInsight() {
    dailyInsightDismissed.value = true;
  }

  // ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ Profile View Recording ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬
  Future<void> recordProfileView(String userId) async {
    if (!_uuidPattern.hasMatch(userId.trim())) return;
    try {
      await _api.post(ApiConstants.recordProfileView(userId));
    } catch (_) {}
  }

  void openFilter() => Get.toNamed(AppRoutes.filter);
  void openNotifications() => _notificationService.openNotifications();
  Future<void> openProfile() async {
    if (Get.currentRoute != AppRoutes.main) {
      await Get.offAllNamed(AppRoutes.main);
    }

    if (Get.isRegistered<NavigationController>()) {
      Get.find<NavigationController>().goToProfile();
    }
  }

  bool get canRewind =>
      hasRewindAccess &&
      _monetization.canUseRewind &&
      (_swipeHistoryStack.isNotEmpty || lastSwipedUser.value != null);
  bool get hasPaidPremiumPlan =>
      _monetization.isPremium || (currentUser?.isPremium ?? false);
  bool get hasRewindAccess =>
      _monetization.hasRewindFeatureAccess || hasPaidPremiumPlan;
  bool get canSendCompliment =>
      _monetization.canUseCompliments || hasPaidPremiumPlan;
  bool get hasBoostAccess =>
      _monetization.hasBoostAccess ||
      (currentUser?.profileBoostsCount ?? 0) > 0;
  int get remainingLikes => _monetization.remainingLikes.value;
  bool get isUnlimitedLikes => _monetization.isUnlimitedLikes.value;
  bool get isPremium {
    try {
      return _monetization.isPremium || (currentUser?.isPremium ?? false);
    } catch (_) {
      return currentUser?.isPremium ?? false;
    }
  }

  bool get isTrialActive => trialManager.isTrialActive;
  Duration get trialTimeRemaining => trialManager.trialTimeRemaining;
  UserModel? get currentUser => _auth.currentUser.value;

  bool _hasBoostInventory(int? rawCount) {
    final count = rawCount ?? 0;
    return count == -1 || count > 0;
  }

  Future<void> _openBoostShop() async {
    if (Get.currentRoute == AppRoutes.shop) return;
    await Get.toNamed(
      AppRoutes.shop,
      arguments: const {'initialType': 'boosts_pack'},
    );
  }

  Future<void> _showBoostZeroStateDialog() async {
    if (Get.isDialogOpen ?? false) {
      Helpers.showSnackbar(
        message:
            'You have 0 boosts remaining. Open the Shop to buy a boost pack.',
        isError: true,
      );
      return;
    }

    await Get.defaultDialog<void>(
      title: '0 boosts remaining',
      middleText:
          'You have 0 boosts remaining. Open the Shop to buy a boost pack and activate your profile again.',
      textCancel: 'Later',
      textConfirm: 'Open Shop',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back<void>();
        unawaited(_openBoostShop());
      },
    );
  }

  Future<void> _openComplimentsShop() async {
    if (Get.currentRoute == AppRoutes.shop) return;
    await Get.toNamed(
      AppRoutes.shop,
      arguments: const {'initialType': 'compliments_pack'},
    );
  }

  Future<void> _showComplimentsExhaustedDialog() async {
    if (Get.isDialogOpen ?? false) {
      Helpers.showSnackbar(
        message: 'No compliments left today. Buy a pack from the shop.',
        isError: true,
      );
      return;
    }

    await Get.defaultDialog<void>(
      title: 'No compliments left',
      middleText:
          'You have no compliments remaining today. Buy 3x, 10x, or 20x compliment packs to keep sending thoughtful messages.',
      textCancel: 'Later',
      textConfirm: 'View packs',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back<void>();
        unawaited(_openComplimentsShop());
      },
    );
  }

  bool _shouldOpenBoostUpgrade(String message) {
    final normalized = message.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return normalized.contains('no boosts remaining') ||
        normalized.contains('insufficient boosts') ||
        normalized.contains('not available on your current plan');
  }

  bool _shouldOpenComplimentShop(String message) {
    final normalized = message.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return normalized.contains('no compliments') ||
        normalized.contains('compliments remaining') ||
        normalized.contains('insufficient compliments') ||
        normalized.contains('compliment credits');
  }

  Future<bool> boostProfile() async {
    var remainingBoosts = currentUser?.profileBoostsCount ?? 0;
    if (!_hasBoostInventory(remainingBoosts)) {
      try {
        await _auth.fetchMe();
      } catch (_) {}

      remainingBoosts = currentUser?.profileBoostsCount ?? 0;
      if (!_hasBoostInventory(remainingBoosts)) {
        await _showBoostZeroStateDialog();
        return false;
      }
    }

    try {
      final activated = await _monetization.purchaseBoost(durationMinutes: 30);
      if (!activated) {
        Helpers.showSnackbar(message: 'something_went_wrong'.tr, isError: true);
        return false;
      }

      _monetization.isBoosted.value = true;
      unawaited(_monetization.fetchBoostStatus());
      unawaited(_monetization.fetchEntitlements());
      Helpers.showSnackbar(message: 'profile_boosted_msg'.tr);
      return true;
    } catch (e) {
      debugPrint('[Home] boostProfile error: $e');
      final message = Helpers.extractErrorMessage(e);
      if (_shouldOpenBoostUpgrade(message)) {
        final normalized = message.toLowerCase();
        if (normalized.contains('no boosts remaining') ||
            normalized.contains('insufficient boosts')) {
          await _showBoostZeroStateDialog();
        } else {
          unawaited(Get.toNamed(AppRoutes.subscription));
        }
        return false;
      }
      Helpers.showSnackbar(
        message: message.isNotEmpty ? message : 'something_went_wrong'.tr,
        isError: true,
      );
      return false;
    }
  }
}
