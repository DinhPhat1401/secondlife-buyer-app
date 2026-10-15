import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_buyer/features/auth/presentation/auth_providers.dart';
import '../../../core/network/api_client.dart';
import '../domain/chat_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ChatRepository(client);
});

class ChatRepository {
  final ApiClient _client;

  ChatRepository(this._client);

  Future<List<ChatRoomModel>> getChatRooms() async {
    final response = await _client.get('/api/v1/chats');
    final raw = response.data;
    final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;

    List list = [];
    if (data is List) {
      list = data;
    } else if (data is Map && data.containsKey('content') && data['content'] is List) {
      list = data['content'] as List;
    } else if (data is Map && data.containsKey('items') && data['items'] is List) {
      list = data['items'] as List;
    }

    return list.map((item) => ChatRoomModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<ChatMessageModel>> getMessages(String roomId) async {
    final response = await _client.get('/api/v1/chats/$roomId/messages');
    final raw = response.data;
    final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;

    List list = [];
    if (data is List) {
      list = data;
    } else if (data is Map && data.containsKey('content') && data['content'] is List) {
      list = data['content'] as List;
    } else if (data is Map && data.containsKey('items') && data['items'] is List) {
      list = data['items'] as List;
    }

    return list.map((item) => ChatMessageModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<ChatMessageModel> sendMessage(String roomId, String messageContent) async {
    final response = await _client.post(
      '/api/v1/chats/$roomId/messages',
      data: {'messageContent': messageContent},
    );
    final raw = response.data;
    final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
    return ChatMessageModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ChatRoomModel> getOrCreateRoom(String postId) async {
    final response = await _client.post('/api/v1/chats/rooms?postId=$postId');
    final raw = response.data;
    final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
    return ChatRoomModel.fromJson(data as Map<String, dynamic>);
  }
}
