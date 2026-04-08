import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
import 'package:methna_app/core/widgets/app_card.dart';
import 'package:methna_app/core/widgets/custom_button.dart';
import 'package:methna_app/core/widgets/datify_shell.dart';
import 'package:methna_app/core/widgets/discovery_flow.dart';

class MatchFoundScreen extends StatefulWidget {
  const MatchFoundScreen({super.key});

  @override
  State<MatchFoundScreen> createState() => _MatchFoundScreenState();
}

class _MatchFoundScreenState extends State<MatchFoundScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _confettiCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    _scaleAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
    _slideAnim = Tween(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  Future<void> _openConversation(UserModel matchedUser) async {
    Get.back();

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
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final matchedUser = args?['user'] as UserModel?;
    final currentUser = Get.find<AuthService>().currentUser.value;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: DatifyBackground(
        child: Stack(
          children: [
            Positioned.fill(child: _MatchBackdrop(animation: _pulseCtrl)),
            ..._buildLightParticles(context),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: DiscoveryIconButton(
                        icon: LucideIcons.chevronLeft,
                        onTap: () => Get.back(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: DiscoveryInfoPill(
                        icon: LucideIcons.sparkles,
                        label: 'its_a_match'.tr,
                        color: AppColors.gold,
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Text(
                        'meaningful_connection_opened'.tr,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.displaySmall.copyWith(
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Text(
                        'celebrate_connection_start'.tr,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                    const Spacer(),
                    SlideTransition(
                      position: _slideAnim,
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: AppCard(
                          radius: AppRadii.hero,
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 170,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Positioned(
                                      left: 24,
                                      child: _MatchAvatar(
                                        imageUrl: currentUser?.mainPhotoUrl,
                                        firstName: currentUser?.firstName,
                                        lastName: currentUser?.lastName,
                                        borderColor: AppColors.gold,
                                      ),
                                    ),
                                    Positioned(
                                      right: 24,
                                      child: _MatchAvatar(
                                        imageUrl: matchedUser?.mainPhotoUrl,
                                        firstName: matchedUser?.firstName,
                                        lastName: matchedUser?.lastName,
                                        borderColor: AppColors.like,
                                      ),
                                    ),
                                    ScaleTransition(
                                      scale: _scaleAnim,
                                      child: Container(
                                        width: 68,
                                        height: 68,
                                        decoration: BoxDecoration(
                                          gradient: AppGradients.primary,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.28),
                                              blurRadius: 24,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          LucideIcons.heart,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                '${currentUser?.firstName ?? 'you'.tr} & ${matchedUser?.firstName ?? 'someone'.tr}',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.headlineLarge.copyWith(
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'connection_baraka_message'.tr,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  DiscoveryInfoPill(
                                    icon: LucideIcons.messageCircle,
                                    label: 'chat_unlocked'.tr,
                                    color: AppColors.primary,
                                  ),
                                  if (matchedUser?.selfieVerified == true)
                                    DiscoveryInfoPill(
                                      icon: LucideIcons.badgeCheck,
                                      label: 'verified_profile'.tr,
                                      color: AppColors.gold,
                                    ),
                                  DiscoveryInfoPill(
                                    icon: LucideIcons.sparkles,
                                    label:
                                        matchedUser?.profile?.intentMode ??
                                        'new_connection'.tr,
                                    color: AppColors.like,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    SlideTransition(
                      position: _slideAnim,
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: CustomButton(
                                text: 'send_message'.tr,
                                icon: LucideIcons.messageCircle,
                                onPressed: matchedUser == null
                                    ? null
                                    : () => _openConversation(matchedUser),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SizedBox(
                              width: double.infinity,
                              child: CustomButton(
                                text: 'keep_swiping'.tr,
                                variant: CustomButtonVariant.secondary,
                                onPressed: _continueSwiping,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
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
    );
  }

  List<Widget> _buildLightParticles(BuildContext context) {
    final rng = Random(21);
    return List.generate(16, (index) {
      final left = rng.nextDouble() * MediaQuery.of(context).size.width;
      final delay = rng.nextDouble();
      final size = 4.0 + rng.nextDouble() * 8;
      final color = [
        AppColors.gold,
        AppColors.like,
        AppColors.primaryLight,
      ][index % 3];
      return AnimatedBuilder(
        animation: _confettiCtrl,
        builder: (context, child) {
          final t = (_confettiCtrl.value - delay * 0.25).clamp(0.0, 1.0);
          final startY = MediaQuery.of(context).size.height * 0.72;
          final y = startY - t * (startY + 90);
          final opacity = t < 0.3
              ? t / 0.3
              : (t < 0.75 ? 1.0 : (1.0 - (t - 0.75) / 0.25));

          return Positioned(
            left: left + sin(t * pi * 2) * 14,
            top: y,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.55),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class _MatchBackdrop extends StatelessWidget {
  final Animation<double> animation;

  const _MatchBackdrop({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final pulse = 0.9 + (animation.value * 0.12);
        return Center(
          child: Transform.scale(
            scale: pulse,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.like.withValues(alpha: 0.2),
                    AppColors.primary.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MatchAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? firstName;
  final String? lastName;
  final Color borderColor;

  const _MatchAvatar({
    this.imageUrl,
    this.firstName,
    this.lastName,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 124,
      height: 124,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.22),
            blurRadius: 22,
            spreadRadius: 3,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: ClipOval(
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) =>
                    _AvatarFallback(firstName: firstName, lastName: lastName),
              )
            : _AvatarFallback(firstName: firstName, lastName: lastName),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String? firstName;
  final String? lastName;

  const _AvatarFallback({this.firstName, this.lastName});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primarySurface,
      alignment: Alignment.center,
      child: Text(
        Helpers.getInitials(firstName, lastName),
        style: AppTextStyles.displaySmall.copyWith(color: AppColors.primary),
      ),
    );
  }
}
