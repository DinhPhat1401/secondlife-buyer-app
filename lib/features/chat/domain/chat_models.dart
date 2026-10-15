import 'dart:convert';

class ChatRoomModel {
  final String id;
  final String postId;
  final String? postTitle;
  final String? postImageUrl;
  final String buyerId;
  final String buyerName;
  final String? buyerAvatar;
  final String sellerId;
  final String sellerName;
  final String? sellerAvatar;
  final String? lastMessage;
  final String? updatedAt;

  const ChatRoomModel({
    required this.id,
    required this.postId,
    this.postTitle,
    this.postImageUrl,
    required this.buyerId,
    this.buyerName = 'Người mua',
    this.buyerAvatar,
    required this.sellerId,
    this.sellerName = 'Người bán',
    this.sellerAvatar,
    this.lastMessage,
    this.updatedAt,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      postTitle: json['postTitle']?.toString() ?? 'Sản phẩm gia dụng',
      postImageUrl: json['postImageUrl']?.toString() ?? json['thumbnailUrl']?.toString(),
      buyerId: json['buyerId']?.toString() ?? '',
      buyerName: json['buyerName']?.toString() ?? 'Khách hàng',
      buyerAvatar: json['buyerAvatar']?.toString(),
      sellerId: json['sellerId']?.toString() ?? '',
      sellerName: json['sellerName']?.toString() ?? 'Cửa hàng của tôi',
      sellerAvatar: json['sellerAvatar']?.toString(),
      lastMessage: json['lastMessage']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

class ChatMessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String messageContent;
  final String sentAt;

  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageContent,
    required this.sentAt,
  });

  bool get isSystem => messageContent.trim().startsWith('SYSTEM:');

  String get cleanText {
    if (isSystem) {
      final raw = messageContent.trim().substring(7).trim();
      try {
        final parsed = jsonDecode(raw);
        if (parsed is Map && parsed['type'] == 'OFFER') {
          return 'Đề xuất giá mới: ${parsed['price']} đ';
        }
      } catch (_) {}
      return raw;
    }
    return messageContent;
  }

  bool get isOffer {
    if (!isSystem) return false;
    final raw = messageContent.trim().substring(7).trim();
    try {
      final parsed = jsonDecode(raw);
      return parsed is Map && parsed['type'] == 'OFFER';
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic>? get offerPayload {
    if (!isOffer) return null;
    final raw = messageContent.trim().substring(7).trim();
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map<String, dynamic>) return parsed;
    } catch (_) {}
    return null;
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      messageContent: json['messageContent']?.toString() ?? '',
      sentAt: json['sentAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
}
