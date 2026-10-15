import 'dart:async';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import 'api_endpoints.dart';
import 'api_response.dart';
import 'error_handler.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorageService storage;

  final _sessionExpiredController = StreamController<void>.broadcast();
  Stream<void> get onSessionExpired => _sessionExpiredController.stream;

  ApiClient({SecureStorageService? storageService})
      : storage = storageService ?? SecureStorageService() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(_createAuthInterceptor());
  }

  QueuedInterceptor _createAuthInterceptor() {
    return QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        // Dynamically ensure request uses the latest configured baseUrl
        options.baseUrl = AppConfig.baseUrl;

        // Do not attach token for public auth endpoints
        final path = options.path;
        if (!path.startsWith('/api/auth/login') &&
            !path.startsWith('/api/auth/register') &&
            !path.startsWith('/api/auth/refresh')) {
          final token = await storage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        // If 401 Unauthorized, attempt single-flight token refresh
        if (error.response?.statusCode == 401 &&
            !error.requestOptions.path.contains('/api/auth/')) {
          final refreshToken = await storage.getRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              // Create independent Dio to avoid interceptor deadlock
              final refreshDio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
              final refreshResponse = await refreshDio.post(
                ApiEndpoints.refresh,
                data: {'refreshToken': refreshToken},
              );

              final data = refreshResponse.data;
              final newAccessToken = data?['data']?['accessToken'] ?? data?['accessToken'];
              final newRefreshToken = data?['data']?['refreshToken'] ?? data?['refreshToken'] ?? refreshToken;

              if (newAccessToken != null) {
                await storage.saveTokens(
                  accessToken: newAccessToken,
                  refreshToken: newRefreshToken,
                );

                // Retry original request with updated access token
                final newOptions = error.requestOptions;
                newOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                final clonedResponse = await dio.fetch(newOptions);
                return handler.resolve(clonedResponse);
              }
            } catch (_) {
              // Refresh token failed or expired
              await storage.clearAuth();
              _sessionExpiredController.add(null);
            }
          } else {
            await storage.clearAuth();
            _sessionExpiredController.add(null);
          }
        }
        return handler.next(error);
      },
    );
  }

  // Generic Request Handlers
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final res = await dio.get(path, queryParameters: queryParameters);
      return ApiResponse.fromJson(res.data, fromJsonT);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final res = await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResponse.fromJson(res.data, fromJsonT);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final res = await dio.put(
        path,
        data: data,
        options: options,
      );
      return ApiResponse.fromJson(res.data, fromJsonT);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final res = await dio.patch(path, data: data);
      return ApiResponse.fromJson(res.data, fromJsonT);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final res = await dio.delete(path, data: data);
      return ApiResponse.fromJson(res.data, fromJsonT);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  void dispose() {
    _sessionExpiredController.close();
  }
}
