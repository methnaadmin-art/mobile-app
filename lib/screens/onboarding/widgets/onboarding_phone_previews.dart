import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/constants/app_constants.dart';
import 'package:methna_app/core/widgets/chat_flow.dart';
import 'package:methna_app/core/widgets/login_security_avatar.dart';

class OnboardingAuthPhonePreview extends StatelessWidget {
  const OnboardingAuthPhonePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final border = AppColors.primary.withValues(alpha: 0.18);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFFEFEFE), Color(0xFFFFFAFB)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 2, 6, 6),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                _MiniIconCircle(icon: LucideIcons.languages),
                SizedBox(width: 6),
                _MiniIconCircle(icon: LucideIcons.moon),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: ClipOval(
                child: Image.asset(
                  AppConstants.appLogoAsset,
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.appName,
              style: AppTextStyles.headlineSmall.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'app_tagline'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 8.5,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 10),
            LoginSecurityAvatar(
              isPasswordFocused: true,
              isPasswordVisible: false,
              hasPasswordText: true,
              isIdentifierFocused: false,
              size: 70,
              accent: AppColors.primary,
              accentLight: AppColors.primaryLight,
              faceColor: const Color(0xFFFFF5F7),
              strokeColor: border,
            ),
            const SizedBox(height: 10),
            _MiniFieldLabel(text: 'email'.tr),
            const SizedBox(height: 4),
            _MiniField(
              hint: 'email_hint'.tr,
              icon: LucideIcons.mail,
              border: border,
            ),
            const SizedBox(height: 7),
            _MiniFieldLabel(text: 'password'.tr),
            const SizedBox(height: 4),
            _MiniField(
              hint: 'password_hint'.tr,
              icon: LucideIcons.lock,
              suffixIcon: LucideIcons.eyeOff,
              border: border,
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    LucideIcons.check,
                    size: 9,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'remember_me'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 9,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                Text(
                  'forgot_password'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 9,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const _MiniPrimaryButton(labelKey: 'login'),
            const SizedBox(height: 7),
            Container(
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'continue_with_google'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
              ),
            ),
            const Spacer(),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 2,
              children: [
                Text(
                  'no_account'.tr,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 8.5,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                Text(
                  'sign_up'.tr,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 8.5,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingChatPhonePreview extends StatelessWidget {
  const OnboardingChatPhonePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
        child: Column(
          children: [
            Row(
              children: [
                const _MiniHeaderButton(icon: LucideIcons.chevronLeft),
                const SizedBox(width: 8),
                const ChatAvatar(
                  fallback: 'AM',
                  size: 34,
                  online: true,
                  showGradientRing: true,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amina',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'typing'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 8.2,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const _MiniHeaderButton(icon: LucideIcons.moreHorizontal),
              ],
            ),
            const SizedBox(height: 10),
            const ChatDateBadge(label: 'Today'),
            const SizedBox(height: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  _MiniBubble(
                    text: 'Assalamu alaikum, I appreciated your profile.',
                    time: '09:18',
                    isMine: false,
                  ),
                  _MiniBubble(
                    text: 'Wa alaikum salam. JazakAllah khair.',
                    time: '09:19',
                    isMine: true,
                    read: true,
                  ),
                  _MiniBubble(
                    text: 'Would you like to continue after Maghrib?',
                    time: '09:20',
                    isMine: false,
                  ),
                  Spacer(),
                ],
              ),
            ),
            ChatComposerCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'send_message_hint'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 9.2,
                          color: AppColors.textHintLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.send,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingDiscoverPhonePreview extends StatelessWidget {
  const OnboardingDiscoverPhonePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.smoothBeige,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
        child: Column(
          children: [
            Row(
              children: const [
                _MiniTopAvatar(),
                Spacer(),
                _MiniTopAction(icon: LucideIcons.bell),
                SizedBox(width: 6),
                _MiniTopAction(icon: LucideIcons.settings2),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFD9B090),
                                    Color(0xFFB2876F),
                                    Color(0xFF493D4D),
                                  ],
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Color(0x22000000),
                                      Color(0xB8000000),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Positioned(
                              top: 10,
                              left: 10,
                              child: _MiniChip(
                                icon: LucideIcons.mapPin,
                                label: '3 km',
                              ),
                            ),
                            const Positioned(
                              top: 10,
                              right: 10,
                              child: _MiniChip(
                                icon: LucideIcons.badgeCheck,
                                label: '98%',
                              ),
                            ),
                            Center(
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.34),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'AM',
                                  style: AppTextStyles.displaySmall.copyWith(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 14,
                              right: 14,
                              bottom: 14,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: RichText(
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Amina',
                                                style: AppTextStyles
                                                    .displaySmall
                                                    .copyWith(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: const Color(
                                                        0xFFFFC95A,
                                                      ),
                                                    ),
                                              ),
                                              TextSpan(
                                                text: ', 27',
                                                style: AppTextStyles.titleLarge
                                                    .copyWith(
                                                      fontSize: 16,
                                                      color: Colors.white,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        LucideIcons.badgeCheck,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Algiers, Algeria',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 10.4,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(
                                        alpha: 0.92,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: const [
                                      _MiniTag(text: 'Practicing'),
                                      _MiniTag(text: "Bachelor's"),
                                      _MiniTag(text: 'Travel'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        _MiniDiscoverAction(
                          icon: LucideIcons.x,
                          color: AppColors.pass,
                        ),
                        _MiniDiscoverAction(
                          icon: LucideIcons.sparkles,
                          color: AppColors.superLike,
                        ),
                        _MiniDiscoverAction(
                          icon: LucideIcons.heart,
                          color: AppColors.like,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniIconCircle extends StatelessWidget {
  const _MiniIconCircle({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F7),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 12, color: AppColors.textPrimaryLight),
    );
  }
}

class _MiniFieldLabel extends StatelessWidget {
  const _MiniFieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
        ),
      ),
    );
  }
}

class _MiniField extends StatelessWidget {
  const _MiniField({
    required this.hint,
    required this.icon,
    required this.border,
    this.suffixIcon,
  });

  final String hint;
  final IconData icon;
  final IconData? suffixIcon;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F7),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 11),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 9.2,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          if (suffixIcon != null)
            Icon(suffixIcon, size: 13, color: Colors.black54),
        ],
      ),
    );
  }
}

class _MiniPrimaryButton extends StatelessWidget {
  const _MiniPrimaryButton({required this.labelKey});

  final String labelKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        labelKey.tr,
        style: AppTextStyles.labelMedium.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _MiniHeaderButton extends StatelessWidget {
  const _MiniHeaderButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 14, color: AppColors.textPrimaryLight),
    );
  }
}

class _MiniBubble extends StatelessWidget {
  const _MiniBubble({
    required this.text,
    required this.time,
    required this.isMine,
    this.read = false,
  });

  final String text;
  final String time;
  final bool isMine;
  final bool read;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 170),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                gradient: isMine ? AppColors.primaryGradient : null,
                color: isMine ? null : const Color(0xFFF8F3EF),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMine ? 16 : 5),
                  bottomRight: Radius.circular(isMine ? 5 : 16),
                ),
              ),
              child: Text(
                text,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 9.2,
                  color: isMine ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 7.8,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 5),
                  Icon(
                    read ? LucideIcons.checkCheck : LucideIcons.check,
                    size: 10,
                    color: read
                        ? AppColors.primary
                        : AppColors.textSecondaryLight,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTopAvatar extends StatelessWidget {
  const _MiniTopAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFF5F7),
        border: Border.all(color: const Color(0xFFEDE9FE)),
      ),
      alignment: Alignment.center,
      child: Text(
        'M',
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MiniTopAction extends StatelessWidget {
  const _MiniTopAction({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 15, color: Color(0xFF232129)),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 7.8,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          fontSize: 7.7,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _MiniDiscoverAction extends StatelessWidget {
  const _MiniDiscoverAction({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }
}
