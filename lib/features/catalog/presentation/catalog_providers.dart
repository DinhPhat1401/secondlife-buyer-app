import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_buyer/features/auth/presentation/auth_providers.dart';
import '../data/catalog_repository.dart';
import '../domain/catalog_models.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return CatalogRepository(client: client);
});

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  try {
    return await repo.getCategories();
  } catch (_) {
    return [];
  }
});

final itemsByCategoryProvider =
    FutureProvider.family<List<ItemModel>, String>((ref, categoryId) async {
  if (categoryId.isEmpty) return [];
  final repo = ref.watch(catalogRepositoryProvider);
  try {
    return await repo.getItemsByCategory(categoryId);
  } catch (_) {
    return [];
  }
});
