class ApiConstants {
  ApiConstants._();

  // ─── Base URLs ──────────────────────────────────────────
  // Local development (Android Emulator):
  // static const String baseUrl = 'http://10.0.2.2:3000/api/v1';
  // static const String socketUrl = 'http://10.0.2.2:3000';
  // Production (Railway):
  static const String baseUrl = 'https://web-production-afbe4.up.railway.app/api/v1';
  static const String socketUrl = 'https://web-production-afbe4.up.railway.app';

  // ─── Auth ───────────────────────────────────────────────
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

  // ─── Users ──────────────────────────────────────────────
  static const String usersMe = '/users/me';
  static const String usersById = '/users'; // + /:id

  // ─── Profiles ───────────────────────────────────────────
  static const String profileMe = '/profiles/me';
  static const String createOrUpdateProfile = '/profiles';
  static const String updateLocation = '/profiles/location';
  static const String updatePrivacy = '/profiles/privacy';
  static const String preferences = '/profiles/preferences';
  static String profileByUserId(String id) => '/profiles/$id';

  // ─── Photos ─────────────────────────────────────────────
  static const String uploadPhoto = '/photos/upload';
  static const String myPhotos = '/photos/me';
  static String setMainPhoto(String id) => '/photos/$id/main';
  static String deletePhoto(String id) => '/photos/$id';

  // ─── Swipes ─────────────────────────────────────────────
  static const String swipe = '/swipes';
  static const String whoLikedMe = '/swipes/who-liked-me';
  static const String interactions = '/swipes/interactions'; // Users who interacted with current user
  static String compatibility(String targetId) => '/swipes/compatibility/$targetId';

  // ─── Matches ────────────────────────────────────────────
  static const String matches = '/matches';
  static const String suggestions = '/matches/suggestions';
  static const String nearbyUsers = '/matches/nearby';
  static const String discoverCategories = '/matches/discover';
  static String unmatch(String id) => '/matches/$id';

  // ─── Chat ───────────────────────────────────────────────
  static const String conversations = '/chat/conversations';
  static String conversationMessages(String id) => '/chat/conversations/$id/messages';
  static String markConversationRead(String id) => '/chat/conversations/$id/read';
  static String markConversationDelivered(String id) => '/chat/conversations/$id/delivered';
  static String muteConversation(String id) => '/chat/conversations/$id/mute';
  static const String chatUnread = '/chat/unread';

  // ─── Notifications ──────────────────────────────────────
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static String deleteNotification(String id) => '/notifications/$id';
  static const String notificationSettings = '/notifications/settings';

  // ─── Subscriptions ──────────────────────────────────────
  static const String subscriptionMe = '/subscriptions/me';
  static const String subscriptionCreate = '/subscriptions';
  static const String subscriptionCancel = '/subscriptions';
  static const String subscriptionPlans = '/subscriptions/plans';

  // ─── Monetization ───────────────────────────────────────
  static const String activePlans = '/monetization/plans';
  static const String monetizationStatus = '/monetization/status';
  static const String monetizationFeatures = '/monetization/features';
  static const String remainingLikes = '/monetization/remaining-likes';
  static const String purchaseSubscription = '/monetization/subscribe';
  static const String purchaseBoost = '/monetization/boost';
  static const String boostStatus = '/monetization/boost';

  // ─── Reports & Blocking ─────────────────────────────────
  static const String createReport = '/reports';
  static String blockUser(String id) => '/reports/block/$id';
  static String unblockUser(String id) => '/reports/block/$id';
  static const String blockedUsers = '/reports/blocked';

  // ─── Monetization (extended) ─────────────────────────────
  static const String rewindCheck = '/monetization/rewind';
  static const String rewindUse = '/monetization/rewind';
  static const String complimentsRemaining = '/monetization/compliments';
  static const String invisibleToggle = '/monetization/invisible';
  static const String invisibleStatus = '/monetization/invisible';
  static const String allLimits = '/monetization/limits';

  // ─── Swipe Rewind ──────────────────────────────────────
  static const String swipeRewind = '/swipes/rewind';

  // ─── Trust & Safety / Verification ──────────────────────
  static const String selfieUpload = '/trust-safety/selfie-upload';
  static const String selfieVerify = '/trust-safety/selfie-verify';
  static const String idUpload = '/trust-safety/id-upload';
  static const String marriageCertUpload = '/trust-safety/marriage-cert-upload';
  static const String verificationStatus = '/trust-safety/verification-status';
  static const String trustScore = '/trust-safety/trust-score';

  // ─── Search ─────────────────────────────────────────────
  static const String search = '/search';

  // ─── Rematch / Second Chance ───────────────────────────
  static String requestRematch(String targetId) => '/swipes/rematch/$targetId';
  static String acceptRematch(String requestId) => '/swipes/rematch/$requestId/accept';
  static String rejectRematch(String requestId) => '/swipes/rematch/$requestId/reject';
  static const String myRematchRequests = '/swipes/rematch/requests';

  // ─── Passport Mode ────────────────────────────────────
  static const String setPassport = '/monetization/passport';
  static const String clearPassport = '/monetization/passport/clear';
  static const String getPassport = '/monetization/passport';

  // ─── Payments ─────────────────────────────────────────
  static const String stripePublishableKey = 'pk_test_TYooMQauvdEDq54NiTphI7jx'; // Replace or use flutter_dotenv
  static const String paymentPricing = '/payments/pricing';
  static const String paymentCreateIntent = '/payments/create-intent';

  // ─── Matching / Recommendations ───────────────────────
  static const String smartSuggestions = '/matching/smart-suggestions';
  static const String recommendedForYou = '/matching/recommended';
  static const String collaborativeRecs = '/matching/collaborative';
  static String matchingCompatibility(String targetId) => '/matching/compatibility/$targetId';

  // ─── Profile Views ────────────────────────────────────
  static const String profileViews = '/profile-views';
  static String recordProfileView(String viewedId) => '/profile-views/$viewedId';

  // ─── Success Stories ──────────────────────────────────
  static const String successStories = '/success-stories';
  static const String submitSuccessStory = '/success-stories';

  // ─── Background Check ─────────────────────────────────
  static const String backgroundCheck = '/trust-safety/background-check';
  static const String backgroundCheckStatus = '/trust-safety/background-check';

  // ─── Boost ──────────────────────────────────────────────
  static const String boostActivate = '/monetization/boost/activate';
  static const String boostPurchase = '/monetization/boost/purchase';

  // ─── Analytics ──────────────────────────────────────────
  static const String analytics = '/analytics/profile';
  static const String analyticsTrack = '/analytics/track';

  // ─── Chat – Image Messages ─────────────────────────────
  static const String sendImageMessage = '/chat/messages/image';
  static const String sendVoiceMessage = '/chat/messages/voice';

  // ─── Categories ───────────────────────────────────────
  static const String categories = '/categories';
  static String categoryById(String id) => '/categories/$id';
  static String categoryUsers(String id) => '/categories/$id/users';

  // ─── Support ──────────────────────────────────────────
  static const String supportTickets = '/support';
  static const String myTickets = '/support/my-tickets';

  // ─── Baraka Meter ───────────────────────────────────
  static String baraka(String targetId) => '/matching/baraka/$targetId';
  static const String barakaBulk = '/matching/baraka/bulk';

  // ─── Ice Breakers ───────────────────────────────────
  static String iceBreakers(String targetId) => '/matching/ice-breakers/$targetId';

  // ─── Daily Insights ─────────────────────────────────
  static const String dailyInsight = '/daily-insights/today';

  // ─── App Content (Terms, Privacy, etc.) ─────────────
  static String appContent(String type) => '/content/$type';
  static const String allContent = '/content';

  // ─── FAQ ─────────────────────────────────────────────
  static const String faqs = '/content/faqs/list';

  // ─── Jobs ────────────────────────────────────────────
  static const String jobs = '/content/jobs/list';

  // ─── Partners ────────────────────────────────────────
  static const String partners = '/content/partners/list';

  // ─── Feedback / My Reports ──────────────────────────
  static const String myReports = '/reports/my-reports';

  // ─── Chat Settings ─────────────────────────────────
  static const String chatSettings = '/users/me/chat-settings';

  // ─── User Settings ─────────────────────────────────
  static const String securitySettings = '/users/me/security';
  static const String privacySettings = '/profiles/privacy';
}
