class ShipmentTimelineEvent {
  final String timestamp;
  final String title;
  final String? description;
  final String? location;
  final bool isCompleted;

  const ShipmentTimelineEvent({
    required this.timestamp,
    required this.title,
    this.description,
    this.location,
    this.isCompleted = true,
  });

  factory ShipmentTimelineEvent.fromJson(Map<String, dynamic> json) {
    return ShipmentTimelineEvent(
      timestamp: json['timestamp'] ?? json['createdAt'] ?? '',
      title: json['title'] ?? json['status'] ?? 'Cập nhật trạng thái',
      description: json['description'] ?? json['message'],
      location: json['location'],
      isCompleted: json['isCompleted'] as bool? ?? true,
    );
  }
}

class ShipmentTrackingModel {
  final String shipmentId;
  final String trackingNumber;
  final String carrier; // LALAMOVE, GHN
  final String? driverName;
  final String? driverPhone;
  final String? plateNumber;
  final String status;
  final String statusDescription;
  final String? originAddress;
  final String? destinationAddress;
  final String? estimatedDelivery;
  final List<ShipmentTimelineEvent> timeline;

  const ShipmentTrackingModel({
    required this.shipmentId,
    required this.trackingNumber,
    required this.carrier,
    this.driverName,
    this.driverPhone,
    this.plateNumber,
    required this.status,
    required this.statusDescription,
    this.originAddress,
    this.destinationAddress,
    this.estimatedDelivery,
    this.timeline = const [],
  });

  factory ShipmentTrackingModel.fromJson(Map<String, dynamic> json) {
    final rawTimeline = json['timeline'] ?? json['events'];
    List<ShipmentTimelineEvent> events = [];
    if (rawTimeline is List) {
      events = rawTimeline
          .map((e) => ShipmentTimelineEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return ShipmentTrackingModel(
      shipmentId: json['shipmentId']?.toString() ?? json['id']?.toString() ?? '',
      trackingNumber: json['trackingNumber'] ?? json['orderNumber'] ?? 'LALA-${DateTime.now().millisecondsSinceEpoch % 100000}',
      carrier: json['carrier'] ?? 'LALAMOVE',
      driverName: json['driverName'] ?? json['shipperName'],
      driverPhone: json['driverPhone'] ?? json['shipperPhone'],
      plateNumber: json['plateNumber'] ?? json['licensePlate'],
      status: json['status'] ?? 'ON_GOING',
      statusDescription: json['statusDescription'] ?? json['statusText'] ?? 'Đang giao hàng',
      originAddress: json['originAddress'] ?? json['senderAddress'],
      destinationAddress: json['destinationAddress'] ?? json['recipientAddress'],
      estimatedDelivery: json['estimatedDelivery'] ?? json['estimatedDeliveryTime'],
      timeline: events,
    );
  }
}
