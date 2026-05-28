import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:methna_app/app/controllers/chat_controller.dart';
import 'package:methna_app/app/controllers/users_controller.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/utils/cloudinary_url.dart';
import 'package:methna_app/core/utils/google_fonts_stub.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/animated_empty_state.dart';

enum _UsersGridCardKind { likedByMe, likedMe, passed, matched }

const Color _usersLuxTone = AppColors.primary;
const Color _usersLuxLightBackground = Color(0xFFFFF5F7);
const Color _usersLuxLightBorder = Color(0xFFEDE9FE);

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  int _selectedTabIndex = 0;
  Worker? _requestedTabWorker;

  UsersController get controller => Get.find<UsersController>();

  int _normalizeTabIndex(int index) => index.clamp(0, 3).toInt();

  int? _parseTabIndex(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  int? _resolveInitialTabIndex(dynamic args) {
    if (args is! Map) return null;
    final map = Map<String, dynamic>.from(args);
    return _parseTabIndex(
      map['usersTabIndex'] ?? map['users_tab_index'] ?? map['initialUsersTab'],
    );
  }

  String _sourceTabKeyForIndex(int index) {
    switch (index) {
      case 0:
        return 'liked_by_me';
      case 1:
        return 'liked_me';
      case 2:
        return 'passed';
      case 3:
        return 'matched';
      default:
        return 'liked_by_me';
    }
  }

  void _applyTabSelection(int index, {bool forceRefresh = false}) {
    final normalized = _normalizeTabIndex(index);
    final changed = normalized != _selectedTabIndex;
    if (changed) {
      setState(() => _selectedTabIndex = normalized);
    }
    unawaited(
      controller.ensureUsersTabData(
        force: forceRefresh || changed,
        tabIndex: normalized,
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    final initialFromArgs = _resolveInitialTabIndex(Get.arguments);
    final requestedFromController = controller.requestedUsersTabIndex.value;
    final initialTab = initialFromArgs ?? requestedFromController;
    if (initialTab != null) {
      _selectedTabIndex = _normalizeTabIndex(initialTab);
      controller.clearRequestedUsersTab();
    }

    _requestedTabWorker = ever<int?>(controller.requestedUsersTabIndex, (
      requestedTab,
    ) {
      if (!mounted || requestedTab == null) return;
      controller.clearRequestedUsersTab();
      _applyTabSelection(requestedTab, forceRefresh: true);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        controller.ensureUsersTabData(
          force: true,
          tabIndex: _selectedTabIndex,
        ),
      );
    });
  }

  @override
  void dispose() {
    _requestedTabWorker?.dispose();
    super.dispose();
  }

  Future<void> _refreshCurrentTab() async {
    switch (_selectedTabIndex) {
      case 0:
        await controller.ensureUsersTabData(force: true, tabIndex: 0);
        return;
      case 1:
        await controller.ensureUsersTabData(force: true, tabIndex: 1);
        return;
      case 2:
        await controller.ensureUsersTabData(force: true, tabIndex: 2);
        return;
      case 3:
        await controller.ensureUsersTabData(force: true, tabIndex: 3);
        return;
      default:
        await controller.ensureUsersTabData(force: true, tabIndex: 0);
    }
  }

  List<UserModel> _uniqueUsers(Iterable<UserModel> input) {
    final seen = <String>{};
    final list = <UserModel>[];
    for (final user in input) {
      if (user.id.isEmpty || !seen.add(user.id)) continue;
      list.add(user);
    }
    return list;
  }

  DateTime? _interactionAt(UserModel user) {
    final fromCache = controller.interactionDateFor(user.id);
    if (_selectedTabIndex != 1) {
      return fromCache ?? user.lastLoginAt;
    }

    for (final item in controller.likesReceived) {
      if (item.user.id == user.id) {
        return item.createdAt ?? fromCache ?? item.user.lastLoginAt;
      }
    }
    return fromCache ?? user.lastLoginAt;
  }

  _UsersGridCardKind _tabKind() {
    switch (_selectedTabIndex) {
      case 0:
        return _UsersGridCardKind.likedByMe;
      case 1:
        return _UsersGridCardKind.likedMe;
      case 2:
        return _UsersGridCardKind.passed;
      case 3:
        return _UsersGridCardKind.matched;
      default:
        return _UsersGridCardKind.likedByMe;
    }
  }

  String _emptyTitle() {
    switch (_selectedTabIndex) {
      case 0:
        return 'no_liked_users_yet'.tr;
      case 1:
        return 'no_who_liked_me_yet'.tr;
      case 2:
        return 'no_passed_users_yet'.tr;
      case 3:
        return 'no_matched_users_yet'.tr;
      default:
        return 'no_profiles_right_now'.tr;
    }
  }

  String _emptySubtitle() {
    switch (_selectedTabIndex) {
      case 0:
        return 'no_liked_users_subtitle'.tr;
      case 1:
        return 'no_who_liked_me_subtitle'.tr;
      case 2:
        return 'no_passed_users_subtitle'.tr;
      case 3:
        return 'no_matched_users_subtitle'.tr;
      default:
        return 'refresh_profiles_hint'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF111218)
          : _usersLuxLightBackground,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final matched = _uniqueUsers(controller.matches);
          final matchedIds = matched.map((user) => user.id).toSet();
          final likedByMe = _uniqueUsers(
            controller.likedUsers.where(
              (user) => !matchedIds.contains(user.id),
            ),
          );
          final passedIds = controller.passedUsers
              .map((user) => user.id)
              .toSet();
          final likedMe = _uniqueUsers(
            controller.likesReceived
                .map((item) => item.user)
                .where(
                  (user) =>
                      !matchedIds.contains(user.id) &&
                      !passedIds.contains(user.id),
                ),
          );
          final likedMeIds = likedMe.map((user) => user.id).toSet();
          final passed = _uniqueUsers(
            controller.passedUsers.where(
              (user) =>
                  !matchedIds.contains(user.id) &&
                  !likedMeIds.contains(user.id),
            ),
          );

          final visibleUsers = switch (_selectedTabIndex) {
            1 => likedMe,
            2 => passed,
            3 => matched,
            _ => likedByMe,
          };

          final monetization = Get.isRegistered<MonetizationService>()
              ? Get.find<MonetizationService>()
              : null;
          final hasWhoLikedMeAccess = controller.whoLikedMeRequiresPremium.value
              ? (monetization?.hasWhoLikedMeAccess ??
                    false)
              : true;

          final tabs = [
            _UsersTabItem(
              label: 'person_i_liked'.tr,
              count: likedByMe.length,
              icon: LucideIcons.heart,
              tone: _usersLuxTone,
            ),
            _UsersTabItem(
              label: 'who_liked_me'.tr,
              count: likedMe.length,
              icon: LucideIcons.badgeCheck,
              tone: _usersLuxTone,
            ),
            _UsersTabItem(
              label: 'swipe_status_pass'.tr,
              count: passed.length,
              icon: LucideIcons.x,
              tone: _usersLuxTone,
            ),
            _UsersTabItem(
              label: 'matches'.tr,
              count: matched.length,
              icon: LucideIcons.sparkles,
              tone: _usersLuxTone,
            ),
          ];

          final isInitialLoading = switch (_selectedTabIndex) {
            1 => controller.isLoadingWhoLikedMe.value && visibleUsers.isEmpty,
            3 => controller.isLoadingMatches.value && visibleUsers.isEmpty,
            _ => controller.isLoadingInteractions.value && visibleUsers.isEmpty,
          };

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  8,
                  AppSpacing.lg,
                  0,
                ),
                child: _UsersOverviewHeader(
                  isDark: isDark,
                  title: tabs[_selectedTabIndex].label,
                  count: visibleUsers.length,
                  icon: tabs[_selectedTabIndex].icon,
                  tone: tabs[_selectedTabIndex].tone,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  10,
                  AppSpacing.lg,
                  0,
                ),
                child: _InteractionTabs(
                  items: tabs,
                  selectedIndex: _selectedTabIndex,
                  onChanged: (index) => _applyTabSelection(index),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _refreshCurrentTab,
                  child: visibleUsers.isEmpty
                      ? (isInitialLoading
                            ? const _MatchesGridLoading()
                            : _MatchesEmptyScrollView(
                                title: _emptyTitle(),
                                subtitle: _emptySubtitle(),
                                onRefresh: _refreshCurrentTab,
                              ))
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            120,
                          ),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.66,
                              ),
                          itemCount: visibleUsers.length,
                          itemBuilder: (context, index) {
                            final selectedUser = visibleUsers[index];
                            final isLikedByMeTab = _selectedTabIndex == 0;
                            final isLikedMeTab = _selectedTabIndex == 1;
                            final isPassedTab = _selectedTabIndex == 2;
                            final shouldBlurWhoLikedMeCard =
                                isLikedMeTab &&
                                !hasWhoLikedMeAccess;

                            Future<void> Function()? quickAction;
                            String? quickActionLabel;
                            IconData? quickActionIcon;
                            Color quickActionTone = _usersLuxTone;

                            if (isLikedByMeTab) {
                              quickAction = () =>
                                  controller.passUser(selectedUser.id);
                              quickActionLabel = 'Pass';
                              quickActionIcon = LucideIcons.x;
                              quickActionTone = const Color(0xFFFF6B6B);
                            } else if (isPassedTab) {
                              quickAction = () =>
                                  controller.likeUser(selectedUser.id);
                              quickActionLabel = 'Like';
                              quickActionIcon = LucideIcons.heart;
                              quickActionTone = _usersLuxTone;
                            } else if (_selectedTabIndex == 3) {
                              quickAction = () async {
                                await Get.find<ChatController>()
                                    .openConversationWithUser(selectedUser);
                              };
                              quickActionLabel = 'message'.tr;
                              quickActionIcon = LucideIcons.messageCircle;
                              quickActionTone = const Color(0xFF22A06B);
                            }

                            return _MatchGridCard(
                              user: selectedUser,
                              interactionAt: _interactionAt(selectedUser),
                              cardKind: _tabKind(),
                              isBlurred: shouldBlurWhoLikedMeCard,
                              quickActionLabel: quickActionLabel,
                              quickActionIcon: quickActionIcon,
                              quickActionTone: quickActionTone,
                              isQuickActionEnabled:
                                  !controller.isSwipeInFlight(selectedUser.id),
                              onQuickAction: quickAction,
                              onBlurCtaTap: shouldBlurWhoLikedMeCard
                                  ? () => Get.toNamed(AppRoutes.subscription)
                                  : null,
                              onTap: () {
                                if (controller.isLockedLikedMePlaceholder(
                                  selectedUser.id,
                                )) {
                                  Get.toNamed(AppRoutes.subscription);
                                  return;
                                }

                                if (_selectedTabIndex == 3) {
                                  controller.openUserDetailById(
                                    selectedUser.id,
                                    fallbackUser: selectedUser,
                                    showLoader: false,
                                    sourceTab: _sourceTabKeyForIndex(
                                      _selectedTabIndex,
                                    ),
                                  );
                                  return;
                                }

                                if (shouldBlurWhoLikedMeCard) {
                                  Get.toNamed(AppRoutes.subscription);
                                  return;
                                }

                                controller.openUserDetail(
                                  selectedUser,
                                  sourceTab: _sourceTabKeyForIndex(
                                    _selectedTabIndex,
                                  ),
                                );
                              },
                            );
                          },
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

class _UsersTabItem {
  const _UsersTabItem({
    required this.label,
    required this.count,
    required this.icon,
    required this.tone,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color tone;
}

class _UsersOverviewHeader extends StatelessWidget {
  const _UsersOverviewHeader({
    required this.isDark,
    required this.title,
    required this.count,
    required this.icon,
    required this.tone,
  });

  final bool isDark;
  final String title;
  final int count;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF171020), Color(0xFF24183C)]
              : const [Colors.white, Color(0xFFF4F0FF)],
        ),
        border: Border.all(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.26)
              : _usersLuxLightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.1),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 19, color: tone),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'profiles'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.labelMedium.copyWith(
                color: tone,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractionTabs extends StatelessWidget {
  const _InteractionTabs({
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<_UsersTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: isRtl,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final item = items[index];
          final selected = index == selectedIndex;
          final activeColor = item.tone;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onChanged(index),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: selected
                      ? activeColor.withValues(alpha: 0.16)
                      : (isDark ? const Color(0xFF191F2D) : Colors.white),
                  border: Border.all(
                    color: selected
                        ? activeColor.withValues(alpha: 0.56)
                        : (isDark
                              ? const Color(0xFF2B3344)
                              : _usersLuxLightBorder),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 14,
                      color: selected
                          ? activeColor
                          : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                    ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 108),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: selected
                              ? activeColor
                              : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                        ),
                      ),
                    ),
                    if (item.count > 0) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? activeColor.withValues(alpha: 0.2)
                              : (isDark
                                    ? const Color(0xFF232D3E)
                                    : AppColors.primary.withValues(
                                        alpha: 0.08,
                                      )),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${item.count}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: selected
                                ? activeColor
                                : (isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: items.length,
      ),
    );
  }
}

class _MatchesGridLoading extends StatelessWidget {
  const _MatchesGridLoading();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.705,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const _MatchCardPlaceholder(),
    );
  }
}

class _MatchesEmptyScrollView extends StatelessWidget {
  const _MatchesEmptyScrollView({
    required this.title,
    required this.subtitle,
    required this.onRefresh,
  });

  final String title;
  final String subtitle;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 48, 18, 120),
      children: [
        _MatchesEmptyState(
          title: title,
          subtitle: subtitle,
          onRefresh: onRefresh,
        ),
      ],
    );
  }
}

class _MatchGridCard extends StatelessWidget {
  const _MatchGridCard({
    required this.user,
    required this.cardKind,
    required this.interactionAt,
    required this.onTap,
    this.isBlurred = false,
    this.onBlurCtaTap,
    this.quickActionLabel,
    this.quickActionIcon,
    this.quickActionTone = _usersLuxTone,
    this.isQuickActionEnabled = true,
    this.onQuickAction,
  });

  final UserModel user;
  final _UsersGridCardKind cardKind;
  final DateTime? interactionAt;
  final VoidCallback onTap;
  final bool isBlurred;
  final VoidCallback? onBlurCtaTap;
  final String? quickActionLabel;
  final IconData? quickActionIcon;
  final Color quickActionTone;
  final bool isQuickActionEnabled;
  final Future<void> Function()? onQuickAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _title(user);
    final job = _jobLine(user);
    final identity = _identityLine(user);
    final locationAndTime =
        '${_locationLine(user)} • ${_timeAgo(interactionAt)}';
    final isVerified = _isVerifiedUser(user);
    final isPremium = user.isPremium;
    final statusTone = _statusTone(cardKind);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.28)
                : _usersLuxLightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _MatchCardPhoto(user: user),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x04000000),
                      Color(0x22000000),
                      Color(0x90000000),
                      Color(0xE4000000),
                    ],
                    stops: [0.0, 0.4, 0.74, 1.0],
                  ),
                ),
              ),
              PositionedDirectional(
                top: 10,
                start: 10,
                child: _MiniGlassBadge(
                  iconText: _countryFlag(user.profile?.country),
                  tint: statusTone,
                ),
              ),
              PositionedDirectional(
                top: 10,
                end: 10,
                child: _MiniGlassBadge(
                  icon: _statusIcon(cardKind),
                  tint: statusTone,
                ),
              ),
              PositionedDirectional(
                start: 12,
                end: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.35,
                              textStyle: const TextStyle(
                                shadows: [
                                  Shadow(
                                    color: Color(0xAA000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (isPremium) ...[
                          const SizedBox(width: 6),
                          Icon(
                            LucideIcons.crown,
                            size: 15,
                            color: const Color(0xFFA78BFA),
                            shadows: const [
                              Shadow(
                                color: Color(0x99000000),
                                blurRadius: 7,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ],
                        if (isVerified) ...[
                          const SizedBox(width: 6),
                          Icon(
                            LucideIcons.badgeCheck,
                            size: 15,
                            color: statusTone,
                            shadows: const [
                              Shadow(
                                color: Color(0x99000000),
                                blurRadius: 7,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    if (job.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        job,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12.4,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                          textStyle: const TextStyle(
                            shadows: [
                              Shadow(
                                color: Color(0x99000000),
                                blurRadius: 6,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (identity.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        identity,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11.2,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.86),
                          textStyle: const TextStyle(
                            shadows: [
                              Shadow(
                                color: Color(0x8A000000),
                                blurRadius: 6,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 1),
                    Text(
                      locationAndTime,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10.6,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.82),
                        textStyle: const TextStyle(
                          shadows: [
                            Shadow(
                              color: Color(0x84000000),
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (quickActionLabel != null && onQuickAction != null) ...[
                      const SizedBox(height: 7),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: _CardQuickActionButton(
                          label: quickActionLabel!,
                          icon: quickActionIcon,
                          tone: quickActionTone,
                          enabled: isQuickActionEnabled,
                          onPressed: onQuickAction,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isBlurred)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.26),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (isBlurred)
                Positioned.fill(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.lock,
                          size: 32,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed:
                              onBlurCtaTap ??
                              () => Get.toNamed(AppRoutes.subscription),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: const Color(0xFF1C1A26),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'upgrade_to_premium'.tr,
                            style: GoogleFonts.poppins(
                              fontSize: 11.2,
                              fontWeight: FontWeight.w700,
                            ),
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
    );
  }
}

class _CardQuickActionButton extends StatelessWidget {
  const _CardQuickActionButton({
    required this.label,
    required this.tone,
    required this.enabled,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final Color tone;
  final bool enabled;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final textColor = enabled
        ? Colors.white
        : Colors.white.withValues(alpha: 0.7);

    return Opacity(
      opacity: enabled ? 1 : 0.72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: !enabled || onPressed == null
              ? null
              : () {
                  unawaited(onPressed!());
                },
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: tone.withValues(alpha: 0.9),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 12.5, color: textColor),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11.2,
                    fontWeight: FontWeight.w700,
                    color: textColor,
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

class _MiniGlassBadge extends StatelessWidget {
  const _MiniGlassBadge({this.icon, this.iconText, required this.tint});

  final IconData? icon;
  final String? iconText;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.74)),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 14, color: tint)
            : Text(iconText ?? '🏳️', style: const TextStyle(fontSize: 12.5)),
      ),
    );
  }
}

class _MatchCardPhoto extends StatefulWidget {
  const _MatchCardPhoto({required this.user});

  final UserModel user;

  @override
  State<_MatchCardPhoto> createState() => _MatchCardPhotoState();
}

class _MatchCardPhotoState extends State<_MatchCardPhoto> {
  late final PageController _pageController;
  int _activePage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
    if (lower.isEmpty ||
        lower == 'null' ||
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
      widget.user.mainPhotoUrl,
      widget.user.fallbackPhotoUrl,
      ...(widget.user.photos ?? const <PhotoModel>[])
          .where((photo) => !photo.isLocked)
          .map((photo) => photo.url),
    ];

    for (final candidate in candidates) {
      final normalized = _normalizePhotoUrl(candidate);
      if (normalized.isEmpty) {
        continue;
      }

      final uri = Uri.tryParse(normalized);
      if (uri != null &&
          (uri.scheme.toLowerCase() == 'http' ||
              uri.scheme.toLowerCase() == 'https') &&
          uri.host.isNotEmpty) {
        final transformed = CloudinaryUrl.medium(normalized);
        if (transformed.isNotEmpty && seen.add(transformed)) {
          results.add(transformed);
        }

        if (seen.add(normalized)) {
          results.add(normalized);
        }
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrls = _resolvePhotoUrls();

    if (imageUrls.isEmpty) {
      return _MatchCardFallback(user: widget.user);
    }

    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1D2230), Color(0xFF2A3144)]
              : const [Color(0xFFF4F0FF), Color(0xFFEDE9FE)],
        ),
      ),
    );

    if (imageUrls.length == 1) {
      return _ResilientCachedImage(
        urls: imageUrls,
        fit: BoxFit.cover,
        fallback: _MatchCardFallback(user: widget.user),
        placeholder: placeholder,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: imageUrls.length,
          onPageChanged: (index) {
            if (!mounted) return;
            setState(() => _activePage = index);
          },
          itemBuilder: (context, index) {
            final url = imageUrls[index];
            return CachedNetworkImage(
              key: ValueKey<String>(url),
              imageUrl: CloudinaryUrl.medium(url),
              fit: BoxFit.cover,
              placeholder: (context, imageUrl) => placeholder,
              errorWidget: (context, imageUrl, error) =>
                  _MatchCardFallback(user: widget.user),
            );
          },
        ),
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(imageUrls.length, (index) {
              final isActive = index == _activePage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _ResilientCachedImage extends StatefulWidget {
  const _ResilientCachedImage({
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
  State<_ResilientCachedImage> createState() => _ResilientCachedImageState();
}

class _ResilientCachedImageState extends State<_ResilientCachedImage> {
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

class _MatchCardFallback extends StatelessWidget {
  const _MatchCardFallback({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1C2230), Color(0xFF2B3347)]
              : const [Color(0xFFF4F0FF), Color(0xFFEDE9FE)],
        ),
      ),
      child: Center(
        child: Text(
          Helpers.getInitials(user.firstName, user.lastName),
          style: GoogleFonts.poppins(
            fontSize: 54,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _MatchCardPlaceholder extends StatelessWidget {
  const _MatchCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF1A202D), Color(0xFF283044)]
                : const [Color(0xFFF4F0FF), Color(0xFFEDE9FE)],
          ),
        ),
      ),
    );
  }
}

class _MatchesEmptyState extends StatelessWidget {
  const _MatchesEmptyState({
    required this.title,
    required this.subtitle,
    required this.onRefresh,
  });

  final String title;
  final String subtitle;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return AnimatedEmptyState(
      lottieAsset: 'assets/animations/no_matches.json',
      title: title,
      subtitle: subtitle,
      fallbackIcon: LucideIcons.heart,
      fallbackColor: AppColors.primary,
      primaryActionLabel: 'refresh'.tr,
      onPrimaryAction: () => onRefresh(),
      width: 188,
    );
  }
}

String _title(UserModel user) {
  final name = _safeDisplayName(user);
  final age = user.profile?.showAge == false ? null : user.age;
  return age != null && age > 0 ? '$name ($age)' : name;
}

String _safeDisplayName(UserModel user) {
  final first = (user.firstName ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
  final last = (user.lastName ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();

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
  return fallback.isNotEmpty ? fallback : 'profile'.tr;
}

IconData _statusIcon(_UsersGridCardKind kind) {
  switch (kind) {
    case _UsersGridCardKind.likedByMe:
      return LucideIcons.heart;
    case _UsersGridCardKind.likedMe:
      return LucideIcons.badgeCheck;
    case _UsersGridCardKind.passed:
      return LucideIcons.x;
    case _UsersGridCardKind.matched:
      return LucideIcons.sparkles;
  }
}

Color _statusTone(_UsersGridCardKind kind) {
  switch (kind) {
    case _UsersGridCardKind.likedByMe:
      return _usersLuxTone;
    case _UsersGridCardKind.likedMe:
      return _usersLuxTone;
    case _UsersGridCardKind.passed:
      return _usersLuxTone;
    case _UsersGridCardKind.matched:
      return _usersLuxTone;
  }
}

String _jobLine(UserModel user) {
  final raw = user.profile?.jobTitle?.trim() ?? '';
  if (raw.isEmpty) return '';
  return raw;
}

String _identityLine(UserModel user) {
  final profile = user.profile;
  final nationality = profile?.nationality?.trim() ?? '';
  final ethnicity = profile?.ethnicity?.trim() ?? '';
  final merged = [
    nationality,
    ethnicity,
  ].where((item) => item.isNotEmpty).join(' ').trim();
  return merged;
}

bool _isVerifiedUser(UserModel user) {
  return user.documentVerified;
}

String _locationLine(UserModel user) {
  final profile = user.profile;
  final city = profile?.city?.trim() ?? '';
  final country = profile?.country?.trim() ?? '';
  final merged = [city, country].where((item) => item.isNotEmpty).join(', ');
  if (merged.isNotEmpty) return merged;
  return 'nearby'.tr;
}

String _countryFlag(String? countryRaw) {
  final country = (countryRaw ?? '').toLowerCase();
  if (country.contains('united kingdom') ||
      country.contains('uk') ||
      country.contains('brit')) {
    return '🇬🇧';
  }
  if (country.contains('alger')) return '🇩🇿';
  if (country.contains('morocco')) return '🇲🇦';
  if (country.contains('tunisia')) return '🇹🇳';
  if (country.contains('egypt')) return '🇪🇬';
  if (country.contains('jordan')) return '🇯🇴';
  if (country.contains('saudi')) return '🇸🇦';
  if (country.contains('uae') || country.contains('emirates')) return '🇦🇪';
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
  return '🏳️';
}

String _timeAgo(DateTime? timestamp) {
  if (timestamp == null) {
    return 'just_now'.tr;
  }

  final diff = DateTime.now().difference(timestamp);
  if (diff.inMinutes < 1) return 'just_now'.tr;
  if (diff.inMinutes < 60) {
    return 'minutes_ago'.trParams({'count': '${diff.inMinutes}'});
  }
  if (diff.inHours < 24) {
    return 'hours_ago'.trParams({'count': '${diff.inHours}'});
  }
  if (diff.inDays < 7) {
    return 'days_ago'.trParams({'count': '${diff.inDays}'});
  }
  return 'weeks_ago'.trParams({'count': '${(diff.inDays / 7).floor()}'});
}
