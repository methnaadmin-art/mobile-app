import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/search_controller.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/core/utils/google_fonts_stub.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/avatar/avatar_controller.dart';
import 'package:methna_app/core/avatar/avatar_widget.dart';
import 'package:methna_app/core/utils/helpers.dart';

class SearchRadarScreen extends StatefulWidget {
  const SearchRadarScreen({super.key});

  @override
  State<SearchRadarScreen> createState() => _SearchRadarScreenState();
}

class _SearchRadarScreenState extends State<SearchRadarScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sweepController;
  late final AnimationController _pulseController;
  late final AvatarController _avatarController;
  final List<_AvatarSlot> _avatarSlots = [];
  final math.Random _rng = math.Random();
  SearchRadarController? _boundController;
  Worker? _userWorker;
  Worker? _searchWorker;
  bool _isClearingSlots = false;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    if (Get.isRegistered<AvatarController>()) {
      _avatarController = Get.find<AvatarController>();
    } else {
      _avatarController = Get.put(AvatarController(), permanent: true);
    }
  }

  void _bindController(SearchRadarController controller) {
    if (identical(_boundController, controller)) {
      return;
    }

    _boundController = controller;
    _userWorker?.dispose();
    _searchWorker?.dispose();

    _userWorker = ever(controller.foundUsers, (List<UserModel> users) {
      if (users.isEmpty) {
        unawaited(_clearAvatarSlots());
        _syncAvatarState(controller);
        return;
      }

      if (users.length < _avatarSlots.length) {
        unawaited(_trimAvatarSlotsTo(users.length));
      }

      if (users.length > _avatarSlots.length) {
        for (var i = _avatarSlots.length; i < users.length; i++) {
          final ringIndex = i % 3;
          final ringRadius = 0.35 + ringIndex * 0.28;
          final angle = _rng.nextDouble() * math.pi * 2;
          final ac = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 500),
          )..forward();
          _avatarSlots.add(_AvatarSlot(
            user: users[i],
            angle: angle,
            ringRadius: ringRadius,
            animation: ac,
          ));
        }
        if (mounted) setState(() {});
      }

      _syncAvatarState(controller);
    });

    _searchWorker = ever(controller.isSearching, (_) {
      _syncAvatarState(controller);
    });

    _syncAvatarState(controller);
  }

  Future<void> _trimAvatarSlotsTo(int targetLength) async {
    if (_isClearingSlots ||
        targetLength < 0 ||
        _avatarSlots.length <= targetLength) {
      return;
    }

    final removed = List<_AvatarSlot>.from(
      _avatarSlots.getRange(targetLength, _avatarSlots.length),
    );

    await Future.wait(removed.map((slot) async {
      try {
        await slot.animation.reverse();
      } catch (_) {}
    }));

    for (final slot in removed) {
      slot.animation.dispose();
    }

    _avatarSlots.removeRange(targetLength, _avatarSlots.length);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _clearAvatarSlots() async {
    if (_isClearingSlots || _avatarSlots.isEmpty) return;
    _isClearingSlots = true;

    try {
      final currentSlots = List<_AvatarSlot>.from(_avatarSlots);

      await Future.wait(currentSlots.map((slot) async {
        try {
          await slot.animation.reverse();
        } catch (_) {}
      }));

      for (final slot in currentSlots) {
        slot.animation.dispose();
      }

      _avatarSlots.clear();
      if (mounted) {
        setState(() {});
      }
    } finally {
      _isClearingSlots = false;
    }
  }

  void _syncAvatarState(SearchRadarController controller) {
    if (controller.isSearching.value) {
      if (controller.foundUsers.isEmpty) {
        _avatarController.onLoading();
      } else {
        _avatarController.onThinking();
      }
      return;
    }

    if (controller.foundUsers.isNotEmpty) {
      _avatarController.onLike();
    } else {
      _avatarController.idle();
    }
  }

  @override
  void dispose() {
    _userWorker?.dispose();
    _searchWorker?.dispose();
    _sweepController.dispose();
    _pulseController.dispose();
    for (final slot in _avatarSlots) {
      slot.animation.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<SearchRadarController>()
        ? Get.find<SearchRadarController>()
        : Get.put(SearchRadarController());
    _bindController(controller);
    final currentUser = Get.find<AuthService>().currentUser.value;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _RadarBackground(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final radarSize = math.min(
                    constraints.maxWidth * 0.86,
                    constraints.maxHeight * 0.52,
                  );

                  return Obx(() {
                    final focusUser = currentUser ??
                        (controller.foundUsers.isNotEmpty
                            ? controller.foundUsers.first
                            : null);

                    return Column(
                      children: [
                        SizedBox(height: constraints.maxHeight * 0.14),
                        Expanded(
                          child: Center(
                            child: SizedBox(
                              width: radarSize,
                              height: radarSize,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: Listenable.merge([
                                      _sweepController,
                                      _pulseController,
                                    ]),
                                    builder: (context, _) => _RadarCore(
                                      size: radarSize,
                                      user: focusUser,
                                      sweepProgress: _sweepController.value,
                                      pulseProgress: _pulseController.value,
                                    ),
                                  ),
                                  ..._buildAvatarWidgets(radarSize),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Obx(() => _RadarCounter(
                          count: controller.foundUsers.length,
                          isSearching: controller.isSearching.value,
                        )),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Text(
                            controller.isSearching.value
                                ? 'finding_people_nearby'.tr
                                : _statusMessage(controller.foundUsers.length),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: AvatarWidget(
                            size: 70,
                            showGlow: true,
                            showReflection: false,
                            onTap: _avatarController.onWave,
                          ),
                        ),
                        SizedBox(height: constraints.maxHeight * 0.10),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: controller.isSearching.value ? 0 : 1,
                          child: IgnorePointer(
                            ignoring: controller.isSearching.value,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _RadarGhostButton(
                                      label: 'back'.tr,
                                      onTap: () => Get.back(),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _RadarGhostButton(
                                      label: 'scan_again'.tr,
                                      onTap: () {
                                        unawaited(_clearAvatarSlots());
                                        controller.retry();
                                      },
                                      emphasized: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAvatarWidgets(double radarSize) {
    return _avatarSlots.map((slot) {
      final r = radarSize * 0.5 * slot.ringRadius;
      final dx = math.cos(slot.angle) * r;
      final dy = math.sin(slot.angle) * r;
      return AnimatedBuilder(
        animation: slot.animation,
        builder: (context, child) {
          final t = Curves.elasticOut.transform(
            slot.animation.value.clamp(0.0, 1.0),
          );
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.scale(
              scale: t,
              child: Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: child,
              ),
            ),
          );
        },
        child: _RadarUserBubble(user: slot.user, size: radarSize * 0.13),
      );
    }).toList();
  }

  String _statusMessage(int count) {
    if (count <= 0) return 'no_one_nearby'.tr;
    if (count == 1) return 'one_person_nearby'.tr;
    return '$count ${'people_found_nearby'.tr}';
  }
}

class _AvatarSlot {
  final UserModel user;
  final double angle;
  final double ringRadius;
  final AnimationController animation;

  _AvatarSlot({
    required this.user,
    required this.angle,
    required this.ringRadius,
    required this.animation,
  });
}

class _RadarCounter extends StatelessWidget {
  const _RadarCounter({required this.count, required this.isSearching});

  final int count;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        isSearching ? '' : '$count',
        key: ValueKey(count),
        style: GoogleFonts.poppins(
          fontSize: 38,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -1,
        ),
      ),
    );
  }
}

class _RadarUserBubble extends StatelessWidget {
  const _RadarUserBubble({required this.user, required this.size});

  final UserModel user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = user.mainPhotoUrl?.trim() ?? '';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8F23FF).withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl.isEmpty
            ? Container(
                color: const Color(0xFFF0E7FF),
                alignment: Alignment.center,
                child: Text(
                  Helpers.getInitials(user.firstName, user.lastName),
                  style: GoogleFonts.poppins(
                    fontSize: size * 0.32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(
                  color: const Color(0xFFF0E7FF),
                  alignment: Alignment.center,
                  child: Text(
                    Helpers.getInitials(user.firstName, user.lastName),
                    style: GoogleFonts.poppins(
                      fontSize: size * 0.32,
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

class _RadarCore extends StatelessWidget {
  const _RadarCore({
    required this.size,
    required this.user,
    required this.sweepProgress,
    required this.pulseProgress,
  });

  final double size;
  final UserModel? user;
  final double sweepProgress;
  final double pulseProgress;

  @override
  Widget build(BuildContext context) {
    final outerPulse = 1 + (pulseProgress * 0.04);
    final middlePulse = 1 + (pulseProgress * 0.03);
    final innerPulse = 1 + (pulseProgress * 0.02);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Transform.scale(
            scale: outerPulse,
            child: Container(
              width: size * 0.94,
              height: size * 0.94,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Middle ring
          Transform.scale(
            scale: middlePulse,
            child: Container(
              width: size * 0.63,
              height: size * 0.63,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.16),
                  width: 1,
                ),
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
          ),
          // Inner ring
          Transform.scale(
            scale: innerPulse,
            child: Container(
              width: size * 0.35,
              height: size * 0.35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                  width: 1,
                ),
                color: Colors.white.withValues(alpha: 0.28),
              ),
            ),
          ),
          // Sweep
          _RadarSweep(size: size * 0.96, progress: sweepProgress),
          // Center white disc
          Container(
            width: size * 0.24,
            height: size * 0.24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          // Center avatar
          _RadarAvatar(
            user: user,
            size: size * 0.17,
          ),
        ],
      ),
    );
  }
}

class _RadarSweep extends StatelessWidget {
  const _RadarSweep({
    required this.size,
    required this.progress,
  });

  final double size;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: progress * math.pi * 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            startAngle: -math.pi / 2,
            endAngle: math.pi / 1.3,
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.04),
              Colors.white.withValues(alpha: 0.18),
              Colors.white.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.62, 0.78, 0.9, 1.0],
          ),
        ),
      ),
    );
  }
}

class _RadarAvatar extends StatelessWidget {
  const _RadarAvatar({
    required this.user,
    required this.size,
  });

  final UserModel? user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = user?.mainPhotoUrl?.trim() ?? '';

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
            ? _RadarFallback(user: user)
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _RadarFallback(user: user),
              ),
      ),
    );
  }
}

class _RadarFallback extends StatelessWidget {
  const _RadarFallback({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0E7FF),
      alignment: Alignment.center,
      child: Text(
        Helpers.getInitials(user?.firstName, user?.lastName),
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _RadarGhostButton extends StatelessWidget {
  const _RadarGhostButton({
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: emphasized
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.12),
            border: Border.all(
              color: Colors.white.withValues(alpha: emphasized ? 0.28 : 0.18),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarBackground extends StatelessWidget {
  const _RadarBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFB54BFF),
                Color(0xFFA134FF),
                Color(0xFF932DFF),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _RadarRoadPainter(
              lineColor: Colors.white.withValues(alpha: 0.08),
              contourColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        const _RadarMapLabels(),
        Positioned(
          left: -80,
          top: 420,
          child: _GlowOrb(
            size: 210,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        Positioned(
          right: -40,
          top: 120,
          child: _GlowOrb(
            size: 130,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

class _RadarMapLabels extends StatelessWidget {
  const _RadarMapLabels();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: const [
          _MapLabel(text: 'Canyon St', left: 50, top: 134, angle: -0.42),
          _MapLabel(text: 'Damion St', left: 60, top: 78, angle: -0.12),
          _MapLabel(text: 'Marlow St', left: 232, top: 42, angle: -0.38),
          _MapLabel(text: 'Bigelow Ave', left: 180, top: 178, angle: -0.04),
          _MapLabel(text: '19th St', left: 204, top: 146, angle: -0.02),
          _MapLabel(text: '24th St', left: 218, top: 522, angle: -0.04),
          _MapLabel(text: 'Elizabeth St', left: 204, top: 470, angle: -0.03),
          _MapLabel(text: 'Seward Street Slides', left: 166, top: 206, angle: -0.01),
          _MapLabel(text: 'Twin Peaks', left: 22, top: 346, angle: -0.12),
          _MapLabel(text: 'Carmel St', left: 218, top: 110, angle: -0.02),
          _MapLabel(text: 'Melrose St', left: 126, top: 72, angle: -1.55),
          _MapLabel(text: 'Clipper St', left: 214, top: 602, angle: -0.03),
          _MapLabel(text: 'Saturn St', left: 262, top: 330, angle: -1.58),
          _MapLabel(text: 'Ord St', left: 46, top: 278, angle: -1.02),
          _MapLabel(text: '17th St', left: 6, top: 46, angle: -1.55),
          _MapLabel(text: 'Eleanore Ave', left: 272, top: 356, angle: -1.58),
          _MapLabel(text: 'Corbett Ave', left: 18, top: 214, angle: 0.92),
          _MapLabel(text: 'Market St', left: 92, top: 116, angle: -1.07),
        ],
      ),
    );
  }
}

class _MapLabel extends StatelessWidget {
  const _MapLabel({
    required this.text,
    required this.left,
    required this.top,
    required this.angle,
  });

  final String text;
  final double left;
  final double top;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Transform.rotate(
        angle: angle,
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: Colors.black.withValues(alpha: 0.12),
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

class _RadarRoadPainter extends CustomPainter {
  const _RadarRoadPainter({
    required this.lineColor,
    required this.contourColor,
  });

  final Color lineColor;
  final Color contourColor;

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    final contourPaint = Paint()
      ..color = contourColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final roads = <List<Offset>>[
      [
        Offset(size.width * 0.1, size.height * 0.22),
        Offset(size.width * 0.22, size.height * 0.3),
        Offset(size.width * 0.36, size.height * 0.34),
        Offset(size.width * 0.56, size.height * 0.33),
        Offset(size.width * 0.84, size.height * 0.27),
      ],
      [
        Offset(size.width * 0.04, size.height * 0.56),
        Offset(size.width * 0.22, size.height * 0.48),
        Offset(size.width * 0.44, size.height * 0.45),
        Offset(size.width * 0.7, size.height * 0.45),
        Offset(size.width * 0.94, size.height * 0.4),
      ],
      [
        Offset(size.width * 0.14, size.height * 0.72),
        Offset(size.width * 0.34, size.height * 0.74),
        Offset(size.width * 0.54, size.height * 0.7),
        Offset(size.width * 0.86, size.height * 0.64),
      ],
      [
        Offset(size.width * 0.78, size.height * 0.18),
        Offset(size.width * 0.84, size.height * 0.32),
        Offset(size.width * 0.82, size.height * 0.56),
        Offset(size.width * 0.78, size.height * 0.84),
      ],
      [
        Offset(size.width * 0.36, size.height * 0.05),
        Offset(size.width * 0.38, size.height * 0.24),
        Offset(size.width * 0.42, size.height * 0.52),
        Offset(size.width * 0.46, size.height * 0.9),
      ],
    ];

    for (final road in roads) {
      final path = Path()..moveTo(road.first.dx, road.first.dy);
      for (var i = 1; i < road.length; i++) {
        final midpoint = Offset(
          (road[i - 1].dx + road[i].dx) / 2,
          (road[i - 1].dy + road[i].dy) / 2,
        );
        path.quadraticBezierTo(midpoint.dx, midpoint.dy, road[i].dx, road[i].dy);
      }
      canvas.drawPath(path, roadPaint);
    }

    final contours = <Path>[
      Path()
        ..moveTo(0, size.height * 0.82)
        ..quadraticBezierTo(
          size.width * 0.18,
          size.height * 0.7,
          size.width * 0.28,
          size.height * 0.84,
        )
        ..quadraticBezierTo(
          size.width * 0.42,
          size.height * 0.98,
          size.width * 0.6,
          size.height * 0.88,
        ),
      Path()
        ..moveTo(size.width * 0.02, size.height * 0.08)
        ..quadraticBezierTo(
          size.width * 0.18,
          size.height * 0.16,
          size.width * 0.24,
          size.height * 0.04,
        )
        ..quadraticBezierTo(
          size.width * 0.36,
          size.height * -0.12,
          size.width * 0.56,
          size.height * 0.06,
        ),
    ];

    for (final path in contours) {
      canvas.drawPath(path, contourPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarRoadPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.contourColor != contourColor;
  }
}
