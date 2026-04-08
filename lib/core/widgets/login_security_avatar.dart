import 'dart:math' as math;

import 'package:flutter/material.dart';

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
  late final AnimationController _scanCtrl;
  late final AnimationController _glanceCtrl;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();

    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();

    _glanceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    _breatheCtrl.dispose();
    _scanCtrl.dispose();
    _glanceCtrl.dispose();
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
    final closeEyes = widget.isPasswordFocused && !widget.isPasswordVisible;
    final spyMode = widget.isPasswordFocused && widget.isPasswordVisible;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _blinkCtrl,
        _breatheCtrl,
        _scanCtrl,
        _glanceCtrl,
      ]),
      builder: (context, child) {
        var eyeOpen = closeEyes ? 0.08 : _blinkOpenFactor();
        if (spyMode) {
          eyeOpen = math.max(eyeOpen, 0.72);
        }

        final scanShift = math.sin(_scanCtrl.value * 2 * math.pi) * 4.8;
        final idleShift = math.sin(_glanceCtrl.value * 2 * math.pi) * 1.6;
        final identifierShift = math.sin(_glanceCtrl.value * 2 * math.pi) * 2.8;

        final pupilShift = closeEyes
            ? 0.0
            : (spyMode
                  ? scanShift
                  : (widget.isIdentifierFocused ? identifierShift : idleShift));

        final shellScale = 1.0 + (_breatheCtrl.value * 0.025);
        final floatY = math.sin(_breatheCtrl.value * math.pi * 2) * 1.6;

        final mouthWidth = spyMode
            ? widget.size * 0.2
            : (closeEyes ? widget.size * 0.16 : widget.size * 0.24);
        final mouthCurve = spyMode
            ? BorderRadius.circular(widget.size * 0.2)
            : BorderRadius.circular(widget.size * 0.06);

        final haloOpacity = spyMode
            ? 0.34
            : (closeEyes ? 0.22 : (widget.hasPasswordText ? 0.28 : 0.16));

        return Transform.translate(
          offset: Offset(0, floatY),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Transform.scale(
                    scale: shellScale,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.accentLight.withValues(alpha: 0.26),
                            widget.accent.withValues(alpha: 0.14),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.accent.withValues(alpha: haloOpacity),
                            blurRadius: spyMode ? 30 : 22,
                            spreadRadius: spyMode ? 1.5 : 0,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.faceColor,
                        border: Border.all(
                          color: widget.strokeColor.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: widget.size * 0.3,
                  left: widget.size * 0.24,
                  right: widget.size * 0.24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _AvatarEye(
                        openFactor: eyeOpen,
                        pupilShift: pupilShift,
                        strokeColor: widget.strokeColor,
                        irisColor: widget.accent,
                      ),
                      _AvatarEye(
                        openFactor: eyeOpen,
                        pupilShift: pupilShift,
                        strokeColor: widget.strokeColor,
                        irisColor: widget.accent,
                        spyLens: spyMode,
                        lensShift: scanShift,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: widget.size * 0.27,
                  left: (widget.size - mouthWidth) / 2,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: mouthWidth,
                    height: closeEyes ? 3 : 5,
                    decoration: BoxDecoration(
                      color: widget.strokeColor.withValues(alpha: 0.56),
                      borderRadius: mouthCurve,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AvatarEye extends StatelessWidget {
  final double openFactor;
  final double pupilShift;
  final Color strokeColor;
  final Color irisColor;
  final bool spyLens;
  final double lensShift;

  const _AvatarEye({
    required this.openFactor,
    required this.pupilShift,
    required this.strokeColor,
    required this.irisColor,
    this.spyLens = false,
    this.lensShift = 0,
  });

  @override
  Widget build(BuildContext context) {
    final eyeHeight = 4.0 + (openFactor * 10.0);
    final showPupil = openFactor > 0.18;

    return SizedBox(
      width: 28,
      height: 22,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (!showPupil)
            Container(
              width: 22,
              height: 2.1,
              decoration: BoxDecoration(
                color: strokeColor.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(999),
              ),
            )
          else
            Container(
              width: 24,
              height: eyeHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: strokeColor.withValues(alpha: 0.45)),
              ),
              child: Center(
                child: Transform.translate(
                  offset: Offset(pupilShift.clamp(-4.0, 4.0), 0),
                  child: Container(
                    width: 7.2,
                    height: 7.2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: irisColor.withValues(alpha: 0.94),
                    ),
                    child: Align(
                      alignment: const Alignment(-0.3, -0.3),
                      child: Container(
                        width: 2.1,
                        height: 2.1,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (spyLens && showPupil)
            Positioned(
              right: -4,
              top: 1,
              child: Transform.translate(
                offset: Offset(lensShift * 0.3, 0),
                child: Transform.rotate(
                  angle: -0.6,
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: irisColor.withValues(alpha: 0.9),
                              width: 1.6,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 7,
                            height: 1.8,
                            decoration: BoxDecoration(
                              color: irisColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
