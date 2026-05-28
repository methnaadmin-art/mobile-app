import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';

/// Top banner shown for LIMITED users.
/// Displays the moderation message and a CTA button matching the required action.
class LimitedAccountBanner extends StatelessWidget {
  final UserModel user;
  const LimitedAccountBanner({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    if (!user.shouldShowModerationUI) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        border: const Border(
          bottom: BorderSide(color: AppColors.primaryLight),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                user.moderationMessage,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (user.actionRequiredLabel.isNotEmpty)
              TextButton(
                onPressed: () => _handleAction(user),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  user.actionRequiredLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleAction(UserModel user) {
    final route = user.actionRequiredRoute;
    if (route != null) {
      Get.toNamed(route);
    } else {
      Get.toNamed(AppRoutes.contactSupport);
    }
  }
}

/// Top banner shown for SUSPENDED users.
/// Suspended users can still use the app, but messaging is disabled.
class SuspendedAccountBanner extends StatelessWidget {
  final UserModel user;
  const SuspendedAccountBanner({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    if (!user.shouldShowModerationUI) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        border: const Border(
          bottom: BorderSide(color: AppColors.primaryLight),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(
              Icons.pause_circle_rounded,
              color: Color(0xFF4F26D9),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                user.moderationMessage,
                style: const TextStyle(fontSize: 13, color: Color(0xFF9A3412)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () {
                final route = user.actionRequiredRoute ?? AppRoutes.contactSupport;
                Get.toNamed(route);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                user.actionRequiredLabel.isNotEmpty
                    ? user.actionRequiredLabel
                    : 'Contact Support',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9A3412),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen overlay for SUSPENDED users.
/// Blocks all interaction with CTA matching the required action.
class SuspendedOverlay extends StatelessWidget {
  final UserModel user;
  const SuspendedOverlay({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    if (!user.shouldShowModerationUI) {
      // If not visible to user, show generic message
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Temporarily Unavailable',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your account is temporarily restricted. Please try again later.',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user.isVerificationAction
                      ? Icons.verified_user_rounded
                      : Icons.block,
                  size: 64,
                  color: user.isVerificationAction
                      ? const Color(0xFFA78BFA)
                      : const Color(0xFFA78BFA),
                ),
                const SizedBox(height: 24),
                Text(
                  user.isVerificationAction
                      ? 'Verification Required'
                      : 'Account Suspended',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  user.moderationMessage,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                if (user.moderationExpiresAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Restriction lifts on ${_formatDate(user.moderationExpiresAt!)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                // Primary CTA — action-specific
                if (user.actionRequiredLabel.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () {
                      final route =
                          user.actionRequiredRoute ??
                          AppRoutes.contactSupport;
                      Get.toNamed(route);
                    },
                    icon: Icon(
                      user.isVerificationAction
                          ? Icons.upload_file
                          : Icons.support_agent,
                    ),
                    label: Text(user.actionRequiredLabel),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                  ),
                // Secondary CTA — always show Contact Support
                if (user.actionRequiredLabel != 'Contact Support') ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Get.toNamed(AppRoutes.contactSupport),
                    icon: const Icon(Icons.support_agent, size: 18),
                    label: const Text('Contact Support'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Full-screen overlay for BANNED users.
/// Forces logout with a banned message and optional support contact.
class BannedOverlay extends StatelessWidget {
  final UserModel user;
  const BannedOverlay({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.gpp_bad, size: 64, color: const Color(0xFF4F26D9)),
                const SizedBox(height: 24),
                const Text(
                  'Account Banned',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  user.shouldShowModerationUI
                      ? user.moderationMessage
                      : 'Your account has been banned.',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Contact Support option before logging out
                OutlinedButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.contactSupport),
                  icon: const Icon(Icons.support_agent, size: 18),
                  label: const Text('Contact Support'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    final auth = Get.find<AuthService>();
                    auth.logout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('OK'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wrapper widget that checks the current user's moderation status
/// and shows the appropriate overlay/banner.
/// SHADOW_SUSPENDED users see NO indication — everything appears normal.
/// Respects isUserVisible and moderationExpiresAt.
class ModerationGuardWrapper extends StatelessWidget {
  final Widget child;
  const ModerationGuardWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final auth = Get.find<AuthService>();
      final user = auth.currentUser.value;
      if (user == null) return child;

      // BANNED — full blocking screen + logout
      if (user.isBanned) {
        return BannedOverlay(user: user);
      }

      // SUSPENDED — full blocking screen with CTA
      if (user.isSuspended && !user.isModerationExpired) {
        return Column(
          children: [
            SuspendedAccountBanner(user: user),
            Expanded(child: child),
          ],
        );
      }

      // LIMITED — banner on top, some buttons disabled
      if (user.isLimited && !user.isModerationExpired) {
        return Column(
          children: [
            LimitedAccountBanner(user: user),
            Expanded(child: child),
          ],
        );
      }

      // SHADOW_SUSPENDED / ACTIVE / expired moderation — no UI indication
      return child;
    });
  }
}
