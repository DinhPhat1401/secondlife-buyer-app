import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../negotiations/presentation/widgets/make_offer_dialog.dart';
import '../../domain/marketplace_models.dart';
import '../marketplace_providers.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const ProductDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(postDetailProvider(widget.postId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Chi Tiết Sản Phẩm'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép liên kết sản phẩm')),
              );
            },
          ),
        ],
      ),
      body: productAsync.when(
        data: (product) => _buildContent(context, product),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Lỗi tải sản phẩm: $e'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(postDetailProvider(widget.postId)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MarketplaceProductModel product) {
    final images = product.imageUrls.isNotEmpty ? product.imageUrls : [product.primaryImage];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image gallery
                Stack(
                  children: [
                    SizedBox(
                      height: 320,
                      child: PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
                        itemBuilder: (context, idx) {
                          return CachedNetworkImage(
                            imageUrl: images[idx],
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: Colors.grey.shade200),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                    if (images.length > 1)
                      Positioned(
                        bottom: 12,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_currentImageIndex + 1}/${images.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),

                // Price & Title Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            product.formattedPrice,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Text(
                              product.conditionLabel,
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Escrow protection banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFDCFCE7)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_outlined, color: Color(0xFF16A34A), size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Bảo Vệ Thanh Toán Escrow 48H',
                                    style: TextStyle(
                                      color: Color(0xFF166534),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'Tiền chỉ được giải ngân cho người bán sau khi bạn nhận và kiểm tra máy.',
                                    style: TextStyle(color: Colors.green.shade700, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 8, color: Color(0xFFF3F4F6)),

                // Seller Card
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        backgroundImage: product.sellerAvatar != null ? NetworkImage(product.sellerAvatar!) : null,
                        child: product.sellerAvatar == null
                            ? const Icon(Icons.person, color: AppColors.primary)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.sellerName,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              product.sellerAddress ?? 'Hà Nội, Việt Nam',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        onPressed: () {
                          // Navigate to Chat
                          context.push('/chat?postId=${product.id}');
                        },
                        child: const Text('Chat ngay', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 8, color: Color(0xFFF3F4F6)),

                // Description
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mô Tả Sản Phẩm',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        product.description.isNotEmpty
                            ? product.description
                            : 'Người bán chưa cung cấp mô tả chi tiết cho sản phẩm này.',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom CTA Sticky Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Chat button
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                  onPressed: () {
                    context.push('/chat?postId=${product.id}');
                  },
                ),
                const SizedBox(width: 8),

                // Make Offer button
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => MakeOfferDialog(
                          postId: product.id,
                          productTitle: product.title,
                          originalPrice: product.price,
                        ),
                      );
                    },
                    child: const Text(
                      'Trả Giá',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Buy Now button
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      context.push('/checkout?postId=${product.id}');
                    },
                    child: const Text(
                      'Mua Ngay',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
