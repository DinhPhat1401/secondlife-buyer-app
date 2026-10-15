import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/chat_models.dart';
import '../chat_providers.dart';

class ChatConversationScreen extends ConsumerStatefulWidget {
  final String roomId;
  final ChatRoomModel? room;

  const ChatConversationScreen({
    super.key,
    required this.roomId,
    this.room,
  });

  @override
  ConsumerState<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends ConsumerState<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatMessagesNotifierProvider.notifier).fetchMessages(widget.roomId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    final success = await ref
        .read(chatMessagesNotifierProvider.notifier)
        .sendMessage(widget.roomId, text);

    setState(() => _isSending = false);

    if (success) {
      _scrollToBottom();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể gửi tin nhắn. Vui lòng thử lại.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(chatMessagesNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                widget.room != null && widget.room!.buyerName.isNotEmpty
                    ? widget.room!.buyerName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.room?.buyerName ?? 'Khách hàng',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Đang hoạt động',
                    style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(chatMessagesNotifierProvider.notifier).fetchMessages(widget.roomId),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.room?.postTitle != null) _buildProductBanner(),
          Expanded(
            child: _buildMessagesList(messagesState),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ChatMessagesState messagesState) {
    if (messagesState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (messagesState.errorMessage != null) {
      return Center(
        child: Text('Lỗi tải tin nhắn: ${messagesState.errorMessage}',
            style: const TextStyle(color: AppColors.textSecondary)),
      );
    }

    final messages = messagesState.messages;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    if (messages.isEmpty) {
      return const Center(
        child: Text('Chưa có tin nhắn nào. Hãy gửi lời chào đến người mua!',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return _buildMessageItem(msg);
      },
    );
  }

  Widget _buildProductBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: widget.room?.postImageUrl != null
                ? Image.network(
                    widget.room!.postImageUrl!,
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholderSquare(),
                  )
                : _buildPlaceholderSquare(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.room!.postTitle!,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
            icon: const Icon(Icons.handshake_outlined, size: 16, color: AppColors.primary),
            label: const Text('Xem Trả Giá', style: TextStyle(fontSize: 12, color: AppColors.primary)),
            onPressed: () => context.push('/negotiations'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderSquare() {
    return Container(
      width: 38,
      height: 38,
      color: AppColors.divider,
      child: const Icon(Icons.kitchen_outlined, size: 20, color: AppColors.textMuted),
    );
  }

  Widget _buildMessageItem(ChatMessageModel msg) {
    if (msg.isSystem) {
      return _buildSystemOfferBubble(msg);
    }

    final isMe = msg.senderId == 'ME' ||
        (widget.room != null && msg.senderId == widget.room!.sellerId);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 14),
          ),
          border: isMe ? null : Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.messageContent,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatMessageTime(msg.sentAt),
              style: TextStyle(
                color: isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemOfferBubble(ChatMessageModel msg) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          border: Border.all(color: const Color(0xFFFED7AA)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.handshake_rounded, color: Color(0xFFEA580C), size: 18),
                const SizedBox(width: 6),
                Text(
                  msg.cleanText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9A3412),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => context.push('/negotiations'),
              child: const Text(
                'Bấm vào đây để Xem & Chấp thuận hoặc Từ chối',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _messageController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Nhập tin nhắn trả lời...',
                    hintStyle: TextStyle(fontSize: 14, color: AppColors.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(Icons.send_rounded, color: AppColors.primary),
              onPressed: _handleSendMessage,
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(String raw) {
    try {
      final date = DateTime.parse(raw).toLocal();
      return DateFormat('HH:mm').format(date);
    } catch (_) {
      return '';
    }
  }
}
