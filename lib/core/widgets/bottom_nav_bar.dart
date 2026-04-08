import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/chat_controller.dart';
import 'package:methna_app/app/controllers/navigation_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/utils/google_fonts_stub.dart';

class AppBottomNavBar extends GetView<NavigationController> {
  const AppBottomNavBar({super.key});

  static const _tabs = [
    _BottomTab(LucideIcons.flame, 'nav_home'),
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
          ? Colors.white.withValues(alpha: 0.74)
          : const Color(0xFF5E596A);
      final glassColor = isDark
          ? const Color(0x7A121319)
          : const Color(0x8AFFFFFF);
      final glassBorder = isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.07);
      final badgeBorderColor = isDark
          ? const Color(0xCC12131A)
          : Colors.white.withValues(alpha: 0.94);

      return Padding(
        padding: EdgeInsets.fromLTRB(
          14,
          0,
          14,
          bottomInset > 0 ? bottomInset + 8 : 10,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              height: 66,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              decoration: BoxDecoration(
                color: glassColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: glassBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.14),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  final tab = _tabs[index];
                  final isActive = index == currentIndex;
                  final hasBadge =
                      index == 2 && (chatController?.totalUnread ?? 0) > 0;

                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => controller.changePage(index),
                        borderRadius: BorderRadius.circular(18),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          decoration: isActive
                              ? BoxDecoration(
                                  color: activeColor.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: activeColor.withValues(alpha: 0.4),
                                  ),
                                )
                              : null,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Center(
                                      child: AnimatedScale(
                                        duration: const Duration(milliseconds: 180),
                                        scale: isActive ? 1.07 : 1.0,
                                        child: Icon(
                                          tab.icon,
                                          size: index == 3 ? 18.4 : 18,
                                          color: isActive
                                              ? activeColor
                                              : inactiveColor,
                                        ),
                                      ),
                                    ),
                                    if (hasBadge)
                                      Positioned(
                                        top: 1,
                                        right: 0,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: activeColor,
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
                              const SizedBox(height: 4),
                              Text(
                                tab.labelKey.tr,
                                style: GoogleFonts.poppins(
                                  fontSize: 9.2,
                                  fontWeight:
                                      isActive ? FontWeight.w600 : FontWeight.w500,
                                  color: isActive ? activeColor : inactiveColor,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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

class _BottomTab {
  const _BottomTab(this.icon, this.labelKey);

  final IconData icon;
  final String labelKey;
}
