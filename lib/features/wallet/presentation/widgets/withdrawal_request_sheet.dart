import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/wallet_models.dart';
import '../wallet_providers.dart';

class WithdrawalRequestSheet extends ConsumerStatefulWidget {
  final double availableBalance;

  const WithdrawalRequestSheet({
    super.key,
    required this.availableBalance,
  });

  static Future<bool?> show(BuildContext context, double availableBalance) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WithdrawalRequestSheet(availableBalance: availableBalance),
    );
  }

  @override
  ConsumerState<WithdrawalRequestSheet> createState() => _WithdrawalRequestSheetState();
}

class _WithdrawalRequestSheetState extends ConsumerState<WithdrawalRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();

  SupportedBank _selectedBank = SupportedBank.list.first;
  String? _customError;

  @override
  void dispose() {
    _amountController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  void _setAmount(double amount) {
    final target = amount > widget.availableBalance ? widget.availableBalance : amount;
    _amountController.text = target.toInt().toString();
    setState(() => _customError = null);
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(sellerWalletNotifierProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Yêu Cầu Rút Tiền',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Balance notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Số dư khả dụng:',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    Text(
                      currencyFormatter.format(widget.availableBalance),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Amount Input
              const Text(
                'Số tiền cần rút (VND)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Tối thiểu 50.000 đ',
                  prefixIcon: const Icon(Icons.monetization_on_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập số tiền cần rút';
                  }
                  final amount = double.tryParse(val) ?? 0.0;
                  if (amount < 50000) {
                    return 'Số tiền rút tối thiểu là 50.000 đ';
                  }
                  if (amount > widget.availableBalance) {
                    return 'Số tiền vượt quá số dư khả dụng (${currencyFormatter.format(widget.availableBalance)})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              // Quick amount chips
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('200k', style: TextStyle(fontSize: 12)),
                    onPressed: () => _setAmount(200000),
                  ),
                  ActionChip(
                    label: const Text('500k', style: TextStyle(fontSize: 12)),
                    onPressed: () => _setAmount(500000),
                  ),
                  ActionChip(
                    label: const Text('1 Triệu', style: TextStyle(fontSize: 12)),
                    onPressed: () => _setAmount(1000000),
                  ),
                  ActionChip(
                    label: const Text('Rút tất cả', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    onPressed: () => _setAmount(widget.availableBalance),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Bank Dropdown
              const Text(
                'Ngân hàng thụ hưởng (VietQR)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<SupportedBank>(
                value: _selectedBank,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.account_balance_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: SupportedBank.list.map((bank) {
                  return DropdownMenuItem(
                    value: bank,
                    child: Text('${bank.shortName} - ${bank.name} (${bank.code})', overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBank = val);
                },
              ),
              const SizedBox(height: 14),
              // Account Number
              const Text(
                'Số tài khoản ngân hàng',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Nhập số tài khoản nhận tiền',
                  prefixIcon: const Icon(Icons.credit_card_outlined, color: AppColors.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 6) {
                    return 'Vui lòng nhập số tài khoản hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              // Account Holder Name
              const Text(
                'Tên chủ tài khoản (VIẾT HOA KHÔNG DẤU)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _accountHolderController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'VD: NGUYEN VAN A',
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập tên chủ tài khoản thụ hưởng';
                  }
                  return null;
                },
              ),
              if (_customError != null) ...[
                const SizedBox(height: 12),
                Text(_customError!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
              ],
              const SizedBox(height: 24),
              // Submit button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: walletState.isSubmittingWithdrawal
                    ? null
                    : () async {
                        if (_formKey.currentState?.validate() != true) return;
                        final amount = double.parse(_amountController.text.trim());
                        final success = await ref
                            .read(sellerWalletNotifierProvider.notifier)
                            .requestWithdrawal(
                              amount: amount,
                              bankCode: _selectedBank.code,
                              accountNumber: _accountNumberController.text.trim(),
                              accountHolderName: _accountHolderController.text.trim(),
                            );
                        if (mounted) {
                          if (success) {
                            Navigator.pop(context, true);
                          } else {
                            setState(() {
                              _customError = walletState.errorMessage ?? 'Gửi yêu cầu thất bại.';
                            });
                          }
                        }
                      },
                child: walletState.isSubmittingWithdrawal
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Xác Nhận Rút Tiền',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
