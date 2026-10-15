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

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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
      setState(() {
        _depositInfo = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo yêu cầu nạp: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

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
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _depositInfo!['qrCode'] != null
                        ? Image.network(
                            _depositInfo!['qrCode'].toString(),
                            width: 200,
                            height: 200,
                            errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2, size: 160),
                          )
                        : const Icon(Icons.qr_code_2, size: 160),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Số tiền cần chuyển: ${f.format(_depositInfo!['amount'] ?? 0)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),

                  _buildCopyRow('Ngân hàng', _depositInfo!['bankName']?.toString() ?? 'VietinBank'),
                  _buildCopyRow('Số tài khoản', _depositInfo!['accountNumber']?.toString() ?? ''),
                  _buildCopyRow('Chủ tài khoản', _depositInfo!['accountName']?.toString() ?? 'SECONDLIFE'),
                  _buildCopyRow('Nội dung CK', _depositInfo!['transferContent']?.toString() ?? _depositInfo!['code']?.toString() ?? ''),

                  const SizedBox(height: 16),
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
                    child: const Text('Tôi Đã Chuyển Khoản'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
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
            icon: const Icon(Icons.copy, size: 16, color: AppColors.primary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã sao chép $label')),
              );
            },
          ),
        ],
      ),
    );
  }
}
