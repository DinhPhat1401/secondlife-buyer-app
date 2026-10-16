import 'package:cached_network_image/cached_network_image.dart';
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
    _controller = TextEditingController(text: widget.initialSealId ?? '');
    if (_controller.text.trim().isNotEmpty) {
      _verify();
    }
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
                        Expanded(
                          child: Text(
                            _sealResult!.tamperSealId,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
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
                    const SizedBox(height: 12),

                    // Hiển thị ảnh sản phẩm
                    if (_sealResult!.productImageUrl != null && _sealResult!.productImageUrl!.isNotEmpty) ...[
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: _sealResult!.productImageUrl!,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(width: 64, height: 64, color: Colors.grey.shade200),
                              errorWidget: (_, _, _) => const Icon(Icons.devices, size: 36, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _sealResult!.productTitle,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Hạng ${_sealResult!.conditionGrade}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_sealResult!.conditionScore}/100 điểm',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                    ] else ...[
                      _buildInfoRow('Thiết bị:', _sealResult!.productTitle),
                    ],

                    if (_sealResult!.orderCode != null)
                      _buildInfoRow('Mã đơn:', _sealResult!.orderCode!),
                    _buildInfoRow('Trung tâm:', _sealResult!.centerName),
                    _buildInfoRow('Kỹ thuật viên:', _sealResult!.inspectorName),
                    _buildInfoRow('Thời gian dán:', dateFormatter.format(_sealResult!.inspectionDate)),
                    if (_sealResult!.notes != null)
                      _buildInfoRow('Ghi chú KTV:', _sealResult!.notes!),

                    // Lịch sử trạm quét GPS
                    if (_sealResult!.scanLogs.isNotEmpty) ...[
                      const Divider(height: 20),
                      const Text(
                        'Hành Trình & Lưu Vết Tem Niêm Phong (GPS)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      ..._sealResult!.scanLogs.map((log) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, size: 14, color: Color(0xFF22C55E)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      log.stageLabel,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Text(
                                    dateFormatter.format(log.scannedAt),
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              if (log.hasCoordinates) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 12, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Vị trí GPS: ${log.latitude!.toStringAsFixed(4)}, ${log.longitude!.toStringAsFixed(4)}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                              if (log.notes != null && log.notes!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  log.notes!,
                                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
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
