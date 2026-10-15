import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/chat_models.dart';
import '../chat_providers.dart';

class ChatInboxScreen extends ConsumerStatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  ConsumerState<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends ConsumerState<ChatInboxScreen> {
  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatRoomsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tin Nhắn & Đàm Phán',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.handshake_outlined, color: AppColors.primary),
            tooltip: 'Yêu cầu trả giá',
            onPressed: () => context.push('/negotiations'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(chatRoomsNotifierProvider.notifier).fetchRooms(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner directing to Negotiations
          InkWell(
            onTap: () => context.push('/negotiations'),
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_offer_outlined, color: Color(0xFFE65100), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yêu Cầu Thương Lượng Giá',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100), fontSize: 13),
                        ),
                        Text(
                          'Xem danh sách khách hàng đang đề xuất mặc cả sản phẩm',
                          style: TextStyle(fontSize: 11, color: Color(0xFF795548)),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Color(0xFFE65100)),
                ],
              ),
            ),
          ),
          Expanded(
            child: _buildInboxContent(chatState),
          ),
        ],
      ),
    );
  }

  Widget _buildInboxContent(ChatRoomsState chatState) {
    if (chatState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (chatState.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Lỗi: ${chatState.errorMessage}', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.read(chatRoomsNotifierProvider.notifier).fetchRooms(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (chatState.rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text(
              'Chưa có tin nhắn nào',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Khi khách hàng hỏi mua sản phẩm, cuộc trò chuyện sẽ hiện ở đây',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(chatRoomsNotifierProvider.notifier).fetchRooms(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: chatState.rooms.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 68),
        itemBuilder: (context, index) {
          final room = chatState.rooms[index];
          return _buildRoomTile(context, room);
        },
      ),
    );
  }

  Widget _buildRoomTile(BuildContext context, ChatRoomModel room) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onTap: () => context.push('/chats/${room.id}', extra: room),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              room.buyerName.isNotEmpty ? room.buyerName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          if (room.postImageUrl != null && room.postImageUrl!.isNotEmpty)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  image: DecorationImage(
                    image: NetworkImage(room.postImageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              room.buyerName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (room.updatedAt != null)
            Text(
              _formatTime(room.updatedAt!),
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (room.postTitle != null) ...[
            const SizedBox(height: 2),
            Text(
              'Tin: ${room.postTitle}',
              style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 2),
          Text(
            room.lastMessage ?? 'Bắt đầu cuộc trò chuyện...',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatTime(String raw) {
    try {
      final date = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      if (date.day == now.day && date.month == now.month && date.year == now.year) {
        return DateFormat('HH:mm').format(date);
      }
      return DateFormat('dd/MM').format(date);
    } catch (_) {
      return '';
    }
  }
}
