import 'dart:async';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:methna_app/core/utils/helpers.dart';

class LocationService extends GetxService {
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxString currentCity = ''.obs;
  final RxString currentCountry = ''.obs;
  final RxString currentCountryCode = ''.obs;
  final RxBool isFetching = false.obs;

  /// Resolve an arbitrary country string or ISO-3166 alpha-2 code to the
  /// canonical English name used by the backend (e.g. "Algerie" → "Algeria",
  /// "DZ" → "Algeria"). Returns the trimmed input if no canonical form can
  /// be found, so legacy data is never lost.
  static String canonicalizeCountry({String? name, String? isoCode}) {
    final code = (isoCode ?? '').trim().toUpperCase();
    if (code.length == 2) {
      try {
        final byCode = CountryService().findByCode(code);
        if (byCode != null && byCode.name.trim().isNotEmpty) {
          return byCode.name.trim();
        }
      } catch (_) {}
    }

    final raw = (name ?? '').trim();
    if (raw.isEmpty) return '';

    try {
      final byName = CountryService().findByName(raw);
      if (byName != null && byName.name.trim().isNotEmpty) {
        return byName.name.trim();
      }
    } catch (_) {}

    // Last-resort manual aliases for locales the picker can't match.
    const aliases = <String, String>{
      'algerie': 'Algeria',
      'algérie': 'Algeria',
      'الجزائر': 'Algeria',
      'maroc': 'Morocco',
      'المغرب': 'Morocco',
      'tunisie': 'Tunisia',
      'تونس': 'Tunisia',
      'égypte': 'Egypt',
      'egypte': 'Egypt',
      'مصر': 'Egypt',
      'arabie saoudite': 'Saudi Arabia',
      'السعودية': 'Saudi Arabia',
      'émirats arabes unis': 'United Arab Emirates',
      'emirats arabes unis': 'United Arab Emirates',
      'الإمارات': 'United Arab Emirates',
      'états-unis': 'United States',
      'etats-unis': 'United States',
      'royaume-uni': 'United Kingdom',
      'france': 'France',
      'espagne': 'Spain',
      'allemagne': 'Germany',
      'italie': 'Italy',
    };
    final lowered = raw.toLowerCase();
    final alias = aliases[lowered];
    if (alias != null) return alias;

    return raw;
  }

  Future<LocationService> init() async {
    return this;
  }

  /// Silent readiness check used during startup/home gating.
  /// This does not trigger the permission prompt.
  Future<bool> isLocationReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    final permission = await Geolocator.checkPermission();
    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  /// Check and request permission — returns true only if fully granted.
  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  /// Silently try to get position — used internally.
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkPermission();
    if (!hasPermission) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('GPS timeout'),
      );
      currentPosition.value = position;
      await _reverseGeocode(position);
      return position;
    } catch (e) {
      debugPrint('[LocationService] getCurrentPosition error: $e');
      return null;
    }
  }

  /// Request location with a single native OS permission prompt at most.
  /// Never shows a blocking dialog and never re-prompts on its own — the
  /// caller must always be able to proceed with `locationEnabled = false`
  /// when this returns null. Location is optional everywhere in the app
  /// (Apple 5.1.5); this is the only entry point that should run during
  /// signup or any automatic/startup flow.
  Future<Position?> requestLocationSilently() async {
    if (isFetching.value) return currentPosition.value;
    isFetching.value = true;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Single native OS prompt. iOS never re-prompts after this, so a
        // second "denied" result here is equivalent to deniedForever.
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('GPS timeout'),
      );
      currentPosition.value = position;
      await _reverseGeocode(position);
      return position;
    } catch (e) {
      debugPrint('[LocationService] requestLocationSilently error: $e');
      return null;
    } finally {
      isFetching.value = false;
    }
  }

  /// Request location from a screen the user explicitly and voluntarily
  /// tapped for a location-specific feature (e.g. the Home "enable
  /// location" banner, Settings > Location, Passport). Only in that
  /// context may we surface a non-blocking notice that optionally offers
  /// to open Settings — the notice is a dismissible snackbar, never a
  /// modal dialog, and it never prevents the caller from continuing.
  Future<Position?> requestLocationWithFeedback() async {
    if (isFetching.value) return currentPosition.value;
    isFetching.value = true;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showOptionalSettingsNotice(
          message:
              'Location Services are off. You can turn them on in Settings to see nearby matches.',
          onOpenSettings: Geolocator.openLocationSettings,
        );
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showOptionalSettingsNotice(
          message: 'Location permission was not granted.',
          onOpenSettings: Geolocator.openAppSettings,
        );
        return null;
      }

      if (permission == LocationPermission.deniedForever) {
        _showOptionalSettingsNotice(
          message:
              'Location access is off. You can enable it anytime in Settings to see nearby matches.',
          onOpenSettings: Geolocator.openAppSettings,
        );
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('GPS timeout'),
      );

      currentPosition.value = position;
      await _reverseGeocode(position);

      Helpers.showSnackbar(message: 'Location enabled successfully! 📍');
      return position;
    } catch (e) {
      Helpers.showSnackbar(
        message: 'Could not get your location right now.',
        isError: true,
      );
      return null;
    } finally {
      isFetching.value = false;
    }
  }

  /// Non-blocking, auto-dismissing notice with an optional "Settings"
  /// action. Never modal, never awaited, never repeated automatically.
  void _showOptionalSettingsNotice({
    required String message,
    required Future<bool> Function() onOpenSettings,
  }) {
    if (Get.context == null) return;
    Get.snackbar(
      'location'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 4),
      isDismissible: true,
      mainButton: TextButton(
        onPressed: () {
          Get.closeCurrentSnackbar();
          unawaited(onOpenSettings());
        },
        child: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _reverseGeocode(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        currentCity.value = place.locality ?? '';
        final iso = (place.isoCountryCode ?? '').trim().toUpperCase();
        currentCountryCode.value = iso;
        currentCountry.value = canonicalizeCountry(
          name: place.country,
          isoCode: iso,
        );
      }
    } catch (_) {}
  }

  double distanceBetween(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000; // km
  }
}
