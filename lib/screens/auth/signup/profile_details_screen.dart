import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/utils/validators.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProfileDetailsScreen extends GetView<SignupController> {
  const ProfileDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller.syncStep(AppRoutes.signupProfileDetails);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHintLight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: back arrow + progress ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  _BackArrow(isDark: isDark),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() => _ProgressBar(
                          progress: controller.progressPercent,
                        )),
                  ),
                ],
              ),
            ),

            // ── Scrollable content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: controller.profileFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 28),

                      // Title
                      Text(
                        'profile_details'.tr,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── First name ──
                      _OutlinedField(
                        label: 'first_name'.tr,
                        controller: controller.firstNameController,
                        validator: Validators.name,
                        isDark: isDark,
                        borderColor: borderColor,
                        hintColor: hintColor,
                      ),
                      const SizedBox(height: 20),

                      // ── Last name ──
                      _OutlinedField(
                        label: 'last_name'.tr,
                        controller: controller.lastNameController,
                        validator: Validators.name,
                        isDark: isDark,
                        borderColor: borderColor,
                        hintColor: hintColor,
                      ),
                      const SizedBox(height: 20),

                      // ── Email Address ──
                      _OutlinedField(
                        label: 'email'.tr,
                        controller: controller.emailController,
                        validator: Validators.email,
                        keyboardType: TextInputType.emailAddress,
                        isDark: isDark,
                        borderColor: borderColor,
                        hintColor: hintColor,
                      ),
                      const SizedBox(height: 20),

                      // ── Phone with country code ──
                      _PhoneField(
                        controller: controller.phoneController,
                        validator: Validators.phone,
                        isDark: isDark,
                        borderColor: borderColor,
                        hintColor: hintColor,
                      ),
                      const SizedBox(height: 20),

                      // ── Password ──
                      Obx(() => TextFormField(
                            controller: controller.passwordController,
                            validator: Validators.password,
                            obscureText: controller.obscurePassword.value,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                            decoration: InputDecoration(
                              labelText: 'password'.tr,
                              labelStyle:
                                  TextStyle(fontSize: 13, color: hintColor),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  controller.obscurePassword.value
                                      ? LucideIcons.eyeOff
                                      : LucideIcons.eye,
                                  color: hintColor,
                                  size: 20,
                                ),
                                onPressed: controller.togglePasswordVisibility,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.primary, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: AppColors.error),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.error, width: 2),
                              ),
                            ),
                          )),
                      const SizedBox(height: 20),

                      // ── Confirm Password ──
                      TextFormField(
                        controller: controller.confirmPasswordController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'confirm_password_required'.tr;
                          }
                          if (value != controller.passwordController.text) {
                            return 'passwords_no_match'.tr;
                          }
                          return null;
                        },
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        decoration: InputDecoration(
                          labelText: 'confirm_password'.tr,
                          labelStyle:
                              TextStyle(fontSize: 13, color: hintColor),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.error),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.error, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      const SizedBox(height: 12),

                      // ── Country & City ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Obx(() => DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: controller.selectedCountry.value,
                              decoration: InputDecoration(
                                labelText: 'country'.tr,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                              ),
                              items: controller.arabicCountries.map((c) => DropdownMenuItem(
                                value: c, 
                                child: Text(c.tr, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))
                              )).toList(),
                              onChanged: (val) {
                                if (val != null) controller.onCountryChanged(val);
                              },
                            )),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Obx(() => DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: controller.selectedCity.value.isEmpty && controller.availableCities.isNotEmpty
                                  ? controller.availableCities.first
                                  : (controller.availableCities.contains(controller.selectedCity.value) ? controller.selectedCity.value : null),
                              decoration: InputDecoration(
                                labelText: 'city'.tr,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                              ),
                              items: controller.availableCities.map((city) => DropdownMenuItem(
                                value: city, 
                                child: Text(city.tr, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14))
                              )).toList(),
                              onChanged: (val) {
                                if (val != null) controller.selectedCity.value = val;
                              },
                            )),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom: Continue button ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Obx(() => SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () {
                              if (controller.profileFormKey.currentState!
                                      .validate()) {
                                controller.registerAccount();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              'continue_text'.tr,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Outlined field matching Image 1 ──────────────────────────────────────
class _OutlinedField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool isDark;
  final Color borderColor;
  final Color hintColor;

  const _OutlinedField({
    required this.label,
    required this.controller,
    this.validator,
    this.keyboardType,
    required this.isDark,
    required this.borderColor,
    required this.hintColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      style: TextStyle(
        fontSize: 15,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: hintColor),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }
}

// ─── Phone field with country code prefix ─────────────────────────────────
class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool isDark;
  final Color borderColor;
  final Color hintColor;

  const _PhoneField({
    required this.controller,
    this.validator,
    required this.isDark,
    required this.borderColor,
    required this.hintColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country code box
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🇩🇿', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 4),
              Text(
                '(+213)',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              Icon(LucideIcons.chevronDown,
                  size: 18, color: hintColor),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Phone number input
        Expanded(
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            style: TextStyle(
              fontSize: 15,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: 'phone_hint'.tr,
              hintStyle: TextStyle(color: hintColor, fontSize: 15),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.error, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Progress bar ─────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final double progress;
  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 6,
        backgroundColor: Colors.grey.shade200,
        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
      ),
    );
  }
}

// ─── Reusable back arrow ──────────────────────────────────────────────────
class _BackArrow extends StatelessWidget {
  final bool isDark;
  const _BackArrow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.find<SignupController>().goBack(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          LucideIcons.chevronLeft,
          size: 16,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}
