import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/chat_repository.dart';
import '../domain/chat_models.dart';

class ChatRoomsState {
  final bool isLoading;
  final String? errorMessage;
  final List<ChatRoomModel> rooms;

  const ChatRoomsState({
    this.isLoading = false,
    this.errorMessage,
    this.rooms = const [],
  });

  ChatRoomsState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<ChatRoomModel>? rooms,
  }) {
    return ChatRoomsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      rooms: rooms ?? this.rooms,
    );
  }
}

final chatRoomsNotifierProvider =
    NotifierProvider<ChatRoomsNotifier, ChatRoomsState>(ChatRoomsNotifier.new);

class ChatRoomsNotifier extends Notifier<ChatRoomsState> {
  @override
  ChatRoomsState build() {
    final userId = ref.watch(authNotifierProvider.select((s) => s.user?.id));
    if (userId != null && userId.isNotEmpty) {
      Future.microtask(() => fetchRooms());
      return const ChatRoomsState(isLoading: true);
    }
    return const ChatRoomsState();
  }

  ChatRepository get _repository => ref.read(chatRepositoryProvider);

  Future<void> fetchRooms() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final rooms = await _repository.getChatRooms();
      state = state.copyWith(isLoading: false, rooms: rooms);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

class ChatMessagesState {
  final bool isLoading;
  final String? errorMessage;
  final String? currentRoomId;
  final List<ChatMessageModel> messages;

  const ChatMessagesState({
    this.isLoading = false,
    this.errorMessage,
    this.currentRoomId,
    this.messages = const [],
  });

  ChatMessagesState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? currentRoomId,
    List<ChatMessageModel>? messages,
  }) {
    return ChatMessagesState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentRoomId: currentRoomId ?? this.currentRoomId,
      messages: messages ?? this.messages,
    );
  }
}

final chatMessagesNotifierProvider =
    NotifierProvider<ChatMessagesNotifier, ChatMessagesState>(ChatMessagesNotifier.new);

class ChatMessagesNotifier extends Notifier<ChatMessagesState> {
  @override
  ChatMessagesState build() {
    return const ChatMessagesState();
  }

  ChatRepository get _repository => ref.read(chatRepositoryProvider);

  Future<void> fetchMessages(String roomId) async {
    state = state.copyWith(isLoading: true, errorMessage: null, currentRoomId: roomId);
    try {
      final messages = await _repository.getMessages(roomId);
      state = state.copyWith(isLoading: false, messages: messages);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> sendMessage(String roomId, String content) async {
    if (content.trim().isEmpty) return false;

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final optimisticMsg = ChatMessageModel(
      id: tempId,
      conversationId: roomId,
      senderId: 'ME',
      messageContent: content,
      sentAt: DateTime.now().toIso8601String(),
    );

    final currentMessages = state.messages;
    state = state.copyWith(messages: [...currentMessages, optimisticMsg]);

    try {
      final sent = await _repository.sendMessage(roomId, content);
      final updated = state.messages.map((m) => m.id == tempId ? sent : m).toList();
      state = state.copyWith(messages: updated);
      return true;
    } catch (e) {
      state = state.copyWith(messages: currentMessages);
      return false;
    }
  }
}
