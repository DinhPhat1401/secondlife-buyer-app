import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  AppException({
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() => message;

  factory AppException.fromDio(DioException error) {
    final targetUrl = error.requestOptions.baseUrl;
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return AppException(
        message: 'Kết nối máy chủ quá hạn ($targetUrl). Vui lòng kiểm tra lại mạng.',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return AppException(
        message: 'Không thể kết nối đến máy chủ ($targetUrl). Vui lòng kiểm tra cổng mạng.',
      );
    }

    final response = error.response;
    if (response != null) {
      final statusCode = response.statusCode;
      String? message;
      String? errorCode;

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        message = data['message'] ?? data['error'];
        errorCode = data['errorCode'] ?? data['code'];

        if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
          final errorList = (data['errors'] as List).map((e) {
            if (e is Map) {
              final field = e['field']?.toString();
              final msg = e['message']?.toString() ?? '';
              if (field != null && field.isNotEmpty) {
                final vietnameseField = _fieldTranslations[field] ?? field;
                return '$vietnameseField ($msg)';
              }
              return msg;
            }
            return e.toString();
          }).where((s) => s.isNotEmpty).toList();

          if (errorList.isNotEmpty) {
            message = errorList.join(', ');
          }
        }
      } else if (response.data is String && (response.data as String).isNotEmpty) {
        message = response.data;
      }

      // Map domain error code
      if (errorCode != null && _errorCodeMessages.containsKey(errorCode)) {
        return AppException(
          message: _errorCodeMessages[errorCode]!,
          statusCode: statusCode,
          errorCode: errorCode,
        );
      }

      if (statusCode == 401) {
        final path = error.requestOptions.path;
        final isLogin = path.contains('/api/auth/login');
        return AppException(
          message: isLogin
              ? (message ?? 'Email hoặc mật khẩu không chính xác.')
              : 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          statusCode: 401,
        );
      }

      if (statusCode == 403) {
        return AppException(
          message: 'Bạn không có quyền thực hiện thao tác này.',
          statusCode: 403,
        );
      }

      if (statusCode == 429) {
        return AppException(
          message: message ?? 'Bạn đang thao tác quá nhanh trên hệ thống (giới hạn 30 yêu cầu/phút). Vui lòng thử lại sau 1 phút.',
          statusCode: 429,
          errorCode: errorCode,
        );
      }

      return AppException(
        message: message ?? 'Có lỗi xảy ra (Mã lỗi $statusCode)',
        statusCode: statusCode,
        errorCode: errorCode,
      );
    }

    return AppException(message: error.message ?? 'Đã xảy ra sự cố không xác định');
  }

  static const Map<String, String> _errorCodeMessages = {
    'EMAIL_ALREADY_EXISTS': 'Email này đã được đăng ký tài khoản khác.',
    'INVALID_CREDENTIALS': 'Email hoặc mật khẩu không chính xác.',
    'SELLER_NOT_VERIFIED': 'Tài khoản của bạn chưa hoàn tất định danh người bán eKYC.',
    'LISTING_CREDIT_EXHAUSTED': 'Bạn đã hết lượt đăng tin. Vui lòng mua thêm gói lượt đăng.',
    'VALUATION_CREDIT_EXHAUSTED': 'Bạn đã hết lượt định giá AI. Vui lòng mua thêm gói định giá.',
    'SIMILAR_LISTING_COOLDOWN': 'Bạn vừa đăng một sản phẩm tương tự trong 24h qua. Hãy sử dụng tính năng Đẩy tin (Re-up).',
    'WALLET_INSUFFICIENT_BALANCE': 'Số dư trong ví không đủ để thực hiện giao dịch này.',
    'INSPECTION_RESULT_IMMUTABLE': 'Biên bản kiểm định này đã nộp và không thể chỉnh sửa.',
  };

  static const Map<String, String> _fieldTranslations = {
    'categoryId': 'Danh mục sản phẩm',
    'images': 'Hình ảnh sản phẩm',
    'itemId': 'Loại thiết bị',
    'brand': 'Thương hiệu',
    'model': 'Mã model',
    'price': 'Giá bán',
    'title': 'Tiêu đề tin đăng',
    'description': 'Mô tả',
    'shippingWeight': 'Khối lượng đóng gói',
    'shippingLength': 'Chiều dài kiện hàng',
    'shippingWidth': 'Chiều rộng kiện hàng',
    'shippingHeight': 'Chiều cao kiện hàng',
  };
}
