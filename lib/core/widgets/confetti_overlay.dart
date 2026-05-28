import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:methna_app/app/theme/app_colors.dart';

/// A reusable confetti overlay widget for celebrations (matches, super-likes, etc.).
/// Wrap any widget with this and call [fire()] to trigger confetti.
class ConfettiOverlay extends StatefulWidget {
  final Widget child;

  const ConfettiOverlay({super.key, required this.child});

  /// Fire confetti from the global key.
  static void fire(GlobalKey<ConfettiOverlayState> key) {
    key.currentState?.fire();
  }

  @override
  State<ConfettiOverlay> createState() => ConfettiOverlayState();
}

class ConfettiOverlayState extends State<ConfettiOverlay> {
  late final ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Trigger the confetti animation.
  void fire() => _controller.play();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Center-top confetti burst
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 30,
            maxBlastForce: 40,
            minBlastForce: 15,
            emissionFrequency: 0.05,
            gravity: 0.15,
            colors: const [
              AppColors.primary,
              AppColors.primaryLight,
              AppColors.primaryDark,
              AppColors.secondaryLight,
              Colors.white,
            ],
            createParticlePath: _drawStar,
          ),
        ),
      ],
    );
  }

  /// Custom star-shaped particle.
  Path _drawStar(Size size) {
    final path = Path();
    final mid = size.width / 2;
    final min = size.width / 4;
    final half = size.height / 2;
    path.moveTo(mid, 0);
    path.lineTo(mid + min / 2, half - min / 2);
    path.lineTo(mid + min, half);
    path.lineTo(mid + min / 2, half + min / 2);
    path.lineTo(mid, size.height);
    path.lineTo(mid - min / 2, half + min / 2);
    path.lineTo(mid - min, half);
    path.lineTo(mid - min / 2, half - min / 2);
    path.close();
    return path;
  }
}

/// Simple confetti trigger widget that fires once on build.
class MatchConfetti extends StatefulWidget {
  const MatchConfetti({super.key});

  @override
  State<MatchConfetti> createState() => _MatchConfettiState();
}

class _MatchConfettiState extends State<MatchConfetti> {
  late final ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 4));
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.play());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiWidget(
      confettiController: _controller,
      blastDirectionality: BlastDirectionality.explosive,
      shouldLoop: false,
      numberOfParticles: 50,
      maxBlastForce: 50,
      minBlastForce: 20,
      emissionFrequency: 0.03,
      gravity: 0.1,
      colors: const [
        AppColors.primary,
        AppColors.primaryLight,
        AppColors.primaryDark,
        Colors.white,
        Color(0xFF6E3DFB),
      ],
      createParticlePath: (size) {
        // Diamond shape
        final path = Path();
        final mid = size.width / 2;
        path.moveTo(mid, 0);
        path.lineTo(size.width, size.height / 2);
        path.lineTo(mid, size.height);
        path.lineTo(0, size.height / 2);
        path.close();
        return path;
      },
    );
  }
}
