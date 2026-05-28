import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';

Future<void> showDeleteAccountFlow(
  BuildContext context,
  SettingsController controller,
) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final continueToFinal = await Get.dialog<bool>(
    AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      title: Text('delete_account'.tr),
      content: Text('delete_account_confirm'.tr),
      actions: [
        TextButton(
          onPressed: () => Get.back<bool>(result: false),
          child: Text('cancel'.tr),
        ),
        FilledButton(
          onPressed: () => Get.back<bool>(result: true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: Text('continue_text'.tr),
        ),
      ],
    ),
  );

  if (continueToFinal != true) return;

  await Get.dialog<void>(
    Obx(
      () => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: Text('delete_account'.tr),
        content: Text('delete_account_second_confirm'.tr),
        actions: [
          TextButton(
            onPressed: controller.isDeletingAccount.value
                ? null
                : () => Get.back<void>(),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: controller.isDeletingAccount.value
                ? null
                : () async {
                    await controller.deleteAccount();
                  },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: controller.isDeletingAccount.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text('delete'.tr),
          ),
        ],
      ),
    ),
  );
}
