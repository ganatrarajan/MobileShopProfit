import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/warranty.dart';

class WarrantyRepository {
  final ApiClient _apiClient = ApiClient();

  /// Get paginated list of warranties
  Future<ApiResponse<List<Warranty>>> getWarranties({
    String? search,
    String? status,
    String? warrantyType,
    int? customerId,
    int? deviceId,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty && status != 'all') 'status': status,
      if (warrantyType != null && warrantyType.isNotEmpty && warrantyType != 'all') 'warranty_type': warrantyType,
      if (customerId != null) 'customer_id': customerId.toString(),
      if (deviceId != null) 'device_id': deviceId.toString(),
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final path = '${ApiEndpoints.warranties}?$queryString';

    final response = await _apiClient.get(path);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      List rawList = [];
      if (rawData is List) {
        rawList = rawData;
      } else if (rawData is Map && rawData['data'] is List) {
        rawList = rawData['data'];
      }

      final warranties = rawList.map((item) => Warranty.fromJson(Map<String, dynamic>.from(item))).toList();
      return ApiResponse<List<Warranty>>(success: true, message: response.message, data: warranties);
    }

    return ApiResponse<List<Warranty>>(success: false, message: response.message);
  }

  /// Create a new warranty record
  Future<ApiResponse<Warranty>> createWarranty({
    required int customerId,
    required int deviceId,
    required String warrantyType,
    required int durationDays,
    int? saleId,
    int? repairId,
    String? warrantyStartDate,
    String? warrantyTerms,
    String? notes,
  }) async {
    final body = {
      'customer_id': customerId,
      'device_id': deviceId,
      'warranty_type': warrantyType,
      'duration_days': durationDays,
      if (saleId != null) 'sale_id': saleId,
      if (repairId != null) 'repair_id': repairId,
      if (warrantyStartDate != null && warrantyStartDate.isNotEmpty) 'warranty_start_date': warrantyStartDate,
      if (warrantyTerms != null && warrantyTerms.isNotEmpty) 'warranty_terms': warrantyTerms,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await _apiClient.post(ApiEndpoints.warranties, body: body);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> itemMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final warranty = Warranty.fromJson(itemMap);
      return ApiResponse<Warranty>(success: true, message: response.message, data: warranty);
    }

    return ApiResponse<Warranty>(success: false, message: response.message);
  }

  /// Get warranty details by ID
  Future<ApiResponse<Warranty>> getWarrantyDetails(int id) async {
    final response = await _apiClient.get('${ApiEndpoints.warranties}/$id');

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> itemMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final warranty = Warranty.fromJson(itemMap);
      return ApiResponse<Warranty>(success: true, message: response.message, data: warranty);
    }

    return ApiResponse<Warranty>(success: false, message: response.message);
  }

  /// Update warranty details
  Future<ApiResponse<Warranty>> updateWarranty({
    required int id,
    String? warrantyStartDate,
    int? durationDays,
    String? warrantyTerms,
    String? status,
    String? notes,
  }) async {
    final body = {
      if (warrantyStartDate != null) 'warranty_start_date': warrantyStartDate,
      if (durationDays != null) 'duration_days': durationDays,
      if (warrantyTerms != null) 'warranty_terms': warrantyTerms,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
    };

    final response = await _apiClient.put('${ApiEndpoints.warranties}/$id', body: body);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> itemMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final warranty = Warranty.fromJson(itemMap);
      return ApiResponse<Warranty>(success: true, message: response.message, data: warranty);
    }

    return ApiResponse<Warranty>(success: false, message: response.message);
  }

  /// Delete warranty
  Future<ApiResponse<dynamic>> deleteWarranty(int id) async {
    try {
      final response = await _apiClient.post(
        '${ApiEndpoints.warranties}/$id',
        body: {'_method': 'DELETE'},
      );
      return response;
    } catch (_) {
      return ApiResponse(success: false, message: 'Failed to delete warranty.');
    }
  }

  /// Get claims listing
  Future<ApiResponse<List<WarrantyClaim>>> getClaims({
    int? warrantyId,
    String? search,
    String? claimStatus,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (claimStatus != null && claimStatus.isNotEmpty && claimStatus != 'all') 'claim_status': claimStatus,
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final path = warrantyId != null
        ? '${ApiEndpoints.warranties}/$warrantyId/claims?$queryString'
        : '${ApiEndpoints.warrantyClaims}?$queryString';

    final response = await _apiClient.get(path);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      List rawList = [];
      if (rawData is List) {
        rawList = rawData;
      } else if (rawData is Map && rawData['data'] is List) {
        rawList = rawData['data'];
      }

      final claims = rawList.map((item) => WarrantyClaim.fromJson(Map<String, dynamic>.from(item))).toList();
      return ApiResponse<List<WarrantyClaim>>(success: true, message: response.message, data: claims);
    }

    return ApiResponse<List<WarrantyClaim>>(success: false, message: response.message);
  }

  /// Register a new claim for a warranty
  Future<ApiResponse<WarrantyClaim>> createClaim({
    required int warrantyId,
    required String complaint,
    String? claimDate,
    String? notes,
  }) async {
    final body = {
      'complaint': complaint,
      if (claimDate != null && claimDate.isNotEmpty) 'claim_date': claimDate,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await _apiClient.post('${ApiEndpoints.warranties}/$warrantyId/claims', body: body);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> itemMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final claim = WarrantyClaim.fromJson(itemMap);
      return ApiResponse<WarrantyClaim>(success: true, message: response.message, data: claim);
    }

    return ApiResponse<WarrantyClaim>(success: false, message: response.message);
  }

  /// Update claim status and resolution
  Future<ApiResponse<WarrantyClaim>> updateClaimStatus({
    required int claimId,
    required String claimStatus,
    String? complaint,
    String? resolution,
    String? notes,
  }) async {
    final body = {
      'claim_status': claimStatus,
      if (complaint != null) 'complaint': complaint,
      if (resolution != null) 'resolution': resolution,
      if (notes != null) 'notes': notes,
    };

    final response = await _apiClient.put('${ApiEndpoints.warrantyClaims}/$claimId', body: body);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> itemMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final claim = WarrantyClaim.fromJson(itemMap);
      return ApiResponse<WarrantyClaim>(success: true, message: response.message, data: claim);
    }

    return ApiResponse<WarrantyClaim>(success: false, message: response.message);
  }

  /// Delete claim
  Future<ApiResponse<dynamic>> deleteClaim(int claimId) async {
    try {
      final response = await _apiClient.post(
        '${ApiEndpoints.warrantyClaims}/$claimId',
        body: {'_method': 'DELETE'},
      );
      return response;
    } catch (_) {
      return ApiResponse(success: false, message: 'Failed to delete warranty claim.');
    }
  }
}
