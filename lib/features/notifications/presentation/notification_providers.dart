import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/notification_repository.dart';
import '../domain/notification_models.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return NotificationRepository(client: client);
});

class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final String selectedType;
  final bool unreadOnly;
  final String? errorMessage;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.selectedType = 'ALL',
    this.unreadOnly = false,
    this.errorMessage,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? selectedType,
    bool? unreadOnly,
    String? errorMessage,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      selectedType: selectedType ?? this.selectedType,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      errorMessage: errorMessage,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() {
    final userId = ref.watch(authNotifierProvider.select((s) => s.user?.id));
    if (userId != null && userId.isNotEmpty) {
      Future.microtask(() => loadData());
      return const NotificationState(isLoading: true);
    }
    return const NotificationState();
  }

  NotificationRepository get _repository => ref.read(notificationRepositoryProvider);

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final unread = await _repository.getUnreadCount();
      final items = await _repository.getNotifications(
        unreadOnly: state.unreadOnly ? true : null,
        type: state.selectedType == 'ALL' ? null : state.selectedType,
      );
      state = state.copyWith(
        notifications: items,
        unreadCount: unread,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải danh sách thông báo.',
      );
    }
  }

  void filterByType(String type) {
    state = state.copyWith(selectedType: type);
    loadData();
  }

  void toggleUnreadOnly(bool unreadOnly) {
    state = state.copyWith(unreadOnly: unreadOnly);
    loadData();
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      final updated = state.notifications.map((n) {
        if (n.id == id) return n.copyWith(isRead: true);
        return n;
      }).toList();
      final newCount = (state.unreadCount - 1).clamp(0, 999);
      state = state.copyWith(notifications: updated, unreadCount: newCount);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
      state = state.copyWith(notifications: updated, unreadCount: 0);
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _repository.deleteNotification(id);
      final item = state.notifications.firstWhere((n) => n.id == id, orElse: () => state.notifications.first);
      final wasUnread = !item.isRead;
      final updated = state.notifications.where((n) => n.id != id).toList();
      final newCount = wasUnread ? (state.unreadCount - 1).clamp(0, 999) : state.unreadCount;
      state = state.copyWith(notifications: updated, unreadCount: newCount);
    } catch (_) {}
  }

  Future<void> clearRead() async {
    try {
      await _repository.clearRead();
      final updated = state.notifications.where((n) => !n.isRead).toList();
      state = state.copyWith(notifications: updated);
    } catch (_) {}
  }
}

final notificationNotifierProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationNotifierProvider).unreadCount;
});
