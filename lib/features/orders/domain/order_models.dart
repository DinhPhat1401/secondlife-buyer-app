import 'package:intl/intl.dart';

enum OrderStatus {
  pending('PENDING', 'Chờ xác nhận'),
  confirmed('CONFIRMED', 'Đã xác nhận'),
  shipping('SHIPPING', 'Đang vận chuyển'),
  delivered('DELIVERED', 'Đã nhận hàng'),
  cancelled('CANCELLED', 'Đã hủy'),
  unknown('UNKNOWN', 'Không xác định');

  final String code;
  final String label;

  const OrderStatus(this.code, this.label);

  static OrderStatus fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'PENDING':
        return OrderStatus.pending;
      case 'CONFIRMED':
        return OrderStatus.confirmed;
      case 'SHIPPING':
      case 'SHIPPED':
        return OrderStatus.shipping;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'CANCELLED':
      case 'CANCELED':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.unknown;
    }
  }
}

class BuyerOrderModel {
  final String id;
  final String? orderNumber;
  final String? postId;
  final String postTitle;
  final String? postThumbnail;
  final String sellerId;
  final String sellerName;
  final String? sellerPhone;
  final String deliveryAddress;
  final double itemPrice;
  final double shippingFee;
  final double totalAmount;
  final OrderStatus status;
  final bool hasInspection;
  final String? shipmentId;
  final String? createdAt;
  final String? updatedAt;

  const BuyerOrderModel({
    required this.id,
    this.orderNumber,
    this.postId,
    required this.postTitle,
    this.postThumbnail,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhone,
    required this.deliveryAddress,
    required this.itemPrice,
    this.shippingFee = 0.0,
    required this.totalAmount,
    required this.status,
    this.hasInspection = false,
    this.shipmentId,
    this.createdAt,
    this.updatedAt,
  });

  factory BuyerOrderModel.fromJson(Map<String, dynamic> json) {
    final itemPrice = (json['itemPrice'] as num?)?.toDouble() ?? (json['price'] as num?)?.toDouble() ?? 0.0;
    final shippingFee = (json['shippingFee'] as num?)?.toDouble() ?? 0.0;
    final total = (json['totalAmount'] as num?)?.toDouble() ?? (itemPrice + shippingFee);

    String addr = '';
    if (json['deliveryAddress'] is Map) {
      final m = json['deliveryAddress'] as Map;
      addr = m['address'] ?? m['fullAddress'] ?? m['detailAddress'] ?? '';
    } else if (json['deliveryAddress'] != null) {
      addr = json['deliveryAddress'].toString();
    }

    return BuyerOrderModel(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'],
      postId: json['postId'],
      postTitle: json['postTitle'] ?? json['productTitle'] ?? json['title'] ?? 'Đơn hàng đồ gia dụng',
      postThumbnail: json['postThumbnail'] ?? json['thumbnail'] ?? json['imageUrl'],
      sellerId: json['sellerId'] ?? '',
      sellerName: json['sellerName'] ?? 'Người bán SecondLife',
      sellerPhone: json['sellerPhone'],
      deliveryAddress: addr,
      itemPrice: itemPrice,
      shippingFee: shippingFee,
      totalAmount: total,
      status: OrderStatus.fromString(json['status'] ?? json['orderStatus']),
      hasInspection: json['hasInspection'] == true,
      shipmentId: json['shipmentId'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  bool get canConfirmDelivered => status == OrderStatus.shipping;
  bool get canCancel => status == OrderStatus.pending;

  String get formattedTotal {
    final f = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return f.format(totalAmount);
  }

  String get formattedItemPrice {
    final f = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return f.format(itemPrice);
  }

  String get formattedShippingFee {
    final f = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return f.format(shippingFee);
  }
}
