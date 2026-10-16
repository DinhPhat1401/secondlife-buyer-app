class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String accountStatus;
  final bool emailVerified;
  final List<String> roles;
  final List<String> permissions;
  final String? badgeCode;
  final String? stationHubId;
  final String? stationHubName;
  final String? certificationTitle;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    required this.accountStatus,
    required this.emailVerified,
    required this.roles,
    required this.permissions,
    this.badgeCode,
    this.stationHubId,
    this.stationHubName,
    this.certificationTitle,
  });

  bool get isSeller => roles.contains('SELLER');
  bool get isInspector => roles.contains('INSPECTOR');
  bool get isAdmin => roles.contains('ADMIN');

  factory UserModel.fromJson(Map<String, dynamic> json, {List<String>? roles, List<String>? permissions}) {
    // Backend may return user summary directly or nested in auth response
    final userMap = json['user'] is Map<String, dynamic> ? json['user'] as Map<String, dynamic> : json;
    
    return UserModel(
      id: userMap['id']?.toString() ?? '',
      email: userMap['email'] ?? '',
      fullName: userMap['fullName'] ?? '',
      phone: userMap['phone'],
      avatarUrl: userMap['avatarUrl'],
      accountStatus: userMap['accountStatus'] ?? 'ACTIVE',
      emailVerified: userMap['emailVerified'] as bool? ?? false,
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? roles ?? [],
      permissions: (json['permissions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? permissions ?? [],
      badgeCode: userMap['badgeCode']?.toString(),
      stationHubId: userMap['stationHubId']?.toString(),
      stationHubName: userMap['stationHubName']?.toString(),
      certificationTitle: userMap['certificationTitle']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'phone': phone,
    'avatarUrl': avatarUrl,
    'accountStatus': accountStatus,
    'emailVerified': emailVerified,
    'roles': roles,
    'permissions': permissions,
    'badgeCode': badgeCode,
    'stationHubId': stationHubId,
    'stationHubName': stationHubName,
    'certificationTitle': certificationTitle,
  };
}
