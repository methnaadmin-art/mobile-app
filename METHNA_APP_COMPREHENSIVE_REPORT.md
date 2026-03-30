# Methna App - Comprehensive Technical Report
## Muslim Dating & Marriage Application

**Version:** 1.0.0  
**Report Date:** March 28, 2026  
**Platform:** Flutter (Android & iOS)

---

# Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Application Architecture](#2-application-architecture)
3. [Technology Stack](#3-technology-stack)
4. [Backend API Communication](#4-backend-api-communication)
5. [Authentication System](#5-authentication-system)
6. [User Management](#6-user-management)
7. [Profile System](#7-profile-system)
8. [Matching & Discovery](#8-matching--discovery)
9. [Chat & Messaging](#9-chat--messaging)
10. [Notifications](#10-notifications)
11. [Settings & Preferences](#11-settings--preferences)
12. [Security & Privacy](#12-security--privacy)
13. [Monetization Features](#13-monetization-features)
14. [Data Flow Diagrams](#14-data-flow-diagrams)
15. [Deployment & Store Readiness](#15-deployment--store-readiness)

---

# 1. Executive Summary

Methna is a sophisticated Muslim dating and marriage application designed to connect Muslims seeking meaningful relationships. The app combines modern dating features with Islamic values, providing a secure and respectful platform for finding compatible partners.

## Key Features
- **Profile Management:** Comprehensive user profiles with photos, bio, and Islamic preferences
- **Smart Matching:** Algorithm-based matching considering religious compatibility
- **Real-time Chat:** Secure messaging with read receipts and typing indicators
- **Baraka Meter:** Unique compatibility scoring based on Islamic values
- **Selfie Verification:** AI-powered identity verification for safety
- **Location Services:** Find matches nearby with privacy controls
- **Subscription System:** Premium features with Stripe integration

## Recent Updates (This Session)
- ✅ Fixed Enable Location screen navigation
- ✅ Redesigned Profile screen with cleaner UI
- ✅ Added animated Change Username screen
- ✅ Implemented FAQ content fetching from backend
- ✅ Added Reset App Data functionality
- ✅ Fixed Report/Request submission
- ✅ Updated Android/iOS permissions for store compliance

---

# 2. Application Architecture

## 2.1 Project Structure

```
methna_app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app/
│   │   ├── bindings/                # Dependency injection
│   │   ├── controllers/             # GetX controllers
│   │   ├── data/
│   │   │   ├── models/              # Data models
│   │   │   ├── providers/           # API providers
│   │   │   └── services/            # Business logic services
│   │   ├── routes/                  # Navigation routes
│   │   └── theme/                   # App theming
│   ├── core/
│   │   ├── constants/               # API constants, app constants
│   │   └── utils/                   # Helper utilities
│   ├── screens/                     # UI screens
│   │   ├── auth/                    # Authentication screens
│   │   ├── main/                    # Main app screens
│   │   └── settings/                # Settings screens
│   └── widgets/                     # Reusable widgets
├── android/                         # Android native code
├── ios/                             # iOS native code
└── assets/                          # Images, icons, animations
```

## 2.2 State Management

The app uses **GetX** for state management, providing:
- Reactive state with `Rx` variables
- Dependency injection via `Get.put()` and `Get.find()`
- Route management with named routes
- Internationalization support

### Controllers Overview

| Controller | Purpose |
|------------|---------|
| `AuthController` | Authentication state and login/logout |
| `SignupController` | Multi-step signup flow |
| `ProfileController` | User profile management |
| `SettingsController` | App settings and preferences |
| `HomeController` | Home screen and recommendations |
| `ChatController` | Messaging functionality |
| `MatchController` | Matching and swipe actions |

---

# 3. Technology Stack

## 3.1 Frontend (Flutter)

| Category | Technology | Version |
|----------|------------|---------|
| Framework | Flutter | 3.10.1+ |
| State Management | GetX | 4.6.6 |
| HTTP Client | Dio | 5.4.0 |
| Real-time | Socket.IO Client | 2.0.3 |
| Local Storage | GetStorage + Flutter Secure Storage | 2.1.1 / 9.2.2 |
| UI Animation | Flutter Animate | 4.5.0 |
| Image Caching | Cached Network Image | 3.3.1 |
| Camera | Camera + Image Picker | 0.11.0 / 1.1.2 |
| Face Detection | Google ML Kit | 0.11.0 |
| Location | Geolocator + Geocoding | 12.0.0 / 3.0.0 |
| Payments | Flutter Stripe | 10.1.0 |
| Notifications | Flutter Local Notifications | 17.2.2 |
| Biometrics | Local Auth | 2.3.0 |

## 3.2 Backend (NestJS)

| Category | Technology |
|----------|------------|
| Framework | NestJS |
| Database | PostgreSQL with TypeORM |
| Caching | Redis |
| Authentication | JWT (Access + Refresh tokens) |
| File Storage | Cloudinary |
| Real-time | Socket.IO |
| Email | Nodemailer |

---

# 4. Backend API Communication

## 4.1 API Service Architecture

The app communicates with the backend through a centralized `ApiService` class that wraps Dio HTTP client.

### Base Configuration

```dart
class ApiService extends GetxService {
  late Dio _dio;
  
  Future<ApiService> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Add interceptors for auth and error handling
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LogInterceptor());
    
    return this;
  }
}
```

### Auth Interceptor

```dart
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = StorageService.to.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Attempt token refresh
      _refreshTokenAndRetry(err, handler);
    } else {
      handler.next(err);
    }
  }
}
```

## 4.2 API Endpoints

### Authentication Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/auth/register` | POST | User registration |
| `/auth/login` | POST | User login |
| `/auth/logout` | POST | User logout |
| `/auth/refresh` | POST | Refresh access token |
| `/auth/verify-email` | POST | Email verification |
| `/auth/resend-otp` | POST | Resend OTP code |
| `/auth/forgot-password` | POST | Password reset request |
| `/auth/reset-password` | POST | Reset password |

### User & Profile Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/users/me` | GET | Get current user |
| `/users/me` | PATCH | Update user profile |
| `/users/me` | DELETE | Delete account |
| `/users/me/photos` | POST | Upload photos |
| `/users/me/photos/:id` | DELETE | Delete photo |
| `/users/me/photos/reorder` | PATCH | Reorder photos |
| `/users/me/selfie` | POST | Upload verification selfie |
| `/users/me/location` | PATCH | Update location |

### Matching & Discovery Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/matching/recommendations` | GET | Get recommended profiles |
| `/matching/swipe` | POST | Swipe action (like/pass) |
| `/matching/super-like/:id` | POST | Super like a user |
| `/matching/undo` | POST | Undo last swipe |
| `/matching/baraka/:id` | GET | Get Baraka compatibility score |
| `/matching/ice-breakers/:id` | GET | Get conversation starters |

### Chat Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/chat/conversations` | GET | List conversations |
| `/chat/conversations/:id` | GET | Get conversation details |
| `/chat/conversations/:id/messages` | GET | Get messages |
| `/chat/messages` | POST | Send message |
| `/chat/messages/image` | POST | Send image message |
| `/chat/messages/voice` | POST | Send voice message |
| `/chat/messages/:id/read` | PATCH | Mark as read |

### Settings & Content Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/users/me/notifications` | GET/PATCH | Notification settings |
| `/users/me/privacy` | PATCH | Privacy settings |
| `/content/:type` | GET | App content (FAQ, Terms, etc.) |
| `/support` | POST | Create support ticket |
| `/reports` | POST | Submit report |

---

# 5. Authentication System

## 5.1 Authentication Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Login     │────▶│   Backend   │────▶│  Generate   │
│   Screen    │     │   Verify    │     │   Tokens    │
└─────────────┘     └─────────────┘     └─────────────┘
                                               │
                    ┌─────────────┐            │
                    │   Store     │◀───────────┘
                    │   Tokens    │
                    └─────────────┘
                           │
              ┌────────────┴────────────┐
              ▼                         ▼
       ┌─────────────┐          ┌─────────────┐
       │   Access    │          │   Refresh   │
       │   Token     │          │   Token     │
       │  (15 min)   │          │  (7 days)   │
       └─────────────┘          └─────────────┘
```

## 5.2 Token Management

### Access Token
- Short-lived (15 minutes)
- Stored in Flutter Secure Storage
- Sent with every API request
- Auto-refreshed on 401 response

### Refresh Token
- Long-lived (7 days)
- Stored securely
- Used to obtain new access token
- Rotated on each refresh

## 5.3 AuthService Implementation

```dart
class AuthService extends GetxService {
  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isLoggedIn = false.obs;
  
  Future<bool> login(String email, String password) async {
    try {
      final response = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      final tokens = response.data;
      await _storage.saveAccessToken(tokens['accessToken']);
      await _storage.saveRefreshToken(tokens['refreshToken']);
      
      currentUser.value = UserModel.fromJson(tokens['user']);
      isLoggedIn.value = true;
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } finally {
      await _storage.clearTokens();
      currentUser.value = null;
      isLoggedIn.value = false;
    }
  }
}
```

---

# 6. User Management

## 6.1 User Model

```dart
class UserModel {
  final String id;
  final String email;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? mainPhotoUrl;
  final bool emailVerified;
  final bool selfieVerified;
  final String status; // active, deactivated, banned
  final ProfileModel? profile;
  final List<PhotoModel> photos;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  
  // Computed properties
  String get displayName => '$firstName $lastName'.trim();
  int get photoCount => photos.length;
}
```

## 6.2 Profile Model

```dart
class ProfileModel {
  final String? bio;
  final int? age;
  final String? gender;
  final String? sect;
  final String? prayerFrequency;
  final String? religiousLevel;
  final String? hijabStatus;
  final String? nationality;
  final String? ethnicity;
  final String? education;
  final String? jobTitle;
  final int? height;
  final String? maritalStatus;
  final String? marriageIntention;
  final bool? hasChildren;
  final int? numberOfChildren;
  final String? city;
  final String? country;
  final double? latitude;
  final double? longitude;
  final List<String>? interests;
}
```

---

# 7. Profile System

## 7.1 Profile Controller

The `ProfileController` manages all profile-related operations:

```dart
class ProfileController extends GetxController {
  final Rxn<UserModel> user = Rxn<UserModel>();
  final RxInt barakaScore = 0.obs;
  final RxString barakaLevel = 'low'.obs;
  
  @override
  void onInit() {
    super.onInit();
    fetchProfile();
    calculateBarakaScore();
  }
  
  Future<void> fetchProfile() async {
    final response = await _api.get('/users/me');
    user.value = UserModel.fromJson(response.data);
  }
  
  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _api.patch('/users/me', data: data);
    await fetchProfile();
  }
  
  int get barakaScore {
    // Calculate profile completeness
    int score = 0;
    if (user.value?.profile?.bio != null) score += 10;
    if (user.value?.selfieVerified == true) score += 20;
    if (user.value?.photos.length >= 3) score += 15;
    // ... more criteria
    return score;
  }
}
```

## 7.2 Photo Management

### Upload Flow
1. User selects/captures photo
2. Image cropped and compressed
3. Uploaded to Cloudinary via backend
4. Photo URL saved to user profile

### Photo Verification
- Selfie verification using ML Kit face detection
- Backend AI comparison for authenticity
- Verified badge on successful verification

---

# 8. Matching & Discovery

## 8.1 Recommendation Algorithm

The backend provides recommendations based on:
- **Location proximity** (configurable distance)
- **Religious compatibility** (sect, prayer frequency)
- **Age preferences**
- **Shared interests**
- **Activity status**

## 8.2 Swipe Actions

| Action | Description | Premium |
|--------|-------------|---------|
| Like | Express interest | Free |
| Pass | Skip profile | Free |
| Super Like | Priority notification | Premium |
| Rewind | Undo last action | Premium |

## 8.3 Match Flow

```
User A likes User B
        │
        ▼
┌───────────────────┐
│ Check if B liked A │
└───────────────────┘
        │
   ┌────┴────┐
   ▼         ▼
  Yes        No
   │         │
   ▼         ▼
┌──────┐  ┌────────┐
│MATCH!│  │ Pending │
└──────┘  └────────┘
   │
   ▼
Create conversation
Send notifications
```

---

# 9. Chat & Messaging

## 9.1 Real-time Architecture

The app uses Socket.IO for real-time messaging:

```dart
class ChatService extends GetxService {
  late Socket _socket;
  
  void connect() {
    _socket = io(ApiConstants.socketUrl, OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': _storage.accessToken})
      .build());
    
    _socket.on('new_message', _handleNewMessage);
    _socket.on('message_read', _handleMessageRead);
    _socket.on('typing', _handleTyping);
  }
  
  void sendMessage(String conversationId, String content) {
    _socket.emit('send_message', {
      'conversationId': conversationId,
      'content': content,
    });
  }
}
```

## 9.2 Message Types

| Type | Description |
|------|-------------|
| Text | Plain text messages |
| Image | Photo messages |
| Voice | Voice recordings |
| System | System notifications |

## 9.3 Chat Features

- **Read Receipts:** Double-check marks for read messages
- **Typing Indicators:** Real-time typing status
- **Message Status:** Sent, delivered, read states
- **Media Support:** Images and voice messages
- **Ice Breakers:** Suggested conversation starters

---

# 10. Notifications

## 10.1 Notification Types

| Type | Description |
|------|-------------|
| Match | New match notification |
| Message | New message received |
| Like | Someone liked your profile |
| Profile View | Someone viewed your profile |
| Super Like | Received a super like |
| Safety | Safety alerts |
| Promotion | App promotions |

## 10.2 Notification Settings

```dart
final notifSettings = {
  'matchNotifications': true,
  'messageNotifications': true,
  'likeNotifications': true,
  'profileVisitorNotifications': false,
  'safetyAlertNotifications': true,
  'promotionsNotifications': false,
};
```

---

# 11. Settings & Preferences

## 11.1 SettingsController

```dart
class SettingsController extends GetxController {
  // Theme
  final RxString themeMode = 'system'.obs;
  
  // Privacy
  final RxBool showOnlineStatus = true.obs;
  final RxBool showDistance = true.obs;
  final RxBool showLastSeen = true.obs;
  
  // Chat
  final RxBool receiveDMs = true.obs;
  final RxBool readReceipts = true.obs;
  final RxBool typingIndicator = true.obs;
  
  // Methods
  Future<void> resetAppData() async {
    await _storage.clearPreferences();
    _resetLocalState();
    Helpers.showSnackbar(message: 'App data reset successfully');
  }
  
  Future<bool> submitFeedback(String type, String description) async {
    await _api.post('/support', data: {
      'type': type,
      'subject': type,
      'description': description,
    });
    return true;
  }
}
```

## 11.2 Available Settings

| Category | Settings |
|----------|----------|
| Account | Discovery preferences, Privacy, Security |
| Communication | Notifications, Chat settings, Blocked users |
| Preferences | Subscription, Appearance, Language |
| More | Analytics, Report/Request, Help, Reset data |
| Legal | Terms & Conditions, Privacy Policy |

---

# 12. Security & Privacy

## 12.1 Data Security

- **Token Storage:** Flutter Secure Storage with encryption
- **API Communication:** HTTPS with TLS 1.3
- **Password Hashing:** bcrypt on backend
- **Sensitive Data:** Never stored in plain text

## 12.2 Privacy Features

| Feature | Description |
|---------|-------------|
| Online Status | Toggle visibility |
| Distance | Hide exact location |
| Last Seen | Control visibility |
| Privacy Mode | Enhanced privacy |
| Blocked Users | Block unwanted contacts |

## 12.3 Verification

- **Email Verification:** OTP-based verification
- **Selfie Verification:** AI face matching
- **Photo Moderation:** Content review system

---

# 13. Monetization Features

## 13.1 Subscription Tiers

| Tier | Features |
|------|----------|
| Free | Basic matching, limited likes |
| Premium | Unlimited likes, see who liked you |
| VIP | All features + priority support |

## 13.2 In-App Purchases

- **Boosts:** Increase profile visibility
- **Super Likes:** Premium like feature
- **Rewinds:** Undo last swipe

## 13.3 Payment Integration

```dart
// Stripe integration
Future<void> processPayment(String planId) async {
  final response = await _api.post('/payments/create-intent', data: {
    'planId': planId,
  });
  
  await Stripe.instance.confirmPayment(
    paymentIntentClientSecret: response.data['clientSecret'],
  );
}
```

---

# 14. Data Flow Diagrams

## 14.1 User Registration Flow

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  Email   │──▶│  Verify  │──▶│  Profile │──▶│  Photos  │
│  Screen  │   │   OTP    │   │  Setup   │   │  Upload  │
└──────────┘   └──────────┘   └──────────┘   └──────────┘
                                                   │
┌──────────┐   ┌──────────┐   ┌──────────┐        │
│   Home   │◀──│  Enable  │◀──│  Selfie  │◀───────┘
│  Screen  │   │ Location │   │  Verify  │
└──────────┘   └──────────┘   └──────────┘
```

## 14.2 API Request Flow

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│   UI    │───▶│Controller│───▶│  API    │───▶│ Backend │
│         │    │         │    │ Service │    │         │
└─────────┘    └─────────┘    └─────────┘    └─────────┘
     ▲              │              │              │
     │              │              │              │
     └──────────────┴──────────────┴──────────────┘
              Response Flow (Rx Updates)
```

---

# 15. Deployment & Store Readiness

## 15.1 Android Configuration

### build.gradle.kts
```kotlin
android {
    namespace = "com.methna.methna_app"
    compileSdk = flutter.compileSdkVersion
    
    defaultConfig {
        applicationId = "com.methna.methna_app"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }
}
```

### Permissions (AndroidManifest.xml)
- ✅ INTERNET
- ✅ ACCESS_NETWORK_STATE
- ✅ ACCESS_FINE_LOCATION
- ✅ ACCESS_COARSE_LOCATION
- ✅ CAMERA
- ✅ READ_MEDIA_IMAGES
- ✅ VIBRATE

## 15.2 iOS Configuration

### Info.plist Permissions
- ✅ NSLocationWhenInUseUsageDescription
- ✅ NSLocationAlwaysUsageDescription
- ✅ NSCameraUsageDescription
- ✅ NSPhotoLibraryUsageDescription
- ✅ NSMicrophoneUsageDescription
- ✅ NSFaceIDUsageDescription

## 15.3 Pre-Release Checklist

| Task | Status |
|------|--------|
| App Icon | ✅ Configured |
| Splash Screen | ✅ Configured |
| App Name | ✅ "Methna" |
| Version | ✅ 1.0.0+1 |
| Permissions | ✅ All declared |


## 15.4 Release Build Commands

### Android
```bash
flutter build appbundle --release
# or
flutter build apk --release
```

### iOS
```bash
flutter build ipa --release
```

---

# Appendix A: API Constants Reference

```dart
class ApiConstants {
  static const String baseUrl = 'https://api.methna.com/api/v1';
  static const String socketUrl = 'wss://api.methna.com';
  
  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  
  // Users
  static const String usersMe = '/users/me';
  static const String uploadPhotos = '/users/me/photos';
  static const String updateLocation = '/users/me/location';
  
  // Matching
  static const String recommendations = '/matching/recommendations';
  static const String swipe = '/matching/swipe';
  
  // Chat
  static const String conversations = '/chat/conversations';
  static const String sendMessage = '/chat/messages';
  
  // Content
  static String appContent(String type) => '/content/$type';
  static const String faqContent = '/content/faq';
}
```

---

# Appendix B: Error Handling

```dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  ApiException(this.message, [this.statusCode]);
}

// Usage in controllers
try {
  await _api.post('/endpoint', data: data);
} on DioException catch (e) {
  if (e.response?.statusCode == 400) {
    Helpers.showSnackbar(message: 'Invalid request', isError: true);
  } else if (e.response?.statusCode == 401) {
    // Token refresh handled by interceptor
  } else if (e.response?.statusCode == 500) {
    Helpers.showSnackbar(message: 'Server error', isError: true);
  }
}
```

---

# Appendix C: Storage Keys

| Key | Type | Description |
|-----|------|-------------|
| `access_token` | Secure | JWT access token |
| `refresh_token` | Secure | JWT refresh token |
| `user_data` | Regular | Cached user object |
| `theme_mode` | Regular | light/dark/system |
| `onboarding_complete` | Regular | Boolean flag |
| `notif_*` | Regular | Notification settings |
| `privacy_*` | Regular | Privacy settings |
| `chat_*` | Regular | Chat settings |

---

**Report Generated:** March 28, 2026  
**Total Pages:** 15  
**Document Version:** 1.0

---

*This report provides a comprehensive overview of the Methna application architecture, backend communication, and deployment readiness. For specific implementation details, refer to the source code documentation.*
