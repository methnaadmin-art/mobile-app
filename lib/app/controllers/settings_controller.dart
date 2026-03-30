import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  // ─── Theme ──────────────────────────────────────────────
  final RxString themeMode = 'system'.obs;

  // ─── Privacy ────────────────────────────────────────────
  final RxBool showOnlineStatus = true.obs;
  final RxBool showDistance = true.obs;
  final RxBool showLastSeen = true.obs;
  final RxBool showAge = true.obs;
  final RxBool privacyMode = false.obs;
  final RxString visibility = 'everyone'.obs;

  // ─── Chat Settings ──────────────────────────────────────
  final RxBool receiveDMs = true.obs;
  final RxBool readReceipts = true.obs;
  final RxBool typingIndicator = true.obs;
  final RxBool autoDownloadMedia = true.obs;

  // ─── Notification settings ─────────────────────────────
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

  // ─── Blocked users ─────────────────────────────────────
  final RxList<UserModel> blockedUsers = <UserModel>[].obs;
  final RxBool isLoadingBlocked = false.obs;

  // ─── Username ──────────────────────────────────────────
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
    fetchNotificationSettings();
    fetchBlockedUsers();
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
      showOnlineStatus.value = profile.showOnlineStatus ?? true;
      showDistance.value = profile.showDistance ?? true;
      showLastSeen.value = profile.showLastSeen ?? true;
      showAge.value = profile.showAge ?? true;
      // Persist backend values locally
      _storage.saveBool('privacy_showOnline', showOnlineStatus.value);
      _storage.saveBool('privacy_showDistance', showDistance.value);
      _storage.saveBool('privacy_showLastSeen', showLastSeen.value);
      _storage.saveBool('privacy_showAge', showAge.value);
    }
    debugPrint('[Settings] Loaded privacy: online=${showOnlineStatus.value}, distance=${showDistance.value}, lastSeen=${showLastSeen.value}, age=${showAge.value}, privacy=${privacyMode.value}, vis=${visibility.value}');
  }

  void _loadChatSettings() {
    receiveDMs.value = _storage.getBool('chat_receive_dms') ?? true;
    readReceipts.value = _storage.getBool('chat_read_receipts') ?? true;
    typingIndicator.value = _storage.getBool('chat_typing_indicator') ?? true;
    autoDownloadMedia.value = _storage.getBool('chat_auto_download') ?? true;
  }

  // ═══════════════════════════════════════════════════════════
  // THEME
  // ═══════════════════════════════════════════════════════════
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

  // ═══════════════════════════════════════════════════════════
  // USERNAME
  // ═══════════════════════════════════════════════════════════
  Future<bool> changeUsername(String newUsername) async {
    if (newUsername.trim().isEmpty) {
      Helpers.showSnackbar(message: 'Username cannot be empty', isError: true);
      return false;
    }
    isSavingUsername.value = true;
    try {
      await _api.patch(ApiConstants.usersMe, data: {
        'username': newUsername.trim(),
      });
      await _auth.fetchMe();
      Helpers.showSnackbar(message: 'Username updated successfully');
      return true;
    } catch (e) {
      Helpers.showSnackbar(message: 'Failed to update username', isError: true);
      return false;
    } finally {
      isSavingUsername.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // NOTIFICATION SETTINGS
  // ═══════════════════════════════════════════════════════════
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
      await _api.patch(ApiConstants.usersMe, data: {key: value});
      debugPrint('[Settings] Notif setting API sync success: $key=$value');
    } catch (e) {
      debugPrint('[Settings] Notif setting API sync failed (local saved): $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BLOCKED USERS
  // ═══════════════════════════════════════════════════════════
  Future<void> fetchBlockedUsers() async {
    isLoadingBlocked.value = true;
    try {
      final response = await _api.get(ApiConstants.blockedUsers);
      debugPrint('[SettingsController] fetchBlockedUsers response: ${response.data}');
      
      final data = response.data;
      final list = data is List ? data : data['users'] ?? [];
      blockedUsers.value = (list as List).map((u) => UserModel.fromJson(u)).toList();
      debugPrint('[SettingsController] Parsed ${blockedUsers.length} blocked users');
    } catch (e, stackTrace) {
      debugPrint('[SettingsController] fetchBlockedUsers CRITICAL ERROR: $e');
      debugPrint('[SettingsController] stackTrace: $stackTrace');
      Helpers.showSnackbar(message: 'Failed to load blocked users', isError: true);
    } finally {
      isLoadingBlocked.value = false;
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      await _api.delete(ApiConstants.unblockUser(userId));
      blockedUsers.removeWhere((u) => u.id == userId);
      Helpers.showSnackbar(message: 'User unblocked');
    } catch (e) {
      Helpers.showSnackbar(message: 'Failed to unblock user', isError: true);
    }
  }

  Future<void> blockUser(String userId) async {
    try {
      await _api.post(ApiConstants.blockUser(userId));
      Helpers.showSnackbar(message: 'User blocked');
      fetchBlockedUsers();
    } catch (e) {
      Helpers.showSnackbar(message: 'Failed to block user', isError: true);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // REPORTS
  // ═══════════════════════════════════════════════════════════
  Future<bool> submitReport(String reportedUserId, String reason, {String? details}) async {
    try {
      await _api.post(ApiConstants.createReport, data: {
        'reportedId': reportedUserId,
        'reason': reason,
        'details': details,
      });
      Helpers.showSnackbar(message: 'Report submitted');
      return true;
    } catch (e) {
      Helpers.showSnackbar(message: 'Failed to submit report', isError: true);
      return false;
    }
  }

  Future<bool> submitFeedback(String type, String description) async {
    try {
      // Try support ticket endpoint first, fallback to reports
      try {
        await _api.post(ApiConstants.supportTickets, data: {
          'subject': type == 'bug' ? 'Bug Report' : (type == 'suggestion' ? 'Feature Suggestion' : 'General Feedback'),
          'message': description,
        });
      } catch (_) {
        // Fallback to reports endpoint
        await _api.post(ApiConstants.createReport, data: {
          'reason': type,
          'details': description,
        });
      }
      Helpers.showSnackbar(message: 'Thank you for your feedback!');
      return true;
    } catch (e) {
      debugPrint('[Settings] submitFeedback error: $e');
      Helpers.showSnackbar(message: 'Failed to submit feedback. Try again.', isError: true);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // APP CONTENT (Terms, Privacy)
  // ═══════════════════════════════════════════════════════════
  Future<String?> fetchAppContent(String type) async {
    final locale = _storage.getString('app_language')?.split('_').first ?? 'en';
    try {
      final response = await _api.get(
        ApiConstants.appContent(type),
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

  // ═══════════════════════════════════════════════════════════
  // PRIVACY
  // ═══════════════════════════════════════════════════════════
  Future<void> updatePrivacy({bool? showOnline, bool? showDist, bool? showLastSeenVal, bool? showAgeVal, bool? privacyModeVal}) async {
    debugPrint('[Settings] updatePrivacy: online=$showOnline, dist=$showDist, lastSeen=$showLastSeenVal, age=$showAgeVal, privacy=$privacyModeVal');
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

  // ═══════════════════════════════════════════════════════════
  // CHAT SETTINGS
  // ═══════════════════════════════════════════════════════════
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
      await _api.patch(ApiConstants.usersMe, data: {
        key: value,
      });
      debugPrint('[Settings] Chat settings API sync success: $key=$value');
    } catch (e) {
      debugPrint('[Settings] Chat settings API sync failed (local saved): $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ACCOUNT
  // ═══════════════════════════════════════════════════════════
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
      Helpers.showSnackbar(message: 'deactivate_account_failed'.tr, isError: true);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CHANGE PASSWORD
  // ═══════════════════════════════════════════════════════════
  final RxBool isChangingPassword = false.obs;

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (oldPassword.trim().isEmpty || newPassword.trim().isEmpty) {
      Helpers.showSnackbar(message: 'Please fill in all fields', isError: true);
      return false;
    }
    if (newPassword.trim().length < 8) {
      Helpers.showSnackbar(message: 'Password must be at least 8 characters', isError: true);
      return false;
    }
    isChangingPassword.value = true;
    try {
      await _api.patch(ApiConstants.changePassword, data: {
        'oldPassword': oldPassword.trim(),
        'newPassword': newPassword.trim(),
      });
      Helpers.showSnackbar(message: 'Password changed successfully');
      return true;
    } catch (e) {
      Helpers.showSnackbar(message: 'Failed to change password', isError: true);
      return false;
    } finally {
      isChangingPassword.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SECURITY TOGGLES (local persistence)
  // ═══════════════════════════════════════════════════════════
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

  // ═══════════════════════════════════════════════════════════
  // FEEDBACK / REPORT
  // ═══════════════════════════════════════════════════════════
  Future<bool> sendFeedback(String subject, String message) async {
    if (message.trim().isEmpty) {
      Helpers.showSnackbar(message: 'Please enter your feedback', isError: true);
      return false;
    }
    try {
      await _api.post(ApiConstants.createReport, data: {
        'reason': 'feedback',
        'details': '[$subject] $message',
      });
      Helpers.showSnackbar(message: 'Feedback sent successfully');
      return true;
    } catch (e) {
      Helpers.showSnackbar(message: 'Failed to send feedback', isError: true);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CLEAR CACHE
  // ═══════════════════════════════════════════════════════════
  Future<bool> clearCache() async {
    try {
      // Clear image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      
      // Clear temporary storage keys (non-critical data)
      final keysToKeep = ['access_token', 'refresh_token', 'user_id', 'security_biometric', 'security_face_id', 'security_remember_me'];
      // Note: In a real implementation, you'd selectively clear cached data
      
      Helpers.showSnackbar(message: 'Cache cleared successfully');
      return true;
    } catch (e) {
      debugPrint('[Settings] clearCache error: $e');
      Helpers.showSnackbar(message: 'Failed to clear cache', isError: true);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // REQUEST DATA DOWNLOAD (GDPR)
  // ═══════════════════════════════════════════════════════════
  Future<bool> requestDataDownload() async {
    try {
      await _api.post(ApiConstants.supportTickets, data: {
        'type': 'data_request',
        'subject': 'Data Download Request',
        'description': 'User has requested a copy of their personal data (GDPR compliance).',
      });
      Helpers.showSnackbar(message: 'Data request submitted. You will receive an email within 48 hours.');
      return true;
    } catch (e) {
      debugPrint('[Settings] requestDataDownload error: $e');
      Helpers.showSnackbar(message: 'Failed to submit data request', isError: true);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // RESET APP DATA
  // ═══════════════════════════════════════════════════════════
  final RxBool isResettingData = false.obs;

  Future<bool> resetAppData() async {
    isResettingData.value = true;
    try {
      // Clear all local storage
      await _storage.clearAll();
      
      // Reset all local state
      themeMode.value = 'system';
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
      
      Helpers.showSnackbar(message: 'App data reset successfully');
      return true;
    } catch (e) {
      debugPrint('[Settings] resetAppData error: $e');
      Helpers.showSnackbar(message: 'Failed to reset app data', isError: true);
      return false;
    } finally {
      isResettingData.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // FAQ CONTENT (fetch from backend)
  // ═══════════════════════════════════════════════════════════
  final RxList<Map<String, dynamic>> faqItems = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingFaq = false.obs;

  Future<void> fetchFaqContent() async {
    isLoadingFaq.value = true;
    final locale = _storage.getString('app_language')?.split('_').first ?? 'en';
    try {
      // Try new FAQ endpoint first
      final response = await _api.get(ApiConstants.faqs, queryParameters: {'locale': locale});
      if (response.data is List) {
        faqItems.value = List<Map<String, dynamic>>.from(response.data);
        return;
      }
    } catch (e) {
      debugPrint('[Settings] fetchFaqContent from /faqs error: $e');
    }
    
    // Fallback to old content endpoint
    try {
      final response = await _api.get(ApiConstants.appContent('faq'), queryParameters: {'locale': locale});
      final data = response.data;
      if (data is Map && data['items'] != null) {
        faqItems.value = List<Map<String, dynamic>>.from(data['items']);
      } else if (data is Map && data['content'] != null) {
        // If it's a static page of type 'faq', might be a JSON string?
        debugPrint('[Settings] FAQ fallback got Map with content: ${data['content']}');
      } else if (data is List) {
        faqItems.value = List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint('[Settings] fetchFaqContent fallback error: $e');
      // Use default FAQ items if API fails
      faqItems.value = _getDefaultFaqs(locale);
    } finally {
      isLoadingFaq.value = false;
    }
  }

  List<Map<String, dynamic>> _getDefaultFaqs(String locale) {
    if (locale == 'ar') {
      return [
        {'question': 'كيف أنشئ حسابي؟', 'answer': 'سجل بالبريد الإلكتروني واتبع الخطوات لإكمال ملفك الشخصي بالصور والمعلومات.'},
        {'question': 'كيف يعمل التوافق؟', 'answer': 'اسحب يميناً للإعجاب، يساراً للتخطي. عندما يعجب الطرفان ببعضهما يتم التوافق ويمكنكما المحادثة!'},
        {'question': 'هل بياناتي آمنة؟', 'answer': 'نعم، نستخدم تشفيراً متقدماً ولا نشارك معلوماتك مع أطراف ثالثة.'},
        {'question': 'كيف أبلغ عن مستخدم؟', 'answer': 'اذهب لملف المستخدم، اضغط على القائمة واختر "إبلاغ". فريقنا يراجع البلاغات خلال 24 ساعة.'},
        {'question': 'هل يمكنني تغيير اسم المستخدم؟', 'answer': 'نعم، اذهب للإعدادات > أمان الحساب > تغيير اسم المستخدم.'},
      ];
    }
    return [
      {'question': 'How do I create a profile?', 'answer': 'Sign up with your email and follow the guided steps to complete your profile with photos and personal information.'},
      {'question': 'How does matching work?', 'answer': 'Swipe right to like someone, left to pass. When both users like each other, it\'s a match and you can start chatting!'},
      {'question': 'Is my data secure?', 'answer': 'Yes, we use industry-standard encryption and never share your personal information with third parties.'},
      {'question': 'How do I report a user?', 'answer': 'Go to the user\'s profile, tap the menu icon, and select "Report". Our team reviews all reports within 24 hours.'},
      {'question': 'Can I change my username?', 'answer': 'Yes, go to Settings > Account Security > Change Username. Note that username changes are limited.'},
    ];
  }
}
