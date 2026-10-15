class TamperSealModel {
  final String tamperSealId;
  final String status; // ACTIVE, TAMPERED, EXPIRED
  final String productTitle;
  final String? orderCode;
  final String centerName;
  final String inspectorName;
  final DateTime inspectionDate;
  final String sealCondition; // INTACT, TAMPERED
  final String? notes;

  const TamperSealModel({
    required this.tamperSealId,
    required this.status,
    required this.productTitle,
    this.orderCode,
    required this.centerName,
    required this.inspectorName,
    required this.inspectionDate,
    this.sealCondition = 'INTACT',
    this.notes,
  });

  bool get isIntact => sealCondition.toUpperCase() == 'INTACT' && status.toUpperCase() == 'ACTIVE';

  factory TamperSealModel.fromJson(Map<String, dynamic> json) {
    return TamperSealModel(
      tamperSealId: json['tamperSealId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
      productTitle: json['productTitle']?.toString() ?? 'Thiết bị kiểm định',
      orderCode: json['orderCode']?.toString(),
      centerName: json['centerName']?.toString() ?? 'Trung tâm kiểm định SecondLife',
      inspectorName: json['inspectorName']?.toString() ?? 'Kỹ thuật viên kiểm định',
      inspectionDate: json['inspectionDate'] != null
          ? DateTime.tryParse(json['inspectionDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      sealCondition: json['sealCondition']?.toString() ?? 'INTACT',
      notes: json['notes']?.toString(),
    );
  }
}
