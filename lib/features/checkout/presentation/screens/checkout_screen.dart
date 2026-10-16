import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../marketplace/presentation/marketplace_providers.dart';
import '../../../wallet/presentation/widgets/vietqr_deposit_sheet.dart';
import '../../../wallet/presentation/wallet_providers.dart';
import '../../domain/checkout_models.dart';
import '../checkout_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String postId;
  final String? negotiationId;

  const CheckoutScreen({
    super.key,
    required this.postId,
    this.negotiationId,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _requireInspection = false;
  String _selectedPaymentMethod = 'WALLET'; // 'WALLET' hoặc 'BANK_TRANSFER'

  void _showEditAddressDialog(BuildContext context, DeliveryAddressModel current) {
    final nameCtrl = TextEditingController(text: current.name);
    final phoneCtrl = TextEditingController(text: current.phone);
    final addrCtrl = TextEditingController(text: current.address);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Địa Chỉ Nhận Hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Họ tên người nhận'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: addrCtrl,
              decoration: const InputDecoration(labelText: 'Địa chỉ chi tiết'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(selectedDeliveryAddressProvider.notifier).setAddress(DeliveryAddressModel(
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                latitude: current.latitude,
                longitude: current.longitude,
                address: addrCtrl.text.trim(),
              ));
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(postDetailProvider(widget.postId));
    final address = ref.watch(selectedDeliveryAddressProvider);
    final quoteAsync = ref.watch(shippingQuoteProvider((postId: widget.postId, negotiationId: widget.negotiationId)));
    final walletState = ref.watch(sellerWalletNotifierProvider); final walletBalance = walletState.wallet?.balance ?? 0.0;
    final checkoutState = ref.watch(checkoutNotifierProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F5),
      appBar: AppBar(
        title: const Text('Xác Nhận Đơn Hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: productAsync.when(
        data: (product) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Delivery Address Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Địa chỉ nhận hàng (Lalamove)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _showEditAddressDialog(context, address),
                            child: const Text('Thay đổi', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${address.name} | ${address.phone}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address.address,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Product Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: product.primaryImage,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.formattedPrice,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Người bán: ${product.sellerName}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Optional Inspection Service Add-on
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_outlined, color: Color(0xFF16A34A), size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Dịch vụ kiểm định kỹ thuật (Tùy chọn)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          Switch(
                            value: _requireInspection,
                            activeColor: AppColors.primary,
                            onChanged: (val) => setState(() => _requireInspection = val),
                          ),
                        ],
                      ),
                      if (_requireInspection) ...[
                        const Divider(height: 16),
                        Text(
                          'Kỹ thuật viên sẽ mở máy kiểm tra bo mạch, tem linh kiện và quay video test trước khi bạn nhận hàng. Phí kiểm định: 50.000₫.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Payment Breakdown & Shipping Quote
                quoteAsync.when(
                  data: (quote) {
                    final inspectionFee = _requireInspection ? 50000.0 : 0.0;
                    final total = quote.productPrice + quote.shippingFee + inspectionFee;
                    final hasEnoughBalance = walletBalance >= total;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Chi Tiết Thanh Toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tiền sản phẩm', style: TextStyle(fontSize: 13, color: Colors.black87)),
                                  Text(currencyFormatter.format(quote.productPrice), style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Text('Cước vận chuyển ', style: TextStyle(fontSize: 13, color: Colors.black87)),
                                      Text('(${quote.provider})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                  Text(currencyFormatter.format(quote.shippingFee), style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                              if (_requireInspection) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Phí kiểm định máy', style: TextStyle(fontSize: 13, color: Colors.black87)),
                                    Text(currencyFormatter.format(inspectionFee), style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ],
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tổng thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text(
                                    currencyFormatter.format(total),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const SizedBox(height: 12),

                        // Payment Methods Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Phương Thức Thanh Toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 12),

                              // Option 1: Direct Bank Transfer via SePay
                              InkWell(
                                onTap: () => setState(() => _selectedPaymentMethod = 'BANK_TRANSFER'),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _selectedPaymentMethod == 'BANK_TRANSFER'
                                        ? AppColors.primary.withValues(alpha: 0.05)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _selectedPaymentMethod == 'BANK_TRANSFER'
                                          ? AppColors.primary
                                          : Colors.grey.shade300,
                                      width: _selectedPaymentMethod == 'BANK_TRANSFER' ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Radio<String>(
                                        value: 'BANK_TRANSFER',
                                        groupValue: _selectedPaymentMethod,
                                        activeColor: AppColors.primary,
                                        onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 20),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  'Chuyển khoản VietQR SePay',
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade50,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'Khuyên dùng',
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Quét mã VietQR qua 40+ app ngân hàng, không mất phí, xác nhận tức thì trong 15 phút.',
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Option 2: SecondLife Escrow Wallet
                              InkWell(
                                onTap: () => setState(() => _selectedPaymentMethod = 'WALLET'),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _selectedPaymentMethod == 'WALLET'
                                        ? AppColors.primary.withValues(alpha: 0.05)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _selectedPaymentMethod == 'WALLET'
                                          ? AppColors.primary
                                          : (hasEnoughBalance ? Colors.grey.shade300 : Colors.red.shade300),
                                      width: _selectedPaymentMethod == 'WALLET' ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Radio<String>(
                                            value: 'WALLET',
                                            groupValue: _selectedPaymentMethod,
                                            activeColor: AppColors.primary,
                                            onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 20),
                                                    const SizedBox(width: 6),
                                                    const Text(
                                                      'Ví SecondLife Escrow',
                                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      currencyFormatter.format(walletBalance),
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                        color: hasEnoughBalance ? Colors.green.shade700 : Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Trừ tiền trực tiếp từ số dư ví SecondLife của bạn.',
                                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_selectedPaymentMethod == 'WALLET' && !hasEnoughBalance) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Số dư ví không đủ. Cần nạp thêm ${currencyFormatter.format(total - walletBalance)}.',
                                          style: const TextStyle(fontSize: 11, color: Colors.red),
                                        ),
                                        const SizedBox(height: 6),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            icon: const Icon(Icons.add_card, size: 16, color: AppColors.primary),
                                            label: const Text('Nạp tiền vào ví', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: AppColors.primary),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            onPressed: () => showVietQrDepositSheet(context, ref),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Error Banner if order failed
                        if (checkoutState.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              checkoutState.errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: (checkoutState.isSubmitting ||
                                    (_selectedPaymentMethod == 'WALLET' && !hasEnoughBalance))
                                ? null
                                : () async {
                                    final orderId = await ref
                                        .read(checkoutNotifierProvider.notifier)
                                        .submitOrder(
                                          postId: widget.postId,
                                          shippingQuoteId: quote.quoteId,
                                          negotiationId: widget.negotiationId,
                                          paymentMethod: _selectedPaymentMethod,
                                        );

                                    if (orderId != null && context.mounted) {
                                      if (_selectedPaymentMethod == 'BANK_TRANSFER') {
                                        // Điều hướng sang màn hình quét mã VietQR 15 phút
                                        context.push('/order-bank-transfer/$orderId');
                                      } else {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (_) => AlertDialog(
                                            title: const Row(
                                              children: [
                                                Icon(Icons.check_circle, color: Colors.green),
                                                SizedBox(width: 8),
                                                Text('Đặt Hàng Thành Công!'),
                                              ],
                                            ),
                                            content: const Text(
                                              'Đơn hàng của bạn đã được ghi nhận. Tiền thanh toán được giữ an toàn trong Escrow và sẽ chỉ chuyển cho người bán khi bạn xác nhận nhận hàng.',
                                            ),
                                            actions: [
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  context.go('/orders');
                                                },
                                                child: const Text('Xem Đơn Mua', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: checkoutState.isSubmitting
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    _selectedPaymentMethod == 'BANK_TRANSFER'
                                        ? 'Tiếp Tục Quét VietQR (${currencyFormatter.format(total)})'
                                        : 'Xác Nhận Đặt Hàng (${currencyFormatter.format(total)})',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                  error: (e, _) => Text('Lỗi tính phí ship: $e'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }
}
