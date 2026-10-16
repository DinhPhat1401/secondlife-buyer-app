import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/error_handler.dart';
import '../domain/checkout_models.dart';

class CheckoutRepository {
  final ApiClient _client;

  CheckoutRepository(this._client);

  Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _client.post(
        ApiEndpoints.reverseGeocode,
        data: {
          'latitude': lat,
          'longitude': lng,
        },
      );
      final raw = response.data;
      final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
      if (data is Map && data.containsKey('address')) {
        return data['address'].toString();
      }
      return 'Vị trí đã chọn ($lat, $lng)';
    } catch (_) {
      return 'Vị trí đã chọn ($lat, $lng)';
    }
  }

  Future<ShippingQuoteModel> getShippingQuote({
    required String postId,
    required DeliveryAddressModel address,
    String? negotiationId,
    String? serviceType,
  }) async {
    try {
      final payload = <String, dynamic>{
        'postId': postId,
        'deliveryAddress': address.toJson(),
      };
      if (negotiationId != null && negotiationId.isNotEmpty) {
        payload['negotiationId'] = negotiationId;
      }
      if (serviceType != null && serviceType.isNotEmpty) {
        payload['serviceType'] = serviceType;
      }

      final response = await _client.post(
        ApiEndpoints.shippingQuotes,
        data: payload,
      );

      final raw = response.data;
      final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
      return ShippingQuoteModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    } catch (e) {
      throw AppException(message: 'Không thể tính phí vận chuyển từ hệ thống: $e');
    }
  }

  Future<Map<String, dynamic>> createOrder(CreateOrderRequestModel request) async {
    final response = await _client.post(
      '/api/v1/orders',
      data: request.toJson(),
    );
    final raw = response.data;
    final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
    return (data is Map<String, dynamic>) ? data : {'success': true};
  }

  Future<OrderBankPaymentResponse> getOrderBankPayment(String orderId) async {
    final response = await _client.get(
      ApiEndpoints.orderPayment(orderId),
    );
    final raw = response.data;
    final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
    return OrderBankPaymentResponse.fromJson(data as Map<String, dynamic>);
  }
}
