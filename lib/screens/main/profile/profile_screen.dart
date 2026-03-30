import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:methna_app/app/controllers/profile_controller.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/utils/cloudinary_url.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D14) : const Color(0xFFF8F7FC);

    return Scaffold(
      backgroundColor: bgColor,
      body: Obx(() {
        final user = controller.user.value;
        if (user == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48, height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Loading profile...', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshProfile,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              _buildPhotoHeader(user, isDark, context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: Column(
                    children: [
                      // Name Card with completion ring
                      _buildNameCard(user, isDark),
                      const SizedBox(height: 20),

                      // Action Buttons Row
                      _buildActionRow(isDark),
                      const SizedBox(height: 24),

                      // Completion Progress
                      _buildCompletionBar(isDark),
                      const SizedBox(height: 28),

                      // Bio
                      if (user.profile?.bio?.isNotEmpty ?? false) ...[
                        _buildBioCard(user, isDark),
                        const SizedBox(height: 20),
                      ],

                      // About Me Section
                      _buildAboutSection(user, isDark),
                      const SizedBox(height: 20),

                      // Interests
                      if (user.profile?.interests?.isNotEmpty ?? false) ...[
                        _buildInterestsCard(user.profile!.interests!, isDark),
                        const SizedBox(height: 20),
                      ],

                      // Languages
                      if (user.profile?.languages?.isNotEmpty ?? false) ...[
                        _buildLanguagesCard(user.profile!.languages!, isDark),
                        const SizedBox(height: 20),
                      ],

                      // About Partner
                      if (user.profile?.aboutPartner?.isNotEmpty ?? false) ...[
                        _buildPartnerCard(user.profile!.aboutPartner!, isDark),
                        const SizedBox(height: 20),
                      ],

                      // Verification
                      _buildVerificationCard(user, isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ─── Photo Header with gallery dots ──────────────────────────
  Widget _buildPhotoHeader(UserModel user, bool isDark, BuildContext context) {
    final photos = user.photos ?? [];
    final hasPhotos = photos.isNotEmpty;

    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.height * 0.52,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? const Color(0xFF0D0D14) : Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Get.back(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ),
      actions: [
        _glassAction(LucideIcons.edit3, () => controller.openEditProfile()),
        _glassAction(LucideIcons.settings, () => controller.openSettings()),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhotos)
              _PhotoGallery(photos: photos)
            else if (user.mainPhotoUrl != null)
              CachedNetworkImage(
                imageUrl: CloudinaryUrl.large(user.mainPhotoUrl),
                fit: BoxFit.cover,
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE8396B), Color(0xFFFF6B9D), Color(0xFFFF9A76)],
                  ),
                ),
                child: Center(
                  child: Text(
                    Helpers.getInitials(user.firstName ?? '', user.lastName ?? ''),
                    style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
            // Bottom name overlay
            Positioned(
              bottom: 20,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${user.displayName}, ${user.profile?.age ?? ''}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      if (user.selfieVerified) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.emerald.withValues(alpha: 0.5)),
                          ),
                          child: const Icon(LucideIcons.badgeCheck, color: AppColors.emerald, size: 16),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        '${user.profile?.city ?? ''}, ${user.profile?.country ?? ''}'.trim().replaceAll(RegExp(r'^,\s*|,\s*$'), ''),
                        style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassAction(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Name Card with completion ring ──────────────────────────
  Widget _buildNameCard(UserModel user, bool isDark) {
    final completion = controller.profileCompletion;
    final score = controller.barakaScore;

    return Transform.translate(
      offset: const Offset(0, -32),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            // Completion ring
            SizedBox(
              width: 64, height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 64, height: 64,
                    child: CircularProgressIndicator(
                      value: completion / 100,
                      strokeWidth: 4,
                      backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                      color: completion >= 80 ? AppColors.emerald : AppColors.primary,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '$completion%',
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    completion >= 80 ? 'Profile Complete!' : 'Complete Your Profile',
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    completion >= 80
                        ? 'You\'re all set to find your match'
                        : '${100 - completion}% more to get noticed',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black45),
                  ),
                ],
              ),
            ),
            // Baraka badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  score >= 75 ? AppColors.emerald : (score >= 45 ? AppColors.gold : AppColors.primary),
                  (score >= 75 ? AppColors.emerald : (score >= 45 ? AppColors.gold : AppColors.primary)).withValues(alpha: 0.7),
                ]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(LucideIcons.sparkles, color: Colors.white, size: 14),
                  const SizedBox(height: 2),
                  Text('$score', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0),
    );
  }

  // ─── Action Buttons ──────────────────────────────────────────
  Widget _buildActionRow(bool isDark) {
    return Transform.translate(
      offset: const Offset(0, -16),
      child: Row(
        children: [
          _actionBtn(LucideIcons.camera, 'Photos', AppColors.primary, () => controller.openEditPhotos(), isDark),
          const SizedBox(width: 12),
          _actionBtn(LucideIcons.edit3, 'Edit', const Color(0xFF6C63FF), () => controller.openEditProfile(), isDark),
          const SizedBox(width: 12),
          _actionBtn(LucideIcons.settings, 'Settings', AppColors.gold, () => controller.openSettings(), isDark),
        ],
      ).animate().fadeIn(delay: 100.ms, duration: 350.ms),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? color.withValues(alpha: 0.12) : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Completion Bar ──────────────────────────────────────────
  Widget _buildCompletionBar(bool isDark) {
    final completion = controller.profileCompletion;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [Colors.white, const Color(0xFFF5F3FF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Profile Strength', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : Colors.black54)),
              Text('$completion%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: completion >= 80 ? AppColors.emerald : AppColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: completion / 100,
              minHeight: 6,
              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
              color: completion >= 80 ? AppColors.emerald : AppColors.primary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 350.ms);
  }

  // ─── Bio Card ────────────────────────────────────────────────
  Widget _buildBioCard(UserModel user, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
              : [Colors.white, const Color(0xFFFFF5F7)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.quote, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text('About Me', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            user.profile?.bio ?? '',
            style: TextStyle(fontSize: 15, height: 1.7, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  // ─── About Section ───────────────────────────────────────────
  Widget _buildAboutSection(UserModel user, bool isDark) {
    final p = user.profile;
    String fmt(String? v) => v == null ? '' : v.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');

    final sections = <_SectionData>[
      _SectionData('Basic Info', LucideIcons.user, const Color(0xFF6C63FF), [
        _DetailItem(label: 'Gender', value: fmt(p?.gender), icon: LucideIcons.user),
        _DetailItem(label: 'Age', value: p?.age != null ? '${p!.age} yrs' : null, icon: LucideIcons.cake),
        _DetailItem(label: 'Status', value: fmt(p?.maritalStatus), icon: LucideIcons.heart),
        _DetailItem(label: 'Height', value: p?.height != null ? '${p!.height} cm' : null, icon: LucideIcons.ruler),
        _DetailItem(label: 'Weight', value: p?.weight != null ? '${p!.weight} kg' : null, icon: LucideIcons.ruler),
        _DetailItem(label: 'Nationality', value: fmt(p?.nationality), icon: LucideIcons.globe),
        _DetailItem(label: 'City', value: p?.city, icon: LucideIcons.mapPin),
        _DetailItem(label: 'Country', value: p?.country, icon: LucideIcons.map),
      ]),
      _SectionData('Faith & Practice', LucideIcons.sparkles, const Color(0xFFE8396B), [
        _DetailItem(label: 'Sect', value: fmt(p?.sect), icon: LucideIcons.shield),
        _DetailItem(label: 'Religious Level', value: fmt(p?.religiousLevel), icon: LucideIcons.sparkles),
        _DetailItem(label: 'Prayer', value: fmt(p?.prayerFrequency), icon: LucideIcons.sunrise),
        _DetailItem(label: 'Hijab', value: fmt(p?.hijabStatus), icon: LucideIcons.shirt),
        _DetailItem(label: 'Dietary', value: fmt(p?.dietary), icon: LucideIcons.coffee),
        _DetailItem(label: 'Alcohol', value: fmt(p?.alcohol), icon: LucideIcons.coffee),
      ]),
      _SectionData('Career & Education', LucideIcons.briefcase, const Color(0xFF00B4D8), [
        _DetailItem(label: 'Education', value: fmt(p?.education), icon: LucideIcons.graduationCap),
        _DetailItem(label: 'Job Title', value: p?.jobTitle, icon: LucideIcons.briefcase),
        _DetailItem(label: 'Company', value: p?.company, icon: LucideIcons.building),
      ]),
      _SectionData('Family & Marriage', LucideIcons.heartHandshake, AppColors.emerald, [
        _DetailItem(label: 'Looking For', value: fmt(p?.marriageIntention), icon: LucideIcons.search),
        _DetailItem(label: 'Family Plans', value: fmt(p?.familyPlans), icon: LucideIcons.heart),
        _DetailItem(label: 'Has Children', value: p?.hasChildren == true ? 'Yes (${p?.numberOfChildren ?? '?'})' : (p?.hasChildren == false ? 'No' : null), icon: LucideIcons.users),
        _DetailItem(label: 'Wants Children', value: p?.wantsChildren == true ? 'Yes' : (p?.wantsChildren == false ? 'No' : null), icon: LucideIcons.heartHandshake),
        _DetailItem(label: 'Willing to Relocate', value: p?.willingToRelocate == true ? 'Yes' : (p?.willingToRelocate == false ? 'No' : null), icon: LucideIcons.navigation),
      ]),
      _SectionData('Lifestyle', LucideIcons.coffee, AppColors.gold, [
        _DetailItem(label: 'Living', value: fmt(p?.livingSituation), icon: LucideIcons.home),
        _DetailItem(label: 'Workout', value: fmt(p?.workoutFrequency), icon: LucideIcons.activity),
        _DetailItem(label: 'Communication', value: fmt(p?.communicationStyle), icon: LucideIcons.messageCircle),
        _DetailItem(label: 'Sleep', value: fmt(p?.sleepSchedule), icon: LucideIcons.moon),
        _DetailItem(label: 'Social Media', value: fmt(p?.socialMediaUsage), icon: LucideIcons.smartphone),
      ]),
    ];

    return Column(
      children: sections.asMap().entries.map((entry) {
        final idx = entry.key;
        final section = entry.value;
        final items = section.items.where((i) => i.value != null && i.value!.isNotEmpty).toList();
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildSectionCard(section.title, section.icon, section.color, items, isDark)
              .animate().fadeIn(delay: (200 + idx * 60).ms, duration: 400.ms).slideY(begin: 0.06, end: 0),
        );
      }).toList(),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Color accent, List<_DetailItem> items, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: items.map((item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? accent.withValues(alpha: 0.08) : accent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, size: 13, color: accent.withValues(alpha: 0.7)),
                  const SizedBox(width: 6),
                  Text(
                    '${item.label}: ',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
                  ),
                  Flexible(
                    child: Text(
                      item.value!,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Interests Card ──────────────────────────────────────────
  Widget _buildInterestsCard(List<String> interests, bool isDark) {
    final colors = [
      const Color(0xFFE8396B), const Color(0xFF6C63FF), const Color(0xFF00B4D8),
      AppColors.emerald, AppColors.gold, const Color(0xFFFF6B9D),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(LucideIcons.heart, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text('Interests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interests.asMap().entries.map((entry) {
              final color = colors[entry.key % colors.length];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.06)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Text(
                  entry.value.tr,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  // ─── Languages Card ──────────────────────────────────────────
  Widget _buildLanguagesCard(List<String> languages, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF00B4D8).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(LucideIcons.globe, size: 16, color: Color(0xFF00B4D8)),
              ),
              const SizedBox(width: 10),
              Text('Languages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: languages.map((lang) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF00B4D8).withValues(alpha: 0.1) : const Color(0xFF00B4D8).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00B4D8).withValues(alpha: 0.15)),
              ),
              child: Text(lang, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF00B4D8))),
            )).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 330.ms, duration: 400.ms);
  }

  // ─── Partner Card ────────────────────────────────────────────
  Widget _buildPartnerCard(String aboutPartner, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF1A2E1A)]
              : [Colors.white, const Color(0xFFF0FFF4)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.emerald.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(LucideIcons.heartHandshake, size: 16, color: AppColors.emerald),
              ),
              const SizedBox(width: 10),
              Text('About My Partner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          const SizedBox(height: 14),
          Text(aboutPartner, style: TextStyle(fontSize: 15, height: 1.7, color: isDark ? Colors.white70 : Colors.black54)),
        ],
      ),
    ).animate().fadeIn(delay: 360.ms, duration: 400.ms);
  }

  // ─── Verification Card ───────────────────────────────────────
  Widget _buildVerificationCard(UserModel user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1A2E), const Color(0xFF0A2A1A)]
              : [Colors.white, const Color(0xFFF0FFF4)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.emerald.withValues(alpha: 0.2), AppColors.emerald.withValues(alpha: 0.1)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.shieldCheck, color: AppColors.emerald, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          const SizedBox(height: 16),
          _verifyRow('Email', user.email, user.emailVerified, LucideIcons.mail, isDark),
          const SizedBox(height: 12),
          _verifyRow('Selfie', user.selfieVerified ? 'Verified' : 'Pending', user.selfieVerified, LucideIcons.camera, isDark),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }

  Widget _verifyRow(String label, String value, bool isOk, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (isOk ? AppColors.emerald : Colors.orange).withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? Colors.white38 : Colors.black38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white38 : Colors.black38)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
          ),
          Icon(isOk ? LucideIcons.checkCircle2 : LucideIcons.clock, color: isOk ? AppColors.emerald : Colors.orange, size: 20),
        ],
      ),
    );
  }
}

// ─── Photo Gallery Widget ──────────────────────────────────────
class _PhotoGallery extends StatefulWidget {
  final List<PhotoModel> photos;
  const _PhotoGallery({required this.photos});

  @override
  State<_PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<_PhotoGallery> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: widget.photos.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (context, index) {
            final photo = widget.photos[index];
            return CachedNetworkImage(
              imageUrl: CloudinaryUrl.large(photo.url),
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey.shade900),
            );
          },
        ),
        // Page indicators
        if (widget.photos.length > 1)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: List.generate(widget.photos.length, (i) => Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i == _currentPage ? Colors.white : Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )),
            ),
          ),
      ],
    );
  }
}

// ─── Data Models ───────────────────────────────────────────────
class _DetailItem {
  final String label;
  final String? value;
  final IconData icon;
  _DetailItem({required this.label, this.value, required this.icon});
}

class _SectionData {
  final String title;
  final IconData icon;
  final Color color;
  final List<_DetailItem> items;
  _SectionData(this.title, this.icon, this.color, this.items);
}
