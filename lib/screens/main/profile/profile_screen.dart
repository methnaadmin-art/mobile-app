import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:methna_app/app/controllers/home_controller.dart';
import 'package:methna_app/app/controllers/profile_controller.dart';
import 'package:methna_app/app/controllers/users_controller.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:methna_app/app/data/services/permission_service.dart';
import 'package:methna_app/app/data/services/verification_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/utils/cloudinary_url.dart';
import 'package:methna_app/core/utils/google_fonts_stub.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/app_modal_sheet.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  static final ImagePicker _imagePicker = ImagePicker();

  static Future<void> _showPhotoSourceSheet(
    BuildContext context,
    ProfileController controller,
  ) async {
    if (controller.isUploading.value) return;

    await showMethnaModalSheet<void>(
      context: context,
      title: 'Add profile photo',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(LucideIcons.camera, color: AppColors.primary),
            title: const Text('Take a photo'),
            onTap: () async {
              Navigator.of(context).pop();
              await _pickAndUpload(
                context,
                controller,
                source: ImageSource.camera,
              );
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              LucideIcons.imagePlus,
              color: AppColors.primary,
            ),
            title: const Text('Choose from gallery'),
            onTap: () async {
              Navigator.of(context).pop();
              await _pickAndUpload(
                context,
                controller,
                source: ImageSource.gallery,
              );
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              LucideIcons.layoutGrid,
              color: AppColors.primary,
            ),
            title: const Text('Manage all photos'),
            onTap: () {
              Navigator.of(context).pop();
              controller.openEditPhotos();
            },
          ),
        ],
      ),
    );
  }

  static Future<void> _pickAndUpload(
    BuildContext context,
    ProfileController controller, {
    required ImageSource source,
  }) async {
    try {
      final hasPermission = await _requestImageSourcePermission(source);
      if (!hasPermission) return;

      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2560,
        maxHeight: 2560,
        imageQuality: 96,
      );

      if (picked == null) return;

      final existingPhotoCount = controller.user.value?.photos?.length ?? 0;
      final uploaded = await controller.uploadPhoto(
        File(picked.path),
        isMain: existingPhotoCount == 0,
      );

      if (uploaded) {
        await controller.refreshProfile();
        Helpers.showSnackbar(message: 'Photo uploaded successfully');
      }
    } catch (e) {
      Helpers.showSnackbar(message: 'Failed to upload photo', isError: true);
    }
  }

  static Future<bool> _requestImageSourcePermission(ImageSource source) async {
    if (!Get.isRegistered<PermissionService>()) return true;

    final permissionService = Get.find<PermissionService>();
    if (source == ImageSource.camera) {
      return permissionService.requestCamera();
    }
    return permissionService.requestPhotos();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.surfaceLight,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final user = controller.user.value;
          if (user == null) {
            return const _ProfileLoadingState();
          }

          final monetization = Get.find<MonetizationService>();
          final hasActivePremium = user.isPremium || monetization.isPremium;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: controller.refreshProfile,
            child: ProfileShowcaseContent(
              user: user,
              isOwnProfile: true,
              completion: controller.profileCompletion,
              onUpgrade: hasActivePremium
                  ? null
                  : () => Get.toNamed(AppRoutes.subscription),
              onBoost: controller.triggerProfileBoost,
              onSettings: controller.openSettings,
              onEdit: controller.openEditProfile,
              onPhotoTap: (index) =>
                  openProfileGalleryViewer(context, user, initialIndex: index),
              onCameraTap: () => _showPhotoSourceSheet(context, controller),
              extraBottomPadding: 132,
            ),
          );
        }),
      ),
    );
  }
}

class ProfileShowcaseContent extends StatelessWidget {
  const ProfileShowcaseContent({
    super.key,
    required this.user,
    this.isOwnProfile = false,
    this.completion,
    this.onUpgrade,
    this.onBoost,
    this.onSettings,
    this.onEdit,
    this.onPhotoTap,
    this.onCameraTap,
    this.onBack,
    this.onMore,
    this.extraBottomPadding = 120,
    this.heroAvatarSize = 122,
  });

  final UserModel user;
  final bool isOwnProfile;
  final int? completion;
  final VoidCallback? onUpgrade;
  final VoidCallback? onBoost;
  final VoidCallback? onSettings;
  final VoidCallback? onEdit;
  final ValueChanged<int>? onPhotoTap;
  final VoidCallback? onCameraTap;
  final VoidCallback? onBack;
  final VoidCallback? onMore;
  final double extraBottomPadding;
  final double heroAvatarSize;

  @override
  Widget build(BuildContext context) {
    final profile = user.profile;
    final usersController = Get.isRegistered<UsersController>()
        ? Get.find<UsersController>()
        : null;
    final homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : null;
    final preferredDistanceLabel = isOwnProfile
        ? _preferredDistanceLabel(
            profile?.preferredDistanceKm,
            homeController?.maxDistance.value,
            homeController?.useKm.value ?? true,
          )
        : null;
    final locationPermissionLabel = isOwnProfile
        ? _locationPermissionLabel(profile)
        : null;
    final accountHandle = (user.username ?? '').trim().isEmpty
        ? null
        : '@${user.username!.trim().replaceFirst('@', '')}';
    if (isOwnProfile) {
      Get.find<ProfileController>().ensureEngagementStatsBootstrap();
    }
    final sections = [
      if (isOwnProfile)
        _section('Account', [
          _field(
            'Username',
            accountHandle,
            LucideIcons.atSign,
            prettify: false,
          ),
          _field(
            'First name',
            user.firstName,
            LucideIcons.userCircle2,
            prettify: false,
          ),
          _field(
            'Last name',
            user.lastName,
            LucideIcons.userCircle2,
            prettify: false,
          ),
          _field('Email', user.email, LucideIcons.mail, prettify: false),
          _field('Phone', user.phone, LucideIcons.phone, prettify: false),
          _field('Password', 'Secured', LucideIcons.lock, prettify: false),
          _field(
            'Confirm password',
            'Confirmed',
            LucideIcons.shieldCheck,
            prettify: false,
          ),
          _field(
            'Terms & Privacy',
            user.agreedToTerms && user.agreedToPrivacyPolicy
                ? 'Accepted'
                : 'Pending',
            LucideIcons.shieldCheck,
            prettify: false,
          ),
          _field(
            'Registration oath',
            user.oathAccepted ? 'Accepted' : 'Pending',
            LucideIcons.shieldCheck,
            prettify: false,
          ),
        ], useIcons: true),
      if (isOwnProfile)
        _section('Verification', [
          _boolField(
            'Email verification',
            user.emailVerified,
            LucideIcons.mailCheck,
            trueLabel: 'Verified',
            falseLabel: 'Pending',
          ),
          _boolField(
            'Selfie verification',
            user.selfieVerified,
            LucideIcons.camera,
            trueLabel: 'Verified',
            falseLabel: 'Pending',
          ),
          _boolField(
            'Identity verification',
            user.documentVerified,
            LucideIcons.badgeCheck,
            trueLabel: 'Verified',
            falseLabel: 'Pending',
          ),
          _field(
            'Photos uploaded',
            _photoUploadLabel(user),
            LucideIcons.image,
            prettify: false,
          ),
        ], useIcons: true),
      _section('basic_information'.tr, [
        _field(
          'gender'.tr,
          (profile?.gender ?? '').trim().isNotEmpty
              ? _genderLabel(profile?.gender)
              : null,
          _genderIcon(profile?.gender),
          prettify: false,
        ),
        _numberField('age'.tr, profile?.age, LucideIcons.calendarDays),
        _dateField(
          'Date of birth',
          profile?.dateOfBirth,
          LucideIcons.calendarDays,
        ),
        _field(
          'country'.tr,
          _countryLabelWithFlag(profile?.country),
          LucideIcons.mapPin,
          prettify: false,
        ),
        _field('city'.tr, profile?.city, LucideIcons.locate, prettify: false),
        _field(
          'nationality'.tr,
          _countryLabelWithFlag(profile?.nationality),
          LucideIcons.flag,
          prettify: false,
        ),
        _field(
          'nationalities'.tr,
          _countryListWithFlags(profile?.nationalities),
          LucideIcons.flag,
          prettify: false,
        ),
        _field('ethnicity'.tr, profile?.ethnicity, LucideIcons.globe),
        _field('education'.tr, profile?.education, LucideIcons.graduationCap),
        _field(
          'education_details'.tr,
          profile?.educationDetails,
          LucideIcons.school,
          prettify: false,
        ),
        _field(
          'profession'.tr,
          profile?.jobTitle,
          LucideIcons.briefcase,
          prettify: false,
        ),
        _field(
          'company'.tr,
          profile?.company,
          LucideIcons.building2,
          prettify: false,
        ),
        _field(
          'height'.tr,
          profile?.height != null ? '${profile!.height} cm' : null,
          LucideIcons.ruler,
          prettify: false,
        ),
        _field(
          'weight'.tr,
          profile?.weight != null ? '${profile!.weight} kg' : null,
          LucideIcons.scale,
          prettify: false,
        ),
        _field(
          'skin_complexion'.tr,
          profile?.skinComplexion,
          Icons.palette_outlined,
        ),
        _field(
          'body_build'.tr,
          profile?.bodyBuild,
          Icons.accessibility_new_rounded,
        ),
      ], useIcons: true),
      _section('faith_values'.tr, [
        _field('sect'.tr, profile?.sect, LucideIcons.shield),
        _field(
          'religious_level'.tr,
          profile?.religiousLevel,
          LucideIcons.sparkles,
        ),
        _field('prayer'.tr, profile?.prayerFrequency, LucideIcons.sunrise),
        _field('hijab'.tr, profile?.hijabStatus, LucideIcons.shirt),
      ]),
      _section('partner_preferences'.tr, [
        _field(
          'describe_ideal_spouse'.tr,
          profile?.aboutPartner,
          LucideIcons.heart,
          prettify: false,
        ),
      ], useIcons: true),
      _section('family_home'.tr, [
        _field('marital_status'.tr, profile?.maritalStatus, LucideIcons.heartHandshake),
        _field(
          'Marriage timeline',
          _marriageTimelineLabel(profile),
          LucideIcons.timer,
          prettify: false,
        ),
        _field('family_plans'.tr, profile?.familyPlans, LucideIcons.baby),
        _boolField(
          'children'.tr,
          profile?.hasChildren,
          LucideIcons.baby,
          trueLabel: 'has_children'.tr,
          falseLabel: 'no_children'.tr,
        ),
        _numberField(
          'number_of_children'.tr,
          profile?.numberOfChildren,
          LucideIcons.listOrdered,
        ),
        _boolField(
          'wants_children'.tr,
          profile?.wantsChildren,
          LucideIcons.baby,
          trueLabel: 'yes'.tr,
          falseLabel: 'no'.tr,
        ),
        _boolField(
          'willing_to_relocate'.tr,
          profile?.willingToRelocate,
          LucideIcons.plane,
          trueLabel: 'yes'.tr,
          falseLabel: 'no'.tr,
        ),
        if (isOwnProfile)
          _field(
            'Location permission',
            locationPermissionLabel,
            LucideIcons.mapPin,
            prettify: false,
          ),
        if (isOwnProfile)
          _field(
            'distance_preference'.tr,
            preferredDistanceLabel,
            LucideIcons.route,
            prettify: false,
          ),
      ]),
      _section('lifestyle'.tr, [
        _field(
          'living_situation'.tr,
          profile?.livingSituation,
          LucideIcons.home,
        ),
        _field(
          'communication_style'.tr,
          profile?.communicationStyle,
          LucideIcons.messageCircle,
        ),
        _field('dietary'.tr, profile?.dietary, LucideIcons.utensils),
        _field('drinking'.tr, profile?.alcohol, LucideIcons.cupSoda),
        _field('workout'.tr, profile?.workoutFrequency, LucideIcons.dumbbell),
        _field(
          'sleep_schedule'.tr,
          profile?.sleepSchedule,
          LucideIcons.moonStar,
        ),
        _field(
          'social_media'.tr,
          profile?.socialMediaUsage,
          LucideIcons.smartphone,
        ),
        _boolField(
          'pets'.tr,
          profile?.hasPets,
          LucideIcons.dog,
          trueLabel: 'has_pets'.tr,
          falseLabel: 'no_pets'.tr,
        ),
        _field('pet_preference'.tr, profile?.petPreference, LucideIcons.dog),
      ]),
      _section('health_wellness'.tr, [
        _boolField(
          'vaccination'.tr,
          profile?.vaccinationStatus,
          LucideIcons.shieldCheck,
          trueLabel: 'vaccinated'.tr,
          falseLabel: 'not_vaccinated'.tr,
        ),
        _field(
          'blood_type'.tr,
          profile?.bloodType,
          LucideIcons.droplets,
          prettify: false,
        ),
        _field(
          'health_notes'.tr,
          profile?.healthNotes,
          LucideIcons.heartPulse,
          prettify: false,
        ),
      ]),
      _section('favorites'.tr, [
        _listField('music'.tr, profile?.favoriteMusic, LucideIcons.music4),
        _listField('movies'.tr, profile?.favoriteMovies, LucideIcons.film),
        _listField('books'.tr, profile?.favoriteBooks, LucideIcons.bookOpen),
      ]),
    ].whereType<_SectionData>().toList();

    return Stack(
      children: [
        ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(12, 10, 12, extraBottomPadding),
          children: [
            isOwnProfile
                ? _OwnProfileBar(
                    onUpgrade: onUpgrade,
                    onSettings: onSettings,
                    onEdit: onEdit,
                  )
                : _PublicProfileBar(onBack: onBack, onMore: onMore),
            const SizedBox(height: 12),
            _ProfileHeaderCard(
              user: user,
              onPhotoTap: onPhotoTap,
              onCameraTap: onCameraTap,
              heroAvatarSize: heroAvatarSize,
            ),
            if (isOwnProfile) ...[
              const SizedBox(height: 14),
              const _IdentityVerificationCard(),
            ],
            if (isOwnProfile && completion != null) ...[
              const SizedBox(height: 12),
              _CompletionBanner(completion: completion!, onTap: onEdit),
            ],
            if (isOwnProfile) ...[
              const SizedBox(height: 16),
              _ProfileStatsPanel(
                user: user,
                usersController: usersController,
                completion: completion,
              ),
              if (onBoost != null) ...[
                const SizedBox(height: 16),
                _BoostProfileCard(
                  onTap: onBoost!,
                  boostsUsed: user.profileBoostsCount,
                ),
              ],
            ],
            const SizedBox(height: 16),
            _ProfileGalleryCard(
              user: user,
              isOwnProfile: isOwnProfile,
              onTap: onPhotoTap,
            ),
            if ((profile?.bio ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _TextCard(title: 'about_me'.tr, text: profile!.bio!.trim()),
            ],
            if ((profile?.interests ?? const <String>[]).isNotEmpty) ...[
              const SizedBox(height: 16),
              _ChipCard(
                title: 'interests'.tr,
                values: profile!.interests!,
                emojiize: true,
              ),
            ],
            if (_relationshipGoal(profile) != null) ...[
              const SizedBox(height: 16),
              _ChipCard(
                title: 'relationship_goals'.tr,
                values: [_relationshipGoal(profile)!],
              ),
            ],
            if ((profile?.languages ?? const <String>[]).isNotEmpty) ...[
              const SizedBox(height: 16),
              _ChipCard(
                title: 'languages_speak'.tr,
                values: profile!.languages!,
                emojiize: true,
              ),
            ],
            if ((profile?.familyValues ?? const <String>[]).isNotEmpty) ...[
              const SizedBox(height: 16),
              _ChipCard(
                title: 'family_values'.tr,
                values: profile!.familyValues!,
              ),
            ],
            if ((profile?.travelPreferences ?? const <String>[])
                .isNotEmpty) ...[
              const SizedBox(height: 16),
              _ChipCard(
                title: 'travel_preferences'.tr,
                values: profile!.travelPreferences!,
                emojiize: true,
              ),
            ],
            for (final section in sections) ...[
              const SizedBox(height: 16),
              _SectionCard(section: section),
            ],
          ],
        ),
      ],
    );
  }
}

class _ProfileLoadingState extends StatelessWidget {
  const _ProfileLoadingState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFECE7F6),
          ),
        ),
        child: Text(
          'loading'.tr,
          style: AppTextStyles.labelLarge.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _OwnProfileBar extends StatelessWidget {
  const _OwnProfileBar({this.onUpgrade, this.onSettings, this.onEdit});

  final VoidCallback? onUpgrade;
  final VoidCallback? onSettings;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (onUpgrade != null)
            Align(
              alignment: Alignment.centerLeft,
              child: _UpgradePill(onTap: onUpgrade!),
            ),
          Text(
            'My Profile',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF25163D),
              letterSpacing: -0.4,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null) ...[
                  _RoundButton(
                    icon: LucideIcons.pencil,
                    onTap: onEdit,
                    size: 42,
                    backgroundColor: Colors.transparent,
                    borderColor: Colors.transparent,
                    iconColor: const Color(0xFF7046F8),
                  ),
                  const SizedBox(width: 8),
                ],
                _RoundButton(
                  icon: LucideIcons.settings2,
                  onTap: onSettings,
                  size: 42,
                  backgroundColor: Colors.transparent,
                  borderColor: Colors.transparent,
                  iconColor: const Color(0xFF7046F8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicProfileBar extends StatelessWidget {
  const _PublicProfileBar({this.onBack, this.onMore});

  final VoidCallback? onBack;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _RoundButton(icon: LucideIcons.chevronLeft, onTap: onBack),
          ),
          Text(
            'profile'.tr,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : const Color(0xFF232129),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _RoundButton(icon: LucideIcons.moreVertical, onTap: onMore),
          ),
        ],
      ),
    );
  }
}

class _UpgradePill extends StatelessWidget {
  const _UpgradePill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6E3DFB), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'upgrade'.tr,
                style: GoogleFonts.poppins(
                  fontSize: 9.4,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    this.onTap,
    this.size = 30,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedBackground =
        backgroundColor ??
        (isDark ? AppColors.surfaceDark : const Color(0xFFF7F6FB));
    final resolvedBorder =
        borderColor ??
        (isDark ? AppColors.borderDark : const Color(0xFFECE7F6));
    final resolvedIconColor =
        iconColor ??
        (isDark ? AppColors.textPrimaryDark : const Color(0xFF4F475B));
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: resolvedBackground,
            shape: BoxShape.circle,
            border: Border.all(color: resolvedBorder),
            boxShadow: [
              if (!isDark)
                const BoxShadow(
                  color: Color(0x120F0624),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
            ],
          ),
          child: Icon(
            icon,
            size: size <= 32 ? 16 : 18,
            color: resolvedIconColor,
          ),
        ),
      ),
    );
  }
}

class _CompletionBanner extends StatelessWidget {
  const _CompletionBanner({required this.completion, this.onTap});
  final int completion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6E3DFB), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  '$completion%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      completion >= 100
                          ? 'profile_complete'.tr
                          : 'complete_your_profile'.tr,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      completion >= 100
                          ? 'profile_complete_desc'.tr
                          : 'complete_profile_desc'.tr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 8.8,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.sparkles,
                size: 14,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityVerificationCard extends StatefulWidget {
  const _IdentityVerificationCard();

  @override
  State<_IdentityVerificationCard> createState() =>
      _IdentityVerificationCardState();
}

class _IdentityVerificationCardState extends State<_IdentityVerificationCard> {
  final VerificationService _verification = Get.find<VerificationService>();

  @override
  void initState() {
    super.initState();
    Future.microtask(_verification.fetchVerificationStatus);
  }

  Future<void> _openVerificationCenter() async {
    await Get.toNamed(AppRoutes.verificationCenter);
    if (!mounted) return;
    await _verification.fetchVerificationStatus();
  }

  Color _statusColor(String value) {
    switch (value) {
      case 'verified':
        return const Color(0xFF12805C);
      case 'pending_review':
        return const Color(0xFF6E3DFB);
      case 'reverify_required':
        return const Color(0xFF4F26D9);
      default:
        return const Color(0xFF4F475B);
    }
  }

  String _title(String value) {
    switch (value) {
      case 'verified':
        return 'identity_verified'.tr;
      case 'pending_review':
        return 'identity_review_progress'.tr;
      case 'reverify_required':
        return 'reupload_identity'.tr;
      default:
        return 'identity_not_verified'.tr;
    }
  }

  String _subtitle(String value) {
    final reason = _verification.idDocRejectionReason.value.trim();
    switch (value) {
      case 'verified':
        return 'identity_verified_desc'.tr;
      case 'pending_review':
        return 'identity_pending_desc'.tr;
      case 'reverify_required':
        return reason.isNotEmpty ? reason : 'identity_reverify_desc'.tr;
      default:
        return 'identity_not_verified_desc'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final status = _verification.idDocStatus.value;
      final statusColor = _statusColor(status);
      final type = _verification.idDocType.value.trim();

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openVerificationCenter,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              gradient: isDark
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFFFFF), Color(0xFFF4F0FF)],
                    ),
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFE7DDF8),
              ),
              boxShadow: isDark
                  ? const []
                  : const [
                      BoxShadow(
                        color: Color(0x120F0624),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFA78BFA),
                        statusColor.withValues(alpha: 0.92),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    status == 'verified'
                        ? LucideIcons.badgeCheck
                        : status == 'reverify_required'
                        ? LucideIcons.shield
                        : LucideIcons.badge,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'verification_center'.tr,
                        style: GoogleFonts.poppins(
                          fontSize: 13.4,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : const Color(0xFF232129),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _subtitle(status),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10.8,
                          height: 1.45,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : const Color(0xFF6F697B),
                        ),
                      ),
                      if (type.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${'identity_document'.tr}: ${_pretty(type)}',
                          style: GoogleFonts.poppins(
                            fontSize: 9.8,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _title(status),
                        style: GoogleFonts.poppins(
                          fontSize: 9.2,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : const Color(0xFF8B8496),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.user,
    this.onPhotoTap,
    this.onCameraTap,
    this.heroAvatarSize = 122,
  });

  final UserModel user;
  final ValueChanged<int>? onPhotoTap;
  final VoidCallback? onCameraTap;
  final double heroAvatarSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = user.profile;
    final backgroundStatus = _normalizeBackgroundStatus(
      user.backgroundCheckStatus,
    );
    final name = _resolvedDisplayName(user);
    final username = (user.username ?? '').trim();
    final handle = username.isEmpty ? '' : '@${username.replaceFirst('@', '')}';
    final location = _locationLabel(profile, includeFlag: true);
    final nationality = _countryLabelWithFlag(profile?.nationality);
    final age = profile?.age;
    final showLocation =
        location.trim().isNotEmpty && location != 'location_hidden'.tr;
    final showNationality =
        (nationality ?? '').trim().isNotEmpty &&
        nationality != 'location_hidden'.tr;
    final showBackground = backgroundStatus != 'not_started';
    final avatarOverlap = heroAvatarSize * 0.48;
    final heroHeight = 176 + ((heroAvatarSize - 122).clamp(0, 40) * 0.6);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE7DDF8),
        ),
        boxShadow: isDark
            ? const []
            : const [
                BoxShadow(
                  color: Color(0x120F0624),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
      ),
      child: Column(
        children: [
          Container(
            height: heroHeight,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFA78BFA), Color(0xFF6E3DFB)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 18,
                  left: 22,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: 32,
                  right: 26,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 26,
                  left: 58,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      if (user.isPremium)
                        _ProfileMetaChip(
                          icon: LucideIcons.crown,
                          text: 'Premium',
                          color: const Color(0xFFA78BFA),
                        ),
                      if (user.isPremium && user.selfieVerified)
                        const SizedBox(width: 6),
                      if (user.selfieVerified)
                        _ProfileMetaChip(
                          icon: LucideIcons.badgeCheck,
                          text: 'verified_profile'.tr,
                          color: Colors.white,
                        )
                      else if (!user.isPremium)
                        const SizedBox(width: 40),
                      const Spacer(),
                      if (showBackground)
                        _ProfileMetaChip(
                          icon: LucideIcons.shieldCheck,
                          text: _backgroundCheckStatusLabel(
                            user.backgroundCheckStatus,
                          ),
                          color: const Color(0xFFFFE89A),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -avatarOverlap,
                  child: Center(
                    child: _HeroCard(
                      user: user,
                      onTap: onPhotoTap,
                      onCameraTap: onCameraTap,
                      circular: true,
                      size: heroAvatarSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, avatarOverlap + 14, 20, 20),
            child: Column(
              children: [
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF25163D),
                    letterSpacing: -0.7,
                  ),
                ),
                if (handle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    handle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : const Color(0xFF8B7AA8),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (age != null && age > 0)
                      _ProfileMetaChip(
                        icon: LucideIcons.calendarDays,
                        text: age.toString(),
                        color: const Color(0xFF7E57FF),
                      ),
                    _ProfileMetaChip(
                      icon: _genderIcon(profile?.gender),
                      text: _genderLabel(profile?.gender),
                      color: const Color(0xFFFF8B4D),
                    ),
                    if (showLocation)
                      _ProfileMetaChip(
                        icon: LucideIcons.mapPin,
                        text: location,
                        color: const Color(0xFF4D9CFF),
                      ),
                    if (showNationality)
                      _ProfileMetaChip(
                        icon: LucideIcons.flag,
                        text: nationality!,
                        color: const Color(0xFFFF7E7E),
                      ),
                    if (user.isPremium)
                      _ProfileMetaChip(
                        icon: LucideIcons.crown,
                        text: 'Premium',
                        color: const Color(0xFFA78BFA),
                      ),
                    if (user.selfieVerified)
                      _ProfileMetaChip(
                        icon: LucideIcons.shieldCheck,
                        text: 'identity_verified'.tr,
                        color: const Color(0xFF31C48D),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMetaChip extends StatelessWidget {
  const _ProfileMetaChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : const Color(0xFF4B3967);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.38 : 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10.4,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatsPanel extends StatelessWidget {
  const _ProfileStatsPanel({
    required this.user,
    required this.usersController,
    this.completion,
  });

  final UserModel user;
  final UsersController? usersController;
  final int? completion;

  @override
  Widget build(BuildContext context) {
    if (usersController == null) {
      return _buildPanel(
        context,
        likesSent: 0,
        likesReceived: 0,
        complimentsSent: user.sentComplimentsCount,
        matchesCount: 0,
      );
    }

    return Obx(
      () => _buildPanel(
        context,
        likesSent: usersController!.likedUsers.length,
        likesReceived: usersController!.whoLikedMeCount.value,
        complimentsSent: user.sentComplimentsCount,
        matchesCount: usersController!.matches.length,
      ),
    );
  }

  Widget _buildPanel(
    BuildContext context, {
    required int likesSent,
    required int likesReceived,
    required int complimentsSent,
    required int matchesCount,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF281D41), const Color(0xFF1D1733)]
              : [const Color(0xFFFFF5F7), const Color(0xFFFFF3FA)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFEDE9FE),
        ),
        boxShadow: isDark
            ? const []
            : const [
                BoxShadow(
                  color: Color(0x0F5C2D9F),
                  blurRadius: 20,
                  offset: Offset(0, 9),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.barChart3,
                size: 15,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'profile_engagement'.tr,
                style: GoogleFonts.poppins(
                  fontSize: 12.4,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF2A223B),
                ),
              ),
              const Spacer(),
              if (completion != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: isDark ? 0.25 : 0.14,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${completion!.clamp(0, 100)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.primaryDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatMetricTile(
                  icon: LucideIcons.send,
                  value: likesSent,
                  label: 'likes_sent'.tr,
                  color: const Color(0xFFFF5AA6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatMetricTile(
                  icon: LucideIcons.heartHandshake,
                  value: likesReceived,
                  label: 'likes_received'.tr,
                  color: const Color(0xFF45B7FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatMetricTile(
                  icon: LucideIcons.messageSquare,
                  value: complimentsSent,
                  label: 'compliments_sent'.tr,
                  color: const Color(0xFF6E3DFB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatMetricTile(
                  icon: LucideIcons.users,
                  value: matchesCount,
                  label: 'matches'.tr,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatMetricTile extends StatelessWidget {
  const _StatMetricTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFEDE5FB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.28 : 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF231A38),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 9.6,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : const Color(0xFF6E6485),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoostProfileCard extends StatelessWidget {
  const _BoostProfileCard({required this.onTap, required this.boostsUsed});

  final VoidCallback onTap;
  final int boostsUsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6E3DFB), Color(0xFF6E3DFB), Color(0xFFFF5AA6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x292E0E67),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: const Icon(LucideIcons.zap, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'boost_profile_title'.tr,
                  style: GoogleFonts.poppins(
                    fontSize: 12.6,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'boost_profile_hint'.tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 9.8,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${'boosts_label'.tr}: $boostsUsed',
                  style: GoogleFonts.poppins(
                    fontSize: 9.8,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6227E8),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(
              'boost_profile'.tr,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileGalleryCard extends StatelessWidget {
  const _ProfileGalleryCard({
    required this.user,
    required this.isOwnProfile,
    this.onTap,
  });

  final UserModel user;
  final bool isOwnProfile;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final urls = _collectProfilePhotoUrls(user);
    final lockedCount = isOwnProfile ? 0 : user.lockedPhotoCount;
    final totalPhotoCount = urls.length + lockedCount;
    final previewCount = totalPhotoCount > 6 ? 6 : totalPhotoCount;
    final visiblePreviewCount = urls.length > previewCount
        ? previewCount
        : urls.length;
    final previewUrls = urls.take(visiblePreviewCount).toList(growable: false);
    final hasMore = totalPhotoCount > previewCount;
    final hiddenCount = totalPhotoCount - previewCount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: isDark ? 0.28 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  LucideIcons.image,
                  size: 15,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOwnProfile ? 'my_photos'.tr : 'profile_gallery'.tr,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : const Color(0xFF232129),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'profile_gallery_hint'.tr,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : const Color(0xFF7D748F),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                TextButton(
                  onPressed: () {
                    if (urls.isNotEmpty) {
                      onTap!(0);
                      return;
                    }
                    if (lockedCount > 0) {
                      Get.toNamed(AppRoutes.verificationCenter);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? AppColors.primaryLight
                        : AppColors.primary,
                    textStyle: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text('view_all_photos'.tr),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (previewCount == 0)
            Container(
              height: 104,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : const Color(0xFFF7F3FD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : const Color(0xFFECE4FA),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                LucideIcons.imageOff,
                size: 24,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : const Color(0xFF8E82AA),
              ),
            )
          else
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: previewCount,
                separatorBuilder: (_, _) => const SizedBox(width: 9),
                itemBuilder: (context, index) {
                  final isLockedPreview = index >= visiblePreviewCount;
                  final url = isLockedPreview ? '' : previewUrls[index];
                  final showOverlay = hasMore && index == previewCount - 1;
                  return GestureDetector(
                    onTap: onTap == null
                        ? null
                        : () {
                            if (!isLockedPreview) {
                              onTap!(index);
                              return;
                            }
                            Get.toNamed(AppRoutes.verificationCenter);
                          },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 88,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (!isLockedPreview)
                              CachedNetworkImage(
                                imageUrl: CloudinaryUrl.large(url),
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.surfaceDark
                                        : const Color(0xFFF2ECFA),
                                  ),
                                  child: Icon(
                                    LucideIcons.imageOff,
                                    size: 19,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : const Color(0xFF8E82AA),
                                  ),
                                ),
                              )
                            else
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isDark
                                        ? const [
                                            Color(0xFF251C37),
                                            Color(0xFF1A1427),
                                          ]
                                        : const [
                                            Color(0xFFF4F0FF),
                                            Color(0xFFEDE9FE),
                                          ],
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.lock,
                                        size: 19,
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.9,
                                              )
                                            : const Color(0xFF6E47A7),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Locked',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.95,
                                                )
                                              : const Color(0xFF6E47A7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (showOverlay)
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xAA1B1230),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    '+$hiddenCount',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (lockedCount > 0 && !isOwnProfile) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: (isDark
                    ? const Color(0xFF2A1D25)
                    : const Color(0xFFF4F0FF)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.lock,
                    size: 16,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : const Color(0xFF6E47A7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$lockedCount photos are locked. Verify to unlock full gallery.',
                      style: GoogleFonts.poppins(
                        fontSize: 10.8,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.92)
                            : const Color(0xFF5A3C8D),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.verificationCenter),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Verify',
                      style: GoogleFonts.poppins(
                        fontSize: 10.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.user,
    this.onTap,
    this.onCameraTap,
    this.circular = false,
    this.size,
  });
  final UserModel user;
  final ValueChanged<int>? onTap;
  final VoidCallback? onCameraTap;
  final bool circular;
  final double? size;

  String _extractEmbeddedUrl(String input) {
    final value = input.trim();
    if (value.isEmpty) return '';

    final jsonUrl = RegExp(
      "[\"']url[\"']\\s*:\\s*[\"']([^\"']+)[\"']",
      caseSensitive: false,
    ).firstMatch(value);
    if (jsonUrl != null) {
      final extracted = (jsonUrl.group(1) ?? '').trim();
      if (extracted.isNotEmpty) return extracted;
    }

    final absoluteUrl = RegExp(
      "https?://[^\\s\"']+",
      caseSensitive: false,
    ).firstMatch(value);
    if (absoluteUrl != null) {
      return (absoluteUrl.group(0) ?? '').trim();
    }

    return value;
  }

  String _apiOrigin() {
    final base = ApiConstants.baseUrl.trim();
    if (base.isEmpty) return '';

    final uri = Uri.tryParse(base);
    if (uri == null || uri.host.isEmpty) return '';

    final scheme = uri.scheme.isNotEmpty ? uri.scheme : 'https';
    final portSegment = uri.hasPort ? ':${uri.port}' : '';
    return '$scheme://${uri.host}$portSegment';
  }

  String _normalizePhotoUrl(String? candidate) {
    var value = (candidate ?? '').trim();
    if (value.isEmpty) return '';

    value = value.replaceAll('\\', '/');

    while (value.startsWith('"') || value.startsWith("'")) {
      value = value.substring(1);
    }
    while (value.endsWith('"') || value.endsWith("'")) {
      value = value.substring(0, value.length - 1);
    }

    value = _extractEmbeddedUrl(value);
    if (value.isEmpty) return '';

    final lower = value.toLowerCase();
    if (lower == 'null' ||
        lower == 'undefined' ||
        lower == 'nan' ||
        lower == '[object object]' ||
        lower.startsWith('data:') ||
        lower.startsWith('blob:')) {
      return '';
    }

    if (value.startsWith('//')) {
      return 'https:$value';
    }

    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      final parsed = Uri.tryParse(value);
      if (parsed == null || parsed.host.isEmpty) return '';

      final hostLower = parsed.host.toLowerCase();
      final localHosts = <String>{
        'localhost',
        '127.0.0.1',
        '0.0.0.0',
        '10.0.2.2',
        '::1',
        '[::1]',
      };

      final apiOrigin = Uri.tryParse(_apiOrigin());
      if (apiOrigin != null && localHosts.contains(hostLower)) {
        return parsed
            .replace(
              scheme: apiOrigin.scheme,
              host: apiOrigin.host,
              port: apiOrigin.hasPort ? apiOrigin.port : null,
            )
            .toString();
      }

      final secureUri =
          parsed.scheme.toLowerCase() == 'http' &&
              !localHosts.contains(hostLower)
          ? parsed.replace(scheme: 'https')
          : parsed;
      return Uri.encodeFull(secureUri.toString());
    }

    final knownScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+\-.]*://');
    if (knownScheme.hasMatch(value)) {
      return '';
    }

    if (RegExp(r'^[\w.-]+\.[a-zA-Z]{2,}(/.*)?$').hasMatch(value)) {
      return Uri.encodeFull('https://$value');
    }

    final origin = _apiOrigin();
    if (origin.isNotEmpty) {
      if (value.startsWith('/')) {
        return Uri.encodeFull('$origin$value');
      }

      if (value.startsWith('uploads/') ||
          value.startsWith('upload/') ||
          value.startsWith('images/') ||
          value.startsWith('media/') ||
          value.startsWith('api/') ||
          value.startsWith('v1/')) {
        return Uri.encodeFull('$origin/$value');
      }
    }

    return Uri.encodeFull(value);
  }

  List<String> _resolvePhotoUrls() {
    final results = <String>[];
    final seen = <String>{};
    final candidates = <String?>[
      user.mainPhotoUrl,
      user.fallbackPhotoUrl,
      ...(user.photos ?? const <PhotoModel>[])
          .where((photo) => !photo.isLocked)
          .map((photo) => photo.url),
    ];

    for (final candidate in candidates) {
      final normalized = _normalizePhotoUrl(candidate);
      if (normalized.isEmpty) continue;

      final uri = Uri.tryParse(normalized);
      if (uri != null &&
          (uri.scheme.toLowerCase() == 'http' ||
              uri.scheme.toLowerCase() == 'https') &&
          uri.host.isNotEmpty) {
        final transformed = CloudinaryUrl.large(normalized);
        if (transformed.isNotEmpty &&
            transformed != normalized &&
            seen.add(transformed)) {
          results.add(transformed);
        }
        if (seen.add(normalized)) {
          results.add(normalized);
        }
      }
    }

    return results;
  }

  Widget _fallback(bool isDark) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1520), const Color(0xFF241D28)]
              : [const Color(0xFFF4F0FF), const Color(0xFFEDE9FE)],
        ),
      ),
      child: Center(
        child: Text(
          Helpers.getInitials(user.firstName, user.lastName),
          style: GoogleFonts.poppins(
            fontSize: circular ? 40 : 52,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrls = _resolvePhotoUrls();
    final image = imageUrls.isEmpty
        ? _fallback(isDark)
        : _ResilientHeroImage(urls: imageUrls, fallback: _fallback(isDark));

    if (circular) {
      final avatarSize = size ?? 116;
      return GestureDetector(
        onTap: onTap == null ? null : () => onTap!(0),
        child: SizedBox(
          width: avatarSize,
          height: avatarSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(child: image),
                ),
              ),
              if (onCameraTap != null)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onCameraTap,
                      customBorder: const CircleBorder(),
                      child: Ink(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE7DDF8)),
                        ),
                        child: const Icon(
                          LucideIcons.camera,
                          size: 14,
                          color: Color(0xFF6E3DFB),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 0.9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              image,
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x08000000), Color(0x3A000000)],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 30,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResilientHeroImage extends StatefulWidget {
  const _ResilientHeroImage({required this.urls, required this.fallback});

  final List<String> urls;
  final Widget fallback;

  @override
  State<_ResilientHeroImage> createState() => _ResilientHeroImageState();
}

class _ResilientHeroImageState extends State<_ResilientHeroImage> {
  int _activeIndex = 0;

  void _tryNextUrl() {
    if (_activeIndex >= widget.urls.length - 1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_activeIndex >= widget.urls.length - 1) return;
      setState(() => _activeIndex += 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) return widget.fallback;

    final safeIndex = _activeIndex.clamp(0, widget.urls.length - 1);
    final currentUrl = widget.urls[safeIndex];

    return CachedNetworkImage(
      key: ValueKey<String>(currentUrl),
      imageUrl: currentUrl,
      fit: BoxFit.cover,
      errorWidget: (context, url, error) {
        _tryNextUrl();
        return safeIndex < widget.urls.length - 1
            ? const ColoredBox(color: Color(0x22000000))
            : widget.fallback;
      },
    );
  }
}

class _TextCard extends StatelessWidget {
  const _TextCard({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : const Color(0xFF232129),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              height: 1.55,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : const Color(0xFF5F5A68),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipCard extends StatelessWidget {
  const _ChipCard({
    required this.title,
    required this.values,
    this.emojiize = false,
  });
  final String title;
  final List<String> values;
  final bool emojiize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : const Color(0xFF232129),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values
                .where((item) => item.trim().isNotEmpty)
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : const Color(0xFFE9E3F3),
                      ),
                    ),
                    child: Text(
                      emojiize ? _emojiizedChipValue(item) : _pretty(item),
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : const Color(0xFF4F475B),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});
  final _SectionData section;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : const Color(0xFF232129),
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < section.fields.length; i++) ...[
            _SectionRow(field: section.fields[i], useIcons: section.useIcons),
            if (i != section.fields.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark
                      ? AppColors.borderDark
                      : const Color(0xFFF2EDF8),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.field, required this.useIcons});
  final _FieldData field;
  final bool useIcons;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = _fieldIconColor(field.icon);
    final emoji = _fieldEmoji(field.icon);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: isDark ? 0.24 : 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: useIcons
              ? Icon(field.icon, size: 14, color: iconColor)
              : Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 13)),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                field.label,
                style: GoogleFonts.poppins(
                  fontSize: 10.2,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : const Color(0xFF6E6386),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                field.value,
                style: GoogleFonts.poppins(
                  fontSize: 11.6,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF232129),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void openProfileGalleryViewer(
  BuildContext context,
  UserModel user, {
  int initialIndex = 0,
}) {
  final urls = _collectProfilePhotoUrls(user);
  if (urls.isEmpty) return;

  final safeIndex = initialIndex.clamp(0, urls.length - 1).toInt();

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _ProfilePhotoViewerPage(
        user: user,
        photoUrls: urls,
        initialIndex: safeIndex,
      ),
    ),
  );
}

class _ProfilePhotoViewerPage extends StatefulWidget {
  const _ProfilePhotoViewerPage({
    required this.user,
    required this.photoUrls,
    required this.initialIndex,
  });

  final UserModel user;
  final List<String> photoUrls;
  final int initialIndex;

  @override
  State<_ProfilePhotoViewerPage> createState() =>
      _ProfilePhotoViewerPageState();
}

class _ProfilePhotoViewerPageState extends State<_ProfilePhotoViewerPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFF171321),
      alignment: Alignment.center,
      child: Text(
        Helpers.getInitials(widget.user.firstName, widget.user.lastName),
        style: GoogleFonts.poppins(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1}/${widget.photoUrls.length}',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photoUrls.length,
        onPageChanged: (value) => setState(() => _currentIndex = value),
        itemBuilder: (context, index) {
          final rawUrl = widget.photoUrls[index];
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: CloudinaryUrl.full(rawUrl),
                fit: BoxFit.contain,
                placeholder: (_, _) => const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.image_outlined,
                    size: 28,
                    color: Colors.white70,
                  ),
                ),
                errorWidget: (_, _, _) => _fallback(),
              ),
            ),
          );
        },
      ),
    );
  }
}

BoxDecoration _cardDecoration(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: isDark ? AppColors.cardDark : Colors.white,
    borderRadius: const BorderRadius.all(Radius.circular(16)),
    border: Border.fromBorderSide(
      BorderSide(
        color: isDark ? AppColors.borderDark : const Color(0xFFF0ECF7),
      ),
    ),
    boxShadow: isDark
        ? const []
        : const [
            BoxShadow(
              color: Color(0x0A1C0D37),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
  );
}

class _SectionData {
  const _SectionData({
    required this.title,
    required this.fields,
    this.useIcons = false,
  });
  final String title;
  final List<_FieldData> fields;
  final bool useIcons;
}

class _FieldData {
  const _FieldData({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;
}

_SectionData? _section(
  String title,
  List<_FieldData?> fields, {
  bool useIcons = false,
}) {
  final cleaned = fields.whereType<_FieldData>().toList();
  if (cleaned.isEmpty) return null;
  return _SectionData(title: title, fields: cleaned, useIcons: useIcons);
}

_FieldData? _field(
  String label,
  String? value,
  IconData icon, {
  bool prettify = true,
}) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return null;
  return _FieldData(
    label: label,
    value: prettify ? _pretty(text) : text,
    icon: icon,
  );
}

_FieldData? _numberField(String label, int? value, IconData icon) {
  if (value == null || value <= 0) return null;
  return _FieldData(label: label, value: value.toString(), icon: icon);
}

_FieldData? _dateField(String label, DateTime? value, IconData icon) {
  if (value == null) return null;
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final formatted = '$day/$month/${value.year}';
  return _FieldData(label: label, value: formatted, icon: icon);
}

_FieldData? _boolField(
  String label,
  bool? value,
  IconData icon, {
  required String trueLabel,
  required String falseLabel,
}) {
  if (value == null) return null;
  return _FieldData(
    label: label,
    value: value ? trueLabel : falseLabel,
    icon: icon,
  );
}

_FieldData? _listField(String label, List<String>? values, IconData icon) {
  final cleaned = (values ?? const <String>[])
      .where((item) => item.trim().isNotEmpty)
      .map(_pretty)
      .toList();
  if (cleaned.isEmpty) return null;
  return _FieldData(label: label, value: cleaned.join(', '), icon: icon);
}

String? _photoUploadLabel(UserModel user) {
  final uploadedCount = (user.photos ?? const <PhotoModel>[])
      .where((photo) => photo.url.trim().isNotEmpty)
      .length;
  if (uploadedCount <= 0) return null;
  return '$uploadedCount uploaded';
}

String? _locationPermissionLabel(ProfileModel? profile) {
  final latitude = profile?.latitude;
  final longitude = profile?.longitude;
  final hasLocation =
      latitude != null &&
      longitude != null &&
      (latitude != 0 || longitude != 0);
  return hasLocation ? 'Enabled' : 'Not shared';
}

String? _preferredDistanceLabel(
  double? profilePreferredKm,
  double? fallbackKm,
  bool useKm,
) {
  final raw = profilePreferredKm ?? fallbackKm;
  if (raw == null || raw <= 0) return null;
  if (useKm) {
    return '${raw.round()} km';
  }
  final miles = raw * 0.621371;
  return '${miles.round()} mi';
}

String _resolvedDisplayName(UserModel user) {
  final first = _namePart(user.firstName);
  final last = _namePart(user.lastName);

  if (first.isNotEmpty && last.isNotEmpty) {
    final firstLower = first.toLowerCase();
    final lastLower = last.toLowerCase();

    if (firstLower == lastLower || firstLower.endsWith(' $lastLower')) {
      return first;
    }
    if (lastLower.startsWith('$firstLower ')) {
      return last;
    }
    return '$first $last';
  }

  if (first.isNotEmpty) return first;
  if (last.isNotEmpty) return last;

  final fallback = user.publicDisplayName.trim().replaceFirst('@', '');
  if (fallback.isNotEmpty) {
    return fallback;
  }

  return 'profile'.tr;
}

String _namePart(String? raw) {
  return (raw ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _genderLabel(String? gender) {
  final value = (gender ?? '').trim().toLowerCase();
  if (value.isEmpty) return 'not_shared'.tr;
  if (value == 'male' || value == 'man') return 'male'.tr;
  if (value == 'female' || value == 'woman') return 'female'.tr;
  return _pretty(value);
}

IconData _genderIcon(String? gender) {
  final value = (gender ?? '').trim().toLowerCase();
  if (value == 'female' || value == 'woman') return LucideIcons.user2;
  if (value == 'male' || value == 'man') return LucideIcons.user;
  return LucideIcons.badgeHelp;
}

String _normalizeCountryAlias(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';

  final normalized = trimmed.toLowerCase();
  switch (normalized) {
    case 'uae':
      return 'United Arab Emirates';
    case 'uk':
      return 'United Kingdom';
    case 'usa':
      return 'United States';
    default:
      return trimmed;
  }
}

String? _countryLabelWithFlag(String? countryRaw) {
  final normalized = _normalizeCountryAlias((countryRaw ?? '').trim());
  if (normalized.isEmpty) return null;

  final country = Country.tryParse(normalized);
  if (country == null) {
    return _pretty(normalized);
  }

  return '${country.flagEmoji} ${country.name}';
}

String? _countryListWithFlags(List<String>? countries) {
  final seen = <String>{};
  final labels = <String>[];

  for (final raw in countries ?? const <String>[]) {
    final label = _countryLabelWithFlag(raw)?.trim();
    if (label == null || label.isEmpty) continue;
    if (seen.add(label.toLowerCase())) {
      labels.add(label);
    }
  }

  if (labels.isEmpty) return null;
  return labels.join(', ');
}

String _locationLabel(ProfileModel? profile, {bool includeFlag = false}) {
  final city = profile?.city?.trim() ?? '';
  final countryRaw = profile?.country?.trim() ?? '';
  final country = includeFlag
      ? (_countryLabelWithFlag(countryRaw) ?? _pretty(countryRaw))
      : countryRaw;
  final location = [city, country].where((part) => part.isNotEmpty).join(', ');
  return location.isNotEmpty ? location : 'location_hidden'.tr;
}

List<String> _collectProfilePhotoUrls(UserModel user) {
  final seen = <String>{};
  final urls = <String>[];

  void add(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return;
    if (seen.add(value)) {
      urls.add(value);
    }
  }

  add(user.mainPhotoUrl);
  add(user.fallbackPhotoUrl);
  for (final photo in user.photos ?? const <PhotoModel>[]) {
    if (photo.isLocked) continue;
    add(photo.url);
  }

  return urls;
}

Color _fieldIconColor(IconData icon) {
  const palette = <Color>[
    Color(0xFF6E3DFB),
    Color(0xFFFF5AA6),
    Color(0xFF45B7FF),
    Color(0xFF8B5CF6),
    Color(0xFF31C48D),
  ];
  return palette[icon.codePoint % palette.length];
}

String _fieldEmoji(IconData icon) {
  if (icon == LucideIcons.bookOpen) return '📖';
  if (icon == LucideIcons.sparkles) return '✨';
  if (icon == LucideIcons.sunrise) return '🌅';
  if (icon == LucideIcons.shirt) return '🧕';
  if (icon == LucideIcons.users) return '👪';
  if (icon == LucideIcons.baby) return '👶';
  if (icon == LucideIcons.listOrdered) return '🔢';
  if (icon == LucideIcons.home) return '🏠';
  if (icon == LucideIcons.messageCircle) return '💬';
  if (icon == LucideIcons.utensils) return '🍽️';
  if (icon == LucideIcons.cupSoda) return '🥤';
  if (icon == LucideIcons.dumbbell) return '🏋️';
  if (icon == LucideIcons.moonStar) return '🌙';
  if (icon == LucideIcons.smartphone) return '📱';
  if (icon == LucideIcons.dog) return '🐾';
  if (icon == LucideIcons.shieldCheck) return '🛡️';
  if (icon == LucideIcons.droplets) return '🩸';
  if (icon == LucideIcons.heartPulse) return '❤️';
  if (icon == LucideIcons.music4) return '🎵';
  if (icon == LucideIcons.film) return '🎬';
  return '✨';
}

String _emojiizedChipValue(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.contains('travel')) return '✈️ ${_pretty(raw)}';
  if (normalized.contains('cook')) return '🍳 ${_pretty(raw)}';
  if (normalized.contains('hiking')) return '🥾 ${_pretty(raw)}';
  if (normalized.contains('yoga') || normalized.contains('meditation')) {
    return '🧘 ${_pretty(raw)}';
  }
  if (normalized.contains('movie') || normalized.contains('film')) {
    return '🎬 ${_pretty(raw)}';
  }
  if (normalized.contains('music')) return '🎵 ${_pretty(raw)}';
  if (normalized.contains('book') || normalized.contains('read')) {
    return '📚 ${_pretty(raw)}';
  }
  if (normalized.contains('dance')) return '💃 ${_pretty(raw)}';
  if (normalized.contains('sport') || normalized.contains('fitness')) {
    return '🏃 ${_pretty(raw)}';
  }
  if (normalized.contains('tech')) return '💻 ${_pretty(raw)}';
  if (normalized.contains('arabic') ||
      normalized.contains('english') ||
      normalized.contains('french') ||
      normalized.contains('language')) {
    return '🗣️ ${_pretty(raw)}';
  }
  return '✨ ${_pretty(raw)}';
}

String? _relationshipGoal(ProfileModel? profile) {
  final raw = (profile?.intentMode ?? profile?.marriageIntention ?? '').trim();
  if (raw.isEmpty) return null;
  switch (raw) {
    case 'serious_marriage':
      return 'serious_marriage'.tr;
    case 'family_introduction':
      return 'family_introduction'.tr;
    case 'exploring':
      return 'getting_to_know'.tr;
    case 'within_months':
      return 'marriage_soon'.tr;
    case 'within_year':
      return 'within_year'.tr;
    case 'one_to_two_years':
      return 'one_to_two_years'.tr;
    case 'not_sure':
      return 'not_sure_yet'.tr;
    default:
      return _pretty(raw);
  }
}

String? _marriageTimelineLabel(ProfileModel? profile) {
  final raw = (profile?.marriageIntention ?? '').trim();
  if (raw.isEmpty) return null;
  switch (raw) {
    case 'within_months':
      return '3-6 months';
    case 'within_year':
      return 'Within 1 year';
    case 'one_to_two_years':
      return '1-2 years';
    case 'not_sure':
      return 'Not sure yet';
    case 'just_exploring':
      return 'Just exploring';
    default:
      return _pretty(raw);
  }
}

String _normalizeBackgroundStatus(String? rawStatus) {
  final status = (rawStatus ?? '').trim().toLowerCase();
  switch (status) {
    case 'approved':
    case 'clear':
    case 'cleared':
    case 'passed':
    case 'verified':
      return 'verified';
    case 'pending':
    case 'processing':
    case 'submitted':
    case 'in_review':
    case 'in-review':
    case 'in_progress':
    case 'under_review':
      return 'in_review';
    case 'declined':
    case 'rejected':
    case 'denied':
      return 'rejected';
    case 'failed':
    case 'error':
      return 'failed';
    case '':
    case 'not_started':
    case 'not-started':
    case 'none':
      return 'not_started';
    default:
      return status;
  }
}

String _backgroundCheckStatusLabel(String? rawStatus) {
  switch (_normalizeBackgroundStatus(rawStatus)) {
    case 'verified':
      return 'background_status_verified'.tr;
    case 'in_review':
      return 'background_status_in_review'.tr;
    case 'rejected':
      return 'background_status_rejected'.tr;
    case 'failed':
      return 'background_status_failed'.tr;
    case 'not_started':
      return 'background_status_not_started'.tr;
    default:
      return 'background_check'.tr;
  }
}

String _pretty(String value) {
  return value
      .trim()
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
