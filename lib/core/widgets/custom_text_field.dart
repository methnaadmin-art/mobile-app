import 'package:flutter/material.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_shadows.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String hint;
  final String? label;
  final String? initialValue;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final bool enabled;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final TextAlign textAlign;

  const CustomTextField({
    super.key,
    this.controller,
    required this.hint,
    this.label,
    this.initialValue,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
    this.textAlign = TextAlign.start,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.surfaceMutedDark
        : AppColors.surfaceMutedLight;
    final borderColor = _isFocused
        ? AppColors.primary
        : (isDark ? AppColors.borderDark : AppColors.borderLight);
    final iconColor = _isFocused
        ? AppColors.primary
        : (isDark ? AppColors.textHintDark : AppColors.textHintLight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.xs),
            child: Text(
              widget.label!,
              style: AppTextStyles.inputLabel.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: borderColor, width: _isFocused ? 1.4 : 1),
            boxShadow: AppShadows.subtleField(isDark, focused: _isFocused),
          ),
          child: TextFormField(
            controller: widget.controller,
            initialValue: widget.controller == null
                ? widget.initialValue
                : null,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onTap: widget.onTap,
            readOnly: widget.readOnly,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            textInputAction: widget.textInputAction,
            focusNode: _focusNode,
            textAlign: widget.textAlign,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w400,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textHintDark
                    : AppColors.textHintLight,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Container(
                        key: ValueKey<bool>(_isFocused),
                        margin: const EdgeInsets.only(left: 6, right: 2),
                        child: Icon(
                          widget.prefixIcon,
                          size: 19,
                          color: iconColor,
                        ),
                      ),
                    )
                  : null,
              suffixIcon: widget.suffix,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              errorStyle: AppTextStyles.error.copyWith(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }
}
