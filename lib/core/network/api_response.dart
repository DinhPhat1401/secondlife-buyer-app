class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? timestamp;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.timestamp,
  });

  factory ApiResponse.fromJson(
    dynamic json,
    T Function(dynamic json)? fromJsonT,
  ) {
    if (json == null) {
      return ApiResponse<T>(success: true, message: '', data: null);
    }
    if (json is List) {
      return ApiResponse<T>(
        success: true,
        message: '',
        data: fromJsonT != null ? fromJsonT(json) : json as T?,
      );
    }
    if (json is Map<String, dynamic>) {
      final success = json['success'] as bool? ?? true;
      final message = json['message'] as String? ?? '';
      final timestamp = json['timestamp'] as String?;

      if (json.containsKey('success') && !success && !json.containsKey('data')) {
        return ApiResponse<T>(
          success: false,
          message: message,
          data: null,
          timestamp: timestamp,
        );
      }

      final hasDataKey = json.containsKey('data');
      final rawData = hasDataKey ? json['data'] : json;

      return ApiResponse<T>(
        success: success,
        message: message,
        data: rawData != null && fromJsonT != null ? fromJsonT(rawData) : rawData as T?,
        timestamp: timestamp,
      );
    }

    return ApiResponse<T>(
      success: true,
      message: '',
      data: fromJsonT != null ? fromJsonT(json) : json as T?,
    );
  }
}

class PageResponse<T> {
  final List<T> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool isLast;

  PageResponse({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.isLast,
  });

  factory PageResponse.fromJson(
    dynamic json,
    T Function(dynamic item) fromJsonItem,
  ) {
    if (json == null) {
      return PageResponse<T>(items: [], page: 0, size: 0, totalElements: 0, totalPages: 0, isLast: true);
    }
    if (json is List) {
      final items = json.map((i) => fromJsonItem(i)).toList();
      return PageResponse<T>(
        items: items,
        page: 0,
        size: items.length,
        totalElements: items.length,
        totalPages: 1,
        isLast: true,
      );
    }
    if (json is Map<String, dynamic>) {
      final rawData = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
      final rawList = rawData['items'] ?? rawData['content'] ?? [];
      final List<T> items = (rawList as List).map((i) => fromJsonItem(i)).toList();

      final page = rawData['page'] ?? rawData['number'] ?? rawData['pageNumber'] ?? 0;
      final size = rawData['size'] ?? rawData['pageSize'] ?? (items.isNotEmpty ? items.length : 10);
      final totalElements = rawData['totalElements'] ?? items.length;
      final totalPages = rawData['totalPages'] ?? 1;
      final isLast = rawData['isLast'] ?? rawData['last'] ?? (page >= totalPages - 1);

      return PageResponse<T>(
        items: items,
        page: (page as num).toInt(),
        size: (size as num).toInt(),
        totalElements: (totalElements as num).toInt(),
        totalPages: (totalPages as num).toInt(),
        isLast: isLast as bool,
      );
    }
    return PageResponse<T>(items: [], page: 0, size: 0, totalElements: 0, totalPages: 0, isLast: true);
  }
}
