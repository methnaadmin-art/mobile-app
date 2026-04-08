abstract class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';

  // Auth
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String otp = '/otp';

  // Signup Flow
  static const String signupUsername = '/signup/username';
  static const String signupGender = '/signup/gender';
  static const String signupMaritalStatus = '/signup/marital-status';
  static const String signupProfileDetails = '/signup/profile-details';
  static const String signupBirthday = '/signup/birthday';
  static const String signupEmailVerification = '/signup/email-verification';
  static const String signupEmailVerify = '/signup/email-verification';
  static const String signupFaithReligion = '/signup/faith-religion';
  static const String signupHobbies = '/signup/hobbies';
  static const String signupProfession = '/signup/profession';
  static const String signupPhotos = '/signup/photos';
  static const String signupSelfie = '/signup/selfie';
  static const String signupLocation = '/signup/location';

  // Main App
  static const String main = '/main';
  static const String home = '/home';
  static const String users = '/users';
  static const String chat = '/chat';
  static const String profile = '/profile';

  // Sub-screens
  static const String searchRadar = '/search-radar';
  static const String search = '/search';
  static const String chatDetail = '/chat/detail';
  static const String notifications = '/notifications';
  static const String whoLikedMe = '/who-liked-me';
  static const String settings = '/settings';
  static const String editProfile = '/edit-profile';
  static const String enhancedEditProfile = '/edit-profile/enhanced';
  static const String userDetail = '/user-detail';
  static const String matchFound = '/match-found';
  static const String filter = '/filter';

  // Settings Sub-screens
  static const String discoveryPreferences = '/settings/discovery-preferences';
  static const String profilePrivacy = '/settings/profile-privacy';
  static const String verificationCenter = '/settings/verification-center';
  static const String accountSecurity = '/settings/account-security';
  static const String subscription = '/settings/subscription';
  static const String appAppearance = '/settings/app-appearance';
  static const String helpSupport = '/settings/help-support';
  static const String clearCacheInfo = '/settings/clear-cache-info';
  static const String resetAppDataInfo = '/settings/reset-app-data-info';
  static const String notificationSettings = '/settings/notification-settings';
  static const String changeUsername = '/settings/change-username';
  static const String visibility = '/settings/visibility';
  static const String blockedUsers = '/settings/blocked-users';
  static const String manageMessages = '/settings/manage-messages';
  static const String manageActiveStatus = '/settings/manage-active-status';
  static const String faq = '/settings/faq';
  static const String contactSupport = '/settings/contact-support';
  static const String appLanguage = '/settings/app-language';
  static const String reportRequest = '/settings/report-request';
  static const String termsConditions = '/settings/terms-conditions';
  static const String privacyPolicy = '/settings/privacy-policy';

  // Profile Sub-screens
  static const String editProfileImages = '/profile/edit-images';
  static const String editProfileData = '/profile/edit-data';
  static const String editProfilePhotos = '/profile/edit-photos';

  // Chat Sub-screens
  static const String messageSettings = '/message-settings';

  // Categories
  static const String categories = '/categories';
  static const String categoryUsers = '/categories/users';

  // Success Stories
  static const String successStories = '/success-stories';
}
