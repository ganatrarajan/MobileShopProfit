class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? rawJson;
  final dynamic errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.rawJson,
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

    final bool isSuccess = (json['success'] == true) || (json['status'] == 'success');

    return ApiResponse<T>(
      success: isSuccess,
      message: json['message'] ?? '',
      data: payload as T?,
      rawJson: json,
      errors: json['errors'],
    );
  }
}
