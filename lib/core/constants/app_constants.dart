class AppConstants {
  AppConstants._();

  static const String appName = 'Methna';
  static const String appTagline = 'Muslim matchmaking with intention';
  static const String appLogoAsset = 'assets/images/methna_logo_glow.png';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String authSessionHintKey = 'has_auth_session';
  static const String userKey = 'user_data';
  static const String authProviderKey = 'auth_provider';
  static const String onboardingKey = 'onboarding_done';
  static const String themeKey = 'theme_mode';
  static const String localeKey = 'locale';
  static const String firstLaunchKey = 'first_launch';
  static const String signupDraftKey = 'signup_draft';
  static const String swipeTutorialPendingKey = 'swipe_tutorial_pending';

  // Signup Steps
  static const int signupTotalSteps = 11;

  // Photo Limits
  static const int maxPhotos = 6; // 1 main + 5 extra
  static const int minPhotos = 1;

  // Pagination
  static const int defaultPageSize = 20;
  static const int chatPageSize = 50;

  // Animation Durations (ms)
  static const int splashDuration = 2500;
  static const int pageTransition = 300;
  static const int fadeIn = 400;
  static const int slideUp = 500;
  static const int radarPulse = 2000;

  // Swipe Thresholds
  static const double swipeThreshold = 100.0;
  static const double swipeVelocity = 800.0;

  // Location
  static const double defaultSearchRadius = 50.0; // km
  static const double maxSearchRadius = 200.0;

  // Age Range
  static const int minAge = 18;
  static const int maxAge = 60;
}
