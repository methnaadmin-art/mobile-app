import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/controllers/chat_controller.dart';
import 'package:methna_app/app/data/models/conversation_model.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/constants/app_constants.dart';
import 'package:methna_app/core/utils/cloudinary_url.dart';
import 'package:methna_app/core/utils/google_fonts_stub.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/animated_empty_state.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final controller = Get.find<ChatController>();

          if (controller.isLoading.value &&
              controller.conversations.isEmpty &&
              controller.onlineTodayUsers.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final currentUserId = Get.find<AuthService>().userId ?? '';
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
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 118),
              children: [
                _ChatsTopBar(
                  onSearch: () => _showSearchSheet(context, controller),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'now_active'.tr,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : const Color(0xFF232129),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _showActiveUsersSheet(context, controller),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(56, 20),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'see_all'.tr,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 72,
                  child: controller.onlineTodayUsers.isEmpty
                      ? ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 5,
                          separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                          itemBuilder: (context, index) =>
                            const _ActiveAvatarPlaceholder(),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: controller.onlineTodayUsers.length,
                          separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final user = controller.onlineTodayUsers[index];
                            return _ActiveAvatarItem(
                              user: user,
                              onTap: () => controller.openConversationWithUser(user),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 18),
                if (conversations.isEmpty)
                  const _EmptyChatsState()
                else
                  ...List.generate(conversations.length, (index) {
                    final conversation = conversations[index];
                    return _ConversationTile(
                      conversation: conversation,
                      currentUserId: currentUserId,
                    );
                  }),
              ],
            ),
          );
        }),
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
          : Colors.white,
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
                  color: isDark ? AppColors.handleDark : const Color(0xFFE8E7EC),
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
                  fillColor: isDark ? AppColors.cardDark : const Color(0xFFF6F6F8),
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
          : Colors.white,
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
                    color: isDark ? AppColors.handleDark : const Color(0xFFE8E7EC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'now_active'.tr,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF232129),
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
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : const Color(0xFF232129),
                          ),
                        ),
                        subtitle: Text(
                          'start_chatting'.tr,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : const Color(0xFF8B8797),
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

class _ChatsTopBar extends StatelessWidget {
  const _ChatsTopBar({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ClipOval(
              child: Image.asset(
                AppConstants.appLogoAsset,
                width: 20,
                height: 20,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Text(
            'chats'.tr,
            style: GoogleFonts.poppins(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : const Color(0xFF232129),
              letterSpacing: -0.3,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TopActionIcon(
                  icon: LucideIcons.search,
                  onTap: onSearch,
                ),
                const SizedBox(width: 4),
                _TopActionIcon(
                  icon: LucideIcons.moreVertical,
                  onTap: () => Get.toNamed(AppRoutes.messageSettings),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopActionIcon extends StatelessWidget {
  const _TopActionIcon({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 19,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF232129),
          ),
        ),
      ),
    );
  }
}

class _ActiveAvatarItem extends StatelessWidget {
  const _ActiveAvatarItem({
    required this.user,
    required this.onTap,
  });

  final UserModel user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _AvatarBubble(user: user, size: 56),
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  const _AvatarBubble({
    required this.user,
    required this.size,
  });

  final UserModel? user;
  final double size;

  @override
  Widget build(BuildContext context) {
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFA020F9), Color(0xFF7C1EFF)],
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
                color: AppColors.primary,
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
      color: const Color(0xFFF1E8FF),
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
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F1F6),
        shape: BoxShape.circle,
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
    final preview = (conversation.lastMessageContent ?? '').trim().isEmpty
        ? 'say_hi'.tr
        : conversation.lastMessageContent!.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.openConversation(conversation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              _AvatarBubble(
                user: otherUser,
                size: 52,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _conversationName(otherUser),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : const Color(0xFF232129),
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : const Color(0xFF8D8899),
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
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                      color: unreadCount > 0
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : const Color(0xFF8D8899)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  unreadCount > 0
                      ? Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$unreadCount',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const SizedBox(height: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _conversationName(UserModel? user) {
    if (user == null) {
      return 'conversation'.tr;
    }

    final fullName = user.fullName.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }

    final displayName = user.displayName.trim();
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
    return AnimatedEmptyState(
      lottieAsset: 'assets/animations/no_chat.json',
      title: 'no_chats_yet'.tr,
      subtitle: 'no_chats_desc'.tr,
      fallbackIcon: LucideIcons.messageCircle,
      fallbackColor: AppColors.primary,
      width: 182,
    );
  }
}

String _displayName(UserModel user) {
  final firstName = user.firstName?.trim() ?? '';
  if (firstName.isNotEmpty) {
    return firstName;
  }

  final displayName = user.displayName.trim();
  if (displayName.isNotEmpty) {
    return displayName;
  }

  return 'user'.tr;
}
