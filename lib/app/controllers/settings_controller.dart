import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/data/services/storage_service.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/utils/helpers.dart';

class SettingsController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final StorageService _storage = Get.find<StorageService>();
  final ApiService _api = Get.find<ApiService>();

  // â”€â”€â”€ Theme â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final RxString themeMode = 'dark'.obs;

  // â”€â”€â”€ Privacy â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final RxBool showOnlineStatus = true.obs;
  final RxBool showDistance = true.obs;
  final RxBool showLastSeen = true.obs;
  final RxBool showAge = true.obs;
  final RxBool privacyMode = false.obs;
  final RxString visibility = 'everyone'.obs;

  // â”€â”€â”€ Chat Settings â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final RxBool receiveDMs = true.obs;
  final RxBool readReceipts = true.obs;
  final RxBool typingIndicator = true.obs;
  final RxBool autoDownloadMedia = true.obs;

  // â”€â”€â”€ Notification settings â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final RxBool isLoadingNotifSettings = false.obs;
  final RxMap<String, bool> notifSettings = <String, bool>{
    'matchNotifications': true,
    'messageNotifications': true,
    'likeNotifications': true,
    'profileVisitorNotifications': false,
    'eventsNotifications': false,
    'safetyAlertNotifications': true,
    'promotionsNotifications': false,
    'inAppRecommendationNotifications': false,
    'weeklySummaryNotifications': false,
    'connectionRequestNotifications': true,
    'surveyNotifications': false,
  }.obs;

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

  @override
  void onInit() {
    super.onInit();
    themeMode.value = _storage.themeMode;
    _loadSecuritySettings();
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
    privacyMode.value = _storage.getBool('privacy_privacyMode') ?? false;
    visibility.value = _storage.getString('privacy_visibility') ?? 'everyone';

    // Then sync from backend user profile (source of truth)
    final profile = _auth.currentUser.value?.profile;
    if (profile != null) {
      showOnlineStatus.value = profile.showOnlineStatus;
      showDistance.value = profile.showDistance;
      showLastSeen.value = profile.showLastSeen;
      showAge.value = profile.showAge;
      // Persist backend values locally
      _storage.saveBool('privacy_showOnline', showOnlineStatus.value);
      _storage.saveBool('privacy_showDistance', showDistance.value);
      _storage.saveBool('privacy_showLastSeen', showLastSeen.value);
      _storage.saveBool('privacy_showAge', showAge.value);
    }
    debugPrint(
      '[Settings] Loaded privacy: online=${showOnlineStatus.value}, distance=${showDistance.value}, lastSeen=${showLastSeen.value}, age=${showAge.value}, privacy=${privacyMode.value}, vis=${visibility.value}',
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
    themeMode.value = mode;
    _storage.setThemeMode(mode);
    switch (mode) {
      case 'light':
        Get.changeThemeMode(ThemeMode.light);
        break;
      case 'dark':
        Get.changeThemeMode(ThemeMode.dark);
        break;
      default:
        Get.changeThemeMode(ThemeMode.system);
    }
  }

  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  // USERNAME
  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  Future<bool> changeUsername(String newUsername) async {
    if (newUsername.trim().isEmpty) {
      Helpers.showSnackbar(message: 'username_empty'.tr, isError: true);
      return false;
    }
    isSavingUsername.value = true;
    try {
      await _api.patch(
        ApiConstants.usersMe,
        data: {'username': newUsername.trim()},
      );
      await _auth.fetchMe();
      Helpers.showSnackbar(message: 'username_updated_success'.tr);
      return true;
    } catch (e) {
      Helpers.showSnackbar(
        message: 'username_updated_failed'.tr,
        isError: true,
      );
      return false;
    } finally {
      isSavingUsername.value = false;
    }
  }

  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  // NOTIFICATION SETTINGS
  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  Future<void> fetchNotificationSettings() async {
    isLoadingNotifSettings.value = true;

    // Load local first
    for (final key in notifSettings.keys.toList()) {
      final localVal = _storage.getBool('notif_$key');
      if (localVal != null) {
        notifSettings[key] = localVal;
      }
    }

    try {
      final response = await _api.get(ApiConstants.notificationSettings);
      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        for (final key in notifSettings.keys.toList()) {
          if (data.containsKey(key)) {
            notifSettings[key] = data[key] == true;
            _storage.saveBool('notif_$key', data[key] == true);
          }
        }
      }
    } catch (e) {
      debugPrint('[Settings] fetchNotificationSettings error: $e');
    } finally {
      isLoadingNotifSettings.value = false;
    }
  }

  Future<void> updateNotifSetting(String key, bool value) async {
    debugPrint('[Settings] updateNotifSetting: $key=$value');
    notifSettings[key] = value;
    _storage.saveBool('notif_$key', value);
    try {
      await _api.patch(ApiConstants.notificationSettings, data: {key: value});
      debugPrint(
        '[Settings] Notification setting synced via notificationSettings: $key=$value',
      );
    } catch (e) {
      // Fallback for backends that still expect user-level patch fields.
      try {
        await _api.patch(ApiConstants.usersMe, data: {key: value});
        debugPrint(
          '[Settings] Notification setting synced via usersMe fallback: $key=$value',
        );
      } catch (fallbackError) {
        debugPrint(
          '[Settings] Notification setting sync failed (local kept): $fallbackError',
        );
      }
    }
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
      await _api.delete(ApiConstants.unblockUser(userId));
      blockedUsers.removeWhere((u) => u.id == userId);
      Helpers.showSnackbar(message: 'user_unblocked'.tr);
    } catch (e) {
      Helpers.showSnackbar(message: 'user_unblock_failed'.tr, isError: true);
    }
  }

  Future<void> blockUser(String userId) async {
    try {
      await _api.post(ApiConstants.blockUser(userId));
      Helpers.showSnackbar(message: 'user_blocked'.tr);
      fetchBlockedUsers();
    } catch (e) {
      Helpers.showSnackbar(message: 'user_block_failed'.tr, isError: true);
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
    final email = _auth.currentUser.value?.email.trim();
    if (description.trim().length < 10) {
      Helpers.showSnackbar(message: 'feedback_min_chars'.tr, isError: true);
      return false;
    }

    try {
      // Try the dedicated feedback endpoint first, then fall back.
      try {
        await _api.post(
          ApiConstants.supportFeedback,
          data: {
            'type': normalizedType == 'other' ? 'feedback' : normalizedType,
            'message': message,
            if (email != null && email.isNotEmpty) 'email': email,
          },
        );
      } catch (_) {
        await _api.post(
          ApiConstants.createReport,
          data: {'reason': normalizedType, 'details': message},
        );
      }
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
    try {
      final response = await _api.get(
        ApiConstants.appContent(normalizedType),
        queryParameters: {'locale': locale},
      );
      if (response.data is Map) {
        return response.data['content']?.toString();
      }
      return null;
    } catch (e) {
      debugPrint('[Settings] fetchAppContent error: $e');
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
    bool? privacyModeVal,
  }) async {
    debugPrint(
      '[Settings] updatePrivacy: online=$showOnline, dist=$showDist, lastSeen=$showLastSeenVal, age=$showAgeVal, privacy=$privacyModeVal',
    );
    // 1. Optimistic UI update
    if (showOnline != null) showOnlineStatus.value = showOnline;
    if (showDist != null) showDistance.value = showDist;
    if (showLastSeenVal != null) showLastSeen.value = showLastSeenVal;
    if (showAgeVal != null) showAge.value = showAgeVal;
    if (privacyModeVal != null) privacyMode.value = privacyModeVal;

    // 2. Persist to storage
    _storage.saveBool('privacy_showOnline', showOnlineStatus.value);
    _storage.saveBool('privacy_showDistance', showDistance.value);
    _storage.saveBool('privacy_showLastSeen', showLastSeen.value);
    _storage.saveBool('privacy_showAge', showAge.value);
    _storage.saveBool('privacy_privacyMode', privacyMode.value);
    debugPrint('[Settings] Privacy saved to local storage');

    // 3. API
    try {
      final data = <String, dynamic>{};
      if (showOnline != null) data['showOnlineStatus'] = showOnline;
      if (showDist != null) data['showDistance'] = showDist;
      if (showLastSeenVal != null) data['showLastSeen'] = showLastSeenVal;
      if (showAgeVal != null) data['showAge'] = showAgeVal;
      if (privacyModeVal != null) data['privacyMode'] = privacyModeVal;
      if (data.isEmpty) return;

      await _api.patch(ApiConstants.updatePrivacy, data: data);
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
      debugPrint('[Settings] Visibility updated to: $val');
    } catch (e) {
      debugPrint('[Settings] updateVisibility error: $e');
    }
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
    await _auth.logout();
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> deleteAccount() async {
    try {
      Helpers.showLoading(message: 'deleting_account'.tr);
      await _api.delete(ApiConstants.usersMe);
      Helpers.hideLoading();
      await _auth.logout();
      Get.offAllNamed(AppRoutes.login);
      Helpers.showSnackbar(message: 'account_deleted'.tr);
    } catch (e) {
      Helpers.hideLoading();
      Helpers.showSnackbar(message: 'delete_account_failed'.tr, isError: true);
    }
  }

  Future<void> deactivateAccount() async {
    try {
      await _api.patch(ApiConstants.usersMe, data: {'status': 'deactivated'});
      await _auth.logout();
      Get.offAllNamed(AppRoutes.login);
      Helpers.showSnackbar(message: 'account_deactivated'.tr);
    } catch (e) {
      Helpers.showSnackbar(
        message: 'deactivate_account_failed'.tr,
        isError: true,
      );
    }
  }

  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  // CHANGE PASSWORD
  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  final RxBool isChangingPassword = false.obs;

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (oldPassword.trim().isEmpty || newPassword.trim().isEmpty) {
      Helpers.showSnackbar(message: 'fill_all_fields'.tr, isError: true);
      return false;
    }
    if (newPassword.trim().length < 8) {
      Helpers.showSnackbar(message: 'password_min_8'.tr, isError: true);
      return false;
    }
    isChangingPassword.value = true;
    try {
      await _api.patch(
        ApiConstants.changePassword,
        data: {
          'oldPassword': oldPassword.trim(),
          'newPassword': newPassword.trim(),
        },
      );
      Helpers.showSnackbar(message: 'password_changed_success'.tr);
      return true;
    } catch (e) {
      Helpers.showSnackbar(
        message: 'password_changed_failed'.tr,
        isError: true,
      );
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

  void _loadSecuritySettings() {
    rememberMe.value = _storage.getBool('security_remember_me') ?? true;
    biometricId.value = _storage.getBool('security_biometric') ?? false;
    faceId.value = _storage.getBool('security_face_id') ?? false;
    smsAuth.value = _storage.getBool('security_sms_auth') ?? false;
    googleAuth.value = _storage.getBool('security_google_auth') ?? false;
  }

  void toggleRememberMe(bool val) {
    debugPrint('[Settings] toggleRememberMe: $val');
    rememberMe.value = val;
    _storage.saveBool('security_remember_me', val);
  }

  void toggleBiometric(bool val) {
    debugPrint('[Settings] toggleBiometric: $val');
    biometricId.value = val;
    _storage.saveBool('security_biometric', val);
  }

  void toggleFaceId(bool val) {
    debugPrint('[Settings] toggleFaceId: $val');
    faceId.value = val;
    _storage.saveBool('security_face_id', val);
  }

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
      themeMode.value = 'dark';
      Get.changeThemeMode(ThemeMode.dark);
      showOnlineStatus.value = true;
      showDistance.value = true;
      showLastSeen.value = true;
      showAge.value = true;
      privacyMode.value = false;
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
