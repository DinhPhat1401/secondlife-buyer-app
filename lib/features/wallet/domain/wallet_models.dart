enum WalletTransactionType {
  orderPayout('ORDER_PAYOUT', 'Nhận tiền bán hàng', true),
  withdrawal('WITHDRAWAL', 'Rút tiền về ngân hàng', false),
  commissionFee('COMMISSION_FEE', 'Phí hoa hồng dịch vụ', false),
  refund('REFUND', 'Hoàn tiền giao dịch', true),
  deposit('DEPOSIT', 'Nạp tiền vào ví', true),
  payment('PAYMENT', 'Thanh toán dịch vụ', false),
  adjustment('ADJUSTMENT', 'Điều chỉnh hệ thống', true);

  final String code;
  final String label;
  final bool isCredit; // true = +, false = -

  const WalletTransactionType(this.code, this.label, this.isCredit);

  static WalletTransactionType fromCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'ORDER_PAYOUT':
        return WalletTransactionType.orderPayout;
      case 'WITHDRAWAL':
        return WalletTransactionType.withdrawal;
      case 'COMMISSION_FEE':
        return WalletTransactionType.commissionFee;
      case 'REFUND':
        return WalletTransactionType.refund;
      case 'DEPOSIT':
        return WalletTransactionType.deposit;
      case 'PAYMENT':
        return WalletTransactionType.payment;
      case 'ADJUSTMENT':
      default:
        return WalletTransactionType.adjustment;
    }
  }
}

enum WithdrawalStatus {
  pendingReview('PENDING_REVIEW', 'Đang xử lý'),
  approved('APPROVED', 'Đã chuyển tiền'),
  rejected('REJECTED', 'Bị từ chối'),
  cancelled('CANCELLED', 'Đã hủy');

  final String code;
  final String label;

  const WithdrawalStatus(this.code, this.label);

  static WithdrawalStatus fromCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'APPROVED':
        return WithdrawalStatus.approved;
      case 'REJECTED':
        return WithdrawalStatus.rejected;
      case 'CANCELLED':
        return WithdrawalStatus.cancelled;
      case 'PENDING_REVIEW':
      default:
        return WithdrawalStatus.pendingReview;
    }
  }
}

class SupportedBank {
  final String code;
  final String shortName;
  final String name;

  const SupportedBank({
    required this.code,
    required this.shortName,
    required this.name,
  });

  static const List<SupportedBank> list = [
    SupportedBank(code: 'VCB', shortName: 'Vietcombank', name: 'Ngoại Thương Việt Nam'),
    SupportedBank(code: 'MB', shortName: 'MB Bank', name: 'Quân Đội'),
    SupportedBank(code: 'TCB', shortName: 'Techcombank', name: 'Kỹ Thương Việt Nam'),
    SupportedBank(code: 'ACB', shortName: 'ACB', name: 'Á Châu'),
    SupportedBank(code: 'VPB', shortName: 'VPBank', name: 'Việt Nam Thịnh Vượng'),
    SupportedBank(code: 'TPB', shortName: 'TPBank', name: 'Tiên Phong'),
    SupportedBank(code: 'BIDV', shortName: 'BIDV', name: 'Đầu tư & Phát triển VN'),
    SupportedBank(code: 'CTG', shortName: 'VietinBank', name: 'Công Thương Việt Nam'),
  ];
}

class SellerWalletModel {
  final String id;
  final String userId;
  final double balance;
  final double pendingBalance;
  final double totalWithdrawn;
  final DateTime updatedAt;

  const SellerWalletModel({
    required this.id,
    required this.userId,
    required this.balance,
    this.pendingBalance = 0.0,
    this.totalWithdrawn = 0.0,
    required this.updatedAt,
  });

  factory SellerWalletModel.fromJson(Map<String, dynamic> json) {
    return SellerWalletModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      pendingBalance: (json['pendingBalance'] as num?)?.toDouble() ?? 0.0,
      totalWithdrawn: (json['totalWithdrawn'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class WalletTransactionModel {
  final String id;
  final double amount;
  final WalletTransactionType type;
  final String description;
  final String? referenceId;
  final double? balanceAfter;
  final DateTime createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    this.referenceId,
    this.balanceAfter,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: WalletTransactionType.fromCode(json['type']?.toString()),
      description: json['description'] ?? 'Biến động số dư',
      referenceId: json['referenceId']?.toString(),
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class WalletWithdrawalModel {
  final String id;
  final double amount;
  final String bankCode;
  final String? bankName;
  final String accountNumber;
  final String accountHolderName;
  final WithdrawalStatus status;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? processedAt;

  const WalletWithdrawalModel({
    required this.id,
    required this.amount,
    required this.bankCode,
    this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
    required this.status,
    this.adminNote,
    required this.createdAt,
    this.processedAt,
  });

  factory WalletWithdrawalModel.fromJson(Map<String, dynamic> json) {
    return WalletWithdrawalModel(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      bankCode: json['bankCode']?.toString() ?? '',
      bankName: json['bankName']?.toString(),
      accountNumber: json['accountNumber']?.toString() ?? '',
      accountHolderName: json['accountHolderName']?.toString() ?? '',
      status: WithdrawalStatus.fromCode(json['status']?.toString()),
      adminNote: json['adminNote']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      processedAt: json['processedAt'] != null
          ? DateTime.tryParse(json['processedAt'].toString())
          : null,
    );
  }
}
