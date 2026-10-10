import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../routes/app_routes.dart';
import '../storage/auth_storage.dart';
import '../theme/app_colors.dart';
import 'api_exception.dart';
import 'api_response.dart';

class ApiClient {
  static bool _isSessionExpiredDialogShowing = false;
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
      return _handleResponse(response, fromJson, path: path);
    } catch (e) {
      debugPrint('[API GET Error]: ${e.toString()}');
      return _handleCatchError<T>(e);
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
      return _handleResponse(response, fromJson, path: path);
    } catch (e) {
      debugPrint('[API POST Error]: ${e.toString()}');
      return _handleCatchError<T>(e);
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
      return _handleResponse(response, fromJson, path: path);
    } catch (e) {
      debugPrint('[API Multipart Error]: ${e.toString()}');
      return _handleCatchError<T>(e);
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
      return _handleResponse(response, fromJson, path: path);
    } catch (e) {
      debugPrint('[API PUT Error]: ${e.toString()}');
      return _handleCatchError<T>(e);
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
      return _handleResponse(response, fromJson, path: path);
    } catch (e) {
      debugPrint('[API DELETE Error]: ${e.toString()}');
      return _handleCatchError<T>(e);
    }
  }

  ApiResponse<T> _handleCatchError<T>(dynamic e) {
    final errStr = e.toString().toLowerCase();
    String message = 'Server unreachable or connection error. Please try again later.';
    if (errStr.contains('socketexception') ||
        errStr.contains('clientexception') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('connection refused') ||
        errStr.contains('connection timed out') ||
        errStr.contains('network is unreachable') ||
        errStr.contains('timeout')) {
      message = 'No Internet Connection. Please check your network connection and try again.';
    } else if (e is ApiException) {
      message = e.message;
    }

    return ApiResponse<T>(
      success: false,
      message: message,
    );
  }

  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson, {
    String? path,
  }) {
    dynamic jsonResponseBody;
    try {
      jsonResponseBody = jsonDecode(response.body);
    } catch (_) {
      return ApiResponse<T>(
        success: false,
        message: 'Invalid response format from server (${response.statusCode})',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse.fromJson(jsonResponseBody, fromJson);
    } else {
      String errorMessage = '';

      // 1. Extract error messages from Laravel 'errors' map/list if available
      final errorsObj = jsonResponseBody is Map ? jsonResponseBody['errors'] : null;
      if (errorsObj is Map && errorsObj.isNotEmpty) {
        final List<String> extractedErrors = [];
        errorsObj.forEach((key, value) {
          if (value is List) {
            for (var item in value) {
              if (item != null && item.toString().trim().isNotEmpty) {
                extractedErrors.add(item.toString().trim());
              }
            }
          } else if (value != null && value.toString().trim().isNotEmpty) {
            extractedErrors.add(value.toString().trim());
          }
        });
        if (extractedErrors.isNotEmpty) {
          errorMessage = extractedErrors.join('\n');
        }
      }

      // 2. Fallback to 'message' property if 'errors' wasn't present or empty
      if (errorMessage.isEmpty && jsonResponseBody is Map && jsonResponseBody.containsKey('message')) {
        final msgStr = jsonResponseBody['message'].toString().trim();
        if (msgStr.isNotEmpty && msgStr.toLowerCase() != 'the given data was invalid.') {
          errorMessage = msgStr;
        }
      }

      // 3. Ultimate fallback
      if (errorMessage.isEmpty) {
        if (jsonResponseBody is Map && jsonResponseBody.containsKey('message')) {
          errorMessage = jsonResponseBody['message'].toString();
        } else {
          errorMessage = 'Request failed with status code ${response.statusCode}';
        }
      }

      if (response.statusCode == 403 || response.statusCode == 401) {
        final lowerMsg = errorMessage.toLowerCase();
        final requestPath = path ?? response.request?.url.path ?? '';
        final isAuthEndpoint = requestPath.contains('/login') ||
            requestPath.contains('/register') ||
            requestPath.contains('/forgot-password') ||
            requestPath.contains('/reset-password');
        final isInvalidCredentials = lowerMsg.contains('invalid mobile') ||
            lowerMsg.contains('invalid password') ||
            lowerMsg.contains('invalid credentials') ||
            lowerMsg.contains('invalid email') ||
            lowerMsg.contains('incorrect password');

        if (lowerMsg.contains('deactivated')) {
          _authStorage.clearSession();
          AppRoutes.navigatorKey.currentState?.pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
            arguments: errorMessage,
          );
        } else if ((response.statusCode == 401 || lowerMsg.contains('unauthenticated')) &&
            !isAuthEndpoint &&
            !isInvalidCredentials) {
          _handleUnauthorizedSession(errorMessage);
        }
      }

      return ApiResponse<T>(
        success: false,
        message: errorMessage,
        errors: jsonResponseBody is Map ? jsonResponseBody['errors'] : null,
      );
    }
  }

  void _handleUnauthorizedSession(String serverMessage) {
    _authStorage.clearSession();

    if (_isSessionExpiredDialogShowing) return;
    _isSessionExpiredDialogShowing = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = AppRoutes.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.devices_rounded, color: Colors.orange, size: 28),
                  SizedBox(width: 8),
                  Text('Session Expired', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: const Text(
                'You have been logged out because your account was logged in from another device.',
                style: TextStyle(fontSize: 14),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    _isSessionExpiredDialogShowing = false;
                    Navigator.of(dialogCtx, rootNavigator: true).pop();
                    AppRoutes.navigatorKey.currentState?.pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (route) => false,
                      arguments: 'Session expired: Account logged in on another device.',
                    );
                  },
                  child: const Text('Log In Again'),
                ),
              ],
            );
          },
        ).then((_) {
          _isSessionExpiredDialogShowing = false;
        });
      } else {
        _isSessionExpiredDialogShowing = false;
        AppRoutes.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
          arguments: 'Session expired: Account logged in on another device.',
        );
      }
    });
  }
}