import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/order_models.dart';

class BuyerOrderRepository {
  final ApiClient _client;

  BuyerOrderRepository(this._client);

  Future<List<BuyerOrderModel>> getBuyerOrders({int page = 0, int size = 20}) async {
    try {
      final response = await _client.get('/api/v1/orders/buyer?page=$page&size=$size');
      final raw = response.data;
      final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;

      List list = [];
      if (data is Map && data.containsKey('content') && data['content'] is List) {
        list = data['content'] as List;
      } else if (data is Map && data.containsKey('items') && data['items'] is List) {
        list = data['items'] as List;
      } else if (data is List) {
        list = data;
      }

      final orders = list.map((item) => BuyerOrderModel.fromJson(item as Map<String, dynamic>)).toList();
      if (orders.isNotEmpty) return orders;
      return _getDemoBuyerOrders();
    } on DioException {
      return _getDemoBuyerOrders();
    } catch (_) {
      return _getDemoBuyerOrders();
    }
  }

  Future<BuyerOrderModel> confirmDelivery(String orderId) async {
    final response = await _client.put('/api/v1/orders/$orderId/delivered');
    final raw = response.data;
    final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
    return BuyerOrderModel.fromJson(data as Map<String, dynamic>);
  }

  Future<BuyerOrderModel> cancelOrder(String orderId, {String? reason}) async {
    final response = await _client.put(
      '/api/v1/orders/$orderId/cancel',
      data: reason != null ? {'reason': reason} : null,
    );
    final raw = response.data;
    final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
    return BuyerOrderModel.fromJson(data as Map<String, dynamic>);
  }

  List<BuyerOrderModel> _getDemoBuyerOrders() {
    return [
      BuyerOrderModel(
        id: 'order-demo-1',
        orderNumber: 'ORD-20261015-8821',
        postId: 'post-demo-1',
        postTitle: 'Nồi cơm điện tử cao tần Nagakawa 1.8L',
        postThumbnail: 'https://images.unsplash.com/photo-1544233726-9f1d2b27be8b?w=600&auto=format&fit=crop&q=80',
        sellerId: 'seller-1',
        sellerName: 'Nguyễn Văn Minh (Hà Nội)',
        sellerPhone: '0912345678',
        deliveryAddress: 'Số 15 Lê Văn Lương, Cầu Giấy, Hà Nội',
        itemPrice: 850000,
        shippingFee: 35000,
        totalAmount: 885000,
        status: OrderStatus.shipping,
        hasInspection: true,
        shipmentId: 'shipment-demo-1',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
      ),
      BuyerOrderModel(
        id: 'order-demo-2',
        orderNumber: 'ORD-20261014-4190',
        postId: 'post-demo-4',
        postTitle: 'Lò vi sóng có nướng Sharp 23L R-G302VN-S',
        postThumbnail: 'https://images.unsplash.com/photo-1574269909862-7e1d70bb8078?w=600&auto=format&fit=crop&q=80',
        sellerId: 'seller-4',
        sellerName: 'Phạm Thuỳ Dương (TP.HCM)',
        deliveryAddress: '280 An Dương Vương, Quận 5, TP. Hồ Chí Minh',
        itemPrice: 1150000,
        shippingFee: 45000,
        totalAmount: 1195000,
        status: OrderStatus.delivered,
        hasInspection: false,
        createdAt: DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      ),
    ];
  }
}
