import 'package:get/get.dart';
import 'package:methna_app/app/controllers/profile_controller.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ProfileController>()) {
      Get.lazyPut<ProfileController>(() => ProfileController(), fenix: true);
    }
    if (!Get.isRegistered<SettingsController>()) {
      Get.lazyPut<SettingsController>(() => SettingsController(), fenix: true);
    }
  }
}
