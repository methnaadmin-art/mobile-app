import 'package:get/get.dart';
import 'package:methna_app/app/controllers/home_controller.dart';
import 'package:methna_app/app/controllers/users_controller.dart';
import 'package:methna_app/app/controllers/chat_controller.dart';
import 'package:methna_app/app/controllers/profile_controller.dart';

class NavigationController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final RxBool isReady = false.obs;

  // Track when each tab was last visited for smart refresh
  final Map<int, DateTime> _lastVisited = {};

  // Debounce: ignore rapid taps within 300ms
  DateTime _lastTap = DateTime(2000);

  @override
  void onInit() {
    super.onInit();
    _lastVisited[0] = DateTime.now(); // Home is the default tab
  }

  @override
  void onReady() {
    super.onReady();
    isReady.value = true;
  }

  void changePage(int index) {
    final now = DateTime.now();
    if (now.difference(_lastTap).inMilliseconds < 300 && index == currentIndex.value) {
      return; // Ignore rapid double-tap on same tab
    }
    _lastTap = now;

    if (index == currentIndex.value) return; // Already on this tab

    currentIndex.value = index;

    // Smart refresh: if tab data is older than 2 minutes, silently refresh
    final lastVisit = _lastVisited[index];
    if (lastVisit != null && now.difference(lastVisit).inMinutes >= 2) {
      _refreshTab(index);
    }
    _lastVisited[index] = now;
  }

  /// Silently refresh a tab's data in the background (no loading spinner).
  void _refreshTab(int index) {
    try {
      switch (index) {
        case 0:
          if (Get.isRegistered<HomeController>()) {
            Get.find<HomeController>().fetchDiscoverUsers();
          }
          break;
        case 1:
          if (Get.isRegistered<UsersController>()) {
            Get.find<UsersController>().refreshUsers();
          }
          break;
        case 2:
          if (Get.isRegistered<ChatController>()) {
            Get.find<ChatController>().fetchConversations();
          }
          break;
        case 3:
          if (Get.isRegistered<ProfileController>()) {
            Get.find<ProfileController>().refreshProfile();
          }
          break;
      }
    } catch (_) {
      // Silently ignore — tab will show cached data
    }
  }

  void goToHome() => changePage(0);
  void goToUsers() => changePage(1);
  void goToChat() => changePage(2);
  void goToProfile() => changePage(3);
}
