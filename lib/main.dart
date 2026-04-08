import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:methna_app/app/bindings/initial_binding.dart';
import 'package:methna_app/app/controllers/locale_controller.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/data/services/connectivity_service.dart';
import 'package:methna_app/app/data/services/content_service.dart';
import 'package:methna_app/app/data/services/location_service.dart';
import 'package:methna_app/app/data/services/message_queue_service.dart';
import 'package:methna_app/app/data/services/notification_service.dart';
import 'package:methna_app/app/data/services/permission_service.dart';
import 'package:methna_app/app/data/services/socket_service.dart';
import 'package:methna_app/app/data/services/storage_service.dart';
import 'package:methna_app/app/routes/app_pages.dart';
import 'package:methna_app/app/theme/app_theme.dart';
import 'package:methna_app/app/translations/app_translations.dart';
import 'package:methna_app/core/constants/app_constants.dart';
import 'package:methna_app/core/services/trial_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

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

  await Get.putAsync<ApiService>(
    () => ApiService().init(),
    permanent: true,
  );

  // Locale depends on storage and is needed immediately for app rendering.
  Get.put<LocaleController>(LocaleController(), permanent: true);

  // Everything else is lazy and should not block startup.
  Get.lazyPut<SocketService>(() => SocketService(), fenix: true);
  Get.lazyPut<LocationService>(() => LocationService(), fenix: true);
  Get.lazyPut<NotificationService>(() => NotificationService(), fenix: true);
  Get.lazyPut<MessageQueueService>(() => MessageQueueService(), fenix: true);
  Get.lazyPut<PermissionService>(() => PermissionService(), fenix: true);
  Get.lazyPut<ConnectivityService>(() => ConnectivityService(), fenix: true);
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
      return ThemeMode.system;
    default:
      return ThemeMode.dark;
  }
}

class MethnaApp extends StatelessWidget {
  const MethnaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<StorageService>();

    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: const TextScaler.linear(1.08),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _getSavedThemeMode(storage),
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
      initialBinding: InitialBinding(),
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      translations: AppTranslations(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ar', 'DZ'),
      ],
      locale: _getSavedLocale(storage),
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}
