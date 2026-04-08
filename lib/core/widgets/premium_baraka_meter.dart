import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/premium_theme.dart';

/// Premium Baraka Meter — Islamic-values compatibility indicator.
/// Circular animated progress with gold gradient stroke and glow effect.
class PremiumBarakaMeter extends StatefulWidget {
  final int score; // 0–100
  final String level; // 'low', 'medium', 'high'
  final bool compact; // small overlay vs. full widget
  final bool showBreakdown;
  final Map<String, int>? breakdown;
  final double size;

  const PremiumBarakaMeter({
    super.key,
    required this.score,
    required this.level,
    this.compact = true,
    this.showBreakdown = false,
    this.breakdown,
    this.size = 80,
  });

  @override
  State<PremiumBarakaMeter> createState() => _PremiumBarakaMeterState();
}

class _PremiumBarakaMeterState extends State<PremiumBarakaMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.score / 100,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(PremiumBarakaMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _progressAnimation =
          Tween<double>(
            begin: _progressAnimation.value,
            end: widget.score / 100,
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color {
    if (widget.score >= 75) return const Color(0xFF2E7D32);
    if (widget.score >= 45) return AppTheme.gold;
    return const Color(0xFFB71C1C);
  }

  String get _levelLabel {
    switch (widget.level) {
      case 'high':
        return 'High Baraka';
      case 'medium':
        return 'Moderate';
      default:
        return 'Growing';
    }
  }

  IconData get _icon {
    if (widget.score >= 75) return Icons.auto_awesome;
    if (widget.score >= 45) return Icons.brightness_5;
    return Icons.brightness_3;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) return _buildCompact();
    return _buildFull();
  }

  Widget _buildCompact() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final showGlow = widget.score > 70 && _progressAnimation.value > 0.7;

        return Container(
          width: widget.size,
          height: widget.size,
          decoration: showGlow
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.gold.withValues(
                        alpha: 0.4 * _progressAnimation.value,
                      ),
                      blurRadius: 25,
                      spreadRadius: 8,
                    ),
                  ],
                )
              : null,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _PremiumBarakaPainter(
              progress: _progressAnimation.value,
              color: _color,
              strokeWidth: 5,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icon, color: _color, size: widget.size * 0.25),
                  const SizedBox(height: 2),
                  Text(
                    '${(widget.score * _progressAnimation.value).toInt()}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.size * 0.22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFull() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final showGlow = widget.score > 70 && _progressAnimation.value > 0.7;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.white10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
              if (showGlow)
                BoxShadow(
                  color: AppTheme.gold.withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Animated Circular Progress
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: showGlow
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.gold.withValues(
                                  alpha: 0.5 * _progressAnimation.value,
                                ),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          )
                        : null,
                    child: CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _PremiumBarakaPainter(
                        progress: _progressAnimation.value,
                        color: _color,
                        strokeWidth: 6,
                        showGradient: true,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _icon,
                              color: _color,
                              size: widget.size * 0.22,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${(widget.score * _progressAnimation.value).toInt()}%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: widget.size * 0.28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Baraka Meter',
                          style: TextStyle(
                            color: AppTheme.gold,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _levelLabel,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            widget.score >= 75
                                ? 'Exceptional Match'
                                : widget.score >= 45
                                ? 'Good Compatibility'
                                : 'Still Growing',
                            style: TextStyle(
                              color: _color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.showBreakdown && widget.breakdown != null) ...[
                const SizedBox(height: 20),
                const Divider(color: AppTheme.white10, height: 1),
                const SizedBox(height: 16),
                _buildBreakdownBar(
                  'Prayer & Faith',
                  widget.breakdown!['prayer'] ?? 0,
                  30,
                  _color,
                ),
                const SizedBox(height: 10),
                _buildBreakdownBar(
                  'Intentions',
                  widget.breakdown!['intentions'] ?? 0,
                  25,
                  _color,
                ),
                const SizedBox(height: 10),
                _buildBreakdownBar(
                  'Lifestyle',
                  widget.breakdown!['lifestyle'] ?? 0,
                  20,
                  _color,
                ),
                const SizedBox(height: 10),
                _buildBreakdownBar(
                  'Family Values',
                  widget.breakdown!['family'] ?? 0,
                  15,
                  _color,
                ),
                const SizedBox(height: 10),
                _buildBreakdownBar(
                  'Shared Interests',
                  widget.breakdown!['interests'] ?? 0,
                  10,
                  _color,
                ),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildBreakdownBar(String label, int value, int max, Color color) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$value/$max',
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: AppTheme.white10,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for premium circular progress with gold gradient
class _PremiumBarakaPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool showGradient;

  _PremiumBarakaPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    this.showGradient = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background arc
    final bgPaint = Paint()
      ..color = AppTheme.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      // Create gold gradient for the progress arc
      final gradient = SweepGradient(
        center: Alignment.center,
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + (2 * math.pi * progress),
        colors: showGradient
            ? [
                AppTheme.goldGradientStart,
                AppTheme.goldGradientEnd,
                AppTheme.goldGradientStart,
              ]
            : [color, color, color],
        stops: const [0.0, 0.5, 1.0],
      );

      final fgPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        fgPaint,
      );

      // Add glow at the tip of the progress arc
      if (progress > 0.1 && showGradient) {
        final tipAngle = -math.pi / 2 + (2 * math.pi * progress);
        final tipX = center.dx + radius * math.cos(tipAngle);
        final tipY = center.dy + radius * math.sin(tipAngle);

        final glowPaint = Paint()
          ..color = AppTheme.gold.withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

        canvas.drawCircle(Offset(tipX, tipY), strokeWidth * 0.8, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
