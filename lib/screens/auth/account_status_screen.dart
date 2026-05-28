import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/widgets/backend_wait_overlay.dart';
import 'package:methna_app/core/widgets/backend_wait_dots.dart';

class AccountStatusScreen extends StatelessWidget {
  const AccountStatusScreen({super.key});

  Map<String, dynamic> get _arguments {
    final raw = Get.arguments;
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const <String, dynamic>{};
  }

  String _cleanText(dynamic raw) {
    final text = raw?.toString() ?? '';
    final withoutInvisible = text.replaceAll(
      RegExp(r'[\u00A0\u200B\u200C\u200D\uFEFF]'),
      ' ',
    );
    return withoutInvisible.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _hasMeaningfulText(String raw) {
    final normalized = _cleanText(raw);
    if (normalized.isEmpty) {
      return false;
    }

    final stripped = normalized
        .replaceAll(RegExp(r'[-_.,:;|/\\()\[\]{}]+'), '')
        .trim();
    return stripped.isNotEmpty;
  }

  String _normalizedForCompare(String raw) => _cleanText(raw).toLowerCase();

  String get _status =>
      (_arguments['status']?.toString().trim().toLowerCase() ?? '')
          .trim()
          .isNotEmpty
      ? _arguments['status'].toString().trim().toLowerCase()
      : 'pending_verification';

  String get _reason {
    final value = _cleanText(_arguments['reason']);
    return _hasMeaningfulText(value) ? value : '';
  }

  String get _supportMessage {
    final value = _cleanText(_arguments['supportMessage']);
    return _hasMeaningfulText(value) ? value : '';
  }

  String get _staffMessage {
    final value = _cleanText(_arguments['staffMessage']);
    return _hasMeaningfulText(value) ? value : '';
  }

  String get _actionRequired {
    final value = _cleanText(_arguments['actionRequired']);
    return _hasMeaningfulText(value) ? value : '';
  }

  String get _expiresAtRaw =>
      _cleanText(_arguments['expiresAt']);

  bool get _allowBackNavigation {
    final raw = _arguments['allowBackNavigation'];
    if (raw is bool) return raw;
    return raw?.toString().toLowerCase() == 'true';
  }

  void _handleBackNavigation() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
      return;
    }
    Get.offAllNamed(AppRoutes.main);
  }

  String _normalizeAction(String raw) =>
      raw.trim().toUpperCase().replaceAll('-', '_');

  String? _formatExpiresAt() {
    if (_expiresAtRaw.isEmpty) return null;
    final parsed = DateTime.tryParse(_expiresAtRaw);
    if (parsed == null) return null;

    final local = parsed.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} ${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  _AccountAction? _resolveRequiredAction() {
    final normalized = _normalizeAction(_actionRequired);
    if (normalized.isEmpty || normalized == 'NO_ACTION') {
      return null;
    }

    switch (normalized) {
      case 'REUPLOAD_IDENTITY_DOCUMENT':
      case 'UPLOAD_IDENTITY_DOCUMENT':
      case 'IDENTITY_UPLOAD_REQUIRED':
      case 'REVERIFY_REQUIRED':
        return _AccountAction(
          title: 'Re-upload your identity document',
          description:
              'Upload a clearer identity document so the review team can continue verification.',
          buttonLabel: 'Open Verification Center',
          onPressed: () => Get.toNamed(AppRoutes.verificationCenter),
        );
      case 'RETAKE_SELFIE':
      case 'SELFIE_RETAKE_REQUIRED':
        return _AccountAction(
          title: 'Retake your selfie verification',
          description:
              'Please retake your selfie in good lighting and keep your face fully visible.',
          buttonLabel: 'Retake Verification',
          onPressed: () => Get.toNamed(AppRoutes.verificationCenter),
        );
      case 'UPLOAD_MARRIAGE_DOCUMENT':
        return _AccountAction(
          title: 'Upload your marital-status document',
          description:
              'A valid marital-status document is required before full account access is restored.',
          buttonLabel: 'Open Verification Center',
          onPressed: () => Get.toNamed(AppRoutes.verificationCenter),
        );
      case 'VERIFY_EMAIL':
        return _AccountAction(
          title: 'Verify your email address',
          description:
              'Finish email verification to continue using all account features.',
          buttonLabel: 'Verify Email',
          onPressed: () => Get.toNamed(AppRoutes.signupEmailVerification),
        );
      case 'VERIFY_PHONE':
        return _AccountAction(
          title: 'Verify your phone number',
          description:
              'Phone verification is required for account security and full access.',
          buttonLabel: 'Contact Support',
          onPressed: () => Get.toNamed(AppRoutes.contactSupport),
        );
      case 'CONTACT_SUPPORT':
        return _AccountAction(
          title: 'Contact support to continue',
          description:
              'A team member needs to review your case before account access can be restored.',
          buttonLabel: 'Contact Support',
          onPressed: () => Get.toNamed(AppRoutes.contactSupport),
        );
      case 'WAIT_FOR_REVIEW':
        return const _AccountAction(
          title: 'Wait for review completion',
          description:
              'No extra action is needed right now. You will be notified when the review is complete.',
        );
      default:
        return _AccountAction(
          title: 'Action required',
          description: _actionRequired,
          buttonLabel: 'Contact Support',
          onPressed: () => Get.toNamed(AppRoutes.contactSupport),
        );
    }
  }

  _AccountStatusContent _contentForStatus(BuildContext context) {
    final action = _resolveRequiredAction();
    final isVerificationAction = action != null &&
        (_normalizeAction(_actionRequired).contains('IDENTITY') ||
            _normalizeAction(_actionRequired).contains('SELFIE') ||
            _normalizeAction(_actionRequired).contains('MARRIAGE') ||
            _normalizeAction(_actionRequired).contains('REUPLOAD') ||
            _normalizeAction(_actionRequired).contains('RETAKE') ||
            _normalizeAction(_actionRequired).contains('UPLOAD'));
    final isPolicyViolation = _normalizeAction(_actionRequired) == 'POLICY_VIOLATION' ||
        _reason.toLowerCase().contains('violation') ||
        _reason.toLowerCase().contains('terms');

    switch (_status) {
      case 'active':
        return _AccountStatusContent(
          icon: Icons.verified_rounded,
          accent: AppColors.primary,
          pill: 'Account active',
          title: 'Your account is in good standing',
          body: 'Your account is active and all core features are available.',
          primaryLabel: _allowBackNavigation ? 'Back to Settings' : 'Logout',
          onPrimaryPressed:
              _allowBackNavigation ? _handleBackNavigation : null,
        );
      case 'rejected':
        return _AccountStatusContent(
          icon: Icons.assignment_late_rounded,
          accent: AppColors.primaryDark,
          pill: 'Verification update',
          title: 'Your verification was rejected',
          body: _supportMessage.isNotEmpty
              ? _supportMessage
              : _reason.isNotEmpty
                  ? _reason
                  : 'Please upload a clearer selfie or marital-status document to continue.',
          primaryLabel: isVerificationAction
              ? (action.buttonLabel ?? 'Open Verification Center')
              : 'Open Verification Center',
          secondaryLabel: 'Logout',
          onPrimaryPressed: () => Get.toNamed(AppRoutes.verificationCenter),
        );
      case 'banned':
        return _AccountStatusContent(
          icon: Icons.block_rounded,
          accent: AppColors.secondaryDark,
          pill: 'Access blocked',
          title: 'Your account is banned',
          body: _supportMessage.isNotEmpty
              ? _supportMessage
              : _reason.isNotEmpty
                  ? _reason
                  : 'This account can no longer use Methna. If you believe this is a mistake, please contact support.',
          primaryLabel: 'Contact Support',
          secondaryLabel: 'Logout',
          onPrimaryPressed: () => Get.toNamed(AppRoutes.contactSupport),
        );
      case 'suspended':
        return _AccountStatusContent(
          icon: Icons.pause_circle_rounded,
          accent: AppColors.secondary,
          pill: 'Account suspended',
          title: isVerificationAction
              ? 'Account suspended — verification required'
              : isPolicyViolation
                  ? 'Account suspended — policy violation'
                  : 'Account suspended. Contact support',
          body: _supportMessage.isNotEmpty
              ? _supportMessage
              : _reason.isNotEmpty
                  ? _reason
                  : isVerificationAction
                      ? 'Your account has been suspended because a verification document was not accepted. Please visit the verification center to upload the required document.'
                      : isPolicyViolation
                          ? 'Your account has been suspended due to a policy violation. Please review our terms of service and contact support for assistance.'
                          : 'Your account is temporarily suspended while the team reviews activity on it. Support can help you with the next step.',
          primaryLabel: isVerificationAction
              ? 'Open Verification Center'
              : 'Contact Support',
          secondaryLabel: 'Logout',
          onPrimaryPressed: isVerificationAction
              ? () => Get.toNamed(AppRoutes.verificationCenter)
              : () => Get.toNamed(AppRoutes.contactSupport),
        );
      case 'limited':
        return _AccountStatusContent(
          icon: Icons.warning_amber_rounded,
          accent: AppColors.secondary,
          pill: 'Limited access',
          title: isVerificationAction
              ? 'Limited access — verification required'
              : isPolicyViolation
                  ? 'Limited access — policy violation'
                  : 'Your account has limited access',
          body: _supportMessage.isNotEmpty
              ? _supportMessage
              : _reason.isNotEmpty
                  ? _reason
                  : isVerificationAction
                      ? 'Some features are restricted because a verification document needs to be uploaded. Please visit the verification center.'
                      : isPolicyViolation
                          ? 'Some features are restricted due to a policy violation. Please review our terms of service and contact support.'
                          : 'Some features are restricted on your account. Contact support for details or wait for the restriction to expire.',
          primaryLabel: isVerificationAction
              ? 'Open Verification Center'
              : 'Contact Support',
          secondaryLabel: 'Logout',
          onPrimaryPressed: isVerificationAction
              ? () => Get.toNamed(AppRoutes.verificationCenter)
              : () => Get.toNamed(AppRoutes.contactSupport),
        );
      case 'shadow_suspended':
        return _AccountStatusContent(
          icon: Icons.visibility_off_rounded,
          accent: AppColors.primaryDark,
          pill: 'Account restricted',
          title: 'Your account is under review',
          body: _supportMessage.isNotEmpty
              ? _supportMessage
              : _reason.isNotEmpty
                  ? _reason
                  : 'Your account is being reviewed. Some features may be temporarily limited. You will be notified when the review is complete.',
          primaryLabel: 'Contact Support',
          secondaryLabel: 'Logout',
          onPrimaryPressed: () => Get.toNamed(AppRoutes.contactSupport),
        );
      case 'deactivated':
        return _AccountStatusContent(
          icon: Icons.person_off_rounded,
          accent: AppColors.primaryDark,
          pill: 'Account deactivated',
          title: 'Your account is deactivated',
          body: _supportMessage.isNotEmpty
              ? _supportMessage
              : _reason.isNotEmpty
                  ? _reason
                  : 'Your account has been deactivated. You can reactivate it by logging in again or contacting support.',
          primaryLabel: 'Contact Support',
          secondaryLabel: 'Logout',
          onPrimaryPressed: () => Get.toNamed(AppRoutes.contactSupport),
        );
      case 'closed':
        return _AccountStatusContent(
          icon: Icons.cancel_rounded,
          accent: AppColors.primaryDark,
          pill: 'Account closed',
          title: 'Your account has been closed',
          body: _supportMessage.isNotEmpty
              ? _supportMessage
              : _reason.isNotEmpty
                  ? _reason
                  : 'This account has been closed and is no longer active. If you believe this is a mistake, please contact support.',
          primaryLabel: 'Contact Support',
          secondaryLabel: 'Logout',
          onPrimaryPressed: () => Get.toNamed(AppRoutes.contactSupport),
        );
      case 'pending_verification':
      default:
        return _AccountStatusContent(
          icon: Icons.verified_user_rounded,
          accent: AppColors.primaryLight,
          pill: 'Account review',
          title: 'Your account is under review',
          body: _supportMessage.isNotEmpty
              ? _supportMessage
              : _reason.isNotEmpty
                  ? _reason
                  : 'We are reviewing your verification details now. You will be able to use the app once the review is approved.',
          primaryLabel: 'Logout',
        );
    }
  }

  Future<void> _logout(RxBool isLoggingOut) async {
    if (isLoggingOut.value) return;
    isLoggingOut.value = true;

    final auth = Get.find<AuthService>();
    try {
      await auth.logout();
      Get.offAllNamed(AppRoutes.login);
    } finally {
      isLoggingOut.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headingColor =
      isDark ? const Color(0xFFFFF5F7) : const Color(0xFF181224);
    final bodyColor =
      isDark ? const Color(0xFFD1C9E0) : const Color(0xFF5F5A68);
    final backIconColor =
      isDark ? const Color(0xFFE9E2F7) : const Color(0xFF181224);
    final secondaryButtonTextColor =
      isDark ? const Color(0xFFF0EBFA) : const Color(0xFF181224);
    final secondaryButtonBorderColor = isDark
      ? Colors.white.withValues(alpha: 0.18)
      : Colors.black.withValues(alpha: 0.08);
    final content = _contentForStatus(context);
    final isLoggingOut = false.obs;
    final supportMessage = _supportMessage;
    final staffMessage = _staffMessage;
    final expiresAt = _formatExpiresAt();
    final requiredAction = _resolveRequiredAction();
    final hasSupportMessage =
      _hasMeaningfulText(supportMessage) &&
      _normalizedForCompare(supportMessage) !=
        _normalizedForCompare(content.body);

    return PopScope(
      canPop: _allowBackNavigation,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isDark ? AppColors.canvasDark : AppColors.primarySurface,
                isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_allowBackNavigation)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: IconButton(
                              onPressed: _handleBackNavigation,
                              icon: const Icon(Icons.arrow_back_rounded),
                              tooltip: 'Back',
                              color: backIconColor,
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: content.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            content.pill,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: content.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: content.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Icon(
                            content.icon,
                            size: 42,
                            color: content.accent,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          content.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: headingColor,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          content.body,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: bodyColor,
                            height: 1.45,
                          ),
                        ),
                        if (hasSupportMessage) ...[
                          const SizedBox(height: 16),
                          _StatusInfoCard(
                            title: 'Support guidance',
                            message: supportMessage,
                            accent: content.accent,
                            icon: Icons.support_agent_rounded,
                            isDark: isDark,
                          ),
                        ],
                        if (requiredAction != null) ...[
                          const SizedBox(height: 12),
                          _StatusInfoCard(
                            title: requiredAction.title,
                            message: requiredAction.description,
                            accent: content.accent,
                            icon: Icons.task_alt_rounded,
                            isDark: isDark,
                            buttonLabel: requiredAction.buttonLabel,
                            onButtonPressed: requiredAction.onPressed,
                          ),
                        ],
                        if (expiresAt != null) ...[
                          const SizedBox(height: 12),
                          _StatusInfoCard(
                            title: 'Restriction expiry',
                            message: 'This status is currently set to expire at $expiresAt.',
                            accent: content.accent,
                            icon: Icons.schedule_rounded,
                            isDark: isDark,
                          ),
                        ],
                        if (_hasMeaningfulText(staffMessage)) ...[
                          const SizedBox(height: 12),
                          _StatusInfoCard(
                            title: 'Staff note',
                            message: staffMessage,
                            accent: content.accent,
                            icon: Icons.admin_panel_settings_rounded,
                            isDark: isDark,
                          ),
                        ],
                        const SizedBox(height: 20),
                        if (content.secondaryLabel != null) ...[
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: content.onPrimaryPressed,
                              style: FilledButton.styleFrom(
                                backgroundColor: content.accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Text(
                                content.primaryLabel,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: Obx(
                              () => OutlinedButton(
                                onPressed: isLoggingOut.value
                                    ? null
                                    : () => _logout(isLoggingOut),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: secondaryButtonTextColor,
                                  side: BorderSide(
                                    color: secondaryButtonBorderColor,
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: isLoggingOut.value
                                    ? SizedBox(
                                        width: 28,
                                        child: BackendWaitDots(
                                          color: content.accent,
                                          size: 5,
                                          spacing: 3,
                                        ),
                                      )
                                    : Text(
                                        content.secondaryLabel!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            child: Obx(
                              () {
                                final primaryAction = content.onPrimaryPressed;
                                final isLogoutAction = primaryAction == null;

                                return FilledButton(
                                  onPressed: isLogoutAction
                                      ? (isLoggingOut.value
                                            ? null
                                            : () => _logout(isLoggingOut))
                                      : primaryAction,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: content.accent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: isLogoutAction && isLoggingOut.value
                                      ? SizedBox(
                                          width: 28,
                                          child: BackendWaitDots(
                                            color: Colors.white,
                                            size: 5,
                                            spacing: 3,
                                          ),
                                        )
                                      : Text(
                                          content.primaryLabel,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountStatusContent {
  const _AccountStatusContent({
    required this.icon,
    required this.accent,
    required this.pill,
    required this.title,
    required this.body,
    required this.primaryLabel,
    this.secondaryLabel,
    this.onPrimaryPressed,
  });

  final IconData icon;
  final Color accent;
  final String pill;
  final String title;
  final String body;
  final String primaryLabel;
  final String? secondaryLabel;
  final VoidCallback? onPrimaryPressed;
}

class _AccountAction {
  const _AccountAction({
    required this.title,
    required this.description,
    this.buttonLabel,
    this.onPressed,
  });

  final String title;
  final String description;
  final String? buttonLabel;
  final VoidCallback? onPressed;
}

class _StatusInfoCard extends StatelessWidget {
  const _StatusInfoCard({
    required this.title,
    required this.message,
    required this.accent,
    required this.icon,
    required this.isDark,
    this.buttonLabel,
    this.onButtonPressed,
  });

  final String title;
  final String message;
  final Color accent;
  final IconData icon;
  final bool isDark;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = isDark
        ? Color.alphaBlend(
            accent.withValues(alpha: 0.16),
            const Color(0xFF111521),
          )
        : accent.withValues(alpha: 0.09);
    final borderColor = accent.withValues(alpha: isDark ? 0.34 : 0.2);
    final titleColor =
        isDark ? const Color(0xFFF0EAFB) : const Color(0xFF1D1930);
    final messageColor =
        isDark ? const Color(0xFFD3CBE2) : const Color(0xFF4D485D);
    final buttonBackground = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.8);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: messageColor,
              height: 1.45,
            ),
          ),
          if ((buttonLabel ?? '').trim().isNotEmpty && onButtonPressed != null) ...[
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: onButtonPressed,
              style: FilledButton.styleFrom(
                foregroundColor: accent,
                backgroundColor: buttonBackground,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonLabel!,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
