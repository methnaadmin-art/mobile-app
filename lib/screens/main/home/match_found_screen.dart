import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:methna_app/app/controllers/chat_controller.dart';
import 'package:methna_app/app/controllers/navigation_controller.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_gradients.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/custom_button.dart';
import 'package:methna_app/core/widgets/datify_shell.dart';

class MatchFoundScreen extends StatefulWidget {
  const MatchFoundScreen({super.key, this.user, this.overlayMode = false});

  final UserModel? user;
  final bool overlayMode;

  static Future<bool> showOverlay(UserModel matchedUser) async {
    final context = Get.overlayContext ?? Get.context;
    if (context == null) {
      debugPrint('[MatchFound] Overlay context missing, cannot present.');
      return false;
    }

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'match_found',
      barrierColor: Colors.black.withValues(alpha: 0.46),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, _, _) =>
          MatchFoundScreen(user: matchedUser, overlayMode: true),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.975, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
    return true;
  }

  @override
  State<MatchFoundScreen> createState() => _MatchFoundScreenState();
}

class _MatchFoundScreenState extends State<MatchFoundScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _haloCtrl;
  late final AnimationController _particleCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    )..forward();
    _haloCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();

    _fadeAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.08, 1, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.12, 1, curve: Curves.easeOutCubic),
          ),
        );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0, 1, curve: Curves.easeOutBack),
      ),
    );
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _haloCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  void _dismissSelf() {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    }
  }

  Future<void> _openConversation(UserModel matchedUser) async {
    _dismissSelf();

    try {
      final chatController = Get.find<ChatController>();
      await chatController.openConversationWithUser(matchedUser);

      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().goToChat();
      }
    } catch (e) {
      debugPrint('[MatchFound] Error opening conversation: $e');
      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().goToChat();
      }
    }
  }

  void _continueSwiping() {
    if (Get.isRegistered<NavigationController>()) {
      Get.find<NavigationController>().goToHome();
    }
    _dismissSelf();
  }

  @override
  Widget build(BuildContext context) {
    final matchedUser = widget.user ?? _matchedUserFromArguments(Get.arguments);
    final currentUser = Get.find<AuthService>().currentUser.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentName = _preferredShortName(currentUser) ?? 'you'.tr;
    final matchedName = _preferredShortName(matchedUser) ?? 'someone'.tr;
    final intentLabel = _bestContextLabel(matchedUser);

    return Scaffold(
      backgroundColor: isDark ? AppColors.canvasDark : AppColors.canvasLight,
      body: DatifyBackground(
        compact: true,
        child: Stack(
          children: [
            Positioned.fill(
              child: _MatchAtmosphere(haloAnimation: _haloCtrl, isDark: isDark),
            ),
            ..._buildCelebrationParticles(context, isDark: isDark),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - AppSpacing.sm,
                      ),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: DatifyBackButton(
                                  onTap: () => Get.back(),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              ScaleTransition(
                                scale: _scaleAnim,
                                child: _MatchHeader(isDark: isDark),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              _MatchHeroCard(
                                currentUser: currentUser,
                                matchedUser: matchedUser,
                                currentName: currentName,
                                matchedName: matchedName,
                                intentLabel: intentLabel,
                                isDark: isDark,
                                scaleAnimation: _scaleAnim,
                              ),
                              SizedBox(
                                height: constraints.maxHeight > 760 ? 30 : 20,
                              ),
                              CustomButton(
                                text: 'send_message'.tr,
                                icon: LucideIcons.messageCircle,
                                onPressed: matchedUser == null
                                    ? null
                                    : () => _openConversation(matchedUser),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              CustomButton(
                                text: 'keep_swiping'.tr,
                                variant: CustomButtonVariant.secondary,
                                onPressed: _continueSwiping,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCelebrationParticles(
    BuildContext context, {
    required bool isDark,
  }) {
    final rng = Random(41);
    final colors = <Color>[
      AppColors.gold,
      AppColors.like,
      AppColors.primaryLight,
    ];

    return List<Widget>.generate(18, (index) {
      final baseLeft = rng.nextDouble() * MediaQuery.of(context).size.width;
      final baseTop = rng.nextDouble() * 220;
      final size = 5 + rng.nextDouble() * 8;
      final color = colors[index % colors.length];
      final delay = rng.nextDouble() * 0.28;

      return AnimatedBuilder(
        animation: _particleCtrl,
        builder: (context, child) {
          final progress = (_particleCtrl.value - delay).clamp(0.0, 1.0);
          final drift = sin(progress * pi * 2) * 14;
          final offsetY = progress * 42;
          final opacity = progress < 0.2
              ? progress / 0.2
              : (progress > 0.85 ? (1 - progress) / 0.15 : 1.0);

          return Positioned(
            left: baseLeft + drift,
            top: baseTop + offsetY,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.52 : 0.42),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class _MatchHeader extends StatelessWidget {
  const _MatchHeader({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: AppColors.goldButtonGradient,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.sparkles, size: 14, color: Colors.white),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'its_a_match'.tr,
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'meaningful_connection_opened'.tr,
          textAlign: TextAlign.center,
          style: AppTextStyles.displaySmall.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'celebrate_connection_start'.tr,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _MatchHeroCard extends StatelessWidget {
  const _MatchHeroCard({
    required this.currentUser,
    required this.matchedUser,
    required this.currentName,
    required this.matchedName,
    required this.intentLabel,
    required this.isDark,
    required this.scaleAnimation,
  });

  final UserModel? currentUser;
  final UserModel? matchedUser;
  final String currentName;
  final String matchedName;
  final String intentLabel;
  final bool isDark;
  final Animation<double> scaleAnimation;

  @override
  Widget build(BuildContext context) {
    final cardGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? <Color>[
              const Color(0xFF4F26D9),
              const Color(0xFF8B5CF6),
              const Color(0xFF4F26D9),
            ]
          : <Color>[
              Colors.white,
              const Color(0xFFF4F0FF),
              const Color(0xFFFFF8F1),
            ],
    );

    return ScaleTransition(
      scale: scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: cardGradient,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.9),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.12),
              blurRadius: 34,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              height: 288,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withValues(
                              alpha: isDark ? 0.18 : 0.12,
                            ),
                            AppColors.like.withValues(
                              alpha: isDark ? 0.1 : 0.08,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Transform.rotate(
                      angle: -0.08,
                      child: _MatchPortraitPanel(
                        imageUrl: currentUser?.mainPhotoUrl,
                        displayName: currentName,
                        caption: currentUser?.profile?.city?.trim(),
                        edgeColor: AppColors.primary,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Transform.rotate(
                      angle: 0.08,
                      child: _MatchPortraitPanel(
                        imageUrl: matchedUser?.mainPhotoUrl,
                        displayName: matchedName,
                        caption: matchedUser?.profile?.city?.trim(),
                        edgeColor: AppColors.like,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  const _HeartBridge(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '$currentName & $matchedName',
              textAlign: TextAlign.center,
              style: AppTextStyles.displaySmall.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'connection_baraka_message'.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                const _MatchMetaChip(
                  icon: LucideIcons.messageCircle,
                  labelKey: 'chat_unlocked',
                  color: AppColors.primary,
                ),
                if (matchedUser?.selfieVerified == true)
                  const _MatchMetaChip(
                    icon: LucideIcons.badgeCheck,
                    labelKey: 'verified_profile',
                    color: AppColors.gold,
                  ),
                if (intentLabel.isNotEmpty)
                  _MatchTextChip(
                    icon: LucideIcons.heartHandshake,
                    label: intentLabel,
                    color: AppColors.like,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchPortraitPanel extends StatelessWidget {
  const _MatchPortraitPanel({
    required this.imageUrl,
    required this.displayName,
    required this.caption,
    required this.edgeColor,
    required this.isDark,
  });

  final String? imageUrl;
  final String displayName;
  final String? caption;
  final Color edgeColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      height: 224,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: edgeColor.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: edgeColor.withValues(alpha: isDark ? 0.26 : 0.18),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl!.trim().isNotEmpty)
              CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _PortraitFallback(
                  displayName: displayName,
                  edgeColor: edgeColor,
                  isDark: isDark,
                ),
              )
            else
              _PortraitFallback(
                displayName: displayName,
                edgeColor: edgeColor,
                isDark: isDark,
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.04),
                      Colors.black.withValues(alpha: 0.64),
                    ],
                    stops: const [0.15, 0.55, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  if (caption != null && caption!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      caption!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortraitFallback extends StatelessWidget {
  const _PortraitFallback({
    required this.displayName,
    required this.edgeColor,
    required this.isDark,
  });

  final String displayName;
  final Color edgeColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            edgeColor.withValues(alpha: 0.88),
            (isDark ? AppColors.secondaryLight : AppColors.primaryLight),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        Helpers.getInitials(displayName, ''),
        style: AppTextStyles.displayMedium.copyWith(color: Colors.white),
      ),
    );
  }
}

class _HeartBridge extends StatelessWidget {
  const _HeartBridge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.like.withValues(alpha: 0.24),
            AppColors.primary.withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          gradient: AppGradients.premium,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
          boxShadow: [
            BoxShadow(
              color: AppColors.like.withValues(alpha: 0.28),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Icon(LucideIcons.heart, color: Colors.white, size: 30),
      ),
    );
  }
}

class _MatchMetaChip extends StatelessWidget {
  const _MatchMetaChip({
    required this.icon,
    required this.labelKey,
    required this.color,
  });

  final IconData icon;
  final String labelKey;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _MatchTextChip(icon: icon, label: labelKey.tr, color: color);
  }
}

class _MatchTextChip extends StatelessWidget {
  const _MatchTextChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppTextStyles.labelMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _MatchAtmosphere extends StatelessWidget {
  const _MatchAtmosphere({required this.haloAnimation, required this.isDark});

  final Animation<double> haloAnimation;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: haloAnimation,
      builder: (context, child) {
        final pulse = 0.92 + (haloAnimation.value * 0.1);
        return Stack(
          children: [
            Center(
              child: Transform.scale(
                scale: pulse,
                child: Container(
                  width: 420,
                  height: 420,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(
                          alpha: isDark ? 0.16 : 0.12,
                        ),
                        AppColors.like.withValues(alpha: isDark ? 0.08 : 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -90,
              right: -50,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: isDark ? 0.14 : 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

String? _preferredShortName(UserModel? user) {
  if (user == null) return null;
  final short = user.publicShortName.trim();
  if (short.isNotEmpty) return short;
  final full = user.publicDisplayName.trim();
  if (full.isNotEmpty) return full;
  return null;
}

UserModel? _matchedUserFromArguments(dynamic args) {
  if (args is UserModel) return args;
  if (args is! Map) return null;

  final map = Map<String, dynamic>.from(args);
  final directUser = map['user'];
  if (directUser is UserModel) return directUser;

  final nested = [
    map['user'],
    map['matchedUser'],
    map['matched_user'],
    map['otherUser'],
    map['other_user'],
  ].whereType<Map>().map((value) => Map<String, dynamic>.from(value));

  for (final candidate in nested) {
    final user = UserModel.fromApiEntry(candidate);
    if (user.id.trim().isNotEmpty) return user;
  }

  final matchedUserId = _firstPayloadString([
    map['matchedUserId'],
    map['matched_user_id'],
    map['userId'],
    map['user_id'],
    map['actorId'],
    map['senderId'],
  ]);
  if (matchedUserId == null) return null;

  final displayName = _firstPayloadString([
    map['matchedUserName'],
    map['matched_user_name'],
    map['displayName'],
    map['name'],
    map['title'],
  ]);

  return UserModel.fromApiEntry({
    'id': matchedUserId,
    'userId': matchedUserId,
    'firstName': displayName ?? 'Someone',
    'email': '',
  });
}

String? _firstPayloadString(List<dynamic> values) {
  for (final value in values) {
    final normalized = value?.toString().trim() ?? '';
    if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
      return normalized;
    }
  }
  return null;
}

String _bestContextLabel(UserModel? user) {
  final raw = user?.profile?.intentMode?.trim() ?? '';
  if (raw.isEmpty) return '';
  final translated = raw.tr;
  if (translated != raw) return translated;
  return raw
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.trim().isNotEmpty)
      .map(
        (word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}
