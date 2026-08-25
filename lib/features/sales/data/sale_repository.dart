import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/sale.dart';

class SaleRepository {
  final ApiClient _apiClient = ApiClient();

  /// Get sales list with filters
  Future<ApiResponse<List<Sale>>> getSales({
    String? search,
    String? paymentStatus,
    String? saleType,
    int? customerId,
    String? dateFrom,
    String? dateTo,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (paymentStatus != null && paymentStatus.isNotEmpty && paymentStatus != 'all') 'payment_status': paymentStatus,
      if (saleType != null && saleType.isNotEmpty && saleType != 'all') 'sale_type': saleType,
      if (customerId != null) 'customer_id': customerId.toString(),
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final path = '${ApiEndpoints.sales}?$queryString';

    final response = await _apiClient.get(path);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      List rawList = [];
      if (rawData is List) {
        rawList = rawData;
      } else if (rawData is Map && rawData['data'] is List) {
        rawList = rawData['data'];
      }

      final sales = rawList.map((item) => Sale.fromJson(Map<String, dynamic>.from(item))).toList();
      return ApiResponse<List<Sale>>(success: true, message: response.message, data: sales);
    }

    return ApiResponse<List<Sale>>(success: false, message: response.message);
  }

  /// Create a new sale invoice (Quick or Regular)
  Future<ApiResponse<Sale>> createSale({
    String saleType = 'regular',
    int? customerId,
    String? customerName,
    String? customerMobile,
    int? deviceId,
    String? saleDate,
    double discount = 0.0,
    double taxAmount = 0.0,
    String? notes,
    required List<SaleItem> items,
    double? paymentAmount,
    String? paymentMethod,
    String? paymentNotes,
  }) async {
    final body = {
      'sale_type': saleType,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null && customerName.isNotEmpty) 'customer_name': customerName,
      if (customerMobile != null && customerMobile.isNotEmpty) 'customer_mobile': customerMobile,
      if (deviceId != null) 'device_id': deviceId,
      if (saleDate != null) 'sale_date': saleDate,
      'discount': discount,
      'tax_amount': taxAmount,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'items': items.map((i) => i.toJson()).toList(),
      if (paymentAmount != null) 'payment_amount': paymentAmount,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (paymentNotes != null && paymentNotes.isNotEmpty) 'payment_notes': paymentNotes,
    };

    final response = await _apiClient.post(ApiEndpoints.sales, body: body);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> saleMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final sale = Sale.fromJson(saleMap);
      return ApiResponse<Sale>(success: true, message: response.message, data: sale);
    }

    return ApiResponse<Sale>(success: false, message: response.message);
  }

  /// Get sale details by ID
  Future<ApiResponse<Sale>> getSaleDetails(int id) async {
    final response = await _apiClient.get('${ApiEndpoints.sales}/$id');

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> saleMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final sale = Sale.fromJson(saleMap);
      return ApiResponse<Sale>(success: true, message: response.message, data: sale);
    }

    return ApiResponse<Sale>(success: false, message: response.message);
  }

  /// Collect a new payment for a sale invoice
  Future<ApiResponse<Sale>> collectPayment({
    required int saleId,
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

    final response = await _apiClient.post('${ApiEndpoints.sales}/$saleId/payments', body: body);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> saleMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final sale = Sale.fromJson(saleMap);
      return ApiResponse<Sale>(success: true, message: response.message, data: sale);
    }

    return ApiResponse<Sale>(success: false, message: response.message);
  }

  /// Get payments list for a sale invoice
  Future<ApiResponse<List<SalePayment>>> getSalePayments(int saleId) async {
    final response = await _apiClient.get('${ApiEndpoints.sales}/$saleId/payments');

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      List rawList = [];
      if (rawData is List) {
        rawList = rawData;
      } else if (rawData is Map && rawData['data'] is List) {
        rawList = rawData['data'];
      }

      final payments = rawList.map((item) => SalePayment.fromJson(Map<String, dynamic>.from(item))).toList();
      return ApiResponse<List<SalePayment>>(success: true, message: response.message, data: payments);
    }

    return ApiResponse<List<SalePayment>>(success: false, message: response.message);
  }

  /// Delete a sale invoice
  Future<ApiResponse<dynamic>> deleteSale(int id) async {
    try {
      final response = await _apiClient.post(
        '${ApiEndpoints.sales}/$id',
        body: {'_method': 'DELETE'},
      );
      return response;
    } catch (_) {
      return ApiResponse(success: false, message: 'Failed to delete sale invoice.');
    }
  }
}
