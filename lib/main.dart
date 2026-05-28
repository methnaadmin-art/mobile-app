import 'dart:async';
import 'dart:ui';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:methna_app/app/bindings/initial_binding.dart';
import 'package:methna_app/app/controllers/locale_controller.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/data/services/apple_billing_service.dart';
import 'package:methna_app/app/data/services/app_update_service.dart';
import 'package:methna_app/app/data/services/connectivity_service.dart';
import 'package:methna_app/app/data/services/content_service.dart';
import 'package:methna_app/app/data/services/firebase_bootstrap.dart';
import 'package:methna_app/app/data/services/location_service.dart';
import 'package:methna_app/app/data/services/message_queue_service.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:methna_app/app/data/services/notification_service.dart';
import 'package:methna_app/app/data/services/permission_service.dart';
import 'package:methna_app/app/data/services/play_billing_service.dart';
import 'package:methna_app/app/data/services/socket_service.dart';
import 'package:methna_app/app/data/services/storage_service.dart';
import 'package:methna_app/app/routes/app_pages.dart';
import 'package:methna_app/app/theme/app_theme.dart';
import 'package:methna_app/app/translations/app_translations.dart';
import 'package:methna_app/core/constants/app_constants.dart';
import 'package:methna_app/core/services/trial_manager.dart';
import 'package:methna_app/core/widgets/backend_wait_overlay.dart';
import 'package:methna_app/core/widgets/offline_status_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  // Firebase MUST be initialized before any Crashlytics calls.
  final firebaseReady = await initializeFirebaseIfAvailable();

  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[Firebase] Background handler registration skipped: $e');
  }

  // Crashlytics: only hook after Firebase is confirmed initialized
  if (firebaseReady) {
    try {
      // Disable Crashlytics collection in debug; enable in release
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );

      // Preserve the original Flutter error handler so debug red-screen still works
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        // Always record to Crashlytics (non-fatal in debug, fatal in release)
        if (kDebugMode) {
          FirebaseCrashlytics.instance.recordFlutterError(details);
        } else {
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        }
        // Also call the original handler so debug overlay still appears
        originalOnError?.call(details);
      };

      // Catch async errors not handled by Flutter framework
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (e) {
      debugPrint('[Crashlytics] Hook setup failed: $e');
    }
  } else {
    debugPrint('[Crashlytics] Skipped — Firebase not initialized');
  }

  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  await _registerCriticalServicesOnly();

  runApp(const MethnaApp());
}

Future<void> _registerCriticalServicesOnly() async {
  // Only services needed for first paint + initial route decision.
  await Get.putAsync<StorageService>(
    () => StorageService().init(),
    permanent: true,
  );

  await Get.putAsync<ApiService>(() => ApiService().init(), permanent: true);

  Get.put<AppUpdateService>(AppUpdateService(), permanent: true);

  await Get.putAsync<NotificationService>(
    () => NotificationService().init(),
    permanent: true,
  );

  await Get.putAsync<ConnectivityService>(
    () => ConnectivityService().init(),
    permanent: true,
  );

  await Get.putAsync<PlayBillingService>(
    () => PlayBillingService().init(),
    permanent: true,
  );
  await Get.putAsync<AppleBillingService>(
    () => AppleBillingService().init(),
    permanent: true,
  );

  // Locale depends on storage and is needed immediately for app rendering.
  Get.put<LocaleController>(LocaleController(), permanent: true);

  // Everything else is lazy and should not block startup.
  Get.lazyPut<SocketService>(() => SocketService(), fenix: true);
  Get.lazyPut<LocationService>(() => LocationService(), fenix: true);
  Get.lazyPut<MessageQueueService>(() => MessageQueueService(), fenix: true);
  Get.lazyPut<PermissionService>(() => PermissionService(), fenix: true);
  Get.lazyPut<ContentService>(() => ContentService(), fenix: true);
  Get.lazyPut<TrialManager>(() => TrialManager(), fenix: true);
}

Locale _getSavedLocale(StorageService storage) {
  final code = storage.getString('app_language');

  if (code != null && code.contains('_')) {
    final parts = code.split('_');
    if (parts.length == 2) {
      return Locale(parts[0].toLowerCase(), parts[1].toUpperCase());
    }
  }

  return const Locale('en', 'US');
}

ThemeMode _getSavedThemeMode(StorageService storage) {
  switch (storage.themeMode) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
      // Normalize legacy/system values to explicit app themes for consistency.
      return ThemeMode.light;
    default:
      return ThemeMode.light;
  }
}

class MethnaApp extends StatefulWidget {
  const MethnaApp({super.key});

  @override
  State<MethnaApp> createState() => _MethnaAppState();
}

class _MethnaAppState extends State<MethnaApp> with WidgetsBindingObserver {
  StreamSubscription<Uri>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deepLinkSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (Get.isRegistered<AppUpdateService>()) {
        unawaited(Get.find<AppUpdateService>().checkForUpdate());
      }
      // Notify MonetizationService so it can sync purchase state on resume
      if (Get.isRegistered<MonetizationService>()) {
        Get.find<MonetizationService>().onAppResumed();
      }
    }
  }

  void _initDeepLinks() {
    final appLinks = AppLinks();
    _deepLinkSub = appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('[DeepLink] Received: $uri');
        if (Get.isRegistered<MonetizationService>()) {
          Get.find<MonetizationService>().onDeepLinkReturn(uri.toString());
        }
      },
      onError: (e) {
        debugPrint('[DeepLink] Error: $e');
      },
    );

    // Also check initial link in case app was launched from a deep link
    appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        debugPrint('[DeepLink] Initial: $uri');
        if (Get.isRegistered<MonetizationService>()) {
          Get.find<MonetizationService>().onDeepLinkReturn(uri.toString());
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<StorageService>();

    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final appChild = child ?? const SizedBox.shrink();
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1.08)),
          child: Stack(
            children: [
              BackendRequestOverlay(child: appChild),
              const OfflineStatusBanner(),
            ],
          ),
        );
      },
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _getSavedThemeMode(storage),
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
      initialBinding: InitialBinding(),
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => const Scaffold(body: Center(child: Text('Page not found'))),
      ),
      defaultTransition: Transition.rightToLeftWithFade,
      transitionDuration: const Duration(milliseconds: 360),
      translations: AppTranslations(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US'), Locale('ar', 'DZ')],
      locale: _getSavedLocale(storage),
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}

/// ─── Crashlytics Test ───────────────────────────────────────────────
/// Call from a debug-only button or remote config trigger.
/// NEVER ship with this wired to production UI.
///
/// Usage (temporary, in any screen):
///   import 'package:methna_app/main.dart' show testCrash;
///   ElevatedButton(onPressed: testCrash, child: Text('Test Crash'))
///
/// After triggering: close the app completely, relaunch, then check
/// Firebase Console → Crashlytics within 5–15 minutes.
void testCrash() {
  assert(() {
    FirebaseCrashlytics.instance.crash();
    return true;
  }());
}
