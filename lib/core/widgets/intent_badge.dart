import 'package:flutter/material.dart';

/// Intent Mode badge — shows user's intention with adapted colors.
/// - Serious Marriage: deep green + ring icon
/// - Exploring: warm amber + compass icon
/// - Family Introduction: soft primaryBrand + family icon
class IntentBadge extends StatelessWidget {
  final String intentMode;
  final bool compact;

  const IntentBadge({
    super.key,
    required this.intentMode,
    this.compact = true,
  });

  Color get _color {
    switch (intentMode) {
      case 'serious_marriage': return const Color(0xFF8B5CF6);
      case 'exploring': return const Color(0xFFF9A825);
      case 'family_introduction': return const Color(0xFF7B1FA2);
      default: return const Color(0xFF757575);
    }
  }

  Color get _bgColor => _color.withValues(alpha: 0.12);

  IconData get _icon {
    switch (intentMode) {
      case 'serious_marriage': return Icons.favorite;
      case 'exploring': return Icons.explore;
      case 'family_introduction': return Icons.family_restroom;
      default: return Icons.help_outline;
    }
  }

  String get _label {
    switch (intentMode) {
      case 'serious_marriage': return 'Serious';
      case 'exploring': return 'Exploring';
      case 'family_introduction': return 'Family';
      default: return 'Unknown';
    }
  }

  String get _fullLabel {
    switch (intentMode) {
      case 'serious_marriage': return 'Serious Marriage';
      case 'exploring': return 'Exploring';
      case 'family_introduction': return 'Family Introduction';
      default: return 'Not Set';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact();
    return _buildFull();
  }

  Widget _buildCompact() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: 12),
          const SizedBox(width: 3),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFull() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: _color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Intent',
                style: TextStyle(
                  color: _color.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                _fullLabel,
                style: TextStyle(
                  color: _color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
