import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../routes/app_routes.dart';
import '../storage/auth_storage.dart';
import 'api_exception.dart';
import 'api_response.dart';

class ApiClient {
  final AuthStorage _authStorage = AuthStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authStorage.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      debugPrint('[API Auth]: Attached Bearer token (${token.length > 10 ? token.substring(0, 10) : token}...)');
    } else {
      debugPrint('[API Auth]: NO TOKEN FOUND IN STORAGE');
    }
    return headers;
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      var uri = Uri.parse('${EnvConfig.baseUrl}$path');
      if (queryParameters != null && queryParameters.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParameters);
      }
      final headers = await _getHeaders();
      debugPrint('[API GET] Requesting: $uri');
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
      debugPrint('[API GET] Response (${response.statusCode}): ${response.body}');
      return _handleResponse(response, fromJson);
    } catch (e) {
      debugPrint('[API GET Error]: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to connect to local Laravel server: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${EnvConfig.baseUrl}$path');
      final headers = await _getHeaders();
      debugPrint('[API POST] Requesting: $uri');
      if (body != null) debugPrint('[API Body]: ${jsonEncode(body)}');

      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));

      debugPrint('[API POST] Response (${response.statusCode}): ${response.body}');
      return _handleResponse(response, fromJson);
    } catch (e) {
      debugPrint('[API POST Error]: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to connect to local Laravel server: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> postMultipart<T>(
    String path, {
    required String filePath,
    required String fileFieldName,
    Map<String, String>? fields,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${EnvConfig.baseUrl}$path');
      final token = await _authStorage.getToken();

      debugPrint('[API Multipart POST] Requesting: $uri');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Accept'] = 'application/json';
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      if (fields != null) {
        request.fields.addAll(fields);
      }

      request.files.add(await http.MultipartFile.fromPath(fileFieldName, filePath));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('[API Multipart POST] Response (${response.statusCode}): ${response.body}');
      return _handleResponse(response, fromJson);
    } catch (e) {
      debugPrint('[API Multipart Error]: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to upload file to local server: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${EnvConfig.baseUrl}$path');
      final headers = await _getHeaders();
      debugPrint('[API PUT] Requesting: $uri');
      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));
      debugPrint('[API PUT] Response (${response.statusCode}): ${response.body}');
      return _handleResponse(response, fromJson);
    } catch (e) {
      debugPrint('[API PUT Error]: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to connect to local Laravel server: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${EnvConfig.baseUrl}$path');
      final headers = await _getHeaders();
      debugPrint('[API DELETE] Requesting: $uri');
      final response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 15));
      debugPrint('[API DELETE] Response (${response.statusCode}): ${response.body}');
      return _handleResponse(response, fromJson);
    } catch (e) {
      debugPrint('[API DELETE Error]: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to connect to local Laravel server: ${e.toString()}');
    }
  }

  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) {
    dynamic jsonResponseBody;
    try {
      jsonResponseBody = jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        message: 'Invalid response format from server (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse.fromJson(jsonResponseBody, fromJson);
    } else {
      final message = jsonResponseBody['message'] ?? 'Request failed with status code ${response.statusCode}';

      if (response.statusCode == 403 || response.statusCode == 401) {
        _authStorage.clearSession();
        AppRoutes.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
          arguments: message,
        );
      }

      throw ApiException(
        message: message,
        statusCode: response.statusCode,
        errors: jsonResponseBody['errors'],
      );
    }
  }
}
