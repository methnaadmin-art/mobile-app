import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/core/utils/validators.dart';
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
        () => ExactSignupPrimaryButton(
          label: 'continue'.tr,
          isLoading: controller.isLoading.value,
          onTap: controller.isLoading.value
              ? null
              : () {
                  if (controller.profileFormKey.currentState!.validate()) {
                    controller.registerAccount();
                  }
                },
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
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 124,
                  child: _CountryCodePickerCard(controller: controller),
                ),
                SizedBox(width: isRtl ? 10 : 12),
                Expanded(
                  child: ExactSignupTextField(
                    controller: controller.phoneController,
                    hint: 'phone_hint'.tr,
                    keyboardType: TextInputType.phone,
                    validator: Validators.phone,
                    prefix: const Icon(
                      LucideIcons.phone,
                      size: 18,
                      color: exactSignupMuted,
                    ),
                  ),
                ),
              ],
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
                    () => _ExactDropdownField(
                      label: 'country'.tr,
                      value: controller.selectedCountry.value,
                      items: controller.arabicCountries,
                      onChanged: (value) {
                        if (value != null) {
                          controller.onCountryChanged(value);
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(width: isRtl ? 10 : 12),
                Expanded(
                  child: Obx(() {
                    final cities = controller.availableCities;
                    final currentValue =
                        cities.contains(controller.selectedCity.value)
                        ? controller.selectedCity.value
                        : (cities.isNotEmpty ? cities.first : null);

                    return _ExactDropdownField(
                      label: 'city'.tr,
                      value: currentValue,
                      items: cities,
                      onChanged: (value) {
                        if (value != null) {
                          controller.selectedCity.value = value;
                        }
                      },
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: signupText(isDark),
        ),
      ),
    );
  }
}

class _CountryCodePickerCard extends StatelessWidget {
  const _CountryCodePickerCard({required this.controller});

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
            style: TextStyle(
              fontSize: 12.8,
              fontWeight: FontWeight.w600,
              color: signupText(isDark),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              showCountryPicker(
                context: context,
                showPhoneCode: true,
                countryListTheme: CountryListThemeData(
                  borderRadius: BorderRadius.circular(16),
                  inputDecoration: InputDecoration(
                    hintText: 'country_picker_search_hint'.tr,
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                onSelect: (Country country) {
                  controller.setPhoneCountry(
                    dialCode: '+${country.phoneCode}',
                    countryCode: country.countryCode,
                    countryName: country.name,
                  );
                  if (controller.arabicCountries.contains(country.name)) {
                    controller.onCountryChanged(country.name);
                  }
                },
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: signupField(isDark),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: signupBorder(isDark)),
              ),
              child: Row(
                textDirection: TextDirection.ltr,
                children: [
                  Text(
                    _flagEmoji(countryCode),
                    style: const TextStyle(fontSize: 16),
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
                          style: TextStyle(
                            fontSize: 14.2,
                            fontWeight: FontWeight.w600,
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

class _ExactDropdownField extends StatelessWidget {
  const _ExactDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.8,
            fontWeight: FontWeight.w600,
            color: signupText(isDark),
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: signupField(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: signupBorder(isDark)),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: signupText(isDark),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: signupMuted(isDark),
            ),
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item.tr, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
