import 'package:flutter/material.dart';
import 'package:methna_app/app/theme/app_colors.dart';

class BackendWaitDots extends StatefulWidget {
  final Color color;
  final double size;
  final double spacing;

  const BackendWaitDots({
    super.key,
    this.color = AppColors.primary,
    this.size = 6,
    this.spacing = 4,
  });

  @override
  State<BackendWaitDots> createState() => _BackendWaitDotsState();
}

class _BackendWaitDotsState extends State<BackendWaitDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.size * 2,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = (_controller.value + i * 0.2) % 1.0;
              final scale = 0.7 + 0.6 * (1 - (t - 0.5).abs() * 2);
              return Container(
                margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.7 + 0.3 * scale),
                  shape: BoxShape.circle,
                ),
                transform: Matrix4.diagonal3Values(scale, scale, 1),
              );
            }),
          );
        },
      ),
    );
  }
}
