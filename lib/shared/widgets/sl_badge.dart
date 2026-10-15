import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SlBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const SlBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  factory SlBadge.success(String label) => SlBadge(
        label: label,
        backgroundColor: AppColors.successLight,
        textColor: AppColors.success,
      );

  factory SlBadge.warning(String label) => SlBadge(
        label: label,
        backgroundColor: AppColors.warningLight,
        textColor: AppColors.warning,
      );

  factory SlBadge.info(String label) => SlBadge(
        label: label,
        backgroundColor: AppColors.infoLight,
        textColor: AppColors.info,
      );

  factory SlBadge.error(String label) => SlBadge(
        label: label,
        backgroundColor: AppColors.errorLight,
        textColor: AppColors.error,
      );

  factory SlBadge.neutral(String label) => SlBadge(
        label: label,
        backgroundColor: AppColors.divider,
        textColor: AppColors.textSecondary,
      );

  factory SlBadge.fromStatus(String status) {
    Color bg;
    Color fg;
    String display = status;

    switch (status.toUpperCase()) {
      case 'ACTIVE':
        bg = AppColors.successLight;
        fg = AppColors.success;
        display = 'Đang bán';
        break;
      case 'DRAFT':
        bg = AppColors.divider;
        fg = AppColors.textSecondary;
        display = 'Bản nháp';
        break;
      case 'PENDING':
      case 'WAITING_SELLER_APPROVAL':
      case 'WAITING_FEE_PAYMENT':
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        display = 'Chờ xử lý';
        break;
      case 'PENDING_INSPECTION':
      case 'INSPECTING':
        bg = AppColors.infoLight;
        fg = AppColors.info;
        display = 'Kiểm định';
        break;
      case 'PASSED':
      case 'COMPLETED':
      case 'DELIVERED':
        bg = AppColors.successLight;
        fg = AppColors.success;
        display = 'Thành công';
        break;
      case 'REJECTED':
      case 'FAILED':
      case 'CANCELLED':
        bg = AppColors.errorLight;
        fg = AppColors.error;
        display = 'Đã hủy / Lỗi';
        break;
      case 'APPROVED':
        bg = AppColors.successLight;
        fg = AppColors.success;
        display = 'Đã duyệt';
        break;
      default:
        bg = AppColors.divider;
        fg = AppColors.textPrimary;
        break;
    }

    return SlBadge(
      label: display,
      backgroundColor: bg,
      textColor: fg,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
