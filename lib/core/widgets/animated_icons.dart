import 'dart:math';
import 'package:flutter/material.dart';
import 'package:methna_app/app/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED HEART — Pulsing/beating heart with glow
// ═══════════════════════════════════════════════════════════════════════════
class AnimatedHeartIcon extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedHeartIcon({
    super.key,
    this.size = 120,
    this.color = AppColors.primary,
  });

  @override
  State<AnimatedHeartIcon> createState() => _AnimatedHeartIconState();
}

class _AnimatedHeartIconState extends State<AnimatedHeartIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        final scale = 1.0 + 0.12 * sin(t * pi);
        final glowOpacity = 0.15 + 0.15 * t;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: widget.size * 0.9,
                height: widget.size * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: glowOpacity),
                      blurRadius: 30 + 10 * t,
                      spreadRadius: 5 * t,
                    ),
                  ],
                ),
              ),
              // Heart body
              Transform.scale(
                scale: scale,
                child: CustomPaint(
                  size: Size(widget.size * 0.55, widget.size * 0.55),
                  painter: _HeartPainter(color: widget.color),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED SEARCH — Rotating magnifying glass with pulse rings
// ═══════════════════════════════════════════════════════════════════════════
class AnimatedSearchIcon extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedSearchIcon({
    super.key,
    this.size = 120,
    this.color = AppColors.primary,
  });

  @override
  State<AnimatedSearchIcon> createState() => _AnimatedSearchIconState();
}

class _AnimatedSearchIconState extends State<AnimatedSearchIcon>
    with TickerProviderStateMixin {
  late AnimationController _rotateCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotateCtrl, _pulseCtrl]),
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _SearchPainter(
              color: widget.color,
              rotateProgress: _rotateCtrl.value,
              pulseProgress: _pulseCtrl.value,
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED LOCATION PIN — Bouncing pin with ripple
// ═══════════════════════════════════════════════════════════════════════════
class AnimatedLocationIcon extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedLocationIcon({
    super.key,
    this.size = 120,
    this.color = AppColors.primary,
  });

  @override
  State<AnimatedLocationIcon> createState() => _AnimatedLocationIconState();
}

class _AnimatedLocationIconState extends State<AnimatedLocationIcon>
    with TickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late AnimationController _rippleCtrl;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _rippleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_bounceCtrl, _rippleCtrl]),
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _LocationPainter(
              color: widget.color,
              bounceProgress: _bounceCtrl.value,
              rippleProgress: _rippleCtrl.value,
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED CHAT BUBBLE — Floating bubble with typing dots
// ═══════════════════════════════════════════════════════════════════════════
class AnimatedChatIcon extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedChatIcon({
    super.key,
    this.size = 120,
    this.color = AppColors.primary,
  });

  @override
  State<AnimatedChatIcon> createState() => _AnimatedChatIconState();
}

class _AnimatedChatIconState extends State<AnimatedChatIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _ChatBubblePainter(
              color: widget.color,
              progress: _ctrl.value,
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED CHECKMARK — Draw-in checkmark with success circle
// ═══════════════════════════════════════════════════════════════════════════
class AnimatedCheckIcon extends StatefulWidget {
  final double size;
  final Color color;
  final bool repeat;

  const AnimatedCheckIcon({
    super.key,
    this.size = 120,
    this.color = AppColors.primary,
    this.repeat = false,
  });

  @override
  State<AnimatedCheckIcon> createState() => _AnimatedCheckIconState();
}

class _AnimatedCheckIconState extends State<AnimatedCheckIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.repeat) {
      _ctrl.repeat();
    } else {
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _BellPainter(color: widget.color, progress: _ctrl.value),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED SPARKLE — Twinkling star / sparkle effect
// ═══════════════════════════════════════════════════════════════════════════
class AnimatedSparkleIcon extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedSparkleIcon({
    super.key,
    this.size = 120,
    this.color = AppColors.primaryLight,
  });

  @override
  State<AnimatedSparkleIcon> createState() => _AnimatedSparkleIconState();
}

class _AnimatedSparkleIconState extends State<AnimatedSparkleIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _CheckPainter(color: widget.color, progress: _ctrl.value),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED NOTIFICATION BELL — Swinging bell with ring pulse
// ═══════════════════════════════════════════════════════════════════════════
class AnimatedBellIcon extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedBellIcon({
    super.key,
    this.size = 120,
    this.color = AppColors.primary,
  });

  @override
  State<AnimatedBellIcon> createState() => _AnimatedBellIconState();
}

class _AnimatedBellIconState extends State<AnimatedBellIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _SparklePainter(
              color: widget.color,
              progress: _ctrl.value,
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED ERROR — X mark draw-in with red circle
// ═══════════════════════════════════════════════════════════════════════════
class AnimatedErrorIcon extends StatefulWidget {
  final double size;
  final Color color;

  const AnimatedErrorIcon({
    super.key,
    this.size = 120,
    this.color = AppColors.primaryDark,
  });

  @override
  State<AnimatedErrorIcon> createState() => _AnimatedErrorIconState();
}

class _AnimatedErrorIconState extends State<AnimatedErrorIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _ErrorPainter(color: widget.color, progress: _ctrl.value),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//                        CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════════════

class _HeartPainter extends CustomPainter {
  final Color color;
  _HeartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w / 2, h);
    path.cubicTo(w / 2, h, 0, h * 0.65, 0, h * 0.35);
    path.cubicTo(0, h * 0.1, w * 0.25, 0, w / 2, h * 0.2);
    path.cubicTo(w * 0.75, 0, w, h * 0.1, w, h * 0.35);
    path.cubicTo(w, h * 0.65, w / 2, h, w / 2, h);
    path.close();

    canvas.drawPath(path, paint);

    // Highlight
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.32, h * 0.28), w * 0.08, highlight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SearchPainter extends CustomPainter {
  final Color color;
  final double rotateProgress;
  final double pulseProgress;

  _SearchPainter({
    required this.color,
    required this.rotateProgress,
    required this.pulseProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.28;

    // Pulse rings
    for (int i = 0; i < 3; i++) {
      final phase = (pulseProgress + i * 0.33) % 1.0;
      final ringR = r * 0.6 + r * 0.9 * phase;
      final opacity = (1.0 - phase) * 0.25;
      final ringPaint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, ringR, ringPaint);
    }

    // Glass circle
    final glassCenter = Offset(center.dx - r * 0.12, center.dy - r * 0.12);
    final glassPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(glassCenter, r, glassPaint);

    final glassBorder = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(glassCenter, r, glassBorder);

    // Handle with rotation wobble
    final handleAngle = pi / 4 + sin(rotateProgress * 2 * pi) * 0.15;
    final handleStart = Offset(
      glassCenter.dx + r * cos(handleAngle),
      glassCenter.dy + r * sin(handleAngle),
    );
    final handleEnd = Offset(
      glassCenter.dx + (r + r * 0.65) * cos(handleAngle),
      glassCenter.dy + (r + r * 0.65) * sin(handleAngle),
    );
    final handlePaint = Paint()
      ..color = color
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(handleStart, handleEnd, handlePaint);

    // Glass highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(glassCenter.dx - r * 0.25, glassCenter.dy - r * 0.25),
      r * 0.15,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SearchPainter old) =>
      old.rotateProgress != rotateProgress ||
      old.pulseProgress != pulseProgress;
}

class _LocationPainter extends CustomPainter {
  final Color color;
  final double bounceProgress;
  final double rippleProgress;

  _LocationPainter({
    required this.color,
    required this.bounceProgress,
    required this.rippleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final baseY = size.height * 0.72;

    // Shadow ellipse
    final shadowW = size.width * 0.25;
    final shadowH = 6.0;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(
        alpha: 0.12 + 0.08 * (1 - _bounceY(bounceProgress).abs()),
      );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseY + 4),
        width: shadowW,
        height: shadowH,
      ),
      shadowPaint,
    );

    // Ripple rings from base
    for (int i = 0; i < 2; i++) {
      final phase = (rippleProgress + i * 0.5) % 1.0;
      final rippleR = 8 + 30 * phase;
      final opacity = (1.0 - phase) * 0.2;
      final ripplePaint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, baseY),
          width: rippleR * 2,
          height: rippleR * 0.5,
        ),
        ripplePaint,
      );
    }

    // Pin body - bounce
    final bounceOffset = _bounceY(bounceProgress) * -18;
    final pinTop = baseY - size.height * 0.5 + bounceOffset;
    final pinCenter = Offset(cx, pinTop);
    final pinR = size.width * 0.14;

    // Pin shape
    final pinPath = Path();
    pinPath.addArc(
      Rect.fromCircle(center: pinCenter, radius: pinR),
      pi * 0.15,
      pi * 1.7,
    );
    pinPath.lineTo(cx, baseY + bounceOffset);
    pinPath.close();

    final pinPaint = Paint()..color = color;
    canvas.drawPath(pinPath, pinPaint);

    // Inner white dot
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(pinCenter, pinR * 0.45, dotPaint);
  }

  double _bounceY(double t) {
    // Creates a bouncing motion
    final x = t * 2 * pi;
    return sin(x) * (1.0 - t * 0.3).clamp(0.0, 1.0);
  }

  @override
  bool shouldRepaint(covariant _LocationPainter old) =>
      old.bounceProgress != bounceProgress ||
      old.rippleProgress != rippleProgress;
}

class _ChatBubblePainter extends CustomPainter {
  final Color color;
  final double progress;

  _ChatBubblePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 8;
    final bw = size.width * 0.55;
    final bh = size.height * 0.35;

    // Floating motion
    final floatY = sin(progress * 2 * pi) * 4;

    // Bubble body
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + floatY), width: bw, height: bh),
      Radius.circular(bh * 0.4),
    );
    final bubblePaint = Paint()..color = color.withValues(alpha: 0.15);
    canvas.drawRRect(bubbleRect, bubblePaint);

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(bubbleRect, borderPaint);

    // Tail
    final tailPath = Path();
    tailPath.moveTo(cx - 8, cy + bh / 2 + floatY - 1);
    tailPath.lineTo(cx - 16, cy + bh / 2 + 12 + floatY);
    tailPath.lineTo(cx + 2, cy + bh / 2 + floatY - 1);
    canvas.drawPath(tailPath, Paint()..color = color.withValues(alpha: 0.15));
    canvas.drawPath(
      tailPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Typing dots
    final dotR = 3.5;
    for (int i = 0; i < 3; i++) {
      final phase = (progress * 3 + i * 0.3) % 1.0;
      final dotY = cy + floatY + sin(phase * 2 * pi) * 4;
      final dotX = cx + (i - 1) * 14.0;
      final dotOpacity = 0.4 + 0.6 * ((sin(phase * 2 * pi) + 1) / 2);
      canvas.drawCircle(
        Offset(dotX, dotY),
        dotR,
        Paint()..color = color.withValues(alpha: dotOpacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChatBubblePainter old) =>
      old.progress != progress;
}

class _CheckPainter extends CustomPainter {
  final Color color;
  final double progress;

  _CheckPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.38;

    // Circle draw-in
    final circleProgress = (progress * 2).clamp(0.0, 1.0);
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -pi / 2,
      2 * pi * circleProgress,
      false,
      circlePaint,
    );

    // Fill circle with fade
    if (circleProgress >= 1.0) {
      final fillProgress = ((progress - 0.5) * 4).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        r,
        Paint()..color = color.withValues(alpha: fillProgress * 0.12),
      );
    }

    // Checkmark draw-in
    final checkProgress = ((progress - 0.4) * 2.5).clamp(0.0, 1.0);
    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final p1 = Offset(center.dx - r * 0.35, center.dy + r * 0.05);
      final p2 = Offset(center.dx - r * 0.05, center.dy + r * 0.35);
      final p3 = Offset(center.dx + r * 0.4, center.dy - r * 0.25);

      final checkPath = Path();
      if (checkProgress <= 0.5) {
        final t = checkProgress * 2;
        checkPath.moveTo(p1.dx, p1.dy);
        checkPath.lineTo(
          p1.dx + (p2.dx - p1.dx) * t,
          p1.dy + (p2.dy - p1.dy) * t,
        );
      } else {
        final t = (checkProgress - 0.5) * 2;
        checkPath.moveTo(p1.dx, p1.dy);
        checkPath.lineTo(p2.dx, p2.dy);
        checkPath.lineTo(
          p2.dx + (p3.dx - p2.dx) * t,
          p2.dy + (p3.dy - p2.dy) * t,
        );
      }
      canvas.drawPath(checkPath, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) => old.progress != progress;
}

class _SparklePainter extends CustomPainter {
  final Color color;
  final double progress;

  _SparklePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Main 4-point star
    final mainScale = 0.8 + 0.2 * sin(progress * 2 * pi);
    _drawStar(
      canvas,
      Offset(cx, cy),
      size.width * 0.22 * mainScale,
      color,
      progress,
    );

    // Smaller orbiting sparkles
    final sparkles = [
      _SparkleData(0.0, 0.35, 0.08),
      _SparkleData(0.25, 0.4, 0.06),
      _SparkleData(0.5, 0.32, 0.07),
      _SparkleData(0.75, 0.38, 0.05),
    ];

    for (final s in sparkles) {
      final angle = (progress + s.angleOffset) * 2 * pi;
      final dist = size.width * s.distance;
      final sparkleSize = size.width * s.size;
      final sx = cx + cos(angle) * dist;
      final sy = cy + sin(angle) * dist;
      final opacity = (0.4 + 0.6 * sin((progress + s.angleOffset) * 4 * pi))
          .clamp(0.0, 1.0);
      _drawStar(
        canvas,
        Offset(sx, sy),
        sparkleSize,
        color.withValues(alpha: opacity),
        progress + s.angleOffset,
      );
    }
  }

  void _drawStar(Canvas canvas, Offset center, double r, Color c, double rot) {
    final paint = Paint()
      ..color = c
      ..style = PaintingStyle.fill;

    final path = Path();
    final innerR = r * 0.3;
    final rotAngle = rot * pi;

    for (int i = 0; i < 4; i++) {
      final angle = rotAngle + i * pi / 2;
      final outerX = center.dx + cos(angle) * r;
      final outerY = center.dy + sin(angle) * r;
      final innerAngle1 = angle - pi / 4;
      final innerAngle2 = angle + pi / 4;
      final inner1X = center.dx + cos(innerAngle1) * innerR;
      final inner1Y = center.dy + sin(innerAngle1) * innerR;
      final inner2X = center.dx + cos(innerAngle2) * innerR;
      final inner2Y = center.dy + sin(innerAngle2) * innerR;

      if (i == 0) {
        path.moveTo(inner1X, inner1Y);
      } else {
        path.lineTo(inner1X, inner1Y);
      }
      path.lineTo(outerX, outerY);
      path.lineTo(inner2X, inner2Y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => old.progress != progress;
}

class _SparkleData {
  final double angleOffset;
  final double distance;
  final double size;
  const _SparkleData(this.angleOffset, this.distance, this.size);
}

class _BellPainter extends CustomPainter {
  final Color color;
  final double progress;

  _BellPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final bellW = size.width * 0.35;
    final bellH = size.height * 0.32;

    // Swing angle
    double swingAngle = 0;
    if (progress < 0.4) {
      final t = progress / 0.4;
      swingAngle = sin(t * 3 * pi) * 0.2 * (1 - t);
    }

    canvas.save();
    canvas.translate(cx, cy - bellH * 0.4);
    canvas.rotate(swingAngle);
    canvas.translate(-cx, -(cy - bellH * 0.4));

    // Bell body
    final bellPath = Path();
    bellPath.moveTo(cx - bellW * 0.15, cy - bellH * 0.7);
    bellPath.quadraticBezierTo(
      cx,
      cy - bellH * 0.85,
      cx + bellW * 0.15,
      cy - bellH * 0.7,
    );
    bellPath.cubicTo(
      cx + bellW * 0.5,
      cy - bellH * 0.5,
      cx + bellW * 0.55,
      cy + bellH * 0.1,
      cx + bellW * 0.6,
      cy + bellH * 0.3,
    );
    bellPath.lineTo(cx - bellW * 0.6, cy + bellH * 0.3);
    bellPath.cubicTo(
      cx - bellW * 0.55,
      cy + bellH * 0.1,
      cx - bellW * 0.5,
      cy - bellH * 0.5,
      cx - bellW * 0.15,
      cy - bellH * 0.7,
    );
    bellPath.close();

    canvas.drawPath(bellPath, Paint()..color = color);

    // Bell bottom rim
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy + bellH * 0.3),
          width: bellW * 1.3,
          height: 6,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = color,
    );

    // Clapper
    canvas.drawCircle(Offset(cx, cy + bellH * 0.42), 4, Paint()..color = color);

    // Top knob
    canvas.drawCircle(
      Offset(cx, cy - bellH * 0.78),
      3.5,
      Paint()..color = color,
    );

    canvas.restore();

    // Sound waves (only during swing)
    if (progress < 0.5) {
      for (int i = 0; i < 2; i++) {
        final phase = ((progress * 3) + i * 0.3) % 1.0;
        final waveR = 8 + 18 * phase;
        final opacity = (1.0 - phase) * 0.3;
        final side = i.isEven ? 1.0 : -1.0;
        canvas.drawArc(
          Rect.fromCircle(
            center: Offset(cx + side * bellW * 0.5, cy - bellH * 0.2),
            radius: waveR,
          ),
          -pi / 3 * side,
          pi / 3,
          false,
          Paint()
            ..color = color.withValues(alpha: opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BellPainter old) => old.progress != progress;
}

class _ErrorPainter extends CustomPainter {
  final Color color;
  final double progress;

  _ErrorPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.38;

    // Circle draw-in
    final circleProgress = (progress * 2).clamp(0.0, 1.0);
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -pi / 2,
      2 * pi * circleProgress,
      false,
      circlePaint,
    );

    // Fill with fade
    if (circleProgress >= 1.0) {
      final fillProgress = ((progress - 0.5) * 4).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        r,
        Paint()..color = color.withValues(alpha: fillProgress * 0.1),
      );
    }

    // X mark draw-in
    final xProgress = ((progress - 0.4) * 2.5).clamp(0.0, 1.0);
    if (xProgress > 0) {
      final xPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      final arm = r * 0.32;

      // First stroke: top-left to bottom-right
      if (xProgress <= 0.5) {
        final t = xProgress * 2;
        final from = Offset(center.dx - arm, center.dy - arm);
        final to = Offset(center.dx + arm, center.dy + arm);
        canvas.drawLine(
          from,
          Offset(
            from.dx + (to.dx - from.dx) * t,
            from.dy + (to.dy - from.dy) * t,
          ),
          xPaint,
        );
      } else {
        // First stroke complete
        canvas.drawLine(
          Offset(center.dx - arm, center.dy - arm),
          Offset(center.dx + arm, center.dy + arm),
          xPaint,
        );
        // Second stroke: top-right to bottom-left
        final t = (xProgress - 0.5) * 2;
        final from = Offset(center.dx + arm, center.dy - arm);
        final to = Offset(center.dx - arm, center.dy + arm);
        canvas.drawLine(
          from,
          Offset(
            from.dx + (to.dx - from.dx) * t,
            from.dy + (to.dy - from.dy) * t,
          ),
          xPaint,
        );
      }
    }

    // Shake effect via small vibration particles
    if (progress > 0.7 && progress < 0.9) {
      final shakeProg = ((progress - 0.7) / 0.2);
      for (int i = 0; i < 4; i++) {
        final angle = i * pi / 2 + pi / 4;
        final dist = r * 1.2 + r * 0.3 * shakeProg;
        final px = center.dx + cos(angle) * dist;
        final py = center.dy + sin(angle) * dist;
        final opacity = (1.0 - shakeProg) * 0.5;
        canvas.drawCircle(
          Offset(px, py),
          2.5,
          Paint()..color = color.withValues(alpha: opacity),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ErrorPainter old) => old.progress != progress;
}
