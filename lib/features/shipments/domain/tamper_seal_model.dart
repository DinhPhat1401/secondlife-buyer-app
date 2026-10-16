class InspectionSealLogModel {
  final String id;
  final String stage;
  final DateTime scannedAt;
  final String? scannedByName;
  final String? notes;
  final double? latitude;
  final double? longitude;

  const InspectionSealLogModel({
    required this.id,
    required this.stage,
    required this.scannedAt,
    this.scannedByName,
    this.notes,
    this.latitude,
    this.longitude,
  });

  factory InspectionSealLogModel.fromJson(Map<String, dynamic> json) {
    double? parseCoord(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    return InspectionSealLogModel(
      id: json['id']?.toString() ?? '',
      stage: (json['stage'] ?? json['scanStage'] ?? 'CENTER_RECEIVE').toString(),
      scannedAt: json['scannedAt'] != null
          ? DateTime.tryParse(json['scannedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      scannedByName: json['scannedByName']?.toString(),
      notes: (json['notes'] ?? json['note'])?.toString(),
      latitude: parseCoord(json['latitude']),
      longitude: parseCoord(json['longitude']),
    );
  }

  String get stageLabel {
    switch (stage) {
      case 'INITIAL_SEAL':
        return 'KTV dán tem niêm phong';
      case 'SELLER_TO_CENTER':
        return 'Người bán gửi tới Hub kiểm định';
      case 'CENTER_RECEIVE':
        return 'Hub tiếp nhận & niêm phong';
      case 'CARRIER_HANDOVER':
        return 'Bàn giao tài xế vận chuyển';
      case 'DELIVERED_BUYER':
        return 'Đã giao tới tay người mua';
      case 'RETURN_TO_SELLER':
        return 'Hoàn trả hàng về người bán';
      default:
        return stage;
    }
  }

  bool get hasCoordinates => latitude != null && longitude != null;
}

class TamperSealModel {
  final String tamperSealId;
  final String status; // ACTIVE, PASSED, TAMPERED, EXPIRED
  final String productTitle;
  final String? productImageUrl; // [MỚI] Ảnh sản phẩm
  final String? orderCode;
  final String centerName;
  final String inspectorName;
  final DateTime inspectionDate;
  final String sealCondition; // INTACT, TAMPERED
  final String? notes;
  final String conditionGrade;
  final int conditionScore;
  final List<InspectionSealLogModel> scanLogs;

  const TamperSealModel({
    required this.tamperSealId,
    required this.status,
    required this.productTitle,
    this.productImageUrl,
    this.orderCode,
    required this.centerName,
    required this.inspectorName,
    required this.inspectionDate,
    this.sealCondition = 'INTACT',
    this.notes,
    this.conditionGrade = 'A',
    this.conditionScore = 95,
    this.scanLogs = const [],
  });

  bool get isIntact =>
      sealCondition.toUpperCase() == 'INTACT' &&
      (status.toUpperCase() == 'ACTIVE' || status.toUpperCase() == 'PASSED');

  factory TamperSealModel.fromJson(Map<String, dynamic> json) {
    final rawLogs = json['scanLogs'] ?? json['scanHistory'];
    final logs = (rawLogs as List<dynamic>?)
            ?.map((e) => InspectionSealLogModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final center = json['centerName'] ?? json['inspectionCenterName'];
    final inspector = json['sealedByName'] ?? json['inspectorName'];
    final inspDateRaw = json['sealedAt'] ?? json['inspectedAt'] ?? json['inspectionDate'];

    return TamperSealModel(
      tamperSealId: json['tamperSealId']?.toString() ?? '',
      status: json['status']?.toString() ?? json['inspectionStatus']?.toString() ?? 'PASSED',
      productTitle: json['productTitle']?.toString() ?? 'Thiết bị kiểm định SecondLife',
      productImageUrl: json['productImageUrl']?.toString(),
      orderCode: (json['orderCode'] ?? json['orderId'] ?? json['inspectionOrderId'])?.toString(),
      centerName: center?.toString() ?? 'Trung tâm kiểm định SecondLife',
      inspectorName: inspector?.toString() ?? 'Kỹ thuật viên kiểm định',
      inspectionDate: inspDateRaw != null
          ? DateTime.tryParse(inspDateRaw.toString()) ?? DateTime.now()
          : DateTime.now(),
      sealCondition: json['sealCondition']?.toString() ?? json['currentSealStatus']?.toString() ?? 'INTACT',
      notes: (json['notes'] ?? json['note'] ?? json['reportSummary'])?.toString(),
      conditionGrade: json['conditionGrade']?.toString() ?? 'A',
      conditionScore: (json['conditionScore'] as num?)?.toInt() ?? 95,
      scanLogs: logs,
    );
  }
}
