import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/chat_controller.dart';
import 'package:methna_app/app/controllers/users_controller.dart';
import 'package:methna_app/app/data/models/message_model.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_shadows.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/chat_flow.dart';
import 'package:methna_app/core/widgets/ice_breaker_suggestions.dart';

class ChatDetailScreen extends GetView<ChatController> {
  const ChatDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = Get.find<AuthService>().userId ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) controller.leaveActiveChat();
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Obx(() {
                  final other =
                      controller.activeConversation.value?.otherUser;
                  final displayName =
                      other?.publicDisplayName.trim().isNotEmpty == true
                      ? other!.publicDisplayName
                      : 'chats'.tr;

                  final avatarUrl = other?.mainPhotoUrl ??
                      other?.fallbackPhotoUrl ??
                      (() {
                        for (final photo in other?.photos ?? const []) {
                          final url = photo.url.trim();
                          if (photo.isLocked || url.isEmpty) continue;
                          return url;
                        }
                        return null;
                      })();
                  final initials = Helpers.getInitials(
                    other?.firstName,
                    other?.lastName,
                  );

                  void openProfile() {
                    if (other == null) return;
                    if (Get.isRegistered<UsersController>()) {
                      Get.find<UsersController>().openUserDetail(other);
                      return;
                    }
                    Get.toNamed(
                      AppRoutes.userDetail,
                      arguments: {'user': other},
                    );
                  }

                  return Row(
                    children: [
                      _TopIconButton(
                        icon: LucideIcons.chevronLeft,
                        onTap: () {
                          controller.leaveActiveChat();
                          Get.back();
                        },
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: openProfile,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Row(
                              children: [
                                ChatAvatar(
                                  imageUrl: avatarUrl,
                                  fallback: initials.isEmpty
                                      ? displayName.characters.take(1).toString()
                                      : initials,
                                  size: 42,
                                  online: other?.isOnline ?? false,
                                  showGradientRing: true,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              displayName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyles.titleLarge.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          if (other?.isPremium ?? false)
                                            const Padding(
                                              padding: EdgeInsets.only(left: 6),
                                              child: Icon(
                                                LucideIcons.crown,
                                                size: 14,
                                                color: Color(0xFFA78BFA),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        controller.isTyping.value
                                            ? 'typing'.tr
                                            : (other?.isOnline ?? false)
                                            ? 'online'.tr
                                            : 'conversation'.tr,
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: controller.isTyping.value
                                              ? AppColors.primary
                                              : (isDark
                                                    ? AppColors.textSecondaryDark
                                                    : AppColors.textSecondaryLight),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _TopIconButton(
                        icon: LucideIcons.moreHorizontal,
                        onTap: () => Get.toNamed(AppRoutes.messageSettings),
                      ),
                    ],
                  );
                }),
              ),
              Expanded(
                child: Obx(() {
                    if (controller.messagesLoading.value &&
                        controller.activeMessages.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    final isLocked = controller.activeConversation.value?.isLocked ?? false;
                    final lockReason = controller.activeConversation.value?.lockReason;

                    if (controller.activeMessages.isEmpty && !isLocked) {
                      return _EmptyConversation(
                        suggestions: controller.iceBreakers.toList(),
                        onSuggestionTap: controller.sendIceBreaker,
                      );
                    }

                    return Column(
                      children: [
                        if (isLocked)
                          _LockedBanner(reason: lockReason),
                        Expanded(
                          child: controller.activeMessages.isEmpty
                              ? const SizedBox.shrink()
                              : ListView.builder(
                                  reverse: true,
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.lg,
                                    AppSpacing.sm,
                                    AppSpacing.lg,
                                    AppSpacing.md,
                                  ),
                                  itemCount: controller.activeMessages.length,
                                  itemBuilder: (context, index) {
                                    final message = controller.activeMessages[index];
                                    final isMine = message.isMine(currentUserId);
                                    final status = isMine
                                      ? controller.getMessageStatus(message.id)
                                      : null;
                                    final read = isMine &&
                                      (message.isRead ||
                                        controller.isMessageRead(message.id) ||
                                        status == MessageStatus.read);
                                    final showDate =
                                        index == controller.activeMessages.length - 1 ||
                                        !_sameDay(
                                          message.createdAt,
                                          controller.activeMessages[index + 1].createdAt,
                                        );

                                    return Column(
                                      children: [
                                        if (showDate)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: AppSpacing.md,
                                            ),
                                            child: ChatDateBadge(
                                              label: Helpers.formatDate(message.createdAt),
                                            ),
                                          ),
                                        _MessageBubble(
                                          message: message,
                                          isMine: isMine,
                                          status: status,
                                          isRead: read,
                                          onRetry: status == MessageStatus.failed
                                              ? () => controller.retryMessage(message.id)
                                              : null,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  }),
              ),
              Obx(() {
                final isLocked = controller.activeConversation.value?.isLocked ?? false;
                if (isLocked) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: _ComposerBar(controller: controller),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.cardDark.withValues(alpha: 0.82)
                : Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 17,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSuggestionTap;

  const _EmptyConversation({
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                LucideIcons.messageCircle,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'say_salam_first'.tr,
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'chat_warm_opener_desc'.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              IceBreakerSuggestions(
                suggestions: suggestions,
                onSelect: onSuggestionTap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final MessageStatus? status;
  final bool isRead;
  final VoidCallback? onRetry;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    this.status,
    this.isRead = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final receivedColor = isDark ? AppColors.cardDark : const Color(0xFFF8F3EF);
    final metaColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.68,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: isMine ? AppColors.primaryGradient : null,
              color: isMine ? null : receivedColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMine ? 18 : 6),
                bottomRight: Radius.circular(isMine ? 6 : 18),
              ),
            ),
            child: Text(
              message.content,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isMine
                    ? Colors.white
                    : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Helpers.formatTime(message.createdAt),
                style: AppTextStyles.labelSmall.copyWith(color: metaColor),
              ),
              if (isMine) ...[
                const SizedBox(width: 6),
                _DeliveryStatusChip(
                  status: status ?? MessageStatus.delivered,
                  isRead: isRead,
                  onRetry: onRetry,
                  isDark: isDark,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _DeliveryStatusChip extends StatelessWidget {
  const _DeliveryStatusChip({
    required this.status,
    required this.isRead,
    required this.isDark,
    this.onRetry,
  });

  final MessageStatus status;
  final bool isRead;
  final bool isDark;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final effectiveStatus = isRead ? MessageStatus.read : status;

    IconData icon;
    Color color;

    switch (effectiveStatus) {
      case MessageStatus.pending:
        icon = LucideIcons.clock3;
        color = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
        break;
      case MessageStatus.sent:
        icon = LucideIcons.check;
        color = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
        break;
      case MessageStatus.delivered:
        icon = LucideIcons.checkCheck;
        color = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
        break;
      case MessageStatus.read:
        icon = LucideIcons.checkCheck;
        color = AppColors.primary;
        break;
      case MessageStatus.failed:
        icon = LucideIcons.alertCircle;
        color = AppColors.error;
        break;
    }

    final iconWidget = Icon(icon, size: 13, color: color);

    if (effectiveStatus == MessageStatus.failed && onRetry != null) {
      return InkWell(
        onTap: onRetry,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          child: iconWidget,
        ),
      );
    }

    return iconWidget;
  }
}

class _ComposerBar extends StatelessWidget {
  final ChatController controller;

  const _ComposerBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark.withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: AppShadows.surface(isDark),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.messageTextController,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => controller.sendTypingIndicator(),
              decoration: InputDecoration(
                hintText: 'send_message_hint'.tr,
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textHintDark
                      : AppColors.textHintLight,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                final text = controller.messageTextController.text.trim();
                if (text.isEmpty) return;
                controller.sendMessage(text);
                controller.messageTextController.clear();
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.send,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedBanner extends StatelessWidget {
  final String? reason;
  const _LockedBanner({this.reason});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.error.withValues(alpha: 0.15)
            : AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.lock,
            size: 18,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              reason ?? 'This conversation is no longer available.'.tr,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
