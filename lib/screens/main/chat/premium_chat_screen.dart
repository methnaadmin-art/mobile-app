import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/core/widgets/datify_shell.dart';
import '../../../app/controllers/chat_controller.dart';
import '../../../app/data/services/auth_service.dart';
import '../../../app/data/models/message_model.dart';
import '../../../core/theme/premium_theme.dart';

/// Premium Chat Detail Screen with gradient bubbles
class PremiumChatScreen extends GetView<ChatController> {
  const PremiumChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: DatifyBackground(
        compact: true,
        child: Obx(() {
          final conversation = controller.activeConversation.value;
          if (conversation == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.gold),
            );
          }

          return Column(
            children: [
              // Header
              _ChatHeader(conversation: conversation),

              // Messages
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.background,
                        AppTheme.surface.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                  child: _MessagesList(),
                ),
              ),

              // Typing indicator
              if (controller.isTyping.value) _TypingIndicator(),

              // Input
              _MessageInput(),
            ],
          );
        }),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final dynamic conversation;

  const _ChatHeader({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final otherUser = conversation.otherUser;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: AppTheme.white10)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.chevronLeft,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: otherUser?.isOnline == true
                    ? AppTheme.success
                    : AppTheme.white10,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: otherUser?.mainPhotoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: otherUser.mainPhotoUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppTheme.surfaceElevated,
                      child: Icon(LucideIcons.user, color: AppTheme.white50),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Name & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherUser?.publicDisplayName.trim().isNotEmpty == true
                      ? otherUser!.publicDisplayName
                      : 'user'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  otherUser?.isOnline == true
                      ? 'online'.tr
                      : 'last_seen_recently'.tr,
                  style: TextStyle(
                    color: otherUser?.isOnline == true
                        ? AppTheme.success
                        : AppTheme.white50,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // More options
          IconButton(
            icon: const Icon(LucideIcons.moreVertical, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _MessagesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatController>(
      builder: (controller) {
        final messages = controller.activeMessages;
        // Get userId from auth service
        final auth = Get.find<AuthService>();
        final userId = auth.userId ?? '';

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == userId;
            final showAvatar =
                index == 0 ||
                (index > 0 && messages[index - 1].senderId != message.senderId);

            return _MessageBubble(
              message: message,
              isMe: isMe,
              showAvatar: showAvatar,
            );
          },
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showAvatar;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF22222E),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.user,
                size: 16,
                color: Colors.white54,
              ),
            )
          else if (!isMe)
            const SizedBox(width: 40),

          Flexible(
            child:
                Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: isMe
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF6E3DFB), Color(0xFFA78BFA)],
                              )
                            : null,
                        color: isMe ? null : const Color(0xFF22222E),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isMe ? 20 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 20),
                        ),
                        border: isMe
                            ? null
                            : Border.all(color: const Color(0x0DFFFFFF)),
                        boxShadow: isMe
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6E3DFB,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Text(
                        message.content,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.white,
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(delay: 0),
            const SizedBox(width: 4),
            _Dot(delay: 200),
            const SizedBox(width: 4),
            _Dot(delay: 400),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final int delay;

  const _Dot({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.white50,
            shape: BoxShape.circle,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          duration: 600.ms,
          delay: delay.ms,
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
        )
        .fade(duration: 600.ms, delay: delay.ms, begin: 0.3, end: 1);
  }
}

class _MessageInput extends StatefulWidget {
  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.trim().isNotEmpty;
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      Get.find<ChatController>().sendMessage(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.9),
        border: Border(top: BorderSide(color: AppTheme.white10)),
      ),
      child: Row(
        children: [
          // Text field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.white10),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'send_message_hint'.tr,
                  hintStyle: const TextStyle(color: AppTheme.white50),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Send button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _hasText
                ? GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6E3DFB), Color(0xFFA78BFA)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF6E3DFB),
                            blurRadius: 15,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.send,
                        color: Color(0xFF0B0B0F),
                        size: 20,
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0x0DFFFFFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.mic,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

