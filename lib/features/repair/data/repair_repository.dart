import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/repair.dart';

class RepairRepository {
  final ApiClient _apiClient = ApiClient();

  /// Get paginated list of repair job cards
  Future<ApiResponse<List<Repair>>> getRepairs({
    String? search,
    String? repairStatus,
    int? customerId,
    String? dateFrom,
    String? dateTo,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (repairStatus != null && repairStatus.isNotEmpty && repairStatus != 'all') 'repair_status': repairStatus,
      if (customerId != null) 'customer_id': customerId.toString(),
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final path = '${ApiEndpoints.repairs}?$queryString';

    final response = await _apiClient.get(path);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      List rawList = [];
      if (rawData is List) {
        rawList = rawData;
      } else if (rawData is Map && rawData['data'] is List) {
        rawList = rawData['data'];
      }

      final repairs = rawList.map((item) => Repair.fromJson(Map<String, dynamic>.from(item))).toList();
      return ApiResponse<List<Repair>>(success: true, message: response.message, data: repairs);
    }

    return ApiResponse<List<Repair>>(success: false, message: response.message);
  }

  /// Create a new repair job card
  Future<ApiResponse<Repair>> createRepair({
    required int customerId,
    required int deviceId,
    required String problemDescription,
    List<String>? deviceCondition,
    String? conditionNotes,
    List<String>? accessoriesReceived,
    String? accessoriesNotes,
    String? pinPasscode,
    String? dateReceived,
    String? expectedDeliveryDate,
    double estimatedCost = 0.0,
    double finalCost = 0.0,
    double labourCost = 0.0,
    double paymentAmount = 0.0,
    String paymentMethod = 'cash',
    String? paymentNotes,
    String? customerNotes,
    String? internalNotes,
  }) async {
    final body = {
      'customer_id': customerId,
      'device_id': deviceId,
      'problem_description': problemDescription,
      if (deviceCondition != null) 'device_condition': deviceCondition,
      if (conditionNotes != null && conditionNotes.isNotEmpty) 'condition_notes': conditionNotes,
      if (accessoriesReceived != null) 'accessories_received': accessoriesReceived,
      if (accessoriesNotes != null && accessoriesNotes.isNotEmpty) 'accessories_notes': accessoriesNotes,
      if (pinPasscode != null && pinPasscode.isNotEmpty) 'pin_passcode': pinPasscode,
      if (dateReceived != null) 'date_received': dateReceived,
      if (expectedDeliveryDate != null) 'expected_delivery_date': expectedDeliveryDate,
      'estimated_cost': estimatedCost,
      if (finalCost > 0) 'final_cost': finalCost,
      if (labourCost > 0) 'labour_cost': labourCost,
      if (paymentAmount > 0) 'payment_amount': paymentAmount,
      'payment_method': paymentMethod,
      if (paymentNotes != null && paymentNotes.isNotEmpty) 'payment_notes': paymentNotes,
      if (customerNotes != null && customerNotes.isNotEmpty) 'customer_notes': customerNotes,
      if (internalNotes != null && internalNotes.isNotEmpty) 'internal_notes': internalNotes,
    };

    final response = await _apiClient.post(ApiEndpoints.repairs, body: body);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> repairMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final repair = Repair.fromJson(repairMap);
      return ApiResponse<Repair>(success: true, message: response.message, data: repair);
    }

    return ApiResponse<Repair>(success: false, message: response.message);
  }

  /// Get repair details by ID
  Future<ApiResponse<Repair>> getRepairDetails(int id) async {
    final response = await _apiClient.get('${ApiEndpoints.repairs}/$id');

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> repairMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final repair = Repair.fromJson(repairMap);
      return ApiResponse<Repair>(success: true, message: response.message, data: repair);
    }

    return ApiResponse<Repair>(success: false, message: response.message);
  }

  /// Update repair job card details
  Future<ApiResponse<Repair>> updateRepair({
    required int id,
    String? problemDescription,
    List<String>? deviceCondition,
    String? conditionNotes,
    List<String>? accessoriesReceived,
    String? accessoriesNotes,
    String? pinPasscode,
    String? expectedDeliveryDate,
    double? estimatedCost,
    double? finalCost,
    double? labourCost,
    String? customerNotes,
    String? internalNotes,
  }) async {
    final body = {
      if (problemDescription != null) 'problem_description': problemDescription,
      if (deviceCondition != null) 'device_condition': deviceCondition,
      if (conditionNotes != null) 'condition_notes': conditionNotes,
      if (accessoriesReceived != null) 'accessories_received': accessoriesReceived,
      if (accessoriesNotes != null) 'accessories_notes': accessoriesNotes,
      if (pinPasscode != null) 'pin_passcode': pinPasscode,
      if (expectedDeliveryDate != null) 'expected_delivery_date': expectedDeliveryDate,
      if (estimatedCost != null) 'estimated_cost': estimatedCost,
      if (finalCost != null) 'final_cost': finalCost,
      if (labourCost != null) 'labour_cost': labourCost,
      if (customerNotes != null) 'customer_notes': customerNotes,
      if (internalNotes != null) 'internal_notes': internalNotes,
    };

    final response = await _apiClient.put('${ApiEndpoints.repairs}/$id', body: body);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> repairMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final repair = Repair.fromJson(repairMap);
      return ApiResponse<Repair>(success: true, message: response.message, data: repair);
    }

    return ApiResponse<Repair>(success: false, message: response.message);
  }

  /// Update repair status
  Future<ApiResponse<Repair>> updateStatus({
    required int id,
    required String repairStatus,
    String? notes,
  }) async {
    final body = {
      'repair_status': repairStatus,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await _apiClient.post(
      '${ApiEndpoints.repairs}/$id/status',
      body: {'_method': 'PATCH', ...body},
    );

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> repairMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final repair = Repair.fromJson(repairMap);
      return ApiResponse<Repair>(success: true, message: response.message, data: repair);
    }

    return ApiResponse<Repair>(success: false, message: response.message);
  }

  /// Collect a payment for a repair
  Future<ApiResponse<Repair>> collectPayment({
    required int repairId,
    required double amount,
    required String paymentMethod,
    String? paymentDate,
    String? notes,
  }) async {
    final body = {
      'amount': amount,
      'payment_method': paymentMethod,
      if (paymentDate != null) 'payment_date': paymentDate,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await _apiClient.post('${ApiEndpoints.repairs}/$repairId/payments', body: body);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> repairMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final repair = Repair.fromJson(repairMap);
      return ApiResponse<Repair>(success: true, message: response.message, data: repair);
    }

    return ApiResponse<Repair>(success: false, message: response.message);
  }

  /// Add a part used in repair
  Future<ApiResponse<Repair>> addPart({
    required int repairId,
    required String partName,
    int quantity = 1,
    double? costPrice,
    double sellingPrice = 0.0,
    String? notes,
  }) async {
    final body = {
      'part_name': partName,
      'quantity': quantity,
      if (costPrice != null) 'cost_price': costPrice,
      'selling_price': sellingPrice,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await _apiClient.post('${ApiEndpoints.repairs}/$repairId/parts', body: body);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> repairMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final repair = Repair.fromJson(repairMap);
      return ApiResponse<Repair>(success: true, message: response.message, data: repair);
    }

    return ApiResponse<Repair>(success: false, message: response.message);
  }

  /// Delete a repair part
  Future<ApiResponse<Repair>> deletePart(int partId) async {
    try {
      final response = await _apiClient.post(
        '/repair-parts/$partId',
        body: {'_method': 'DELETE'},
      );

      if (response.success && response.data != null) {
        final dynamic rawData = response.data;
        final Map<String, dynamic> repairMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
            ? Map<String, dynamic>.from(rawData['data'])
            : Map<String, dynamic>.from(rawData);
        final repair = Repair.fromJson(repairMap);
        return ApiResponse<Repair>(success: true, message: response.message, data: repair);
      }
      return ApiResponse<Repair>(success: false, message: response.message);
    } catch (_) {
      return ApiResponse<Repair>(success: false, message: 'Failed to delete repair part.');
    }
  }

  /// Delete a repair job card
  Future<ApiResponse<dynamic>> deleteRepair(int id) async {
    try {
      final response = await _apiClient.post(
        '${ApiEndpoints.repairs}/$id',
        body: {'_method': 'DELETE'},
      );
      return response;
    } catch (_) {
      return ApiResponse(success: false, message: 'Failed to delete repair job card.');
    }
  }
}
