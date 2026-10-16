import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../checkout_providers.dart';

class OrderBankTransferScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderBankTransferScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderBankTransferScreen> createState() => _OrderBankTransferScreenState();
}

class _OrderBankTransferScreenState extends ConsumerState<OrderBankTransferScreen> {
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  Duration _remainingTime = const Duration(minutes: 15);
  bool _isChecking = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingTime.inSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingTime = Duration.zero);
        _showExpiredDialog();
      } else {
        setState(() => _remainingTime = _remainingTime - const Duration(seconds: 1));
      }
    });
  }

  void _startPolling() {
    // Polling trạng thái thanh toán từ SePay webhook mỗi 5 giây
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkPaymentStatus(silent: true));
  }

  Future<void> _checkPaymentStatus({bool silent = false}) async {
    if (_isCompleted) return;
    if (!silent) setState(() => _isChecking = true);

    try {
      final repo = ref.read(checkoutRepositoryProvider);
      final payment = await repo.getOrderBankPayment(widget.orderId);

      if (mounted) {
        final now = DateTime.now();
        if (payment.expiresAt.isAfter(now)) {
          _remainingTime = payment.expiresAt.difference(now);
        }

        if (payment.isPaid) {
          _isCompleted = true;
          _pollingTimer?.cancel();
          _countdownTimer?.cancel();
          _showSuccessDialog();
        }
      }
    } catch (_) {}

    if (!silent && mounted) {
      setState(() => _isChecking = false);
    }
  }

  void _showExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.timer_off_outlined, color: Colors.red),
            SizedBox(width: 8),
            Text('Hết Hạn Thanh Toán'),
          ],
        ),
        content: const Text(
          'Giao dịch chuyển khoản cho đơn hàng này đã hết hạn 15 phút. Nếu bạn đã chuyển khoản, hệ thống sẽ tự động hoàn tiền vào ví.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(context);
              context.go('/orders');
            },
            child: const Text('Về Đơn Mua', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Thanh Toán Thành Công!'),
          ],
        ),
        content: const Text(
          'Hệ thống SePay đã xác nhận giao dịch chuyển khoản thành công. Số tiền đã được chuyển vào Escrow SecondLife để bảo vệ bạn.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(context);
              context.go('/orders');
            },
            child: const Text('Xem Đơn Hàng', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label: $text'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentAsync = ref.watch(orderBankPaymentProvider(widget.orderId));
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    final minutes = _remainingTime.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _remainingTime.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F5),
      appBar: AppBar(
        title: const Text('Thanh Toán Chuyển Khoản'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: paymentAsync.when(
        data: (payment) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Countdown Timer Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _remainingTime.inMinutes < 3 ? Colors.red.shade50 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _remainingTime.inMinutes < 3 ? Colors.red.shade300 : Colors.amber.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: _remainingTime.inMinutes < 3 ? Colors.red : Colors.amber.shade900,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Thời gian thanh toán còn lại: $minutes:$seconds',
                        style: TextStyle(
                          color: _remainingTime.inMinutes < 3 ? Colors.red : Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // VietQR Code Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Quét Mã VietQR Bằng App Ngân Hàng',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Hỗ trợ 40+ ứng dụng ngân hàng và ví MoMo, ZaloPay',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: payment.qrCodeUrl,
                          width: 240,
                          height: 240,
                          fit: BoxFit.contain,
                          placeholder: (_, _) => Container(
                            width: 240,
                            height: 240,
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          ),
                          errorWidget: (_, _, _) => const Icon(Icons.qr_code_2, size: 160, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt, color: Colors.green, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Xác nhận tự động trong 3 - 5 giây',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Bank Details Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hoặc Chuyển Khoản Thủ Công',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Divider(height: 20),
                      _buildCopyRow(
                        label: 'Ngân hàng thụ hưởng',
                        value: payment.bankName,
                        copyValue: payment.bankName,
                      ),
                      _buildCopyRow(
                        label: 'Số tài khoản',
                        value: payment.bankAccountNumber,
                        copyValue: payment.bankAccountNumber,
                      ),
                      _buildCopyRow(
                        label: 'Tên chủ tài khoản',
                        value: payment.bankAccountName,
                        copyValue: payment.bankAccountName,
                      ),
                      _buildCopyRow(
                        label: 'Số tiền chính xác',
                        value: currencyFormatter.format(payment.remainingAmount > 0 ? payment.remainingAmount : payment.totalAmount),
                        copyValue: (payment.remainingAmount > 0 ? payment.remainingAmount : payment.totalAmount).toInt().toString(),
                        isHighlight: true,
                      ),
                      _buildCopyRow(
                        label: 'Nội dung chuyển khoản (Bắt buộc)',
                        value: payment.transferContent,
                        copyValue: payment.transferContent,
                        isHighlight: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Manual check status button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isChecking ? null : () => _checkPaymentStatus(silent: false),
                    icon: _isChecking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: Text(
                      _isChecking ? 'Đang kiểm tra giao dịch...' : 'Tôi Đã Chuyển Khoản Thành Công',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text('Lỗi tải thông tin thanh toán: $e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(orderBankPaymentProvider(widget.orderId)),
                  child: const Text('Thử Lại'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCopyRow({
    required String label,
    required String value,
    required String copyValue,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                color: isHighlight ? AppColors.primary : Colors.black87,
              ),
            ),
          ),
          InkWell(
            onTap: () => _copyToClipboard(copyValue, label),
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.copy, size: 16, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
