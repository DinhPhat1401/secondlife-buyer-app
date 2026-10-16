import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/error_handler.dart';
import '../domain/marketplace_models.dart';

class MarketplaceRepository {
  final ApiClient _apiClient;

  MarketplaceRepository(this._apiClient);

  Future<List<MarketplaceProductModel>> getMarketplacePosts({
    String? categoryId,
    String? itemId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['categoryId'] = categoryId;
      }
      if (itemId != null && itemId.isNotEmpty) {
        queryParams['itemId'] = itemId;
      }

      final response = await _apiClient.get(
        ApiEndpoints.posts,
        queryParameters: queryParams,
      );

      final data = response.data;
      List<dynamic> items = [];

      if (data is Map<String, dynamic>) {
        final payload = data['data'] ?? data;
        if (payload is Map<String, dynamic> && payload['content'] is List) {
          items = payload['content'] as List;
        } else if (payload is List) {
          items = payload;
        }
      } else if (data is List) {
        items = data;
      }

      final posts = items
          .map((item) => MarketplaceProductModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return posts;
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    } catch (e) {
      throw AppException(message: 'Không thể tải danh sách tin đăng: $e');
    }
  }

  Future<MarketplaceProductModel> getPostDetail(String postId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.postDetail(postId));
      final data = response.data;
      Map<String, dynamic> itemMap = {};
      if (data is Map<String, dynamic>) {
        itemMap = (data['data'] is Map<String, dynamic>)
            ? (data['data'] as Map<String, dynamic>)
            : data;
      }
      return MarketplaceProductModel.fromJson(itemMap);
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    } catch (e) {
      throw AppException(message: 'Không thể tải chi tiết tin đăng: $e');
    }
  }
}
