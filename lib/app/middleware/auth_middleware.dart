import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';

/// GetX middleware that protects routes requiring authentication.
/// Redirects unauthenticated users to the login screen.
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    try {
      final auth = Get.find<AuthService>();
      if (!auth.isLoggedIn.value) {
        return const RouteSettings(name: AppRoutes.login);
      }
    } catch (_) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}

/// Middleware that redirects already-authenticated users away from
/// auth screens (login, signup) to the home screen.
class GuestMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    try {
      final auth = Get.find<AuthService>();
      if (auth.isLoggedIn.value) {
        return const RouteSettings(name: AppRoutes.main);
      }
    } catch (_) {
      // Service not ready yet; allow navigation
    }
    return null;
  }
}
