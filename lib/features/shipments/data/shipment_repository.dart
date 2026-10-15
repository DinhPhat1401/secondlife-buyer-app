import 'package:secondlife_app_buyer/core/network/api_client.dart';
import 'package:secondlife_app_buyer/core/network/api_endpoints.dart';
import 'package:secondlife_app_buyer/core/network/error_handler.dart';
import '../domain/shipment_models.dart';
import '../domain/tamper_seal_model.dart';

class ShipmentRepository {
  final ApiClient client;

  ShipmentRepository({required this.client});

  Future<ShipmentTrackingModel> getTracking(String shipmentId) async {
    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.shipmentTracking(shipmentId),
    );
    if (response.data == null) {
      throw AppException(message: 'KhÃ´ng tÃ¬m tháº¥y thÃ´ng tin váº­n chuyá»ƒn cho Ä‘Æ¡n $shipmentId');
    }
    final payload = response.data!['data'] ?? response.data!;
    return ShipmentTrackingModel.fromJson(payload as Map<String, dynamic>);
  }

  Future<ShipmentTrackingModel> syncTracking(String shipmentId) async {
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.shipmentSync(shipmentId),
    );
    if (response.data == null) {
      throw AppException(message: 'Äá»“ng bá»™ hÃ nh trÃ¬nh váº­n chuyá»ƒn tháº¥t báº¡i');
    }
    final payload = response.data!['data'] ?? response.data!;
    return ShipmentTrackingModel.fromJson(payload as Map<String, dynamic>);
  }

  Future<TamperSealModel?> verifyTamperSeal(String sealId) async {
    final cleanId = sealId.trim();
    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.inspectionSealLookup(cleanId),
    );
    if (response.data == null) {
      throw AppException(message: 'KhÃ´ng tÃ¬m tháº¥y thÃ´ng tin tem niÃªm phong $cleanId');
    }
    final data = response.data!['data'] ?? response.data!;
    return TamperSealModel.fromJson(data as Map<String, dynamic>);
  }
}
