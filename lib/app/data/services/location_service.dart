import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:methna_app/core/utils/helpers.dart';

class LocationService extends GetxService {
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxString currentCity = ''.obs;
  final RxString currentCountry = ''.obs;
  final RxBool isFetching = false.obs;

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

  /// Request location WITH full user feedback — shows dialogs on every
  /// possible failure case. Returns the Position or null.
  Future<Position?> requestLocationWithFeedback() async {
    isFetching.value = true;
    try {
      // Step 1: Check if device GPS is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        isFetching.value = false;
        final shouldOpen = await _showDialog(
          title: 'Location Services Disabled',
          message: 'Please enable GPS/Location Services in your device settings to continue.',
          confirmText: 'Open Settings',
        );
        if (shouldOpen == true) {
          await Geolocator.openLocationSettings();
        }
        return null;
      }

      // Step 2: Check/request permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        isFetching.value = false;
        Helpers.showSnackbar(
          message: 'Location permission denied. Please allow access to continue.',
          isError: true,
        );
        return null;
      }

      if (permission == LocationPermission.deniedForever) {
        isFetching.value = false;
        final shouldOpen = await _showDialog(
          title: 'Permission Permanently Denied',
          message: 'Location access was permanently denied. Please enable it in your app settings.',
          confirmText: 'Open App Settings',
        );
        if (shouldOpen == true) {
          await Geolocator.openAppSettings();
        }
        return null;
      }

      // Step 3: Fetch GPS position
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
        message: 'Failed to get location. Please try again.',
        isError: true,
      );
      return null;
    } finally {
      isFetching.value = false;
    }
  }

  Future<bool?> _showDialog({
    required String title,
    required String message,
    required String confirmText,
  }) {
    return Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(confirmText),
          ),
        ],
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
        currentCity.value = placemarks.first.locality ?? '';
        currentCountry.value = placemarks.first.country ?? '';
      }
    } catch (_) {}
  }

  double distanceBetween(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000; // km
  }
}
