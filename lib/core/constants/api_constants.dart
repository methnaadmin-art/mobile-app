import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  static String _normalizeOrigin(String url) {
    final trimmed = url.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.parse(trimmed);
    final normalized = uri
        .replace(path: '', query: null, fragment: null)
        .toString();
    return normalized.replaceFirst(RegExp(r'/$'), '');
  }

  // â”€â”€â”€ Base URLs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static String get baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (configured.isNotEmpty) return configured;

    if (kDebugMode) {
      return switch (defaultTargetPlatform) {
        TargetPlatform.android =>
          'https://web-production-afbe4.up.railway.app/api/v1', // changed from 10.0.2.2 for stability
        _ =>
          'https://web-production-afbe4.up.railway.app/api/v1', // changed from 127.0.0.1
      };
    }

    return 'https://web-production-afbe4.up.railway.app/api/v1';
  }

  static String get socketUrl {
    const configured = String.fromEnvironment('SOCKET_URL', defaultValue: '');
    if (configured.isNotEmpty) return _normalizeOrigin(configured);

    if (kDebugMode) {
      return switch (defaultTargetPlatform) {
        TargetPlatform.android => _normalizeOrigin(
          'https://web-production-afbe4.up.railway.app:443',
        ),
        _ => _normalizeOrigin(
          'https://web-production-afbe4.up.railway.app:443',
        ),
      };
    }

    return _normalizeOrigin('https://web-production-afbe4.up.railway.app:443');
  }

  // â”€â”€â”€ Auth â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyResetOtp = '/auth/verify-reset-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  static const String checkUsername = '/auth/check-username';
  static const String googleSignIn = '/auth/google';

  // â”€â”€â”€ Users â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String usersMe = '/users/me';
  static const String usersById = '/users'; // + /:id
  static String userById(String id) => '$usersById/$id';

  // â”€â”€â”€ Profiles â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String profileMe = '/profiles/me';
  static const String createOrUpdateProfile = '/profiles';
  static const String updateLocation = '/profiles/location';
  static const String updatePrivacy = '/profiles/privacy';
  static const String preferences = '/profiles/preferences';
  static String profileByUserId(String id) => '/profiles/$id';

  // â”€â”€â”€ Photos â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String uploadPhoto = '/photos/upload';
  static const String myPhotos = '/photos/me';
  static String setMainPhoto(String id) => '/photos/$id/main';
  static String deletePhoto(String id) => '/photos/$id';

  // â”€â”€â”€ Swipes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String swipe = '/swipes';
  static const String whoLikedMe = '/swipes/who-liked-me';
  static const String interactions =
      '/swipes/interactions'; // Users who interacted with current user
  static String compatibility(String targetId) =>
      '/swipes/compatibility/$targetId';

  // â”€â”€â”€ Matches â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String matches = '/matches';
  static const String suggestions = '/matches/suggestions';
  static const String nearbyUsers = '/matches/nearby';
  static const String discoverCategories = '/matches/discover';
  static String unmatch(String id) => '/matches/$id';

  // â”€â”€â”€ Chat â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String conversations = '/chat/conversations';
  static String conversationMessages(String id) =>
      '/chat/conversations/$id/messages';
  static String markConversationRead(String id) =>
      '/chat/conversations/$id/read';
  static String markConversationDelivered(String id) =>
      '/chat/conversations/$id/delivered';
  static String muteConversation(String id) => '/chat/conversations/$id/mute';
  static const String chatUnread = '/chat/unread';
  static const String chatLiveToday = '/chat/live-today';

  // â”€â”€â”€ Notifications â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static String deleteNotification(String id) => '/notifications/$id';
  static const String notificationSettings = '/notifications/settings';

  // â”€â”€â”€ Subscriptions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String subscriptionMe = '/subscriptions/me';
  static const String subscriptionCreate = '/subscriptions';
  static const String subscriptionCancel = '/subscriptions';
  static const String subscriptionPlans = '/subscriptions/plans';

  // â”€â”€â”€ Monetization â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String activePlans = '/monetization/plans';
  static const String monetizationStatus = '/monetization/status';
  static const String monetizationFeatures = '/monetization/features';
  static const String remainingLikes = '/monetization/remaining-likes';
  static const String purchaseSubscription = '/monetization/subscribe';
  static const String purchaseBoost = '/monetization/boost';
  static const String boostStatus = '/monetization/boost';

  // â”€â”€â”€ Reports & Blocking â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String createReport = '/reports';
  static String blockUser(String id) => '/reports/block/$id';
  static String unblockUser(String id) => '/reports/block/$id';
  static const String blockedUsers = '/reports/blocked';

  // â”€â”€â”€ Monetization (extended) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String rewindCheck = '/monetization/rewind';
  static const String rewindUse = '/monetization/rewind';
  static const String complimentsRemaining = '/monetization/compliments';
  static const String invisibleToggle = '/monetization/invisible';
  static const String invisibleStatus = '/monetization/invisible';
  static const String allLimits = '/monetization/limits';

  // â”€â”€â”€ Swipe Rewind â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String swipeRewind = '/swipes/rewind';

  // â”€â”€â”€ Trust & Safety / Verification â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String selfieUpload = '/trust-safety/selfie-upload';
  static const String selfieVerify = '/trust-safety/selfie-verify';
  static const String idUpload = '/trust-safety/id-upload';
  static const String marriageCertUpload = '/trust-safety/marriage-cert-upload';
  static const String verificationStatus = '/trust-safety/verification-status';
  static const String trustScore = '/trust-safety/trust-score';

  // â”€â”€â”€ Search â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String search = '/search';

  // â”€â”€â”€ Rematch / Second Chance â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static String requestRematch(String targetId) => '/swipes/rematch/$targetId';
  static String acceptRematch(String requestId) =>
      '/swipes/rematch/$requestId/accept';
  static String rejectRematch(String requestId) =>
      '/swipes/rematch/$requestId/reject';
  static const String myRematchRequests = '/swipes/rematch/requests';

  // â”€â”€â”€ Passport Mode â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String setPassport = '/monetization/passport';
  static const String clearPassport = '/monetization/passport/clear';
  static const String getPassport = '/monetization/passport';

  // â”€â”€â”€ Payments â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );
  static const String stripeMerchantIdentifier = String.fromEnvironment(
    'STRIPE_MERCHANT_IDENTIFIER',
    defaultValue: 'merchant.com.methna.app',
  );
  static const String stripeMerchantCountryCode = String.fromEnvironment(
    'STRIPE_MERCHANT_COUNTRY_CODE',
    defaultValue: 'US',
  );
  static const String stripeCurrencyCode = String.fromEnvironment(
    'STRIPE_CURRENCY_CODE',
    defaultValue: 'USD',
  );
  static const String stripeReturnUrl = String.fromEnvironment(
    'STRIPE_RETURN_URL',
    defaultValue: '',
  );
  static const bool stripeForceTestMode = bool.fromEnvironment(
    'STRIPE_TEST_MODE',
    defaultValue: false,
  );
  static const String paymentPricing = '/payments/pricing';
  static const String paymentCreateIntent = '/payments/create-intent';

  // â”€â”€â”€ Matching / Recommendations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String smartSuggestions = '/matching/smart-suggestions';
  static const String recommendedForYou = '/matching/recommended';
  static const String collaborativeRecs = '/matching/collaborative';
  static String matchingCompatibility(String targetId) =>
      '/matching/compatibility/$targetId';

  // â”€â”€â”€ Profile Views â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String profileViews = '/profile-views';
  static String recordProfileView(String viewedId) =>
      '/profile-views/$viewedId';

  // â”€â”€â”€ Success Stories â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String successStories = '/success-stories';
  static const String submitSuccessStory = '/success-stories';

  // â”€â”€â”€ Background Check â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String backgroundCheck = '/trust-safety/background-check';
  static const String backgroundCheckStatus = '/trust-safety/background-check';

  // â”€â”€â”€ Boost â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String boostActivate = '/monetization/boost/activate';
  static const String boostPurchase = '/monetization/boost/purchase';

  // â”€â”€â”€ Analytics â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String analytics = '/analytics/profile';
  static const String analyticsTrack = '/analytics/track';

  // â”€â”€â”€ Chat â€“ Image Messages â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String sendImageMessage = '/chat/messages/image';
  static const String sendVoiceMessage = '/chat/messages/voice';

  // â”€â”€â”€ Categories â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String categories = '/categories';
  static String categoryById(String id) => '/categories/$id';
  static String categoryUsers(String id) => '/categories/$id/users';

  // â”€â”€â”€ Support â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String supportTickets = '/support';
  static const String supportFeedback = '/support/feedback';
  static const String myTickets = '/support/my-tickets';

  // â”€â”€â”€ Baraka Meter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static String baraka(String targetId) => '/matching/baraka/$targetId';
  static const String barakaBulk = '/matching/baraka/bulk';

  static const String compatibilityBulk = '/matching/compatibility/bulk';
  // â”€â”€â”€ Ice Breakers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static String iceBreakers(String targetId) =>
      '/matching/ice-breakers/$targetId';

  // â”€â”€â”€ Daily Insights â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String dailyInsight = '/daily-insights/today';

  // â”€â”€â”€ App Content (Terms, Privacy, etc.) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static String appContent(String type) => '/content/$type';
  static const String allContent = '/content';

  // â”€â”€â”€ FAQ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String faqs = '/content/faqs/list';

  // â”€â”€â”€ Jobs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String jobs = '/content/jobs/list';

  // â”€â”€â”€ Partners â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String partners = '/content/partners/list';

  // â”€â”€â”€ Feedback / My Reports â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String myReports = '/reports/my-reports';

  // â”€â”€â”€ Chat Settings â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String chatSettings = '/chat/settings';

  // â”€â”€â”€ User Settings â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String securitySettings = '/users/me/security';
  static const String privacySettings = '/profiles/privacy';
}
