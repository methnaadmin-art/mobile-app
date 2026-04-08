import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/profile_controller.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/data/services/verification_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/constants/app_constants.dart';
import 'package:methna_app/core/utils/cloudinary_url.dart';
import 'package:methna_app/core/utils/google_fonts_stub.dart';
import 'package:methna_app/core/utils/helpers.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final user = controller.user.value;
          if (user == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: controller.refreshProfile,
            child: ProfileShowcaseContent(
              user: user,
              isOwnProfile: true,
              completion: controller.profileCompletion,
              onUpgrade: () => Get.toNamed(AppRoutes.subscription),
              onSettings: controller.openSettings,
              onEdit: controller.openEditProfile,
              onPhotoTap: controller.openEditPhotos,
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
    this.onSettings,
    this.onEdit,
    this.onPhotoTap,
    this.onBack,
    this.onMore,
    this.extraBottomPadding = 120,
  });

  final UserModel user;
  final bool isOwnProfile;
  final int? completion;
  final VoidCallback? onUpgrade;
  final VoidCallback? onSettings;
  final VoidCallback? onEdit;
  final VoidCallback? onPhotoTap;
  final VoidCallback? onBack;
  final VoidCallback? onMore;
  final double extraBottomPadding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = user.profile;
    final sections = [
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
      _section('family_home'.tr, [
        _field('marital_status'.tr, profile?.maritalStatus, LucideIcons.heart),
        _field('family_plans'.tr, profile?.familyPlans, LucideIcons.baby),
        _boolField(
          'children'.tr,
          profile?.hasChildren,
          LucideIcons.users,
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
          LucideIcons.locate,
          trueLabel: 'yes'.tr,
          falseLabel: 'no'.tr,
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
          LucideIcons.messagesSquare,
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
      _section('my_details'.tr, [
        _field(
          'gender'.tr,
          (profile?.gender ?? '').trim().isNotEmpty
              ? _genderLabel(profile?.gender)
              : null,
          _genderIcon(profile?.gender),
          prettify: false,
        ),
        _numberField('age'.tr, profile?.age, LucideIcons.calendarDays),
        _field('nationality'.tr, profile?.nationality, LucideIcons.flag),
        _listField(
          'nationalities'.tr,
          profile?.nationalities,
          LucideIcons.flag,
        ),
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
                ? _OwnProfileBar(onUpgrade: onUpgrade, onSettings: onSettings)
                : _PublicProfileBar(onBack: onBack, onMore: onMore),
            if (isOwnProfile && completion != null) ...[
              const SizedBox(height: 12),
              _CompletionBanner(completion: completion!, onTap: onEdit),
            ],
            if (isOwnProfile) ...[
              const SizedBox(height: 12),
              const _IdentityVerificationCard(),
            ],
            const SizedBox(height: 14),
            _HeroCard(user: user, onTap: onPhotoTap),
            const SizedBox(height: 14),
            Text(
              _displayName(user),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF232129),
                letterSpacing: -0.25,
              ),
            ),
            const SizedBox(height: 8),
            _MetaRow(
              icon: _genderIcon(profile?.gender),
              text: _genderLabel(profile?.gender),
            ),
            const SizedBox(height: 6),
            _MetaRow(icon: LucideIcons.mapPin, text: _locationLabel(profile)),
            if (user.selfieVerified) ...[
              const SizedBox(height: 6),
              _MetaRow(
                icon: LucideIcons.badgeCheck,
                text: 'verified_profile'.tr,
                iconColor: const Color(0xFF8E2CFF),
              ),
            ],
            if (_normalizeBackgroundStatus(user.backgroundCheckStatus) !=
                'not_started') ...[
              const SizedBox(height: 6),
              _MetaRow(
                icon: LucideIcons.shieldCheck,
                text: _backgroundCheckStatusLabel(user.backgroundCheckStatus),
                iconColor: _backgroundCheckStatusColor(
                  user.backgroundCheckStatus,
                ),
              ),
            ],
            if ((profile?.bio ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _TextCard(title: 'about_me'.tr, text: profile!.bio!.trim()),
            ],
            if ((profile?.interests ?? const <String>[]).isNotEmpty) ...[
              const SizedBox(height: 16),
              _ChipCard(title: 'interests'.tr, values: profile!.interests!),
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
              ),
            ],
            if ((profile?.travelPreferences ?? const <String>[])
                .isNotEmpty) ...[
              const SizedBox(height: 16),
              _ChipCard(
                title: 'travel_preferences'.tr,
                values: profile!.travelPreferences!,
              ),
            ],
            for (final section in sections) ...[
              const SizedBox(height: 16),
              _SectionCard(section: section),
            ],
            if ((profile?.aboutPartner ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _TextCard(
                title: 'partner_preferences'.tr,
                text: profile!.aboutPartner!.trim(),
              ),
            ],
          ],
        ),
        if (isOwnProfile && onEdit != null)
          Positioned(right: 14, bottom: 98, child: _EditButton(onTap: onEdit!)),
      ],
    );
  }
}

class _OwnProfileBar extends StatelessWidget {
  const _OwnProfileBar({this.onUpgrade, this.onSettings});

  final VoidCallback? onUpgrade;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ClipOval(
              child: Image.asset(
                AppConstants.appLogoAsset,
                width: 18,
                height: 18,
                fit: BoxFit.cover,
              ),
            ),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onUpgrade != null) _UpgradePill(onTap: onUpgrade!),
                if (onUpgrade != null) const SizedBox(width: 8),
                _CircleTopIcon(icon: LucideIcons.settings2, onTap: onSettings),
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
          height: 20,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFA020F9), Color(0xFF7C1EFF)],
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
                  fontSize: 8.5,
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

class _CircleTopIcon extends StatelessWidget {
  const _CircleTopIcon({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 22,
          height: 22,
          child: Icon(
            icon,
            size: 15,
            color: isDark
                ? AppColors.textSecondaryDark
                : const Color(0xFF6F697B),
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : const Color(0xFFF7F6FB),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFECE7F6),
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF4F475B),
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
              colors: [Color(0xFFA020F9), Color(0xFF7C1EFF)],
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
        return const Color(0xFF8E2CFF);
      case 'reverify_required':
        return const Color(0xFFD9485F);
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

  String _buttonLabel(String value) {
    switch (value) {
      case 'verified':
        return 'view_identity_status'.tr;
      case 'pending_review':
        return 'replace_document'.tr;
      case 'reverify_required':
        return 'reupload_identity'.tr;
      default:
        return 'verify_identity'.tr;
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
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withValues(alpha: 0.18)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A1C0D37),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
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
                        _title(status),
                        style: GoogleFonts.poppins(
                          fontSize: 12.8,
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
                          fontSize: 10.6,
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
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _buttonLabel(status),
                        style: GoogleFonts.poppins(
                          fontSize: 9,
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.user, this.onTap});
  final UserModel user;
  final VoidCallback? onTap;

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

      final secureUri = parsed.scheme.toLowerCase() == 'http' &&
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
      ...(user.photos ?? const <PhotoModel>[]).map((photo) => photo.url),
    ];

    for (final candidate in candidates) {
      final normalized = _normalizePhotoUrl(candidate);
      if (normalized.isEmpty) continue;

      final uri = Uri.tryParse(normalized);
      if (uri != null &&
          (uri.scheme.toLowerCase() == 'http' ||
              uri.scheme.toLowerCase() == 'https') &&
          uri.host.isNotEmpty) {
        if (seen.add(normalized)) {
          results.add(normalized);
        }
        final transformed = CloudinaryUrl.large(normalized);
        if (transformed.isNotEmpty && seen.add(transformed)) {
          results.add(transformed);
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
              ? [const Color(0xFF1B1730), const Color(0xFF241D3F)]
              : [const Color(0xFFF7ECFF), const Color(0xFFEAE4FF)],
        ),
      ),
      child: Center(
        child: Text(
          Helpers.getInitials(user.firstName, user.lastName),
          style: GoogleFonts.poppins(
            fontSize: 52,
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

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 0.76,
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageUrls.isEmpty
                  ? _fallback(isDark)
                  : _ResilientHeroImage(
                      urls: imageUrls,
                      fallback: _fallback(isDark),
                    ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x05000000), Color(0x16000000)],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 24,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
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

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.text,
    this.iconColor = const Color(0xFF5F5A68),
  });
  final IconData icon;
  final String text;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11.8,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : const Color(0xFF5F5A68),
            ),
          ),
        ),
      ],
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
  const _ChipCard({required this.title, required this.values});
  final String title;
  final List<String> values;

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
                      _pretty(item),
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
            _SectionRow(field: section.fields[i]),
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
  const _SectionRow({required this.field});
  final _FieldData field;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : const Color(0xFFF7F5FB),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(field.icon, size: 14, color: const Color(0xFF8E2CFF)),
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
                      : const Color(0xFF8B8496),
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

class _EditButton extends StatelessWidget {
  const _EditButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFA020F9), Color(0xFF7C1EFF)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x332B0B5C),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(LucideIcons.pencil, color: Colors.white, size: 18),
        ),
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
  const _SectionData({required this.title, required this.fields});
  final String title;
  final List<_FieldData> fields;
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

_SectionData? _section(String title, List<_FieldData?> fields) {
  final cleaned = fields.whereType<_FieldData>().toList();
  if (cleaned.isEmpty) return null;
  return _SectionData(title: title, fields: cleaned);
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

String _displayName(UserModel user) {
  final name = user.fullName.trim().isNotEmpty
      ? user.fullName.trim()
      : (user.displayName.trim().isNotEmpty
            ? user.displayName.trim()
            : 'profile'.tr);
  final age = user.profile?.showAge == false ? null : user.profile?.age;
  return age != null && age > 0 ? '$name (${age.toString()})' : name;
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

String _locationLabel(ProfileModel? profile) {
  final city = profile?.city?.trim() ?? '';
  final country = profile?.country?.trim() ?? '';
  final location = [city, country].where((part) => part.isNotEmpty).join(', ');
  return location.isNotEmpty ? location : 'location_hidden'.tr;
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

Color _backgroundCheckStatusColor(String? rawStatus) {
  switch (_normalizeBackgroundStatus(rawStatus)) {
    case 'verified':
      return const Color(0xFF12805C);
    case 'in_review':
      return AppColors.warning;
    case 'rejected':
    case 'failed':
      return AppColors.error;
    default:
      return const Color(0xFF5F5A68);
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
