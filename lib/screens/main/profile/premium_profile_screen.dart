import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/core/widgets/datify_shell.dart';
import '../../../app/controllers/profile_controller.dart';
import '../../../app/data/models/user_model.dart';
import '../../../core/theme/premium_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/cloudinary_url.dart';

/// Premium Profile Screen with Parallax Scroll
class PremiumProfileScreen extends GetView<ProfileController> {
  const PremiumProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: DatifyBackground(
        compact: true,
        child: Obx(() {
          final user = controller.user.value;
          if (user == null) {
            return const _LoadingState();
          }

          final displayName = user.publicDisplayName.trim().isNotEmpty
              ? user.publicDisplayName.trim()
              : 'profile'.tr;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Parallax Photo Header
              _ParallaxPhotoHeader(user: user, displayName: displayName),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: Column(
                    children: [
                      // Name & Stats Card
                      _NameStatsCard(user: user, controller: controller),
                      const SizedBox(height: 20),

                      // Action Buttons
                      _ActionButtons(controller: controller),
                      const SizedBox(height: 24),

                      // About Section (Glass Card)
                      if (user.profile?.bio?.isNotEmpty ?? false)
                        _GlassSectionCard(
                          icon: LucideIcons.quote,
                          title: 'about_me'.tr,
                          content: user.profile!.bio!,
                        ),
                      const SizedBox(height: 16),

                      // Faith & Religion
                      _FaithSection(user: user),
                      const SizedBox(height: 16),

                      // Interests
                      if (user.profile?.interests?.isNotEmpty ?? false)
                        _InterestsSection(interests: user.profile!.interests!),
                      const SizedBox(height: 16),

                      // Personal Details
                      _DetailsSection(user: user),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ParallaxPhotoHeader extends StatelessWidget {
  final UserModel user;
  final String displayName;

  const _ParallaxPhotoHeader({
    required this.user,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.height * 0.55,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.background,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(12),
        child: _GlassIconButton(
          icon: LucideIcons.chevronLeft,
          onTap: () => Get.back(),
        ),
      ),
      actions: [
        _GlassIconButton(icon: LucideIcons.settings2, onTap: () {}),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Photo
            user.mainPhotoUrl != null
                ? CachedNetworkImage(
                    imageUrl: CloudinaryUrl.large(user.mainPhotoUrl),
                    fit: BoxFit.cover,
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.emeraldGradient,
                    ),
                    child: Center(
                      child: Text(
                        Helpers.getInitials(
                          user.firstName ?? '',
                          user.lastName ?? '',
                        ),
                        style: const TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    AppTheme.background.withValues(alpha: 0.8),
                    AppTheme.background,
                  ],
                  stops: const [0.0, 0.5, 0.8, 1.0],
                ),
              ),
            ),

            // Bottom Info
            Positioned(
              left: 24,
              right: 24,
              bottom: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '$displayName, ${user.profile?.age ?? ''}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      if (user.selfieVerified) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.success.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.badgeCheck,
                            color: AppTheme.success,
                            size: 20,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        color: AppTheme.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${user.profile?.city ?? ''}, ${user.profile?.country ?? ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameStatsCard extends StatelessWidget {
  final UserModel user;
  final ProfileController controller;

  const _NameStatsCard({required this.user, required this.controller});

  @override
  Widget build(BuildContext context) {
    final completion = controller.profileCompletion;
    final score = controller.barakaScore;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        children: [
          Row(
            children: [
              // Profile Completion Ring
              SizedBox(
                width: 70,
                height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: completion / 100,
                      strokeWidth: 5,
                      backgroundColor: AppTheme.white10,
                      valueColor: AlwaysStoppedAnimation(
                        completion >= 80 ? AppTheme.success : AppTheme.gold,
                      ),
                    ),
                    Text(
                      '$completion%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
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
                      completion >= 80
                          ? 'profile_complete'.tr
                          : 'complete_your_profile'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      completion >= 80
                          ? 'profile_complete_desc'.tr
                          : 'profile_completion_remaining'.trParams({
                              'percent': '${100 - completion}',
                            }),
                      style: const TextStyle(
                        color: AppTheme.white50,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.white10, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                icon: LucideIcons.sparkles,
                value: '$score',
                label: 'match_score'.tr,
                color: AppTheme.gold,
              ),
              Container(width: 1, height: 40, color: AppTheme.white10),
              _StatItem(
                icon: LucideIcons.heart,
                value: '0',
                label: 'matches'.tr,
                color: const Color(0xFF4F26D9),
              ),
              Container(width: 1, height: 40, color: AppTheme.white10),
              _StatItem(
                icon: LucideIcons.eye,
                value: '0',
                label: 'total_views'.tr,
                color: AppTheme.success,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0);
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.white50,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final ProfileController controller;

  const _ActionButtons({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PremiumButton(
            onTap: () => controller.openEditPhotos(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.camera, size: 18),
                const SizedBox(width: 8),
                Text('my_photos'.tr),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PremiumButton(
            onTap: () => controller.openEditProfile(),
            isOutlined: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.edit3, size: 18),
                const SizedBox(width: 8),
                Text('edit_profile'.tr),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _GlassSectionCard({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: AppTheme.gold),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            content,
            style: const TextStyle(
              color: AppTheme.white70,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}

class _FaithSection extends StatelessWidget {
  final UserModel user;

  const _FaithSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final p = user.profile;

    final items = [
      if (p?.sect != null)
        _FaithItem('sect_label'.tr, p!.sect!, LucideIcons.shield),
      if (p?.religiousLevel != null)
        _FaithItem('religious_level'.tr, p!.religiousLevel!, LucideIcons.sparkles),
      if (p?.prayerFrequency != null)
        _FaithItem('prayer_label'.tr, p!.prayerFrequency!, LucideIcons.sunrise),
      if (p?.hijabStatus != null)
        _FaithItem('hijab_label'.tr, p!.hijabStatus!, LucideIcons.shirt),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.moon,
                  size: 18,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'faith_and_religion'.tr,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items.map((item) => _FaithChip(item: item)).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}

class _FaithItem {
  final String label;
  final String value;
  final IconData icon;

  _FaithItem(this.label, this.value, this.icon);
}

class _FaithChip extends StatelessWidget {
  final _FaithItem item;

  const _FaithChip({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 14, color: AppTheme.success),
          const SizedBox(width: 8),
          Text(
            '${item.label}: ',
            style: const TextStyle(color: AppTheme.white50, fontSize: 12),
          ),
          Text(
            item.value.capitalizeFirst!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestsSection extends StatelessWidget {
  final List<String> interests;

  const _InterestsSection({required this.interests});

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppTheme.gold,
      AppTheme.success,
      const Color(0xFF6E3DFB),
      const Color(0xFFA78BFA),
      const Color(0xFF6E3DFB),
    ];

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.heart,
                  size: 18,
                  color: AppTheme.gold,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'interests'.tr,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: interests.asMap().entries.map((entry) {
              final color = colors[entry.key % colors.length];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.15),
                      color.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  entry.value.tr,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}

class _DetailsSection extends StatelessWidget {
  final UserModel user;

  const _DetailsSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final p = user.profile;

    final details = [
      if (p?.education != null)
        _DetailItem('education_label'.tr, p!.education!, LucideIcons.graduationCap),
      if (p?.jobTitle != null)
        _DetailItem('profession_label'.tr, p!.jobTitle!, LucideIcons.briefcase),
      if (p?.maritalStatus != null)
        _DetailItem('marital_status'.tr, p!.maritalStatus!, LucideIcons.heart),
      if (p?.height != null)
        _DetailItem('height_label'.tr, '${p!.height} cm', LucideIcons.ruler),
    ];

    if (details.isEmpty) return const SizedBox.shrink();

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'personal_details_title'.tr,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          ...details.map((detail) => _DetailRow(item: detail)),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}

class _DetailRow extends StatelessWidget {
  final _DetailItem item;

  const _DetailRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 16, color: AppTheme.white70),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(color: AppTheme.white50, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value.capitalizeFirst!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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

class _DetailItem {
  final String label;
  final String value;
  final IconData icon;

  _DetailItem(this.label, this.value, this.icon);
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.white10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppTheme.gold,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading profile...',
            style: TextStyle(color: AppTheme.white50, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
