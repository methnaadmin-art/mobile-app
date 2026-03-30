import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/controllers/signup_data.dart';
import 'package:methna_app/app/routes/app_routes.dart';

class FaithReligionScreen extends GetView<SignupController> {
  const FaithReligionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller.syncStep(AppRoutes.signupFaithReligion);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : Colors.white;
    final cardColor = isDark ? AppColors.cardDark : Colors.white;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
                      onPressed: () => controller.goBack(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'faith_and_religion'.tr,
                            style:  TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'tell_us_about_your_faith'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildSection(
                        title: 'sect'.tr,
                        icon: Icons.mosque,
                        options: SignupData.sects,
                        selectedOption: controller.selectedSect,
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        title: 'religious_level'.tr,
                        icon: Icons.auto_awesome,
                        options: SignupData.religiousLevels,
                        selectedOption: controller.selectedReligiousLevel,
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        title: 'prayer_frequency'.tr,
                        icon: Icons.query_builder,
                        options: SignupData.prayerFrequencies,
                        selectedOption: controller.selectedPrayerFrequency,
                      ),
                      const SizedBox(height: 20),
                      
                      // Diet & Smoking
                      _buildSection(
                        title: 'dietary_preference'.tr,
                        icon: Icons.restaurant,
                        options: SignupData.dietaryPreferences,
                        selectedOption: controller.selectedDietary,
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        title: 'alcohol_usage'.tr,
                        icon: Icons.local_drink,
                        options: SignupData.alcoholPreferences,
                        selectedOption: controller.selectedAlcohol,
                      ),
                      const SizedBox(height: 20),
                      Obx(() => controller.selectedGender.value.toLowerCase() == 'female' 
                        ? Column(
                            children: [
                              _buildSection(
                                title: 'hijab_status'.tr,
                                icon: Icons.face_2,
                                options: SignupData.hijabStatuses,
                                selectedOption: controller.selectedHijab,
                              ),
                              const SizedBox(height: 20),
                            ],
                          )
                        : const SizedBox.shrink()
                      ),

                      // Continue Button
                      ElevatedButton(
                        onPressed: () => controller.navigateTo(AppRoutes.signupHobbies),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: AppColors.primary.withValues(alpha: 0.5),
                        ),
                        child: Text(
                          'continue'.tr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<String> options,
    required RxString selectedOption,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).brightness == Brightness.dark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(Get.context!).brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(Get.context!).brightness == Brightness.dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Obx(() => Column(
                children: options.map((option) {
                  final selected = selectedOption.value == option;
                  return GestureDetector(
                    onTap: () => selectedOption.value = option,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? AppColors.primary : (Theme.of(Get.context!).brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderLight),
                                width: 2,
                              ),
                            ),
                            child: selected?
                                     Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primary,
                                      ),
                                    )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            option.tr,
                            style: TextStyle(
                              fontSize: 15, 
                              color: Theme.of(Get.context!).brightness == Brightness.dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              )),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required IconData icon,
    required RxBool value,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15, 
              color: Theme.of(Get.context!).brightness == Brightness.dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight
            ),
          ),
        ),
        Obx(() => Switch(
              value: value.value,
              onChanged: (val) => value.value = val,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
            )),
      ],
    );
  }
}
