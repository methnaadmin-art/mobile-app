import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:get/get.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:methna_app/app/controllers/home_controller.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/app/data/services/location_service.dart';
import 'package:methna_app/app/data/services/notification_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/utils/cloudinary_url.dart';
import 'package:methna_app/core/utils/google_fonts_stub.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/animated_empty_state.dart';
import 'package:methna_app/core/widgets/app_modal_sheet.dart';
import 'package:methna_app/core/widgets/custom_button.dart';
import 'package:methna_app/core/widgets/ad_card.dart';
import 'package:url_launcher/url_launcher.dart';

class _DiscoverCardPhoto {
  const _DiscoverCardPhoto({
    required this.url,
    this.isLocked = false,
    this.lockReason,
    this.unlockCta,
  });

  final String url;
  final bool isLocked;
  final String? lockReason;
  final String? unlockCta;
}

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  Future<void> _openComplimentComposer(
    BuildContext context,
    UserModel user,
  ) async {
    if (!controller.canSendCompliment) {
      Get.toNamed(AppRoutes.subscription);
      return;
    }

    final message = await showMethnaModalSheet<String>(
      context: context,
      child: _ComplimentComposerSheet(user: user),
    );
    final trimmed = message?.trim() ?? '';
    if (trimmed.isEmpty) return;

    final sent = await controller.complimentUser(user.id, trimmed);
    if (!sent) return;

    final fallback = user.publicDisplayName.trim();
    final displayName = fallback.isNotEmpty ? fallback : 'someone'.tr;
    Helpers.showSnackbar(
      message: 'compliment_sent_success'.trParams({'name': displayName}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationService = Get.isRegistered<NotificationService>()
        ? Get.find<NotificationService>()
        : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: isDark ? AppColors.backgroundDark : AppColors.surfaceLight,
        child: SafeArea(
          bottom: false,
          child: Obx(() {
            final hasCards = controller.discoverUsers.isNotEmpty;
            final showLocationGate = controller.showLocationGate.value;
            final showSwipeTutorial = controller.showSwipeTutorial.value;
            return Stack(
              children: [
                Positioned.fill(
                  child: Builder(
                    builder: (context) {
                      if (controller.discoverUsers.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 54, bottom: 0),
                          child: _EmptyState(
                            onRefresh: controller.refreshDiscoverUsers,
                          ),
                        );
                      }

                      final topCardId = controller.discoverUsers.isEmpty
                          ? 'empty'
                          : controller.discoverUsers.first.id;

                      return Stack(
                        children: [
                          CardSwiper(
                        key: ValueKey<String>(
                          'discover_${topCardId}_${controller.discoverUsers.length}',
                        ),
                        controller: controller.swiperController,
                        cardsCount: controller.discoverUsers.length,
                        numberOfCardsDisplayed:
                            controller.discoverUsers.length > 1 ? 2 : 1,
                        padding: EdgeInsets.zero,
                        backCardOffset: controller.discoverUsers.length > 1
                            ? const Offset(0, 28)
                            : Offset.zero,
                        allowedSwipeDirection: const AllowedSwipeDirection.only(
                          up: true,
                        ),
                        onSwipe: (previousIndex, currentIndex, direction) {
                          if (previousIndex < 0 ||
                              previousIndex >=
                                  controller.discoverUsers.length) {
                            return false;
                          }

                          final user = controller.discoverUsers[previousIndex];

                          if (direction == CardSwiperDirection.top) {
                            HapticFeedback.heavyImpact();
                            unawaited(_openComplimentComposer(context, user));
                            return false;
                          }

                          switch (direction) {
                            case CardSwiperDirection.right:
                              HapticFeedback.mediumImpact();
                              controller.likeUser(
                                user.id,
                                swiperCurrentIndex: currentIndex,
                              );
                              break;
                            case CardSwiperDirection.left:
                              HapticFeedback.selectionClick();
                              controller.passUser(
                                user.id,
                                swiperCurrentIndex: currentIndex,
                              );
                              break;
                            case CardSwiperDirection.top:
                              break;
                            case CardSwiperDirection.bottom:
                              break;
                          }

                          controller.incrementSwipeCount();
                          return true;
                        },
                        onUndo: (previousIndex, currentIndex, direction) {
                          controller.currentCardIndex.value = currentIndex;
                          controller.rewindLastSwipe();
                          return true;
                        },
                        cardBuilder:
                            (
                              context,
                              index,
                              horizontalOffsetPercentage,
                              verticalOffsetPercentage,
                            ) {
                              final user = controller.discoverUsers[index];
                              return _HomeProfileCard(
                                user: user,
                                controller: controller,
                                onComplimentRequested: (targetUser) =>
                                    _openComplimentComposer(
                                      context,
                                      targetUser,
                                    ),
                                horizontalOffsetPercentage:
                                    horizontalOffsetPercentage.toDouble(),
                                verticalOffsetPercentage:
                                    verticalOffsetPercentage.toDouble(),
                              );
                            },
                      ),

                          // Full-screen ad overlay
                          if (controller.showAdOverlay.value)
                            _AdOverlayCard(
                              controller: controller,
                              featuredAd: controller.featuredAd.value,
                            ),
                        ],
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 14,
                  right: 14,
                  child: _HomeTopBar(
                    notificationService: notificationService,
                    transparent: hasCards && !showLocationGate,
                  ),
                ),
                if (showLocationGate)
                  Positioned.fill(
                    child: _LocationGateOverlay(
                      onEnable: controller.enableLocationFromGate,
                    ),
                  ),
                if (showSwipeTutorial)
                  Positioned.fill(
                    child: _SwipeTutorialOverlay(
                      onDismiss: controller.dismissSwipeTutorial,
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({this.notificationService, this.transparent = false});

  final NotificationService? notificationService;
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeController = Get.find<HomeController>();

    return SizedBox(
      height: 38,
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          Obx(() {
            final current = homeController.currentUser;
            final avatarUrl = CloudinaryUrl.thumbnail(current?.mainPhotoUrl);
            final initials = Helpers.getInitials(
              current?.firstName,
              current?.lastName,
            );
            return _TopAvatarButton(
              imageUrl: avatarUrl,
              initials: initials,
              transparent: transparent,
              onTap: () => Get.toNamed(AppRoutes.settings),
            );
          }),
          const Spacer(),
          if (notificationService != null)
            Obx(() {
              final hasBadge = notificationService!.unreadCount.value > 0;
              return _TopIconButton(
                icon: LucideIcons.bell,
                onTap: Get.find<HomeController>().openNotifications,
                hasBadge: hasBadge,
                color: transparent
                    ? Colors.white
                    : (isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF232129)),
                transparent: transparent,
              );
            })
          else
            _TopIconButton(
              icon: LucideIcons.bell,
              onTap: Get.find<HomeController>().openNotifications,
              color: transparent
                  ? Colors.white
                  : (isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF232129)),
              transparent: transparent,
            ),
          const SizedBox(width: 6),
          _TopIconButton(
            icon: LucideIcons.settings2,
            onTap: Get.find<HomeController>().openFilter,
            color: transparent
                ? Colors.white
                : (isDark
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF232129)),
            transparent: transparent,
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    required this.onTap,
    this.hasBadge = false,
    this.color = const Color(0xFF232129),
    this.transparent = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool hasBadge;
  final Color color;
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    final iconCore = Container(
      width: 32,
      height: 32,
      decoration: transparent
          ? BoxDecoration(
              color: Colors.black.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            )
          : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 18.5, color: color),
          if (hasBadge)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
              ),
            ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: transparent
            ? ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: iconCore,
                ),
              )
            : iconCore,
      ),
    );
  }
}

class _TopAvatarButton extends StatelessWidget {
  const _TopAvatarButton({
    required this.onTap,
    required this.imageUrl,
    required this.initials,
    this.transparent = false,
  });

  final VoidCallback onTap;
  final String imageUrl;
  final String initials;
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final avatar = Container(
      width: 34,
      height: 34,
      decoration: transparent
          ? BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            )
          : BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1D2130) : const Color(0xFFFFF5F7),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF353B4B)
                    : const Color(0xFFEDE9FE),
              ),
            ),
      child: ClipOval(
        child: imageUrl.trim().isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => _AvatarInitials(
                  initials: initials,
                  transparent: transparent,
                ),
              )
            : _AvatarInitials(initials: initials, transparent: transparent),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: transparent
            ? ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: avatar,
                ),
              )
            : avatar,
      ),
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  const _AvatarInitials({required this.initials, required this.transparent});

  final String initials;
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    final color = transparent ? Colors.white : AppColors.primary;
    return Container(
      alignment: Alignment.center,
      color: Colors.transparent,
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _HomeProfileCard extends StatelessWidget {
  const _HomeProfileCard({
    required this.user,
    required this.controller,
    required this.onComplimentRequested,
    required this.horizontalOffsetPercentage,
    required this.verticalOffsetPercentage,
  });

  final UserModel user;
  final HomeController controller;
  final Future<void> Function(UserModel user) onComplimentRequested;
  final double horizontalOffsetPercentage;
  final double verticalOffsetPercentage;

  @override
  Widget build(BuildContext context) => _buildImageFirstCard(context);

  Widget _buildImageFirstCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final likeProgress = horizontalOffsetPercentage > 0
        ? horizontalOffsetPercentage.clamp(0.0, 1.0).toDouble()
        : 0.0;
    final passProgress = horizontalOffsetPercentage < 0
        ? (-horizontalOffsetPercentage).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final complimentProgress = verticalOffsetPercentage < 0
        ? (-verticalOffsetPercentage).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final profile = user.profile;
    final infoItems = _profileSummaryItems(profile);
    final interests = profile?.interests ?? const <String>[];
    final languages = profile?.languages ?? const <String>[];
    final familyValues = profile?.familyValues ?? const <String>[];
    final basicFacts = _factsFromPairs([
      MapEntry('gender'.tr, _humanizeNullable(profile?.gender)),
      MapEntry('ethnicity'.tr, _humanizeNullable(profile?.ethnicity)),
      MapEntry('nationality'.tr, _humanizeNullable(profile?.nationality)),
      MapEntry(
        'nationalities'.tr,
        profile?.nationalities
            ?.where((item) => item.trim().isNotEmpty)
            .join(', '),
      ),
      MapEntry(
        'height'.tr,
        profile?.height != null ? '${profile!.height} cm' : null,
      ),
      MapEntry(
        'weight'.tr,
        profile?.weight != null ? '${profile!.weight} kg' : null,
      ),
    ]);
    final faithFacts = _factsFromPairs([
      MapEntry(
        'religious_level'.tr,
        _humanizeNullable(profile?.religiousLevel),
      ),
      MapEntry('sect'.tr, _humanizeNullable(profile?.sect)),
      MapEntry('prayer'.tr, _humanizeNullable(profile?.prayerFrequency)),
      MapEntry(
        'marriage_intention'.tr,
        _humanizeNullable(profile?.intentMode),
      ),
      MapEntry('marital_status'.tr, _humanizeNullable(profile?.maritalStatus)),
      MapEntry('time_frame'.tr, _humanizeNullable(profile?.marriageIntention)),
      MapEntry(
        'second_wife_preference'.tr,
        _humanizeNullable(profile?.secondWifePreference),
      ),
    ]);
    final careerFacts = _factsFromPairs([
      MapEntry('education'.tr, _humanizeNullable(profile?.education)),
      MapEntry(
        'education_details'.tr,
        _humanizeNullable(profile?.educationDetails),
      ),
      MapEntry('job_title'.tr, _humanizeNullable(profile?.jobTitle)),
      MapEntry('company'.tr, _humanizeNullable(profile?.company)),
    ]);
    final lifestyleFacts = _factsFromPairs([
      MapEntry(
        'living_situation'.tr,
        _humanizeNullable(profile?.livingSituation),
      ),
      MapEntry(
        'communication_style'.tr,
        _humanizeNullable(profile?.communicationStyle),
      ),
      MapEntry('dietary'.tr, _humanizeNullable(profile?.dietary)),
      MapEntry('workout'.tr, _humanizeNullable(profile?.workoutFrequency)),
      MapEntry('sleep_schedule'.tr, _humanizeNullable(profile?.sleepSchedule)),
      MapEntry('social_media'.tr, _humanizeNullable(profile?.socialMediaUsage)),
      MapEntry('drinking'.tr, _humanizeNullable(profile?.alcohol)),
      MapEntry('hijab'.tr, _humanizeNullable(profile?.hijabStatus)),
      MapEntry(
        'has_pets'.tr,
        _boolValue(profile?.hasPets, yesLabel: 'yes'.tr, noLabel: 'no'.tr),
      ),
      MapEntry('pet_preference'.tr, _humanizeNullable(profile?.petPreference)),
    ]);
    final familyFacts = _factsFromPairs([
      MapEntry('family_plans'.tr, _humanizeNullable(profile?.familyPlans)),
      MapEntry(
        'has_children'.tr,
        _boolValue(profile?.hasChildren, yesLabel: 'yes'.tr, noLabel: 'no'.tr),
      ),
      MapEntry(
        'children'.tr,
        profile?.numberOfChildren != null
            ? profile!.numberOfChildren.toString()
            : null,
      ),
      MapEntry(
        'wants_children'.tr,
        _boolValue(
          profile?.wantsChildren,
          yesLabel: 'yes'.tr,
          noLabel: 'no'.tr,
        ),
      ),
      MapEntry(
        'relocate'.tr,
        _boolValue(
          profile?.willingToRelocate,
          yesLabel: 'open_to_relocate'.tr,
          noLabel: 'prefer_to_stay'.tr,
        ),
      ),
    ]);
    final healthFacts = _factsFromPairs([
      MapEntry(
        'vaccination'.tr,
        _boolValue(
          profile?.vaccinationStatus,
          yesLabel: 'vaccinated'.tr,
          noLabel: 'not_vaccinated'.tr,
        ),
      ),
      MapEntry('blood_type'.tr, _humanizeNullable(profile?.bloodType)),
      MapEntry('health_notes'.tr, _humanizeNullable(profile?.healthNotes)),
    ]);
    final favoritesMusic = profile?.favoriteMusic ?? const <String>[];
    final favoriteMovies = profile?.favoriteMovies ?? const <String>[];
    final favoriteBooks = profile?.favoriteBooks ?? const <String>[];
    final travelPreferences = profile?.travelPreferences ?? const <String>[];
    final previewInterests = interests.take(4).toList(growable: false);
    final countryLabel = (profile?.country ?? '').trim();
    final cardPhotos = <_DiscoverCardPhoto>[];
    final seenUnlockedPhotoUrls = <String>{};

    for (final photo in user.photos ?? const <PhotoModel>[]) {
      final rawUrl = photo.url.trim();
      if (photo.isLocked) {
        cardPhotos.add(
          _DiscoverCardPhoto(
            url: rawUrl,
            isLocked: true,
            lockReason: photo.lockReason,
            unlockCta: photo.unlockCta,
          ),
        );
        continue;
      }

      if (rawUrl.isEmpty) continue;
      if (seenUnlockedPhotoUrls.add(rawUrl)) {
        cardPhotos.add(_DiscoverCardPhoto(url: rawUrl));
      }
    }

    final fallbackMain = (user.mainPhotoUrl ?? '').trim();
    if (fallbackMain.isNotEmpty && seenUnlockedPhotoUrls.add(fallbackMain)) {
      cardPhotos.insert(0, _DiscoverCardPhoto(url: fallbackMain));
    }

    final firstUnlockedPhotoIndex = cardPhotos.indexWhere(
      (photo) => !photo.isLocked && photo.url.trim().isNotEmpty,
    );
    if (firstUnlockedPhotoIndex > 0) {
      final unlockedMain = cardPhotos.removeAt(firstUnlockedPhotoIndex);
      cardPhotos.insert(0, unlockedMain);
    }

    if (cardPhotos.isEmpty) {
      cardPhotos.add(const _DiscoverCardPhoto(url: ''));
    }

    final surfaceColor = isDark ? const Color(0xFF0F1320) : Colors.white;
    final detailsSurface = isDark
        ? const Color(0xFF171D2C)
        : const Color(0xFFF4F6FB);
    final detailsPrimary = isDark ? Colors.white : const Color(0xFF191E2A);
    final detailsSecondary = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : const Color(0xFF606B82);
    final detailsBody = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : const Color(0xFF2A3143);
    final tagSurface = isDark
        ? Colors.white.withValues(alpha: 0.09)
        : const Color(0xFFE9EDF6);
    final chipSurface = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE2E8F5);
    final chipText = isDark ? Colors.white : const Color(0xFF1F2738);
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : const Color(0xFFD5DCEA);
    final topMaskColor = Colors.black.withValues(alpha: isDark ? 0.42 : 0.34);
    final bottomMaskColor = Colors.black.withValues(
      alpha: isDark ? 0.9 : 0.88,
    );
    final panelBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFD9E0EF);

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageHeight = constraints.maxHeight;
        const floatingNavHeight = 66.0;
        const actionNavGap = 0.0;
        const actionRowHeight = 74.0;
        const actionDockPullDown = 30.0;
        final bottomInset = MediaQuery.of(context).padding.bottom;
        final floatingNavBottomMargin = bottomInset > 0
            ? bottomInset + 8
            : 10.0;
        // Aggressively dock actions closer to nav, while keeping a tiny safe floor.
        final actionRowBottom =
            (floatingNavBottomMargin +
                    floatingNavHeight +
                    actionNavGap -
                    actionDockPullDown)
                .clamp(floatingNavBottomMargin + 4, double.infinity)
                .clamp(0.0, double.infinity)
                .toDouble();
        final scrollBottomPadding = actionRowBottom + actionRowHeight + 20;
        final infoTextBottom = actionRowBottom + actionRowHeight + 14;

        return Obx(() {
          final currentPhotoIndex = controller.cardPhotoIndexFor(
            user.id,
            cardPhotos.length,
          );
          final currentPhoto = cardPhotos[currentPhotoIndex];
          final photoUrl = currentPhoto.url;
          final cityLabel = (profile?.city ?? '').trim();
          final locationLabel = [
            cityLabel,
            countryLabel,
          ].where((value) => value.isNotEmpty).join(', ');
          final summaryLocation = locationLabel.isNotEmpty
              ? '${_countryFlagEmoji(countryLabel)} $locationLabel'
              : _subtitle(user, controller.currentUser);
          final summaryInterests = previewInterests
              .take(3)
              .toList(growable: false);
          final summaryInterestsLine = summaryInterests.join(' • ');
          final summaryFaith =
              [
                    _humanizeNullable(profile?.religiousLevel),
                    _humanizeNullable(profile?.sect),
                  ]
                  .whereType<String>()
                  .where((value) => value.trim().isNotEmpty)
                  .take(2)
                  .join(' • ');
          final cue = controller.swipeButtonCue.value.trim().toLowerCase();
          final passEmphasis = math.max(
            passProgress,
            cue == 'pass' ? 1.0 : 0.0,
          );
          final likeEmphasis = math.max(
            likeProgress,
            cue == 'like' ? 1.0 : 0.0,
          );
          final likeFlashStrength = likeEmphasis.clamp(0.0, 1.0).toDouble();
          final complimentEmphasis = math.max(
            complimentProgress,
            cue == 'compliment' ? 1.0 : 0.0,
          );
          final passFlashStrength = passEmphasis.clamp(0.0, 1.0).toDouble();
          final swipeTextProgress = math.max(likeProgress, passProgress);
          final swipeTextCue = likeProgress >= passProgress ? 'like' : 'pass';
          final primaryName = _primaryName(user);
          final age = profile?.showAge == false ? null : user.age;
          final score = controller.getCompatibilityScore(user.id);
          final displayScore = score > 0
              ? score
              : controller.estimateCompatibilityScore(user);
          final focusedSwipeAction = likeProgress > 0.03
              ? 'like'
              : passProgress > 0.03
              ? 'pass'
              : (cue == 'like' || cue == 'pass' ? cue : '');
          final focusedSwipeStrength = focusedSwipeAction == 'like'
              ? likeProgress
              : focusedSwipeAction == 'pass'
              ? passProgress
              : 0.0;
          final focusedVisualStrength = math
              .max(
                focusedSwipeStrength,
                focusedSwipeAction.isNotEmpty ? 0.34 : 0.0,
              )
              .clamp(0.0, 1.0)
              .toDouble();

          void onPassTap() {
            HapticFeedback.selectionClick();
            controller.triggerSwipeButtonCue('pass');
            controller.swiperController.swipe(CardSwiperDirection.left);
          }

          void onLikeTap() {
            HapticFeedback.mediumImpact();
            controller.triggerSwipeButtonCue('like');
            controller.swiperController.swipe(CardSwiperDirection.right);
          }

          return Container(
            decoration: BoxDecoration(color: surfaceColor),
            child: Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: scrollBottomPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: imageHeight,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: _CardPhoto(
                                  user: user,
                                  imageUrl: photoUrl,
                                  isLocked: currentPhoto.isLocked,
                                  lockReason: currentPhoto.lockReason,
                                  unlockCta: currentPhoto.unlockCta,
                                ),
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withValues(
                                            alpha: isDark ? 0.12 : 0.14,
                                          ),
                                          Colors.transparent,
                                          Colors.black.withValues(
                                            alpha: isDark ? 0.2 : 0.24,
                                          ),
                                        ],
                                        stops: const [0, 0.36, 1],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: 128,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        topMaskColor,
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                height: 300,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(
                                          alpha: isDark ? 0.44 : 0.4,
                                        ),
                                        bottomMaskColor,
                                      ],
                                      stops: const [0.05, 0.55, 1],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: _SwipeEdgeFeedback(
                                    likeStrength: likeFlashStrength,
                                    passStrength: passFlashStrength,
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: () =>
                                            controller.previousCardPhoto(
                                              user.id,
                                              cardPhotos.length,
                                            ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: () => controller.nextCardPhoto(
                                          user.id,
                                          cardPhotos.length,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 12,
                                left: 12,
                                right: 12,
                                child: _CardTopProgress(
                                  count: cardPhotos.length,
                                  activeIndex: currentPhotoIndex,
                                ),
                              ),
                              Positioned(
                                top: 42,
                                left: 12,
                                child: _CompatibilityBadge(score: displayScore),
                              ),
                              Positioned(
                                top: 42,
                                right: 12,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  switchInCurve: Curves.easeOutQuart,
                                  switchOutCurve: Curves.easeInCubic,
                                  transitionBuilder: (child, animation) {
                                    final offset = _swipeStatusOffsetFromKey(
                                      child.key,
                                    );
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: offset,
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: ScaleTransition(
                                          scale: Tween<double>(
                                            begin: 0.9,
                                            end: 1,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                      ),
                                    );
                                  },
                                  child: _swipeStatusTitle(cue) == null
                                      ? const SizedBox(
                                          key: ValueKey('swipe_status_hidden'),
                                        )
                                      : _SwipeStatusChip(
                                          key: ValueKey('swipe_status_$cue'),
                                          icon: _swipeStatusIcon(cue),
                                          color: _swipeStatusColor(cue),
                                          title: _swipeStatusTitle(cue)!,
                                          subtitle: 'swipe_status_subtitle'.tr,
                                        ),
                                ),
                              ),
                              Positioned(
                                top: imageHeight * 0.2,
                                left: 16,
                                right: 16,
                                child: IgnorePointer(
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 120),
                                    curve: Curves.easeOutCubic,
                                    opacity: swipeTextProgress.clamp(0.0, 1.0),
                                    child: AnimatedScale(
                                      duration: const Duration(
                                        milliseconds: 120,
                                      ),
                                      curve: Curves.easeOutBack,
                                      scale:
                                          0.92 +
                                          (0.16 *
                                              swipeTextProgress.clamp(
                                                0.0,
                                                1.0,
                                              )),
                                      child: Transform.translate(
                                        offset: Offset(
                                          (passProgress - likeProgress) * 22,
                                          0,
                                        ),
                                        child: _SwipeDragLabel(
                                          title:
                                              _swipeStatusTitle(swipeTextCue) ??
                                              swipeTextCue,
                                          icon: _swipeStatusIcon(swipeTextCue),
                                          color: _swipeStatusColor(
                                            swipeTextCue,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: infoTextBottom,
                                child: IgnorePointer(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: RichText(
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: primaryName,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 36,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: const Color(
                                                        0xFFFFC95A,
                                                      ),
                                                      letterSpacing: -0.62,
                                                      textStyle:
                                                          const TextStyle(
                                                            shadows: [
                                                              Shadow(
                                                                color: Color(
                                                                  0xB0000000,
                                                                ),
                                                                blurRadius: 12,
                                                                offset: Offset(
                                                                  0,
                                                                  2,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                    ),
                                                  ),
                                                  if (age != null && age > 0)
                                                    TextSpan(
                                                      text: ', $age',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 25,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white
                                                            .withValues(
                                                              alpha: 0.95,
                                                            ),
                                                        textStyle:
                                                            const TextStyle(
                                                              shadows: [
                                                                Shadow(
                                                                  color: Color(
                                                                    0x9A000000,
                                                                  ),
                                                                  blurRadius:
                                                                      10,
                                                                  offset:
                                                                      Offset(
                                                                        0,
                                                                        2,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (user.isPremium)
                                            ...[
                                              const SizedBox(width: 6),
                                              Icon(
                                                LucideIcons.crown,
                                                size: 19,
                                                color: const Color(0xFFA78BFA),
                                                shadows: const [
                                                  Shadow(
                                                    color: Color(0xAA000000),
                                                    blurRadius: 8,
                                                    offset: Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          if (user.selfieVerified) ...[
                                            const SizedBox(width: 6),
                                            Icon(
                                              LucideIcons.badgeCheck,
                                              size: 20,
                                              color: Colors.white,
                                              shadows: const [
                                                Shadow(
                                                  color: Color(0xAA000000),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        summaryLocation,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14.8,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withValues(
                                            alpha: 0.93,
                                          ),
                                          textStyle: const TextStyle(
                                            shadows: [
                                              Shadow(
                                                color: Color(0x8D000000),
                                                blurRadius: 8,
                                                offset: Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (summaryFaith.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          summaryFaith,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withValues(
                                              alpha: 0.88,
                                            ),
                                            textStyle: const TextStyle(
                                              shadows: [
                                                Shadow(
                                                  color: Color(0x85000000),
                                                  blurRadius: 7,
                                                  offset: Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (summaryInterestsLine.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          summaryInterestsLine,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12.4,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withValues(
                                              alpha: 0.86,
                                            ),
                                            textStyle: const TextStyle(
                                              shadows: [
                                                Shadow(
                                                  color: Color(0x80000000),
                                                  blurRadius: 6,
                                                  offset: Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(height: actionRowHeight + 22),
                        ..._buildProfileDetailsSections(
                          profile: profile,
                          photos: cardPhotos,
                          currentPhotoIndex: currentPhotoIndex,
                          infoItems: infoItems,
                          interests: interests,
                          languages: languages,
                          familyValues: familyValues,
                          basicFacts: basicFacts,
                          faithFacts: faithFacts,
                          careerFacts: careerFacts,
                          lifestyleFacts: lifestyleFacts,
                          familyFacts: familyFacts,
                          healthFacts: healthFacts,
                          favoritesMusic: favoritesMusic,
                          favoriteMovies: favoriteMovies,
                          favoriteBooks: favoriteBooks,
                          travelPreferences: travelPreferences,
                          detailsSurface: detailsSurface,
                          detailsPrimary: detailsPrimary,
                          detailsSecondary: detailsSecondary,
                          detailsBody: detailsBody,
                          tagSurface: tagSurface,
                          chipSurface: chipSurface,
                          chipText: chipText,
                          dividerColor: dividerColor,
                          panelBorderColor: panelBorderColor,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 32,
                  right: 32,
                  bottom: actionRowBottom,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutQuart,
                    switchOutCurve: Curves.easeInCubic,
                    child: focusedSwipeAction == 'pass'
                        ? Center(
                            key: const ValueKey('focused_pass_action'),
                            child: _FocusedSwipeActionButton(
                              icon: LucideIcons.x,
                              color: const Color(0xFFFF4D4F),
                              emphasis: focusedVisualStrength,
                              onTap: onPassTap,
                            ),
                          )
                        : focusedSwipeAction == 'like'
                        ? Center(
                            key: const ValueKey('focused_like_action'),
                            child: _FocusedSwipeActionButton(
                              icon: LucideIcons.badgeCheck,
                              color: AppColors.primary,
                              emphasis: focusedVisualStrength,
                              onTap: onLikeTap,
                            ),
                          )
                        : Row(
                            key: const ValueKey('full_action_row'),
                            textDirection: TextDirection.ltr,
                            children: [
                              Expanded(
                                child: _LabeledActionButton(
                                  label: 'home_action_relay'.tr,
                                  icon: LucideIcons.rotateCcw,
                                  color: const Color(0xFF2A9D6A),
                                  outerSize: 48,
                                  innerSize: 38,
                                  iconSize: 15,
                                  showLabel: false,
                                  labelColor: detailsPrimary,
                                  emphasis: controller.canRewind ? 0.2 : 0,
                                  onTap: () {
                                    if (!controller.hasRewindAccess) {
                                      Get.toNamed(AppRoutes.subscription);
                                      return;
                                    }
                                    if (controller.canRewind) {
                                      HapticFeedback.selectionClick();
                                      controller.rewindLastSwipe();
                                    } else {
                                      Helpers.showSnackbar(
                                        message: 'no_swipe_to_undo'.tr,
                                      );
                                    }
                                  },
                                ),
                              ),
                              Expanded(
                                child: _LabeledActionButton(
                                  label: 'home_action_pass'.tr,
                                  icon: LucideIcons.x,
                                  color: const Color(0xFFFF4D4F),
                                  outerSize: 74,
                                  innerSize: 62,
                                  iconSize: 24,
                                  showLabel: false,
                                  labelColor: detailsPrimary,
                                  emphasis: passEmphasis,
                                  highlightColor: const Color(0xFFFF4D4F),
                                  onTap: onPassTap,
                                ),
                              ),
                              Expanded(
                                child: _LabeledActionButton(
                                  label: 'home_action_compliment'.tr,
                                  icon: LucideIcons.messageSquare,
                                  color: AppColors.primary,
                                  outerSize: 74,
                                  innerSize: 62,
                                  iconSize: 24,
                                  showLabel: false,
                                  labelColor: detailsPrimary,
                                  emphasis: complimentEmphasis,
                                  highlightColor: AppColors.primary,
                                  onTap: () {
                                    if (!controller.canSendCompliment) {
                                      Get.toNamed(AppRoutes.subscription);
                                      return;
                                    }
                                    HapticFeedback.heavyImpact();
                                    controller.triggerSwipeButtonCue(
                                      'compliment',
                                    );
                                    unawaited(onComplimentRequested(user));
                                  },
                                ),
                              ),
                              Expanded(
                                child: _LabeledActionButton(
                                  label: 'home_action_like'.tr,
                                  icon: LucideIcons.badgeCheck,
                                  color: const Color(0xFF2ED47A),
                                  outerSize: 74,
                                  innerSize: 62,
                                  iconSize: 24,
                                  showLabel: false,
                                  labelColor: detailsPrimary,
                                  emphasis: likeEmphasis,
                                  highlightColor: const Color(0xFF2ED47A),
                                  onTap: onLikeTap,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: actionRowBottom - 24,
                  child: IgnorePointer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'home_swipe_hint'.tr,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.88),
                            letterSpacing: 0.05,
                            textStyle: const TextStyle(
                              shadows: [
                                Shadow(
                                  color: Color(0x92000000),
                                  blurRadius: 7,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          LucideIcons.chevronsUp,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  List<Widget> _buildProfileDetailsSections({
    required ProfileModel? profile,
    required List<_DiscoverCardPhoto> photos,
    required int currentPhotoIndex,
    required List<String> infoItems,
    required List<String> interests,
    required List<String> languages,
    required List<String> familyValues,
    required List<_ProfileFact> basicFacts,
    required List<_ProfileFact> faithFacts,
    required List<_ProfileFact> careerFacts,
    required List<_ProfileFact> lifestyleFacts,
    required List<_ProfileFact> familyFacts,
    required List<_ProfileFact> healthFacts,
    required List<String> favoritesMusic,
    required List<String> favoriteMovies,
    required List<String> favoriteBooks,
    required List<String> travelPreferences,
    required Color detailsSurface,
    required Color detailsPrimary,
    required Color detailsSecondary,
    required Color detailsBody,
    required Color tagSurface,
    required Color chipSurface,
    required Color chipText,
    required Color dividerColor,
    required Color panelBorderColor,
  }) {
    final sections = <Widget>[];

    void addTagSection({required String label, required List<String> values}) {
      if (values.isEmpty) return;
      sections.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _CardSectionLabel(label: label, color: detailsPrimary),
        ),
      );
      sections.add(const SizedBox(height: 8));
      sections.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values
                .map(
                  (item) => _SoftTag(
                    label: item,
                    background: chipSurface,
                    textColor: chipText,
                  ),
                )
                .toList(growable: false),
          ),
        ),
      );
      sections.add(const SizedBox(height: 18));
    }

    void addFactsSection({
      required String title,
      required List<_ProfileFact> facts,
    }) {
      if (facts.isEmpty) return;
      sections.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _DetailFactsCard(
            title: title,
            facts: facts,
            surface: detailsSurface,
            primary: detailsPrimary,
            secondary: detailsSecondary,
            dividerColor: dividerColor,
          ),
        ),
      );
      sections.add(const SizedBox(height: 14));
    }

    final lockedPreviewUrl = CloudinaryUrl.medium(user.mainPhotoUrl ?? '');

    if (photos.length > 1) {
      sections.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _CardSectionLabel(label: 'photos'.tr, color: detailsPrimary),
        ),
      );
      sections.add(const SizedBox(height: 8));
      sections.add(
        SizedBox(
          height: 102,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: photos.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final photo = photos[index];
              final thumb = photo.url;
              final resolvedThumb = CloudinaryUrl.medium(thumb);
              final selected = index == currentPhotoIndex;

              return GestureDetector(
                onTap: () {
                  controller.cardPhotoIndices[user.id] = index;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 74,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? AppColors.primary : panelBorderColor,
                      width: selected ? 1.8 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: photo.isLocked
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              if (lockedPreviewUrl.isNotEmpty)
                                CachedNetworkImage(
                                  imageUrl: lockedPreviewUrl,
                                  fit: BoxFit.cover,
                                )
                              else
                                Container(
                                  color: tagSurface,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.lock_rounded,
                                    color: detailsSecondary,
                                  ),
                                ),
                              Positioned.fill(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 5,
                                    sigmaY: 5,
                                  ),
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.45),
                                  ),
                                ),
                              ),
                              Center(
                                child: Icon(
                                  Icons.lock_rounded,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  size: 20,
                                ),
                              ),
                            ],
                          )
                        : resolvedThumb.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: resolvedThumb,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: tagSurface,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.person_rounded,
                              color: detailsSecondary,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      sections.add(const SizedBox(height: 16));
    }

    if ((profile?.bio ?? '').trim().isNotEmpty) {
      sections.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            profile!.bio!.trim(),
            style: GoogleFonts.poppins(
              fontSize: 13.4,
              fontWeight: FontWeight.w400,
              height: 1.58,
              color: detailsBody,
            ),
          ),
        ),
      );
      sections.add(const SizedBox(height: 16));
    }

    if (infoItems.isNotEmpty) {
      sections.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: infoItems
                .map(
                  (item) => _InfoPill(
                    label: item,
                    background: tagSurface,
                    textColor: detailsPrimary,
                  ),
                )
                .toList(growable: false),
          ),
        ),
      );
      sections.add(const SizedBox(height: 18));
    }

    addTagSection(label: 'interests'.tr, values: interests.take(10).toList());
    addTagSection(label: 'languages_speak'.tr, values: languages);
    addTagSection(label: 'family_values'.tr, values: familyValues);

    if ((profile?.aboutPartner ?? '').trim().isNotEmpty) {
      sections.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _CardSectionLabel(
            label: 'looking_for'.tr,
            color: detailsPrimary,
          ),
        ),
      );
      sections.add(const SizedBox(height: 8));
      sections.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            profile!.aboutPartner!.trim(),
            style: GoogleFonts.poppins(
              fontSize: 13.2,
              fontWeight: FontWeight.w400,
              height: 1.55,
              color: detailsBody,
            ),
          ),
        ),
      );
      sections.add(const SizedBox(height: 18));
    }

    addFactsSection(title: 'basics'.tr, facts: basicFacts);
    addFactsSection(title: 'faith_intentions'.tr, facts: faithFacts);
    addFactsSection(title: 'education_work'.tr, facts: careerFacts);
    addFactsSection(title: 'lifestyle'.tr, facts: lifestyleFacts);
    addFactsSection(title: 'family'.tr, facts: familyFacts);
    addFactsSection(title: 'health'.tr, facts: healthFacts);

    addTagSection(label: 'favorite_music'.tr, values: favoritesMusic);
    addTagSection(label: 'favorite_movies'.tr, values: favoriteMovies);
    addTagSection(label: 'favorite_books'.tr, values: favoriteBooks);
    addTagSection(label: 'travel_preferences'.tr, values: travelPreferences);

    return sections;
  }

  String _subtitle(UserModel user, UserModel? currentUser) {
    final profile = user.profile;
    final currentProfile = currentUser?.profile;
    final locationService = Get.isRegistered<LocationService>()
        ? Get.find<LocationService>()
        : null;

    if (profile != null &&
        profile.showDistance &&
        locationService != null &&
        profile.latitude != null &&
        profile.longitude != null &&
        currentProfile?.latitude != null &&
        currentProfile?.longitude != null) {
      final distance = locationService.distanceBetween(
        currentProfile!.latitude!,
        currentProfile.longitude!,
        profile.latitude!,
        profile.longitude!,
      );
      return _formatDistance(distance);
    }

    final locationLabel = [
      profile?.city?.trim(),
      profile?.country?.trim(),
    ].whereType<String>().where((value) => value.isNotEmpty).join(', ');

    if (locationLabel.isNotEmpty) {
      return locationLabel;
    }

    return 'nearby'.tr;
  }

  String _primaryName(UserModel user) {
    final displayName = user.publicShortName.trim();
    if (displayName.isNotEmpty) {
      return displayName;
    }
    return 'profile'.tr;
  }

  String _countryFlagEmoji(String countryRaw) {
    final country = countryRaw.trim().toLowerCase();
    if (country.isEmpty) return '🏳️';
    if (country.contains('alger')) return '🇩🇿';
    if (country.contains('morocco')) return '🇲🇦';
    if (country.contains('tunisia')) return '🇹🇳';
    if (country.contains('egypt')) return '🇪🇬';
    if (country.contains('jordan')) return '🇯🇴';
    if (country.contains('saudi')) return '🇸🇦';
    if (country.contains('emirates') || country.contains('uae')) return '🇦🇪';
    if (country.contains('qatar')) return '🇶🇦';
    if (country.contains('kuwait')) return '🇰🇼';
    if (country.contains('bahrain')) return '🇧🇭';
    if (country.contains('oman')) return '🇴🇲';
    if (country.contains('iraq')) return '🇮🇶';
    if (country.contains('palestin')) return '🇵🇸';
    if (country.contains('syria')) return '🇸🇾';
    if (country.contains('lebanon')) return '🇱🇧';
    if (country.contains('yemen')) return '🇾🇪';
    if (country.contains('sudan')) return '🇸🇩';
    if (country.contains('somalia')) return '🇸🇴';
    if (country.contains('united kingdom') || country == 'uk') return '🇬🇧';
    if (country.contains('united states') || country == 'usa') return '🇺🇸';
    if (country.contains('france')) return '🇫🇷';
    if (country.contains('germany')) return '🇩🇪';
    if (country.contains('canada')) return '🇨🇦';
    if (country.contains('turkey')) return '🇹🇷';
    return '🏳️';
  }

  String _formatDistance(double km) {
    if (km < 1) {
      return 'meters_away'.trParams({'count': '${(km * 1000).round()}'});
    }

    final rounded = km >= 10
        ? km.round().toString()
        : (km % 1 == 0 ? km.toInt().toString() : km.toStringAsFixed(1));
    return 'km_away'.trParams({'distance': rounded});
  }

  List<String> _profileSummaryItems(ProfileModel? profile) {
    if (profile == null) return const <String>[];

    return [
      if ((profile.jobTitle ?? '').trim().isNotEmpty) profile.jobTitle!.trim(),
      if ((profile.education ?? '').trim().isNotEmpty)
        profile.education!.trim(),
      if (profile.height != null) '${profile.height} cm',
      if ((profile.religiousLevel ?? '').trim().isNotEmpty)
        profile.religiousLevel!.trim(),
      if ((profile.maritalStatus ?? '').trim().isNotEmpty)
        profile.maritalStatus!.trim(),
      if ((profile.familyPlans ?? '').trim().isNotEmpty)
        profile.familyPlans!.trim(),
      if ((profile.communicationStyle ?? '').trim().isNotEmpty)
        profile.communicationStyle!.trim(),
      if ((profile.livingSituation ?? '').trim().isNotEmpty)
        profile.livingSituation!.trim(),
      if ((profile.workoutFrequency ?? '').trim().isNotEmpty)
        profile.workoutFrequency!.trim(),
    ];
  }

  List<_ProfileFact> _factsFromPairs(List<MapEntry<String, String?>> pairs) {
    return pairs
        .where((entry) => entry.value != null && entry.value!.trim().isNotEmpty)
        .map((entry) => _ProfileFact(entry.key, entry.value!.trim()))
        .toList(growable: false);
  }

  String? _humanizeNullable(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    // Try translation first for snake_case API values like "never_married"
    final translated = trimmed.tr;
    if (translated != trimmed) return translated;
    return trimmed
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) => part.length == 1
              ? part.toUpperCase()
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String? _boolValue(
    bool? value, {
    required String yesLabel,
    required String noLabel,
  }) {
    if (value == null) return null;
    return value ? yesLabel : noLabel;
  }

  String? _swipeStatusTitle(String cue) {
    switch (cue) {
      case 'like':
        return 'swipe_status_like'.tr;
      case 'pass':
        return 'swipe_status_pass'.tr;
      case 'compliment':
        return 'swipe_status_compliment'.tr;
      default:
        return null;
    }
  }

  IconData _swipeStatusIcon(String cue) {
    switch (cue) {
      case 'like':
        return LucideIcons.badgeCheck;
      case 'pass':
        return LucideIcons.x;
      case 'compliment':
        return LucideIcons.star;
      default:
        return LucideIcons.messageSquare;
    }
  }

  Color _swipeStatusColor(String cue) {
    switch (cue) {
      case 'like':
        return AppColors.primary;
      case 'pass':
        return const Color(0xFFFF4D4F);
      case 'compliment':
        return const Color(0xFFFFA31A);
      default:
        return AppColors.primary;
    }
  }

  Offset _swipeStatusOffset(String cue) {
    switch (cue) {
      case 'like':
        return const Offset(0.22, 0);
      case 'pass':
        return const Offset(-0.22, 0);
      case 'compliment':
        return const Offset(0, -0.22);
      default:
        return const Offset(0, -0.16);
    }
  }

  Offset _swipeStatusOffsetFromKey(Key? key) {
    if (key is! ValueKey<String>) {
      return const Offset(0, -0.16);
    }

    const prefix = 'swipe_status_';
    final raw = key.value;
    if (!raw.startsWith(prefix)) {
      return const Offset(0, -0.16);
    }

    final cue = raw.substring(prefix.length);
    return _swipeStatusOffset(cue);
  }

  // ignore: unused_element
  Future<void> _showBoostSheet(BuildContext context) {
    if (!controller.hasBoostAccess) {
      return controller.boostProfile().then((_) {});
    }

    return Get.to<void>(
          () => _BoostInfoScreen(onActivate: controller.boostProfile),
          transition: Transition.rightToLeftWithFade,
          duration: const Duration(milliseconds: 240),
        ) ??
        Future<void>.value();
  }
}

class _AdOverlayCard extends StatelessWidget {
  final HomeController controller;
  final Map<String, dynamic>? featuredAd;

  const _AdOverlayCard({
    required this.controller,
    required this.featuredAd,
  });

  @override
  Widget build(BuildContext context) {
    final adData = featuredAd != null ? AdCardData.fromJson(featuredAd!) : null;

    return Positioned.fill(
      child: Material(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            if (adData != null && adData.imageUrl != null && adData.imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: CloudinaryUrl.large(adData.imageUrl),
                fit: BoxFit.cover,
                placeholder: (context, url) => const SizedBox(),
                errorWidget: (context, url, error) => const SizedBox(),
              ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.92),
                  ],
                  stops: const [0.0, 0.3, 0.65, 1.0],
                ),
              ),
            ),

            // Close (dismiss) button top-right
            Positioned(
              top: 50,
              right: 16,
              child: GestureDetector(
                onTap: () => controller.dismissAdOverlay(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                ),
              ),
            ),

            // "Sponsored" badge top-left
            Positioned(
              top: 50,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'Sponsored',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Content
            Positioned(
              left: 24,
              right: 24,
              bottom: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    adData?.title ?? 'Sponsored',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (adData?.description != null && adData!.description!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      adData.description!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 28),
                  // Two buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          onTap: () => controller.dismissAdOverlay(),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: Colors.white.withValues(alpha: 0.12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Center(
                              child: Text(
                                'Dismiss',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () {
                            final link = adData?.link?.trim() ?? '';
                            final adId = (featuredAd?['id'] ?? '').toString().trim();
                            if (adId.isNotEmpty) {
                              controller.trackAdClick(adId);
                            }
                            if (link.isNotEmpty) {
                              final uri = Uri.tryParse(link);
                              if (uri != null) {
                                launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            }
                            controller.dismissAdOverlay();
                          },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryLight],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                adData?.buttonText ?? 'Visit',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
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
}

class _CardTopProgress extends StatelessWidget {
  const _CardTopProgress({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) {
      return Align(
        alignment: Alignment.center,
        child: Container(
          width: 30,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      );
    }

    final currentIndex = activeIndex.clamp(0, count - 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: isActive ? 18 : 7,
          height: 7,
          margin: EdgeInsets.only(right: index == count - 1 ? 0 : 5),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withValues(alpha: 0.94)
                : Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _CompatibilityBadge extends StatelessWidget {
  const _CompatibilityBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final tone = score >= 80
        ? const Color(0xFF2ED47A)
        : (score >= 60 ? const Color(0xFFFFC857) : const Color(0xFF6EC3FF));
    final progress = (score.clamp(0, 100).toDouble()) / 100;

    return SizedBox(
      width: 62,
      height: 62,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.34),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                valueColor: AlwaysStoppedAnimation<Color>(tone),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.sparkles, size: 10.5, color: tone),
                const SizedBox(height: 2),
                Text(
                  '$score%',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.05,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeStatusChip extends StatelessWidget {
  const _SwipeStatusChip({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      constraints: const BoxConstraints(minWidth: 140),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
            ),
            child: Icon(icon, size: 12.5, color: color),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11.8,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 10.4,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwipeDragLabel extends StatelessWidget {
  const _SwipeDragLabel({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: color.withValues(alpha: 0.7),
                width: 1.25,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.24),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeEdgeFeedback extends StatelessWidget {
  const _SwipeEdgeFeedback({
    required this.likeStrength,
    required this.passStrength,
  });

  final double likeStrength;
  final double passStrength;

  @override
  Widget build(BuildContext context) {
    final like = likeStrength.clamp(0.0, 1.0).toDouble();
    final pass = passStrength.clamp(0.0, 1.0).toDouble();

    return Stack(
      children: [
        if (pass > 0.001)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOutCubic,
            opacity: (0.52 * pass).clamp(0.0, 1.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xA6FF4D4F),
                    const Color(0x22FF4D4F),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.38, 0.74],
                ),
              ),
            ),
          ),
        if (like > 0.001)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOutCubic,
            opacity: (0.52 * like).clamp(0.0, 1.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.7),
                    AppColors.primary.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.38, 0.74],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ComplimentComposerSheet extends StatefulWidget {
  const _ComplimentComposerSheet({required this.user});

  final UserModel user;

  @override
  State<_ComplimentComposerSheet> createState() =>
      _ComplimentComposerSheetState();
}

class _ComplimentComposerSheetState extends State<_ComplimentComposerSheet> {
  static const _maxLength = 200;
  static const _minLength = 6;

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _displayName {
    final displayName = widget.user.publicDisplayName.trim();
    if (displayName.isNotEmpty) return displayName;
    return 'someone'.tr;
  }

  List<String> _quickCompliments() {
    return [
      'compliment_quick_1'.tr,
      'compliment_quick_2'.tr,
      'compliment_quick_3'.tr,
    ];
  }

  void _appendQuick(String value) {
    final current = _textController.text.trim();
    final next = current.isEmpty ? value : '$current $value';
    if (next.length > _maxLength) return;
    _textController
      ..text = next
      ..selection = TextSelection.collapsed(offset: next.length);
    setState(() {});
  }

  void _submit() {
    final message = _textController.text.trim();
    if (message.isEmpty) {
      Helpers.showSnackbar(
        message: 'compliment_message_required'.tr,
        isError: true,
      );
      return;
    }
    if (message.length < _minLength) {
      Helpers.showSnackbar(
        message: 'compliment_message_too_short'.trParams({
          'count': _minLength.toString(),
        }),
        isError: true,
      );
      return;
    }
    Navigator.of(context).pop(message);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = CloudinaryUrl.medium(widget.user.mainPhotoUrl);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomInset + 8),
      child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: ClipOval(
                child: imageUrl.isEmpty
                    ? Container(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        alignment: Alignment.center,
                        child: Text(
                          Helpers.getInitials(
                            widget.user.firstName,
                            widget.user.lastName,
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'send_compliment'.tr,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF232129),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'compliment_to_user'.trParams({'name': _displayName}),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.72)
                          : const Color(0xFF6E6979),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'compliment_compose_subtitle'.tr,
          style: GoogleFonts.poppins(
            fontSize: 12.6,
            height: 1.5,
            fontWeight: FontWeight.w500,
            color: isDark
                ? Colors.white.withValues(alpha: 0.8)
                : const Color(0xFF625C70),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _textController,
          focusNode: _focusNode,
          maxLength: _maxLength,
          maxLines: 4,
          minLines: 3,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: 'write_something_nice'.tr,
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : const Color(0xFFF4F0FF),
            contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFEDE9FE),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.2,
              ),
            ),
          ),
          style: GoogleFonts.poppins(
            fontSize: 13.4,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickCompliments()
              .map(
                (item) => ActionChip(
                  onPressed: () => _appendQuick(item),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.35),
                  ),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  label: Text(
                    item,
                    style: GoogleFonts.poppins(
                      fontSize: 11.2,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 10),
        Text(
          'compliment_notification_hint'.trParams({'name': _displayName}),
          style: GoogleFonts.poppins(
            fontSize: 11.2,
            fontWeight: FontWeight.w500,
            color: isDark
                ? Colors.white.withValues(alpha: 0.66)
                : const Color(0xFF7A7488),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'cancel'.tr,
                variant: CustomButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
                height: 48,
                borderRadius: 14,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomButton(
                text: 'compliment_send_cta'.tr,
                onPressed: _textController.text.trim().isEmpty ? null : _submit,
                height: 48,
                borderRadius: 14,
              ),
            ),
          ],
        ),
      ],
    ),
    );
  }
}

class _CardSectionLabel extends StatelessWidget {
  const _CardSectionLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.background,
    required this.textColor,
  });

  final String label;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: background.withValues(alpha: 0.95)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11.8,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

class _SoftTag extends StatelessWidget {
  const _SoftTag({
    required this.label,
    required this.background,
    required this.textColor,
  });

  final String label;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11.6,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

class _ProfileFact {
  const _ProfileFact(this.label, this.value);

  final String label;
  final String value;
}

class _DetailFactsCard extends StatelessWidget {
  const _DetailFactsCard({
    required this.title,
    required this.facts,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.dividerColor,
  });

  final String title;
  final List<_ProfileFact> facts;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    if (facts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(facts.length, (index) {
            final fact = facts[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == facts.length - 1 ? 0 : 8,
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          fact.label,
                          style: GoogleFonts.poppins(
                            fontSize: 12.4,
                            fontWeight: FontWeight.w500,
                            color: secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          fact.value,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.poppins(
                            fontSize: 12.8,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (index != facts.length - 1) ...[
                    const SizedBox(height: 8),
                    Divider(height: 1, thickness: 1, color: dividerColor),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CardPhoto extends StatelessWidget {
  const _CardPhoto({
    required this.user,
    required this.imageUrl,
    this.isLocked = false,
    this.lockReason,
    this.unlockCta,
  });

  final UserModel user;
  final String imageUrl;
  final bool isLocked;
  final String? lockReason;
  final String? unlockCta;

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
      imageUrl,
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
      if (uri == null ||
          uri.host.isEmpty ||
          !(uri.scheme.toLowerCase() == 'http' ||
              uri.scheme.toLowerCase() == 'https')) {
        continue;
      }

      final transformed = CloudinaryUrl.medium(normalized);
      if (transformed.isNotEmpty &&
          transformed != normalized &&
          seen.add(transformed)) {
        results.add(transformed);
      }
      if (seen.add(normalized)) {
        results.add(normalized);
      }
    }

    return results;
  }

  Widget _fallback(bool isDark) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A1520), const Color(0xFF241D28)]
              : [const Color(0xFFF4F0FF), const Color(0xFFEDE9FE)],
        ),
      ),
      child: Center(
        child: Text(
          Helpers.getInitials(user.firstName, user.lastName),
          style: GoogleFonts.poppins(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _placeholder(bool isDark) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1C1520), const Color(0xFF261D28)]
              : [const Color(0xFFFFF5F7), const Color(0xFFEDE9FE)],
        ),
      ),
    );
  }

  List<String> _resolveLockedPreviewUrls() {
    final preview = _normalizePhotoUrl(user.mainPhotoUrl ?? user.fallbackPhotoUrl);
    if (preview.isEmpty) {
      return const <String>[];
    }

    final transformed = CloudinaryUrl.medium(preview);
    if (transformed.isNotEmpty && transformed != preview) {
      return <String>[transformed, preview];
    }
    return <String>[preview];
  }

  Widget _lockedPhotoView(bool isDark) {
    final previewUrls = _resolveLockedPreviewUrls();
    final reasonText = (lockReason ?? '').trim().isNotEmpty
        ? lockReason!.trim()
      : 'Verify your selfie to unlock all photos';
    final ctaText = (unlockCta ?? '').trim().isNotEmpty
        ? unlockCta!.trim()
      : 'Verify selfie now';

    return Stack(
      fit: StackFit.expand,
      children: [
        if (previewUrls.isNotEmpty)
          _HomeResilientCachedImage(
            urls: previewUrls,
            fit: BoxFit.cover,
            fallback: _fallback(isDark),
            placeholder: _placeholder(isDark),
          )
        else
          _placeholder(isDark),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 26),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              color: const Color(0xCC0F1320),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_rounded,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: 28,
                ),
                const SizedBox(height: 10),
                Text(
                  reasonText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Get.toNamed(AppRoutes.verificationCenter),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: const Color(0xFF1C1A26),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    ctaText,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isLocked) {
      return _lockedPhotoView(isDark);
    }

    final imageUrls = _resolvePhotoUrls();

    if (imageUrls.isEmpty) {
      return _fallback(isDark);
    }

    return _HomeResilientCachedImage(
      urls: imageUrls,
      fit: BoxFit.cover,
      fallback: _fallback(isDark),
      placeholder: _placeholder(isDark),
    );
  }
}

class _HomeResilientCachedImage extends StatefulWidget {
  const _HomeResilientCachedImage({
    required this.urls,
    required this.fallback,
    required this.placeholder,
    required this.fit,
  });

  final List<String> urls;
  final Widget fallback;
  final Widget placeholder;
  final BoxFit fit;

  @override
  State<_HomeResilientCachedImage> createState() =>
      _HomeResilientCachedImageState();
}

class _HomeResilientCachedImageState extends State<_HomeResilientCachedImage> {
  int _activeIndex = 0;

  @override
  void didUpdateWidget(covariant _HomeResilientCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    var hasChanged = widget.urls.length != oldWidget.urls.length;
    if (!hasChanged) {
      for (var i = 0; i < widget.urls.length; i++) {
        if (widget.urls[i] != oldWidget.urls[i]) {
          hasChanged = true;
          break;
        }
      }
    }

    if (hasChanged) {
      _activeIndex = 0;
    }
  }

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
      fit: widget.fit,
      placeholder: (context, imageUrl) => widget.placeholder,
      errorWidget: (context, imageUrl, error) {
        _tryNextUrl();
        return safeIndex < widget.urls.length - 1
            ? widget.placeholder
            : widget.fallback;
      },
    );
  }
}

class _LabeledActionButton extends StatelessWidget {
  const _LabeledActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.emphasis = 0,
    this.highlightColor,
    this.labelColor,
    this.showLabel = true,
    this.outerSize = 58,
    this.innerSize = 48,
    this.iconSize = 19,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double emphasis;
  final Color? highlightColor;
  final Color? labelColor;
  final bool showLabel;
  final double outerSize;
  final double innerSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (!showLabel) {
      return Tooltip(
        message: label,
        child: _ActionRingButton(
          icon: icon,
          color: color,
          onTap: onTap,
          emphasis: emphasis,
          highlightColor: highlightColor,
          outerSize: outerSize,
          innerSize: innerSize,
          iconSize: iconSize,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionRingButton(
          icon: icon,
          color: color,
          onTap: onTap,
          emphasis: emphasis,
          highlightColor: highlightColor,
          outerSize: outerSize,
          innerSize: innerSize,
          iconSize: iconSize,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 9.2,
            fontWeight: FontWeight.w600,
            color: labelColor ?? Colors.white.withValues(alpha: 0.96),
            height: 1,
            letterSpacing: 0.15,
          ),
        ),
      ],
    );
  }
}

class _ActionRingButton extends StatelessWidget {
  const _ActionRingButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.emphasis = 0,
    this.highlightColor,
    this.outerSize = 58,
    this.innerSize = 48,
    this.iconSize = 19,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double emphasis;
  final Color? highlightColor;
  final double outerSize;
  final double innerSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final clamped = emphasis.clamp(0.0, 1.0).toDouble();
    final activeColor = highlightColor ?? color;
    final ringExpansion = innerSize * 0.34;
    final iconBoost = icon == LucideIcons.badgeCheck ? 2.0 : 0.0;
    final fillColor = Color.lerp(
      activeColor.withValues(alpha: 0.86),
      activeColor,
      clamped,
    );

    return AnimatedScale(
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeOutCubic,
      scale: 1 + (0.14 * clamped),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: outerSize,
            height: outerSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: innerSize + (ringExpansion * clamped),
                    height: innerSize + (ringExpansion * clamped),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: activeColor.withValues(alpha: 0.45 * clamped),
                        width: 1.0 + (1.5 * clamped),
                      ),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  width: innerSize,
                  height: innerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fillColor,
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: 0.26 + (0.2 * clamped),
                      ),
                      width: 1.05 + (0.55 * clamped),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(
                          alpha: 0.28 + (0.18 * clamped),
                        ),
                        blurRadius: 14 + (10 * clamped),
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: iconSize + iconBoost + (2 * clamped),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusedSwipeActionButton extends StatelessWidget {
  const _FocusedSwipeActionButton({
    required this.icon,
    required this.color,
    required this.emphasis,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final double emphasis;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final clamped = emphasis.clamp(0.0, 1.0).toDouble();
    final outerSize = 84 + (20 * clamped);
    final innerSize = 72 + (14 * clamped);
    final iconSize = 29 + (8 * clamped);

    return SizedBox(
      width: outerSize + 30,
      height: outerSize + 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutQuart,
              width: innerSize + (26 * clamped),
              height: innerSize + (26 * clamped),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.36 + (0.2 * clamped)),
                    color.withValues(alpha: 0),
                  ],
                  stops: const [0.22, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2 + (0.22 * clamped)),
                    blurRadius: 24 + (24 * clamped),
                    spreadRadius: 1 + (6 * clamped),
                  ),
                ],
              ),
            ),
          ),
          _ActionRingButton(
            icon: icon,
            color: color,
            highlightColor: color,
            emphasis: (0.55 + (0.45 * clamped)).clamp(0.0, 1.0).toDouble(),
            outerSize: outerSize,
            innerSize: innerSize,
            iconSize: iconSize,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _BoostBenefitRow extends StatelessWidget {
  const _BoostBenefitRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : const Color(0xFF232129),
            ),
          ),
        ),
      ],
    );
  }
}

class _BoostInfoScreen extends StatefulWidget {
  const _BoostInfoScreen({required this.onActivate});

  final Future<bool> Function() onActivate;

  @override
  State<_BoostInfoScreen> createState() => _BoostInfoScreenState();
}

class _BoostInfoScreenState extends State<_BoostInfoScreen> {
  bool _isActivating = false;

  Future<void> _activateBoost() async {
    if (_isActivating) return;
    setState(() => _isActivating = true);
    final activated = await widget.onActivate();
    if (!mounted) return;
    setState(() => _isActivating = false);
    if (activated) {
      Get.back<void>();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark
            ? AppColors.textPrimaryDark
            : AppColors.textPrimaryLight,
        title: Text(
          'boost_your_profile'.tr,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.boost.withValues(
                    alpha: isDark ? 0.26 : 0.14,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.messageSquare,
                  color: AppColors.boost,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'boost_desc'.tr,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.52,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : const Color(0xFF66626F),
                ),
              ),
              const SizedBox(height: 20),
              _BoostBenefitRow(
                icon: LucideIcons.badgeCheck,
                label: 'boost_benefit_1'.tr,
              ),
              const SizedBox(height: 12),
              _BoostBenefitRow(
                icon: LucideIcons.sparkles,
                label: 'boost_benefit_2'.tr,
              ),
              const SizedBox(height: 12),
              _BoostBenefitRow(
                icon: LucideIcons.eye,
                label: 'boost_benefit_3'.tr,
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'not_now'.tr,
                      onPressed: _isActivating ? null : () => Get.back<void>(),
                      variant: CustomButtonVariant.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'activate_boost'.tr,
                      isLoading: _isActivating,
                      onPressed: _isActivating ? null : _activateBoost,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationGateOverlay extends StatelessWidget {
  const _LocationGateOverlay({required this.onEnable});

  final Future<void> Function() onEnable;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    // Keep CTA controls fully above the floating bottom nav.
    final navClearance = bottomInset > 0 ? bottomInset + 104.0 : 96.0;

    return ColoredBox(
      color: isDark ? const Color(0xFF111218) : AppColors.smoothBeige,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 72, 22, navClearance),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.mapPin,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'location'.tr,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF232129),
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'location_subtitle'.tr,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.55,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.76)
                      : const Color(0xFF706A7A),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'continue'.tr,
                  onPressed: () => onEnable(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeTutorialOverlay extends StatefulWidget {
  const _SwipeTutorialOverlay({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  State<_SwipeTutorialOverlay> createState() => _SwipeTutorialOverlayState();
}

class _SwipeTutorialOverlayState extends State<_SwipeTutorialOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _handController;

  @override
  void initState() {
    super.initState();
    _handController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _handController.dispose();
    super.dispose();
  }

  Offset _handOffset(double t) {
    if (t < 0.34) {
      final progress = t / 0.34;
      return Offset(-72 * progress, 18);
    }
    if (t < 0.68) {
      final progress = (t - 0.34) / 0.34;
      return Offset(-72 + (144 * progress), 18);
    }
    final progress = (t - 0.68) / 0.32;
    return Offset(72 - (72 * progress), 18 - (86 * progress));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      behavior: HitTestBehavior.opaque,
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.62),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 56, 18, 24),
            child: Column(
              children: [
                Text(
                  'swipe_tutorial_title'.tr,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'swipe_tutorial_subtitle'.tr,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 360,
                        maxHeight: 420,
                      ),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final topLine = constraints.maxHeight * 0.34;
                            return Stack(
                              children: [
                                Positioned(
                                  left: constraints.maxWidth / 2 - 0.6,
                                  top: topLine,
                                  bottom: 16,
                                  child: Container(
                                    width: 1.2,
                                    color: Colors.white.withValues(alpha: 0.28),
                                  ),
                                ),
                                Positioned(
                                  left: 16,
                                  right: 16,
                                  top: topLine,
                                  child: Container(
                                    height: 1.2,
                                    color: Colors.white.withValues(alpha: 0.28),
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: _SwipeTutorialTag(
                                      label: 'swipe_tutorial_compliment'.tr,
                                      color: const Color(0xFF6E3DFB),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 14,
                                  right: constraints.maxWidth / 2 + 12,
                                  bottom: 16,
                                  child: Center(
                                    child: _SwipeTutorialTag(
                                      label: 'swipe_tutorial_pass'.tr,
                                      color: const Color(0xFFFF5F7A),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: constraints.maxWidth / 2 + 12,
                                  right: 14,
                                  bottom: 16,
                                  child: Center(
                                    child: _SwipeTutorialTag(
                                      label: 'swipe_tutorial_like'.tr,
                                      color: const Color(0xFF31C48D),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: AnimatedBuilder(
                                    animation: _handController,
                                    builder: (context, _) {
                                      final offset = _handOffset(
                                        _handController.value,
                                      );
                                      return Align(
                                        alignment: const Alignment(0, 0.2),
                                        child: Transform.translate(
                                          offset: offset,
                                          child: Container(
                                            width: 66,
                                            height: 66,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.2,
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: 0.35,
                                                ),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.pan_tool_alt_rounded,
                                              color: Colors.white,
                                              size: 34,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'swipe_tutorial_got_it'.tr,
                    onPressed: widget.onDismiss,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeTutorialTag extends StatelessWidget {
  const _SwipeTutorialTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StartupRadarOverlay extends StatefulWidget {
  const _StartupRadarOverlay({required this.controller});

  final HomeController controller;

  @override
  State<_StartupRadarOverlay> createState() => _StartupRadarOverlayState();
}

class _StartupRadarOverlayState extends State<_StartupRadarOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _sweepController;

  static const List<_StartupRadarOrbitSlot> _orbitSlots = [
    _StartupRadarOrbitSlot(angle: -0.15, radiusFactor: 0.34),
    _StartupRadarOrbitSlot(angle: 0.78, radiusFactor: 0.48),
    _StartupRadarOrbitSlot(angle: 1.58, radiusFactor: 0.36),
    _StartupRadarOrbitSlot(angle: 2.46, radiusFactor: 0.5),
    _StartupRadarOrbitSlot(angle: 3.3, radiusFactor: 0.37),
    _StartupRadarOrbitSlot(angle: 4.2, radiusFactor: 0.5),
    _StartupRadarOrbitSlot(angle: 5.0, radiusFactor: 0.36),
    _StartupRadarOrbitSlot(angle: 5.72, radiusFactor: 0.48),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focusUser =
        widget.controller.currentUser ??
        (widget.controller.discoverUsers.isNotEmpty
            ? widget.controller.discoverUsers.first
            : null);
    final orbitUsers = widget.controller.discoverUsers
        .where((user) => user.id.isNotEmpty)
        .take(_orbitSlots.length)
        .toList(growable: false);

    return ColoredBox(
      color: const Color(0xFF6E3DFB),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _StartupRadarBackdrop(),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                Expanded(
                  flex: 7,
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final radarSize = math.min(
                          constraints.maxWidth * 0.8,
                          constraints.maxHeight * 0.72,
                        );
                        final avatarSize = radarSize * 0.14;

                        return SizedBox(
                          width: radarSize,
                          height: radarSize,
                          child: AnimatedBuilder(
                            animation: Listenable.merge([
                              _pulseController,
                              _sweepController,
                            ]),
                            builder: (context, _) {
                              final phase =
                                  _sweepController.value * math.pi * 2;
                              final outerPulse =
                                  1 + (_pulseController.value * 0.04);
                              final middlePulse =
                                  1 + (_pulseController.value * 0.03);
                              final innerPulse =
                                  1 + (_pulseController.value * 0.02);

                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.scale(
                                    scale: outerPulse,
                                    child: Container(
                                      width: radarSize,
                                      height: radarSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(
                                          alpha: 0.14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: middlePulse,
                                    child: Container(
                                      width: radarSize * 0.72,
                                      height: radarSize * 0.72,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(
                                          alpha: 0.22,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: innerPulse,
                                    child: Container(
                                      width: radarSize * 0.44,
                                      height: radarSize * 0.44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(
                                          alpha: 0.58,
                                        ),
                                      ),
                                    ),
                                  ),
                                  ClipOval(
                                    child: _StartupRadarSweep(
                                      size: radarSize * 0.96,
                                      phase: phase,
                                    ),
                                  ),
                                  for (
                                    var index = 0;
                                    index < _orbitSlots.length;
                                    index++
                                  )
                                    Builder(
                                      builder: (context) {
                                        final slot = _orbitSlots[index];
                                        final user = index < orbitUsers.length
                                            ? orbitUsers[index]
                                            : null;
                                        final orbitAngle =
                                            slot.angle +
                                            phase *
                                                (index.isEven ? 0.06 : -0.06);
                                        final radius =
                                            radarSize * 0.5 * slot.radiusFactor;
                                        final dx =
                                            math.cos(orbitAngle) * radius;
                                        final dy =
                                            math.sin(orbitAngle) * radius;

                                        return Transform.translate(
                                          offset: Offset(dx, dy),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 420,
                                            ),
                                            switchInCurve: Curves.easeOutBack,
                                            switchOutCurve: Curves.easeInBack,
                                            transitionBuilder:
                                                (child, animation) {
                                                  return FadeTransition(
                                                    opacity: animation,
                                                    child: ScaleTransition(
                                                      scale: animation,
                                                      child: child,
                                                    ),
                                                  );
                                                },
                                            child: user == null
                                                ? SizedBox(
                                                    key: ValueKey(
                                                      'empty_orbit_$index',
                                                    ),
                                                    width: avatarSize,
                                                    height: avatarSize,
                                                  )
                                                : _StartupRadarAvatar(
                                                    key: ValueKey(
                                                      'startup_orbit_${user.id}',
                                                    ),
                                                    user: user,
                                                    size: avatarSize,
                                                  ),
                                          ),
                                        );
                                      },
                                    ),
                                  Container(
                                    width: radarSize * 0.24,
                                    height: radarSize * 0.24,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                  _StartupRadarAvatar(
                                    key: ValueKey(
                                      'startup_focus_${focusUser?.id ?? 'me'}',
                                    ),
                                    user: focusUser,
                                    size: radarSize * 0.2,
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'finding_people_nearby'.tr,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  orbitUsers.isEmpty
                      ? 'finding_people_nearby'.tr
                      : '${orbitUsers.length} ${'people_found_nearby'.tr}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: 42),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StartupRadarOrbitSlot {
  const _StartupRadarOrbitSlot({
    required this.angle,
    required this.radiusFactor,
  });

  final double angle;
  final double radiusFactor;
}

class _StartupRadarSweep extends StatelessWidget {
  const _StartupRadarSweep({required this.size, required this.phase});

  final double size;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Transform.rotate(
        angle: phase,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: size * 0.54,
            height: size * 0.54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.34),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(size)),
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupRadarBackdrop extends StatelessWidget {
  const _StartupRadarBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: -80,
            bottom: 120,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartupRadarAvatar extends StatelessWidget {
  const _StartupRadarAvatar({
    super.key,
    required this.user,
    required this.size,
  });

  final UserModel? user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = CloudinaryUrl.medium(user?.mainPhotoUrl ?? '');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl.isEmpty
            ? Container(
                color: const Color(0xFFF4F0FF),
                alignment: Alignment.center,
                child: Text(
                  Helpers.getInitials(user?.firstName, user?.lastName),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (context, imageUrl, error) => Container(
                  color: const Color(0xFFF4F0FF),
                  alignment: Alignment.center,
                  child: Text(
                    Helpers.getInitials(user?.firstName, user?.lastName),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return AnimatedEmptyState(
      lottieAsset: 'discover_no_users',
      title: 'no_profiles_right_now'.tr,
      subtitle: 'refresh_profiles_hint'.tr,
      width: 220,
      contentMaxWidth: 420,
      fallbackColor: AppColors.primary,
      primaryActionLabel: 'refresh'.tr,
      onPrimaryAction: onRefresh,
    );
  }
}
