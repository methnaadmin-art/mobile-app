import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../app/controllers/navigation_controller.dart';
import '../../app/controllers/chat_controller.dart';
import '../../core/theme/premium_theme.dart';

/// Premium Floating Glass Bottom Navigation Bar
/// - Floating above screen with margin
/// - Heavy glassmorphism (blur)
/// - Soft shadow
/// - Animated tab transitions
/// - Gold highlight for active tab
class PremiumFloatingNavBar extends GetView<NavigationController> {
  const PremiumFloatingNavBar({super.key});

  static const _tabs = [
    _TabDef(LucideIcons.sparkles, 'discover', 0),
    _TabDef(LucideIcons.users, 'matches', 1),
    _TabDef(LucideIcons.messageCircle, 'messages', 2),
    _TabDef(LucideIcons.user, 'profile', 3),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Obx(() {
      final selected = controller.currentIndex.value;
      final chatCtrl = Get.isRegistered<ChatController>()
          ? Get.find<ChatController>()
          : null;

      return Container(
        margin: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          bottomPad > 0 ? bottomPad + 12 : 20,
        ),
        height: 72,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: AppTheme.white10, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: AppTheme.gold.withValues(alpha: 0.05),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_tabs.length, (i) {
                  final isActive = selected == i;
                  final tab = _tabs[i];
                  final hasBadge = i == 2 && (chatCtrl?.totalUnread ?? 0) > 0;

                  return _NavItem(
                    tab: tab,
                    isActive: isActive,
                    hasBadge: hasBadge,
                    onTap: () => controller.changePage(i),
                  );
                }),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _TabDef {
  final IconData icon;
  final String labelKey;
  final int index;

  const _TabDef(this.icon, this.labelKey, this.index);
}

class _NavItem extends StatefulWidget {
  final _TabDef tab;
  final bool isActive;
  final bool hasBadge;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.hasBadge,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _scaleController.forward().then((_) => _scaleController.reverse());
        widget.onTap();
      },
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Active background pill
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    width: widget.isActive ? 56 : 0,
                    height: widget.isActive ? 48 : 0,
                    decoration: BoxDecoration(
                      gradient: widget.isActive ? AppTheme.goldGradient : null,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: widget.isActive
                          ? [
                              BoxShadow(
                                color: AppTheme.gold.withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                  ),

                  // Icon and label
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              widget.tab.icon,
                              color: widget.isActive
                                  ? AppTheme.background
                                  : AppTheme.white50,
                              size: widget.isActive ? 22 : 24,
                            ),
                          ),

                          // Badge
                          if (widget.hasBadge && !widget.isActive)
                            Positioned(
                              right: -6,
                              top: -4,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppTheme.gold,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.surface,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.gold.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          color: widget.isActive
                              ? AppTheme.background
                              : AppTheme.white50,
                          fontSize: 10,
                          fontWeight: widget.isActive
                              ? FontWeight.w800
                              : FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                        child: Text(widget.tab.labelKey.tr),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 500.ms, delay: (widget.tab.index * 100).ms);
  }
}
