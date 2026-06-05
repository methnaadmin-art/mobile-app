import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_shadows.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';

class AppPhoneField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String dialCode;
  final String countryCode;
  final String? countryName;
  final ValueChanged<Country> onCountrySelected;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction textInputAction;
  final bool enabled;

  const AppPhoneField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.dialCode,
    required this.countryCode,
    required this.onCountrySelected,
    this.countryName,
    this.validator,
    this.inputFormatters,
    this.textInputAction = TextInputAction.next,
    this.enabled = true,
  });

  @override
  State<AppPhoneField> createState() => _AppPhoneFieldState();
}

class _AppPhoneFieldState extends State<AppPhoneField> {
  final FocusNode _focusNode = FocusNode();

  String _flagEmoji(String isoCode) {
    final normalized = isoCode.trim().toUpperCase();
    if (normalized.length != 2) return normalized.isEmpty ? 'UN' : normalized;
    final first = normalized.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final second = normalized.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCodes([first, second]);
  }

  String _compactDialCode(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '+213';
    return trimmed.startsWith('+') ? trimmed : '+$trimmed';
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  void _showCountryPicker() {
    if (!widget.enabled) return;

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
      onSelect: widget.onCountrySelected,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final mutedColor = isDark
        ? AppColors.textHintDark
        : AppColors.textHintLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final fieldColor = isDark
        ? AppColors.surfaceMutedDark
        : AppColors.surfaceMutedLight;

    return FormField<String>(
      initialValue: widget.controller.text,
      validator: widget.validator,
      builder: (field) {
        final activeBorder = field.hasError
            ? AppColors.error
            : (_focusNode.hasFocus ? AppColors.primary : borderColor);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.xs),
              child: Text(
                widget.label,
                style: AppTextStyles.inputLabel.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(
                minHeight: AppSpacing.inputHeight,
              ),
              decoration: BoxDecoration(
                color: fieldColor,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(
                  color: activeBorder,
                  width: field.hasError || _focusNode.hasFocus ? 1.4 : 1,
                ),
                boxShadow: AppShadows.subtleField(
                  isDark,
                  focused: _focusNode.hasFocus,
                ),
              ),
              child: Row(
                textDirection: TextDirection.ltr,
                children: [
                  Tooltip(
                    message: widget.countryName ?? widget.countryCode,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showCountryPicker,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 118,
                            maxWidth: 138,
                            minHeight: AppSpacing.inputHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm + 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: isDark ? 0.16 : 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _flagEmoji(widget.countryCode),
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Flexible(
                                  child: Text(
                                    _compactDialCode(widget.dialCode),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.titleSmall.copyWith(
                                      color: textColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: mutedColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: AppSpacing.inputHeight - AppSpacing.md,
                    color: borderColor,
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      keyboardType: TextInputType.phone,
                      textInputAction: widget.textInputAction,
                      inputFormatters: widget.inputFormatters,
                      onChanged: field.didChange,
                      textAlignVertical: TextAlignVertical.center,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: mutedColor,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  field.errorText ?? '',
                  style: AppTextStyles.error.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
