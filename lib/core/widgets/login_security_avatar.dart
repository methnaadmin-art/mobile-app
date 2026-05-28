import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:methna_app/app/theme/app_colors.dart';

class LoginSecurityAvatar extends StatefulWidget {
  final bool isPasswordFocused;
  final bool isPasswordVisible;
  final bool hasPasswordText;
  final bool isIdentifierFocused;
  final double size;
  final Color accent;
  final Color accentLight;
  final Color faceColor;
  final Color strokeColor;

  const LoginSecurityAvatar({
    super.key,
    required this.isPasswordFocused,
    required this.isPasswordVisible,
    required this.hasPasswordText,
    required this.isIdentifierFocused,
    this.size = 116,
    required this.accent,
    required this.accentLight,
    required this.faceColor,
    required this.strokeColor,
  });

  @override
  State<LoginSecurityAvatar> createState() => _LoginSecurityAvatarState();
}

class _LoginSecurityAvatarState extends State<LoginSecurityAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _blinkCtrl;
  late final AnimationController _breatheCtrl;
  late final AnimationController _glanceCtrl;
  late final AnimationController _sparkCtrl;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();

    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _glanceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _sparkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    _breatheCtrl.dispose();
    _glanceCtrl.dispose();
    _sparkCtrl.dispose();
    super.dispose();
  }

  double _blinkOpenFactor() {
    final t = _blinkCtrl.value;
    if (t < 0.78) return 1.0;
    if (t < 0.84) {
      final p = (t - 0.78) / 0.06;
      return 1.0 - (p * 0.94);
    }
    if (t < 0.9) {
      final p = (t - 0.84) / 0.06;
      return 0.06 + (p * 0.94);
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final guardingPassword =
        widget.isPasswordFocused && !widget.isPasswordVisible;
    final revealMode = widget.isPasswordFocused && widget.isPasswordVisible;
    final faceBrightness = ThemeData.estimateBrightnessForColor(
      widget.faceColor,
    );
    final skinTone = Color.lerp(
      widget.faceColor,
      const Color(0xFFE8BDA5),
      faceBrightness == Brightness.dark ? 0.5 : 0.72,
    )!;
    final skinShadow = Color.lerp(skinTone, const Color(0xFF8F5D4A), 0.25)!;
    final hairColor = Color.lerp(
      widget.strokeColor,
      const Color(0xFF3B2641),
      0.5,
    )!;
    final jacketStart = Color.lerp(
      widget.accent,
      const Color(0xFF5E2E8A),
      0.24,
    )!;
    final jacketEnd = Color.lerp(widget.accentLight, Colors.white, 0.14)!;
    final haloOpacity = revealMode
        ? 0.34
        : (guardingPassword ? 0.24 : (widget.hasPasswordText ? 0.26 : 0.18));

    return AnimatedBuilder(
      animation: Listenable.merge([
        _blinkCtrl,
        _breatheCtrl,
        _glanceCtrl,
        _sparkCtrl,
      ]),
      builder: (context, child) {
        var eyeOpen = guardingPassword ? 0.08 : _blinkOpenFactor();
        if (revealMode) {
          eyeOpen = math.max(eyeOpen, 0.84);
        }

        final idleShift = math.sin(_glanceCtrl.value * 2 * math.pi) * 1.7;
        final focusShift = math.sin(_glanceCtrl.value * 2 * math.pi) * 3.0;
        final pupilShift = guardingPassword
            ? 0.0
            : (widget.isIdentifierFocused ? focusShift : idleShift);
        final floatY = math.sin(_breatheCtrl.value * math.pi * 2) * 1.6;
        final bustScale = 1.0 + (_breatheCtrl.value * 0.02);
        final smileWidth = revealMode
            ? widget.size * 0.16
            : (guardingPassword ? widget.size * 0.12 : widget.size * 0.2);
        final sparklePhase = _sparkCtrl.value * 2 * math.pi;

        return Transform.translate(
          offset: Offset(0, floatY),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Transform.scale(
                    scale: bustScale,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            widget.accentLight.withValues(alpha: 0.28),
                            widget.accent.withValues(alpha: 0.12),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.58, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.accent.withValues(alpha: haloOpacity),
                            blurRadius: revealMode ? 30 : 24,
                            spreadRadius: revealMode ? 1.5 : 0.2,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                for (final spark in [
                  (
                    dx: -widget.size * 0.26,
                    dy: -widget.size * 0.11,
                    radius: widget.size * 0.038,
                    phase: 0.0,
                  ),
                  (
                    dx: widget.size * 0.28,
                    dy: -widget.size * 0.04,
                    radius: widget.size * 0.03,
                    phase: 1.5,
                  ),
                  (
                    dx: widget.size * 0.22,
                    dy: widget.size * 0.13,
                    radius: widget.size * 0.024,
                    phase: 3.0,
                  ),
                ])
                  Positioned(
                    left:
                        (widget.size / 2) +
                        spark.dx +
                        (math.cos(sparklePhase + spark.phase) * 2.6) -
                        spark.radius,
                    top:
                        (widget.size / 2) +
                        spark.dy +
                        (math.sin(sparklePhase + spark.phase) * 3.6) -
                        spark.radius,
                    child: _SparkDot(
                      radius: spark.radius,
                      color: widget.accent.withValues(
                        alpha: revealMode ? 0.5 : 0.26,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: widget.size * 0.05,
                  child: Container(
                    width: widget.size * 0.76,
                    height: widget.size * 0.31,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [jacketEnd, jacketStart],
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(widget.size * 0.32),
                        bottom: Radius.circular(widget.size * 0.18),
                      ),
                      border: Border.all(
                        color: widget.strokeColor.withValues(alpha: 0.14),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: widget.size * 0.24,
                  child: Container(
                    width: widget.size * 0.14,
                    height: widget.size * 0.11,
                    decoration: BoxDecoration(
                      color: skinShadow.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(widget.size * 0.06),
                    ),
                  ),
                ),
                Positioned(
                  bottom: widget.size * 0.18,
                  child: Container(
                    width: widget.size * 0.12,
                    height: widget.size * 0.06,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(widget.size * 0.06),
                    ),
                  ),
                ),
                Positioned(
                  top: widget.size * 0.16,
                  child: Container(
                    width: widget.size * 0.48,
                    height: widget.size * 0.56,
                    decoration: BoxDecoration(
                      color: skinTone,
                      borderRadius: BorderRadius.circular(widget.size * 0.22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: widget.size * 0.12,
                  child: Container(
                    width: widget.size * 0.54,
                    height: widget.size * 0.26,
                    decoration: BoxDecoration(
                      color: hairColor,
                      borderRadius: BorderRadius.circular(widget.size * 0.22),
                    ),
                  ),
                ),
                Positioned(
                  top: widget.size * 0.17,
                  left: widget.size * 0.26,
                  child: Container(
                    width: widget.size * 0.1,
                    height: widget.size * 0.22,
                    decoration: BoxDecoration(
                      color: hairColor,
                      borderRadius: BorderRadius.circular(widget.size * 0.12),
                    ),
                  ),
                ),
                Positioned(
                  top: widget.size * 0.17,
                  right: widget.size * 0.26,
                  child: Container(
                    width: widget.size * 0.1,
                    height: widget.size * 0.22,
                    decoration: BoxDecoration(
                      color: hairColor,
                      borderRadius: BorderRadius.circular(widget.size * 0.12),
                    ),
                  ),
                ),
                Positioned(
                  top: widget.size * 0.24,
                  left: widget.size * 0.21,
                  child: Container(
                    width: widget.size * 0.055,
                    height: widget.size * 0.09,
                    decoration: BoxDecoration(
                      color: skinTone,
                      borderRadius: BorderRadius.circular(widget.size * 0.04),
                    ),
                  ),
                ),
                Positioned(
                  top: widget.size * 0.24,
                  right: widget.size * 0.21,
                  child: Container(
                    width: widget.size * 0.055,
                    height: widget.size * 0.09,
                    decoration: BoxDecoration(
                      color: skinTone,
                      borderRadius: BorderRadius.circular(widget.size * 0.04),
                    ),
                  ),
                ),
                Positioned(
                  top: widget.size * 0.29,
                  child: SizedBox(
                    width: widget.size * 0.3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _PortraitBrow(color: hairColor),
                        _PortraitBrow(color: hairColor),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: widget.size * 0.35,
                  child: SizedBox(
                    width: widget.size * 0.3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _PortraitEye(
                          openFactor: eyeOpen,
                          pupilShift: pupilShift,
                          irisColor: widget.accent,
                          strokeColor: widget.strokeColor,
                        ),
                        _PortraitEye(
                          openFactor: eyeOpen,
                          pupilShift: pupilShift,
                          irisColor: widget.accent,
                          strokeColor: widget.strokeColor,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: widget.size * 0.43,
                  child: Container(
                    width: widget.size * 0.042,
                    height: widget.size * 0.1,
                    decoration: BoxDecoration(
                      color: skinShadow.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(widget.size * 0.04),
                    ),
                  ),
                ),
                Positioned(
                  top: widget.size * 0.55,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: smileWidth,
                    height: guardingPassword ? 3 : 6,
                    decoration: BoxDecoration(
                      color: widget.strokeColor.withValues(alpha: 0.54),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(widget.size * 0.04),
                        bottom: Radius.circular(
                          revealMode ? widget.size * 0.08 : widget.size * 0.05,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: widget.size * 0.46,
                  left: widget.size * 0.29,
                  child: _CheekGlow(
                    radius: widget.size * 0.04,
                    color: AppColors.primaryLight.withValues(alpha: 0.12),
                  ),
                ),
                Positioned(
                  top: widget.size * 0.46,
                  right: widget.size * 0.29,
                  child: _CheekGlow(
                    radius: widget.size * 0.04,
                    color: AppColors.primaryLight.withValues(alpha: 0.12),
                  ),
                ),
                if (guardingPassword) ...[
                  Positioned(
                    top: widget.size * 0.32,
                    left: widget.size * 0.16,
                    child: Transform.rotate(
                      angle: -0.38,
                      child: _AvatarHand(
                        width: widget.size * 0.26,
                        height: widget.size * 0.11,
                        skinColor: skinTone,
                        strokeColor: skinShadow,
                      ),
                    ),
                  ),
                  Positioned(
                    top: widget.size * 0.32,
                    right: widget.size * 0.16,
                    child: Transform.rotate(
                      angle: 0.38,
                      child: _AvatarHand(
                        width: widget.size * 0.26,
                        height: widget.size * 0.11,
                        skinColor: skinTone,
                        strokeColor: skinShadow,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PortraitEye extends StatelessWidget {
  final double openFactor;
  final double pupilShift;
  final Color irisColor;
  final Color strokeColor;

  const _PortraitEye({
    required this.openFactor,
    required this.pupilShift,
    required this.irisColor,
    required this.strokeColor,
  });

  @override
  Widget build(BuildContext context) {
    final eyeHeight = 4.0 + (openFactor * 9.0);
    final showPupil = openFactor > 0.18;

    return SizedBox(
      width: 24,
      height: 18,
      child: Center(
        child: !showPupil
            ? Container(
                width: 18,
                height: 2.2,
                decoration: BoxDecoration(
                  color: strokeColor.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(999),
                ),
              )
            : Container(
                width: 20,
                height: eyeHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: strokeColor.withValues(alpha: 0.16),
                  ),
                ),
                child: Center(
                  child: Transform.translate(
                    offset: Offset(pupilShift.clamp(-3.2, 3.2), 0),
                    child: Container(
                      width: 6.6,
                      height: 6.6,
                      decoration: BoxDecoration(
                        color: irisColor.withValues(alpha: 0.94),
                        shape: BoxShape.circle,
                      ),
                      child: Align(
                        alignment: const Alignment(-0.24, -0.28),
                        child: Container(
                          width: 2.0,
                          height: 2.0,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _PortraitBrow extends StatelessWidget {
  final Color color;

  const _PortraitBrow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 2.4,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _AvatarHand extends StatelessWidget {
  final double width;
  final double height;
  final Color skinColor;
  final Color strokeColor;

  const _AvatarHand({
    required this.width,
    required this.height,
    required this.skinColor,
    required this.strokeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: skinColor,
        borderRadius: BorderRadius.circular(height),
        border: Border.all(color: strokeColor.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: width * 0.32,
          height: height * 0.9,
          decoration: BoxDecoration(
            color: strokeColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(height),
              right: Radius.circular(height),
            ),
          ),
        ),
      ),
    );
  }
}

class _SparkDot extends StatelessWidget {
  final double radius;
  final Color color;

  const _SparkDot({required this.radius, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _CheekGlow extends StatelessWidget {
  final double radius;
  final Color color;

  const _CheekGlow({required this.radius, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
