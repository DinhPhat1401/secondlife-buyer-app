import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/shipment_repository.dart';
import '../../domain/tamper_seal_model.dart';

class TamperSealLookupSheet extends StatefulWidget {
  final ShipmentRepository repository;
  final String? initialSealId;

  const TamperSealLookupSheet({
    super.key,
    required this.repository,
    this.initialSealId,
  });

  static Future<void> show(
    BuildContext context, {
    required ShipmentRepository repository,
    String? initialSealId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TamperSealLookupSheet(
        repository: repository,
        initialSealId: initialSealId,
      ),
    );
  }

  @override
  State<TamperSealLookupSheet> createState() => _TamperSealLookupSheetState();
}

class _TamperSealLookupSheetState extends State<TamperSealLookupSheet> {
  late final TextEditingController _controller;
  bool _isLoading = false;
  TamperSealModel? _sealResult;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialSealId ?? 'SL-SEAL-20261014-9988');
    _verify();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final result = await widget.repository.verifyTamperSeal(_controller.text.trim());
    if (mounted) {
      setState(() {
        _sealResult = result;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_outlined, color: Color(0xFF059669), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Tra Cứu Tem Niêm Phong',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Input code
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Nhập mã tem (VD: SL-SEAL-...)',
                      prefixIcon: const Icon(Icons.qr_code, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading ? null : _verify,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Tra cứu'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Result View
            if (_sealResult != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _sealResult!.isIntact ? const Color(0xFFF0FDF4) : AppColors.errorLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _sealResult!.isIntact ? const Color(0xFF86EFAC) : AppColors.error,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _sealResult!.tamperSealId,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _sealResult!.isIntact ? const Color(0xFF22C55E) : AppColors.error,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _sealResult!.isIntact ? 'TEM NGUYÊN VẸN' : 'BỊ RÁCH / BẤT THƯỜNG',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow('Thiết bị:', _sealResult!.productTitle),
                    if (_sealResult!.orderCode != null)
                      _buildInfoRow('Mã đơn:', _sealResult!.orderCode!),
                    _buildInfoRow('Trung tâm:', _sealResult!.centerName),
                    _buildInfoRow('Kỹ thuật viên:', _sealResult!.inspectorName),
                    _buildInfoRow('Thời gian dán:', dateFormatter.format(_sealResult!.inspectionDate)),
                    if (_sealResult!.notes != null)
                      _buildInfoRow('Ghi chú KTV:', _sealResult!.notes!),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
