import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:methna_app/app/theme/app_colors.dart';

class LoginSuccessAnimation extends StatefulWidget {
  const LoginSuccessAnimation({super.key, this.size = 160});

  final double size;

  @override
  State<LoginSuccessAnimation> createState() => _LoginSuccessAnimationState();
}

class _LoginSuccessAnimationState extends State<LoginSuccessAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
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
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final breathe = 1 + 0.035 * math.sin(t * math.pi * 2);
          final orbit = t * math.pi * 2;
          final checkScale = Curves.easeOutBack.transform(
            (t * 1.8).clamp(0.0, 1.0),
          );

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              for (final offset in [0.0, 0.22, 0.44])
                _PulseRing(
                  size: widget.size,
                  progress: ((t - offset) % 1 + 1) % 1,
                ),
              Transform.rotate(
                angle: orbit * 0.18,
                child: Container(
                  width: widget.size * 0.82,
                  height: widget.size * 0.82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 28,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
              Transform.scale(
                scale: breathe,
                child: Container(
                  width: widget.size * 0.62,
                  height: widget.size * 0.62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryLight, AppColors.primaryDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.22),
                        blurRadius: 22,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              Transform.scale(
                scale: checkScale,
                child: Container(
                  width: widget.size * 0.39,
                  height: widget.size * 0.39,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFFBF4),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.72),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.24),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: widget.size * 0.22,
                    color: AppColors.primary,
                  ),
                ),
              ),
              for (final particle in _particles)
                _SparkParticle(
                  size: widget.size,
                  orbit: orbit,
                  progress: t,
                  particle: particle,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.size, required this.progress});

  final double size;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final scale = 0.48 + (progress * 0.82);
    final opacity = (1 - progress).clamp(0.0, 1.0) * 0.36;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: opacity),
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _SparkParticle extends StatelessWidget {
  const _SparkParticle({
    required this.size,
    required this.orbit,
    required this.progress,
    required this.particle,
  });

  final double size;
  final double orbit;
  final double progress;
  final _ParticleConfig particle;

  @override
  Widget build(BuildContext context) {
    final radius = size * particle.radiusFactor;
    final angle = orbit + particle.angleOffset;
    final drift = math.sin((progress + particle.delay) * math.pi * 2) * 5;
    final dx = math.cos(angle) * radius;
    final dy = math.sin(angle) * radius + drift;
    final sparkleScale =
        0.78 +
        (0.24 * math.sin((progress + particle.delay) * math.pi * 2).abs());

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: -orbit * 0.35,
        child: Transform.scale(
          scale: sparkleScale,
          child: Icon(
            particle.icon,
            size: size * particle.sizeFactor,
            color: particle.color,
          ),
        ),
      ),
    );
  }
}

class _ParticleConfig {
  const _ParticleConfig({
    required this.angleOffset,
    required this.radiusFactor,
    required this.sizeFactor,
    required this.color,
    required this.icon,
    required this.delay,
  });

  final double angleOffset;
  final double radiusFactor;
  final double sizeFactor;
  final Color color;
  final IconData icon;
  final double delay;
}

const List<_ParticleConfig> _particles = [
  _ParticleConfig(
    angleOffset: 0.15,
    radiusFactor: 0.34,
    sizeFactor: 0.12,
    color: Color(0xFFA78BFA),
    icon: Icons.auto_awesome_rounded,
    delay: 0.00,
  ),
  _ParticleConfig(
    angleOffset: 1.95,
    radiusFactor: 0.39,
    sizeFactor: 0.10,
    color: Color(0xFFF4F0FF),
    icon: Icons.star_rounded,
    delay: 0.16,
  ),
  _ParticleConfig(
    angleOffset: 3.55,
    radiusFactor: 0.37,
    sizeFactor: 0.11,
    color: Color(0xFF6E3DFB),
    icon: Icons.auto_awesome_rounded,
    delay: 0.34,
  ),
  _ParticleConfig(
    angleOffset: 4.65,
    radiusFactor: 0.3,
    sizeFactor: 0.09,
    color: Color(0xFF8B5CF6),
    icon: Icons.circle,
    delay: 0.52,
  ),
];
