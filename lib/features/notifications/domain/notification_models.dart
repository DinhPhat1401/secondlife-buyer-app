import 'package:flutter/material.dart';

enum NotificationType {
  order('ORDER', 'Đơn hàng', Icons.local_shipping_outlined, Color(0xFF3B82F6), Color(0xFFDBEAFE)),
  negotiation('NEGOTIATION', 'Trả giá', Icons.handshake_outlined, Color(0xFF8B5CF6), Color(0xFFEDE9FE)),
  chat('CHAT', 'Tin nhắn', Icons.chat_bubble_outline_rounded, Color(0xFF10B981), Color(0xFFD1FAE5)),
  wallet('WALLET', 'Ví & Tiền', Icons.account_balance_wallet_outlined, Color(0xFFF59E0B), Color(0xFFFEF3C7)),
  inspection('INSPECTION', 'Kiểm định', Icons.verified_outlined, Color(0xFF059669), Color(0xFFCCFBF1)),
  system('SYSTEM', 'Hệ thống', Icons.notifications_none_outlined, Color(0xFF6B7280), Color(0xFFF3F4F6));

  final String code;
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const NotificationType(this.code, this.label, this.icon, this.color, this.bgColor);

  static NotificationType fromCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'ORDER':
        return NotificationType.order;
      case 'NEGOTIATION':
        return NotificationType.negotiation;
      case 'CHAT':
        return NotificationType.chat;
      case 'WALLET':
        return NotificationType.wallet;
      case 'INSPECTION':
        return NotificationType.inspection;
      case 'SYSTEM':
      default:
        return NotificationType.system;
    }
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final String? referenceId;
  final String? referenceType;
  final String? targetUrl;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    this.referenceId,
    this.referenceType,
    this.targetUrl,
    required this.createdAt,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    bool? isRead,
    String? referenceId,
    String? referenceType,
    String? targetUrl,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      targetUrl: targetUrl ?? this.targetUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Thông báo mới',
      body: json['body'] ?? json['content'] ?? '',
      type: NotificationType.fromCode(json['type']?.toString() ?? json['notificationType']?.toString()),
      isRead: json['isRead'] == true || json['read'] == true,
      referenceId: json['referenceId']?.toString(),
      referenceType: json['referenceType']?.toString(),
      targetUrl: json['targetUrl']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
