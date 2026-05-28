import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:methna_app/app/controllers/chat_controller.dart';
import 'package:methna_app/app/controllers/home_controller.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/controllers/users_controller.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/screens/main/profile/profile_screen.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  bool _didRecordView = false;

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final user = args?['user'] as UserModel?;
    final sourceTab =
        (args?['sourceTab']?.toString().trim().toLowerCase() ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final home = Get.find<HomeController>();

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('profile'.tr)),
        body: Center(child: Text('user_not_found'.tr)),
      );
    }

    if (!_didRecordView) {
      _didRecordView = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _uuidPattern.hasMatch(user.id.trim())) {
          Get.find<MonetizationService>().recordProfileView(user.id);
        }
      });
    }

    final hidePassAction =
      sourceTab == 'liked_me' || sourceTab == 'who_liked_me';
    final usersController = Get.isRegistered<UsersController>()
        ? Get.find<UsersController>()
        : null;

    return Obx(() {
      final isMatched = usersController?.isMatchedWithUser(user.id) ?? false;
      final isPassed = usersController?.hasPassedUser(user.id) ?? false;
      final hideActions =
          !isPassed &&
          (home.hasInteractedWith(user.id) ||
              (usersController?.hasInteractedWith(user.id) ?? false));
      final premiumComplimentOnly =
          hidePassAction && !home.hasPaidPremiumPlan;

      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        body: SafeArea(
          bottom: false,
          child: ProfileShowcaseContent(
            user: user,
            onBack: () => Get.back(),
            onMore: () => _showUserActions(context, user),
            onPhotoTap: (initialIndex) => openProfileGalleryViewer(
              context,
              user,
              initialIndex: initialIndex,
            ),
            heroAvatarSize: 148,
            extraBottomPadding: 160,
          ),
        ),
        bottomNavigationBar: isMatched
            ? _MatchedActionBar(isDark: isDark, user: user)
            : hideActions
            ? null
            : _BottomActionBar(
                isDark: isDark,
                user: user,
                showPassAction: !hidePassAction,
                sourceTab: sourceTab,
                requirePremiumForCompliment: premiumComplimentOnly,
              ),
      );
    });
  }

  void _showUserActions(BuildContext context, UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.ban, color: AppColors.error),
              title: Text('block_user'.tr),
              onTap: () {
                Get.back();
                Get.find<SettingsController>().blockUser(user.id);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.flag, color: AppColors.primary),
              title: Text('report_user'.tr),
              onTap: () {
                Get.back();
                _showReportDialog(context, user);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, UserModel user) {
    final noteController = TextEditingController();
    var selectedReason = 'spam';
    var isSubmitting = false;

    const reasons = <String>[
      'spam',
      'fake_profile',
      'inappropriate_content',
      'harassment',
      'underage',
      'other',
    ];

    Get.dialog<void>(
      StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              'report_user'.tr,
              style: TextStyle(
                color: isDark ? AppColors.textPrimaryDark : Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey<String>(selectedReason),
                    initialValue: selectedReason,
                    decoration: InputDecoration(
                      labelText: 'reason'.tr,
                      labelStyle: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.cardDark : Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    dropdownColor: isDark ? AppColors.cardDark : Colors.white,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    items: reasons
                        .map(
                          (reason) => DropdownMenuItem<String>(
                            value: reason,
                            child: Text(reason.tr),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: isSubmitting
                        ? null
                        : (value) {
                            setModalState(() {
                              selectedReason = value ?? 'spam';
                            });
                          },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: noteController,
                    enabled: !isSubmitting,
                    maxLines: 4,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      hintText: 'add_extra_details_optional'.tr,
                      hintStyle: TextStyle(
                        color: isDark
                            ? AppColors.textHintDark
                            : AppColors.textHintLight,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.cardDark : Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Get.back(),
                child: Text(
                  'cancel'.tr,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setModalState(() => isSubmitting = true);
                        final success = await Get.find<SettingsController>()
                            .submitReport(
                              user.id,
                              selectedReason,
                              details: noteController.text.trim(),
                            );
                        if (success && (Get.isDialogOpen ?? false)) {
                          Get.back();
                          return;
                        }
                        setModalState(() => isSubmitting = false);
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text('submit'.tr),
              ),
            ],
          );
        },
      ),
    ).whenComplete(noteController.dispose);
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.isDark,
    required this.user,
    this.showPassAction = true,
    this.sourceTab,
    this.requirePremiumForCompliment = false,
  });

  final bool isDark;
  final UserModel user;
  final bool showPassAction;
  final String? sourceTab;
  final bool requirePremiumForCompliment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10151F) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF273043) : const Color(0xFFE9EAF0),
          ),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showPassAction)
            Expanded(
              child: _ActionPillButton(
                icon: LucideIcons.x,
                label: 'home_action_pass'.tr,
                iconColor: const Color(0xFFFF9862),
                backgroundColor: isDark
                    ? const Color(0xFF1D2330)
                    : const Color(0xFFFFEFE6),
                borderColor: const Color(0xFFFFC3A0),
                onTap: () async {
                  final success = await Get.find<HomeController>().passUser(
                    user.id,
                    fallbackUser: user,
                  );
                  if (success) {
                    Get.back();
                  }
                },
              ),
            ),
          if (showPassAction) const SizedBox(width: 10),
          Expanded(
            child: _ActionPillButton(
              icon: LucideIcons.heart,
              label: 'home_action_like'.tr,
              iconColor: Colors.white,
              textColor: Colors.white,
              gradient: AppColors.primaryGradient,
              onTap: () async {
                final success = await Get.find<HomeController>().likeUser(
                  user.id,
                  fallbackUser: user,
                );
                final matchedNow = Get.isRegistered<UsersController>() &&
                    Get.find<UsersController>().isMatchedWithUser(user.id);
                if (success && !matchedNow) {
                  Get.back();
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ActionPillButton(
              icon: LucideIcons.award,
              label: 'home_action_compliment'.tr,
              iconColor: const Color(0xFF2D95FF),
              backgroundColor: isDark
                  ? const Color(0xFF1D2330)
                  : const Color(0xFFEAF4FF),
              borderColor: const Color(0xFF9BCBFF),
              onTap: () => _showComplimentDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showComplimentDialog(BuildContext context) {
    if (requirePremiumForCompliment) {
      Get.toNamed(AppRoutes.subscription);
      return;
    }

    final controller = Get.find<HomeController>();
    final tc = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'send_compliment'.tr,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        content: TextField(
          controller: tc,
          maxLength: 200,
          autofocus: true,
          style: TextStyle(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: 'write_something_nice'.tr,
            hintStyle: TextStyle(
              color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
            ),
            filled: true,
            fillColor: isDark ? AppColors.cardDark : Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (tc.text.trim().isNotEmpty) {
                final success = await controller.complimentUser(
                  user.id,
                  tc.text.trim(),
                  fallbackUser: user,
                );
                if (success) {
                  if (Get.isDialogOpen ?? false) {
                    Get.back();
                  }
                  final matchedNow = Get.isRegistered<UsersController>() &&
                      Get.find<UsersController>().isMatchedWithUser(user.id);
                  if (!matchedNow) {
                    Get.back();
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('send'.tr),
          ),
        ],
      ),
    );
  }
}

class _MatchedActionBar extends StatelessWidget {
  const _MatchedActionBar({required this.isDark, required this.user});

  final bool isDark;
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10151F) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF273043) : const Color(0xFFE9EAF0),
          ),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionPillButton(
              icon: LucideIcons.messageCircle,
              label: 'chat'.tr,
              iconColor: const Color(0xFF2D95FF),
              backgroundColor: isDark
                  ? const Color(0xFF1D2330)
                  : const Color(0xFFEAF4FF),
              borderColor: const Color(0xFF9BCBFF),
              onTap: () =>
                  Get.find<ChatController>().openConversationWithUser(user),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionPillButton(
              icon: LucideIcons.xCircle,
              label: 'remove_match'.tr,
              iconColor: Colors.white,
              textColor: Colors.white,
              backgroundColor: AppColors.error,
              onTap: () => _confirmUnmatch(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmUnmatch(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await Get.dialog<void>(
      AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: Text('remove_match'.tr),
        content: Text('remove_match_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back<void>(),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () async {
              Get.back<void>();
              final success = await Get.find<UsersController>().unmatchUser(
                user.id,
              );
              if (success) {
                Get.back<void>();
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('remove_match'.tr),
          ),
        ],
      ),
    );
  }
}

class _ActionPillButton extends StatelessWidget {
  const _ActionPillButton({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
    this.gradient,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color? textColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedTextColor = textColor ?? iconColor;
    final resolvedIconSize =
        icon == LucideIcons.heart || icon == LucideIcons.heartHandshake
        ? 20.0
        : 18.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? backgroundColor : null,
        borderRadius: BorderRadius.circular(16),
        border: gradient == null && borderColor != null
            ? Border.all(color: borderColor!)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: resolvedIconSize),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: resolvedTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
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
