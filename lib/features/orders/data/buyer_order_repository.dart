import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/error_handler.dart';
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

      return list.map((item) => BuyerOrderModel.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    } catch (e) {
      throw AppException(message: 'Không thể tải danh sách đơn hàng: $e');
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

  Future<bool> confirmFinalPurchase(String orderId) async {
    try {
      await _client.post('/api/v1/inspection/orders/$orderId/confirm-purchase');
      return true;
    } catch (_) {
      return false;
    }
  }
}
