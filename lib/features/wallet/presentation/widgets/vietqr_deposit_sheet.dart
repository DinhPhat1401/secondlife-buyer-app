import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../wallet_providers.dart';

void showVietQrDepositSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _VietQrDepositSheetContent(),
  );
}

class _VietQrDepositSheetContent extends ConsumerStatefulWidget {
  const _VietQrDepositSheetContent();

  @override
  ConsumerState<_VietQrDepositSheetContent> createState() => _VietQrDepositSheetContentState();
}

class _VietQrDepositSheetContentState extends ConsumerState<_VietQrDepositSheetContent> {
  final _amountController = TextEditingController(text: '500000');
  bool _isLoading = false;
  Map<String, dynamic>? _depositInfo;

  Timer? _countdownTimer;
  Timer? _pollingTimer;
  Duration _remainingTime = const Duration(minutes: 15);
  double _initialBalance = 0.0;
  bool _isSuccess = false;

  bool get _isExpired => _remainingTime.inSeconds <= 0;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _remainingTime = const Duration(minutes: 15);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingTime.inSeconds <= 1) {
        timer.cancel();
        _pollingTimer?.cancel();
        setState(() => _remainingTime = Duration.zero);
      } else {
        setState(() => _remainingTime = _remainingTime - const Duration(seconds: 1));
      }
    });
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    // Lấy số dư ban đầu để so sánh khi tiền về ví
    final wallet = ref.read(sellerWalletNotifierProvider).wallet;
    _initialBalance = wallet?.balance ?? 0.0;

    // Polling mỗi 3 giây kiểm tra xem tiền đã vào ví chưa
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted || _isExpired || _isSuccess) return;
      try {
        final repo = ref.read(walletRepositoryProvider);
        final currentWallet = await repo.getMyWallet();
        if (currentWallet.balance > _initialBalance) {
          _isSuccess = true;
          _pollingTimer?.cancel();
          _countdownTimer?.cancel();
          HapticFeedback.mediumImpact();
          await ref.read(sellerWalletNotifierProvider.notifier).loadWalletData();

          if (mounted) {
            _showSuccessModal();
          }
        }
      } catch (_) {}
    });
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Nạp Tiền Thành Công!'),
          ],
        ),
        content: const Text(
          'Hệ thống SePay đã ghi nhận tiền nạp qua VietQR và cộng số dư ví SecondLife của bạn thành công.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Đóng luôn sheet nạp
            },
            child: const Text('Xem Số Dư Mới', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _createRequest() async {
    final amount = double.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0.0;
    if (amount < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số tiền nạp tối thiểu là 10.000₫')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(walletRepositoryProvider);
      final res = await repo.createDepositRequest(amount);
      if (mounted) {
        setState(() {
          _depositInfo = res;
          _isLoading = false;
        });
        _startCountdown();
        _startPolling();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo yêu cầu nạp: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
                  '⚠️ Đã chép mã: $text. Tuyệt đối KHÔNG dùng lại nội dung nạp cũ trong danh bạ ngân hàng!',
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
                'Mã VietQR Nạp Ví',
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
              const SizedBox(height: 14),
              const Text(
                'Chụp màn hình mã này để quét từ Album trong App Ngân Hàng',
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
    final f = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final minutes = _remainingTime.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _remainingTime.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 28),
              const SizedBox(width: 10),
              const Text(
                'Nạp Tiền Ví Qua VietQR',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 20),

          if (_depositInfo == null) ...[
            const Text(
              'Chọn nhanh số tiền nạp:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildQuickAmount(200000),
                const SizedBox(width: 8),
                _buildQuickAmount(500000),
                const SizedBox(width: 8),
                _buildQuickAmount(1000000),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              'Hoặc nhập số tiền (VNĐ):',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                suffixText: '₫',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _createRequest,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Tạo Mã Chuyển Khoản VietQR', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ] else ...[
            // Countdown Timer Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: _isExpired
                    ? Colors.grey.shade100
                    : (_remainingTime.inMinutes < 3 ? Colors.red.shade50 : Colors.amber.shade50),
                borderRadius: BorderRadius.circular(10),
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
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isExpired ? 'MÃ NẠP TIỀN ĐÃ HẾT HẠN (15 PHÚT)' : 'Hết hạn sau: $minutes:$seconds',
                    style: TextStyle(
                      color: _isExpired
                          ? Colors.grey.shade800
                          : (_remainingTime.inMinutes < 3 ? Colors.red : Colors.amber.shade900),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Center(
              child: Column(
                children: [
                  // QR Stack với Blur che phủ khi hết hạn
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: _resolveQrUrl(),
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const SizedBox(
                              width: 200,
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.qr_code_2, size: 160),
                          ),
                        ),
                      ),
                      if (_isExpired)
                        Container(
                          width: 224,
                          height: 224,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.block_outlined, color: Colors.red, size: 40),
                                SizedBox(height: 6),
                                Text(
                                  'MÃ NẠP ĐÃ HẾT HẠN\nVui lòng tạo mã mới',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  TextButton.icon(
                    onPressed: _isExpired ? null : () => _showFullScreenQr(_resolveQrUrl()),
                    icon: const Icon(Icons.crop_free, size: 16),
                    label: const Text('Phóng to mã QR / Chụp màn hình', style: TextStyle(fontSize: 12)),
                  ),

                  Text(
                    'Số tiền cần chuyển: ${f.format(_depositInfo!['amount'] ?? 0)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 10),

                  _buildCopyRow('Ngân hàng', _depositInfo!['bankName']?.toString() ?? 'MBBank'),
                  _buildCopyRow('Số tài khoản', _depositInfo!['bankAccountNumber']?.toString() ?? _depositInfo!['accountNumber']?.toString() ?? ''),
                  _buildCopyRow('Chủ tài khoản', _depositInfo!['bankAccountName']?.toString() ?? _depositInfo!['accountName']?.toString() ?? 'CONG TY SECONDLIFE'),

                  // Ô NỘI DUNG CHUYỂN KHOẢN NỔI BẬT ĐẶC BIỆT
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
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
                              const SizedBox(height: 2),
                              Text(
                                _depositInfo!['code']?.toString() ?? _depositInfo!['transferContent']?.toString() ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
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
                                    _depositInfo!['code']?.toString() ?? _depositInfo!['transferContent']?.toString() ?? '',
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
                  const SizedBox(height: 4),
                  const Text(
                    '* Lưu ý: Dán chính xác mã này vào lời nhắn để SePay tự động cộng tiền.',
                    style: TextStyle(fontSize: 11, color: Colors.redAccent, fontStyle: FontStyle.italic),
                  ),

                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Đang lắng nghe SePay tự động nạp tiền...',
                        style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      ref.read(sellerWalletNotifierProvider.notifier).loadWalletData();
                      Navigator.pop(context);
                    },
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _resolveQrUrl() {
    if (_depositInfo == null) return '';
    if (_depositInfo!['qrCode'] != null && _depositInfo!['qrCode'].toString().isNotEmpty) {
      return _depositInfo!['qrCode'].toString();
    }
    final acc = _depositInfo!['bankAccountNumber'] ?? _depositInfo!['accountNumber'] ?? '';
    final bank = _depositInfo!['bankName'] ?? 'MBBank';
    final amount = (_depositInfo!['amount'] is num) ? (_depositInfo!['amount'] as num).toInt() : 0;
    final code = _depositInfo!['code'] ?? _depositInfo!['transferContent'] ?? '';
    return 'https://qr.sepay.vn/img?acc=$acc&bank=$bank&amount=$amount&des=$code';
  }

  Widget _buildQuickAmount(int amount) {
    final f = NumberFormat.compact(locale: 'vi');
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          setState(() {
            _amountController.text = amount.toString();
          });
        },
        child: Text('${f.format(amount)}₫', style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ),
    );
  }

  Widget _buildCopyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy, size: 16, color: _isExpired ? Colors.grey : AppColors.primary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _isExpired ? null : () => _copyToClipboard(value, label),
          ),
        ],
      ),
    );
  }
}
