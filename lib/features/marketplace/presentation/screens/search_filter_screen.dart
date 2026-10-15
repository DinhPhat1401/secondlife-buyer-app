import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../catalog/presentation/catalog_providers.dart';
import '../marketplace_providers.dart';

class SearchFilterScreen extends ConsumerStatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  ConsumerState<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends ConsumerState<SearchFilterScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  int _selectedPriceRange = 0; // 0: All, 1: <1M, 2: 1-3M, 3: 3-5M, 4: >5M

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    double? minPrice;
    double? maxPrice;

    if (_selectedPriceRange == 1) {
      maxPrice = 1000000;
    } else if (_selectedPriceRange == 2) {
      minPrice = 1000000;
      maxPrice = 3000000;
    } else if (_selectedPriceRange == 3) {
      minPrice = 3000000;
      maxPrice = 5000000;
    } else if (_selectedPriceRange == 4) {
      minPrice = 5000000;
    }

    ref.read(marketplaceFilterProvider.notifier).updateFilter(
          (s) => s.copyWith(
            keyword: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
            categoryId: _selectedCategory,
            minPrice: minPrice,
            maxPrice: maxPrice,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
        final postsAsync = ref.watch(marketplacePostsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm sản phẩm...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _applyFilters();
                    },
                  )
                : null,
          ),
          onChanged: (_) => _applyFilters(),
        ),
      ),
      body: Column(
        children: [
          // Filter options bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPriceChip('Tất cả giá', 0),
                  const SizedBox(width: 8),
                  _buildPriceChip('< 1 triệu', 1),
                  const SizedBox(width: 8),
                  _buildPriceChip('1 - 3 triệu', 2),
                  const SizedBox(width: 8),
                  _buildPriceChip('3 - 5 triệu', 3),
                  const SizedBox(width: 8),
                  _buildPriceChip('> 5 triệu', 4),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Search results
          Expanded(
            child: postsAsync.when(
              data: (posts) {
                final keyword = _searchController.text.trim().toLowerCase();
                final filtered = posts.where((p) {
                  if (keyword.isNotEmpty && !p.title.toLowerCase().contains(keyword) && !p.description.toLowerCase().contains(keyword)) {
                    return false;
                  }
                  if (_selectedCategory != null && p.categoryId != _selectedCategory) {
                    return false;
                  }
                  if (_selectedPriceRange == 1 && p.price >= 1000000) return false;
                  if (_selectedPriceRange == 2 && (p.price < 1000000 || p.price > 3000000)) return false;
                  if (_selectedPriceRange == 3 && (p.price < 3000000 || p.price > 5000000)) return false;
                  if (_selectedPriceRange == 4 && p.price <= 5000000) return false;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Không tìm thấy sản phẩm phù hợp',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return GestureDetector(
                      onTap: () => context.push('/products/${item.id}'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.primaryImage,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.formattedPrice,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.sellerAddress ?? item.sellerName,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceChip(String label, int value) {
    final isSelected = _selectedPriceRange == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPriceRange = value);
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
