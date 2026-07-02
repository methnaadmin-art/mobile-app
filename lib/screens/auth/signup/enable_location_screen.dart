import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/data/services/location_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/core/utils/google_fonts_stub.dart';
import 'package:methna_app/core/utils/helpers.dart';
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

  // Location is optional (Apple 5.1.5): whatever happens below — granted,
  // denied, "Don't Allow", Location Services off, timeout — signup always
  // proceeds into the app. Only `locationEnabled` differs.
  Future<void> _handleEnableLocation() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    final locationService = Get.find<LocationService>();

    try {
      controller.preferredDistanceKm.value = _distanceKm;
      final position = await locationService.requestLocationSilently();
      controller.locationEnabled.value = position != null;
      if (position == null) {
        Helpers.showSnackbar(
          message: 'location_optional_notice'.tr,
        );
      }
      await controller.completeSignup(fastEnterHome: true);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleSkipLocation() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      controller.preferredDistanceKm.value = _distanceKm;
      controller.locationEnabled.value = false;
      await controller.completeSignup(fastEnterHome: true);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
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
          subtitle: '',
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
                  activeTrackColor: signupMockPrimary,
                  thumbColor: Colors.white,
                  overlayColor: signupMockPrimary.withValues(alpha: 0.12),
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
              TextButton(
                onPressed: busy ? null : _handleSkipLocation,
                child: Text(
                  'skip_for_now'.tr,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
