import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/notification_controller.dart';
import 'package:methna_app/app/data/models/notification_model.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/utils/google_fonts_stub.dart';
import 'package:methna_app/core/utils/notification_route_resolver.dart';
import 'package:methna_app/core/widgets/animated_empty_state.dart';

class NotificationsScreen extends GetView<NotificationController> {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lightBackground = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.primarySurface, AppColors.surfaceLight],
    );
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.primarySurface,
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : null,
            gradient: isDark ? null : lightBackground,
          ),
          child: Column(
            children: [
              _Header(
                onBack: () => Get.back(),
                onSettings: () => Get.toNamed(AppRoutes.notificationSettings),
                onMarkAllRead: () => controller.markAllAsRead(),
                onClearAll: () => _confirmClearAll(context),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: controller.refreshNotifications,
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 110, 16, 24),
                        children: const [
                          _NotificationsLoadingState(),
                        ],
                      );
                    }

                    final notifications = controller.notifications;
                    if (notifications.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
                        children: const [_EmptyState()],
                      );
                    }

                    final sections = _buildSections(context, notifications);
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(0, 4, 0, 20),
                      itemCount: sections.length,
                      itemBuilder: (context, index) {
                        final section = sections[index];
                        return _Section(
                          title: section.title,
                          items: section.items,
                          onTap: controller.openNotification,
                          onDelete: controller.deleteNotification,
                        );
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    if (controller.notifications.isEmpty) return;

    final shouldClear = await Get.dialog<bool>(
      AlertDialog(
        title: Text('clear_all'.tr),
        content: Text('clear_all_notifications_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'clear_all'.tr,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      await controller.clearAllNotifications();
    }
  }

  List<_NotificationSectionData> _buildSections(
    BuildContext context,
    List<NotificationModel> notifications,
  ) {
    final grouped = <String, List<NotificationModel>>{};
    for (final notification in notifications) {
      final key = _sectionLabel(context, notification.createdAt);
      grouped.putIfAbsent(key, () => <NotificationModel>[]).add(notification);
    }

    return grouped.entries
        .map((entry) => _NotificationSectionData(entry.key, entry.value))
        .toList();
  }

  String _sectionLabel(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'today'.tr;
    if (diff == 1) return 'yesterday'.tr;
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
    required this.onSettings,
    required this.onMarkAllRead,
    required this.onClearAll,
  });

  final VoidCallback onBack;
  final VoidCallback onSettings;
  final VoidCallback onMarkAllRead;
  final Future<void> Function() onClearAll;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: SizedBox(
        height: 42,
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: onBack,
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'notification'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    height: 1,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 52,
              child: Align(
                alignment: Alignment.centerRight,
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceMutedLight,
                  elevation: 6,
                  offset: const Offset(0, 38),
                  onSelected: (value) {
                    switch (value) {
                      case 'mark_all_read':
                        onMarkAllRead();
                        break;
                      case 'clear_all':
                        unawaited(onClearAll());
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'mark_all_read',
                      child: Row(
                        children: [
                          Icon(
                            Icons.done_all_rounded,
                            size: 18,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'mark_all_read'.tr,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_sweep_outlined,
                            size: 18,
                            color: isDark
                                ? AppColors.primaryLight
                                : AppColors.error,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'clear_all'.tr,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.primaryLight
                                  : AppColors.error,
                            ),
                          ),
                        ],
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

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.onTap,
    required this.onDelete,
  });

  final String title;
  final List<NotificationModel> items;
  final ValueChanged<NotificationModel> onTap;
  final Future<void> Function(NotificationModel) onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceGlassDark
              : AppColors.surfaceMutedLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: isDark
              ? const []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Day group header with divider line ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // ── Notification rows with dividers ──
            for (var i = 0; i < items.length; i++) ...[
              Dismissible(
                key: ValueKey(
                  '${items[i].id}_${items[i].createdAt.millisecondsSinceEpoch}_$i',
                ),
                direction: DismissDirection.endToStart,
                background: const SizedBox.shrink(),
                secondaryBackground: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.only(right: 18),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                ),
                onDismissed: (_) {
                  unawaited(onDelete(items[i]));
                },
                child: _NotificationRow(
                  notification: items[i],
                  onTap: () => onTap(items[i]),
                ),
              ),
              if (i < items.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    height: 1,
                    thickness: 0.6,
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visual = _NotificationVisual.from(notification);
    final highlightColor = notification.isRead
        ? Colors.transparent
        : (isDark
              ? AppColors.primary.withValues(alpha: 0.14)
              : const Color(0xFFF4F0FF));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: BoxDecoration(
            color: highlightColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LeadingVisual(visual: visual),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayNotificationText(
                        notification.title,
                        notification.type,
                        isTitle: true,
                        data: notification.data,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.2,
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _displayNotificationText(
                        notification.body,
                        notification.type,
                        isTitle: false,
                        data: notification.data,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.6,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatTime(context, notification.createdAt),
                      style: TextStyle(
                        fontSize: 10.8,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? AppColors.textHintDark
                            : AppColors.textHintLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Row(
                children: [
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8, top: 2),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: notification.isRead
                          ? (isDark
                                ? AppColors.textHintDark
                                : AppColors.textHintLight)
                          : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(BuildContext context, DateTime date) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(date),
      alwaysUse24HourFormat: false,
    );
  }
}

bool _hasWhoLikedMeAccess() {
  if (!Get.isRegistered<MonetizationService>()) {
    return false;
  }

  return Get.find<MonetizationService>().hasWhoLikedMeAccess;
}

String _displayNotificationText(
  String text,
  String rawType, {
  required bool isTitle,
  Map<String, dynamic>? data,
}) {
  final normalizedType = normalizeNotificationType(rawType);

  if ((normalizedType == 'like' || normalizedType == 'who_liked_me') &&
      !_hasWhoLikedMeAccess()) {
    return isTitle
        ? 'notification_like_private_title'.tr
        : 'notification_like_private_body'.tr;
  }

  final normalizedText = normalizedType == 'super_like'
      ? text.replaceAll(
          RegExp(r'super[\s_-]?like', caseSensitive: false),
          'like',
        )
      : text;

  final localeCode = Get.locale?.languageCode.toLowerCase() ?? '';
  if (!localeCode.startsWith('ar')) {
    return normalizedText;
  }

  if (normalizedText.trim().isNotEmpty &&
      _containsArabicScript(normalizedText)) {
    return normalizedText;
  }

  final localized = _localizedNotificationByType(
    normalizedType,
    isTitle: isTitle,
    data: data,
  );
  if (localized != null && localized.trim().isNotEmpty) {
    return localized;
  }

  if (normalizedText.trim().isNotEmpty) {
    return normalizedText;
  }

  return isTitle
      ? 'notification_title_default'.tr
      : 'notification_body_default'.tr;
}

String? _localizedNotificationByType(
  String normalizedType, {
  required bool isTitle,
  Map<String, dynamic>? data,
}) {
  final actorName = _extractActorName(data);
  late final String key;

  switch (normalizedType) {
    case 'match':
    case 'new_match':
      key = isTitle ? 'notification_title_match' : 'notification_body_match';
      break;
    case 'like':
    case 'super_like':
    case 'connection_request':
      key = isTitle ? 'notification_title_like' : 'notification_body_like';
      break;
    case 'compliment':
    case 'compliment_received':
    case 'compliment_sent':
      key = isTitle
          ? 'notification_title_compliment'
          : 'notification_body_compliment';
      break;
    case 'message':
    case 'msg':
      key = isTitle
          ? 'notification_title_message'
          : 'notification_body_message';
      break;
    case 'subscription':
      key = isTitle
          ? 'notification_title_subscription'
          : 'notification_body_subscription';
      break;
    case 'verification':
      key = isTitle
          ? 'notification_title_verification'
          : 'notification_body_verification';
      break;
    default:
      return null;
  }

  final translated = key.trParams({'name': actorName});
  if (translated == key) {
    return null;
  }
  return translated;
}

String _extractActorName(Map<String, dynamic>? data) {
  if (data == null || data.isEmpty) {
    return 'someone'.tr;
  }

  try {
    final parsedUser = UserModel.fromApiEntry(data);
    if (parsedUser.publicDisplayName.trim().isNotEmpty) {
      return parsedUser.publicDisplayName.trim();
    }
  } catch (_) {}

  const directKeys = [
    'senderName',
    'likerName',
    'targetUserName',
    'userName',
    'username',
    'name',
    'fullName',
    'firstName',
  ];

  for (final key in directKeys) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }

  const nestedKeys = ['sender', 'user', 'targetUser'];
  for (final key in nestedKeys) {
    final nested = data[key];
    if (nested is Map) {
      try {
        final nestedUser = UserModel.fromApiEntry(
          Map<String, dynamic>.from(nested),
        );
        if (nestedUser.publicDisplayName.trim().isNotEmpty) {
          return nestedUser.publicDisplayName.trim();
        }
      } catch (_) {
        final nestedMap = Map<String, dynamic>.from(nested);
        for (final directKey in directKeys) {
          final nestedValue = nestedMap[directKey];
          if (nestedValue is String && nestedValue.trim().isNotEmpty) {
            return nestedValue.trim();
          }
        }
      }
    }
  }

  return 'someone'.tr;
}

bool _containsArabicScript(String value) {
  return RegExp(r'[\u0600-\u06FF]').hasMatch(value);
}

class _LeadingVisual extends StatelessWidget {
  const _LeadingVisual({required this.visual});

  final _NotificationVisual visual;

  @override
  Widget build(BuildContext context) {
    if (visual.imageUrl != null && visual.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: visual.imageUrl!,
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => _IconBubble(visual: visual),
        ),
      );
    }

    return _IconBubble(visual: visual);
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.visual});

  final _NotificationVisual visual;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor =
        isDark && visual.background == AppColors.surfaceMutedLight
        ? AppColors.surfaceMutedDark
        : visual.background;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bubbleColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(visual.icon, size: 18, color: visual.foreground),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return AnimatedEmptyState(
      lottieAsset: 'assets/animations/no_notifications.json',
      title: 'no_notifications_yet'.tr,
      subtitle: 'no_notifications_desc'.tr,
      fallbackIcon: Icons.notifications_none_rounded,
      fallbackColor: AppColors.primary,
      width: 176,
    );
  }
}

class _NotificationsLoadingState extends StatelessWidget {
  const _NotificationsLoadingState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Text(
        'loading'.tr,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}

class _NotificationSectionData {
  const _NotificationSectionData(this.title, this.items);

  final String title;
  final List<NotificationModel> items;
}

class _NotificationVisual {
  const _NotificationVisual({
    required this.icon,
    required this.foreground,
    required this.background,
    this.imageUrl,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final String? imageUrl;

  factory _NotificationVisual.from(NotificationModel notification) {
    final data = notification.data ?? const <String, dynamic>{};
    final imageUrl = _extractImageUrl(data);
    final type = notification.type.toLowerCase().trim();

    switch (type) {
      case 'match':
      case 'new_match':
        return _NotificationVisual(
          icon: Icons.auto_awesome_rounded,
          foreground: AppColors.primaryLight,
          background: AppColors.primarySurface,
          imageUrl: imageUrl,
        );
      case 'like':
      case 'super_like':
      case 'compliment':
      case 'compliment_received':
      case 'compliment_sent':
      case 'connection_request':
        return _NotificationVisual(
          icon: Icons.favorite_border_rounded,
          foreground: AppColors.primary,
          background: AppColors.primarySurface,
          imageUrl: imageUrl,
        );
      case 'message':
      case 'msg':
        return _NotificationVisual(
          icon: Icons.chat_bubble_outline_rounded,
          foreground: AppColors.secondary,
          background: AppColors.primarySurface,
          imageUrl: imageUrl,
        );
      case 'verification':
        return _NotificationVisual(
          icon: Icons.verified_user_outlined,
          foreground: AppColors.primaryDark,
          background: AppColors.primarySurface,
        );
      case 'subscription':
        return _NotificationVisual(
          icon: Icons.star_border_rounded,
          foreground: AppColors.primaryDark,
          background: AppColors.primarySurface,
        );
      default:
        return _NotificationVisual(
          icon: Icons.notifications_none_rounded,
          foreground: AppColors.primaryDark,
          background: AppColors.primarySurface,
          imageUrl: imageUrl,
        );
    }
  }

  static String? _extractImageUrl(Map<String, dynamic> data) {
    const keys = [
      'photoUrl',
      'avatarUrl',
      'imageUrl',
      'profilePhoto',
      'mainPhotoUrl',
      'senderPhotoUrl',
      'senderAvatarUrl',
      'targetUserPhotoUrl',
      'targetUserAvatarUrl',
      'userPhotoUrl',
      'userAvatarUrl',
    ];

    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }

    return null;
  }
}
