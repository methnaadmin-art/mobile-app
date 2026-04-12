import 'package:flutter/material.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';

const Color signupMockPurple = Color(0xFF9627FF);
const Color signupMockPurpleEnd = Color(0xFF7B1FFF);
const Color signupMockText = Color(0xFF25222D);
const Color signupMockTextDark = Color(0xFFF0ECF6);
const Color signupMockMuted = Color(0xFF8D8897);
const Color signupMockMutedDark = Color(0xFFA8A0B8);
const Color signupMockBorder = Color(0xFFE9E7EF);
const Color signupMockBorderDark = Color(0xFF3A3445);
const Color signupMockSurface = Color(0xFFF7F6FA);
const Color signupMockSurfaceDark = Color(0xFF252030);

Color _mockText(bool d) => d ? signupMockTextDark : signupMockText;
Color _mockMuted(bool d) => d ? signupMockMutedDark : signupMockMuted;
Color _mockBorder(bool d) => d ? signupMockBorderDark : signupMockBorder;
Color _mockBg(bool d) => d ? const Color(0xFF14101E) : Colors.white;
Color _mockCardBg(bool d) => d ? signupMockSurfaceDark : Colors.white;

class SignupMockScaffold extends StatelessWidget {
  const SignupMockScaffold({
    super.key,
    required this.progress,
    required this.onBack,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.footer,
  });

  final double progress;
  final VoidCallback onBack;
  final String title;
  final String subtitle;
  final Widget body;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: _mockBg(isDark),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    splashRadius: 18,
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: _mockText(isDark),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 6,
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: isDark ? const Color(0xFF3A3445) : const Color(0xFFE9E7ED),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            signupMockPurple,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  title,
                  style: AppTextStyles.screenTitle.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _mockText(isDark),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    height: 1.55,
                    color: _mockMuted(isDark),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Expanded(child: body),
              const SizedBox(height: 12),
              footer,
            ],
          ),
        ),
      ),
    );
  }
}

class SignupMockPrimaryButton extends StatelessWidget {
  const SignupMockPrimaryButton({
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
      height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: enabled
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [signupMockPurple, signupMockPurpleEnd],
                )
              : null,
          color: enabled ? null : const Color(0xFFD8D4E1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(999),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: AppTextStyles.button.copyWith(
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

class SignupMockWideOption extends StatelessWidget {
  const SignupMockWideOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: selected
                  ? const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [signupMockPurple, signupMockPurpleEnd],
                    )
                  : null,
              color: selected ? null : _mockCardBg(Theme.of(context).brightness == Brightness.dark),
              border: Border.all(
                color: selected ? Colors.transparent : _mockBorder(Theme.of(context).brightness == Brightness.dark),
              ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.button.copyWith(
                      fontSize: 14,
                      color: selected ? Colors.white : _mockText(Theme.of(context).brightness == Brightness.dark),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 6),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SignupMockCardOption extends StatelessWidget {
  const SignupMockCardOption({
    super.key,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: _mockCardBg(Theme.of(context).brightness == Brightness.dark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? signupMockPurple : _mockBorder(Theme.of(context).brightness == Brightness.dark),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  color: _mockText(Theme.of(context).brightness == Brightness.dark),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  height: 1.5,
                  color: _mockMuted(Theme.of(context).brightness == Brightness.dark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignupMockChip extends StatelessWidget {
  const SignupMockChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? signupMockPurple : _mockCardBg(Theme.of(context).brightness == Brightness.dark),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? signupMockPurple : _mockBorder(Theme.of(context).brightness == Brightness.dark),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : _mockText(Theme.of(context).brightness == Brightness.dark),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
