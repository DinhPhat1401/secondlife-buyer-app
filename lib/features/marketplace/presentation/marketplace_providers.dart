import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/marketplace_repository.dart';
import '../domain/marketplace_models.dart';

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MarketplaceRepository(apiClient);
});

class MarketplaceFilterNotifier extends Notifier<MarketplaceFilterModel> {
  @override
  MarketplaceFilterModel build() => const MarketplaceFilterModel();

  void updateFilter(MarketplaceFilterModel Function(MarketplaceFilterModel) fn) {
    state = fn(state);
  }
}

final marketplaceFilterProvider =
    NotifierProvider<MarketplaceFilterNotifier, MarketplaceFilterModel>(MarketplaceFilterNotifier.new);

final marketplacePostsProvider = FutureProvider<List<MarketplaceProductModel>>((ref) async {
  final repository = ref.watch(marketplaceRepositoryProvider);
  final filter = ref.watch(marketplaceFilterProvider);
  return repository.getMarketplacePosts(
    categoryId: filter.categoryId,
    itemId: filter.itemId,
    page: filter.page,
    size: filter.size,
  );
});

final postDetailProvider = FutureProvider.family<MarketplaceProductModel, String>((ref, postId) async {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return repository.getPostDetail(postId);
});
