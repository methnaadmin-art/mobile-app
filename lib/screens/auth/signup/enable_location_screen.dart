import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/data/services/location_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/core/utils/google_fonts_stub.dart';
import 'package:methna_app/core/widgets/signup_mockup_shell.dart';

class EnableLocationScreen extends StatefulWidget {
  const EnableLocationScreen({super.key});

  @override
  State<EnableLocationScreen> createState() => _EnableLocationScreenState();
}

class _EnableLocationScreenState extends State<EnableLocationScreen> {
  final SignupController controller = Get.find<SignupController>();
  bool _isProcessing = false;
  double _distanceKm = 80;

  @override
  void initState() {
    super.initState();
    _distanceKm = controller.preferredDistanceKm.value;
    controller.syncStep(AppRoutes.signupLocation);
  }

  Future<void> _handleEnableLocation() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    final locationService = Get.find<LocationService>();

    try {
      controller.preferredDistanceKm.value = _distanceKm;
      final position = await locationService.requestLocationWithFeedback();
      controller.locationEnabled.value = position != null;
      unawaited(controller.completeSignup(fastEnterHome: true));
    } catch (_) {
      controller.locationEnabled.value = false;
      unawaited(controller.completeSignup(fastEnterHome: true));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleSkip() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    controller.locationEnabled.value = false;
    controller.preferredDistanceKm.value = _distanceKm;
    unawaited(controller.completeSignup(fastEnterHome: true));
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationService = Get.find<LocationService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final busy =
          _isProcessing ||
          controller.isLoading.value ||
          locationService.isFetching.value;

      return PopScope(
        canPop: !busy,
        child: SignupMockScaffold(
          progress: controller.progressPercent,
          onBack: busy ? () {} : controller.goBack,
          title: 'find_matches_nearby'.tr,
          subtitle: 'find_matches_nearby_desc'.tr,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'distance_preference'.tr,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? signupMockTextDark : signupMockText,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_distanceKm.round()} ${'km'.tr}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? signupMockMutedDark : signupMockMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 18,
                  ),
                  inactiveTrackColor: const Color(0xFFE9E7EF),
                  activeTrackColor: signupMockPurple,
                  thumbColor: Colors.white,
                  overlayColor: signupMockPurple.withValues(alpha: 0.12),
                ),
                child: Slider(
                  min: 5,
                  max: 100,
                  value: _distanceKm,
                  onChanged: (value) {
                    setState(() => _distanceKm = value);
                    controller.preferredDistanceKm.value = value;
                  },
                ),
              ),
              const Spacer(),
            ],
          ),
          footer: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SignupMockPrimaryButton(
                label: 'continue'.tr,
                onTap: busy ? null : _handleEnableLocation,
                isLoading: busy,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: busy ? null : _handleSkip,
                child: Text(
                  'skip'.tr,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? signupMockMutedDark : signupMockMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
