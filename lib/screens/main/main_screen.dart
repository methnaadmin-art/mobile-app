import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/home_controller.dart';
import 'package:methna_app/app/controllers/navigation_controller.dart';
import 'package:methna_app/core/widgets/bottom_nav_bar.dart';
import 'package:methna_app/screens/main/home/home_screen.dart';
import 'package:methna_app/screens/main/users/users_screen.dart';
import 'package:methna_app/screens/main/chat/chat_list_screen.dart';
import 'package:methna_app/screens/main/profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final NavigationController controller = Get.find<NavigationController>();
  final Set<int> _loadedIndexes = <int>{0};

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const UsersScreen();
      case 2:
        return const ChatListScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentIndex = controller.currentIndex.value;
      _loadedIndexes.add(currentIndex);
      final isHome = currentIndex == 0;
        final hideBottomNav =
          isHome &&
          Get.isRegistered<HomeController>() &&
          Get.find<HomeController>().showStartupRadar.value;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final overlayStyle = isDark
          ? SystemUiOverlayStyle.light
          : (isHome ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light);

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          extendBody: true,
          body: IndexedStack(
            index: currentIndex,
            children: List<Widget>.generate(
              4,
              (index) => _loadedIndexes.contains(index)
                  ? _buildPage(index)
                  : const SizedBox.shrink(),
            ),
          ),
          bottomNavigationBar: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: hideBottomNav
                ? const SizedBox.shrink(key: ValueKey('hidden_bottom_nav'))
                : const AppBottomNavBar(key: ValueKey('visible_bottom_nav')),
          ),
        ),
      );
    });
  }
}
