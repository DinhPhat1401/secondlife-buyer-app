import '../../../shipments/presentation/screens/shipment_tracking_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shipments/presentation/widgets/tamper_seal_lookup_sheet.dart';
import '../../domain/order_models.dart';
import '../buyer_order_providers.dart';

class BuyerOrdersScreen extends ConsumerStatefulWidget {
  const BuyerOrdersScreen({super.key});

  @override
  ConsumerState<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends ConsumerState<BuyerOrdersScreen> {
  OrderStatus? _selectedFilter;

  void _showConfirmDeliveryDialog(BuildContext context, BuyerOrderModel order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified, color: Colors.green),
            SizedBox(width: 8),
            Text('Xác Nhận Đã Nhận Hàng?'),
          ],
        ),
        content: const Text(
          'Vui lòng chỉ xác nhận khi bạn đã kiểm tra sản phẩm thực tế hoạt động tốt.\n\nSau khi xác nhận, tiền thanh toán trong Escrow sẽ được giải ngân ngay cho người bán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kiểm tra thêm'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              final ok = await ref.read(buyerOrdersNotifierProvider.notifier).confirmDelivery(order.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Đã hoàn tất đơn hàng và giải ngân cho người bán!' : 'Lỗi cập nhật. Vui lòng thử lại!'),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xác nhận nhận hàng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(buyerOrdersNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F5),
      appBar: AppBar(
        title: const Text('Đơn Mua Của Tôi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Filter status chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip('Tất cả', null),
                  const SizedBox(width: 8),
                  _buildStatusChip('Chờ xác nhận', OrderStatus.pending),
                  const SizedBox(width: 8),
                  _buildStatusChip('Đang vận chuyển', OrderStatus.shipping),
                  const SizedBox(width: 8),
                  _buildStatusChip('Đã nhận hàng', OrderStatus.delivered),
                  const SizedBox(width: 8),
                  _buildStatusChip('Đã hủy', OrderStatus.cancelled),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await ref.read(buyerOrdersNotifierProvider.notifier).fetchOrders();
              },
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : state.filteredOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'Bạn chưa có đơn hàng nào trong mục này',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.filteredOrders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final order = state.filteredOrders[index];
                            return _buildOrderCard(context, order);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, OrderStatus? status) {
    final isSelected = _selectedFilter == status;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = status);
        ref.read(buyerOrdersNotifierProvider.notifier).setFilter(status);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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

  Widget _buildOrderCard(BuildContext context, BuyerOrderModel order) {
    Color statusBg = Colors.grey.shade100;
    Color statusColor = Colors.grey.shade800;

    switch (order.status) {
      case OrderStatus.pending:
        statusBg = Colors.amber.shade50;
        statusColor = Colors.amber.shade900;
        break;
      case OrderStatus.confirmed:
        statusBg = Colors.blue.shade50;
        statusColor = Colors.blue.shade800;
        break;
      case OrderStatus.shipping:
        statusBg = Colors.orange.shade50;
        statusColor = Colors.orange.shade900;
        break;
      case OrderStatus.delivered:
        statusBg = Colors.green.shade50;
        statusColor = Colors.green.shade800;
        break;
      case OrderStatus.cancelled:
        statusBg = Colors.red.shade50;
        statusColor = Colors.red.shade800;
        break;
      default:
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Row(
            children: [
              Text(
                order.orderNumber ?? 'Đơn #${order.id.substring(0, 8)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.status.label,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const Divider(height: 16),

          // Product item details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: order.postThumbnail != null
                    ? CachedNetworkImage(
                        imageUrl: order.postThumbnail!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      )
                    : Container(width: 64, height: 64, color: Colors.grey.shade200),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.postTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Người bán: ${order.sellerName}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.formattedTotal,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 16),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (order.hasInspection)
                OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code, size: 16),
                  label: const Text('Tem niêm phong', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => TamperSealLookupSheet(repository: ref.read(shipmentRepositoryProvider)),
                    );
                  },
                ),
              const SizedBox(width: 8),

              if (order.status == OrderStatus.shipping) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.navigation_outlined, size: 16, color: Colors.orange),
                  label: const Text('Theo dõi', style: TextStyle(fontSize: 12, color: Colors.orange)),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    context.push('/shipments/tracking/${order.shipmentId ?? order.id}');
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showConfirmDeliveryDialog(context, order),
                  child: const Text('Đã nhận hàng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],

              if (order.status == OrderStatus.pending)
                TextButton(
                  onPressed: () async {
                    final ok = await ref.read(buyerOrdersNotifierProvider.notifier).cancelOrder(order.id, reason: 'Người mua đổi ý');
                    if (context.mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã hủy đơn hàng thành công')),
                      );
                    }
                  },
                  child: const Text('Hủy đơn', style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
