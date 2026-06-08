import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:methna_app/app/controllers/chat_controller.dart';
import 'package:methna_app/app/controllers/navigation_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';

class AppBottomNavBar extends GetView<NavigationController> {
  const AppBottomNavBar({super.key});

  static const _tabs = [
    _BottomTab(LucideIcons.house, 'nav_home'),
    _BottomTab(LucideIcons.compass, 'nav_matches'),
    _BottomTab(LucideIcons.messageCircle, 'nav_chats'),
    _BottomTab(LucideIcons.userCircle2, 'nav_profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final currentIndex = controller.currentIndex.value;
      final chatController = Get.isRegistered<ChatController>()
          ? Get.find<ChatController>()
          : null;
      final activeColor = AppColors.primary;
      final inactiveColor = isDark
          ? Colors.white.withValues(alpha: 0.55)
          : const Color(0xFF8E8A96);

      // Frosted capsule with layered highlights to match the requested style.
      final glassColor = isDark
          ? Colors.black.withValues(alpha: 0.24)
          : Colors.white.withValues(alpha: 0.62);
      final glassBorder = isDark
          ? Colors.white.withValues(alpha: 0.14)
          : Colors.white.withValues(alpha: 0.86);
      final glassShadow = isDark
          ? Colors.black.withValues(alpha: 0.36)
          : const Color(0x332A1D16);
      final innerHighlight = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.58);
      final badgeBorderColor = isDark
          ? const Color(0xCC12131A)
          : Colors.white.withValues(alpha: 0.94);

      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          bottomInset > 0 ? bottomInset + AppSpacing.xs : AppSpacing.sm,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Container(
              height: 66,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: glassColor,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [innerHighlight, glassColor],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: glassBorder, width: 0.9),
                boxShadow: [
                  BoxShadow(
                    color: glassShadow,
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    alignment: Alignment(
                      -1 + (2 * currentIndex / (_tabs.length - 1)),
                      0.88,
                    ),
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      width: 30,
                      height: 4,
                      decoration: BoxDecoration(
                        color: activeColor,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(_tabs.length, (index) {
                      final tab = _tabs[index];
                      final isActive = index == currentIndex;
                      final hasBadge =
                          index == 2 && (chatController?.totalUnread ?? 0) > 0;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => controller.changePage(index),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 26,
                                height: 26,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Center(
                                      child: AnimatedScale(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        scale: isActive ? 1.12 : 1.0,
                                        child: Icon(
                                          tab.icon,
                                          size: 20,
                                          color: isActive
                                              ? activeColor
                                              : inactiveColor,
                                        ),
                                      ),
                                    ),
                                    if (hasBadge)
                                      Positioned(
                                        top: 0,
                                        right: -1,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: AppColors.error,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: badgeBorderColor,
                                              width: 1.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                tab.labelKey.tr,
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isActive ? activeColor : inactiveColor,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeOutCubic,
                                width: isActive ? 5 : 0,
                                height: isActive ? 5 : 0,
                                decoration: BoxDecoration(
                                  color: activeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _BottomTab {
  const _BottomTab(this.icon, this.labelKey);

  final IconData icon;
  final String labelKey;
}
