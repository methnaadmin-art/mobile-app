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

// Screens
import 'package:methna_app/screens/success_stories/success_stories_screen.dart';
import 'package:methna_app/screens/splash/splash_screen.dart';
import 'package:methna_app/screens/onboarding/onboarding_screen.dart';
import 'package:methna_app/screens/auth/login_screen.dart';
import 'package:methna_app/screens/auth/account_status_screen.dart';
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
import 'package:methna_app/screens/main/users/who_liked_me_screen.dart';
import 'package:methna_app/screens/notifications/notifications_screen.dart';
import 'package:methna_app/screens/settings/settings_screen.dart';
import 'package:methna_app/screens/main/home/match_found_screen.dart';
import 'package:methna_app/screens/main/home/filter_screen.dart';
import 'package:methna_app/screens/main/users/user_detail_screen.dart';
import 'package:methna_app/screens/main/profile/edit_profile_images_screen.dart';
import 'package:methna_app/screens/main/profile/edit_profile_photos_screen.dart';
import 'package:methna_app/screens/main/profile/enhanced_edit_profile_screen.dart';
import 'package:methna_app/screens/main/profile/beautiful_edit_profile_screen.dart';
import 'package:methna_app/screens/settings/discovery_preferences_screen.dart';
import 'package:methna_app/screens/settings/profile_privacy_screen.dart';
import 'package:methna_app/screens/settings/account_security_screen.dart';
import 'package:methna_app/screens/settings/subscription_screen.dart';
import 'package:methna_app/screens/settings/shop_screen.dart';
import 'package:methna_app/screens/settings/app_appearance_screen.dart';
import 'package:methna_app/screens/settings/app_data_actions_info_screen.dart';
import 'package:methna_app/screens/settings/help_support_screen.dart';
import 'package:methna_app/screens/settings/notification_settings_screen.dart';
import 'package:methna_app/screens/settings/change_username_screen.dart';
import 'package:methna_app/screens/settings/change_password_screen.dart';
import 'package:methna_app/screens/settings/visibility_screen.dart';
import 'package:methna_app/screens/settings/blocked_users_screen.dart';
import 'package:methna_app/screens/settings/manage_messages_screen.dart';
import 'package:methna_app/screens/settings/deactivate_account_screen.dart';
import 'package:methna_app/screens/settings/delete_account_screen.dart';
import 'package:methna_app/screens/settings/faq_screen.dart';
import 'package:methna_app/screens/settings/app_language_screen.dart';
import 'package:methna_app/screens/settings/report_request_screen.dart';
import 'package:methna_app/screens/settings/contact_support_screen.dart';
import 'package:methna_app/screens/settings/static_content_screen.dart';
import 'package:methna_app/screens/settings/verification_center_screen.dart';
import 'package:methna_app/screens/categories/categories_screen.dart';
import 'package:methna_app/screens/categories/category_users_screen.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.splash;
  static const _kSlideTransitionDuration = Duration(milliseconds: 360);
  static const _kFadeTransitionDuration = Duration(milliseconds: 300);
  static const _kModalTransitionDuration = Duration(milliseconds: 420);

  static final pages = <GetPage>[
    // â”€â”€â”€ Splash â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
      transitionDuration: _kFadeTransitionDuration,
    ),

    // â”€â”€â”€ Onboarding â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      transition: Transition.fadeIn,
      transitionDuration: _kFadeTransitionDuration,
    ),

    // â”€â”€â”€ Auth â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _kSlideTransitionDuration,
    ),
    GetPage(
      name: AppRoutes.accountStatus,
      page: () => const AccountStatusScreen(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _kSlideTransitionDuration,
    ),
    GetPage(
      name: AppRoutes.otp,
      page: () => const OtpScreen(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _kSlideTransitionDuration,
    ),
    GetPage(
      name: AppRoutes.resetPassword,
      page: () => const ResetPasswordScreen(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _kSlideTransitionDuration,
    ),

    // â”€â”€â”€ Signup Flow â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    GetPage(
      name: AppRoutes.signupUsername,
      page: () => const UsernameScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _kSlideTransitionDuration,
    ),
    GetPage(
      name: AppRoutes.signupGender,
      page: () => const GenderScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _kSlideTransitionDuration,
    ),
    GetPage(
      name: AppRoutes.signupMaritalStatus,
      page: () => const MaritalStatusScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _kSlideTransitionDuration,
    ),
    GetPage(
      name: AppRoutes.signupProfileDetails,
      page: () => const ProfileDetailsScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _kSlideTransitionDuration,
    ),
    GetPage(
      name: AppRoutes.signupBirthday,
      page: () => const BirthdayScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _kSlideTransitionDuration,
    ),
    GetPage(
      name: AppRoutes.signupEmailVerification,
      page: () => const EmailVerificationScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _kSlideTransitionDuration,
    ),
    GetPage(
      name: AppRoutes.signupFaithReligion,
      page: () => const FaithReligionScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _kSlideTransitionDuration,
    ),
    GetPage(
      name: AppRoutes.signupHobbies,
      page: () => const HobbiesInterestsScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _kSlideTransitionDuration,
    ),
    GetPage(
      name: AppRoutes.signupProfession,
      page: () => const ProfessionPersonalScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _kSlideTransitionDuration,
    ),
    GetPage(
      name: AppRoutes.signupPhotos,
      page: () => const AddPhotosScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _kSlideTransitionDuration,
    ),
    GetPage(
      name: AppRoutes.signupSelfie,
      page: () => const SelfieVerificationScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _kSlideTransitionDuration,
    ),
    GetPage(
      name: AppRoutes.signupLocation,
      page: () => const EnableLocationScreen(),
      binding: SignupBinding(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _kSlideTransitionDuration,
    ),

    // â”€â”€â”€ Main App (Bottom Nav) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

    // â”€â”€â”€ Sub-screens â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const BeautifulEditProfileScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.searchRadar,
      page: () => const SearchRadarScreen(),
      transition: Transition.downToUp,
      transitionDuration: _kModalTransitionDuration,
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchScreen(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: _kSlideTransitionDuration,
    ),
    GetPage(
      name: AppRoutes.chatDetail,
      page: () => const ChatDetailScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsScreen(),
      binding: NotificationsBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.whoLikedMe,
      page: () => const WhoLikedMeScreen(),
      binding: UsersBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.matchFound,
      page: () => const MatchFoundScreen(),
      transition: Transition.fadeIn,
      transitionDuration: _kFadeTransitionDuration,
      fullscreenDialog: true,
    ),
    GetPage(
      name: AppRoutes.filter,
      page: () => const FilterScreen(),
      transition: Transition.downToUp,
      transitionDuration: _kModalTransitionDuration,
    ),
    GetPage(
      name: AppRoutes.userDetail,
      page: () => const UserDetailScreen(),
      transition: Transition.rightToLeftWithFade,
    ),

    // â”€â”€â”€ Settings Sub-screens â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    GetPage(
      name: AppRoutes.discoveryPreferences,
      page: () => const DiscoveryPreferencesScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.profilePrivacy,
      page: () => const ProfilePrivacyScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.verificationCenter,
      page: () => const VerificationCenterScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.accountSecurity,
      page: () => const AccountSecurityScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.subscription,
      page: () => const SubscriptionScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.shop,
      page: () => const ShopScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.appAppearance,
      page: () => const AppAppearanceScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.clearCacheInfo,
      page: () => const ClearCacheInfoScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.resetAppDataInfo,
      page: () => const ResetAppDataInfoScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.helpSupport,
      page: () => const HelpSupportScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.notificationSettings,
      page: () => const NotificationSettingsScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.changeUsername,
      page: () => const ChangeUsernameScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.visibility,
      page: () => const VisibilityScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.blockedUsers,
      page: () => const BlockedUsersScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.manageMessages,
      page: () => const ManageMessagesScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.deactivateAccount,
      page: () => const DeactivateAccountScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.deleteAccount,
      page: () => const DeleteAccountScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.faq,
      page: () => const FaqScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.contactSupport,
      page: () => const ContactSupportScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.appLanguage,
      page: () => const AppLanguageScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.reportRequest,
      page: () => const ReportRequestScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.termsConditions,
      page: () => StaticContentScreen(
        title: 'terms_conditions'.tr,
        contentType: 'terms',
      ),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.privacyPolicy,
      page: () => StaticContentScreen(
        title: 'privacy_policy'.tr,
        contentType: 'privacy',
      ),
      transition: Transition.rightToLeftWithFade,
    ),

    // â”€â”€â”€ Profile Sub-screens â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    GetPage(
      name: AppRoutes.editProfileImages,
      page: () => const EditProfileImagesScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.enhancedEditProfile,
      page: () => const EnhancedEditProfileScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.editProfilePhotos,
      page: () => const EditProfilePhotosScreen(),
      transition: Transition.rightToLeftWithFade,
    ),

    // â”€â”€â”€ Chat Sub-screens â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    GetPage(
      name: AppRoutes.messageSettings,
      page: () => const ManageMessagesScreen(),
      transition: Transition.rightToLeftWithFade,
    ),

    // â”€â”€â”€ Categories â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    GetPage(
      name: AppRoutes.categories,
      page: () => const CategoriesScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.categoryUsers,
      page: () => const CategoryUsersScreen(),
      binding: CategoriesBinding(),
      transition: Transition.rightToLeftWithFade,
    ),

    // â”€â”€â”€ Success Stories â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    GetPage(
      name: AppRoutes.successStories,
      page: () => const SuccessStoriesScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
  ];
}
