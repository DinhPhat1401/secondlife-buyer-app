import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/notification_models.dart';
import '../notification_providers.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen> {
  String _selectedCategory = 'ALL';

  final List<({String label, String code})> _categories = const [
    (label: 'Tất cả', code: 'ALL'),
    (label: 'Đơn hàng', code: 'ORDER'),
    (label: 'Trả giá', code: 'NEGOTIATION'),
    (label: 'Tin nhắn', code: 'CHAT'),
    (label: 'Ví & Tiền', code: 'WALLET'),
    (label: 'Kiểm định', code: 'INSPECTION'),
  ];

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  void _handleNotificationTap(NotificationModel notif) {
    ref.read(notificationNotifierProvider.notifier).markAsRead(notif.id);

    if (notif.targetUrl != null && notif.targetUrl!.isNotEmpty) {
      context.push(notif.targetUrl!);
      return;
    }

    switch (notif.type) {
      case NotificationType.order:
        context.push('/orders');
        break;
      case NotificationType.negotiation:
        context.push('/negotiations');
        break;
      case NotificationType.chat:
        context.push('/chats');
        break;
      case NotificationType.wallet:
        context.push('/wallet');
        break;
      case NotificationType.inspection:
        context.push('/orders');
        break;
      case NotificationType.system:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Thông Báo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (state.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.unreadCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(notificationNotifierProvider.notifier).loadData();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'read_all') {
                ref.read(notificationNotifierProvider.notifier).markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc.')),
                );
              } else if (val == 'clear_read') {
                ref.read(notificationNotifierProvider.notifier).clearRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã dọn dẹp các thông báo đã đọc.')),
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'read_all',
                child: Row(
                  children: [
                    Icon(Icons.done_all, size: 18, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text('Đánh dấu tất cả đã đọc'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_read',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 10),
                    Text('Xóa thông báo đã đọc'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Categories Horizontal Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat.code;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat.label),
                      selected: isSelected,
                      selectedColor: AppColors.primaryLight,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = cat.code);
                          ref.read(notificationNotifierProvider.notifier).filterByType(cat.code);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Notification List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(notificationNotifierProvider.notifier).loadData(),
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.notifications.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: state.notifications.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final notif = state.notifications[index];
                            return _buildNotificationCard(notif);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_off_outlined,
                  size: 48,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Không có thông báo nào',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Mọi thông tin về đơn hàng, trả giá và ví sẽ hiển thị tại đây.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(NotificationModel notif) {
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(notificationNotifierProvider.notifier).deleteNotification(notif.id);
      },
      child: InkWell(
        onTap: () => _handleNotificationTap(notif),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notif.isRead ? Colors.white : const Color(0xFFFFFBF9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: notif.isRead ? AppColors.border : AppColors.primary.withOpacity(0.3),
              width: notif.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Type
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: notif.type.bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(notif.type.icon, color: notif.type.color, size: 20),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notif.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTimeAgo(notif.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
