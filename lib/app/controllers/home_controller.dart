import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/controllers/navigation_controller.dart';
import 'package:methna_app/app/controllers/users_controller.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:methna_app/app/data/services/notification_service.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/constants/app_constants.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/utils/match_found_presentation_guard.dart';
import 'package:methna_app/core/services/trial_manager.dart';

import 'package:methna_app/app/data/services/location_service.dart';
import 'package:methna_app/app/data/services/storage_service.dart';
import 'package:methna_app/app/data/models/category_model.dart';
import 'package:methna_app/app/data/models/success_story_model.dart';

class HomeController extends GetxController {
  static const double distanceFilterMinKm = 20.0;
  static const double distanceFilterUnlimitedKm = 500.0;
  static const int _discoverPrefetchThreshold = 8;

  final ApiService _api = Get.find<ApiService>();
  final AuthService _auth = Get.find<AuthService>();
  final MonetizationService _monetization = Get.find<MonetizationService>();
  final LocationService _location = Get.find<LocationService>();
  final StorageService _storage = Get.find<StorageService>();
  final NotificationService _notificationService =
      Get.find<NotificationService>();

  void _presentMatchFound(UserModel? matchedUser) {
    if (matchedUser == null) return;
    if (Get.currentRoute == AppRoutes.matchFound) return;
    if (!MatchFoundPresentationGuard.shouldPresent(matchedUser.id)) return;
    Get.toNamed(AppRoutes.matchFound, arguments: {'user': matchedUser});
  }
  final TrialManager trialManager = Get.find<TrialManager>();

  final CardSwiperController swiperController = CardSwiperController();

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
  final RxBool locationGranted = false.obs;
  final RxBool showLocationGate = false.obs;
  final RxBool showStartupRadar = false.obs;
  final RxBool showSwipeTutorial = false.obs;
  final RxString swipeButtonCue = ''.obs;
  final RxMap<String, int> cardPhotoIndices = <String, int>{}.obs;
  final RxMap<String, bool> cardDetailsExpanded = <String, bool>{}.obs;

  // Filter state
  final RxInt minAge = 18.obs;
  final RxInt maxAge = 90.obs;
  final RxDouble maxDistance = 50.0.obs;
  final RxString genderFilter = 'all'.obs;
  final RxString countryFilter = ''.obs;
  final RxString cityFilter = ''.obs;
  final RxString educationFilter = ''.obs;
  final RxString religiousLevelFilter = ''.obs;
  final RxString prayerFrequencyFilter = ''.obs;
  final RxString marriageIntentionFilter = ''.obs;
  final RxString livingSituationFilter = ''.obs;
  final RxList<String> interestsFilter = <String>[].obs;
  final RxList<String> languagesFilter = <String>[].obs;
  final RxList<String> familyValuesFilter = <String>[].obs;
  final RxBool verifiedOnlyFilter = false.obs;
  final RxBool goGlobalFilter = false.obs;
  final RxBool useKm = true.obs;
  final RxBool recentlyActiveOnlyFilter = false.obs;
  final RxBool withPhotosOnlyFilter = false.obs;
  final RxInt minTrustScoreFilter = 0.obs;
  final RxBool backgroundCheckOnlyFilter = false.obs;

  // Pagination
  final RxInt _page = 1.obs;
  final RxBool _hasMore = true.obs;
  final RxBool _isLoadingMore = false.obs;
  final Set<String> _seenUserIds = {};

  // Rewind tracking
  final Rx<UserModel?> lastSwipedUser = Rx<UserModel?>(null);

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
  Timer? _startupRadarTimer;
  Timer? _swipeTutorialTimer;
  DateTime? _startupRadarStartedAt;
  bool _startupFlowHandled = false;
  bool _startupRadarDismissScheduled = false;

  // Behavior-based recommendation signals (client-side learning)
  static const String _behaviorSignalsStorageKey =
      'matching_behavior_signals_v1';
  static bool _startupRadarShownThisLaunch = false;
  final Map<String, double> _likedInterestWeights = <String, double>{};
  final Map<String, double> _passedInterestWeights = <String, double>{};
  double _preferredAgeCenter = 0;
  double _preferredDistanceKm = 0;
  int _positiveSignalCount = 0;
  int _negativeSignalCount = 0;
  int _swipeButtonCueVersion = 0;

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
    cardPhotoIndices[userId] =
        (current - 1 + photoCount) % photoCount;
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
    _seenUserIds.addAll(_storage.getSeenDiscoverUserIds());
    _currentUserWorker = ever<UserModel?>(_auth.currentUser, (_) {
      final sanitizedUsers = _sanitizeDiscoverUsers(discoverUsers);
      if (sanitizedUsers.length != discoverUsers.length) {
        discoverUsers.assignAll(sanitizedUsers);
        isEmpty.value = discoverUsers.isEmpty;
      }

      if (discoverUsers.isEmpty && !isLoading.value) {
        unawaited(fetchDiscoverUsers(forceRefresh: true));
      }
    });
    _loadFilters();
    _loadBehaviorSignals();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCachedUsersInstantly();
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
    _startupRadarTimer?.cancel();
    _swipeTutorialTimer?.cancel();
    _currentUserWorker?.dispose();
    super.onClose();
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
    showSwipeTutorial.value = true;
    _swipeTutorialTimer?.cancel();
    _swipeTutorialTimer = Timer(const Duration(seconds: 4), () {
      showSwipeTutorial.value = false;
    });
  }

  void dismissSwipeTutorial() {
    _swipeTutorialTimer?.cancel();
    showSwipeTutorial.value = false;
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
        isEmpty.value = false;
        debugPrint('[Home] Loaded ${users.length} cached users instantly');
      }
    } catch (e) {
      debugPrint('[Home] Failed to load cached users: $e');
    }
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
      await completer.future.timeout(const Duration(seconds: 10));
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
        unawaited(fetchDiscoverUsers(forceRefresh: true));
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
        unawaited(fetchDiscoverUsers(forceRefresh: true));
      }
      return;
    }

    if (_startupRadarShownThisLaunch) {
      showLocationGate.value = false;
      showStartupRadar.value = false;
      if (discoverUsers.isEmpty && !isLoading.value) {
        unawaited(fetchDiscoverUsers(forceRefresh: true));
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
    showStartupRadar.value = true;
    _startupRadarDismissScheduled = false;
    _startupRadarStartedAt = DateTime.now();

    _startupRadarTimer?.cancel();
    _startupRadarTimer = Timer(const Duration(seconds: 10), () {
      showStartupRadar.value = false;
    });

    if (!isLoading.value) {
      await fetchDiscoverUsers(forceRefresh: true);
    } else {
      _dismissStartupRadarIfReady();
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

  void _loadFilters() {
    final loadedMinAge = _storage.getString('filter_minAge') != null
      ? int.tryParse(_storage.getString('filter_minAge')!)
      : null;
    final loadedMaxAge = _storage.getString('filter_maxAge') != null
      ? int.tryParse(_storage.getString('filter_maxAge')!)
      : null;
    final normalizedMin = (loadedMinAge ?? 18).clamp(18, 90).toInt();
    final normalizedMax = (loadedMaxAge ?? 90).clamp(18, 90).toInt();
    minAge.value = math.min(normalizedMin, normalizedMax);
    maxAge.value = math.max(normalizedMin, normalizedMax);

    final loadedDistance = _storage.getString('filter_maxDistance') != null
      ? double.tryParse(_storage.getString('filter_maxDistance')!)
      : null;
    maxDistance.value = (loadedDistance ?? 50.0).clamp(
      distanceFilterMinKm,
      distanceFilterUnlimitedKm,
    );
    genderFilter.value = _storage.getString('filter_gender') ?? 'all';
    countryFilter.value = _storage.getString('filter_country') ?? '';
    cityFilter.value = _storage.getString('filter_city') ?? '';
    educationFilter.value = _storage.getString('filter_education') ?? '';
    religiousLevelFilter.value =
        _storage.getString('filter_religiousLevel') ?? '';
    prayerFrequencyFilter.value =
        _storage.getString('filter_prayerFrequency') ?? '';
    marriageIntentionFilter.value =
        _storage.getString('filter_marriageIntention') ?? '';
    livingSituationFilter.value =
        _storage.getString('filter_livingSituation') ?? '';
    final savedLanguages = _storage.getString('filter_languages') ?? '';
    languagesFilter.assignAll(
      savedLanguages.isEmpty
          ? const <String>[]
          : savedLanguages
                .split('||')
                .where((value) => value.trim().isNotEmpty),
    );
    final savedFamilyValues = _storage.getString('filter_familyValues') ?? '';
    familyValuesFilter.assignAll(
      savedFamilyValues.isEmpty
          ? const <String>[]
          : savedFamilyValues
                .split('||')
                .where((value) => value.trim().isNotEmpty),
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
    debugPrint('[Home] _loadFilters: loaded all filters from storage');
  }

  Future<void> saveFilters() async {
    await _storage.saveString('filter_minAge', minAge.value.toString());
    await _storage.saveString('filter_maxAge', maxAge.value.toString());
    await _storage.saveString(
      'filter_maxDistance',
      maxDistance.value.toString(),
    );
    await _storage.saveString('filter_gender', genderFilter.value);
    await _storage.saveString('filter_country', countryFilter.value);
    await _storage.saveString('filter_city', cityFilter.value);
    await _storage.saveString('filter_education', educationFilter.value);
    await _storage.saveString(
      'filter_religiousLevel',
      religiousLevelFilter.value,
    );
    await _storage.saveString(
      'filter_prayerFrequency',
      prayerFrequencyFilter.value,
    );
    await _storage.saveString(
      'filter_marriageIntention',
      marriageIntentionFilter.value,
    );
    await _storage.saveString(
      'filter_livingSituation',
      livingSituationFilter.value,
    );
    await _storage.saveString('filter_languages', languagesFilter.join('||'));
    await _storage.saveString(
      'filter_familyValues',
      familyValuesFilter.join('||'),
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

  /// Called from the "Enable Location" button ط£آ¢أ¢â€ڑآ¬أ¢â‚¬â€Œ requests permission with
  /// user feedback dialogs, then fetches discover users.
  Future<void> requestLocationAndFetch() async {
    final position = await _location.requestLocationWithFeedback();
    if (position != null) {
      locationGranted.value = true;
      await _storage.saveBool('location_permission_granted', true);
      fetchDiscoverUsers();
      return;
    }
    locationGranted.value = false;
    await _storage.saveBool('location_permission_granted', false);
  }

  Map<String, dynamic> get _filterParams {
    final requiredOppositeGender = _requiredOppositeGender;
    return {
      'limit': 20,
      if (requiredOppositeGender != null)
        'gender': requiredOppositeGender
      else if (genderFilter.value != 'all')
        'gender': genderFilter.value,
      'minAge': minAge.value,
      'maxAge': maxAge.value,
      if (!goGlobalFilter.value && locationGranted.value)
        if (maxDistance.value < distanceFilterUnlimitedKm)
          'maxDistance': maxDistance.value.round(),
      if (countryFilter.value.trim().isNotEmpty)
        'country': countryFilter.value.trim(),
      if (cityFilter.value.trim().isNotEmpty)
        'city': cityFilter.value.trim(),
      if (educationFilter.value.isNotEmpty) 'education': educationFilter.value,
      if (religiousLevelFilter.value.isNotEmpty)
        'religiousLevel': religiousLevelFilter.value,
      if (prayerFrequencyFilter.value.isNotEmpty)
        'prayerFrequency': prayerFrequencyFilter.value,
      if (marriageIntentionFilter.value.isNotEmpty)
        'marriageIntention': marriageIntentionFilter.value,
      if (livingSituationFilter.value.isNotEmpty)
        'livingSituation': livingSituationFilter.value,
      if (interestsFilter.isNotEmpty) 'interests': interestsFilter.toList(),
      if (languagesFilter.isNotEmpty) 'languages': languagesFilter.toList(),
      if (familyValuesFilter.isNotEmpty)
        'familyValues': familyValuesFilter.map(_toBackendEnumValue).toList(),
      if (verifiedOnlyFilter.value) 'verifiedOnly': true,
      if (recentlyActiveOnlyFilter.value) 'recentlyActiveOnly': true,
      if (withPhotosOnlyFilter.value) 'withPhotosOnly': true,
      if (minTrustScoreFilter.value > 0)
        'minTrustScore': minTrustScoreFilter.value,
      if (backgroundCheckOnlyFilter.value) 'backgroundCheckStatus': 'cleared',
    };
  }

  String _toBackendEnumValue(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r"[^a-z0-9]+"), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

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

  List<UserModel> _sanitizeDiscoverUsers(Iterable<UserModel> users) {
    _seenUserIds.addAll(_storage.getSeenDiscoverUserIds());
    final seen = <String>{};
    return users.where((u) {
      if (u.id.isEmpty) return false;
      if (_isCurrentUser(u)) return false;
      if (!_isOppositeGenderUser(u)) return false;
      if (_seenUserIds.contains(u.id.trim())) return false;
      return seen.add(u.id);
    }).toList();
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

    final completion = user.profile?.profileCompletionPercentage ?? 0;
    if (completion > 0 && completion < 20) return false;

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

  Future<void> refreshDiscoverUsers() => fetchDiscoverUsers(forceRefresh: true);

  bool get isLoadingMoreUsers => _isLoadingMore.value;

  Future<void> fetchDiscoverUsers({bool forceRefresh = false}) async {
    if (isLoading.value) return; // Prevent duplicate calls
    isLoading.value = true;
    hasError.value = false;
    // Keep previous data visible while loading (don't clear discoverUsers)
    _page.value = 1;
    _hasMore.value = true;
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

    // Check location but do NOT block discovery ط£آ¢أ¢â€ڑآ¬أ¢â‚¬â€Œ fetch users regardless
    debugPrint(
      '[Home] fetchDiscoverUsers: using cached locationGranted=${locationGranted.value}',
    );

    try {
      // Add timeout to prevent hanging
      var users = await _fetchPage(1, forceRefresh: forceRefresh).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timeout while fetching users');
        },
      );

      // Fallback: if no users found with filters, retry without distance/age filters
      if (users.isEmpty && locationGranted.value) {
        final requiredOppositeGender = _requiredOppositeGender;
        debugPrint(
          '[Home] fetchDiscoverUsers: 0 users with filters, retrying without distance...',
        );
        final fallbackResponse = await _api
            .get(
              ApiConstants.search,
              queryParameters: {
                'limit': 20,
                'page': 1,
                if (requiredOppositeGender case final requiredGender)
                  'gender': requiredGender,
                if (forceRefresh) 'forceRefresh': true,
              },
            )
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw TimeoutException('Fallback request timeout');
              },
            );
        final fbData = fallbackResponse.data;
        List<dynamic> fbList;
        if (fbData is List) {
          fbList = fbData;
        } else if (fbData is Map) {
          final nested = fbData['data'];
          final candidate =
              fbData['users'] ??
              fbData['results'] ??
              (nested is List
                  ? nested
                  : (nested is Map ? nested['users'] : null)) ??
              <dynamic>[];
          fbList = candidate is List ? candidate : <dynamic>[];
        } else {
          fbList = [];
        }
        users = _sanitizeDiscoverUsers(
          fbList.whereType<Map>().map(UserModel.fromApiEntry).toList(),
        );
        debugPrint(
          '[Home] fetchDiscoverUsers: fallback returned ${users.length} users',
        );
      }

      if (users.isNotEmpty || discoverUsers.isEmpty) {
        // Only replace if we got new data, OR if the screen was genuinely completely empty
        final sanitizedUsers = _sanitizeDiscoverUsers(users);
        discoverUsers.assignAll(_rankDiscoverUsers(sanitizedUsers));
        currentCardIndex.value = 0;
      }

      isEmpty.value = discoverUsers.isEmpty;
      _dismissStartupRadarIfReady();
      debugPrint(
        '[Home] fetchDiscoverUsers: loaded ${users.length} users, total on screen: ${discoverUsers.length}',
      );

      if (discoverUsers.isNotEmpty) {
        final userIds = discoverUsers.map((u) => u.id).toList(growable: false);
        await Future.wait([
          // Cache users locally for instant display on next app launch
          _storage
              .cacheDiscoverUsers(discoverUsers.map((u) => u.toJson()).toList())
              .catchError((_) {}),
          // Fetch Baraka scores for loaded users
          _fetchBulkBaraka(userIds).catchError((e) {
            debugPrint('[Home] Failed to fetch Baraka scores: $e');
          }),
          // Fetch compatibility scores in parallel
          _fetchBulkCompatibility(userIds).catchError((_) {}),
        ]);

        discoverUsers.assignAll(
          _rankDiscoverUsers(discoverUsers.toList(growable: false)),
        );
        isEmpty.value = discoverUsers.isEmpty;
        _prefetchDiscoverBufferIfNeeded();
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
          Helpers.showSnackbar(
            message: 'Session expired. Please login again.',
            isError: true,
          );
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
      isLoading.value = false;
    }
  }

  Future<List<UserModel>> _fetchPage(
    int page, {
    bool forceRefresh = false,
  }) async {
    debugPrint('[Home] _fetchPage($page): params=$_filterParams');
    final response = await _api.get(
      ApiConstants.search,
      queryParameters: {
        ..._filterParams,
        'page': page,
        if (forceRefresh) 'forceRefresh': true,
      },
    );
    final data = response.data;
    debugPrint('[Home] _fetchPage($page): response type=${data.runtimeType}');

    // Robustly extract the users list from various response shapes
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      final nested = data['data'];
      final candidate =
          data['users'] ??
          data['results'] ??
          data['profiles'] ??
          (nested is List
              ? nested
              : (nested is Map ? nested['users'] : null)) ??
          <dynamic>[];
      list = candidate is List ? candidate : <dynamic>[];
    } else {
      debugPrint('[Home] _fetchPage($page): unexpected data=$data');
      list = [];
    }

    final users = _sanitizeDiscoverUsers(
      list.whereType<Map>().map(UserModel.fromApiEntry).toList(),
    );

    // Deduplicate and filter out already seen users
    users.removeWhere((u) => _seenUserIds.contains(u.id));
    if (users.isEmpty) _hasMore.value = false;
    debugPrint(
      '[Home] _fetchPage($page): parsed ${users.length} users after filtering',
    );
    return users;
  }

  Future<void> loadMoreUsers() async {
    if (_isLoadingMore.value || !_hasMore.value) return;
    _isLoadingMore.value = true;
    debugPrint('[Home] loadMoreUsers: page=${_page.value + 1}');
    try {
      _page.value++;
      final moreUsers = await _fetchPage(_page.value);
      final existingIds = discoverUsers.map((u) => u.id).toSet();
      final uniqueMoreUsers = moreUsers
          .where((u) => !existingIds.contains(u.id))
          .toList(growable: false);

      if (uniqueMoreUsers.isNotEmpty) {
        discoverUsers.addAll(uniqueMoreUsers);
        debugPrint(
          '[Home] loadMoreUsers: loaded ${uniqueMoreUsers.length} more users',
        );

        final ids = uniqueMoreUsers.map((u) => u.id).toList(growable: false);
        await Future.wait([
          _fetchBulkBaraka(ids),
          _fetchBulkCompatibility(ids),
        ]);

        discoverUsers.assignAll(
          _rankDiscoverUsers(discoverUsers.toList(growable: false)),
        );
        isEmpty.value = discoverUsers.isEmpty;
      }
    } catch (e) {
      debugPrint('[Home] loadMoreUsers ERROR: $e');
      // Revert page increment on failure so retry fetches the same page
      _page.value--;
    } finally {
      _isLoadingMore.value = false;
    }
  }

  Future<bool> likeUser(String userId) async {
    debugPrint('[Home] likeUser: $userId');
    if (userId.isEmpty) {
      return false;
    }
    triggerSwipeButtonCue('like');
    final selectedUser = discoverUsers.firstWhereOrNull((u) => u.id == userId);
    if ((selectedUser != null && _isCurrentUser(selectedUser)) ||
        _isCurrentUserId(userId)) {
      Helpers.showSnackbar(
        message: 'You cannot like your own profile.',
        isError: true,
      );
      _removeUserById(userId);
      return false;
    }
    if (selectedUser != null && !_isOppositeGenderUser(selectedUser)) {
      _removeUserById(userId);
      return false;
    }

    final hasUnlimitedLikes =
        trialManager.isTrialActive || _monetization.isUnlimitedLikes.value;
    final canUseLike =
        hasUnlimitedLikes || _monetization.remainingLikes.value > 0;
    if (!canUseLike) {
      Helpers.showSnackbar(
        message: 'No likes remaining for today. Upgrade for unlimited likes.',
        isError: true,
      );
      Get.toNamed(AppRoutes.subscription);
      return false;
    }

    final swipedUser = _removeUserById(userId);
    try {
      final response = await _api.post(
        ApiConstants.swipe,
        data: {'targetUserId': userId, 'action': 'like'},
      );
      _rememberSeenUserId(userId);
      if (selectedUser != null) {
        _recordSwipeBehavior(selectedUser, positive: true);
      }
      if (!hasUnlimitedLikes && _monetization.remainingLikes.value > 0) {
        _monetization.remainingLikes.value--;
      }
      final isMatch = response.data?['matched'] ?? false;
      if (swipedUser != null) {
        _syncUsersInteractions(
          swipedUser,
          action: 'like',
          matched: isMatch,
        );
      }
      debugPrint('[Home] likeUser response: matched=$isMatch');
      if (isMatch) {
        final matchedUser = swipedUser ?? lastSwipedUser.value;
        _presentMatchFound(matchedUser);
      }
      return true;
    } catch (e) {
      debugPrint('[Home] likeUser ERROR: $e');
      if (swipedUser != null) {
        discoverUsers.insert(0, swipedUser);
        isEmpty.value = false;
      }
      Helpers.showSnackbar(
        message: Helpers.extractErrorMessage(e),
        isError: true,
      );
      return false;
    }
  }

  Future<bool> passUser(String userId) async {
    debugPrint('[Home] passUser: $userId');
    if (userId.isNotEmpty) {
      triggerSwipeButtonCue('pass');
    }
    final selectedUser = discoverUsers.firstWhereOrNull((u) => u.id == userId);
    if (userId.isEmpty ||
        _isCurrentUserId(userId) ||
        (selectedUser != null && _isCurrentUser(selectedUser))) {
      _removeUserById(userId);
      return false;
    }
    if (selectedUser != null && !_isOppositeGenderUser(selectedUser)) {
      _removeUserById(userId);
      return false;
    }

    final swipedUser = _removeUserById(userId);
    try {
      await _api.post(
        ApiConstants.swipe,
        data: {'targetUserId': userId, 'action': 'pass'},
      );
      _rememberSeenUserId(userId);
      if (selectedUser != null) {
        _recordSwipeBehavior(selectedUser, positive: false);
      }
      if (swipedUser != null) {
        _syncUsersInteractions(swipedUser, action: 'pass');
      }
      return true;
    } catch (e) {
      debugPrint('[Home] passUser ERROR: $e');
      if (swipedUser != null) {
        discoverUsers.insert(0, swipedUser);
        isEmpty.value = false;
      }
      Helpers.showSnackbar(
        message: Helpers.extractErrorMessage(e),
        isError: true,
      );
      return false;
    }
  }

  Future<bool> complimentUser(String userId, String message) async {
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
    final selectedUser = discoverUsers.firstWhereOrNull((u) => u.id == userId);
    if ((selectedUser != null && _isCurrentUser(selectedUser)) ||
        _isCurrentUserId(userId)) {
      Helpers.showSnackbar(
        message: 'You cannot send a compliment to your own profile.',
        isError: true,
      );
      _removeUserById(userId);
      return false;
    }
    if (selectedUser != null && !_isOppositeGenderUser(selectedUser)) {
      _removeUserById(userId);
      return false;
    }

    final hasComplimentAccess =
        trialManager.isEffectivePremium ||
        trialManager.isTrialActive ||
        _monetization.remainingCompliments.value > 0;
    if (!hasComplimentAccess) {
      Helpers.showSnackbar(
        message: 'No compliments remaining. Upgrade to send more compliments.',
        isError: true,
      );
      Get.toNamed(AppRoutes.subscription);
      return false;
    }

    final swipedUser = _removeUserById(userId);
    try {
      final response = await _api.post(
        ApiConstants.swipe,
        data: {
          'targetUserId': userId,
          'action': 'compliment',
          'complimentMessage': normalizedMessage,
        },
      );
      _rememberSeenUserId(userId);
      if (selectedUser != null) {
        _recordSwipeBehavior(selectedUser, positive: true);
      }
      if (!trialManager.isEffectivePremium &&
          !trialManager.isTrialActive &&
          _monetization.remainingCompliments.value > 0) {
        _monetization.remainingCompliments.value--;
      }
      final isMatch = response.data?['matched'] ?? false;
      if (swipedUser != null) {
        _syncUsersInteractions(
          swipedUser,
          action: 'compliment',
          matched: isMatch,
        );
      }
      debugPrint('[Home] complimentUser response: matched=$isMatch');
      if (isMatch) {
        final matchedUser = swipedUser ?? lastSwipedUser.value;
        _presentMatchFound(matchedUser);
      }
      return true;
    } catch (e) {
      debugPrint('[Home] complimentUser ERROR: $e');
      if (swipedUser != null) {
        discoverUsers.insert(0, swipedUser);
        isEmpty.value = false;
      }
      Helpers.showSnackbar(
        message: Helpers.extractErrorMessage(e),
        isError: true,
      );
      return false;
    }
  }

  UserModel? _removeUserById(String userId) {
    if (discoverUsers.isEmpty) return null;

    final idx = discoverUsers.indexWhere((u) => u.id == userId);
    if (idx == -1) return null;

    final removedUser = discoverUsers[idx];
    lastSwipedUser.value = removedUser;
    discoverUsers.removeAt(idx);

    if (currentCardIndex.value >= discoverUsers.length &&
        discoverUsers.isNotEmpty) {
      currentCardIndex.value = discoverUsers.length - 1;
    }

    if (discoverUsers.isEmpty) {
      if (_hasMore.value) {
        isEmpty.value = false;
        unawaited(loadMoreUsers());
      } else {
        isEmpty.value = true;
      }
    } else {
      isEmpty.value = false;
      _prefetchDiscoverBufferIfNeeded();
    }

    return removedUser;
  }

  void _prefetchDiscoverBufferIfNeeded() {
    if (_isLoadingMore.value || !_hasMore.value) return;
    if (discoverUsers.length > _discoverPrefetchThreshold) return;
    unawaited(loadMoreUsers());
  }

  void _syncUsersInteractions(
    UserModel user, {
    required String action,
    bool matched = false,
  }) {
    if (!Get.isRegistered<UsersController>()) return;

    Get.find<UsersController>().registerOutgoingSwipe(
      user,
      action: action,
      matched: matched,
      occurredAt: DateTime.now(),
    );
  }

  Future<void> rewindLastSwipe() async {
    if (lastSwipedUser.value == null) {
      Helpers.showSnackbar(message: 'No swipe to undo');
      return;
    }
    try {
      final result = await _monetization.useRewind();
      if (result != null) {
        final rewoundUser = lastSwipedUser.value!;
        _seenUserIds.remove(rewoundUser.id);
        unawaited(_storage.removeSeenDiscoverUserId(rewoundUser.id));
        // Re-insert the user at the top of the stack
        discoverUsers.insert(0, rewoundUser);
        isEmpty.value = false;
        lastSwipedUser.value = null;
        Helpers.showSnackbar(message: 'Swipe undone!');
      }
    } catch (e) {
      Helpers.showSnackbar(message: 'Cannot rewind right now', isError: true);
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
    isLoading.value = true;
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
      isLoading.value = false;
    }
  }

  void dismissDailyInsight() {
    dailyInsightDismissed.value = true;
  }

  // ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ Profile View Recording ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬ط£آ¢أ¢â‚¬â€Œأ¢â€ڑآ¬
  Future<void> recordProfileView(String userId) async {
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
      _monetization.canRewind.value &&
      lastSwipedUser.value != null;
  bool get hasPaidPremiumPlan =>
      _monetization.isPremium || (currentUser?.isPremium ?? false);
  bool get hasRewindAccess => hasPaidPremiumPlan;
  bool get canSendCompliment =>
      trialManager.isEffectivePremium ||
      trialManager.isTrialActive ||
      _monetization.remainingCompliments.value > 0;
  bool get hasBoostAccess => hasPaidPremiumPlan;
  int get remainingLikes =>
      trialManager.isTrialActive ? 999999 : _monetization.remainingLikes.value;
  bool get isUnlimitedLikes =>
      trialManager.isTrialActive || _monetization.isUnlimitedLikes.value;
  bool get isPremium {
    try {
      return trialManager.isEffectivePremium ||
          _monetization.isPremium ||
          (currentUser?.isPremium ?? false);
    } catch (_) {
      return currentUser?.isPremium ?? false;
    }
  }

  bool get isTrialActive => trialManager.isTrialActive;
  Duration get trialTimeRemaining => trialManager.trialTimeRemaining;
  UserModel? get currentUser => _auth.currentUser.value;

  Future<void> boostProfile() async {
    if (!hasBoostAccess) {
      Get.toNamed(AppRoutes.subscription);
      return;
    }

    try {
      var activated = await _monetization.purchaseBoost(durationMinutes: 30);
      if (!activated) {
        try {
          await _api.post(ApiConstants.boostActivate);
          activated = true;
        } catch (_) {
          activated = false;
        }
      }

      if (!activated) {
        Helpers.showSnackbar(message: 'something_went_wrong'.tr, isError: true);
        return;
      }

      _monetization.isBoosted.value = true;
      unawaited(_monetization.fetchBoostStatus());
      Helpers.showSnackbar(message: 'profile_boosted_msg'.tr);
    } catch (e) {
      debugPrint('[Home] boostProfile error: $e');
      Helpers.showSnackbar(message: 'something_went_wrong'.tr, isError: true);
    }
  }
}
