import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import 'package:get/get.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/utils/validators.dart';
import 'package:methna_app/core/widgets/app_phone_field.dart';
import 'package:methna_app/core/widgets/signup_exact_frame.dart';

class ProfileDetailsScreen extends GetView<SignupController> {
  const ProfileDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller.syncStep(AppRoutes.signupProfileDetails);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return ExactSignupScaffold(
      progress: controller.progressPercent,
      onBack: controller.goBack,
      footer: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PrivacyTermsCheckbox(controller: controller),
            const SizedBox(height: 10),
            _RegistrationOathCheckbox(controller: controller),
            const SizedBox(height: 12),
            ExactSignupPrimaryButton(
              label: 'continue'.tr,
              isLoading: controller.isLoading.value,
              onTap: controller.isLoading.value
                  ? null
                  : () {
                      if (!controller.agreePrivacy.value) {
                        Get.snackbar(
                          '',
                          'must_agree_terms'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.error,
                          colorText: Colors.white,
                          margin: const EdgeInsets.all(16),
                        );
                        return;
                      }
                      if (!controller.agreeOath.value) {
                        Get.snackbar(
                          '',
                          'must_agree_registration_oath'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.error,
                          colorText: Colors.white,
                          margin: const EdgeInsets.all(16),
                        );
                        return;
                      }
                      if (controller.selectedCity.value.trim().isEmpty) {
                        Get.snackbar(
                          '',
                          'select_city_validation'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.error,
                          colorText: Colors.white,
                          margin: const EdgeInsets.all(16),
                        );
                        return;
                      }
                      if (controller.profileFormKey.currentState!.validate()) {
                        controller.registerAccount();
                      }
                    },
            ),
          ],
        ),
      ),
      child: Form(
        key: controller.profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'profile_details'.tr,
              style: AppTextStyles.screenTitle.copyWith(
                fontWeight: FontWeight.w800,
                height: isRtl ? 1.32 : 1.2,
                color: signupText(isDark),
              ),
            ),
            const SizedBox(height: 14),
            _FlatSectionTitle('account_section'.tr),
            Row(
              children: [
                Expanded(
                  child: ExactSignupTextField(
                    controller: controller.firstNameController,
                    hint: 'first_name'.tr,
                    validator: Validators.name,
                  ),
                ),
                SizedBox(width: isRtl ? 10 : 12),
                Expanded(
                  child: ExactSignupTextField(
                    controller: controller.lastNameController,
                    hint: 'last_name'.tr,
                    validator: Validators.name,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FlatSectionTitle('contact_section'.tr),
            ExactSignupTextField(
              controller: controller.emailController,
              hint: 'email_hint'.tr,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
              prefix: const Icon(
                LucideIcons.mail,
                size: 18,
                color: exactSignupMuted,
              ),
            ),
            const SizedBox(height: 14),
            Obx(
              () => AppPhoneField(
                controller: controller.phoneController,
                label: 'phone_label'.tr,
                hint: 'phone_hint'.tr,
                dialCode: controller.selectedPhoneDialCode.value,
                countryCode: controller.selectedPhoneCountryCode.value,
                countryName: controller.selectedPhoneCountryName.value,
                onCountrySelected: (country) {
                  controller.setPhoneCountry(
                    dialCode: '+${country.phoneCode}',
                    countryCode: country.countryCode,
                    countryName: country.name,
                  );
                  controller.onCountryChanged(country.name);
                },
                validator: Validators.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  const _PhoneNumberFormatter(),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _FlatSectionTitle('security_section'.tr),
            Obx(
              () => ExactSignupTextField(
                controller: controller.passwordController,
                hint: 'password_hint'.tr,
                obscureText: controller.obscurePassword.value,
                validator: Validators.password,
                prefix: const Icon(
                  LucideIcons.lock,
                  size: 18,
                  color: exactSignupMuted,
                ),
                suffix: IconButton(
                  onPressed: controller.togglePasswordVisibility,
                  icon: Icon(
                    controller.obscurePassword.value
                        ? LucideIcons.eyeOff
                        : LucideIcons.eye,
                    size: 18,
                    color: exactSignupMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ExactSignupTextField(
              controller: controller.confirmPasswordController,
              hint: 'confirm_password'.tr,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'confirm_password_required'.tr;
                }
                if (value != controller.passwordController.text) {
                  return 'passwords_no_match'.tr;
                }
                return null;
              },
              prefix: const Icon(
                LucideIcons.lock,
                size: 18,
                color: exactSignupMuted,
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 14),
            _FlatSectionTitle('location_section'.tr),
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => _CountryPickerField(
                      label: 'country'.tr,
                      value: controller.selectedCountry.value,
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          showPhoneCode: true,
                          countryListTheme: CountryListThemeData(
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            inputDecoration: InputDecoration(
                              hintText: 'country_picker_search_hint'.tr,
                              prefixIcon: const Icon(Icons.search_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.lg,
                                ),
                              ),
                            ),
                          ),
                          onSelect: (country) {
                            controller.onCountryChanged(country.name);
                            controller.setPhoneCountry(
                              dialCode: '+${country.phoneCode}',
                              countryCode: country.countryCode,
                              countryName: country.name,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(width: isRtl ? 10 : 12),
                Expanded(
                  child: Obx(
                    () => _CountryPickerField(
                      label: 'city'.tr,
                      value: controller.selectedCity.value,
                      onTap: () => _showCityPicker(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'family_responsibility_notice'.tr,
              style: AppTextStyles.caption.copyWith(
                color: signupMuted(isDark),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCityPicker(BuildContext context) async {
    final cities = controller.availableCities;
    if (cities.isEmpty) {
      Get.snackbar(
        '',
        'select_country_first'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final selectedCity = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('city'.tr, style: AppTextStyles.titleLarge),
                const SizedBox(height: 12),
                SizedBox(
                  height: MediaQuery.of(sheetContext).size.height * 0.45,
                  child: ListView.separated(
                    itemCount: cities.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (_, index) {
                      final city = cities[index];
                      final selected = city == controller.selectedCity.value;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(sheetContext).pop(city),
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.borderLight,
                              ),
                              color: selected
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text(city)),
                                if (selected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedCity == null || selectedCity.trim().isEmpty) return;
    controller.cityController.text = selectedCity;
    controller.selectedCity.value = selectedCity;
  }
}

class _PasswordRequirementsHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark
        ? AppColors.textHintDark
        : AppColors.textHintLight;

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'password_requirements_title'.tr,
            style: AppTextStyles.caption.copyWith(
              color: mutedColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          _ReqRow(text: 'password_req_length'.tr, color: mutedColor),
          _ReqRow(text: 'password_req_uppercase'.tr, color: mutedColor),
          _ReqRow(text: 'password_req_lowercase'.tr, color: mutedColor),
          _ReqRow(text: 'password_req_number'.tr, color: mutedColor),
        ],
      ),
    );
  }
}

class _ReqRow extends StatelessWidget {
  const _ReqRow({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(LucideIcons.dot, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _PrivacyTermsCheckbox extends StatelessWidget {
  const _PrivacyTermsCheckbox({required this.controller});

  final SignupController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Obx(
      () => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: controller.agreePrivacy.value,
              onChanged: (value) => controller.agreePrivacy.value = value ?? false,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'agree_terms_prefix'.tr,
                  style: AppTextStyles.caption.copyWith(color: textColor),
                ),
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.termsConditions),
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'terms_of_service_link'.tr,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  'and_text'.tr,
                  style: AppTextStyles.caption.copyWith(color: textColor),
                ),
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'privacy_policy_link'.tr,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlatSectionTitle extends StatelessWidget {
  final String title;

  const _FlatSectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        title,
        style: AppTextStyles.inputLabel.copyWith(color: signupText(isDark)),
      ),
    );
  }
}

class _RegistrationOathCheckbox extends StatelessWidget {
  const _RegistrationOathCheckbox({required this.controller});

  final SignupController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Obx(
      () => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: controller.agreeOath.value,
              onChanged: (value) =>
                  controller.agreeOath.value = value ?? false,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'registration_oath_label'.tr,
                style: AppTextStyles.caption.copyWith(
                  color: textColor,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CountryCodePickerCardLegacy extends StatelessWidget {
  const CountryCodePickerCardLegacy({super.key, required this.controller});

  final SignupController controller;

  String _flagEmoji(String isoCode) {
    final normalized = isoCode.trim().toUpperCase();
    if (normalized.length != 2) return '🌍';
    final first = normalized.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final second = normalized.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCodes([first, second]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Obx(() {
      final dialCode = controller.selectedPhoneDialCode.value.trim().isEmpty
          ? '+213'
          : controller.selectedPhoneDialCode.value.trim();
      final countryCode = controller.selectedPhoneCountryCode.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'code'.tr,
            style: AppTextStyles.inputLabel.copyWith(color: signupText(isDark)),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              showCountryPicker(
                context: context,
                showPhoneCode: true,
                countryListTheme: CountryListThemeData(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  inputDecoration: InputDecoration(
                    hintText: 'country_picker_search_hint'.tr,
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                    ),
                  ),
                ),
                onSelect: (Country country) {
                  controller.setPhoneCountry(
                    dialCode: '+${country.phoneCode}',
                    countryCode: country.countryCode,
                    countryName: country.name,
                  );
                  controller.onCountryChanged(country.name);
                },
              );
            },
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: signupField(isDark),
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: signupBorder(isDark)),
              ),
              child: Row(
                textDirection: TextDirection.ltr,
                children: [
                  Text(
                    _flagEmoji(countryCode),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: signupText(isDark),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          dialCode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: signupText(isDark),
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: signupMuted(isDark),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _CountryPickerField extends StatelessWidget {
  const _CountryPickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.inputLabel.copyWith(color: signupText(isDark)),
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Container(
            height: AppSpacing.inputHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: signupField(isDark),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: signupBorder(isDark)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value.trim().isEmpty ? 'country'.tr : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w400,
                      color: signupText(isDark),
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: signupMuted(isDark),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PhoneNumberFormatter extends TextInputFormatter {
  const _PhoneNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && index % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[index]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
