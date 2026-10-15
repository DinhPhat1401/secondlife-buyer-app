import 'package:intl/intl.dart';

class MarketplaceProductModel {
  final String id;
  final String postId;
  final String sellerId;
  final String sellerName;
  final String? sellerAvatar;
  final String? sellerAddress;
  final String? categoryId;
  final String? itemId;
  final String title;
  final String description;
  final String? itemCondition;
  final String? imageUrl;
  final List<String> imageUrls;
  final double price;
  final String status;
  final DateTime? publishedAt;

  MarketplaceProductModel({
    required this.id,
    required this.postId,
    required this.sellerId,
    required this.sellerName,
    this.sellerAvatar,
    this.sellerAddress,
    this.categoryId,
    this.itemId,
    required this.title,
    required this.description,
    this.itemCondition,
    this.imageUrl,
    this.imageUrls = const [],
    required this.price,
    required this.status,
    this.publishedAt,
  });

  factory MarketplaceProductModel.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    if (json['imageUrls'] is List) {
      images = (json['imageUrls'] as List).map((e) => e.toString()).toList();
    }
    final rawImg = json['imageUrl']?.toString();
    if (rawImg != null && rawImg.isNotEmpty && !images.contains(rawImg)) {
      images.insert(0, rawImg);
    }

    DateTime? pubDate;
    if (json['publishedAt'] != null) {
      try {
        pubDate = DateTime.parse(json['publishedAt'].toString());
      } catch (_) {}
    }

    return MarketplaceProductModel(
      id: (json['id'] ?? json['postId'] ?? '').toString(),
      postId: (json['postId'] ?? json['id'] ?? '').toString(),
      sellerId: (json['sellerId'] ?? '').toString(),
      sellerName: json['sellerName']?.toString() ?? 'Người bán SecondLife',
      sellerAvatar: json['sellerAvatar']?.toString(),
      sellerAddress: json['sellerAddress']?.toString(),
      categoryId: json['categoryId']?.toString(),
      itemId: json['itemId']?.toString(),
      title: json['title']?.toString() ?? 'Sản phẩm gia dụng',
      description: json['description']?.toString() ?? '',
      itemCondition: json['itemCondition']?.toString(),
      imageUrl: rawImg ?? (images.isNotEmpty ? images.first : null),
      imageUrls: images,
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      status: json['status']?.toString() ?? 'ACTIVE',
      publishedAt: pubDate,
    );
  }

  String get primaryImage {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl!;
    if (imageUrls.isNotEmpty) return imageUrls.first;
    return 'https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?w=500&auto=format&fit=crop&q=60';
  }

  String get formattedPrice {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return formatter.format(price);
  }

  String get conditionLabel {
    switch (itemCondition?.toUpperCase()) {
      case 'LIKE_NEW':
        return 'Như mới (99%)';
      case 'EXCELLENT':
        return 'Rất tốt (95%)';
      case 'GOOD':
        return 'Tốt (90%)';
      case 'FAIR':
        return 'Khá (80%)';
      case 'POOR':
        return 'Cũ (70%)';
      default:
        return itemCondition ?? 'Đã qua sử dụng';
    }
  }
}

class MarketplaceFilterModel {
  final String? categoryId;
  final String? itemId;
  final String? keyword;
  final double? minPrice;
  final double? maxPrice;
  final String? condition;
  final int page;
  final int size;

  const MarketplaceFilterModel({
    this.categoryId,
    this.itemId,
    this.keyword,
    this.minPrice,
    this.maxPrice,
    this.condition,
    this.page = 0,
    this.size = 20,
  });

  MarketplaceFilterModel copyWith({
    String? categoryId,
    String? itemId,
    String? keyword,
    double? minPrice,
    double? maxPrice,
    String? condition,
    int? page,
    int? size,
  }) {
    return MarketplaceFilterModel(
      categoryId: categoryId ?? this.categoryId,
      itemId: itemId ?? this.itemId,
      keyword: keyword ?? this.keyword,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      condition: condition ?? this.condition,
      page: page ?? this.page,
      size: size ?? this.size,
    );
  }
}
