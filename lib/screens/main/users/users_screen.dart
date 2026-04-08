import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/users_controller.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/utils/cloudinary_url.dart';
import 'package:methna_app/core/utils/google_fonts_stub.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/animated_empty_state.dart';

enum _UsersGridCardKind { likedByMe, likedMe, passed, matched }

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  int _selectedTabIndex = 0;

  UsersController get controller => Get.find<UsersController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(controller.fetchInteractions());
      unawaited(controller.fetchWhoLikedMe());
      unawaited(controller.fetchMatches());
    });
  }

  Future<void> _refreshCurrentTab() async {
    switch (_selectedTabIndex) {
      case 0:
        await controller.fetchInteractions();
        return;
      case 1:
        await controller.refreshWhoLikedMe();
        return;
      case 2:
        await controller.fetchInteractions();
        return;
      case 3:
        await controller.fetchMatches();
        return;
      default:
        await controller.fetchInteractions();
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
      backgroundColor: isDark ? const Color(0xFF111218) : Colors.white,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final likedByMe = _uniqueUsers(controller.likedUsers);
          final likedMe = _uniqueUsers(
            controller.likesReceived.map((item) => item.user),
          );
          final passed = _uniqueUsers(controller.passedUsers);
          final matched = _uniqueUsers(controller.matches);

          final visibleUsers = switch (_selectedTabIndex) {
            1 => likedMe,
            2 => passed,
            3 => matched,
            _ => likedByMe,
          };

          final tabs = [
            _UsersTabItem(label: 'person_i_liked'.tr, count: likedByMe.length),
            _UsersTabItem(label: 'who_liked_me'.tr, count: likedMe.length),
            _UsersTabItem(label: 'swipe_status_pass'.tr, count: passed.length),
            _UsersTabItem(label: 'matches'.tr, count: matched.length),
          ];

          final isInitialLoading =
              (controller.isLoadingWhoLikedMe.value ||
                  controller.isLoading.value) &&
              visibleUsers.isEmpty;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
                child: _InteractionTabs(
                  items: tabs,
                  selectedIndex: _selectedTabIndex,
                  onChanged: (index) {
                    setState(() => _selectedTabIndex = index);
                    if (index == 1 && controller.likesReceived.isEmpty) {
                      unawaited(controller.fetchWhoLikedMe());
                    } else if ((index == 0 || index == 2) &&
                        controller.likedUsers.isEmpty &&
                        controller.passedUsers.isEmpty) {
                      unawaited(controller.fetchInteractions());
                    } else if (index == 3 && controller.matches.isEmpty) {
                      unawaited(controller.fetchMatches());
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _refreshCurrentTab,
                  child: isInitialLoading
                      ? const _MatchesGridLoading()
                      : visibleUsers.isEmpty
                      ? _MatchesEmptyScrollView(
                          title: _emptyTitle(),
                          subtitle: _emptySubtitle(),
                          onRefresh: _refreshCurrentTab,
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
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
                            return _MatchGridCard(
                              user: selectedUser,
                              interactionAt: _interactionAt(selectedUser),
                              cardKind: _tabKind(),
                              onTap: () {
                                if (_selectedTabIndex == 3) {
                                  controller.openUserDetailById(
                                    selectedUser.id,
                                    fallbackUser: selectedUser,
                                  );
                                  return;
                                }
                                controller.openUserDetail(selectedUser);
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
  const _UsersTabItem({required this.label, required this.count});

  final String label;
  final int count;
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
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: isRtl,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final item = items[index];
          final selected = index == selectedIndex;
          final activeColor = const Color(0xFFEC4D8F);
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onChanged(index),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(4, 2, 4, 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${item.label} ${item.count > 0 ? item.count : ''}'
                          .trim(),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? activeColor
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.78)
                                  : const Color(0xFF7B7F86)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      width: selected ? 54 : 0,
                      height: 2.6,
                      decoration: BoxDecoration(
                        color: activeColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 12),
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
  });

  final UserModel user;
  final _UsersGridCardKind cardKind;
  final DateTime? interactionAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _title(user);
    final job = _jobLine(user);
    final identity = _identityLine(user);
    final locationAndTime = '${_locationLine(user)} • ${_timeAgo(interactionAt)}';
    final isVerified = _isVerifiedUser(user);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2E3441) : const Color(0xFFE8E8ED),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.1),
              blurRadius: isDark ? 16 : 12,
              offset: const Offset(0, 6),
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
                ),
              ),
              PositionedDirectional(
                top: 10,
                end: 10,
                child: _MiniGlassBadge(icon: _statusIcon(cardKind)),
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
                        if (isVerified) ...[
                          const SizedBox(width: 6),
                          Icon(
                            LucideIcons.badgeCheck,
                            size: 15,
                            color: const Color(0xFF7DC4FF),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniGlassBadge extends StatelessWidget {
  const _MiniGlassBadge({this.icon, this.iconText});

  final IconData? icon;
  final String? iconText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 14, color: Colors.white)
            : Text(iconText ?? '🏳️', style: const TextStyle(fontSize: 12.5)),
      ),
    );
  }
}

class _MatchCardPhoto extends StatelessWidget {
  const _MatchCardPhoto({required this.user});

  final UserModel user;

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

    value = value
        .replaceAll('\\', '/');

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
      if (normalized.isEmpty) {
        continue;
      }

      final uri = Uri.tryParse(normalized);
      if (uri != null &&
          (uri.scheme.toLowerCase() == 'http' ||
              uri.scheme.toLowerCase() == 'https') &&
          uri.host.isNotEmpty) {
        if (seen.add(normalized)) {
          results.add(normalized);
        }

        // Try Cloudinary-optimized URL as a fallback, not as the only source.
        final transformed = CloudinaryUrl.medium(normalized);
        if (transformed.isNotEmpty && seen.add(transformed)) {
          results.add(transformed);
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
      return _MatchCardFallback(user: user);
    }

    return _ResilientCachedImage(
      urls: imageUrls,
      fit: BoxFit.cover,
      fallback: _MatchCardFallback(user: user),
      placeholder: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF1D2230), Color(0xFF2A3144)]
                : const [Color(0xFFF7ECFF), Color(0xFFEAE4FF)],
          ),
        ),
      ),
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
              : const [Color(0xFFF7ECFF), Color(0xFFEAE4FF)],
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
                : const [Color(0xFFF8F2FF), Color(0xFFEEE9FF)],
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
  final name = (user.firstName?.trim().isNotEmpty == true)
      ? user.firstName!.trim()
      : (user.displayName.trim().isNotEmpty
            ? user.displayName.trim()
            : 'profile'.tr);
  final age = user.profile?.showAge == false ? null : user.age;
  return age != null && age > 0 ? '$name ($age)' : name;
}

IconData _statusIcon(_UsersGridCardKind kind) {
  switch (kind) {
    case _UsersGridCardKind.likedByMe:
      return LucideIcons.heart;
    case _UsersGridCardKind.likedMe:
      return LucideIcons.heart;
    case _UsersGridCardKind.passed:
      return LucideIcons.x;
    case _UsersGridCardKind.matched:
      return LucideIcons.sparkles;
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
  return user.selfieVerified || user.documentVerified;
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
