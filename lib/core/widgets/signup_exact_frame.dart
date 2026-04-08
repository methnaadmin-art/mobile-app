import 'package:flutter/material.dart';
import 'package:methna_app/core/utils/google_fonts_stub.dart';

const Color exactSignupBg = Color(0xFFFBF8FF);
const Color exactSignupBgDark = Color(0xFF1A1625);
const Color exactSignupPurple = Color(0xFF8E2CFF);
const Color exactSignupPurpleEnd = Color(0xFFB454FF);
const Color exactSignupText = Color(0xFF28242F);
const Color exactSignupTextDark = Color(0xFFF0ECF6);
const Color exactSignupMuted = Color(0xFF8B8497);
const Color exactSignupMutedDark = Color(0xFFA8A0B8);
const Color exactSignupSurface = Color(0xFFFFFFFF);
const Color exactSignupSurfaceDark = Color(0xFF252030);
const Color exactSignupBorder = Color(0xFFF0EDF5);
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
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1E1830), exactSignupBgDark]
                : [const Color(0xFFFFFCFF), exactSignupBg],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
            child: Column(
              children: [
                ExactSignupHeader(progress: progress, onBack: onBack),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: bottomInset > 0 ? 14 : 0),
                    child: child,
                  ),
                ),
                const SizedBox(height: 14),
                footer,
              ],
            ),
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
          color: isDark ? exactSignupSurfaceDark : Colors.white,
          shape: const CircleBorder(),
          elevation: 1.5,
          shadowColor: const Color(0x14000000),
          child: InkWell(
            onTap: onBack,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: signupText(isDark),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
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
                  exactSignupPurple,
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
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [exactSignupPurple, exactSignupPurpleEnd],
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: exactSignupPurple.withValues(alpha: 0.28),
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
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
          const SizedBox(height: 26),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.6,
              color: Colors.white.withValues(alpha: 0.82),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 22),
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
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        color: signupSurface(Theme.of(context).brightness == Brightness.dark),
        borderRadius: BorderRadius.circular(30),
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
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: exactSignupMuted,
            ),
          ),
          const SizedBox(height: 18),
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
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: enabled
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [exactSignupPurple, exactSignupPurpleEnd],
                )
              : null,
          color: enabled ? null : const Color(0xFFDEDCE4),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: exactSignupPurple.withValues(alpha: 0.24),
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
            borderRadius: BorderRadius.circular(999),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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

  String _compactHint(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return value;
    return trimmed.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintText = _compactHint(hint);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: signupText(isDark),
            ),
          ),
          const SizedBox(height: 10),
        ],
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          autocorrect: false,
          enableSuggestions: !obscureText,
          scrollPadding: const EdgeInsets.only(bottom: 180),
          textAlign: textAlign,
          textAlignVertical: TextAlignVertical.center,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: signupText(isDark),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
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
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: signupBorder(isDark)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(
                color: exactSignupPurple,
                width: 1.3,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}
