import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/signup_data.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/data/services/location_service.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class ProfilePrivacyScreen extends StatefulWidget {
  const ProfilePrivacyScreen({super.key});

  @override
  State<ProfilePrivacyScreen> createState() => _ProfilePrivacyScreenState();
}

class _ProfilePrivacyScreenState extends State<ProfilePrivacyScreen> {
  static const Map<String, ({double lat, double lng})> _countryCoordinates = {
    'Saudi Arabia': (lat: 23.8859, lng: 45.0792),
    'United Arab Emirates': (lat: 23.4241, lng: 53.8478),
    'UAE': (lat: 23.4241, lng: 53.8478),
    'Egypt': (lat: 26.8206, lng: 30.8025),
    'Jordan': (lat: 30.5852, lng: 36.2384),
    'Turkey': (lat: 38.9637, lng: 35.2433),
    'Morocco': (lat: 31.7917, lng: -7.0926),
    'Indonesia': (lat: -0.7893, lng: 113.9213),
    'Malaysia': (lat: 4.2105, lng: 101.9758),
    'Algeria': (lat: 28.0339, lng: 1.6596),
    'United Kingdom': (lat: 55.3781, lng: -3.4360),
    'United States': (lat: 37.0902, lng: -95.7129),
  };

  late final SettingsController controller;
  late final MonetizationService _monetization;
  late final LocationService _location;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SettingsController>();
    _monetization = Get.find<MonetizationService>();
    _location = Get.find<LocationService>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_monetization.fetchEntitlements());
      unawaited(_monetization.fetchInvisibleStatus());
      unawaited(_monetization.fetchPassportLocation());
    });
  }

  bool get _hasInvisibleAccess => _monetization.hasGhostModeAccess;

  bool get _hasPassportAccess => _monetization.hasPassportAccess;

  Future<void> _openUpgradeGate() async {
    Helpers.showSnackbar(message: 'upgrade_to_unlock'.tr, isError: true);
    await Get.toNamed(AppRoutes.subscription);
  }

  Future<void> _toggleInvisible(bool enabled) async {
    if (enabled && !_hasInvisibleAccess) {
      await _monetization.fetchEntitlements();
      if (!_hasInvisibleAccess) {
        await _openUpgradeGate();
        return;
      }
    }

    final success = await _monetization.toggleInvisibleMode(enabled);
    if (!success) {
      Helpers.showSnackbar(message: 'something_went_wrong'.tr, isError: true);
    }
  }

  Future<void> _setPassportFromCurrentLocation() async {
    if (!_hasPassportAccess) {
      await _monetization.fetchEntitlements();
      if (!_hasPassportAccess) {
        await _openUpgradeGate();
        return;
      }
    }

    final position =
        _location.currentPosition.value ??
        await _location.requestLocationWithFeedback();
    if (position == null) {
      return;
    }

    final city = _location.currentCity.value.trim();
    final country = _location.currentCountry.value.trim();
    final fallbackName =
        '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
    final cityName = city.isNotEmpty
        ? city
        : (country.isNotEmpty ? country : fallbackName);

    final success = await _monetization.setPassportLocation(
      position.latitude,
      position.longitude,
      cityName,
      countryName: country.isNotEmpty ? country : null,
    );

    if (!success) {
      Helpers.showSnackbar(message: 'something_went_wrong'.tr, isError: true);
    }
  }

  List<String> get _passportCountryNames {
    final countries = SignupData.supportedCountries.toSet().toList();
    countries.sort();
    return countries;
  }

  Future<({double lat, double lng})> _resolveCountryCoordinates(
    String country,
  ) async {
    final known = _countryCoordinates[country];
    if (known != null) return known;

    try {
      final locations = await locationFromAddress(country);
      if (locations.isNotEmpty) {
        final first = locations.first;
        return (lat: first.latitude, lng: first.longitude);
      }
    } catch (error) {
      debugPrint('[ProfilePrivacy] Could not geocode $country: $error');
    }

    return (lat: 0.0, lng: 0.0);
  }

  Future<void> _setPassportFromCountry(String selectedCountry) async {
    if (!_hasPassportAccess) {
      await _monetization.fetchEntitlements();
      if (!_hasPassportAccess) {
        await _openUpgradeGate();
        return;
      }
    }

    final coordinates = await _resolveCountryCoordinates(selectedCountry);
    final success = await _monetization.setPassportLocation(
      coordinates.lat,
      coordinates.lng,
      selectedCountry,
      countryName: selectedCountry,
    );

    if (!success) {
      Helpers.showSnackbar(message: 'something_went_wrong'.tr, isError: true);
      return;
    }

    Helpers.showSnackbar(message: 'Passport set to $selectedCountry');
  }

  Future<void> _openPassportPicker() async {
    if (!_hasPassportAccess) {
      await _monetization.fetchEntitlements();
      if (!_hasPassportAccess) {
        await _openUpgradeGate();
        return;
      }
    }

    if (!mounted) return;

    final countries = _passportCountryNames;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.travel_explore_rounded),
                title: Text(
                  'passport_mode'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text('passport_mode_desc'.tr),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.my_location_rounded),
                title: Text('Use current location'.tr),
                onTap: () {
                  Navigator.of(context).pop();
                  unawaited(_setPassportFromCurrentLocation());
                },
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: countries.length,
                  itemBuilder: (context, index) {
                    final country = countries[index];
                    return ListTile(
                      leading: const Icon(Icons.public_rounded),
                      title: Text(country),
                      onTap: () {
                        Navigator.of(context).pop();
                        unawaited(_setPassportFromCountry(country));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _clearPassportLocation() async {
    if (!_hasPassportAccess) {
      await _monetization.fetchEntitlements();
      if (!_hasPassportAccess) {
        await _openUpgradeGate();
        return;
      }
    }
    await _monetization.clearPassportLocation();
  }

  String _passportLocationLabel(Map<String, dynamic>? location) {
    if (location == null) return 'off'.tr;

    final city =
        (location['city'] ?? location['cityName'] ?? location['name'] ?? '')
            .toString()
            .trim();
    final country = (location['country'] ?? location['countryName'] ?? '')
        .toString()
        .trim();

    if (city.isEmpty && country.isEmpty) {
      return 'on'.tr;
    }
    if (city.isNotEmpty && country.isNotEmpty) {
      return '$city, $country';
    }
    return city.isNotEmpty ? city : country;
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSimplePageScaffold(
      title: 'profile_privacy'.tr,
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            SettingsPlainListCard(
              children: [
                SettingsPlainTile(
                  title: 'username'.tr,
                  value: controller.username.isEmpty
                      ? '@methna'
                      : '@${controller.username}',
                  onTap: () => Get.toNamed(AppRoutes.changeUsername),
                ),
                SettingsPlainTile(
                  title: 'share_my_profile'.tr,
                  onTap: controller.shareMyProfile,
                ),
                SettingsPlainTile(
                  title: 'privacy_visibility'.tr,
                  value: _visibilityLabel(controller.visibility.value),
                  onTap: () => Get.toNamed(AppRoutes.visibility),
                ),
                SettingsPlainSwitchTile(
                  title: 'invisible_mode'.tr,
                  subtitle: _hasInvisibleAccess ? null : 'upgrade_to_unlock'.tr,
                  value: _monetization.isInvisible.value,
                  onChanged: (value) => unawaited(_toggleInvisible(value)),
                ),
                SettingsPlainTile(
                  title: 'passport_mode'.tr,
                  subtitle: _hasPassportAccess
                      ? 'passport_mode_desc'.tr
                      : 'upgrade_to_unlock'.tr,
                  value: _passportLocationLabel(
                    _monetization.passportLocation.value,
                  ),
                  onTap: () => unawaited(_openPassportPicker()),
                  trailing: _monetization.passportLocation.value != null
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          onPressed: () => unawaited(_clearPassportLocation()),
                        )
                      : null,
                ),
                SettingsPlainTile(
                  title: 'profile_verification'.tr,
                  onTap: () => Get.toNamed(AppRoutes.verificationCenter),
                ),
                SettingsPlainTile(
                  title:
                      '${'blocked_users'.tr} (${controller.blockedUsers.length})',
                  onTap: () => Get.toNamed(AppRoutes.blockedUsers),
                ),
                SettingsPlainTile(
                  title: 'manage_messages'.tr,
                  onTap: () => Get.toNamed(AppRoutes.manageMessages),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsSectionLabel(text: 'more_controls'.tr),
            SettingsPlainListCard(
              children: [
                SettingsPlainSwitchTile(
                  title: 'show_age'.tr,
                  value: controller.showAge.value,
                  onChanged: (value) =>
                      controller.updatePrivacy(showAgeVal: value),
                ),
                SettingsPlainSwitchTile(
                  title: 'show_distance'.tr,
                  value: controller.showDistance.value,
                  onChanged: (value) =>
                      controller.updatePrivacy(showDist: value),
                ),
                SettingsPlainSwitchTile(
                  title: 'show_online_status'.tr,
                  value: controller.showOnlineStatus.value,
                  onChanged: (value) =>
                      controller.updatePrivacy(showOnline: value),
                ),
                SettingsPlainSwitchTile(
                  title: 'show_last_seen'.tr,
                  value: controller.showLastSeen.value,
                  onChanged: (value) =>
                      controller.updatePrivacy(showLastSeenVal: value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _visibilityLabel(String value) {
    switch (value) {
      case 'matches':
        return 'only_matches'.tr;
      case 'nobody':
        return 'nobody'.tr;
      default:
        return 'everyone'.tr;
    }
  }
}
