import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/home_controller.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/controllers/users_controller.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/screens/main/profile/profile_screen.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool _didRecordView = false;

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final user = args?['user'] as UserModel?;
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
        if (mounted) {
          Get.find<MonetizationService>().recordProfileView(user.id);
        }
      });
    }

    final usersController = Get.isRegistered<UsersController>()
        ? Get.find<UsersController>()
        : null;
    final hideActions =
        home.hasInteractedWith(user.id) ||
        (usersController?.hasInteractedWith(user.id) ?? false);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: SafeArea(
        bottom: false,
        child: ProfileShowcaseContent(
          user: user,
          onBack: () => Get.back(),
          onMore: () => _showUserActions(context, user),
          extraBottomPadding: 160,
        ),
      ),
      bottomNavigationBar: hideActions
          ? null
          : _BottomActionBar(isDark: isDark, user: user),
    );
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
              leading: const Icon(LucideIcons.flag, color: Colors.orange),
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
  const _BottomActionBar({required this.isDark, required this.user});

  final bool isDark;
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          _CircleActionBtn(
            icon: LucideIcons.x,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textHintLight,
            onTap: () async {
              final success = await Get.find<HomeController>().passUser(
                user.id,
              );
              if (success) {
                Get.back();
              }
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () async {
                  final success = await Get.find<HomeController>().likeUser(
                    user.id,
                  );
                  if (success) {
                    Get.back();
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Text(
                    'interested'.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _CircleActionBtn(
            icon: LucideIcons.award,
            color: AppColors.primary,
            onTap: () => _showComplimentDialog(context),
          ),
        ],
      ),
    );
  }

  void _showComplimentDialog(BuildContext context) {
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
                );
                if (success) {
                  if (Get.isDialogOpen ?? false) {
                    Get.back();
                  }
                  Get.back();
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

class _CircleActionBtn extends StatelessWidget {
  const _CircleActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
