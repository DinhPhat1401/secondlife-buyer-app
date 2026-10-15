import 'package:secondlife_app_buyer/core/network/api_client.dart';
import 'package:secondlife_app_buyer/core/network/api_endpoints.dart';
import '../domain/catalog_models.dart';

class CatalogRepository {
  final ApiClient client;

  CatalogRepository({required this.client});

  Future<List<CategoryModel>> getCategories() async {
    final response = await client.get<dynamic>(ApiEndpoints.categories);
    final data = response.data;
    List<dynamic> list = [];
    if (data is List) {
      list = data;
    } else if (data is Map && data['items'] is List) {
      list = data['items'] as List;
    } else if (data is Map && data['data'] is List) {
      list = data['data'] as List;
    }

    return list.map((c) => CategoryModel.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<List<ItemModel>> getItemsByCategory(String categoryId) async {
    final response = await client.get<dynamic>(ApiEndpoints.itemsByCategory(categoryId));
    final data = response.data;
    List<dynamic> list = [];
    if (data is List) {
      list = data;
    } else if (data is Map && data['items'] is List) {
      list = data['items'] as List;
    } else if (data is Map && data['data'] is List) {
      list = data['data'] as List;
    }

    return list.map((i) => ItemModel.fromJson(i as Map<String, dynamic>)).toList();
  }
}
