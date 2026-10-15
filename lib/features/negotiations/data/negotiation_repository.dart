import '../../auth/presentation/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/negotiation_model.dart';

final negotiationRepositoryProvider = Provider<NegotiationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NegotiationRepository(apiClient);
});

class NegotiationRepository {
  final ApiClient _client;

  NegotiationRepository(this._client);

  Future<NegotiationModel> createNegotiation({
    required String postId,
    required double offeredPrice,
  }) async {
    final response = await _client.post(
      '/api/v1/negotiations',
      data: {
        'postId': postId,
        'offeredPrice': offeredPrice,
      },
    );
    final raw = response.data;
    final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
    return NegotiationModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<NegotiationModel>> getBuyerNegotiations({int page = 0, int size = 20}) async {
    final response = await _client.get('/api/v1/negotiations/buyer?page=$page&size=$size');
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

    return list.map((item) => NegotiationModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<NegotiationModel> cancelNegotiation(String negotiationId) async {
    final response = await _client.put('/api/v1/negotiations/$negotiationId/cancel');
    final raw = response.data;
    final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
    return NegotiationModel.fromJson(data as Map<String, dynamic>);
  }
}
