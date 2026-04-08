import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/locale_controller.dart';
import 'package:methna_app/app/data/services/storage_service.dart';
import 'package:methna_app/app/controllers/login_controller.dart';
import 'package:methna_app/core/constants/app_constants.dart';
import 'package:methna_app/core/utils/validators.dart';
import 'package:methna_app/core/widgets/login_security_avatar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _purple = Color(0xFF8A14FF);
  static const Color _purpleLight = Color(0xFFA93CFF);

  final LoginController controller = Get.find<LoginController>();
  final LocaleController _localeController = Get.find<LocaleController>();
  final StorageService _storage = Get.find<StorageService>();
  bool _showEmailForm = false;

  void _toggleTheme() {
    final useLight = Get.isDarkMode;
    _storage.setThemeMode(useLight ? 'light' : 'dark');
    Get.changeThemeMode(useLight ? ThemeMode.light : ThemeMode.dark);
    setState(() {});
  }

  void _changeLanguage(String langCode) {
    if (langCode == 'ar') {
      _localeController.switchToArabic();
    } else {
      _localeController.switchToEnglish();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E1A28) : const Color(0xFFF7F7FA);
    final border = isDark ? const Color(0xFF3A3445) : const Color(0xFFEAEAF0);
    final textPrimary = isDark
        ? const Color(0xFFF0ECF6)
        : const Color(0xFF222222);
    final textSecondary = isDark
        ? const Color(0xFFA8A0B8)
        : const Color(0xFF91919A);
    final bgColor = isDark ? const Color(0xFF14101E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.opaque,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, animation) {
                    final curved = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    );
                    final slide = Tween<Offset>(
                      begin: const Offset(0.08, 0),
                      end: Offset.zero,
                    ).animate(curved);

                    return FadeTransition(
                      opacity: curved,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: _showEmailForm
                      ? Form(
                          key: controller.formKey,
                          child: _EmailLoginView(
                            key: const ValueKey('email-login'),
                            controller: controller,
                            onBack: () =>
                                setState(() => _showEmailForm = false),
                            purple: _purple,
                            purpleLight: _purpleLight,
                            surface: surface,
                            border: border,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),
                        )
                      : _EntryLoginView(
                          key: const ValueKey('entry-login'),
                          controller: controller,
                          onEmailLogin: () =>
                              setState(() => _showEmailForm = true),
                          purple: _purple,
                          purpleLight: _purpleLight,
                          border: border,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 10,
              child: Row(
                children: [
                  _LoginQuickActionButton(
                    icon: isDark ? LucideIcons.sun : LucideIcons.moon,
                    onTap: _toggleTheme,
                    tooltip: isDark ? 'light'.tr : 'dark'.tr,
                    border: border,
                    foreground: textPrimary,
                    background: surface,
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    initialValue: _localeController
                        .currentLocale
                        .value
                        .languageCode
                        .toLowerCase(),
                    onSelected: _changeLanguage,
                    tooltip: 'language'.tr,
                    itemBuilder: (context) {
                      final currentLang = _localeController
                          .currentLocale
                          .value
                          .languageCode
                          .toLowerCase();
                      return [
                        CheckedPopupMenuItem<String>(
                          value: 'en',
                          checked: currentLang == 'en',
                          child: Text('language_english'.tr),
                        ),
                        CheckedPopupMenuItem<String>(
                          value: 'ar',
                          checked: currentLang == 'ar',
                          child: Text('language_arabic'.tr),
                        ),
                      ];
                    },
                    child: _LoginQuickActionButton(
                      icon: LucideIcons.languages,
                      onTap: null,
                      tooltip: 'language'.tr,
                      border: border,
                      foreground: textPrimary,
                      background: surface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginQuickActionButton extends StatelessWidget {
  const _LoginQuickActionButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    required this.border,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final Color border;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              border: Border.all(color: border),
            ),
            child: Icon(icon, size: 17, color: foreground),
          ),
        ),
      ),
    );
  }
}

class _EntryLoginView extends StatelessWidget {
  final LoginController controller;
  final VoidCallback onEmailLogin;
  final Color purple;
  final Color purpleLight;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  const _EntryLoginView({
    super.key,
    required this.controller,
    required this.onEmailLogin,
    required this.purple,
    required this.purpleLight,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 760;

        return ListView(
          physics: const ClampingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            22,
            compact ? 14 : 26,
            22,
            safeBottom + 16,
          ),
          children: [
            SizedBox(height: compact ? 4 : 14),
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: ClipOval(
                  child: Image.asset(
                    AppConstants.appLogoAsset,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              AppConstants.appName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'app_tagline'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: textSecondary,
              ),
            ),
            SizedBox(height: compact ? 22 : 34),
            Obx(
              () => _SocialButton(
                label: 'continue_with_google'.tr,
                icon: const _BrandIcon.google(),
                onTap: controller.isGoogleLoading.value
                    ? null
                    : controller.signInWithGoogle,
                isLoading: controller.isGoogleLoading.value,
                border: border,
                textPrimary: textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            _SocialButton(
              label: 'continue_with_apple'.tr,
              icon: const _BrandIcon.apple(),
              onTap: null,
              border: border,
              textPrimary: textPrimary,
              comingSoon: true,
            ),
            const SizedBox(height: 14),
            _SocialButton(
              label: 'continue_with_facebook'.tr,
              icon: const _BrandIcon.facebook(),
              onTap: null,
              border: border,
              textPrimary: textPrimary,
              comingSoon: true,
            ),
            const SizedBox(height: 14),
            _SocialButton(
              label: 'continue_with_twitter'.tr,
              icon: const _BrandIcon.twitter(),
              onTap: null,
              border: border,
              textPrimary: textPrimary,
              comingSoon: true,
            ),
            SizedBox(height: compact ? 22 : 34),
            _PrimaryAuthButton(
              label: 'login'.tr,
              onTap: onEmailLogin,
              purple: purple,
              purpleLight: purpleLight,
            ),
            const SizedBox(height: 18),
            _FooterSignupRow(
              textSecondary: textSecondary,
              purple: purple,
              onTap: controller.goToSignUp,
            ),
          ],
        );
      },
    );
  }
}

class _EmailLoginView extends StatelessWidget {
  final LoginController controller;
  final VoidCallback onBack;
  final Color purple;
  final Color purpleLight;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  const _EmailLoginView({
    super.key,
    required this.controller,
    required this.onBack,
    required this.purple,
    required this.purpleLight,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ListView(
      physics: const ClampingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(22, 6, 22, bottomInset + 18),
      children: [
        _EmailLoginContent(
          controller: controller,
          onBack: onBack,
          purple: purple,
          purpleLight: purpleLight,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          keyboardVisible: bottomInset > 0,
        ),
      ],
    );
  }
}

class _EmailLoginContent extends StatefulWidget {
  final LoginController controller;
  final VoidCallback onBack;
  final Color purple;
  final Color purpleLight;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final bool keyboardVisible;

  const _EmailLoginContent({
    required this.controller,
    required this.onBack,
    required this.purple,
    required this.purpleLight,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.keyboardVisible,
  });

  @override
  State<_EmailLoginContent> createState() => _EmailLoginContentState();
}

class _EmailLoginContentState extends State<_EmailLoginContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _formRevealCtrl;
  late final FocusNode _identifierFocusNode;
  late final FocusNode _passwordFocusNode;

  @override
  void initState() {
    super.initState();
    _formRevealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _identifierFocusNode = FocusNode()..addListener(_handleStateChange);
    _passwordFocusNode = FocusNode()..addListener(_handleStateChange);
    widget.controller.passwordController.addListener(_handleStateChange);
    widget.controller.emailController.addListener(_handleStateChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _formRevealCtrl.forward();
    });
  }

  @override
  void dispose() {
    _formRevealCtrl.dispose();
    _identifierFocusNode
      ..removeListener(_handleStateChange)
      ..dispose();
    _passwordFocusNode
      ..removeListener(_handleStateChange)
      ..dispose();
    widget.controller.passwordController.removeListener(_handleStateChange);
    widget.controller.emailController.removeListener(_handleStateChange);
    super.dispose();
  }

  void _handleStateChange() {
    if (!mounted) return;
    setState(() {});
  }

  Widget _staggered({
    required double begin,
    required double end,
    required Widget child,
  }) {
    final animation = CurvedAnimation(
      parent: _formRevealCtrl,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );

    final slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(animation);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: slide, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final onBack = widget.onBack;
    final purple = widget.purple;
    final purpleLight = widget.purpleLight;
    final surface = widget.surface;
    final border = widget.border;
    final textPrimary = widget.textPrimary;
    final textSecondary = widget.textSecondary;
    final keyboardVisible = widget.keyboardVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(LucideIcons.arrowLeft, size: 20, color: textPrimary),
          ),
        ),
        SizedBox(height: keyboardVisible ? 20 : 34),
        _staggered(
          begin: 0.0,
          end: 0.34,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'welcome_back'.tr,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -1.0,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'login_subtitle'.tr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: keyboardVisible ? 18 : 22),
        _staggered(
          begin: 0.12,
          end: 0.5,
          child: Center(
            child: Obx(
              () => LoginSecurityAvatar(
                isPasswordFocused: _passwordFocusNode.hasFocus,
                isPasswordVisible: !controller.obscurePassword.value,
                hasPasswordText: controller.passwordController.text
                    .trim()
                    .isNotEmpty,
                isIdentifierFocused: _identifierFocusNode.hasFocus,
                size: keyboardVisible ? 96 : 114,
                accent: purple,
                accentLight: purpleLight,
                faceColor: surface,
                strokeColor: border,
              ),
            ),
          ),
        ),
        SizedBox(height: keyboardVisible ? 14 : 18),
        _staggered(
          begin: 0.24,
          end: 0.64,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldLabel(text: 'email'.tr, textPrimary: textPrimary),
              const SizedBox(height: 10),
              _ExactInputField(
                controller: controller.emailController,
                hint: 'email_hint'.tr,
                prefix: const Icon(
                  LucideIcons.mail,
                  size: 16,
                  color: Colors.black54,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                fillColor: surface,
                border: border,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                focusNode: _identifierFocusNode,
                onChanged: (_) => _handleStateChange(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _staggered(
          begin: 0.34,
          end: 0.76,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldLabel(text: 'password'.tr, textPrimary: textPrimary),
              const SizedBox(height: 10),
              Obx(
                () => _ExactInputField(
                  controller: controller.passwordController,
                  hint: 'password_hint'.tr,
                  prefix: const Icon(
                    LucideIcons.lock,
                    size: 16,
                    color: Colors.black54,
                  ),
                  suffix: InkWell(
                    onTap: controller.togglePasswordVisibility,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        controller.obscurePassword.value
                            ? LucideIcons.eyeOff
                            : LucideIcons.eye,
                        size: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  obscureText: controller.obscurePassword.value,
                  validator: Validators.password,
                  textInputAction: TextInputAction.done,
                  fillColor: surface,
                  border: border,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  focusNode: _passwordFocusNode,
                  onChanged: (_) => _handleStateChange(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _staggered(
          begin: 0.46,
          end: 0.88,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 360;

              final rememberMeWidget = Obx(
                () => InkWell(
                  onTap: controller.rememberMe.toggle,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 17,
                          height: 17,
                          decoration: BoxDecoration(
                            color: controller.rememberMe.value
                                ? purple
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: purple, width: 1.4),
                          ),
                          child: controller.rememberMe.value
                              ? const Icon(
                                  LucideIcons.check,
                                  size: 11,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'remember_me'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              final forgotWidget = GestureDetector(
                onTap: controller.goToForgotPassword,
                child: Text(
                  'forgot_password'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: purple,
                  ),
                ),
              );

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    rememberMeWidget,
                    const SizedBox(height: 10),
                    forgotWidget,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: rememberMeWidget),
                  forgotWidget,
                ],
              );
            },
          ),
        ),
        SizedBox(height: keyboardVisible ? 28 : 34),
        _staggered(
          begin: 0.58,
          end: 1.0,
          child: Column(
            children: [
              Obx(
                () => _PrimaryAuthButton(
                  label: 'login'.tr,
                  onTap: controller.isLoading.value ? null : controller.login,
                  purple: purple,
                  purpleLight: purpleLight,
                  isLoading: controller.isLoading.value,
                ),
              ),
              const SizedBox(height: 18),
              _FooterSignupRow(
                textSecondary: textSecondary,
                purple: purple,
                onTap: controller.goToSignUp,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color border;
  final Color textPrimary;
  final bool comingSoon;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.border,
    required this.textPrimary,
    this.isLoading = false,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null && !isLoading;
    final content = Row(
      children: [
        SizedBox(width: 22, height: 22, child: Center(child: icon)),
        Expanded(
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 22),
      ],
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: isDisabled
                ? border.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: isDisabled ? 0.66 : 1,
                      child: comingSoon
                          ? ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: 0.9,
                                sigmaY: 0.9,
                              ),
                              child: content,
                            )
                          : content,
                    ),
                  ),
                ),
              ),
              if (comingSoon)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: border),
                    ),
                    child: Text(
                      'coming_soon'.tr,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7E7E88),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandIcon extends StatelessWidget {
  final Widget child;

  const _BrandIcon._({required this.child});

  const _BrandIcon.google()
    : this._(
        child: const Text(
          'G',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFFEA4335),
          ),
        ),
      );

  const _BrandIcon.apple()
    : this._(child: const Icon(Icons.apple, size: 20, color: Colors.black));

  const _BrandIcon.facebook()
    : this._(
        child: const Icon(Icons.facebook, size: 20, color: Color(0xFF1877F2)),
      );

  const _BrandIcon.twitter()
    : this._(
        child: const Text(
          'X',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1DA1F2),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => child;
}

class _PrimaryAuthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color purple;
  final Color purpleLight;

  const _PrimaryAuthButton({
    required this.label,
    required this.onTap,
    required this.purple,
    required this.purpleLight,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [purple, purpleLight],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 54,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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

class _FooterSignupRow extends StatelessWidget {
  final Color textSecondary;
  final Color purple;
  final VoidCallback onTap;

  const _FooterSignupRow({
    required this.textSecondary,
    required this.purple,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'no_account'.tr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: textSecondary,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              'sign_up'.tr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: purple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final Color textPrimary;

  const _FieldLabel({required this.text, required this.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    );
  }
}

class _ExactInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final Color fillColor;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  const _ExactInputField({
    required this.controller,
    required this.hint,
    required this.fillColor,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    this.prefix,
    this.suffix,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: textInputAction,
      focusNode: focusNode,
      onChanged: onChanged,
      cursorColor: _LoginScreenState._purple,
      autocorrect: false,
      enableSuggestions: !obscureText,
      scrollPadding: const EdgeInsets.only(bottom: 160),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        filled: true,
        fillColor: fillColor,
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
          minWidth: 42,
          maxWidth: 42,
          minHeight: 20,
        ),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: _LoginScreenState._purple,
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
