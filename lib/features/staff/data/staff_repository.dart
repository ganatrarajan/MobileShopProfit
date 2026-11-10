import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/staff.dart';

class StaffSummary {
  final int totalStaff;
  final int activeStaff;
  final int staffAccountsUsed;
  final int maxStaffAllowed;
  final String? staffValidUntil;
  final int staffDaysRemaining;
  final bool isStaffExpired;
  final double staffPricePerDay;

  StaffSummary({
    required this.totalStaff,
    required this.activeStaff,
    this.staffAccountsUsed = 0,
    this.maxStaffAllowed = 0,
    this.staffValidUntil,
    this.staffDaysRemaining = 0,
    this.isStaffExpired = false,
    this.staffPricePerDay = 2.0,
  });

  factory StaffSummary.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    double parseDouble(dynamic val) {
      if (val == null) return 2.0;
      if (val is double) return val;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 2.0;
    }

    return StaffSummary(
      totalStaff: parseInt(json['total_staff']),
      activeStaff: parseInt(json['active_staff']),
      staffAccountsUsed: parseInt(json['staff_accounts_used']),
      maxStaffAllowed: parseInt(json['max_staff_allowed']),
      staffValidUntil: json['staff_valid_until']?.toString(),
      staffDaysRemaining: parseInt(json['staff_days_remaining']),
      isStaffExpired: json['is_staff_expired'] == true,
      staffPricePerDay: parseDouble(json['staff_price_per_day']),
    );
  }
}

class StaffListResponse {
  final StaffSummary summary;
  final List<Staff> staff;

  StaffListResponse({
    required this.summary,
    required this.staff,
  });
}

class StaffRepository {
  final ApiClient _apiClient = ApiClient();

  /// Get staff list with optional search and status filter
  Future<ApiResponse<StaffListResponse>> getStaffList({
    String? search,
    String? status,
  }) async {
    final queryParams = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (status != null && status != 'all') {
      queryParams['status'] = status;
    }

    final response = await _apiClient.get(
      ApiEndpoints.staff,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.success) {
      final rootJson = response.rawJson is Map
          ? Map<String, dynamic>.from(response.rawJson!)
          : (response.data is Map ? Map<String, dynamic>.from(response.data) : <String, dynamic>{});
      final List<Staff> items = [];

      final dynamic listSource = response.data is List
          ? response.data
          : (rootJson['data'] is List ? rootJson['data'] : null);

      if (listSource is List) {
        items.addAll(
          listSource
              .map((item) => Staff.fromJson(Map<String, dynamic>.from(item)))
              .toList(),
        );
      }

      final summaryJson = rootJson['summary'] is Map
          ? Map<String, dynamic>.from(rootJson['summary'])
          : null;

      final summary = summaryJson != null
          ? StaffSummary.fromJson(summaryJson)
          : StaffSummary(
              totalStaff: items.length,
              activeStaff: items.where((s) => s.isActive).length,
              maxStaffAllowed: 0,
            );

      return ApiResponse<StaffListResponse>(
        success: true,
        message: response.message,
        data: StaffListResponse(summary: summary, staff: items),
        rawJson: response.rawJson,
      );
    }

    return ApiResponse<StaffListResponse>(
      success: false,
      message: response.message,
      rawJson: response.rawJson,
      errors: response.errors,
    );
  }

  /// Get single staff details
  Future<ApiResponse<Staff>> getStaffDetails(int id) async {
    final response = await _apiClient.get('${ApiEndpoints.staff}/$id');

    if (response.success && response.data != null) {
      final rawData = response.data;
      if (rawData is Map && rawData['data'] is Map) {
        return ApiResponse<Staff>(
          success: true,
          message: response.message,
          data: Staff.fromJson(Map<String, dynamic>.from(rawData['data'])),
          rawJson: response.rawJson,
        );
      }
    }

    return ApiResponse<Staff>(
      success: false,
      message: response.message,
      rawJson: response.rawJson,
      errors: response.errors,
    );
  }

  /// Create a new staff member with app login credentials
  Future<ApiResponse<Staff>> createStaff({
    required String name,
    required String mobile,
    String? email,
    required String password,
    String? designation,
    double? salary,
    String? joiningDate,
    String? address,
    String? notes,
    bool isActive = true,
    Map<String, bool>? permissions,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'mobile': mobile.trim(),
      'password': password,
      'is_active': isActive,
    };

    if (email != null && email.trim().isNotEmpty) {
      body['email'] = email.trim();
    }
    if (designation != null && designation.trim().isNotEmpty) {
      body['designation'] = designation.trim();
    }
    if (salary != null) {
      body['salary'] = salary;
    }
    if (joiningDate != null && joiningDate.trim().isNotEmpty) {
      body['joining_date'] = joiningDate.trim();
    }
    if (address != null && address.trim().isNotEmpty) {
      body['address'] = address.trim();
    }
    if (notes != null && notes.trim().isNotEmpty) {
      body['notes'] = notes.trim();
    }
    if (permissions != null) {
      body['permissions'] = permissions;
    }

    final response = await _apiClient.post(
      ApiEndpoints.staff,
      body: body,
    );

    if (response.success && response.data != null) {
      final rawData = response.data;
      if (rawData is Map && rawData['data'] is Map) {
        return ApiResponse<Staff>(
          success: true,
          message: response.message,
          data: Staff.fromJson(Map<String, dynamic>.from(rawData['data'])),
          rawJson: response.rawJson,
        );
      }
    }

    return ApiResponse<Staff>(
      success: false,
      message: response.message,
      rawJson: response.rawJson,
      errors: response.errors,
    );
  }

  /// Update an existing staff member
  Future<ApiResponse<Staff>> updateStaff({
    required int id,
    required String name,
    required String mobile,
    String? email,
    String? password,
    String? designation,
    double? salary,
    String? joiningDate,
    String? address,
    String? notes,
    bool? isActive,
    Map<String, bool>? permissions,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'mobile': mobile.trim(),
    };

    if (email != null) {
      body['email'] = email.trim().isEmpty ? null : email.trim();
    }
    if (password != null && password.trim().isNotEmpty) {
      body['password'] = password;
    }
    if (designation != null) {
      body['designation'] = designation.trim();
    }
    if (salary != null) {
      body['salary'] = salary;
    }
    if (joiningDate != null) {
      body['joining_date'] = joiningDate.trim();
    }
    if (address != null) {
      body['address'] = address.trim();
    }
    if (notes != null) {
      body['notes'] = notes.trim();
    }
    if (isActive != null) {
      body['is_active'] = isActive;
    }
    if (permissions != null) {
      body['permissions'] = permissions;
    }

    final response = await _apiClient.put(
      '${ApiEndpoints.staff}/$id',
      body: body,
    );

    if (response.success && response.data != null) {
      final rawData = response.data;
      if (rawData is Map && rawData['data'] is Map) {
        return ApiResponse<Staff>(
          success: true,
          message: response.message,
          data: Staff.fromJson(Map<String, dynamic>.from(rawData['data'])),
          rawJson: response.rawJson,
        );
      }
    }

    return ApiResponse<Staff>(
      success: false,
      message: response.message,
      rawJson: response.rawJson,
      errors: response.errors,
    );
  }

  /// Delete a staff member and revoke access
  Future<ApiResponse<bool>> deleteStaff(int id) async {
    final response = await _apiClient.delete('${ApiEndpoints.staff}/$id');
    if (response.success) {
      return ApiResponse<bool>(
        success: true,
        message: response.message,
        data: true,
        rawJson: response.rawJson,
      );
    }
    return ApiResponse<bool>(
      success: false,
      message: response.message,
      rawJson: response.rawJson,
      errors: response.errors,
    );
  }
}
