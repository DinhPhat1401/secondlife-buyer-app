import 'package:secondlife_app_buyer/core/network/api_client.dart';
import 'package:secondlife_app_buyer/core/network/api_endpoints.dart';
import '../domain/notification_models.dart';

class NotificationRepository {
  final ApiClient client;

  NotificationRepository({required this.client});

  Future<List<NotificationModel>> getNotifications({
    bool? unreadOnly,
    String? type,
    int page = 0,
    int size = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (unreadOnly != null) queryParams['unreadOnly'] = unreadOnly;
    if (type != null && type.isNotEmpty && type != 'ALL') queryParams['type'] = type;

    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.notifications,
      queryParameters: queryParams,
    );

    final data = response.data;
    List<dynamic> list = [];
    if (data != null) {
      if (data['content'] is List) {
        list = data['content'] as List;
      } else if (data['data'] is List) {
        list = data['data'] as List;
      } else if (data['items'] is List) {
        list = data['items'] as List;
      }
    }
    return list
        .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await client.get<Map<String, dynamic>>(ApiEndpoints.notificationsUnreadCount);
    final data = response.data;
    if (data != null && data['unreadCount'] is num) {
      return (data['unreadCount'] as num).toInt();
    }
    return 0;
  }

  Future<bool> markAsRead(String id) async {
    await client.patch<Map<String, dynamic>>(ApiEndpoints.notificationMarkRead(id));
    return true;
  }

  Future<bool> markAllAsRead() async {
    await client.patch<Map<String, dynamic>>(ApiEndpoints.notificationReadAll);
    return true;
  }

  Future<bool> deleteNotification(String id) async {
    await client.delete<void>(ApiEndpoints.notificationDelete(id));
    return true;
  }

  Future<bool> clearRead() async {
    await client.delete<void>(ApiEndpoints.notificationClearRead);
    return true;
  }
}
