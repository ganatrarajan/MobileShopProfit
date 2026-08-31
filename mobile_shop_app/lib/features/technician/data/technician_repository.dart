import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/technician.dart';
import '../models/technician_payment.dart';

class TechnicianSummary {
  final int totalTechnicians;
  final int activeTechnicians;
  final int inProgressJobs;
  final int pendingJobs;
  final int completedJobs;

  TechnicianSummary({
    required this.totalTechnicians,
    required this.activeTechnicians,
    required this.inProgressJobs,
    required this.pendingJobs,
    required this.completedJobs,
  });

  factory TechnicianSummary.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    return TechnicianSummary(
      totalTechnicians: parseInt(json['total_technicians']),
      activeTechnicians: parseInt(json['active_technicians']),
      inProgressJobs: parseInt(json['in_progress_jobs']),
      pendingJobs: parseInt(json['pending_jobs']),
      completedJobs: parseInt(json['completed_jobs']),
    );
  }
}

class TechnicianListResponse {
  final TechnicianSummary summary;
  final List<Technician> technicians;

  TechnicianListResponse({
    required this.summary,
    required this.technicians,
  });
}

class TechnicianRepository {
  final ApiClient _apiClient = ApiClient();

  /// Get technicians with search and status filter
  Future<ApiResponse<TechnicianListResponse>> getTechnicians({
    String? search,
    String? status,
  }) async {
    final queryParams = <String, String>{
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty && status != 'all') 'status': status,
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final path = queryString.isNotEmpty
        ? '${ApiEndpoints.technicians}?$queryString'
        : ApiEndpoints.technicians;

    final response = await _apiClient.get(path);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      List rawList = [];
      Map<String, dynamic> summaryMap = {};

      if (rawData is List) {
        rawList = rawData;
      } else if (rawData is Map) {
        if (rawData['data'] is List) rawList = rawData['data'];
        if (rawData['summary'] is Map) summaryMap = Map<String, dynamic>.from(rawData['summary']);
      }

      final rawJson = response.rawJson;
      if (rawJson != null && summaryMap.isEmpty && rawJson['summary'] is Map) {
        summaryMap = Map<String, dynamic>.from(rawJson['summary']);
      }

      final technicians = rawList.map((t) => Technician.fromJson(Map<String, dynamic>.from(t))).toList();
      final summary = TechnicianSummary.fromJson(summaryMap);

      return ApiResponse<TechnicianListResponse>(
        success: true,
        message: response.message,
        data: TechnicianListResponse(summary: summary, technicians: technicians),
        rawJson: rawJson,
      );
    }

    return ApiResponse<TechnicianListResponse>(
      success: false,
      message: response.message,
    );
  }

  /// Create new technician
  Future<ApiResponse<Technician>> createTechnician({
    required String name,
    String? mobile,
    String? specialization,
    bool isActive = true,
  }) async {
    final body = {
      'name': name,
      if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
      if (specialization != null && specialization.isNotEmpty) 'specialization': specialization,
      'is_active': isActive,
    };

    final response = await _apiClient.post(ApiEndpoints.technicians, body: body);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> itemMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final tech = Technician.fromJson(itemMap);
      return ApiResponse<Technician>(success: true, message: response.message, data: tech);
    }

    return ApiResponse<Technician>(success: false, message: response.message);
  }

  /// Get technician details & recent jobs
  Future<ApiResponse<Technician>> getTechnicianDetails(int id) async {
    final response = await _apiClient.get('${ApiEndpoints.technicians}/$id');

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> itemMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final tech = Technician.fromJson(itemMap);
      return ApiResponse<Technician>(success: true, message: response.message, data: tech);
    }

    return ApiResponse<Technician>(success: false, message: response.message);
  }

  /// Update technician details
  Future<ApiResponse<Technician>> updateTechnician({
    required int id,
    String? name,
    String? mobile,
    String? specialization,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (mobile != null) 'mobile': mobile,
      if (specialization != null) 'specialization': specialization,
      if (isActive != null) 'is_active': isActive,
    };

    final response = await _apiClient.put('${ApiEndpoints.technicians}/$id', body: body);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> itemMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final tech = Technician.fromJson(itemMap);
      return ApiResponse<Technician>(success: true, message: response.message, data: tech);
    }

    return ApiResponse<Technician>(success: false, message: response.message);
  }

  /// Delete technician
  Future<ApiResponse<void>> deleteTechnician(int id) async {
    final response = await _apiClient.delete('${ApiEndpoints.technicians}/$id');
    return ApiResponse<void>(
      success: response.success,
      message: response.message,
    );
  }

  /// Record a payout to a technician
  Future<ApiResponse<TechnicianPayment>> recordPayment({
    required int technicianId,
    int? repairId,
    required double amount,
    DateTime? paymentDate,
    String? paymentMethod,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'technician_id': technicianId,
      if (repairId != null) 'repair_id': repairId,
      'amount': amount,
      'payment_date': (paymentDate ?? DateTime.now()).toIso8601String().split('T').first,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (notes != null) 'notes': notes,
    };

    final response = await _apiClient.post('/technician-payments', body: body);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> itemMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final payment = TechnicianPayment.fromJson(itemMap);
      return ApiResponse<TechnicianPayment>(success: true, message: response.message, data: payment);
    }

    return ApiResponse<TechnicianPayment>(success: false, message: response.message);
  }

  /// Get technician payment history
  Future<ApiResponse<List<TechnicianPayment>>> getPaymentHistory(int technicianId) async {
    final response = await _apiClient.get('${ApiEndpoints.technicians}/$technicianId/payments');

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      List rawList = [];
      if (rawData is Map && rawData['data'] is Map && rawData['data']['data'] is List) {
        rawList = rawData['data']['data'];
      } else if (rawData is Map && rawData['data'] is List) {
        rawList = rawData['data'];
      } else if (rawData is List) {
        rawList = rawData;
      }

      final payments = rawList.map((p) => TechnicianPayment.fromJson(Map<String, dynamic>.from(p))).toList();
      return ApiResponse<List<TechnicianPayment>>(success: true, message: response.message, data: payments);
    }

    return ApiResponse<List<TechnicianPayment>>(success: false, message: response.message, data: []);
  }
}