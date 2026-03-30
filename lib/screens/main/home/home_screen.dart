import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:methna_app/app/controllers/home_controller.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/utils/cloudinary_url.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/core/widgets/islamic_pattern_painter.dart';
import 'package:methna_app/core/widgets/animated_empty_state.dart';
import 'package:methna_app/core/widgets/baraka_meter.dart';
import 'package:methna_app/core/widgets/intent_badge.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: Stack(
        children: [
          // Background Pattern
          Positioned.fill(
            child: IslamicPatternWidget(
              opacity: isDark ? 0.03 : 0.05,
              color: isDark ? Colors.white : AppColors.emerald,
            ),
          ),

          Column(
            children: [
              // 1. App Bar Header
              _buildHeader(context, isDark, topPad),

              // 2. Main Swiper Area
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value && controller.discoverUsers.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.isEmpty.value || controller.discoverUsers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedEmptyState(
                            lottieAsset: 'assets/animations/no_users.json',
                            title: 'all_caught_up'.tr,
                            subtitle: 'expand_filters_desc'.tr,
                            fallbackIcon: LucideIcons.search,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: controller.refreshDiscoverUsers,
                            icon: const Icon(LucideIcons.refreshCw, size: 16),
                            label: Text('refresh'.tr),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: CardSwiper(
                          cardsCount: controller.discoverUsers.length,
                          numberOfCardsDisplayed: controller.discoverUsers.length.clamp(1, 3),
                          backCardOffset: const Offset(0, 40),
                          padding: EdgeInsets.zero,
                          isDisabled: controller.isLoading.value,
                          onSwipe: (previousIndex, currentIndex, direction) {
                            final user = controller.discoverUsers[previousIndex];
                            if (direction == CardSwiperDirection.right) {
                              controller.likeUser(user.id);
                            } else if (direction == CardSwiperDirection.left) {
                              controller.passUser(user.id);
                            } else if (direction == CardSwiperDirection.top) {
                              controller.likeUser(user.id); // Swipe up = like
                            }
                            return true;
                          },
                          onUndo: (previousIndex, currentIndex, direction) {
                            controller.rewindLastSwipe();
                            return true;
                          },
                          cardBuilder: (context, index, horizontalOffsetPercentage, verticalOffsetPercentage) {
                            final user = controller.discoverUsers[index];
                            return _UserSwipeCard(user: user, controller: controller, isDark: isDark);
                          },
                        ),
                      ),

                      // Swipe Actions Bottom Bar
                      Positioned(
                        bottom: 40 + bottomPad,
                        left: 0,
                        right: 0,
                        child: _buildSwipeActions(isDark),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, double topPad) {
    final user = controller.currentUser;
    return Container(
      padding: EdgeInsets.only(top: topPad + 10, left: 20, right: 20, bottom: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: controller.openProfile,
            child: Container(
              width: 44, height: 44,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: ClipOval(
                child: user?.mainPhotoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: CloudinaryUrl.thumbnail(user!.mainPhotoUrl),
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Text(
                          Helpers.getInitials(user?.firstName, user?.lastName),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'salaam'.tr + ', ${user?.firstName ?? 'User'} 👋',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.secondary),
                ),
                Text('discover_matches'.tr, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600)),
              ],
            ),
          ),
          _ActionCircleButton(icon: LucideIcons.sliders, onTap: controller.openFilter, isDark: isDark),
          const SizedBox(width: 10),
          _ActionCircleButton(icon: LucideIcons.bell, onTap: controller.openNotifications, isDark: isDark, hasBadge: true),
        ],
      ),
    );
  }

  Widget _buildSwipeActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SwipeBtn(
            icon: LucideIcons.rotateCcw,
            color: AppColors.gold,
            size: 50,
            onTap: controller.rewindLastSwipe,
            isEnabled: controller.canRewind,
          ),
          _SwipeBtn(
            icon: LucideIcons.x,
            color: Colors.redAccent,
            size: 64,
            onTap: () {
              // Trigger swiper left manually if needed or just call passUser
              if (controller.discoverUsers.isNotEmpty) {
                controller.passUser(controller.discoverUsers[0].id);
              }
            },
          ),
          _SwipeBtn(
            icon: LucideIcons.heart,
            color: AppColors.emerald,
            size: 64,
            onTap: () {
              if (controller.discoverUsers.isNotEmpty) {
                controller.likeUser(controller.discoverUsers[0].id);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _UserSwipeCard extends StatefulWidget {
  final UserModel user;
  final HomeController controller;
  final bool isDark;

  const _UserSwipeCard({required this.user, required this.controller, required this.isDark});

  @override
  State<_UserSwipeCard> createState() => _UserSwipeCardState();
}

class _UserSwipeCardState extends State<_UserSwipeCard> {
  final ScrollController _scrollController = ScrollController();
  final RxInt _currentPhotoIndex = 0.obs;
  
  List<String> get _photos {
    if (widget.user.photos != null && widget.user.photos!.isNotEmpty) {
      return widget.user.photos!.map((p) => p.url).toList();
    }
    return widget.user.mainPhotoUrl != null ? [widget.user.mainPhotoUrl!] : [];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final controller = widget.controller;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: widget.isDark ? AppColors.cardDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Section with indicators
              _buildPhotoSection(user, controller),
              
              // User Details Section
              _buildDetailsSection(user),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPhotoSection(UserModel user, HomeController controller) {
    final screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      height: screenHeight * 0.72,
      child: Stack(
        children: [
          // Photo PageView
          PageView.builder(
            itemCount: _photos.isEmpty ? 1 : _photos.length,
            onPageChanged: (i) => _currentPhotoIndex.value = i,
            itemBuilder: (context, index) {
              if (_photos.isEmpty) {
                return Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Text(
                      Helpers.getInitials(user.firstName, user.lastName),
                      style: TextStyle(fontSize: 80, fontWeight: FontWeight.w900, color: Colors.grey.shade400),
                    ),
                  ),
                );
              }
              return CachedNetworkImage(
                imageUrl: CloudinaryUrl.large(_photos[index]),
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey.shade200),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(LucideIcons.user, size: 60, color: Colors.grey),
                ),
              );
            },
          ),
          
          // Photo Indicators
          if (_photos.length > 1)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Obx(() => Row(
                children: List.generate(_photos.length, (i) => Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i == _currentPhotoIndex.value ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              )),
            ),
          
          // Baraka Meter
          Positioned(
            top: 30,
            left: 16,
            child: Obx(() => BarakaMeter(
              score: controller.getBarakaScore(user.id),
              level: controller.getBarakaLevel(user.id),
            )),
          ),
          
          // Intent Badge
          if (user.profile?.intentMode != null)
            Positioned(
              top: 30,
              right: 16,
              child: IntentBadge(intentMode: user.profile!.intentMode!),
            ),
          
          // Bottom Gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 120,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                ),
              ),
            ),
          ),
          
          // Name & Basic Info overlay
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${user.firstName ?? user.username}, ${user.profile?.age ?? '?'}',
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (user.selfieVerified)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Color(0xFFC69C6D), shape: BoxShape.circle),
                        child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 16),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${user.profile?.city ?? 'Unknown'}${user.profile?.country != null ? ', ${user.profile!.country}' : ''}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
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
  
  Widget _buildDetailsSection(UserModel user) {
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.grey.shade600;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (user.profile?.sect != null) 
                _DetailChip(icon: LucideIcons.moon, label: user.profile!.sect!, isDark: isDark),
              if (user.profile?.maritalStatus != null) 
                _DetailChip(icon: LucideIcons.heart, label: user.profile!.maritalStatus!, isDark: isDark),
              if (user.profile?.education != null) 
                _DetailChip(icon: LucideIcons.graduationCap, label: user.profile!.education!, isDark: isDark),
              if (user.profile?.height != null) 
                _DetailChip(icon: LucideIcons.ruler, label: '${user.profile!.height} cm', isDark: isDark),
            ],
          ),
          
          // Bio
          if (user.profile?.bio != null && user.profile!.bio!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 8),
            Text(
              user.profile!.bio!,
              style: TextStyle(fontSize: 14, height: 1.5, color: subtitleColor),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          // Religious Info
          if (user.profile?.religiousLevel != null || user.profile?.prayerFrequency != null) ...[
            const SizedBox(height: 20),
            _buildInfoCard(
              title: 'Faith & Practice',
              icon: LucideIcons.sparkles,
              isDark: isDark,
              children: [
                if (user.profile?.religiousLevel != null)
                  _buildInfoRow(LucideIcons.heart, 'Religious Level', user.profile!.religiousLevel!.replaceAll('_', ' '), isDark),
                if (user.profile?.prayerFrequency != null)
                  _buildInfoRow(LucideIcons.clock, 'Prayer', user.profile!.prayerFrequency!.replaceAll('_', ' '), isDark),
                if (user.profile?.hijabStatus != null)
                  _buildInfoRow(LucideIcons.shirt, 'Hijab', user.profile!.hijabStatus!, isDark),
              ],
            ),
          ],
          
          // Career & Education
          if (user.profile?.jobTitle != null || user.profile?.company != null) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Career',
              icon: LucideIcons.briefcase,
              isDark: isDark,
              children: [
                if (user.profile?.jobTitle != null)
                  _buildInfoRow(LucideIcons.briefcase, 'Job', user.profile!.jobTitle!, isDark),
                if (user.profile?.company != null)
                  _buildInfoRow(LucideIcons.building, 'Company', user.profile!.company!, isDark),
              ],
            ),
          ],
          
          // Interests
          if (user.profile?.interests != null && user.profile!.interests!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Interests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.profile!.interests!.map((i) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(i, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
              )).toList(),
            ),
          ],
          
          // Languages
          if (user.profile?.languages != null && user.profile!.languages!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Languages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.profile!.languages!.map((l) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(l, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
              )).toList(),
            ),
          ],
          
          // Bottom padding for swipe buttons
          const SizedBox(height: 100),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard({required String title, required IconData icon, required bool isDark, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.white38 : Colors.grey),
          const SizedBox(width: 10),
          Text('$label: ', style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey.shade600)),
          Expanded(
            child: Text(
              value.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  
  const _DetailChip({required this.icon, required this.label, required this.isDark});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isDark ? Colors.white70 : Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            label.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' '),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class _SwipeBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  final bool isEnabled;

  const _SwipeBtn({required this.icon, required this.color, required this.size, required this.onTap, this.isEnabled = true});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5)),
            ],
          ),
          child: Icon(icon, color: color, size: size * 0.4),
        ),
      ),
    );
  }
}

class _ActionCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final bool hasBadge;

  const _ActionCircleButton({required this.icon, required this.onTap, required this.isDark, this.hasBadge = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
            ),
            child: Icon(icon, color: isDark ? Colors.white : AppColors.secondary, size: 20),
          ),
          if (hasBadge)
            Positioned(
              right: 2, top: 2,
              child: Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: AppColors.error, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BOTTOM SECTION — User info + action bar
// ═══════════════════════════════════════════════════════════════════════════
class _BottomSection extends StatelessWidget {
  final UserModel user;
  final double bottomPad;
  final bool isDark;
  final VoidCallback onLike, onPass, onRewind, onCompliment, onDetails;

  const _BottomSection({
    required this.user,
    required this.bottomPad,
    required this.isDark,
    required this.onLike,
    required this.onPass,
    required this.onRewind,
    required this.onCompliment,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();
    final isPremium = controller.isPremium;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Rewind (Gold Glass)
          _ActionBtn(
            icon: LucideIcons.refreshCcw,
            bgColor: isDark ? AppColors.cardDark.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
            iconColor: AppColors.gold,
            size: 46,
            iconSize: 20,
            outlined: true,
            onTap: () {
              if (isPremium) {
                onRewind();
              } else {
                _showPremiumRequired('Rewind');
              }
            },
          ),
          // Dislike (Plum/Grey)
          _ActionBtn(
            icon: LucideIcons.x,
            bgColor: AppColors.secondaryDark.withValues(alpha: 0.9),
            iconColor: Colors.white,
            size: 58,
            iconSize: 26,
            onTap: onPass,
          ),
          // Like (Emerald) - Largest
          _ActionBtn(
            icon: LucideIcons.heart,
            bgColor: AppColors.emerald,
            iconColor: Colors.white,
            size: 72,
            iconSize: 32,
            onTap: onLike,
          ),
          // Send Compliment (Gold)
          _ActionBtn(
            icon: LucideIcons.award,
            bgColor: AppColors.gold,
            iconColor: Colors.white,
            size: 58,
            iconSize: 26,
            onTap: () {
              if (isPremium) {
                onCompliment();
              } else {
                _showPremiumRequired('Compliment');
              }
            },
          ),
          // Boost (Accent/Glass)
          _ActionBtn(
            icon: LucideIcons.zap,
            bgColor: isDark ? AppColors.cardDark.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
            iconColor: Colors.amber,
            size: 46,
            iconSize: 20,
            outlined: true,
            onTap: () {
              if (isPremium) {
                Helpers.showSnackbar(message: 'profile_boosted_msg'.tr);
              } else {
                _showPremiumRequired('Boost');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showPremiumRequired(String feature) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.crown, size: 48, color: AppColors.gold),
            const SizedBox(height: 16),
            Text('premium_required'.tr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('upgrade_to_unlock'.tr, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 50)),
              child: Text('maybe_later'.tr, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ), // Or a dedicated "Go Premium" modal
      isScrollControlled: true,
    );
    Helpers.showSnackbar(
      message: 'premium_feature_msg'.trParams({'feature': feature}),
      isError: false,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACTION BUTTON — Glass morphism circle
// ═══════════════════════════════════════════════════════════════════════════
class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final double size;
  final double iconSize;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.size,
    required this.iconSize,
    this.outlined = false,
    required this.onTap,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleCtrl.reverse(),
      onTapUp: (_) {
        _scaleCtrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _scaleCtrl.forward(),
      child: ScaleTransition(
        scale: _scaleCtrl,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.outlined
                ? Colors.white.withValues(alpha: 0.1)
                : widget.bgColor,
            shape: BoxShape.circle,
            border: widget.outlined
                ? Border.all(color: widget.iconColor.withValues(alpha: 0.5), width: 2)
                : null,
            boxShadow: [
              if (!widget.outlined)
                BoxShadow(
                  color: widget.bgColor.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Icon(widget.icon, color: widget.iconColor, size: widget.iconSize),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// USER DETAILS BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════
class _UserDetailsSheet extends StatelessWidget {
  final UserModel user;
  const _UserDetailsSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          // ── Scrollable Content ──
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 1. Photo Gallery with Indicators
                _buildGallery(user),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Name & Age & Verified
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${user.firstName ?? user.username ?? 'User'}${user.profile?.age != null ? ", ${user.profile!.age}" : ""}',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            ),
                          ),
                          if (user.selfieVerified) ...[
                             Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Color(0xFFC69C6D), shape: BoxShape.circle),
                              child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 16),
                            ),
                          ],
                        ],
                      ),
                      
                      if (user.profile?.city != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(LucideIcons.mapPin, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${user.profile!.city!}${user.profile!.country != null ? " ${Helpers.getCountryFlag(user.profile!.country)}" : ""}',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 24),

                      // 3. About Me
                      if (user.profile?.bio?.isNotEmpty == true) ...[
                        _buildSectionHeader('about_me'.tr),
                        Text(
                          user.profile!.bio!,
                          style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey.shade800),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 4. Faith & Foundation (Premium Section)
                      if (user.profile?.sect != null || user.profile?.religiousLevel != null) ...[
                        _buildPremiumSection(
                          title: 'religious_foundation'.tr,
                          icon: LucideIcons.moon,
                          child: Wrap(
                            spacing: 8, runSpacing: 8,
                            children: [
                              if (user.profile?.sect != null) _buildPill(user.profile!.sect!.capitalizeFirst!),
                              if (user.profile?.religiousLevel != null) _buildPill(user.profile!.religiousLevel!.replaceAll('_', ' ').capitalizeFirst!),
                              if (user.profile?.prayerFrequency != null) _buildPill('${'prayer_label'.tr}: ${user.profile!.prayerFrequency!.replaceAll('_', ' ').capitalizeFirst!}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 5. Lifestyle & Attributes
                      _buildPremiumSection(
                        title: 'lifestyle_vibe'.tr,
                        icon: LucideIcons.heart,
                        child: Wrap(
                          spacing: 8, runSpacing: 8,
                          children: [
                            if (user.profile?.maritalStatus != null) _buildPill(user.profile!.maritalStatus!.capitalizeFirst!),
                            if (user.profile?.height != null) _buildPill('${user.profile!.height} cm'),
                            if (user.profile?.education != null) _buildPill(user.profile!.education!.capitalizeFirst!),
                            if (user.profile?.dietary != null) _buildPill(user.profile!.dietary!.capitalizeFirst!),
                            if (user.profile?.hijabStatus != null) _buildPill(user.profile!.hijabStatus!.capitalizeFirst!),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 6. Career
                      if (user.profile?.jobTitle != null) ...[
                        _buildPremiumSection(
                          title: 'profession_label'.tr,
                          icon: LucideIcons.briefcase,
                          child: _buildAttributeRow(LucideIcons.briefcase, '${user.profile!.jobTitle!}${user.profile?.company != null ? " at ${user.profile!.company}" : ""}', padding: 0),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 7. Interests
                      if (user.profile?.interests?.isNotEmpty == true) ...[
                        _buildSectionHeader('interests'.tr),
                        _buildPills(user.profile!.interests!),
                        const SizedBox(height: 24),
                      ],

                      // 8. Languages
                      if (user.profile?.languages?.isNotEmpty == true) ...[
                        _buildSectionHeader('languages'.tr),
                        _buildPills(user.profile!.languages!),
                        const SizedBox(height: 24),
                      ],

                      const SizedBox(height: 180), // Bottom spacer for buttons
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Fixed Top Header ──
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                   PositionedDirectional(
                    start: 0,
                    child: IconButton(
                      icon: const Icon(LucideIcons.x, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Text(
                    'profile'.tr,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  PositionedDirectional(
                    end: 0,
                    child: IconButton(
                      icon: const Icon(LucideIcons.moreVertical, size: 24),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Fixed Bottom Actions ──
          Positioned(
            bottom: bottomPad > 0 ? bottomPad + 10 : 20,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ModalActionBtn(icon: LucideIcons.x, color: Colors.red, onTap: () => Navigator.pop(context)),
                  _ModalActionBtn(
                    icon: LucideIcons.award, 
                    color: Colors.orange, 
                    isCircle: true, 
                    onTap: () {
                      Navigator.pop(context);
                      _showComplimentDialog(context, user.id, Get.find<HomeController>());
                    }
                  ),
                  _ModalActionBtn(icon: LucideIcons.heart, color: Colors.pink, onTap: () {
                    Navigator.pop(context);
                    Get.find<HomeController>().likeUser(user.id);
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallery(UserModel user) {
    final photos = user.photos ?? [];
    if (photos.isEmpty && user.mainPhotoUrl == null) {
      return Container(
        height: 400,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: const Icon(LucideIcons.image, size: 48, color: Colors.grey),
      );
    }

    final displayPhotos = photos.isNotEmpty 
        ? photos.map((p) => p.url).toList() 
        : [user.mainPhotoUrl!];

    final pageController = PageController();
    final currentPage = 0.obs;

    return SizedBox(
      height: 500,
      child: Stack(
        children: [
          PageView.builder(
            controller: pageController,
            itemCount: displayPhotos.length,
            onPageChanged: (v) => currentPage.value = v,
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: CloudinaryUrl.getResizedUrl(displayPhotos[index], width: 800),
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => _PlaceholderPhoto(user: user),
              );
            },
          ),
          // Indicators
          PositionedDirectional(
            top: 70, // Below header
            start: 16,
            end: 16,
            child: Obx(() => Row(
              children: List.generate(displayPhotos.length, (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i == currentPage.value ? Colors.white : Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeRow(IconData icon, String text, {double padding = 12}) {
    return Padding(
      padding: EdgeInsets.only(bottom: padding),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey.shade700))),
        ],
      ),
    );
  }

  Widget _buildPremiumSection({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildPills(List<String> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((it) => _buildPill(it)).toList(),
    );
  }

  Widget _buildPill(String text, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.pink.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? Colors.pink : Colors.black12, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.pink : Colors.grey.shade800,
        ),
      ),
    );
  }

}

class _ModalActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isCircle;
  final VoidCallback onTap;

  const _ModalActionBtn({required this.icon, required this.color, this.isCircle = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isCircle ? 64 : 54,
        height: isCircle ? 64 : 54,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(icon, color: color, size: isCircle ? 32 : 24),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PLACEHOLDER PHOTO
// ═══════════════════════════════════════════════════════════════════════════
class _PlaceholderPhoto extends StatelessWidget {
  final UserModel user;
  const _PlaceholderPhoto({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C3E50), Color(0xFF000000)],
        ),
      ),
      child: Center(
        child: Text(
          Helpers.getInitials(user.firstName ?? user.username, user.lastName),
          style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w900, color: Colors.white24),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STRING EXTENSION
// ═══════════════════════════════════════════════════════════════════════════

void _showComplimentDialog(BuildContext context, String userId, HomeController controller) {
  final tc = TextEditingController();
  Get.dialog(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('compliments_label'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
      content: TextField(
        controller: tc,
        maxLength: 200,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'say_hello'.tr,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
        ElevatedButton(
          onPressed: () {
            if (tc.text.trim().isNotEmpty) {
              controller.complimentUser(userId, tc.text.trim());
              Get.back();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('send'.tr),
        ),
      ],
    ),
  );
}

