import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/wallet_models.dart';
import '../wallet_providers.dart';
import '../widgets/withdrawal_request_sheet.dart';

class SellerWalletScreen extends ConsumerStatefulWidget {
  const SellerWalletScreen({super.key});

  @override
  ConsumerState<SellerWalletScreen> createState() => _SellerWalletScreenState();
}

class _SellerWalletScreenState extends ConsumerState<SellerWalletScreen>
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
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
    final hideBalance = ref.watch(hideWalletBalanceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Ví Doanh Thu Người Bán',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(sellerWalletNotifierProvider.notifier).loadWalletData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(sellerWalletNotifierProvider.notifier).loadWalletData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Balance Card
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC34C36), Color(0xFFA83E2A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
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
                          const Text(
                            'Số dư khả dụng',
                            style: TextStyle(fontSize: 13, color: Colors.white70),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.shield_outlined, color: Colors.white, size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'Bảo chứng SecondLife',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            hideBalance
                                ? '•••••••• đ'
                                : currencyFormatter.format(wallet?.balance ?? 0),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              hideBalance ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.white70,
                              size: 20,
                            ),
                            tooltip: hideBalance ? 'Hiện số dư' : 'Ẩn số dư',
                            onPressed: () {
                              ref.read(hideWalletBalanceProvider.notifier).toggle();
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Text(
                                      'Chờ giải tỏa (Escrow)',
                                      style: TextStyle(fontSize: 11, color: Colors.white70),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.info_outline, size: 12, color: Colors.white70),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hideBalance
                                      ? '•••••••• đ'
                                      : currencyFormatter.format(wallet?.pendingBalance ?? 0),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tổng tiền đã rút',
                                  style: TextStyle(fontSize: 11, color: Colors.white70),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currencyFormatter.format(wallet?.totalWithdrawn ?? 0),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                          label: const Text(
                            'Yêu Cầu Rút Tiền Về Ngân Hàng',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            final success = await WithdrawalRequestSheet.show(
                              context,
                              wallet?.balance ?? 0.0,
                            );
                            if (success == true && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Yêu cầu rút tiền đã được gửi! Đang chờ duyệt.'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tab Bar
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Biến Động Số Dư'),
                    Tab(text: 'Lịch Sử Rút Tiền'),
                  ],
                ),
              ),

              // Tab View Content
              SizedBox(
                height: 480,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Transactions
                    Builder(
                      builder: (context) {
                        final sortedTxs = [...walletState.transactions]
                          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                        if (sortedTxs.isEmpty) {
                          return _buildEmptyTab('Chưa có biến động số dư nào');
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: sortedTxs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) {
                            final tx = sortedTxs[idx];
                            return _buildTransactionCard(tx, currencyFormatter, dateFormatter);
                          },
                        );
                      },
                    ),

                    // Tab 2: Withdrawals
                    Builder(
                      builder: (context) {
                        final sortedWds = [...walletState.withdrawals]
                          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                        if (sortedWds.isEmpty) {
                          return _buildEmptyTab('Chưa có yêu cầu rút tiền nào');
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: sortedWds.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) {
                            final wd = sortedWds[idx];
                            return _buildWithdrawalCard(wd, currencyFormatter, dateFormatter);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTab(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    WalletTransactionModel tx,
    NumberFormat currencyFormatter,
    DateFormat dateFormatter,
  ) {
    final isCredit = tx.type.isCredit;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCredit ? AppColors.successLight : AppColors.errorLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? AppColors.success : AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormatter.format(tx.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? "+" : "-"}${currencyFormatter.format(tx.amount.abs())}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCredit ? AppColors.success : AppColors.error,
                ),
              ),
              if (tx.balanceAfter != null)
                Text(
                  'Dư: ${currencyFormatter.format(tx.balanceAfter)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalCard(
    WalletWithdrawalModel wd,
    NumberFormat currencyFormatter,
    DateFormat dateFormatter,
  ) {
    Color statusColor;
    Color statusBgColor;
    switch (wd.status) {
      case WithdrawalStatus.approved:
        statusColor = AppColors.success;
        statusBgColor = AppColors.successLight;
        break;
      case WithdrawalStatus.rejected:
        statusColor = AppColors.error;
        statusBgColor = AppColors.errorLight;
        break;
      case WithdrawalStatus.cancelled:
        statusColor = AppColors.textMuted;
        statusBgColor = const Color(0xFFF3F4F6);
        break;
      case WithdrawalStatus.pendingReview:
        statusColor = AppColors.warning;
        statusBgColor = AppColors.warningLight;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${wd.bankCode} • ${wd.accountNumber}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  wd.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            wd.accountHolderName,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateFormatter.format(wd.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              Text(
                currencyFormatter.format(wd.amount),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (wd.adminNote != null && wd.adminNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Lý do: ${wd.adminNote!}',
                      style: const TextStyle(fontSize: 11, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
