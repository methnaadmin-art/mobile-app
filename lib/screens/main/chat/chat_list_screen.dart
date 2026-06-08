import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:methna_app/app/controllers/chat_controller.dart';
import 'package:methna_app/app/data/models/conversation_model.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/core/utils/cloudinary_url.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/utils/google_fonts_stub.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/animated_empty_state.dart';
import 'package:methna_app/core/widgets/app_card.dart';
import 'package:methna_app/core/widgets/datify_shell.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DatifyBackground(
        compact: true,
        child: SafeArea(
          bottom: false,
          child: Obx(() {
            final controller = Get.find<ChatController>();

            if (controller.isLoading.value &&
                controller.conversations.isEmpty &&
                controller.onlineTodayUsers.isEmpty) {
              return _ChatLoadingState(isDark: isDark);
            }

            final currentUserId = Get.find<AuthService>().userId ?? '';
            final currentUser = Get.find<AuthService>().currentUser.value;
            final greetingName =
                currentUser?.publicShortName.trim().isNotEmpty == true
                ? currentUser!.publicShortName.trim()
                : (currentUser?.publicDisplayName.trim().isNotEmpty == true
                      ? currentUser!.publicDisplayName.trim().split(' ').first
                      : 'John');
            final conversations = controller.filteredConversations;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await controller.fetchConversations();
                await controller.fetchLiveTodayUsers();
              },
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  118,
                ),
                children: [
                  _LiveTodayPanel(
                    isDark: isDark,
                    greetingName: greetingName,
                    users: controller.onlineTodayUsers,
                    onSeeAll: () => _showActiveUsersSheet(context, controller),
                    onOpenUser: controller.openConversationWithUser,
                    onSearch: () => _showSearchSheet(context, controller),
                    onSettings: () => Get.toNamed(AppRoutes.messageSettings),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ConversationsSurface(
                    isDark: isDark,
                    totalConversations: conversations.length,
                    child: conversations.isEmpty
                        ? const _EmptyChatsState()
                        : Column(
                            children: List.generate(conversations.length, (
                              index,
                            ) {
                              final conversation = conversations[index];
                              return _ConversationTile(
                                conversation: conversation,
                                currentUserId: currentUserId,
                              );
                            }),
                          ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  static void _showSearchSheet(
    BuildContext context,
    ChatController controller,
  ) {
    final searchController = TextEditingController(
      text: controller.searchQuery.value,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark
          : AppColors.smoothBeige,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.handleDark
                      : const Color(0xFFE8E7EC),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: searchController,
                autofocus: true,
                onChanged: controller.searchConversations,
                decoration: InputDecoration(
                  hintText: 'search_chats'.tr,
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 18,
                    color: isDark
                        ? AppColors.textHintDark
                        : const Color(0xFF7F798E),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.cardDark
                      : const Color(0xFFF6F6F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void _showActiveUsersSheet(
    BuildContext context,
    ChatController controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark
          : AppColors.smoothBeige,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final users = controller.onlineTodayUsers;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.handleDark
                        : const Color(0xFFE8E7EC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'now_active'.tr,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: MediaQuery.of(sheetContext).size.height * 0.42,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: users.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _AvatarBubble(user: user, size: 50),
                        title: Text(
                          _displayName(user),
                          style: AppTextStyles.titleSmall.copyWith(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        subtitle: Text(
                          'start_chatting'.tr,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          controller.openConversationWithUser(user);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChatLoadingState extends StatelessWidget {
  const _ChatLoadingState({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        radius: AppRadii.xxl,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Text(
          'loading'.tr,
          style: AppTextStyles.labelLarge.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _LiveTodayPanel extends StatelessWidget {
  const _LiveTodayPanel({
    required this.isDark,
    required this.greetingName,
    required this.users,
    required this.onSeeAll,
    required this.onOpenUser,
    required this.onSearch,
    required this.onSettings,
  });

  final bool isDark;
  final String greetingName;
  final List<UserModel> users;
  final VoidCallback onSeeAll;
  final ValueChanged<UserModel> onOpenUser;
  final VoidCallback onSearch;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF22153D), Color(0xFF351F61)]
              : const [Color(0xFFEDE9FE), Color(0xFFF5C5CE)],
        ),
        border: Border.all(
          color: isDark
              ? const Color(0xFF4E347D)
              : AppColors.primary.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.13),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Salaam, $greetingName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      users.isEmpty
                          ? 'Start a respectful conversation when matches appear.'
                          : '${users.length} active connection${users.length == 1 ? '' : 's'} today',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.secondary.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onSeeAll,
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? const Color(0xFFFAD0D8)
                          : AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(72, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.white.withValues(alpha: 0.42),
                    ),
                    child: const Text('See all'),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _TopActionIcon(icon: LucideIcons.search, onTap: onSearch),
                      const SizedBox(width: 6),
                      _TopActionIcon(
                        icon: LucideIcons.moreVertical,
                        onTap: onSettings,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 92,
            child: users.isEmpty
                ? ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, _) => const _ActiveAvatarPlaceholder(),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: users.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _ActiveAvatarItem(
                        user: user,
                        onTap: () => onOpenUser(user),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConversationsSurface extends StatelessWidget {
  const _ConversationsSurface({
    required this.isDark,
    required this.totalConversations,
    required this.child,
  });

  final bool isDark;
  final int totalConversations;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      child: Column(
        children: [
          _ConversationsSectionHeader(
            isDark: isDark,
            totalConversations: totalConversations,
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ConversationsSectionHeader extends StatelessWidget {
  const _ConversationsSectionHeader({
    required this.isDark,
    required this.totalConversations,
  });

  final bool isDark;
  final int totalConversations;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isDark
                ? const Color(0xFF222C3A)
                : AppColors.primary.withValues(alpha: 0.12),
          ),
          child: const Icon(
            LucideIcons.messageSquare,
            size: 14,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'messages'.tr,
          style: AppTextStyles.titleMedium.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF263244)
                : AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$totalConversations',
            style: AppTextStyles.labelSmall.copyWith(
              color: isDark ? const Color(0xFF9ACBFF) : AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopActionIcon extends StatelessWidget {
  const _TopActionIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.09)
          : Colors.white.withValues(alpha: 0.86),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.textPrimaryDark : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _ActiveAvatarItem extends StatelessWidget {
  const _ActiveAvatarItem({required this.user, required this.onTap});

  final UserModel user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 66,
        child: Column(
          children: [
            _AvatarBubble(user: user, size: 56),
            const SizedBox(height: 6),
            Text(
              _displayName(user),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  const _AvatarBubble({required this.user, required this.size});

  final UserModel? user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = CloudinaryUrl.thumbnail(user?.mainPhotoUrl);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF3A4A63), Color(0xFF1F2B3D)]
                    : const [Color(0xFF6E3DFB), Color(0xFFEDE9FE)],
              ),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: imageUrl.isEmpty
                  ? _AvatarFallback(user: user)
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _AvatarFallback(user: user),
                    ),
            ),
          ),
          Positioned(
            right: -1,
            bottom: 4,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F0FF),
      alignment: Alignment.center,
      child: Text(
        Helpers.getInitials(user?.firstName, user?.lastName),
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _ActiveAvatarPlaceholder extends StatelessWidget {
  const _ActiveAvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 66,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF283345)
                  : AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 44,
            height: 8,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2B3444)
                  : AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
  });

  final ConversationModel conversation;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Get.find<ChatController>();
    final otherUser = conversation.otherUser;
    final unreadCount = conversation.unreadCount(currentUserId);
    final isLocked = conversation.isLocked;
    final isPremium = otherUser?.isPremium ?? false;
    final preview = isLocked
        ? (conversation.lockReason ??
              'This conversation is no longer available.')
        : (conversation.lastMessageContent ?? '').trim().isEmpty
        ? 'say_hi'.tr
        : conversation.lastMessageContent!.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: unreadCount > 0
            ? (isDark ? const Color(0xFF171C27) : const Color(0xFFFBF8FF))
            : (isDark ? const Color(0xFF171C27) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => controller.openConversation(conversation),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isLocked
                    ? AppColors.error.withValues(alpha: 0.18)
                    : unreadCount > 0
                    ? AppColors.primary.withValues(alpha: isDark ? 0.28 : 0.14)
                    : (isDark
                          ? const Color(0xFF273041)
                          : AppColors.primary.withValues(alpha: 0.06)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.03),
                  blurRadius: isDark ? 14 : 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              child: Row(
                children: [
                  _AvatarBubble(user: otherUser, size: 54),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _conversationName(otherUser),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontSize: 14,
                                  color: isLocked
                                      ? AppColors.error
                                      : (isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight),
                                ),
                              ),
                            ),
                            if (isPremium)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(
                                  LucideIcons.crown,
                                  size: 13,
                                  color: Color(0xFFA78BFA),
                                ),
                              ),
                            if (isLocked)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  LucideIcons.lock,
                                  size: 13,
                                  color: AppColors.error.withValues(
                                    alpha: 0.74,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isLocked
                                ? AppColors.error.withValues(alpha: 0.76)
                                : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        conversation.lastMessageAt != null
                            ? Helpers.formatTime(conversation.lastMessageAt!)
                            : '',
                        style: AppTextStyles.caption.copyWith(
                          color: unreadCount > 0
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                        ),
                      ),
                      const SizedBox(height: 8),
                      unreadCount > 0
                          ? Container(
                              constraints: const BoxConstraints(
                                minWidth: 22,
                                minHeight: 20,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$unreadCount',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : const SizedBox(height: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _conversationName(UserModel? user) {
    if (user == null) {
      return 'conversation'.tr;
    }

    final displayName = user.publicDisplayName.trim();
    if (displayName.isNotEmpty) {
      return displayName;
    }

    return 'conversation'.tr;
  }
}

class _EmptyChatsState extends StatelessWidget {
  const _EmptyChatsState();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      child: AnimatedEmptyState(
        lottieAsset: 'assets/animations/no_chat.json',
        title: 'no_chats_yet'.tr,
        subtitle: 'no_chats_desc'.tr,
        fallbackIcon: LucideIcons.messageCircle,
        fallbackColor: AppColors.primary,
        width: 182,
      ),
    );
  }
}

String _displayName(UserModel user) {
  final displayName = user.publicDisplayName.trim();
  if (displayName.isNotEmpty) {
    return displayName;
  }

  return 'user'.tr;
}
