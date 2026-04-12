import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../app/controllers/users_controller.dart';
import '../../../app/data/models/user_model.dart';
import '../../../core/theme/premium_theme.dart';
import 'package:methna_app/core/utils/cloudinary_url.dart';
import 'package:methna_app/core/widgets/animated_empty_state.dart';

/// Premium Tinder-style Swipe Cards Screen
class PremiumSwipeCardsScreen extends StatefulWidget {
  const PremiumSwipeCardsScreen({super.key});

  @override
  State<PremiumSwipeCardsScreen> createState() =>
      _PremiumSwipeCardsScreenState();
}

class _PremiumSwipeCardsScreenState extends State<PremiumSwipeCardsScreen> {
  final UsersController controller = Get.find<UsersController>();
  final CardSwiperController _swiperController = CardSwiperController();
  String? _queuedComplimentMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Obx(() {
        if (controller.isLoading.value && controller.allUsers.isEmpty) {
          return const _LoadingState();
        }

        if (controller.allUsers.isEmpty) {
          return const _EmptyState();
        }

        return Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.3),
                    AppTheme.background,
                  ],
                ),
              ),
            ),

            // Swiper
            SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),

                  // Cards
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: CardSwiper(
                        controller: _swiperController,
                        cardsCount: controller.allUsers.length,
                        numberOfCardsDisplayed: 2,
                        backCardOffset: const Offset(0, 35),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        onSwipe: (previousIndex, currentIndex, direction) {
                          if (previousIndex < controller.allUsers.length) {
                            final user = controller.allUsers[previousIndex];
                            _handleSwipe(direction, user);
                          }
                          return true;
                        },
                        cardBuilder:
                            (context, index, horizontalOffset, verticalOffset) {
                              if (index >= controller.allUsers.length) {
                                return const SizedBox.shrink();
                              }
                              final user = controller.allUsers[index];
                              return _SwipeCard(
                                user: user,
                                compatibilityScore: controller
                                    .getCompatibilityScore(user.id),
                              );
                            },
                      ),
                    ),
                  ),

                  // Action Buttons
                  _buildActionButtons(),

                  const SizedBox(height: 100), // Space for nav bar
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'discover'.tr.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.gold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'find_your_match'.tr,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          GlassContainer(
            padding: const EdgeInsets.all(12),
            borderRadius: 16,
            child: const Icon(
              LucideIcons.slidersHorizontal,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: LucideIcons.x,
            color: Colors.redAccent,
            onTap: () {
              if (controller.allUsers.isNotEmpty) {
                _swiperController.swipe(CardSwiperDirection.left);
              }
            },
          ),
          _ActionButton(
            icon: LucideIcons.star,
            color: AppTheme.gold,
            size: 64,
            iconSize: 28,
            onTap: _onComplimentTap,
          ),
          _ActionButton(
            icon: LucideIcons.heart,
            color: AppTheme.success,
            onTap: () {
              if (controller.allUsers.isNotEmpty) {
                _swiperController.swipe(CardSwiperDirection.right);
              }
            },
          ),
        ],
      ),
    );
  }

  void _onComplimentTap() async {
    if (controller.allUsers.isEmpty) return;
    final message = await _showComplimentDialog(context);
    if (message == null) return;
    _queuedComplimentMessage = message;
    _swiperController.swipe(CardSwiperDirection.top);
  }

  Future<String?> _showComplimentDialog(BuildContext context) async {
    final input = TextEditingController();
    return Get.dialog<String>(
      AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          'send_compliment'.tr,
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: input,
          autofocus: true,
          maxLength: 120,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'write_something_nice'.tr,
            hintStyle: TextStyle(color: AppTheme.white50),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () {
              final text = input.text.trim();
              if (text.isEmpty) return;
              Get.back(result: text);
            },
            child: Text('send'.tr),
          ),
        ],
      ),
    );
  }

  void _handleSwipe(CardSwiperDirection direction, UserModel user) async {
    switch (direction) {
      case CardSwiperDirection.left:
        await controller.passUser(user.id);
        break;
      case CardSwiperDirection.right:
        await controller.likeUser(user.id);
        break;
      case CardSwiperDirection.top:
        final msg =
            _queuedComplimentMessage ??
            'compliment_default_message'.tr;
        _queuedComplimentMessage = null;
        await controller.complimentUser(user.id, message: msg);
        break;
      default:
        break;
    }
  }
}

class _SwipeCard extends StatelessWidget {
  final UserModel user;
  final int compatibilityScore;

  const _SwipeCard({required this.user, required this.compatibilityScore});

  @override
  Widget build(BuildContext context) {
    final displayName = user.publicDisplayName.trim().isNotEmpty
        ? user.publicDisplayName.trim()
        : 'profile'.tr;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            CachedNetworkImage(
              imageUrl: CloudinaryUrl.large(user.mainPhotoUrl),
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppTheme.surface,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.gold,
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppTheme.surface,
                child: Center(
                  child: Icon(
                    LucideIcons.user,
                    size: 80,
                    color: AppTheme.white30,
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
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),

            // Compatibility Badge (Top Right)
            if (compatibilityScore > 0)
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gold.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.sparkles,
                        color: AppTheme.background,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$compatibilityScore%',
                        style: const TextStyle(
                          color: AppTheme.background,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Online Indicator (Top Left)
            if (user.isOnline)
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'online'.tr.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // User Info (Bottom)
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Age
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$displayName, ${user.profile?.age ?? ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      if (user.selfieVerified)
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
                            LucideIcons.shieldCheck,
                            color: AppTheme.success,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        color: AppTheme.white50,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${user.profile?.city ?? ''}, ${user.profile?.country ?? ''}',
                        style: const TextStyle(
                          color: AppTheme.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (user.profile?.religiousLevel != null)
                        _buildTag(
                          user.profile!.religiousLevel!.capitalizeFirst!,
                        ),
                      if (user.profile?.sect != null)
                        _buildTag(user.profile!.sect!.capitalizeFirst!),
                      if (user.profile?.maritalStatus != null)
                        _buildTag(
                          user.profile!.maritalStatus!.capitalizeFirst!,
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

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.white10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 56,
    this.iconSize = 24,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _controller.forward().then((_) => _controller.reverse());
        widget.onTap();
      },
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: widget.color,
                size: widget.iconSize,
              ),
            ),
          );
        },
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
              boxShadow: [
                BoxShadow(
                  color: AppTheme.gold.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppTheme.gold,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'finding_matches'.tr,
            style: TextStyle(
              color: AppTheme.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return AnimatedEmptyState(
      lottieAsset: 'assets/animations/no_users.json',
      title: 'no_users_found'.tr,
      subtitle: 'try_adjusting_filters'.tr,
      fallbackIcon: LucideIcons.users,
      fallbackColor: AppTheme.gold,
      width: 190,
    );
  }
}
