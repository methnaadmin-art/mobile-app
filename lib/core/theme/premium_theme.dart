import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:methna_app/app/theme/app_colors.dart';

/// Premium rose design system
class AppTheme {
  static const Color background = AppColors.backgroundLight;
  static const Color backgroundSecondary = AppColors.primarySurface;
  static const Color surface = AppColors.surfaceLight;
  static const Color surfaceElevated = AppColors.surfaceMutedLight;

  static const Color primary = AppColors.primary;
  static const Color primaryLight = AppColors.primaryLight;
  static const Color primaryDark = AppColors.primaryDark;

  static const Color gold = AppColors.primary;
  static const Color goldLight = AppColors.primaryLight;
  static const Color goldDark = AppColors.primaryDark;
  static const Color goldGradientStart = AppColors.primary;
  static const Color goldGradientEnd = AppColors.secondary;

  // Utility Colors
  static const Color white = Colors.white;
  static const Color white70 = Colors.white70;
  static const Color white50 = Colors.white54;
  static const Color white30 = Colors.white30;
  static const Color white10 = Colors.white10;
  static const Color white05 = Color(0x0DFFFFFF);

  static const Color error = AppColors.primaryDark;
  static const Color success = AppColors.primaryLight;
  static const Color online = AppColors.primaryLight;

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldGradientStart, goldGradientEnd],
  );

  static const LinearGradient emeraldGradient = AppColors.primaryGradient;

  static const LinearGradient darkSurfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.primarySurface, AppColors.surfaceLight],
  );

  // Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get goldGlow => [
    BoxShadow(
      color: gold.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  // Typography
  static TextStyle get heading1 => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimaryLight,
    letterSpacing: 0,
  );

  static TextStyle get heading2 => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimaryLight,
    letterSpacing: 0,
  );

  static TextStyle get heading3 => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimaryLight,
    letterSpacing: 0,
  );

  static TextStyle get body => const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondaryLight,
    height: 1.5,
  );

  static TextStyle get caption => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textHintLight,
    letterSpacing: 0,
  );

  // System UI
  static SystemUiOverlayStyle get systemUiStyle => const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: background,
    systemNavigationBarIconBrightness: Brightness.dark,
  );
}

/// Glassmorphism Container - Premium glass effect
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double blur;
  final Color? backgroundColor;
  final Border? border;
  final List<BoxShadow>? shadows;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 8,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.blur = 20,
    this.backgroundColor,
    this.border,
    this.shadows,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows ?? AppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ?? AppTheme.white05,
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ?? Border.all(color: AppTheme.white10, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Premium Gold Button with scale animation
class PremiumButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final double borderRadius;
  final Gradient? gradient;
  final EdgeInsets padding;
  final bool isOutlined;

  const PremiumButton({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius = 8,
    this.gradient,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.isOutlined = false,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              gradient: widget.isOutlined
                  ? null
                  : (widget.gradient ?? AppTheme.goldGradient),
              color: widget.isOutlined ? Colors.transparent : null,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: widget.isOutlined
                  ? Border.all(color: AppTheme.gold, width: 1.5)
                  : null,
              boxShadow: widget.isOutlined
                  ? null
                  : [
                      BoxShadow(
                        color: AppTheme.gold.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
              child: DefaultTextStyle(
                style: TextStyle(
                color: widget.isOutlined ? AppTheme.gold : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular Gold Progress Indicator with Glow
class GoldCircularProgress extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final bool showGlow;
  final Widget? center;

  const GoldCircularProgress({
    super.key,
    required this.value,
    this.size = 80,
    this.strokeWidth = 6,
    this.showGlow = true,
    this.center,
  });

  @override
  State<GoldCircularProgress> createState() => _GoldCircularProgressState();
}

class _GoldCircularProgressState extends State<GoldCircularProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(GoldCircularProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _progressAnimation =
          Tween<double>(
            begin: _progressAnimation.value,
            end: widget.value,
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: widget.showGlow && _progressAnimation.value > 0.7
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.gold.withValues(
                        alpha: 0.4 * _progressAnimation.value,
                      ),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                  ],
                )
              : null,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _GoldProgressPainter(
              progress: _progressAnimation.value,
              strokeWidth: widget.strokeWidth,
            ),
            child: Center(child: widget.center),
          ),
        );
      },
    );
  }
}

class _GoldProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  _GoldProgressPainter({required this.progress, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = AppTheme.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Gold gradient arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      center: Alignment.center,
      startAngle: -90 * 3.14159 / 180,
      endAngle: (-90 + 360 * progress) * 3.14159 / 180,
      colors: const [
        AppTheme.goldGradientStart,
        AppTheme.goldGradientEnd,
        AppTheme.goldGradientStart,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final fgPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -90 * 3.14159 / 180,
      360 * progress * 3.14159 / 180,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Animated Heart Burst for Like Action
class HeartBurstAnimation extends StatefulWidget {
  final VoidCallback onComplete;

  const HeartBurstAnimation({super.key, required this.onComplete});

  @override
  State<HeartBurstAnimation> createState() => _HeartBurstAnimationState();
}

class _HeartBurstAnimationState extends State<HeartBurstAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scale = Tween<double>(
      begin: 0.5,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) => widget.onComplete());
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
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: const Icon(Icons.favorite, color: AppTheme.gold, size: 100),
          ),
        );
      },
    );
  }
}

/// Premium Card with hover/press effect
class PremiumCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;

  const PremiumCard({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = 8,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _elevation = Tween<double>(begin: 0, end: 8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _elevation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -_elevation.value / 2),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(color: AppTheme.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.3 + (_elevation.value / 20),
                    ),
                    blurRadius: 20 + _elevation.value,
                    offset: Offset(0, 8 + _elevation.value / 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}
