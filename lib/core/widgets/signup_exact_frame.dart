import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/widgets/backend_wait_dots.dart';

const Color exactSignupBg = Color(0xFFFFFFFF);
const Color exactSignupBgDark = Color(0xFF1A1625);
const Color exactSignupPrimary = Color(0xFF6E3DFB);
const Color exactSignupPrimaryEnd = Color(0xFFA78BFA);
const Color exactSignupText = Color(0xFF2E281F);
const Color exactSignupTextDark = Color(0xFFF0ECF6);
const Color exactSignupMuted = Color(0xFF8E806B);
const Color exactSignupMutedDark = Color(0xFFA8A0B8);
const Color exactSignupSurface = Color(0xFFFFFFFF);
const Color exactSignupSurfaceDark = Color(0xFF252030);
const Color exactSignupBorder = Color(0xFFE9E7EF);
const Color exactSignupBorderDark = Color(0xFF3A3445);
const Color exactSignupField = Color(0xFFFFFFFF);
const Color exactSignupFieldDark = Color(0xFF2B2540);

Color signupBg(bool isDark) => isDark ? exactSignupBgDark : exactSignupBg;
Color signupText(bool isDark) => isDark ? exactSignupTextDark : exactSignupText;
Color signupMuted(bool isDark) =>
    isDark ? exactSignupMutedDark : exactSignupMuted;
Color signupSurface(bool isDark) =>
    isDark ? exactSignupSurfaceDark : exactSignupSurface;
Color signupBorder(bool isDark) =>
    isDark ? exactSignupBorderDark : exactSignupBorder;
Color signupField(bool isDark) =>
    isDark ? exactSignupFieldDark : exactSignupField;

class ExactSignupScaffold extends StatelessWidget {
  const ExactSignupScaffold({
    super.key,
    required this.progress,
    required this.onBack,
    required this.child,
    required this.footer,
  });

  final double progress;
  final VoidCallback onBack;
  final Widget child;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: signupBg(isDark),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            children: [
              ExactSignupHeader(progress: progress, onBack: onBack),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(bottom: bottomInset > 0 ? 14 : 0),
                  child: child,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              footer,
            ],
          ),
        ),
      ),
    );
  }
}

class ExactSignupHeader extends StatelessWidget {
  const ExactSignupHeader({
    super.key,
    required this.progress,
    required this.onBack,
  });

  final double progress;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Material(
          color: isDark ? exactSignupSurfaceDark : exactSignupSurface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: signupText(isDark),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: safeProgress,
                backgroundColor: isDark
                    ? const Color(0xFF3A3445)
                    : const Color(0xFFE9E5F0),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  exactSignupPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ExactSignupHeroCard extends StatelessWidget {
  const ExactSignupHeroCard({
    super.key,
    required this.badge,
    required this.icon,
    required this.title,
    required this.description,
    required this.preview,
  });

  final String badge;
  final IconData icon;
  final String title;
  final String description;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [exactSignupPrimary, exactSignupPrimaryEnd],
        ),
        borderRadius: BorderRadius.circular(AppRadii.hero),
        boxShadow: [
          BoxShadow(
            color: exactSignupPrimary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: Text(
                  badge,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: exactSignupText,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.lg),
          preview,
        ],
      ),
    );
  }
}

class ExactSignupSectionCard extends StatelessWidget {
  const ExactSignupSectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: signupSurface(Theme.of(context).brightness == Brightness.dark),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(
          color: signupBorder(Theme.of(context).brightness == Brightness.dark),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x14000000),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              color: exactSignupMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class ExactSignupPrimaryButton extends StatelessWidget {
  const ExactSignupPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !isLoading;
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          gradient: enabled
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [exactSignupPrimary, exactSignupPrimaryEnd],
                )
              : null,
          color: enabled ? null : const Color(0xFFDEDCE4),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: exactSignupPrimary.withValues(alpha: 0.24),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 28,
                      child: BackendWaitDots(
                        color: Colors.white,
                        size: 6,
                        spacing: 4,
                      ),
                    )
                  : Text(
                      label,
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class ExactSignupTextField extends StatelessWidget {
  const ExactSignupTextField({
    super.key,
    this.controller,
    this.label,
    required this.hint,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.suffix,
    this.prefix,
    this.textAlign = TextAlign.start,
    this.inputFormatters,
    this.onChanged,
  });

  final TextEditingController? controller;
  final String? label;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final TextInputAction textInputAction;
  final Widget? suffix;
  final Widget? prefix;
  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.inputLabel.copyWith(color: signupText(isDark)),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          autocorrect: false,
          enableSuggestions: !obscureText,
          scrollPadding: const EdgeInsets.only(bottom: 180),
          textAlign: textAlign,
          textAlignVertical: TextAlignVertical.center,
          onChanged: onChanged,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w400,
            color: signupText(isDark),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? const Color(0xFF706A80) : const Color(0xFFB2AFC0),
            ),
            filled: true,
            fillColor: signupField(isDark),
            prefixIcon: prefix == null
                ? null
                : Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 14),
                      child: prefix,
                    ),
                  ),
            prefixIconConstraints: const BoxConstraints(
              minHeight: 20,
              minWidth: 42,
              maxWidth: 42,
            ),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              borderSide: BorderSide(color: signupBorder(isDark)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              borderSide: const BorderSide(
                color: exactSignupPrimary,
                width: 1.3,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              borderSide: const BorderSide(color: Color(0xFF4F26D9)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              borderSide: const BorderSide(color: Color(0xFF4F26D9)),
            ),
            errorStyle: AppTextStyles.error.copyWith(
              color: const Color(0xFF4F26D9),
            ),
          ),
        ),
      ],
    );
  }
}
