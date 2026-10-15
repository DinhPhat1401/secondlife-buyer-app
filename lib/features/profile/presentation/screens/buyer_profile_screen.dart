import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../shipments/presentation/screens/shipment_tracking_screen.dart';
import '../../../shipments/presentation/widgets/tamper_seal_lookup_sheet.dart';
import '../../../wallet/presentation/wallet_providers.dart';
import '../../../wallet/presentation/widgets/vietqr_deposit_sheet.dart';

class BuyerProfileScreen extends ConsumerStatefulWidget {
  const BuyerProfileScreen({super.key});

  @override
  ConsumerState<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends ConsumerState<BuyerProfileScreen> {
  bool _hideBalance = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final walletState = ref.watch(sellerWalletNotifierProvider);
    final wallet = walletState.wallet;
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F5),
      appBar: AppBar(
        title: const Text('Tài Khoản & Ví'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: const Icon(Icons.person, color: AppColors.primary, size: 36),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName.isNotEmpty == true ? user!.fullName : 'Người mua SecondLife',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Tài khoản Thành Viên',
                            style: TextStyle(fontSize: 10, color: Colors.blue.shade800, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // SecondLife Escrow Wallet Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Số dư ví Escrow',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      IconButton(
                        icon: Icon(
                          _hideBalance ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.white70,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _hideBalance = !_hideBalance),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _hideBalance
                        ? '****** ₫'
                        : (wallet != null ? currencyFormatter.format(wallet.balance) : '0 ₫'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_card, size: 18),
                          label: const Text('Nạp tiền VietQR'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => showVietQrDepositSheet(context, ref),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white60),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        ),
                        onPressed: () => context.push('/wallet'),
                        child: const Text('Lịch sử'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Menu Section
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'Đơn mua của tôi',
                    subtitle: 'Theo dõi tiến trình & bưu tá Lalamove',
                    onTap: () => context.go('/orders'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'Tra cứu tem niêm phong KTV',
                    subtitle: 'Xác minh độ nguyên vẹn máy kiểm định',
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (_) => TamperSealLookupSheet(
                          repository: ref.read(shipmentRepositoryProvider),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    icon: Icons.storefront_outlined,
                    title: 'Mở gian hàng Người Bán',
                    subtitle: 'Bắt đầu bán đồ gia dụng thanh lý trên SecondLife',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng mở ứng dụng SecondLife Seller để vận hành shop!')),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Đăng xuất',
                    titleColor: Colors.red,
                    showArrow: false,
                    onTap: () async {
                      await ref.read(authNotifierProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                ],
              ),
            ),),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    bool showArrow = true,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (titleColor ?? AppColors.primary).withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: titleColor ?? AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: titleColor ?? const Color(0xFF1E293B),
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
          : null,
      trailing: showArrow
          ? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey)
          : null,
      onTap: onTap,
    );
  }
}
