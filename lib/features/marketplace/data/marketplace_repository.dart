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

      if (posts.isNotEmpty) {
        return posts;
      }

      return _getDemoMarketplacePosts();
    } on DioException catch (e) {
      // If network error, provide demo products so app is testable offline
      return _getDemoMarketplacePosts();
    } catch (e) {
      return _getDemoMarketplacePosts();
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
      final demoList = _getDemoMarketplacePosts();
      return demoList.firstWhere(
        (p) => p.id == postId,
        orElse: () => demoList.first,
      );
    }
  }

  List<MarketplaceProductModel> _getDemoMarketplacePosts() {
    return [
      MarketplaceProductModel(
        id: 'post-demo-1',
        postId: 'post-demo-1',
        sellerId: 'seller-1',
        sellerName: 'Nguyễn Văn Minh (Hà Nội)',
        sellerAddress: 'Cầu Giấy, Hà Nội',
        title: 'Nồi cơm điện tử cao tần Nagakawa 1.8L',
        description: 'Nồi cơm điện mới dùng 3 tháng, lòng nồi chống dính kim cương còn nguyên vẹn, nấu cơm dẻo ngon. Đầy đủ phụ kiện muôi, cốc đong và xửng hấp.',
        itemCondition: 'LIKE_NEW',
        price: 850000,
        status: 'ACTIVE',
        imageUrl: 'https://images.unsplash.com/photo-1544233726-9f1d2b27be8b?w=600&auto=format&fit=crop&q=80',
        imageUrls: [
          'https://images.unsplash.com/photo-1544233726-9f1d2b27be8b?w=600&auto=format&fit=crop&q=80',
          'https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?w=600&auto=format&fit=crop&q=80'
        ],
        publishedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      MarketplaceProductModel(
        id: 'post-demo-2',
        postId: 'post-demo-2',
        sellerId: 'seller-2',
        sellerName: 'Trần Thị Thu (Đà Nẵng)',
        sellerAddress: 'Hải Châu, Đà Nẵng',
        title: 'Nồi chiên không dầu Philips HD9650 XXL',
        description: 'Dung tích lớn 1.4kg chiên gà nguyên con, công nghệ Twin TurboStar loại bỏ dầu mỡ thừa. Mới 95% do chuyển nhà thanh lý gấp.',
        itemCondition: 'EXCELLENT',
        price: 2400000,
        status: 'ACTIVE',
        imageUrl: 'https://images.unsplash.com/photo-1585515320310-259814833e62?w=600&auto=format&fit=crop&q=80',
        imageUrls: [
          'https://images.unsplash.com/photo-1585515320310-259814833e62?w=600&auto=format&fit=crop&q=80'
        ],
        publishedAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      MarketplaceProductModel(
        id: 'post-demo-3',
        postId: 'post-demo-3',
        sellerId: 'seller-3',
        sellerName: 'Lê Hoàng Nam (TP.HCM)',
        sellerAddress: 'Bình Thạnh, TP. Hồ Chí Minh',
        title: 'Máy hút bụi không dây Dyson V11 Fluffy',
        description: 'Máy hút bụi pin khỏe 45 phút, đầu hút con lăn mềm làm sạch sàn gỗ cực êm. Kèm đủ 5 đầu hút chuyên dụng.',
        itemCondition: 'GOOD',
        price: 5200000,
        status: 'ACTIVE',
        imageUrl: 'https://images.unsplash.com/photo-1558317374-067fb5f30001?w=600&auto=format&fit=crop&q=80',
        imageUrls: [
          'https://images.unsplash.com/photo-1558317374-067fb5f30001?w=600&auto=format&fit=crop&q=80'
        ],
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      MarketplaceProductModel(
        id: 'post-demo-4',
        postId: 'post-demo-4',
        sellerId: 'seller-4',
        sellerName: 'Phạm Thuỳ Dương (TP.HCM)',
        sellerAddress: 'Quận 7, TP. Hồ Chí Minh',
        title: 'Lò vi sóng có nướng Sharp 23L R-G302VN-S',
        description: 'Lò vi sóng hoạt động hoàn hảo, bảng điều khiển tiếng Việt dễ dùng. Mâm xoay thủy tinh cường lực sạch sẽ.',
        itemCondition: 'LIKE_NEW',
        price: 1150000,
        status: 'ACTIVE',
        imageUrl: 'https://images.unsplash.com/photo-1574269909862-7e1d70bb8078?w=600&auto=format&fit=crop&q=80',
        imageUrls: [
          'https://images.unsplash.com/photo-1574269909862-7e1d70bb8078?w=600&auto=format&fit=crop&q=80'
        ],
        publishedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
}
