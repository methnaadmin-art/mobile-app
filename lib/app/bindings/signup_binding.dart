import 'package:get/get.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';

class SignupBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SignupController>()) {
      Get.put<SignupController>(SignupController());
    }
  }
}
