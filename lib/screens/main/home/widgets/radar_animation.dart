import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/core/utils/cloudinary_url.dart';
import 'package:methna_app/app/theme/app_colors.dart';

class RadarAnimation extends StatefulWidget {
  final UserModel? currentUser;
  final List<UserModel> users;
  final Duration duration;

  const RadarAnimation({
    super.key,
    this.currentUser,
    required this.users,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<RadarAnimation> createState() => _RadarAnimationState();
}

class _RadarAnimationState extends State<RadarAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late AnimationController _pulseController;

  final Random _random = Random();
  final List<_AvatarNode> _nodes = [];

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _generateNodes();
  }

  void _generateNodes() {
    final visibleUsers = widget.users.take(8).toList();
    for (int i = 0; i < visibleUsers.length; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final distance = 80.0 + _random.nextDouble() * 100.0;
      _nodes.add(
        _AvatarNode(
          dx: cos(angle) * distance,
          dy: sin(angle) * distance,
          delay: _random.nextDouble(),
          imageUrl: visibleUsers[i].mainPhotoUrl,
        ),
      );
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.1),
            isDark ? Colors.black : Colors.white,
          ],
          center: Alignment.center,
          radius: 1.2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Subtle Grid
          Positioned.fill(
            child: CustomPaint(
              painter: _RadarGridPainter(
                color: (isDark ? Colors.white : AppColors.primary).withValues(
                  alpha: 0.05,
                ),
              ),
            ),
          ),

          // 2. Decorative Circles
          ...List.generate(
            3,
            (i) => Container(
              width: (i + 1) * 160.0,
              height: (i + 1) * 160.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (isDark ? Colors.white : AppColors.primary).withValues(
                    alpha: 0.1,
                  ),
                  width: 1,
                ),
              ),
            ),
          ),

          // 3. Scanning Beam
          RotationTransition(
            turns: _scanController,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.primary.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 0.51],
                  center: Alignment.center,
                ),
              ),
            ),
          ),

          // 4. Avatars
          ..._nodes.map(
            (node) =>
                _AnimatedAvatarNode(node: node, controller: _scanController),
          ),

          // 5. Center Profile
          _CentralProfile(user: widget.currentUser, pulse: _pulseController),

          // 6. Status Text
          Positioned(
            bottom: 60,
            child: Column(
              children: [
                const Text(
                  'Finding souls near you...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 140,
                  child: LinearProgressIndicator(
                    borderRadius: BorderRadius.circular(10),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
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

class _RadarGridPainter extends CustomPainter {
  final Color color;
  _RadarGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AvatarNode {
  final double dx;
  final double dy;
  final double delay;
  final String? imageUrl;
  _AvatarNode({
    required this.dx,
    required this.dy,
    required this.delay,
    this.imageUrl,
  });
}

class _AnimatedAvatarNode extends StatelessWidget {
  final _AvatarNode node;
  final Animation<double> controller;

  const _AnimatedAvatarNode({required this.node, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Appears when the scan beam passes over it?
        // For simplicity and "Pro" feel, let's just do a nice floating pulse
        return Transform.translate(
          offset: Offset(node.dx, node.dy),
          child: _ProfileBubble(imageUrl: node.imageUrl),
        );
      },
    );
  }
}

class _ProfileBubble extends StatelessWidget {
  final String? imageUrl;
  const _ProfileBubble({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: Colors.grey.shade200),
                errorWidget: (context, url, error) =>
                    Container(color: AppColors.primarySurface),
              )
            : Container(
                color: AppColors.primarySurface,
                child: const Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
      ),
    );
  }
}

class _CentralProfile extends StatelessWidget {
  final UserModel? user;
  final Animation<double> pulse;
  const _CentralProfile({this.user, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse Ripple
            Container(
              width: 80 + (pulse.value * 40),
              height: 80 + (pulse.value * 40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(
                  alpha: 0.2 * (1 - pulse.value),
                ),
              ),
            ),
            // Avatar
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipOval(
                child: user?.mainPhotoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: CloudinaryUrl.thumbnail(user!.mainPhotoUrl!),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: AppColors.primary,
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 40,
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
