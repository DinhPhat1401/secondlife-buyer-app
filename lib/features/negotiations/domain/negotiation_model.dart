class NegotiationModel {
  final String id;
  final String postId;
  final String postTitle;
  final String? buyerId;
  final String buyerName;
  final String? sellerId;
  final double offeredPrice;
  final double? originalPrice;
  final String status;
  final String? createdAt;
  final String? expiredAt;
  final String? productImageUrl;

  const NegotiationModel({
    required this.id,
    required this.postId,
    required this.postTitle,
    this.buyerId,
    this.buyerName = 'Người mua',
    this.sellerId,
    required this.offeredPrice,
    this.originalPrice,
    required this.status,
    this.createdAt,
    this.expiredAt,
    this.productImageUrl,
  });

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isAccepted => status.toUpperCase() == 'ACCEPTED';
  bool get isRejected => status.toUpperCase() == 'REJECTED';
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';
  bool get isCompleted => status.toUpperCase() == 'COMPLETED';
  bool get isExpired => status.toUpperCase() == 'EXPIRED';

  double? get discountPercentage {
    if (originalPrice != null && originalPrice! > 0) {
      final diff = originalPrice! - offeredPrice;
      if (diff > 0) {
        return (diff / originalPrice!) * 100;
      }
    }
    return null;
  }

  factory NegotiationModel.fromJson(Map<String, dynamic> json) {
    return NegotiationModel(
      id: json['id']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      postTitle: json['postTitle']?.toString() ?? json['title']?.toString() ?? 'Thiết bị gia dụng',
      buyerId: json['buyerId']?.toString(),
      buyerName: json['buyerName']?.toString() ??
          json['buyer']?['fullName']?.toString() ??
          json['buyer']?['name']?.toString() ??
          'Người mua',
      sellerId: json['sellerId']?.toString(),
      offeredPrice: (json['offeredPrice'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['originalPrice'] ?? json['postPrice'] as num?)?.toDouble(),
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
      createdAt: json['createdAt']?.toString(),
      expiredAt: json['expiredAt']?.toString(),
      productImageUrl: json['productImageUrl']?.toString() ?? json['thumbnailUrl']?.toString(),
    );
  }

  NegotiationModel copyWith({
    String? id,
    String? postId,
    String? postTitle,
    String? buyerId,
    String? buyerName,
    String? sellerId,
    double? offeredPrice,
    double? originalPrice,
    String? status,
    String? createdAt,
    String? expiredAt,
    String? productImageUrl,
  }) {
    return NegotiationModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      postTitle: postTitle ?? this.postTitle,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      sellerId: sellerId ?? this.sellerId,
      offeredPrice: offeredPrice ?? this.offeredPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiredAt: expiredAt ?? this.expiredAt,
      productImageUrl: productImageUrl ?? this.productImageUrl,
    );
  }
}
