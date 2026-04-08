# Methna Figma Redesign Plan

## Scope Guardrails

- Keep existing GetX controllers, bindings, services, models, API calls, auth flow, persistence, and navigation logic intact.
- Restrict redesign work to the presentation layer: themes, tokens, reusable widgets, layout structure, styling, spacing, and visual states.
- Keep the app buildable after each phase.

## Current Project Structure

- `lib/app/routes/`: named routes and `GetPage` registration.
- `lib/app/controllers/`: state and navigation logic.
- `lib/app/theme/`: current colors, typography, decorations, and app theme.
- `lib/core/widgets/`: shared UI primitives and reusable presentation components.
- `lib/screens/auth/`: login, password recovery, OTP, reset password, signup steps.
- `lib/screens/main/`: bottom-tab shell plus home, users, chat, profile, edit-profile, and detail flows.
- `lib/screens/settings/`: settings hub and all standalone settings screens.
- `lib/screens/search/`, `lib/screens/categories/`, `lib/screens/notifications/`, `lib/screens/splash/`, `lib/screens/onboarding/`, `lib/screens/success_stories/`: additional routed feature areas.

## Navigation Structure

- App entry: `SplashScreen` resolves to onboarding, login, an in-progress signup step, or `MainScreen`.
- Global router: `GetMaterialApp` with named `GetPage` routes in `lib/app/routes/app_pages.dart`.
- Main shell: `MainScreen` uses an `IndexedStack` and `NavigationController` for four tabs:
  - `HomeScreen`
  - `UsersScreen`
  - `ChatListScreen`
  - `ProfileScreen`
- Route groups:
  - Auth
  - 12-step signup flow
  - Main tab shell
  - Detail/utility overlays like notifications, filter, match found, search, user detail
  - Settings sub-screens
  - Categories and success stories

## Shared UI Inventory

### Existing Theme Layer

- `lib/app/theme/app_colors.dart`
- `lib/app/theme/app_text_styles.dart`
- `lib/app/theme/app_theme.dart`
- `lib/app/theme/app_decorations.dart`

### Existing Shared Widgets

- `lib/core/widgets/datify_shell.dart`
- `lib/core/widgets/custom_button.dart`
- `lib/core/widgets/custom_text_field.dart`
- `lib/core/widgets/bottom_nav_bar.dart`
- `lib/core/widgets/glassmorphic_card.dart`
- Feature-specific shared widgets like badges, avatars, loading states, and premium/trial widgets

### Current UI Risk Notes

- The codebase already has a reusable shell and some shared primitives, but many screens still hardcode paddings, radii, local gradients, and ad-hoc buttons/inputs.
- Biggest presentation-heavy screens:
  - `lib/screens/main/home/home_screen.dart`
  - `lib/screens/main/home/filter_screen.dart`
  - `lib/screens/main/profile/profile_screen.dart`
  - `lib/screens/main/profile/beautiful_edit_profile_screen.dart`
  - `lib/screens/settings/settings_screen.dart`
  - `lib/screens/onboarding/onboarding_screen.dart`
  - `lib/screens/auth/login_screen.dart`

## Screen Inventory

### Entry

- Splash: `lib/screens/splash/splash_screen.dart`
- Onboarding: `lib/screens/onboarding/onboarding_screen.dart`

### Auth

- Login: `lib/screens/auth/login_screen.dart`
- Forgot password: `lib/screens/auth/forgot_password_screen.dart`
- OTP: `lib/screens/auth/otp_screen.dart`
- Reset password: `lib/screens/auth/reset_password_screen.dart`

### Signup Flow

- Username
- Gender
- Marital status
- Profile details
- Birthday
- Email verification
- Faith and religion
- Hobbies and interests
- Profession and personal
- Add photos
- Selfie verification
- Enable location

Files:

- `lib/screens/auth/signup/username_screen.dart`
- `lib/screens/auth/signup/gender_screen.dart`
- `lib/screens/auth/signup/marital_status_screen.dart`
- `lib/screens/auth/signup/profile_details_screen.dart`
- `lib/screens/auth/signup/birthday_screen.dart`
- `lib/screens/auth/signup/email_verification_screen.dart`
- `lib/screens/auth/signup/faith_religion_screen.dart`
- `lib/screens/auth/signup/hobbies_interests_screen.dart`
- `lib/screens/auth/signup/profession_personal_screen.dart`
- `lib/screens/auth/signup/add_photos_screen.dart`
- `lib/screens/auth/signup/selfie_verification_screen.dart`
- `lib/screens/auth/signup/enable_location_screen.dart`

### Main Tabs

- Discover/swipe: `lib/screens/main/home/home_screen.dart`
- Users/matches/discovery grid: `lib/screens/main/users/users_screen.dart`
- Chats list: `lib/screens/main/chat/chat_list_screen.dart`
- My profile: `lib/screens/main/profile/profile_screen.dart`

### Main Detail Screens

- Filter: `lib/screens/main/home/filter_screen.dart`
- Match found modal: `lib/screens/main/home/match_found_screen.dart`
- User detail: `lib/screens/main/users/user_detail_screen.dart`
- Chat detail: `lib/screens/main/chat/chat_detail_screen.dart`
- Message settings: `lib/screens/main/chat/message_settings_screen.dart`
- Search radar: `lib/screens/search/search_radar_screen.dart`
- Search: `lib/screens/search/search_screen.dart`
- Notifications: `lib/screens/notifications/notifications_screen.dart`

### Profile Editing

- Primary routed edit profile: `lib/screens/main/profile/beautiful_edit_profile_screen.dart`
- Enhanced edit profile: `lib/screens/main/profile/enhanced_edit_profile_screen.dart`
- Edit profile photos: `lib/screens/main/profile/edit_profile_photos_screen.dart`
- Edit profile images: `lib/screens/main/profile/edit_profile_images_screen.dart`
- Alternate edit data screen: `lib/screens/main/profile/edit_profile_data_screen.dart`

### Settings

- Settings hub
- Discovery preferences
- Profile privacy
- Verification center
- Account and security
- Subscription
- App appearance
- Data and analytics
- Help and support
- Notification settings
- Change username
- Visibility
- Blocked users
- Manage messages
- Manage active status
- FAQ
- Contact support
- App language
- Report request
- Terms and conditions
- Privacy policy

Files:

- `lib/screens/settings/settings_screen.dart`
- `lib/screens/settings/discovery_preferences_screen.dart`
- `lib/screens/settings/profile_privacy_screen.dart`
- `lib/screens/settings/verification_center_screen.dart`
- `lib/screens/settings/account_security_screen.dart`
- `lib/screens/settings/subscription_screen.dart`
- `lib/screens/settings/app_appearance_screen.dart`
- `lib/screens/settings/data_analytics_screen.dart`
- `lib/screens/settings/help_support_screen.dart`
- `lib/screens/settings/notification_settings_screen.dart`
- `lib/screens/settings/change_username_screen.dart`
- `lib/screens/settings/visibility_screen.dart`
- `lib/screens/settings/blocked_users_screen.dart`
- `lib/screens/settings/manage_messages_screen.dart`
- `lib/screens/settings/manage_active_status_screen.dart`
- `lib/screens/settings/faq_screen.dart`
- `lib/screens/settings/contact_support_screen.dart`
- `lib/screens/settings/app_language_screen.dart`
- `lib/screens/settings/report_request_screen.dart`
- `lib/screens/settings/static_content_screen.dart`

### Categories and Other Routed Screens

- Categories: `lib/screens/categories/categories_screen.dart`
- Category users: `lib/screens/categories/category_users_screen.dart`
- Success stories: `lib/screens/success_stories/success_stories_screen.dart`

### Auxiliary or Currently Unwired Variants

- `lib/screens/auth/signup/ml_selfie_verification_screen.dart`
- `lib/screens/main/chat/premium_chat_screen.dart`
- `lib/screens/main/profile/premium_profile_screen.dart`
- `lib/screens/main/settings/premium_settings_screen.dart`
- `lib/screens/main/users/premium_swipe_cards.dart`
- `lib/screens/settings/third_party_integrations_screen.dart`

## Figma Reference Sections

The provided Figma light-theme canvas includes these relevant visual sections:

- Splash screen
- Walkthrough / onboarding
- Sign in with password
- Forgot password
- Sign up
- Swipe / like / nope / super-like / got match
- Notifications / filter / show
- Profile details page
- Search match / filter / show
- Chat / voice / video call
- Edit profile
- Upgrade membership
- Settings and sub-settings
- Profile and privacy sub-settings
- App appearance and app language
- Third party integrations
- Help and support
- Logout modal

## Screen-to-Figma Mapping

### Entry and Auth

- `SplashScreen` -> Figma `1_Light_splash screen`
- `OnboardingScreen` -> Figma walkthrough set (`2_Light_walkthrough 1` and adjacent walkthrough frames)
- `LoginScreen` -> Figma `Sign in with Password`
- `ForgotPasswordScreen` -> Figma `Forgot Password`
- `OtpScreen` -> closest auth continuation frame in the sign-in recovery cluster
- `ResetPasswordScreen` -> closest auth continuation frame in the sign-in recovery cluster

### Signup Flow

- All signup step screens -> Figma `Sign up` sequence
- `EmailVerificationScreen` -> nearest Figma verification/code-entry form in the sign-up cluster
- `AddPhotosScreen` and `SelfieVerificationScreen` -> nearest Figma profile completion / media upload patterns from the sign-up and edit-profile clusters
- `EnableLocationScreen` -> nearest Figma permission/request card treatment from signup walkthrough-style screens

### Main Discover and Matches

- `HomeScreen` -> Figma `Swipe (Like, Nope, Super Like) & Got Match`
- `MatchFoundScreen` -> Figma `Got Match`
- `UsersScreen` -> mix of Figma `Search Match, Filter & Show` plus grid/card treatments from the swipe/profile-details cluster
- `UserDetailScreen` -> Figma `Profile Details Page`
- `FilterScreen` -> Figma `Notification, Filter & Show` and `Search Match, Filter & Show`
- `NotificationsScreen` -> Figma `Notification, Filter & Show`

### Chat

- `ChatListScreen` -> Figma `Chat, Voice & Video Call`
- `ChatDetailScreen` -> Figma `Chat, Voice & Video Call`
- `MessageSettingsScreen` -> closest Figma settings detail row/list treatment

### Profile

- `ProfileScreen` -> Figma `Edit Profile` entry profile/details treatment
- `BeautifulEditProfileScreen`, `EnhancedEditProfileScreen`, `EditProfilePhotosScreen`, `EditProfileImagesScreen`, `ModernEditProfileScreen` -> Figma `Edit Profile`, `Edit & Fill Profile Section`, `Edit Profile (Filled)`, and `Save Profile`

### Settings and Premium

- `SettingsScreen` -> Figma `Settings (Several)`
- `DiscoveryPreferencesScreen` and `FilterScreen` -> Figma `Discovery Preferences`
- `ProfilePrivacyScreen`, `ChangeUsernameScreen`, `VisibilityScreen`, `BlockedUsersScreen`, `ManageMessagesScreen`, `ManageActiveStatusScreen`, `VerificationCenterScreen` -> Figma `Profile & Privacy` and its sub-settings
- `NotificationSettingsScreen` -> Figma `Settings - Notification`
- `AccountSecurityScreen` -> Figma `Settings - Account & Security`
- `SubscriptionScreen` -> Figma `Upgrade Membership` and `Settings - Subscription`
- `AppAppearanceScreen` -> Figma `Settings - App Appearance`
- `AppLanguageScreen` -> Figma `Settings - App Appearance - App Language`
- `ThirdPartyIntegrationsScreen` -> Figma `Settings - Third Party Integrations`
- `HelpSupportScreen`, `FaqScreen`, `ContactSupportScreen`, `StaticContentScreen` -> Figma `Settings - Help & Support` and its detail pages
- Logout confirmation flows -> Figma `Settings, logout modal`

## Phase Plan

### Phase 1: Analysis and Planning

- Inventory routes, screen files, shared widgets, and active vs auxiliary UI files.
- Confirm Figma section mappings.
- Identify theme gaps and repeated hardcoded UI patterns.

### Phase 2: Design System Foundation

- Create reusable tokens for spacing, radii, shadows, gradients, and semantic surfaces.
- Upgrade shared theme and foundational widgets.
- Add reusable cards, chips, list items, tabs, and modal-sheet components.

### Phase 3: Onboarding and Auth

- Redesign splash, onboarding, login, forgot password, OTP, reset password, and the 12-step signup flow.
- Unify progress bars, back buttons, form cards, CTA buttons, and verification states.

### Phase 4: Home, Discover, Matches

- Refactor swipe cards, action controls, filter entry points, match-found modal, user grid cards, and discovery headers.
- Keep swipe, like, pass, compliment, and refresh logic unchanged.

### Phase 5: Profile and Account

- Redesign profile display, edit-profile flows, profile sections, and account entry points.
- Consolidate repeated chip, section, stats, and media-grid UI.

### Phase 6: Chat and Messages

- Redesign chat list, conversation detail, presence states, composer area, and message settings.
- Preserve socket, polling, unread counts, and controller state.

### Phase 7: Settings, Filters, Premium, Remaining Screens

- Migrate all settings screens and premium/paywall surfaces to the shared component system.
- Apply closest Figma equivalents where a 1:1 screen does not exist.

### Phase 8: Polish and Verification

- Remove remaining hardcoded style drift.
- Normalize spacing and radii across screens.
- Run analysis/build checks and smoke through route-critical flows.

## Immediate Foundation Files Added In This Pass

- `lib/app/theme/app_spacing.dart`
- `lib/app/theme/app_radii.dart`
- `lib/app/theme/app_shadows.dart`
- `lib/app/theme/app_gradients.dart`
- `lib/core/widgets/app_card.dart`
- `lib/core/widgets/app_app_bar.dart`
- `lib/core/widgets/app_chip.dart`
- `lib/core/widgets/app_tab_bar.dart`
- `lib/core/widgets/app_list_item.dart`
- `lib/core/widgets/app_modal_sheet.dart`
