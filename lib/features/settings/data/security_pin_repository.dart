import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/storage/auth_storage.dart';

class SecurityPinRepository {
  final ApiClient _apiClient = ApiClient();
  final AuthStorage _authStorage = AuthStorage();

  /// Check whether the current shop owner has a security PIN set up.
  Future<ApiResponse<bool>> checkStatus() async {
    final response = await _apiClient.get(ApiEndpoints.securityPinStatus);
    if (response.success && response.data != null) {
      final dynamic raw = response.data;
      bool hasPin = false;
      if (raw is Map && raw['data'] is Map) {
        hasPin = raw['data']['has_security_pin'] == true;
      } else if (raw is Map) {
        hasPin = raw['has_security_pin'] == true;
      }
      await _authStorage.updateHasSecurityPin(hasPin);
      return ApiResponse<bool>(success: true, message: response.message, data: hasPin);
    }
    return ApiResponse<bool>(success: false, message: response.message, data: false);
  }

  /// Setup security PIN for the first time using account login password.
  Future<ApiResponse<bool>> setupPin({
    required String password,
    required String pin,
    required String pinConfirmation,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.securityPinSetup,
      body: {
        'password': password,
        'pin': pin,
        'pin_confirmation': pinConfirmation,
      },
    );

    if (response.success) {
      await _authStorage.updateHasSecurityPin(true);
      return ApiResponse<bool>(success: true, message: response.message, data: true);
    }
    return ApiResponse<bool>(success: false, message: response.message, data: false);
  }

  /// Update existing security PIN using current PIN.
  Future<ApiResponse<bool>> updatePin({
    required String currentPin,
    required String pin,
    required String pinConfirmation,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.securityPinUpdate,
      body: {
        'current_pin': currentPin,
        'pin': pin,
        'pin_confirmation': pinConfirmation,
      },
    );

    if (response.success) {
      await _authStorage.updateHasSecurityPin(true);
      return ApiResponse<bool>(success: true, message: response.message, data: true);
    }
    return ApiResponse<bool>(success: false, message: response.message, data: false);
  }

  /// Reset/Forgot security PIN using account login password.
  Future<ApiResponse<bool>> forgotPin({
    required String password,
    required String pin,
    required String pinConfirmation,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.securityPinForgot,
      body: {
        'password': password,
        'pin': pin,
        'pin_confirmation': pinConfirmation,
      },
    );

    if (response.success) {
      await _authStorage.updateHasSecurityPin(true);
      return ApiResponse<bool>(success: true, message: response.message, data: true);
    }
    return ApiResponse<bool>(success: false, message: response.message, data: false);
  }

  /// Verify security PIN
  Future<ApiResponse<bool>> verifyPin(String pin) async {
    final response = await _apiClient.post(
      ApiEndpoints.securityPinVerify,
      body: {'pin': pin},
    );

    if (response.success) {
      return ApiResponse<bool>(success: true, message: response.message, data: true);
    }
    return ApiResponse<bool>(success: false, message: response.message, data: false);
  }
}
