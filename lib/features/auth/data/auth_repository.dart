import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final ApiClient client;
  final SecureStorageService storage;

  AuthRepository({
    required this.client,
    required this.storage,
  });

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Không nhận được dữ liệu xác thực từ máy chủ');
    }

    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;

    if (accessToken == null) {
      throw Exception('Thiếu access token trong phản hồi');
    }

    await storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    final user = UserModel.fromJson(data);
    await storage.saveUser(user.toJson());

    return user;
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: {
        'email': email.trim().toLowerCase(),
        'password': password,
        'fullName': fullName.trim(),
        if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
      },
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Đăng ký không thành công');
    }

    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;

    if (accessToken != null) {
      await storage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }

    final user = UserModel.fromJson(data);
    await storage.saveUser(user.toJson());

    return user;
  }

  Future<void> sendEmailVerification(String email) async {
    await client.post(
      ApiEndpoints.sendEmailVerification,
      data: {'email': email.trim().toLowerCase()},
    );
  }

  Future<void> confirmEmailVerification({
    required String email,
    required String otp,
  }) async {
    await client.post(
      ApiEndpoints.confirmEmailVerification,
      data: {
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
      },
    );
  }

  Future<UserModel?> getCurrentUser() async {
    final token = await storage.getAccessToken();
    if (token == null || token.isEmpty) return null;

    final response = await client.get<Map<String, dynamic>>(ApiEndpoints.userMe);
    if (response.data != null) {
      final user = UserModel.fromJson(response.data!);
      await storage.saveUser(user.toJson());
      return user;
    }
    return null;
  }

  Future<void> logout() async {
    try {
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken != null) {
        await client.post(
          ApiEndpoints.logout,
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      await storage.clearAuth();
    }
  }
}
