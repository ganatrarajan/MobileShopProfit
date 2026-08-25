class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final dynamic errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? create,
  ) {
    dynamic payload;
    if (create != null) {
      payload = create(json.containsKey('data') ? json['data'] : json);
    } else {
      payload = json.containsKey('data') ? json['data'] : json;
    }

    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: payload as T?,
      errors: json['errors'],
    );
  }
}