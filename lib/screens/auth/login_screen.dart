import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:methna_app/app/controllers/locale_controller.dart';
import 'package:methna_app/app/data/services/storage_service.dart';
import 'package:methna_app/app/controllers/login_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_shadows.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/constants/app_constants.dart';
import 'package:methna_app/core/utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _primaryBrand = AppColors.primary;
  static const Color _primaryLightBrand = AppColors.primaryLight;

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
    final surface = isDark
        ? AppColors.surfaceMutedDark
        : const Color(0xFFFFF5F7);
    final border = isDark
        ? AppColors.borderDark
        : AppColors.primary.withValues(alpha: 0.22);
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final bgColor = isDark ? AppColors.canvasDark : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _LoginAtmosphere(isDark: isDark)),
            Positioned.fill(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.opaque,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOutQuart,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final curved = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutQuart,
                    );
                    final slide = Tween<Offset>(
                      begin: const Offset(0.06, 0),
                      end: Offset.zero,
                    ).animate(curved);
                    final scale = Tween<double>(
                      begin: 0.985,
                      end: 1,
                    ).animate(curved);

                    return FadeTransition(
                      opacity: curved,
                      child: SlideTransition(
                        position: slide,
                        child: ScaleTransition(scale: scale, child: child),
                      ),
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
                            primaryBrand: _primaryBrand,
                            primaryLightBrand: _primaryLightBrand,
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
                          primaryBrand: _primaryBrand,
                          primaryLightBrand: _primaryLightBrand,
                          border: border,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                ),
              ),
            ),
            Positioned(
              top: 10,
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

class _LoginAtmosphere extends StatelessWidget {
  const _LoginAtmosphere({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? const [
                          Color(0xFF100A22),
                          Color(0xFF1A1238),
                          Color(0xFF29195A),
                        ]
                      : const [
                          Colors.white,
                          Color(0xFFFEFEFE),
                          Color(0xFFFFFAFB),
                        ],
                  stops: const [0.0, 0.46, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: -92,
            left: -72,
            child: _BackgroundBlurBlob(
              size: 260,
              color: isDark ? const Color(0x80E85D75) : const Color(0x1AE85D75),
            ),
          ),
          Positioned(
            top: 128,
            right: -88,
            child: _BackgroundBlurBlob(
              size: 290,
              color: isDark ? const Color(0x70F07A90) : const Color(0x14F07A90),
            ),
          ),
          Positioned(
            bottom: -104,
            left: 24,
            child: _BackgroundBlurBlob(
              size: 320,
              color: isDark ? const Color(0x70E85D75) : const Color(0x14E85D75),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x2B100A22)
                      : const Color(0x00FFFFFF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundBlurBlob extends StatelessWidget {
  const _BackgroundBlurBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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
  final Color primaryBrand;
  final Color primaryLightBrand;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  const _EntryLoginView({
    super.key,
    required this.controller,
    required this.onEmailLogin,
    required this.primaryBrand,
    required this.primaryLightBrand,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 760;
        final showGoogleSignIn = !GetPlatform.isIOS && !GetPlatform.isMacOS;
        final showAppleSignIn = GetPlatform.isIOS || GetPlatform.isMacOS;

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
            Center(child: _LoginBrandHero(primaryBrand: primaryBrand)),
            const SizedBox(height: 22),
            Text(
              AppConstants.appName,
              textAlign: TextAlign.center,
              style: AppTextStyles.displayMedium.copyWith(color: textPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              'app_tagline'.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
            ),
            SizedBox(height: compact ? 22 : 34),
            if (showGoogleSignIn) ...[
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
            ],
            if (showAppleSignIn) ...[
              Obx(
                () => _SocialButton(
                  label: 'continue_with_apple'.tr,
                  icon: _BrandIcon.apple(
                    color: isDark ? Colors.white : const Color(0xFF111111),
                  ),
                  onTap: controller.isAppleLoading.value
                      ? null
                      : controller.signInWithApple,
                  isLoading: controller.isAppleLoading.value,
                  border: border,
                  textPrimary: textPrimary,
                ),
              ),
              const SizedBox(height: 14),
            ],
            SizedBox(height: compact ? 22 : 34),
            _PrimaryAuthButton(
              label: 'login'.tr,
              onTap: onEmailLogin,
              primaryBrand: primaryBrand,
              primaryLightBrand: primaryLightBrand,
            ),
            const SizedBox(height: 18),
            _FooterSignupRow(
              textSecondary: textSecondary,
              primaryBrand: primaryBrand,
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
  final Color primaryBrand;
  final Color primaryLightBrand;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  const _EmailLoginView({
    super.key,
    required this.controller,
    required this.onBack,
    required this.primaryBrand,
    required this.primaryLightBrand,
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
          primaryBrand: primaryBrand,
          primaryLightBrand: primaryLightBrand,
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
  final Color primaryBrand;
  final Color primaryLightBrand;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final bool keyboardVisible;

  const _EmailLoginContent({
    required this.controller,
    required this.onBack,
    required this.primaryBrand,
    required this.primaryLightBrand,
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
    final primaryBrand = widget.primaryBrand;
    final primaryLightBrand = widget.primaryLightBrand;
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
                style: AppTextStyles.displayLarge.copyWith(
                  color: textPrimary,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'login_subtitle'.tr,
                style: AppTextStyles.bodyMedium.copyWith(
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
            child: _LoginBrandHero(
              primaryBrand: primaryBrand,
              size: keyboardVisible ? 96 : 112,
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
                  borderRadius: BorderRadius.circular(AppRadii.sm),
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
                                ? primaryBrand
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: primaryBrand, width: 1.4),
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
                    color: primaryBrand,
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
                  primaryBrand: primaryBrand,
                  primaryLightBrand: primaryLightBrand,
                  isLoading: controller.isLoading.value,
                ),
              ),
              const SizedBox(height: 18),
              _FooterSignupRow(
                textSecondary: textSecondary,
                primaryBrand: primaryBrand,
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

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.border,
    required this.textPrimary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null && !isLoading;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Ink(
          height: AppSpacing.buttonHeight,
          decoration: BoxDecoration(
            color: isDisabled
                ? border.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: border),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: isDisabled ? 0.66 : 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Center(child: icon),
                          ),
                        ),
                        Center(
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.button.copyWith(
                                    color: textPrimary,
                                  ),
                                ),
                        ),
                      ],
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
            color: AppColors.primary,
          ),
        ),
      );

  _BrandIcon.apple({required Color color})
    : this._(child: Icon(Icons.apple, size: 20, color: color));

  @override
  Widget build(BuildContext context) => child;
}

class _LoginBrandHero extends StatelessWidget {
  const _LoginBrandHero({required this.primaryBrand, this.size = 84});

  final Color primaryBrand;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tileRadius = BorderRadius.circular(size * 0.30);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.34),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBrand.withValues(alpha: 0.16),
            primaryBrand.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: primaryBrand.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: primaryBrand.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: ClipRRect(
          borderRadius: tileRadius,
          child: Image.asset(AppConstants.appIconAsset, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color primaryBrand;
  final Color primaryLightBrand;

  const _PrimaryAuthButton({
    required this.label,
    required this.onTap,
    required this.primaryBrand,
    required this.primaryLightBrand,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [primaryBrand, primaryLightBrand],
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: [
          ...AppShadows.buttonGlow(primaryBrand),
          BoxShadow(
            color: primaryBrand.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: SizedBox(
            height: AppSpacing.buttonHeight,
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
                      style: AppTextStyles.button.copyWith(color: Colors.white),
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
  final Color primaryBrand;
  final VoidCallback onTap;

  const _FooterSignupRow({
    required this.textSecondary,
    required this.primaryBrand,
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
                color: primaryBrand,
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
      cursorColor: _LoginScreenState._primaryBrand,
      autocorrect: false,
      enableSuggestions: !obscureText,
      scrollPadding: const EdgeInsets.only(bottom: 160),
      style: AppTextStyles.bodyLarge.copyWith(
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
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
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: const BorderSide(
            color: _LoginScreenState._primaryBrand,
            width: 1.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: const BorderSide(color: const Color(0xFF4F26D9)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: const BorderSide(color: const Color(0xFF4F26D9)),
        ),
        errorStyle: AppTextStyles.error.copyWith(
          color: const Color(0xFF4F26D9),
        ),
      ),
    );
  }
}
