import 'package:intl/intl.dart';

enum OrderStatus {
  pending('PENDING', 'Chờ xác nhận'),
  confirmed('CONFIRMED', 'Đã xác nhận'),
  pendingFinalPayment('PENDING_FINAL_PAYMENT', 'Chờ thanh toán tiền hàng (6h)'),
  shipping('SHIPPING', 'Đang vận chuyển'),
  delivered('DELIVERED', 'Đã nhận hàng'),
  cancelled('CANCELLED', 'Đã hủy'),
  expired('EXPIRED', 'Hết hạn (Bồi thường cọc)'),
  unknown('UNKNOWN', 'Không xác định');

  final String code;
  final String label;

  const OrderStatus(this.code, this.label);

  static OrderStatus fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'PENDING':
      case 'PAYMENT_PENDING':
        return OrderStatus.pending;
      case 'CONFIRMED':
      case 'ESCROWED':
        return OrderStatus.confirmed;
      case 'PENDING_FINAL_PAYMENT':
      case 'INSPECTION_PASSED':
        return OrderStatus.pendingFinalPayment;
      case 'SHIPPING':
      case 'SHIPPED':
      case 'DELIVERING_TO_BUYER':
        return OrderStatus.shipping;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'EXPIRED':
        return OrderStatus.expired;
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
  final DateTime? finalPaymentDeadline; // [MỚI] Hạn chót 6 giờ thanh toán sau khi kiểm định Đạt
  final DateTime? finalPaymentPaidAt;
  final String? inspectionStatus; // PASSED, FAILED
  final String? tamperSealId;
  final String? videoProofUrl;
  final double inspectionFeeBuyerShare;

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
    this.finalPaymentDeadline,
    this.finalPaymentPaidAt,
    this.inspectionStatus,
    this.tamperSealId,
    this.videoProofUrl,
    this.inspectionFeeBuyerShare = 0.0,
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

    DateTime? deadline;
    if (json['finalPaymentDeadline'] != null) {
      deadline = DateTime.tryParse(json['finalPaymentDeadline'].toString());
    }

    DateTime? paidTime;
    if (json['finalPaymentPaidAt'] != null) {
      paidTime = DateTime.tryParse(json['finalPaymentPaidAt'].toString());
    }

    final feeShare = (json['buyerInspectionFeeShare'] as num?)?.toDouble() ??
        (json['inspectionFeeBuyerShare'] as num?)?.toDouble() ??
        0.0;

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
      finalPaymentDeadline: deadline,
      finalPaymentPaidAt: paidTime,
      inspectionStatus: json['inspectionStatus']?.toString(),
      tamperSealId: json['tamperSealId']?.toString(),
      videoProofUrl: json['videoProofUrl']?.toString(),
      inspectionFeeBuyerShare: feeShare,
    );
  }

  bool get canConfirmDelivered => status == OrderStatus.shipping;
  bool get canCancel => status == OrderStatus.pending;
  bool get isPendingFinalPayment =>
      status == OrderStatus.pendingFinalPayment ||
      (hasInspection && inspectionStatus == 'PASSED' && finalPaymentPaidAt == null);

  bool get isExpiredOrForfeited =>
      status == OrderStatus.expired ||
      (status == OrderStatus.cancelled && finalPaymentDeadline != null && finalPaymentPaidAt == null);

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
