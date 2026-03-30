import 'package:get/get.dart';
import 'app_routes.dart';

// Bindings
import 'package:methna_app/app/bindings/auth_binding.dart';
import 'package:methna_app/app/bindings/home_binding.dart';
import 'package:methna_app/app/bindings/chat_binding.dart';
import 'package:methna_app/app/bindings/profile_binding.dart';
import 'package:methna_app/app/bindings/users_binding.dart';
import 'package:methna_app/app/bindings/categories_binding.dart';
import 'package:methna_app/app/bindings/notifications_binding.dart';
import 'package:methna_app/app/bindings/signup_binding.dart';
import 'package:methna_app/app/controllers/analytics_controller.dart';

// Screens
import 'package:methna_app/screens/success_stories/success_stories_screen.dart';
import 'package:methna_app/screens/splash/splash_screen.dart';
import 'package:methna_app/screens/onboarding/onboarding_screen.dart';
import 'package:methna_app/screens/auth/login_screen.dart';
import 'package:methna_app/screens/auth/forgot_password_screen.dart';
import 'package:methna_app/screens/auth/otp_screen.dart';
import 'package:methna_app/screens/auth/reset_password_screen.dart';
import 'package:methna_app/screens/auth/signup/username_screen.dart';
import 'package:methna_app/screens/auth/signup/gender_screen.dart';
import 'package:methna_app/screens/auth/signup/marital_status_screen.dart';
import 'package:methna_app/screens/auth/signup/profile_details_screen.dart';
import 'package:methna_app/screens/auth/signup/birthday_screen.dart';
import 'package:methna_app/screens/auth/signup/email_verification_screen.dart';
import 'package:methna_app/screens/auth/signup/faith_religion_screen.dart';
import 'package:methna_app/screens/auth/signup/hobbies_interests_screen.dart';
import 'package:methna_app/screens/auth/signup/profession_personal_screen.dart';
import 'package:methna_app/screens/auth/signup/add_photos_screen.dart';
import 'package:methna_app/screens/auth/signup/selfie_verification_screen.dart';
import 'package:methna_app/screens/auth/signup/enable_location_screen.dart';
import 'package:methna_app/screens/main/main_screen.dart';
import 'package:methna_app/screens/search/search_radar_screen.dart';
import 'package:methna_app/screens/search/search_screen.dart';
import 'package:methna_app/screens/main/chat/chat_detail_screen.dart';
import 'package:methna_app/screens/notifications/notifications_screen.dart';
import 'package:methna_app/screens/settings/settings_screen.dart';
import 'package:methna_app/screens/main/home/match_found_screen.dart';
import 'package:methna_app/screens/main/home/filter_screen.dart';
import 'package:methna_app/screens/main/users/user_detail_screen.dart';
import 'package:methna_app/screens/main/profile/edit_profile_images_screen.dart';
import 'package:methna_app/screens/main/profile/edit_profile_photos_screen.dart';
import 'package:methna_app/screens/main/profile/enhanced_edit_profile_screen.dart';
import 'package:methna_app/screens/main/profile/beautiful_edit_profile_screen.dart';
import 'package:methna_app/screens/main/chat/message_settings_screen.dart';
import 'package:methna_app/screens/settings/discovery_preferences_screen.dart';
import 'package:methna_app/screens/settings/profile_privacy_screen.dart';
import 'package:methna_app/screens/settings/account_security_screen.dart';
import 'package:methna_app/screens/settings/subscription_screen.dart';
import 'package:methna_app/screens/settings/app_appearance_screen.dart';
import 'package:methna_app/screens/settings/data_analytics_screen.dart';
import 'package:methna_app/screens/settings/help_support_screen.dart';
import 'package:methna_app/screens/settings/notification_settings_screen.dart';
import 'package:methna_app/screens/settings/change_username_screen.dart';
import 'package:methna_app/screens/settings/visibility_screen.dart';
import 'package:methna_app/screens/settings/blocked_users_screen.dart';
import 'package:methna_app/screens/settings/manage_messages_screen.dart';
import 'package:methna_app/screens/settings/manage_active_status_screen.dart';
import 'package:methna_app/screens/settings/faq_screen.dart';
import 'package:methna_app/screens/settings/app_language_screen.dart';
import 'package:methna_app/screens/settings/report_request_screen.dart';
import 'package:methna_app/screens/settings/contact_support_screen.dart';
import 'package:methna_app/screens/settings/static_content_screen.dart';
import 'package:methna_app/screens/categories/categories_screen.dart';
import 'package:methna_app/screens/categories/category_users_screen.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.splash;

  static final pages = <GetPage>[
    // ─── Splash ──────────────────────────────────────────────
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
    ),

    // ─── Onboarding ──────────────────────────────────────────
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      transition: Transition.fadeIn,
    ),

    // ─── Auth ────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.otp,
      page: () => const OtpScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.resetPassword,
      page: () => const ResetPasswordScreen(),
      transition: Transition.rightToLeft,
    ),

    // ─── Signup Flow ─────────────────────────────────────────
    GetPage(
      name: AppRoutes.signupUsername,
      page: () => const UsernameScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.signupGender,
      page: () => const GenderScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.signupMaritalStatus,
      page: () => const MaritalStatusScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.signupProfileDetails,
      page: () => const ProfileDetailsScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.signupBirthday,
      page: () => const BirthdayScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.signupEmailVerification,
      page: () => const EmailVerificationScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.signupFaithReligion,
      page: () => const FaithReligionScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.signupHobbies,
      page: () => const HobbiesInterestsScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.signupProfession,
      page: () => const ProfessionPersonalScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.signupPhotos,
      page: () => const AddPhotosScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.signupSelfie,
      page: () => const SelfieVerificationScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.signupLocation,
      page: () => const EnableLocationScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 350),
    ),

    // ─── Main App (Bottom Nav) ───────────────────────────────
    GetPage(
      name: AppRoutes.main,
      page: () => const MainScreen(),
      bindings: [
        HomeBinding(),
        UsersBinding(),
        ChatBinding(),
        ProfileBinding(),
      ],
      transition: Transition.fadeIn,
    ),

    // ─── Sub-screens ─────────────────────────────────────────
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const BeautifulEditProfileScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.searchRadar,
      page: () => const SearchRadarScreen(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.chatDetail,
      page: () => const ChatDetailScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsScreen(),
      binding: NotificationsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.whoLikedMe,
      page: () => const NotificationsScreen(), // Reuse notifications screen for now
      binding: NotificationsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.matchFound,
      page: () => const MatchFoundScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
      opaque: false,
      fullscreenDialog: true,
    ),
    GetPage(
      name: AppRoutes.filter,
      page: () => const FilterScreen(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.userDetail,
      page: () => const UserDetailScreen(),
      transition: Transition.rightToLeft,
    ),

    // ─── Settings Sub-screens ──────────────────────────────
    GetPage(
      name: AppRoutes.discoveryPreferences,
      page: () => const DiscoveryPreferencesScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.profilePrivacy,
      page: () => const ProfilePrivacyScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.accountSecurity,
      page: () => const AccountSecurityScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.subscription,
      page: () => const SubscriptionScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.appAppearance,
      page: () => const AppAppearanceScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.dataAnalytics,
      page: () => const DataAnalyticsScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<AnalyticsController>()) {
          Get.put(AnalyticsController());
        }
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.helpSupport,
      page: () => const HelpSupportScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.notificationSettings,
      page: () => const NotificationSettingsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.changeUsername,
      page: () => const ChangeUsernameScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.visibility,
      page: () => const VisibilityScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.blockedUsers,
      page: () => const BlockedUsersScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.manageMessages,
      page: () => const ManageMessagesScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.manageActiveStatus,
      page: () => const ManageActiveStatusScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.faq,
      page: () => const FaqScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.contactSupport,
      page: () => const ContactSupportScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.appLanguage,
      page: () => const AppLanguageScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.reportRequest,
      page: () => const ReportRequestScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.termsConditions,
      page: () => const StaticContentScreen(title: 'Terms & Conditions', contentType: 'terms'),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.privacyPolicy,
      page: () => const StaticContentScreen(title: 'Privacy Policy', contentType: 'privacy'),
      transition: Transition.rightToLeft,
    ),

    // ─── Profile Sub-screens ───────────────────────────────
    GetPage(
      name: AppRoutes.editProfileImages,
      page: () => const EditProfileImagesScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.enhancedEditProfile,
      page: () => const EnhancedEditProfileScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.editProfilePhotos,
      page: () => const EditProfilePhotosScreen(),
      transition: Transition.rightToLeft,
    ),

    // ─── Chat Sub-screens ──────────────────────────────────
    GetPage(
      name: AppRoutes.messageSettings,
      page: () => const MessageSettingsScreen(),
      transition: Transition.rightToLeft,
    ),

    // ─── Categories ────────────────────────────────────────
    GetPage(
      name: AppRoutes.categories,
      page: () => const CategoriesScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.categoryUsers,
      page: () => const CategoryUsersScreen(),
      binding: CategoriesBinding(),
      transition: Transition.rightToLeft,
    ),

    // ─── Success Stories ──────────────────────────────────
    GetPage(
      name: AppRoutes.successStories,
      page: () => const SuccessStoriesScreen(),
      transition: Transition.rightToLeft,
    ),
  ];
}
