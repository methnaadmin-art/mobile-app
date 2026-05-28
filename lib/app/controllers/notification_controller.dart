import 'package:get/get.dart';
import 'package:methna_app/app/data/models/notification_model.dart';
import 'package:methna_app/app/data/services/notification_service.dart';

class NotificationController extends GetxController {
  final NotificationService _service = Get.find<NotificationService>();

  RxBool isLoading = false.obs;
  RxString get selectedCategory => _service.selectedCategory;
  RxInt get unreadCount => _service.unreadCount;
  List<String> get categories => _service.categories;

  List<NotificationModel> get notifications => _service.filteredNotifications;

  @override
  void onInit() {
    super.onInit();
    refreshNotifications();
  }

  Future<void> refreshNotifications() async {
    isLoading.value = true;
    try {
      await _service.fetchNotifications();
      await _service.fetchUnreadCount();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(String id) => _service.markAsRead(id);

  Future<void> markAllAsRead() => _service.markAllAsRead();

  Future<void> deleteNotification(NotificationModel notification) {
    return _service.deleteNotificationEntry(notification);
  }

  Future<bool> clearAllNotifications() => _service.clearAllNotifications();

  void setCategory(String category) => _service.setCategory(category);

  void openNotification(NotificationModel notification) {
    _service.openNotificationFromInbox(notification);
  }
}
