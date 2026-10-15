import 'package:intl/intl.dart';

class DeliveryAddressModel {
  final String name;
  final String phone;
  final double latitude;
  final double longitude;
  final String address;

  DeliveryAddressModel({
    required this.name,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };

  factory DeliveryAddressModel.fromJson(Map<String, dynamic> json) {
    return DeliveryAddressModel(
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : 21.0285,
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : 105.8542,
      address: json['address']?.toString() ?? '',
    );
  }
}

class ShippingQuoteModel {
  final String quoteId;
  final String? leg;
  final double shippingFee;
  final double productPrice;
  final double totalPayable;
  final double? insuranceValue;
  final DateTime? expiresAt;
  final String? serviceType;
  final String? provider;
  final DateTime? expectedDeliveryTime;

  ShippingQuoteModel({
    required this.quoteId,
    this.leg,
    required this.shippingFee,
    required this.productPrice,
    required this.totalPayable,
    this.insuranceValue,
    this.expiresAt,
    this.serviceType,
    this.provider,
    this.expectedDeliveryTime,
  });

  factory ShippingQuoteModel.fromJson(Map<String, dynamic> json) {
    DateTime? expAt;
    if (json['expiresAt'] != null) {
      try {
        expAt = DateTime.parse(json['expiresAt'].toString());
      } catch (_) {}
    }

    DateTime? deliveryTime;
    if (json['expectedDeliveryTime'] != null) {
      try {
        deliveryTime = DateTime.parse(json['expectedDeliveryTime'].toString());
      } catch (_) {}
    }

    return ShippingQuoteModel(
      quoteId: (json['quoteId'] ?? '').toString(),
      leg: json['leg']?.toString(),
      shippingFee: (json['shippingFee'] is num) ? (json['shippingFee'] as num).toDouble() : 0.0,
      productPrice: (json['productPrice'] is num) ? (json['productPrice'] as num).toDouble() : 0.0,
      totalPayable: (json['totalPayable'] is num) ? (json['totalPayable'] as num).toDouble() : 0.0,
      insuranceValue: (json['insuranceValue'] is num) ? (json['insuranceValue'] as num).toDouble() : null,
      expiresAt: expAt,
      serviceType: json['serviceType']?.toString(),
      provider: json['provider']?.toString() ?? 'Lalamove',
      expectedDeliveryTime: deliveryTime,
    );
  }

  String get formattedShippingFee {
    final f = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return f.format(shippingFee);
  }

  String get formattedProductPrice {
    final f = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return f.format(productPrice);
  }

  String get formattedTotalPayable {
    final f = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return f.format(totalPayable);
  }
}

class CreateOrderRequestModel {
  final String postId;
  final String shippingQuoteId;
  final String requestId;
  final String? negotiationId;

  CreateOrderRequestModel({
    required this.postId,
    required this.shippingQuoteId,
    required this.requestId,
    this.negotiationId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'postId': postId,
      'shippingQuoteId': shippingQuoteId,
      'requestId': requestId,
    };
    if (negotiationId != null && negotiationId!.isNotEmpty) {
      map['negotiationId'] = negotiationId;
    }
    return map;
  }
}
