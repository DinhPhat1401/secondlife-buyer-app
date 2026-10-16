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

  bool get _isExpired => _remainingTime.inSeconds <= 0;

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
    // Polling tự động mỗi 3 giây theo quy chuẩn FE_SEPAY_VIETQR_INTEGRATION_AND_UX_SAFETY_GUIDE
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkPaymentStatus(silent: true));
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
          HapticFeedback.mediumImpact();
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
          'Đơn hàng đã hết thời hạn thanh toán (15 phút). Vui lòng KHÔNG chuyển tiền vào mã này nữa để tránh đơn hàng bị hủy tự động.',
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
          'Hệ thống SePay đã ghi nhận giao dịch chuyển khoản thành công. Số tiền đã được đưa vào Escrow SecondLife để bảo vệ bạn trong suốt quá trình giao nhận hàng.',
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

  void _copyToClipboard(String text, String label, {bool isTransferContent = false}) {
    if (_isExpired) return;
    Clipboard.setData(ClipboardData(text: text));

    if (isTransferContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.amber.shade900,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚠️ Đã chép mã: $text. Tuyệt đối KHÔNG dùng lại nội dung chuyển khoản cũ để tránh đơn hàng bị hủy!',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã sao chép $label: $text'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _showFullScreenQr(String qrUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Mã VietQR Thanh Toán',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: qrUrl,
                  width: 280,
                  height: 280,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bạn có thể chụp màn hình để mở trong App Ngân Hàng',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
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
                // Chiến lược 5: Wallet Fallback Banner (Nếu tiền đã lỡ chuyển vào ví)
                if (payment.hasWalletFallback)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Color(0xFF059669), size: 24),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Đã Hoàn Tiền Vào Ví An Toàn',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF065F46)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'SecondLife đã nhận được ${currencyFormatter.format(payment.walletCreditedAmount)} từ bạn! Tuy nhiên do giao dịch được thực hiện sau khi đơn hàng hết hạn, toàn bộ số tiền đã được hoàn trả an toàn vào Ví SecondLife của bạn.',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF047857), height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                                label: const Text('Mua Lại Bằng Ví', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  context.push('/marketplace');
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF065F46),
                                  side: const BorderSide(color: Color(0xFF059669)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                                label: const Text('Kiểm Tra Số Dư Ví', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  context.push('/wallet');
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Countdown Timer Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _isExpired
                        ? Colors.grey.shade100
                        : (_remainingTime.inMinutes < 3 ? Colors.red.shade50 : Colors.amber.shade50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isExpired
                          ? Colors.grey.shade300
                          : (_remainingTime.inMinutes < 3 ? Colors.red.shade300 : Colors.amber.shade300),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isExpired ? Icons.timer_off_outlined : Icons.timer_outlined,
                        color: _isExpired
                            ? Colors.grey
                            : (_remainingTime.inMinutes < 3 ? Colors.red : Colors.amber.shade900),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isExpired
                            ? 'MÃ THANH TOÁN ĐÃ HẾT HẠN (15 PHÚT)'
                            : 'Thời gian thanh toán còn lại: $minutes:$seconds',
                        style: TextStyle(
                          color: _isExpired
                              ? Colors.grey.shade800
                              : (_remainingTime.inMinutes < 3 ? Colors.red : Colors.amber.shade900),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // VietQR Code Box (Chiến lược 1 & 3: Động & Làm mờ khi hết hạn)
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
                        'Mở App Ngân hàng bất kỳ để Quét mã QR tự động điền số tiền & nội dung',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),

                      // QR Stack với Blur che phủ khi hết hạn
                      Stack(
                        alignment: Alignment.center,
                        children: [
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

                          // Lớp phủ vô hiệu hóa khi hết hạn 15 phút (Chiến lược 3)
                          if (_isExpired)
                            Container(
                              width: 244,
                              height: 244,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.block_outlined, color: Colors.red, size: 48),
                                    SizedBox(height: 8),
                                    Text(
                                      'MÃ ĐÃ HẾT HẠN\nVui lòng không chuyển tiền',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Nút phóng to / xem toàn màn hình
                      TextButton.icon(
                        onPressed: _isExpired ? null : () => _showFullScreenQr(payment.qrCodeUrl),
                        icon: const Icon(Icons.crop_free, size: 16),
                        label: const Text('Phóng to mã QR / Chụp màn hình', style: TextStyle(fontSize: 12)),
                      ),

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
                              'SePay đối soát & xác nhận tự động trong 3 giây',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Bank Details Card (Chiến lược 2: Cảnh báo mạnh mẽ khi Copy thủ công)
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

                      const SizedBox(height: 8),

                      // Ô NỘI DUNG CHUYỂN TIỀN ĐẶC BIỆT NỔI BẬT (BẮT BUỘC)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade300, width: 1.2),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'NỘI DUNG CHUYỂN TIỀN (BẮT BUỘC):',
                                    style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    payment.transferContent,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      color: Colors.red,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _isExpired
                                  ? null
                                  : () => _copyToClipboard(
                                        payment.transferContent,
                                        'Nội dung chuyển khoản',
                                        isTransferContent: true,
                                      ),
                              icon: const Icon(Icons.copy, size: 14),
                              label: const Text('Sao Chép'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '* Lưu ý quan trọng: Mỗi đơn hàng có mã thanh toán riêng biệt. Tuyệt đối KHÔNG dùng lại nội dung cũ trong danh bạ ngân hàng để tránh đơn hàng bị hủy!',
                        style: TextStyle(fontSize: 11, color: Colors.redAccent, fontStyle: FontStyle.italic),
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
                      _isChecking ? 'Đang kiểm tra giao dịch...' : 'Tôi Đã Chuyển Khoản Xong',
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
            onTap: _isExpired ? null : () => _copyToClipboard(copyValue, label),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.copy, size: 16, color: _isExpired ? Colors.grey : AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
