import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/wallet_models.dart';
import '../wallet_providers.dart';
import '../widgets/vietqr_deposit_sheet.dart';

class BuyerWalletScreen extends ConsumerStatefulWidget {
  const BuyerWalletScreen({super.key});

  @override
  ConsumerState<BuyerWalletScreen> createState() => _BuyerWalletScreenState();
}

class _BuyerWalletScreenState extends ConsumerState<BuyerWalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(sellerWalletNotifierProvider);
    final wallet = walletState.wallet;
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
    final hideBalance = ref.watch(hideWalletBalanceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F5),
      appBar: AppBar(
        title: const Text(
          'Ví Ký Quỹ & Thanh Toán',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(sellerWalletNotifierProvider.notifier).loadWalletData(),
          ),
        ],
      ),
      body: walletState.isLoading && wallet == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(sellerWalletNotifierProvider.notifier).loadWalletData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Combined Balance Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2C3E50), Color(0xFF1A252F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 12,
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
                              Row(
                                children: [
                                  const Icon(Icons.shield_outlined, color: Color(0xFF48BB78), size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'BẢO VỆ ESCROW SECONDLIFE',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.75),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  hideBalance ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                onPressed: () => ref.read(hideWalletBalanceProvider.notifier).toggle(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Số dư khả dụng thanh toán',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hideBalance ? '•••••••• ₫' : currencyFormatter.format(wallet?.balance ?? 0),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Đang tạm giữ Escrow',
                                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    hideBalance ? '••••••' : currencyFormatter.format(wallet?.pendingBalance ?? 0),
                                    style: const TextStyle(
                                      color: Color(0xFFE2E8F0),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                                label: const Text('Nạp tiền VietQR', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () => showVietQrDepositSheet(context, ref),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Escrow guarantee notice
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded, color: Color(0xFF2E7D32), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Cơ chế bảo vệ thanh toán 48h',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20)),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Khoản tiền thanh toán sẽ được giữ an toàn tại ví Escrow và chỉ chuyển cho người bán sau 48h khi bạn đã kiểm tra máy hài lòng.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32), height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Transaction list header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lịch Sử Giao Dịch',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${walletState.transactions.length} giao dịch',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (walletState.transactions.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text('Chưa có phát sinh giao dịch nào', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: walletState.transactions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final tx = walletState.transactions[index];
                          final isPositive = tx.type == WalletTransactionType.deposit ||
                              tx.type == WalletTransactionType.refund ||
                              tx.amount > 0;

                          return Container(
                            color: Colors.white,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isPositive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                child: Icon(
                                  isPositive ? Icons.add : Icons.remove,
                                  color: isPositive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                tx.description.isNotEmpty ? tx.description : 'Giao dịch ví',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                dateFormatter.format(tx.createdAt),
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              trailing: Text(
                                '${isPositive ? "+" : "-"}${currencyFormatter.format(tx.amount.abs())}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isPositive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

