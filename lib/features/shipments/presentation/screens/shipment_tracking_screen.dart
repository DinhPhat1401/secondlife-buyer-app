import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_buyer/core/theme/app_colors.dart';
import 'package:secondlife_app_buyer/features/auth/presentation/auth_providers.dart';
import 'package:secondlife_app_buyer/shared/widgets/sl_badge.dart';
import 'package:secondlife_app_buyer/shared/widgets/sl_button.dart';
import '../../data/shipment_repository.dart';
import '../../domain/shipment_models.dart';
import '../widgets/tamper_seal_lookup_sheet.dart';

final shipmentRepositoryProvider = Provider<ShipmentRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ShipmentRepository(client: client);
});

class ShipmentTrackingScreen extends ConsumerStatefulWidget {
  final String shipmentId;

  const ShipmentTrackingScreen({
    super.key,
    required this.shipmentId,
  });

  @override
  ConsumerState<ShipmentTrackingScreen> createState() => _ShipmentTrackingScreenState();
}

class _ShipmentTrackingScreenState extends ConsumerState<ShipmentTrackingScreen> {
  bool _isLoading = true;
  ShipmentTrackingModel? _tracking;

  @override
  void initState() {
    super.initState();
    _loadTracking();
  }

  Future<void> _loadTracking() async {
    setState(() => _isLoading = true);
    final repo = ref.read(shipmentRepositoryProvider);
    final res = await repo.getTracking(widget.shipmentId);
    if (mounted) {
      setState(() {
        _tracking = res;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSync() async {
    setState(() => _isLoading = true);
    final repo = ref.read(shipmentRepositoryProvider);
    final res = await repo.syncTracking(widget.shipmentId);
    if (mounted) {
      setState(() {
        _tracking = res;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ÄÃ£ cáº­p nháº­t dá»¯ liá»‡u má»›i nháº¥t tá»« Lalamove'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Theo DÃµi Váº­n ÄÆ¡n Lalamove'),
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_outlined, color: Color(0xFF059669)),
            tooltip: 'Tra cá»©u tem niÃªm phong',
            onPressed: () {
              final repo = ref.read(shipmentRepositoryProvider);
              TamperSealLookupSheet.show(context, repository: repo);
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Äá»“ng bá»™ hÃ nh trÃ¬nh',
            onPressed: _handleSync,
          ),
        ],
      ),
      body: _isLoading && _tracking == null
          ? const Center(child: CircularProgressIndicator())
          : _tracking == null
              ? const Center(child: Text('KhÃ´ng tÃ¬m tháº¥y thÃ´ng tin váº­n Ä‘Æ¡n'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card
                      _buildHeaderCard(_tracking!),
                      const SizedBox(height: 16),

                      // Driver Card
                      _buildDriverCard(_tracking!),
                      const SizedBox(height: 20),

                      // Timeline Header
                      const Text(
                        'HÃ nh TrÃ¬nh Giao Nháº­n Chi Tiáº¿t',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 12),

                      // Timeline
                      _buildTimeline(_tracking!.timeline),
                      const SizedBox(height: 24),

                      // Sync button
                      SlButton(
                        text: 'Äá»“ng Bá»™ Láº¡i HÃ nh TrÃ¬nh Tá»« Lalamove',
                        icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                        isLoading: _isLoading,
                        onPressed: _handleSync,
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderCard(ShipmentTrackingModel t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'LALAMOVE',
                      style: TextStyle(color: Color(0xFFEA580C), fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.trackingNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textSecondary),
                tooltip: 'Sao chÃ©p mÃ£',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: t.trackingNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ÄÃ£ sao chÃ©p mÃ£ váº­n Ä‘Æ¡n'), duration: Duration(seconds: 1)),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          SlBadge.info('Äang giao hÃ ng'),
          if (t.estimatedDelivery != null) ...[
            const SizedBox(height: 10),
            Text(
              'Dá»± kiáº¿n giao: ${t.estimatedDelivery}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDriverCard(ShipmentTrackingModel t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryLight,
            child: const Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.driverName ?? 'TÃ i xáº¿ Lalamove',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Biá»ƒn sá»‘: ${t.plateNumber ?? "Äang cáº­p nháº­t"}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (t.driverPhone != null && t.driverPhone!.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.phone_in_talk, color: AppColors.success, size: 20),
                tooltip: 'Gá»i tÃ i xáº¿',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: t.driverPhone!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('SÄT tÃ i xáº¿: ${t.driverPhone} (ÄÃ£ sao chÃ©p)')),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<ShipmentTimelineEvent> events) {
    if (events.isEmpty) {
      return const Text('ChÆ°a cÃ³ sá»± kiá»‡n váº­n chuyá»ƒn nÃ o', style: TextStyle(color: AppColors.textSecondary));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final event = events[index];
          final isLast = index == events.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isLast ? AppColors.primary : AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isLast ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    if (event.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        event.description!,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      event.timestamp,
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
