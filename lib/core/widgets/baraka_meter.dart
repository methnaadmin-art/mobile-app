import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Baraka Meter — Islamic-values compatibility indicator.
/// Shows a crescent-moon-inspired arc with percentage, level label,
/// and optional detailed breakdown for premium users.
class BarakaMeter extends StatelessWidget {
  final int score; // 0–100
  final String level; // 'low', 'medium', 'high'
  final bool compact; // small overlay vs. full widget
  final bool showBreakdown;
  final Map<String, int>? breakdown; // {prayer, intentions, lifestyle, family, interests}

  const BarakaMeter({
    super.key,
    required this.score,
    required this.level,
    this.compact = true,
    this.showBreakdown = false,
    this.breakdown,
  });

  Color get _color {
    if (score >= 75) return const Color(0xFF8B5CF6); // deep green
    if (score >= 45) return const Color(0xFFF9A825); // warm amber
    return const Color(0xFF4F26D9); // muted red
  }

  Color get _bgColor {
    if (score >= 75) return const Color(0xFF8B5CF6).withValues(alpha: 0.15);
    if (score >= 45) return const Color(0xFFF9A825).withValues(alpha: 0.15);
    return const Color(0xFF4F26D9).withValues(alpha: 0.15);
  }

  String get _levelLabel {
    switch (level) {
      case 'high': return 'High Baraka';
      case 'medium': return 'Moderate';
      default: return 'Growing';
    }
  }

  IconData get _icon {
    if (score >= 75) return Icons.auto_awesome;
    if (score >= 45) return Icons.brightness_5;
    return Icons.brightness_3;
  }

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact();
    return _buildFull(context);
  }

  /// Small overlay badge for swipe cards
  Widget _buildCompact() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: 14),
          const SizedBox(width: 4),
          Text(
            '$score%',
            style: TextStyle(
              color: _color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Full-size widget for profile screen
  Widget _buildFull(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BarakaArc(score: score, color: _color, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Baraka Meter',
                      style: TextStyle(
                        color: _color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _levelLabel,
                      style: TextStyle(
                        color: _color.withValues(alpha: 0.85),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(_icon, color: _color, size: 28),
            ],
          ),
          if (showBreakdown && breakdown != null) ...[
            const SizedBox(height: 14),
            _BreakdownBar(label: 'Prayer & Faith', value: breakdown!['prayer'] ?? 0, max: 30, color: _color),
            const SizedBox(height: 6),
            _BreakdownBar(label: 'Intentions', value: breakdown!['intentions'] ?? 0, max: 25, color: _color),
            const SizedBox(height: 6),
            _BreakdownBar(label: 'Lifestyle', value: breakdown!['lifestyle'] ?? 0, max: 20, color: _color),
            const SizedBox(height: 6),
            _BreakdownBar(label: 'Family Values', value: breakdown!['family'] ?? 0, max: 15, color: _color),
            const SizedBox(height: 6),
            _BreakdownBar(label: 'Shared Interests', value: breakdown!['interests'] ?? 0, max: 10, color: _color),
          ],
        ],
      ),
    );
  }
}

class _BarakaArc extends StatelessWidget {
  final int score;
  final Color color;
  final double size;
  const _BarakaArc({required this.score, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ArcPainter(progress: score / 100, color: color),
        child: Center(
          child: Text(
            '$score',
            style: TextStyle(
              color: color,
              fontSize: size * 0.32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    // Background arc
    canvas.drawArc(
      rect,
      -math.pi * 0.75,
      math.pi * 1.5,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    // Progress arc
    canvas.drawArc(
      rect,
      -math.pi * 0.75,
      math.pi * 1.5 * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => old.progress != progress || old.color != color;
}

class _BreakdownBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;
  const _BreakdownBar({required this.label, required this.value, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
            Text('$value/$max', style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.6))),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 5,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
