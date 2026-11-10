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
    final body = <String, dynamic>{
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
      return ApiResponse<Technician>(
        success: true,
        message: response.message,
        data: tech,
        rawJson: response.rawJson,
      );
    }

    return ApiResponse<Technician>(
      success: false,
      message: response.message,
      rawJson: response.rawJson,
      errors: response.errors,
    );
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
      return ApiResponse<Technician>(
        success: true,
        message: response.message,
        data: tech,
        rawJson: response.rawJson,
      );
    }

    return ApiResponse<Technician>(
      success: false,
      message: response.message,
      rawJson: response.rawJson,
      errors: response.errors,
    );
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
      return ApiResponse<Technician>(
        success: true,
        message: response.message,
        data: tech,
        rawJson: response.rawJson,
      );
    }

    return ApiResponse<Technician>(
      success: false,
      message: response.message,
      rawJson: response.rawJson,
      errors: response.errors,
    );
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

  /// Get logged-in technician's own work & profit summary
  Future<ApiResponse<TechnicianWorkSummaryData>> getMyWorkSummary({
    int? technicianId,
    String? month,
    String? status,
  }) async {
    final queryParams = <String, String>{
      if (technicianId != null) 'technician_id': technicianId.toString(),
      if (month != null && month.isNotEmpty) 'month': month,
      if (status != null && status.isNotEmpty && status != 'all') 'status': status,
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final path = queryString.isNotEmpty
        ? '${ApiEndpoints.technicianMyWork}?$queryString'
        : ApiEndpoints.technicianMyWork;

    final response = await _apiClient.get(path);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> dataMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : (rawData is Map ? Map<String, dynamic>.from(rawData) : {});

      final summary = TechnicianWorkSummaryData.fromJson(dataMap);
      return ApiResponse<TechnicianWorkSummaryData>(
        success: true,
        message: response.message,
        data: summary,
        rawJson: response.rawJson,
      );
    }

    return ApiResponse<TechnicianWorkSummaryData>(
      success: false,
      message: response.message,
    );
  }
}

class TechnicianJobItem {
  final int id;
  final String jobNumber;
  final String customerName;
  final String? customerMobile;
  final String deviceName;
  final String problemDescription;
  final String repairStatus;
  final double technicianEarning;
  final double technicianPayable;
  final double finalCost;
  final DateTime? createdAt;
  final DateTime? completedAt;

  TechnicianJobItem({
    required this.id,
    required this.jobNumber,
    required this.customerName,
    this.customerMobile,
    required this.deviceName,
    required this.problemDescription,
    required this.repairStatus,
    required this.technicianEarning,
    required this.technicianPayable,
    required this.finalCost,
    this.createdAt,
    this.completedAt,
  });

  factory TechnicianJobItem.fromJson(Map<String, dynamic> json) {
    double parseDbl(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    DateTime? parseDt(dynamic val) {
      if (val == null) return null;
      return DateTime.tryParse(val.toString());
    }

    return TechnicianJobItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      jobNumber: json['job_number']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'Walk-in Customer',
      customerMobile: json['customer_mobile']?.toString(),
      deviceName: json['device_name']?.toString() ?? 'Device',
      problemDescription: json['problem_description']?.toString() ?? '',
      repairStatus: json['repair_status']?.toString() ?? 'received',
      technicianEarning: parseDbl(json['technician_earning']),
      technicianPayable: parseDbl(json['technician_payable']),
      finalCost: parseDbl(json['final_cost']),
      createdAt: parseDt(json['created_at']),
      completedAt: parseDt(json['completed_at']),
    );
  }
}

class TechnicianMonthOption {
  final String key;
  final String label;

  TechnicianMonthOption({required this.key, required this.label});

  factory TechnicianMonthOption.fromJson(Map<String, dynamic> json) {
    return TechnicianMonthOption(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class TechnicianWorkMetrics {
  final double periodEarnings;
  final int periodJobs;
  final int periodCompleted;
  final int periodInProgress;
  final int periodPending;
  final double allTimeEarnings;
  final double allTimePaid;
  final double balanceDue;

  TechnicianWorkMetrics({
    this.periodEarnings = 0.0,
    this.periodJobs = 0,
    this.periodCompleted = 0,
    this.periodInProgress = 0,
    this.periodPending = 0,
    this.allTimeEarnings = 0.0,
    this.allTimePaid = 0.0,
    this.balanceDue = 0.0,
  });

  factory TechnicianWorkMetrics.fromJson(Map<String, dynamic> json) {
    double parseDbl(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    return TechnicianWorkMetrics(
      periodEarnings: parseDbl(json['period_earnings']),
      periodJobs: parseInt(json['period_jobs']),
      periodCompleted: parseInt(json['period_completed']),
      periodInProgress: parseInt(json['period_in_progress']),
      periodPending: parseInt(json['period_pending']),
      allTimeEarnings: parseDbl(json['all_time_earnings']),
      allTimePaid: parseDbl(json['all_time_paid']),
      balanceDue: parseDbl(json['balance_due']),
    );
  }
}

class TechnicianWorkSummaryData {
  final String technicianName;
  final String? specialization;
  final String? mobile;
  final TechnicianWorkMetrics metrics;
  final List<TechnicianMonthOption> availableMonths;
  final List<TechnicianJobItem> repairs;
  final String selectedMonth;
  final String selectedStatus;

  TechnicianWorkSummaryData({
    required this.technicianName,
    this.specialization,
    this.mobile,
    required this.metrics,
    required this.availableMonths,
    required this.repairs,
    required this.selectedMonth,
    required this.selectedStatus,
  });

  factory TechnicianWorkSummaryData.fromJson(Map<String, dynamic> json) {
    final techMap = json['technician'] is Map ? json['technician'] : {};
    final metricsMap = json['metrics'] is Map ? json['metrics'] : {};
    final filtersMap = json['filters'] is Map ? json['filters'] : {};

    final List rawMonths = json['available_months'] is List ? json['available_months'] : [];
    final List rawRepairs = json['repairs'] is List ? json['repairs'] : [];

    return TechnicianWorkSummaryData(
      technicianName: techMap['name']?.toString() ?? 'Technician',
      specialization: techMap['specialization']?.toString(),
      mobile: techMap['mobile']?.toString(),
      metrics: TechnicianWorkMetrics.fromJson(Map<String, dynamic>.from(metricsMap)),
      availableMonths: rawMonths.map((m) => TechnicianMonthOption.fromJson(Map<String, dynamic>.from(m))).toList(),
      repairs: rawRepairs.map((r) => TechnicianJobItem.fromJson(Map<String, dynamic>.from(r))).toList(),
      selectedMonth: filtersMap['month']?.toString() ?? 'this_month',
      selectedStatus: filtersMap['status']?.toString() ?? 'all',
    );
  }
}