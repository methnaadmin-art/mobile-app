import 'package:flutter/material.dart';
import 'package:methna_app/app/theme/app_colors.dart';

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final Duration duration;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.colors = const [
      AppColors.primary,
      AppColors.secondary,
      AppColors.primaryLight,
      AppColors.primaryDark,
    ],
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.lerp(
                Alignment.topLeft,
                Alignment.bottomRight,
                _controller.value,
              )!,
              end: Alignment.lerp(
                Alignment.bottomRight,
                Alignment.topLeft,
                _controller.value,
              )!,
              colors: [
                Color.lerp(widget.colors[0], widget.colors[1], _controller.value)!,
                Color.lerp(widget.colors[2], widget.colors[3], _controller.value)!,
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
