import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/notification_controller.dart';
import 'package:methna_app/app/data/models/notification_model.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/utils/google_fonts_stub.dart';
import 'package:methna_app/core/widgets/animated_empty_state.dart';

class NotificationsScreen extends GetView<NotificationController> {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => Get.back(),
              onSettings: () => Get.toNamed(AppRoutes.notificationSettings),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.refreshNotifications,
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  final notifications = controller.notifications;
                  if (notifications.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
                      children: const [
                        _EmptyState(),
                      ],
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
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
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
  });

  final VoidCallback onBack;
  final VoidCallback onSettings;

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
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF27242E),
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
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF27242E),
                    height: 1,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 44,
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: onSettings,
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.settings_outlined,
                    size: 19,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF27242E),
                  ),
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
  });

  final String title;
  final List<NotificationModel> items;
  final ValueChanged<NotificationModel> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Day group header with divider line ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : const Color(0xFF9B95A7),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 1,
                    color: isDark ? AppColors.borderDark : const Color(0xFFEEEAF4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // ── Notification rows with dividers ──
          for (var i = 0; i < items.length; i++) ...[
            _NotificationRow(
              notification: items[i],
              onTap: () => onTap(items[i]),
            ),
            if (i < items.length - 1)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 1,
                  thickness: 0.6,
                  color: isDark ? AppColors.borderDark : const Color(0xFFF0ECF5),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visual = _NotificationVisual.from(notification);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
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
                            : FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF26232C),
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
                        color: isDark ? AppColors.textSecondaryDark : Color(0xFF8F8A98),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatTime(context, notification.createdAt),
                      style: TextStyle(
                        fontSize: 10.8,
                        fontWeight: FontWeight.w400,
                        color: isDark ? AppColors.textHintDark : const Color(0xFFAAA6B1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: notification.isRead
                      ? (isDark ? AppColors.textHintDark : const Color(0xFFC7C2CF))
                      : (isDark ? AppColors.textSecondaryDark : const Color(0xFF9B95A7)),
                ),
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
    final bubbleColor = isDark && visual.background == Colors.white
        ? AppColors.surfaceDark
        : visual.background;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bubbleColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFEEEAF4),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        visual.icon,
        size: 18,
        color: visual.foreground,
      ),
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
          foreground: const Color(0xFFFFA726),
          background: const Color(0xFFFFF4E5),
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
          foreground: const Color(0xFFFF4F88),
          background: const Color(0xFFFFEFF5),
          imageUrl: imageUrl,
        );
      case 'message':
      case 'msg':
        return _NotificationVisual(
          icon: Icons.chat_bubble_outline_rounded,
          foreground: const Color(0xFF7C1EFF),
          background: const Color(0xFFF3EAFE),
          imageUrl: imageUrl,
        );
      case 'verification':
        return _NotificationVisual(
          icon: Icons.verified_user_outlined,
          foreground: const Color(0xFF66606F),
          background: Colors.white,
        );
      case 'subscription':
        return _NotificationVisual(
          icon: Icons.star_border_rounded,
          foreground: const Color(0xFF66606F),
          background: Colors.white,
        );
      default:
        return _NotificationVisual(
          icon: Icons.notifications_none_rounded,
          foreground: const Color(0xFF66606F),
          background: Colors.white,
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

String _displayNotificationText(
  String text,
  String rawType, {
  required bool isTitle,
  Map<String, dynamic>? data,
}) {
  final normalizedType = rawType.trim().toLowerCase();
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
      key = isTitle ? 'notification_title_message' : 'notification_body_message';
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
      final nestedMap = Map<String, dynamic>.from(nested);
      for (final directKey in directKeys) {
        final nestedValue = nestedMap[directKey];
        if (nestedValue is String && nestedValue.trim().isNotEmpty) {
          return nestedValue.trim();
        }
      }
    }
  }

  return 'someone'.tr;
}

bool _containsArabicScript(String value) {
  return RegExp(r'[\u0600-\u06FF]').hasMatch(value);
}
