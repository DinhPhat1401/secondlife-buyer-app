import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../negotiation_providers.dart';

class MakeOfferDialog extends ConsumerStatefulWidget {
  final String postId;
  final String productTitle;
  final double originalPrice;

  const MakeOfferDialog({
    super.key,
    required this.postId,
    required this.productTitle,
    required this.originalPrice,
  });

  @override
  ConsumerState<MakeOfferDialog> createState() => _MakeOfferDialogState();
}

class _MakeOfferDialogState extends ConsumerState<MakeOfferDialog> {
  late TextEditingController _priceController;
  late double _currentOffer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default 10% discount suggestion
    _currentOffer = (widget.originalPrice * 0.9).roundToDouble();
    _priceController = TextEditingController(text: _formatRawPrice(_currentOffer));
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  String _formatRawPrice(double price) {
    return price.toStringAsFixed(0);
  }

  void _applyQuickDiscount(double percentage) {
    setState(() {
      _currentOffer = (widget.originalPrice * (1 - percentage)).roundToDouble();
      _priceController.text = _formatRawPrice(_currentOffer);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.handshake_outlined, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Thương Lượng Giá',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.productTitle,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Giá niêm yết: ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                Text(
                  currencyFormatter.format(widget.originalPrice),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const Divider(height: 24),

            const Text(
              'Gợi ý mức giá đề xuất:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildDiscountChip('-5%', 0.05),
                const SizedBox(width: 8),
                _buildDiscountChip('-10%', 0.10),
                const SizedBox(width: 8),
                _buildDiscountChip('-15%', 0.15),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              'Mức giá bạn muốn mua:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                suffixText: 'VNĐ',
                hintText: 'Nhập số tiền...',
                prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              onChanged: (val) {
                final parsed = double.tryParse(val.replaceAll('.', '').replaceAll(',', ''));
                if (parsed != null) {
                  setState(() => _currentOffer = parsed);
                }
              },
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
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() => _isLoading = true);
                        final result = await ref
                            .read(buyerNegotiationsNotifierProvider.notifier)
                            .submitOffer(widget.postId, _currentOffer);
                        setState(() => _isLoading = false);

                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result != null
                                    ? 'Đã gửi đề xuất ${currencyFormatter.format(_currentOffer)} đến người bán!'
                                    : 'Lỗi gửi đề xuất giá. Vui lòng thử lại!',
                              ),
                              backgroundColor: result != null ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      },
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        'Gửi Đề Xuất Cho Người Bán',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountChip(String label, double percentage) {
    final discounted = (widget.originalPrice * (1 - percentage)).roundToDouble();
    final isSelected = (_currentOffer - discounted).abs() < 1000;

    return Expanded(
      child: GestureDetector(
        onTap: () => _applyQuickDiscount(percentage),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.12) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
