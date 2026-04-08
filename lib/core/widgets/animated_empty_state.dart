import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/widgets/animated_icons.dart';

class AnimatedEmptyState extends StatefulWidget {
  final String lottieAsset;
  final String title;
  final String subtitle;
  final double width;
  final IconData? fallbackIcon;
  final Color? fallbackColor;
  final Color? titleColor;
  final Color? subtitleColor;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionLabel;
  final double contentMaxWidth;

  const AnimatedEmptyState({
    super.key,
    required this.lottieAsset,
    required this.title,
    required this.subtitle,
    this.width = 200,
    this.fallbackIcon,
    this.fallbackColor,
    this.titleColor,
    this.subtitleColor,
    this.onPrimaryAction,
    this.primaryActionLabel,
    this.contentMaxWidth = 440,
  });

  @override
  State<AnimatedEmptyState> createState() => _AnimatedEmptyStateState();
}

class _AnimatedEmptyStateState extends State<AnimatedEmptyState>
    with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Widget _buildAnimatedIcon() {
    final c = widget.fallbackColor ?? AppColors.primary;
    final s = widget.width * 0.65;

    final lower = widget.lottieAsset.toLowerCase();
    if (lower.contains('heart') || lower.contains('like') ||
        lower.contains('match')) {
      return AnimatedHeartIcon(size: s, color: c);
    } else if (lower.contains('search') || lower.contains('discover') ||
        lower.contains('no_user')) {
      return AnimatedSearchIcon(size: s, color: c);
    } else if (lower.contains('location') || lower.contains('map') ||
        lower.contains('pin')) {
      return AnimatedLocationIcon(size: s, color: c);
    } else if (lower.contains('chat') || lower.contains('message') ||
        lower.contains('inbox')) {
      return AnimatedChatIcon(size: s, color: c);
    } else if (lower.contains('check') || lower.contains('success') ||
        lower.contains('done')) {
      return AnimatedCheckIcon(size: s, color: c);
    } else if (lower.contains('bell') || lower.contains('notif')) {
      return AnimatedBellIcon(size: s, color: c);
    } else if (lower.contains('star') || lower.contains('sparkle') ||
        lower.contains('premium')) {
      return AnimatedSparkleIcon(size: s, color: c);
    }

    if (widget.fallbackIcon != null) {
      return _PulsingFallbackIcon(
        size: s,
        icon: widget.fallbackIcon!,
        color: c,
      );
    }

    return AnimatedHeartIcon(size: s, color: c);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.fallbackColor ?? AppColors.primary;
    final accentLight = Color.lerp(accent, Colors.white, 0.2) ?? accent;

    final resolvedTitleColor =
        widget.titleColor ?? (isDark ? Colors.white : Colors.black87);
    final resolvedSubtitleColor = widget.subtitleColor ??
        (isDark ? Colors.grey.shade400 : Colors.grey.shade600);

    final cardGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [Color(0xFF241E31), Color(0xFF181323)]
          : const [Color(0xFFFBF8FF), Color(0xFFF3EDF9)],
    );

    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFECE3FA);

    final showAction =
        widget.onPrimaryAction != null && (widget.primaryActionLabel ?? '').trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: AnimatedBuilder(
          animation: Listenable.merge([_floatCtrl, _pulseCtrl]),
          builder: (context, child) {
            final bob = math.sin(_floatCtrl.value * 2 * math.pi) * 5.0;
            final pulse = 0.75 + (_pulseCtrl.value * 0.35);

            return Transform.translate(
              offset: Offset(0, bob),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: widget.contentMaxWidth),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: cardGradient,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: -26,
                        top: -18,
                        child: _Orb(
                          size: 86,
                          color: accent.withValues(alpha: (isDark ? 0.3 : 0.16) * pulse),
                        ),
                      ),
                      Positioned(
                        right: -18,
                        bottom: -14,
                        child: _Orb(
                          size: 68,
                          color: accentLight.withValues(alpha: (isDark ? 0.22 : 0.14) * pulse),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(26, 30, 26, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: widget.width,
                              height: widget.width,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    accent.withValues(alpha: isDark ? 0.18 : 0.11),
                                    accent.withValues(alpha: isDark ? 0.08 : 0.05),
                                  ],
                                ),
                                border: Border.all(
                                  color: accent.withValues(alpha: isDark ? 0.26 : 0.18),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: _buildAnimatedIcon(),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              widget.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                color: resolvedTitleColor,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: resolvedSubtitleColor,
                                height: 1.5,
                              ),
                            ),
                            if (showAction) ...[
                              const SizedBox(height: 22),
                              _AccentActionButton(
                                label: widget.primaryActionLabel!,
                                onPressed: widget.onPrimaryAction!,
                                color: accent,
                                lightColor: accentLight,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;

  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _AccentActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Color lightColor;

  const _AccentActionButton({
    required this.label,
    required this.onPressed,
    required this.color,
    required this.lightColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [color, lightColor],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingFallbackIcon extends StatefulWidget {
  final double size;
  final IconData icon;
  final Color color;

  const _PulsingFallbackIcon({
    required this.size,
    required this.icon,
    required this.color,
  });

  @override
  State<_PulsingFallbackIcon> createState() => _PulsingFallbackIconState();
}

class _PulsingFallbackIconState extends State<_PulsingFallbackIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
        final scale = 0.92 + (_ctrl.value * 0.14);
        return Transform.scale(
          scale: scale,
          child: Icon(
            widget.icon,
            size: widget.size * 0.44,
            color: widget.color,
          ),
        );
      },
    );
  }
}
