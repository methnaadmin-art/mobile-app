import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/chat_controller.dart';
import 'package:methna_app/app/controllers/home_controller.dart';
import 'package:methna_app/app/controllers/users_controller.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/data/services/message_queue_service.dart';
import 'package:methna_app/app/data/services/notification_service.dart';
import 'package:methna_app/app/data/services/storage_service.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/data/services/biometric_service.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/constants/app_constants.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/utils/validators.dart';
import 'package:share_plus/share_plus.dart';

class SettingsController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final StorageService _storage = Get.find<StorageService>();
  final ApiService _api = Get.find<ApiService>();
  final BiometricService _biometric = Get.find<BiometricService>();

  // â”€â”€â”€ Theme â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final RxString themeMode = 'light'.obs;

  // â”€â”€â”€ Privacy â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final RxBool showOnlineStatus = true.obs;
  final RxBool showDistance = true.obs;
  final RxBool showLastSeen = true.obs;
  final RxBool showAge = true.obs;
  final RxString visibility = 'everyone'.obs;

  // â”€â”€â”€ Chat Settings â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final RxBool receiveDMs = true.obs;
  final RxBool readReceipts = true.obs;
  final RxBool typingIndicator = true.obs;
  final RxBool autoDownloadMedia = true.obs;

  // â”€â”€â”€ Notification settings â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final RxBool isLoadingNotifSettings = false.obs;
  final RxBool isSyncingNotifSettings = false.obs;
  final RxBool isDeletingAccount = false.obs;
  final RxBool isDeactivatingAccount = false.obs;
  final RxBool isLoggingOut = false.obs;
  final RxMap<String, bool> notifSettings = <String, bool>{
    'matchNotifications': true,
    'messageNotifications': true,
    'likeNotifications': true,
    'complimentNotifications': true,
    'profileVisitorNotifications': true,
    'eventsNotifications': true,
    'safetyAlertNotifications': true,
    'promotionsNotifications': true,
    'inAppRecommendationNotifications': true,
    'weeklySummaryNotifications': true,
    'connectionRequestNotifications': true,
    'surveyNotifications': true,
  }.obs;
  final RxSet<String> localOnlyNotificationSettings = <String>{}.obs;
  final RxSet<String> syncingNotificationSettings = <String>{}.obs;

  // â”€â”€â”€ Blocked users â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final RxList<UserModel> blockedUsers = <UserModel>[].obs;
  final RxBool isLoadingBlocked = false.obs;

  // â”€â”€â”€ My reports â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final RxList<Map<String, dynamic>> myReports = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingMyReports = false.obs;

  // â”€â”€â”€ Username â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final RxBool isSavingUsername = false.obs;

  UserModel? get currentUser => _auth.currentUser.value;
  String get username => currentUser?.username ?? '';

  Future<bool?> checkUsernameAvailability(String usernameCandidate) async {
    final normalized = usernameCandidate.trim().replaceFirst('@', '');
    final validationError = Validators.username(normalized);
    if (validationError != null) {
      return false;
    }

    final current = username.trim().replaceFirst('@', '');
    if (current.toLowerCase() == normalized.toLowerCase()) {
      return true;
    }

    return _checkUsernameAvailabilityRemote(normalized);
  }

  Future<bool?> _checkUsernameAvailabilityRemote(
    String usernameCandidate,
  ) async {
    try {
      final response = await _api.get(
        ApiConstants.checkUsername,
        queryParameters: {'username': usernameCandidate},
      );
      final payload = response.data;
      if (payload is Map && payload['available'] != null) {
        return payload['available'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('[Settings] username availability check failed: $e');
      return null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    final savedTheme = _storage.themeMode;
    themeMode.value = savedTheme == 'dark' ? 'dark' : 'light';
    if (savedTheme != themeMode.value) {
      unawaited(_storage.setThemeMode(themeMode.value));
    }
    _loadSecuritySettings();
    unawaited(_biometric.init());
    _loadPrivacySettings();
    _loadChatSettings();
    fetchChatSettings();
    fetchNotificationSettings();
    fetchBlockedUsers();
    fetchMyReports();
  }

  void _loadPrivacySettings() {
    // First load from local storage as fast defaults
    showOnlineStatus.value = _storage.getBool('privacy_showOnline') ?? true;
    showDistance.value = _storage.getBool('privacy_showDistance') ?? true;
    showLastSeen.value = _storage.getBool('privacy_showLastSeen') ?? true;
    showAge.value = _storage.getBool('privacy_showAge') ?? true;
    visibility.value = _storage.getString('privacy_visibility') ?? 'everyone';

    // Then sync from backend user profile (source of truth)
    final profile = _auth.currentUser.value?.profile;
    if (profile != null) {
      showOnlineStatus.value = profile.showOnlineStatus;
      showDistance.value = profile.showDistance;
      showLastSeen.value = profile.showLastSeen;
      showAge.value = profile.showAge;
      visibility.value = profile.visibilityAudience;
      // Persist backend values locally
      _storage.saveBool('privacy_showOnline', showOnlineStatus.value);
      _storage.saveBool('privacy_showDistance', showDistance.value);
      _storage.saveBool('privacy_showLastSeen', showLastSeen.value);
      _storage.saveBool('privacy_showAge', showAge.value);
      _storage.saveString('privacy_visibility', visibility.value);
    }
    debugPrint(
      '[Settings] Loaded privacy: online=${showOnlineStatus.value}, distance=${showDistance.value}, lastSeen=${showLastSeen.value}, age=${showAge.value}, vis=${visibility.value}',
    );
  }

  void _loadChatSettings() {
    receiveDMs.value = _storage.getBool('chat_receive_dms') ?? true;
    readReceipts.value = _storage.getBool('chat_read_receipts') ?? true;
    typingIndicator.value = _storage.getBool('chat_typing_indicator') ?? true;
    autoDownloadMedia.value = _storage.getBool('chat_auto_download') ?? true;
  }

  Future<void> fetchChatSettings() async {
    try {
      final response = await _api.get(ApiConstants.chatSettings);
      if (response.data is! Map) return;

      final data = Map<String, dynamic>.from(response.data as Map);
      if (data['receiveDMs'] != null) {
        receiveDMs.value = data['receiveDMs'] == true;
        _storage.saveBool('chat_receive_dms', receiveDMs.value);
      }
      if (data['readReceipts'] != null) {
        readReceipts.value = data['readReceipts'] == true;
        _storage.saveBool('chat_read_receipts', readReceipts.value);
      }
      if (data['typingIndicator'] != null) {
        typingIndicator.value = data['typingIndicator'] == true;
        _storage.saveBool('chat_typing_indicator', typingIndicator.value);
      }
      if (data['autoDownloadMedia'] != null) {
        autoDownloadMedia.value = data['autoDownloadMedia'] == true;
        _storage.saveBool('chat_auto_download', autoDownloadMedia.value);
      }
    } catch (e) {
      debugPrint('[Settings] fetchChatSettings error: $e');
    }
  }

  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  // THEME
  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  void changeTheme(String mode) {
    final normalized = mode == 'dark' ? 'dark' : 'light';
    themeMode.value = normalized;
    _storage.setThemeMode(normalized);
    switch (normalized) {
      case 'light':
        Get.changeThemeMode(ThemeMode.light);
        break;
      case 'dark':
        Get.changeThemeMode(ThemeMode.dark);
        break;
      default:
        Get.changeThemeMode(ThemeMode.light);
    }
  }

  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  // USERNAME
  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  Future<bool> changeUsername(
    String newUsername, {
    bool showFeedback = true,
  }) async {
    final normalized = newUsername.trim();
    final validationError = Validators.username(normalized);
    if (validationError != null) {
      if (showFeedback) {
        Helpers.showSnackbar(message: validationError, isError: true);
      }
      return false;
    }

    final previousUser = _auth.currentUser.value;
    final previousUsername = previousUser?.username?.trim() ?? '';
    if (previousUsername.toLowerCase() == normalized.toLowerCase()) {
      return true;
    }

    final availability = await _checkUsernameAvailabilityRemote(normalized);
    if (availability == false) {
      if (showFeedback) {
        Helpers.showSnackbar(
          message: 'username_not_available'.tr,
          isError: true,
        );
      }
      return false;
    }
    if (availability == null) {
      if (showFeedback) {
        Helpers.showSnackbar(message: 'username_check_fail'.tr, isError: true);
      }
      return false;
    }

    isSavingUsername.value = true;
    try {
      if (previousUser != null) {
        final optimisticPayload = previousUser.toJson()
          ..['username'] = normalized;
        _auth.currentUser.value = UserModel.fromJson(optimisticPayload);
      }

      await _api.patch(ApiConstants.usersMe, data: {'username': normalized});

      await _auth.fetchMe();
      return true;
    } catch (e) {
      if (previousUser != null) {
        _auth.currentUser.value = previousUser;
      }
      if (showFeedback) {
        Helpers.showSnackbar(
          message: Helpers.extractErrorMessage(e),
          isError: true,
        );
      }
      return false;
    } finally {
      isSavingUsername.value = false;
    }
  }

  Future<void> shareMyProfile() async {
    final user = currentUser;
    final usernameValue = (user?.username ?? '').trim().replaceFirst('@', '');
    final fallbackId = (user?.id ?? '').trim();
    final profileToken = usernameValue.isNotEmpty ? usernameValue : fallbackId;

    if (profileToken.isEmpty) {
      Helpers.showSnackbar(message: 'something_went_wrong'.tr, isError: true);
      return;
    }

    final link = '${AppConstants.websiteUrl}/profile/$profileToken';
    final displayName = user?.publicDisplayName.trim() ?? '';
    final message = displayName.isNotEmpty
        ? 'Meet $displayName on Methna\n$link'
        : 'See my profile on Methna\n$link';

    try {
      await Share.share(message, subject: 'Methna Profile');
    } catch (e) {
      Helpers.showSnackbar(
        message: Helpers.extractErrorMessage(e),
        isError: true,
      );
    }
  }

  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  // NOTIFICATION SETTINGS
  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  Future<void> fetchNotificationSettings() async {
    isLoadingNotifSettings.value = true;
    localOnlyNotificationSettings.clear();
    syncingNotificationSettings.clear();
    isSyncingNotifSettings.value = false;
    final localOverrides = <String, bool?>{};

    // Load local first
    for (final key in notifSettings.keys.toList()) {
      final localVal = _storage.getBool('notif_$key');
      localOverrides[key] = localVal;
      if (localVal != null) {
        notifSettings[key] = localVal;
      }
    }

    try {
      final response = await _api.get(ApiConstants.notificationSettings);
      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final missingRemoteBackfill = <String, bool>{};
        for (final key in notifSettings.keys.toList()) {
          if (data.containsKey(key)) {
            notifSettings[key] = data[key] == true;
            _storage.saveBool('notif_$key', data[key] == true);
          } else if (localOverrides[key] == null) {
            missingRemoteBackfill[key] = true;
          }
        }
        if (missingRemoteBackfill.isNotEmpty) {
          await _backfillMissingNotificationSettings(missingRemoteBackfill);
        }
      }
    } catch (e) {
      debugPrint('[Settings] fetchNotificationSettings error: $e');
    } finally {
      for (final entry in localOverrides.entries) {
        if (entry.value == null) {
          await _storage.saveBool(
            'notif_${entry.key}',
            notifSettings[entry.key] ?? true,
          );
        }
      }
      isLoadingNotifSettings.value = false;
    }
  }

  Future<void> _backfillMissingNotificationSettings(
    Map<String, bool> values,
  ) async {
    if (values.isEmpty) return;
    try {
      await _api.patch(ApiConstants.notificationSettings, data: values);
      debugPrint(
        '[Settings] Notification settings backfilled: ${values.keys.join(', ')}',
      );
    } catch (e) {
      try {
        await _api.patch(ApiConstants.usersMe, data: values);
      } catch (fallbackError) {
        localOnlyNotificationSettings.addAll(values.keys);
        debugPrint(
          '[Settings] Notification settings backfill failed: $fallbackError',
        );
      }
    }
  }

  Future<void> updateNotifSetting(String key, bool value) async {
    debugPrint('[Settings] updateNotifSetting: $key=$value');
    notifSettings[key] = value;
    _storage.saveBool('notif_$key', value);
    syncingNotificationSettings.add(key);
    isSyncingNotifSettings.value = true;
    try {
      await _api.patch(ApiConstants.notificationSettings, data: {key: value});
      localOnlyNotificationSettings.remove(key);
      debugPrint(
        '[Settings] Notification setting synced via notificationSettings: $key=$value',
      );
    } catch (e) {
      // Fallback for backends that still expect user-level patch fields.
      try {
        await _api.patch(ApiConstants.usersMe, data: {key: value});
        localOnlyNotificationSettings.remove(key);
        debugPrint(
          '[Settings] Notification setting synced via usersMe fallback: $key=$value',
        );
      } catch (fallbackError) {
        localOnlyNotificationSettings.add(key);
        debugPrint(
          '[Settings] Notification setting sync failed (local kept): $fallbackError',
        );
      }
    } finally {
      syncingNotificationSettings.remove(key);
      isSyncingNotifSettings.value = syncingNotificationSettings.isNotEmpty;
    }
  }

  String getNotificationSyncStatus(String key) {
    if (syncingNotificationSettings.contains(key)) {
      return 'syncing';
    }
    if (localOnlyNotificationSettings.contains(key)) {
      return 'pending';
    }
    return 'synced';
  }

  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  // BLOCKED USERS
  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  Future<void> fetchBlockedUsers() async {
    isLoadingBlocked.value = true;
    try {
      final response = await _api.get(ApiConstants.blockedUsers);
      debugPrint(
        '[SettingsController] fetchBlockedUsers response: ${response.data}',
      );

      final data = response.data;
      final list = data is List ? data : data['users'] ?? [];
      blockedUsers.value = (list as List).map((entry) {
        final rawUser = entry is Map && entry['blocked'] is Map
            ? entry['blocked']
            : entry;
        return UserModel.fromJson(Map<String, dynamic>.from(rawUser as Map));
      }).toList();
      await _syncBlockedUsersCache();
      debugPrint(
        '[SettingsController] Parsed ${blockedUsers.length} blocked users',
      );
    } catch (e, stackTrace) {
      debugPrint('[SettingsController] fetchBlockedUsers CRITICAL ERROR: $e');
      debugPrint('[SettingsController] stackTrace: $stackTrace');
      Helpers.showSnackbar(
        message: 'blocked_users_load_failed'.tr,
        isError: true,
      );
    } finally {
      isLoadingBlocked.value = false;
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      final response = await _api.delete(ApiConstants.unblockUser(userId));
      final payload = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : const <String, dynamic>{};
      final serverMessage = payload['message']?.toString();

      blockedUsers.removeWhere((u) => u.id == userId);
      await _storage.removeBlockedUserId(userId);
      try {
        await fetchBlockedUsers();
      } catch (refreshError) {
        debugPrint('[Settings] unblock refresh failed: $refreshError');
      }
      Helpers.showSnackbar(
        message: (serverMessage != null && serverMessage.trim().isNotEmpty)
            ? serverMessage
            : 'user_unblocked'.tr,
      );
    } catch (e) {
      Helpers.showSnackbar(
        message: Helpers.extractErrorMessage(e),
        isError: true,
      );
    }
  }

  Future<void> blockUser(String userId) async {
    try {
      final response = await _api.post(ApiConstants.blockUser(userId));
      final payload = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : const <String, dynamic>{};
      final serverMessage = payload['message']?.toString();

      await _storage.addBlockedUserIds([userId]);
      _propagateBlockedUsers({userId});

      // Backend block endpoint already performs unmatch logic. Avoid a second
      // explicit unmatch call here to prevent duplicate network side-effects
      // and mixed success/error toasts.
      if (Get.isRegistered<UsersController>()) {
        unawaited(Get.find<UsersController>().ensureUsersTabData(force: true));
      }

      try {
        await fetchBlockedUsers();
      } catch (refreshError) {
        debugPrint('[Settings] block refresh failed: $refreshError');
      }
      Helpers.showSnackbar(
        message: (serverMessage != null && serverMessage.trim().isNotEmpty)
            ? serverMessage
            : 'user_blocked'.tr,
      );
    } catch (e) {
      Helpers.showSnackbar(
        message: Helpers.extractErrorMessage(e),
        isError: true,
      );
    }
  }

  Future<void> _syncBlockedUsersCache() async {
    final blockedIds = blockedUsers
        .map((user) => user.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    await _storage.saveBlockedUserIds(blockedIds);
    _propagateBlockedUsers(blockedIds);
  }

  void _propagateBlockedUsers(Set<String> blockedIds) {
    if (blockedIds.isEmpty) return;
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().evictUsersByIds(blockedIds);
    }
    if (Get.isRegistered<UsersController>()) {
      Get.find<UsersController>().evictUsersByIds(blockedIds);
    }
    if (Get.isRegistered<ChatController>()) {
      Get.find<ChatController>().evictUsersByIds(blockedIds);
    }
  }

  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  // REPORTS
  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  DateTime? _tryParseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String _normalizeReportStatus(dynamic status) {
    final normalized = status?.toString().trim().toLowerCase() ?? '';
    switch (normalized) {
      case 'open':
      case 'new':
      case 'submitted':
      case 'created':
        return 'submitted';
      case 'in_progress':
      case 'in-review':
      case 'in_review':
      case 'pending':
      case 'under_review':
      case 'investigating':
        return 'in_review';
      case 'resolved':
      case 'closed':
      case 'done':
        return 'resolved';
      case 'rejected':
      case 'declined':
      case 'dismissed':
        return 'rejected';
      default:
        return normalized.isEmpty ? 'submitted' : normalized;
    }
  }

  Future<void> fetchMyReports({bool silent = false}) async {
    if (!silent) {
      isLoadingMyReports.value = true;
    }

    try {
      final response = await _api.get(ApiConstants.myReports);
      final payload = response.data;
      final rawList = payload is List
          ? payload
          : payload is Map
          ? (payload['reports'] ??
                payload['items'] ??
                payload['data'] ??
                const [])
          : const [];

      if (rawList is! List) {
        myReports.clear();
        return;
      }

      final parsed = rawList
          .whereType<Map>()
          .map((entry) {
            final report = Map<String, dynamic>.from(entry);
            final createdAt = _tryParseDate(
              report['createdAt'] ??
                  report['created_at'] ??
                  report['submittedAt'] ??
                  report['submitted_at'],
            );

            return {
              ...report,
              'status': _normalizeReportStatus(report['status']),
              if (createdAt != null) 'createdAt': createdAt.toIso8601String(),
            };
          })
          .toList(growable: false);

      DateTime sortDate(Map<String, dynamic> report) =>
          _tryParseDate(report['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      parsed.sort((a, b) => sortDate(b).compareTo(sortDate(a)));
      myReports.assignAll(parsed.take(20).toList(growable: false));
    } catch (e) {
      debugPrint('[Settings] fetchMyReports error: $e');
      if (!silent) {
        Helpers.showSnackbar(
          message: 'report_history_load_failed'.tr,
          isError: true,
        );
      }
    } finally {
      if (!silent) {
        isLoadingMyReports.value = false;
      }
    }
  }

  String _normalizeReportReason(String reason) {
    final normalized = reason.trim().toLowerCase().replaceAll(' ', '_');
    switch (normalized) {
      case 'fake':
      case 'fake_user':
      case 'fake_profile':
        return 'fake_profile';
      case 'inappropriate':
      case 'inappropriate_content':
        return 'inappropriate_content';
      case 'harassment':
      case 'abuse':
        return 'harassment';
      case 'spam':
        return 'spam';
      case 'underage':
        return 'underage';
      case 'feedback':
        return 'feedback';
      case 'bug':
        return 'bug';
      case 'suggestion':
        return 'suggestion';
      default:
        return 'other';
    }
  }

  Future<bool> submitReport(
    String reportedUserId,
    String reason, {
    String? details,
  }) async {
    try {
      await _api.post(
        ApiConstants.createReport,
        data: {
          'reportedId': reportedUserId,
          'reason': _normalizeReportReason(reason),
          if (details != null && details.trim().isNotEmpty)
            'details': details.trim(),
        },
      );
      await fetchMyReports(silent: true);
      Helpers.showSnackbar(message: 'report_submitted'.tr);
      return true;
    } catch (e) {
      debugPrint('[Settings] submitReport error: $e');
      Helpers.showSnackbar(
        message: Helpers.extractErrorMessage(e),
        isError: true,
      );
      return false;
    }
  }

  Future<bool> submitFeedback(String type, String description) async {
    final normalizedType = _normalizeReportReason(type);
    final message = description.trim();
    if (description.trim().length < 10) {
      Helpers.showSnackbar(message: 'feedback_min_chars'.tr, isError: true);
      return false;
    }

    try {
      await _api.post(
        ApiConstants.createReport,
        data: {'reason': normalizedType, 'details': message},
      );
      await fetchMyReports(silent: true);
      Helpers.showSnackbar(message: 'feedback_thank_you'.tr);
      return true;
    } catch (e) {
      debugPrint('[Settings] submitFeedback error: $e');
      Helpers.showSnackbar(
        message: Helpers.extractErrorMessage(e),
        isError: true,
      );
      return false;
    }
  }

  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  // APP CONTENT (Terms, Privacy)
  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  Future<String?> fetchAppContent(String type) async {
    final locale = _storage.getString('app_language')?.split('_').first ?? 'en';
    final normalizedType = switch (type) {
      'partner' => 'partners',
      'job_vacancy' => 'jobs',
      _ => type,
    };

    final localizedContent = await _fetchAppContentFromApi(
      normalizedType: normalizedType,
      locale: locale,
    );
    if (localizedContent != null && localizedContent.trim().isNotEmpty) {
      return localizedContent;
    }

    if (locale != 'en') {
      final englishContent = await _fetchAppContentFromApi(
        normalizedType: normalizedType,
        locale: 'en',
      );
      if (englishContent != null && englishContent.trim().isNotEmpty) {
        return englishContent;
      }
    }

    return _fallbackStaticContent(normalizedType);
  }

  Future<String?> _fetchAppContentFromApi({
    required String normalizedType,
    required String locale,
  }) async {
    try {
      final response = await _api.get(
        ApiConstants.appContent(normalizedType),
        queryParameters: {'locale': locale},
      );
      if (response.data is Map) {
        return response.data['content']?.toString();
      }
    } catch (e) {
      debugPrint(
        '[Settings] fetchAppContent error: type=$normalizedType locale=$locale error=$e',
      );
    }

    return null;
  }

  String? _fallbackStaticContent(String normalizedType) {
    switch (normalizedType) {
      case 'terms':
        return '''Terms of Service

By using Methna, you agree to use the app lawfully and respectfully. Accounts that violate community and safety rules may be restricted or removed.

You are responsible for the accuracy of your profile information and for your activity inside the app.

Full Terms: ${AppConstants.termsUrl}
Support: ${AppConstants.supportEmail}''';
      case 'privacy':
        return '''Privacy Policy

Methna processes account, profile, and usage information to provide matching, safety, notifications, and support.

You can control privacy settings in the app and request account deletion from Settings.

Full Privacy Policy: ${AppConstants.privacyPolicyUrl}
Privacy contact: ${AppConstants.privacyEmail}''';
      default:
        return null;
    }
  }

  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  // PRIVACY
  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  Future<void> updatePrivacy({
    bool? showOnline,
    bool? showDist,
    bool? showLastSeenVal,
    bool? showAgeVal,
  }) async {
    debugPrint(
      '[Settings] updatePrivacy: online=$showOnline, dist=$showDist, lastSeen=$showLastSeenVal, age=$showAgeVal',
    );
    // 1. Optimistic UI update
    if (showOnline != null) showOnlineStatus.value = showOnline;
    if (showDist != null) showDistance.value = showDist;
    if (showLastSeenVal != null) showLastSeen.value = showLastSeenVal;
    if (showAgeVal != null) showAge.value = showAgeVal;

    // 2. Persist to storage
    _storage.saveBool('privacy_showOnline', showOnlineStatus.value);
    _storage.saveBool('privacy_showDistance', showDistance.value);
    _storage.saveBool('privacy_showLastSeen', showLastSeen.value);
    _storage.saveBool('privacy_showAge', showAge.value);
    debugPrint('[Settings] Privacy saved to local storage');

    // 3. API
    try {
      final data = <String, dynamic>{};
      if (showOnline != null) data['showOnlineStatus'] = showOnline;
      if (showDist != null) data['showDistance'] = showDist;
      if (showLastSeenVal != null) data['showLastSeen'] = showLastSeenVal;
      if (showAgeVal != null) data['showAge'] = showAgeVal;
      if (data.isEmpty) return;

      await _api.patch(ApiConstants.updatePrivacy, data: data);
      _patchCurrentUserPrivacy(
        showOnline: showOnlineStatus.value,
        showDistanceValue: showDistance.value,
        showLastSeenValue: showLastSeen.value,
        showAgeValue: showAge.value,
      );
      debugPrint('[Settings] Privacy API sync success');
    } catch (e) {
      debugPrint('[Settings] Privacy API sync failed (local saved): $e');
    }
  }

  Future<void> updateVisibility(String val) async {
    visibility.value = val;
    _storage.saveString('privacy_visibility', val);
    try {
      await _api.patch(ApiConstants.updatePrivacy, data: {'visibility': val});
      _patchCurrentUserPrivacy(visibilityAudience: val);
      debugPrint('[Settings] Visibility updated to: $val');
    } catch (e) {
      debugPrint('[Settings] updateVisibility error: $e');
    }
  }

  void _patchCurrentUserPrivacy({
    bool? showOnline,
    bool? showDistanceValue,
    bool? showLastSeenValue,
    bool? showAgeValue,
    String? visibilityAudience,
  }) {
    final current = _auth.currentUser.value;
    if (current == null) return;

    final payload = current.toJson();
    final profile = Map<String, dynamic>.from(
      (payload['profile'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{},
    );

    profile['showOnlineStatus'] = showOnline ?? showOnlineStatus.value;
    profile['showDistance'] = showDistanceValue ?? showDistance.value;
    profile['showLastSeen'] = showLastSeenValue ?? showLastSeen.value;
    profile['showAge'] = showAgeValue ?? showAge.value;
    profile['visibilityAudience'] = visibilityAudience ?? visibility.value;

    payload['profile'] = profile;
    _auth.currentUser.value = UserModel.fromJson(payload);
  }

  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  // CHAT SETTINGS
  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  Future<void> updateChatSetting(String key, bool value) async {
    debugPrint('[Settings] updateChatSetting: $key=$value');

    // Update local state and storage
    switch (key) {
      case 'receiveDMs':
        receiveDMs.value = value;
        _storage.saveBool('chat_receive_dms', value);
        break;
      case 'readReceipts':
        readReceipts.value = value;
        _storage.saveBool('chat_read_receipts', value);
        break;
      case 'typingIndicator':
        typingIndicator.value = value;
        _storage.saveBool('chat_typing_indicator', value);
        break;
      case 'autoDownloadMedia':
        autoDownloadMedia.value = value;
        _storage.saveBool('chat_auto_download', value);
        break;
    }

    // Attempt API sync via user entity update (flat payload)
    try {
      await _api.patch(ApiConstants.chatSettings, data: {key: value});
      debugPrint('[Settings] Chat settings API sync success: $key=$value');
    } catch (e) {
      debugPrint('[Settings] Chat settings API sync failed (local saved): $e');
    }
  }

  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  // ACCOUNT
  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  Future<void> logout() async {
    if (isLoggingOut.value) return;

    isLoggingOut.value = true;
    try {
      _clearTransientAppState();
      await _auth.logout();
      Get.offAllNamed(AppRoutes.login);
    } finally {
      isLoggingOut.value = false;
    }
  }

  Future<bool> deleteAccount({String? reason, String? details}) async {
    if (isDeletingAccount.value) return false;
    isDeletingAccount.value = true;
    try {
      final payload = <String, dynamic>{'action': 'delete', 'hardDelete': true};
      if (reason != null && reason.trim().isNotEmpty) {
        payload['reason'] = reason.trim();
      }
      if (details != null && details.trim().isNotEmpty) {
        payload['details'] = details.trim();
      }

      try {
        await _api.post(ApiConstants.closeAccount, data: payload);
      } catch (_) {
        await _api.delete(ApiConstants.usersMe);
      }
      _clearTransientAppState();
      await _auth.logout();
      Get.offAllNamed(AppRoutes.login);
      Helpers.showSnackbar(message: 'account_deleted'.tr);
      return true;
    } catch (e) {
      debugPrint('[Settings] deleteAccount error: $e');
      Helpers.showSnackbar(message: 'delete_account_failed'.tr, isError: true);
      return false;
    } finally {
      isDeletingAccount.value = false;
    }
  }

  Future<bool> deactivateAccount({String? reason, String? details}) async {
    if (isDeactivatingAccount.value) return false;
    isDeactivatingAccount.value = true;
    try {
      final payload = <String, dynamic>{'action': 'deactivate'};
      if (reason != null && reason.trim().isNotEmpty) {
        payload['reason'] = reason.trim();
      }
      if (details != null && details.trim().isNotEmpty) {
        payload['details'] = details.trim();
      }

      try {
        await _api.post(ApiConstants.closeAccount, data: payload);
      } catch (_) {
        await _api.patch(ApiConstants.usersMe, data: {'status': 'deactivated'});
      }
      _clearTransientAppState();
      await _auth.logout();
      Get.offAllNamed(AppRoutes.login);
      Helpers.showSnackbar(message: 'account_deactivated'.tr);
      return true;
    } catch (e) {
      Helpers.showSnackbar(
        message: 'deactivate_account_failed'.tr,
        isError: true,
      );
      return false;
    } finally {
      isDeactivatingAccount.value = false;
    }
  }

  void _clearTransientAppState() {
    if (Get.isRegistered<MessageQueueService>()) {
      Get.find<MessageQueueService>().clearQueue();
    }
    if (Get.isRegistered<NotificationService>()) {
      Get.find<NotificationService>().clearAll();
    }
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().resetForLogout();
    }
    if (Get.isRegistered<UsersController>()) {
      Get.find<UsersController>().resetForLogout();
    }
    if (Get.isRegistered<ChatController>()) {
      Get.find<ChatController>().resetForLogout();
    }
  }

  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  // CHANGE PASSWORD
  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  final RxBool isChangingPassword = false.obs;

  Future<bool> changePassword(
    String oldPassword,
    String newPassword, {
    bool showFeedback = true,
  }) async {
    if (oldPassword.trim().isEmpty || newPassword.trim().isEmpty) {
      if (showFeedback) {
        Helpers.showSnackbar(message: 'fill_all_fields'.tr, isError: true);
      }
      return false;
    }
    if (oldPassword.trim() == newPassword.trim()) {
      if (showFeedback) {
        Helpers.showSnackbar(
          message: 'New password must be different from current password.',
          isError: true,
        );
      }
      return false;
    }
    final validationError = Validators.password(newPassword.trim());
    if (validationError != null) {
      if (showFeedback) {
        Helpers.showSnackbar(message: validationError, isError: true);
      }
      return false;
    }
    isChangingPassword.value = true;
    try {
      final response = await _api.patch(
        ApiConstants.changePassword,
        data: {
          'oldPassword': oldPassword.trim(),
          'newPassword': newPassword.trim(),
        },
      );
      final payload = response.data;
      final serverMessage = payload is Map && payload['message'] != null
          ? payload['message'].toString()
          : null;
      if (showFeedback) {
        Helpers.showSnackbar(
          message: (serverMessage != null && serverMessage.trim().isNotEmpty)
              ? serverMessage
              : 'password_changed_success'.tr,
        );
      }
      return true;
    } catch (e) {
      if (showFeedback) {
        Helpers.showSnackbar(
          message: Helpers.extractErrorMessage(e),
          isError: true,
        );
      }
      return false;
    } finally {
      isChangingPassword.value = false;
    }
  }

  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  // SECURITY TOGGLES (local persistence)
  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  final RxBool rememberMe = true.obs;
  final RxBool biometricId = false.obs;
  final RxBool faceId = false.obs;
  final RxBool smsAuth = false.obs;
  final RxBool googleAuth = false.obs;
  final RxBool isUpdatingBiometric = false.obs;

  void _loadSecuritySettings() {
    rememberMe.value = _storage.getBool('security_remember_me') ?? true;
    biometricId.value =
        _storage.getBool('security_biometric') ??
        (_storage.getBool('biometric_enabled') ?? false);
    faceId.value = _storage.getBool('security_face_id') ?? false;
    smsAuth.value = _storage.getBool('security_sms_auth') ?? false;
    googleAuth.value = _storage.getBool('security_google_auth') ?? false;
  }

  void toggleRememberMe(bool val) {
    debugPrint('[Settings] toggleRememberMe: $val');
    rememberMe.value = val;
    _storage.saveBool('security_remember_me', val);
  }

  Future<void> setBiometricLock(bool enabled) async {
    if (isUpdatingBiometric.value) return;

    isUpdatingBiometric.value = true;
    try {
      await _biometric.init();

      if (enabled) {
        if (!_biometric.isAvailable.value) {
          Helpers.showSnackbar(
            message: _biometric.failureMessage,
            isError: true,
          );
          biometricId.value = false;
          faceId.value = false;
          await _biometric.setEnabled(false);
          await _storage.saveBool('security_face_id', false);
          return;
        }

        final verified = await _biometric.authenticate(
          reason: 'authenticate_to_access'.tr,
          requireEnabled: false,
        );
        if (!verified) {
          Helpers.showSnackbar(
            message: _biometric.failureMessage,
            isError: true,
          );
          biometricId.value = false;
          faceId.value = false;
          await _biometric.setEnabled(false);
          await _storage.saveBool('security_face_id', false);
          return;
        }
      }

      biometricId.value = enabled;
      faceId.value = enabled;
      await _biometric.setEnabled(enabled);
      await _storage.saveBool('security_face_id', enabled);
      await _syncSecuritySetting('biometricEnabled', enabled);
      Helpers.showSnackbar(
        message: enabled
            ? 'Biometric lock enabled.'
            : 'Biometric lock disabled.',
      );
    } finally {
      isUpdatingBiometric.value = false;
    }
  }

  Future<void> _syncSecuritySetting(String key, bool value) async {
    try {
      await _api.patch(ApiConstants.securitySettings, data: {key: value});
    } catch (_) {
      try {
        await _api.patch(ApiConstants.usersMe, data: {key: value});
      } catch (error) {
        debugPrint('[Settings] Security setting sync failed for $key: $error');
      }
    }
  }

  Future<void> toggleBiometric(bool val) => setBiometricLock(val);

  Future<void> toggleFaceId(bool val) => setBiometricLock(val);

  void toggleSmsAuth(bool val) {
    debugPrint('[Settings] toggleSmsAuth: $val');
    smsAuth.value = val;
    _storage.saveBool('security_sms_auth', val);
  }

  void toggleGoogleAuth(bool val) {
    debugPrint('[Settings] toggleGoogleAuth: $val');
    googleAuth.value = val;
    _storage.saveBool('security_google_auth', val);
  }

  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  // FEEDBACK / REPORT
  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  Future<bool> sendFeedback(String subject, String message) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      Helpers.showSnackbar(
        message: 'Please enter your feedback',
        isError: true,
      );
      return false;
    }
    final subjectPrefix = subject.trim().isEmpty ? '' : '[${subject.trim()}] ';
    return submitFeedback('feedback', '$subjectPrefix$trimmedMessage');
  }

  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  // CLEAR CACHE
  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  Future<bool> clearCache() async {
    try {
      // Clear image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      Helpers.showSnackbar(message: 'cache_cleared_success'.tr);
      return true;
    } catch (e) {
      debugPrint('[Settings] clearCache error: $e');
      Helpers.showSnackbar(message: 'cache_cleared_failed'.tr, isError: true);
      return false;
    }
  }

  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  // REQUEST DATA DOWNLOAD (GDPR)
  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  Future<bool> requestDataDownload() async {
    try {
      await _api.post(
        ApiConstants.supportTickets,
        data: {
          'subject': 'Data Download Request',
          'message':
              'User has requested a copy of their personal data for account export.',
        },
      );
      Helpers.showSnackbar(message: 'data_request_submitted'.tr);
      return true;
    } catch (e) {
      debugPrint('[Settings] requestDataDownload error: $e');
      Helpers.showSnackbar(
        message: 'data_request_submit_failed'.tr,
        isError: true,
      );
      return false;
    }
  }

  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  // RESET APP DATA
  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  final RxBool isResettingData = false.obs;

  Future<bool> resetAppData() async {
    isResettingData.value = true;
    try {
      // Clear all local storage
      await _storage.clearAll();

      // Reset all local state
      themeMode.value = 'light';
      Get.changeThemeMode(ThemeMode.light);
      showOnlineStatus.value = true;
      showDistance.value = true;
      showLastSeen.value = true;
      showAge.value = true;
      visibility.value = 'everyone';
      receiveDMs.value = true;
      readReceipts.value = true;
      typingIndicator.value = true;
      autoDownloadMedia.value = true;
      rememberMe.value = true;
      biometricId.value = false;
      faceId.value = false;
      smsAuth.value = false;
      googleAuth.value = false;

      // Reset notification settings
      for (final key in notifSettings.keys.toList()) {
        notifSettings[key] = true;
      }
      localOnlyNotificationSettings.clear();
      syncingNotificationSettings.clear();
      isSyncingNotifSettings.value = false;

      Helpers.showSnackbar(message: 'app_data_reset_success'.tr);
      return true;
    } catch (e) {
      debugPrint('[Settings] resetAppData error: $e');
      Helpers.showSnackbar(message: 'app_data_reset_failed'.tr, isError: true);
      return false;
    } finally {
      isResettingData.value = false;
    }
  }

  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  // FAQ CONTENT (fetch from backend)
  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  final RxList<Map<String, dynamic>> faqItems = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingFaq = false.obs;
  final RxString faqError = ''.obs;

  Future<void> fetchFaqContent() async {
    isLoadingFaq.value = true;
    faqError.value = '';
    final locale = _storage.getString('app_language')?.split('_').first ?? 'en';

    try {
      final response = await _api.get(
        ApiConstants.faqs,
        queryParameters: {'locale': locale},
      );
      if (response.data is List) {
        faqItems.value = List<Map<String, dynamic>>.from(response.data);
        return;
      }
    } catch (e) {
      debugPrint('[Settings] fetchFaqContent from /faqs error: $e');
    }

    try {
      final response = await _api.get(
        ApiConstants.appContent('faq'),
        queryParameters: {'locale': locale},
      );
      final data = response.data;
      if (data is Map && data['items'] is List) {
        faqItems.value = List<Map<String, dynamic>>.from(data['items']);
      } else if (data is List) {
        faqItems.value = List<Map<String, dynamic>>.from(data);
      } else {
        faqItems.clear();
      }
    } catch (e) {
      debugPrint('[Settings] fetchFaqContent fallback error: $e');
      faqItems.clear();
      faqError.value = 'Unable to load FAQ right now. Pull down to retry.';
    } finally {
      isLoadingFaq.value = false;
    }
  }
}
