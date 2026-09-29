import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/vendor.dart';
import '../models/purchase.dart';

double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}

int _toInt(dynamic val) {
  if (val == null) return 0;
  if (val is int) return val;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString()) ?? 0;
}

class PurchaseResponse {
  final double totalAmount;
  final double totalPaid;
  final double totalOutstanding;
  final int totalCount;
  final List<Purchase> purchases;
  final int currentPage;
  final int lastPage;

  PurchaseResponse({
    required this.totalAmount,
    required this.totalPaid,
    required this.totalOutstanding,
    required this.totalCount,
    required this.purchases,
    required this.currentPage,
    required this.lastPage,
  });
}

class VendorResponse {
  final int totalVendors;
  final double totalPurchases;
  final double totalPaid;
  final double totalOutstanding;
  final List<Vendor> vendors;
  final int currentPage;
  final int lastPage;

  VendorResponse({
    required this.totalVendors,
    required this.totalPurchases,
    required this.totalPaid,
    required this.totalOutstanding,
    required this.vendors,
    required this.currentPage,
    required this.lastPage,
  });
}

class PurchaseRepository {
  final ApiClient _apiClient = ApiClient();

  // --- VENDORS ---

  Future<ApiResponse<VendorResponse>> getVendors({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final url = '${ApiEndpoints.vendors}?$queryString';

    final response = await _apiClient.get(url);

    if (response.success) {
      final Map<String, dynamic> rawJsonMap = response.rawJson ?? {};
      final dynamic dataField = rawJsonMap.containsKey('data') ? rawJsonMap['data'] : response.data;
      
      List<Vendor> vendors = [];

      if (dataField is List) {
        vendors = dataField.map((v) => Vendor.fromJson(Map<String, dynamic>.from(v as Map))).toList();
      } else if (dataField is Map && dataField['data'] is List) {
        vendors = (dataField['data'] as List).map((v) => Vendor.fromJson(Map<String, dynamic>.from(v as Map))).toList();
      } else if (response.data is List) {
        vendors = (response.data as List).map((v) => Vendor.fromJson(Map<String, dynamic>.from(v as Map))).toList();
      }

      final metricsMap = rawJsonMap['metrics'] is Map ? Map<String, dynamic>.from(rawJsonMap['metrics']) : {};
      final metaMap = rawJsonMap['meta'] is Map ? Map<String, dynamic>.from(rawJsonMap['meta']) : {};

      final resObj = VendorResponse(
        totalVendors: metricsMap['total_vendors'] != null
            ? _toInt(metricsMap['total_vendors'])
            : (metaMap['total'] != null ? _toInt(metaMap['total']) : vendors.length),
        totalPurchases: _toDouble(metricsMap['total_purchases']),
        totalPaid: _toDouble(metricsMap['total_paid']),
        totalOutstanding: _toDouble(metricsMap['total_outstanding']),
        vendors: vendors,
        currentPage: _toInt(metaMap['current_page']) > 0 ? _toInt(metaMap['current_page']) : 1,
        lastPage: _toInt(metaMap['last_page']) > 0 ? _toInt(metaMap['last_page']) : 1,
      );

      return ApiResponse<VendorResponse>(success: true, message: response.message, data: resObj);
    }

    return ApiResponse<VendorResponse>(success: false, message: response.message);
  }

  Future<ApiResponse<Vendor>> createVendor({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? gstNumber,
    String? notes,
  }) async {
    final body = {
      'name': name,
      'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (address != null && address.isNotEmpty) 'address': address,
      if (gstNumber != null && gstNumber.isNotEmpty) 'gst_number': gstNumber,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await _apiClient.post(ApiEndpoints.vendors, body: body);

    if (response.success) {
      final dynamic rawData = response.data ?? response.rawJson?['data'];
      if (rawData != null) {
        final Map<String, dynamic> vendorMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
            ? Map<String, dynamic>.from(rawData['data'])
            : Map<String, dynamic>.from(rawData as Map);
        final vendor = Vendor.fromJson(vendorMap);
        return ApiResponse<Vendor>(success: true, message: response.message, data: vendor);
      }
    }

    return ApiResponse<Vendor>(success: false, message: response.message);
  }

  Future<ApiResponse<Vendor>> getVendorDetails(int id) async {
    final response = await _apiClient.get('${ApiEndpoints.vendors}/$id');

    if (response.success) {
      final dynamic rawData = response.data ?? response.rawJson?['data'];
      if (rawData != null) {
        final Map<String, dynamic> vendorMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
            ? Map<String, dynamic>.from(rawData['data'])
            : Map<String, dynamic>.from(rawData as Map);
        final vendor = Vendor.fromJson(vendorMap);
        return ApiResponse<Vendor>(success: true, message: response.message, data: vendor);
      }
    }

    return ApiResponse<Vendor>(success: false, message: response.message);
  }

  Future<ApiResponse<Vendor>> updateVendor({
    required int id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? gstNumber,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (gstNumber != null) 'gst_number': gstNumber,
      if (notes != null) 'notes': notes,
    };

    final response = await _apiClient.put('${ApiEndpoints.vendors}/$id', body: body);

    if (response.success) {
      final dynamic rawData = response.data ?? response.rawJson?['data'];
      if (rawData != null) {
        final Map<String, dynamic> vendorMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
            ? Map<String, dynamic>.from(rawData['data'])
            : Map<String, dynamic>.from(rawData as Map);
        final vendor = Vendor.fromJson(vendorMap);
        return ApiResponse<Vendor>(success: true, message: response.message, data: vendor);
      }
    }

    return ApiResponse<Vendor>(success: false, message: response.message);
  }

  // --- PURCHASES ---

  Future<ApiResponse<PurchaseResponse>> getPurchases({
    String? search,
    String? vendorId,
    String? paymentStatus,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (vendorId != null && vendorId.isNotEmpty) 'vendor_id': vendorId,
      if (paymentStatus != null && paymentStatus.isNotEmpty) 'payment_status': paymentStatus,
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final url = '${ApiEndpoints.purchases}?$queryString';

    final response = await _apiClient.get(url);

    if (response.success) {
      final Map<String, dynamic> rawJsonMap = response.rawJson ?? {};
      final dynamic dataField = rawJsonMap.containsKey('data') ? rawJsonMap['data'] : response.data;

      List<Purchase> purchases = [];

      if (dataField is List) {
        purchases = dataField.map((p) => Purchase.fromJson(Map<String, dynamic>.from(p as Map))).toList();
      } else if (dataField is Map && dataField['data'] is List) {
        purchases = (dataField['data'] as List).map((p) => Purchase.fromJson(Map<String, dynamic>.from(p as Map))).toList();
      } else if (response.data is List) {
        purchases = (response.data as List).map((p) => Purchase.fromJson(Map<String, dynamic>.from(p as Map))).toList();
      }

      final metricsMap = rawJsonMap['metrics'] is Map ? Map<String, dynamic>.from(rawJsonMap['metrics']) : {};
      final metaMap = rawJsonMap['meta'] is Map ? Map<String, dynamic>.from(rawJsonMap['meta']) : {};

      final resObj = PurchaseResponse(
        totalAmount: _toDouble(metricsMap['total_amount']),
        totalPaid: _toDouble(metricsMap['total_paid']),
        totalOutstanding: _toDouble(metricsMap['total_outstanding']),
        totalCount: metricsMap['total_purchases'] != null
            ? _toInt(metricsMap['total_purchases'])
            : (metaMap['total'] != null ? _toInt(metaMap['total']) : purchases.length),
        purchases: purchases,
        currentPage: _toInt(metaMap['current_page']) > 0 ? _toInt(metaMap['current_page']) : 1,
        lastPage: _toInt(metaMap['last_page']) > 0 ? _toInt(metaMap['last_page']) : 1,
      );

      return ApiResponse<PurchaseResponse>(success: true, message: response.message, data: resObj);
    }

    return ApiResponse<PurchaseResponse>(success: false, message: response.message);
  }

  Future<ApiResponse<Purchase>> createPurchase({
    required int vendorId,
    required String purchaseDate,
    String? purchaseNumber,
    required List<Map<String, dynamic>> items,
    double discount = 0,
    double additionalCharges = 0,
    double amountPaid = 0,
    String paymentStatus = 'pending',
    bool addToInventory = true,
    String? notes,
  }) async {
    final body = {
      'vendor_id': vendorId,
      'purchase_date': purchaseDate,
      if (purchaseNumber != null && purchaseNumber.isNotEmpty) 'purchase_number': purchaseNumber,
      'items': items,
      'discount': discount,
      'additional_charges': additionalCharges,
      'amount_paid': amountPaid,
      'payment_status': paymentStatus,
      'add_to_inventory': addToInventory,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await _apiClient.post(ApiEndpoints.purchases, body: body);

    if (response.success) {
      final dynamic rawData = response.data ?? response.rawJson?['data'];
      if (rawData != null) {
        final Map<String, dynamic> pMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
            ? Map<String, dynamic>.from(rawData['data'])
            : Map<String, dynamic>.from(rawData as Map);
        final purchase = Purchase.fromJson(pMap);
        return ApiResponse<Purchase>(success: true, message: response.message, data: purchase);
      }
    }

    return ApiResponse<Purchase>(success: false, message: response.message);
  }

  Future<ApiResponse<Purchase>> getPurchaseDetails(int id) async {
    final response = await _apiClient.get('${ApiEndpoints.purchases}/$id');

    if (response.success) {
      final dynamic rawData = response.data ?? response.rawJson?['data'];
      if (rawData != null) {
        final Map<String, dynamic> pMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
            ? Map<String, dynamic>.from(rawData['data'])
            : Map<String, dynamic>.from(rawData as Map);
        final purchase = Purchase.fromJson(pMap);
        return ApiResponse<Purchase>(success: true, message: response.message, data: purchase);
      }
    }

    return ApiResponse<Purchase>(success: false, message: response.message);
  }

  Future<ApiResponse<Purchase>> updatePurchase(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.put('${ApiEndpoints.purchases}/$id', body: data);

    if (response.success) {
      final dynamic rawData = response.data ?? response.rawJson?['data'];
      if (rawData != null) {
        final Map<String, dynamic> pMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
            ? Map<String, dynamic>.from(rawData['data'])
            : Map<String, dynamic>.from(rawData as Map);
        final purchase = Purchase.fromJson(pMap);
        return ApiResponse<Purchase>(success: true, message: response.message, data: purchase);
      }
    }

    return ApiResponse<Purchase>(success: false, message: response.message);
  }

  Future<ApiResponse<void>> deletePurchase(int id) async {
    final response = await _apiClient.delete('${ApiEndpoints.purchases}/$id');
    return ApiResponse<void>(success: response.success, message: response.message);
  }

  Future<ApiResponse<Purchase>> addStockToPurchase(int id) async {
    final response = await _apiClient.post('${ApiEndpoints.purchases}/$id/add-stock', body: {});

    if (response.success) {
      final dynamic rawData = response.data ?? response.rawJson?['data'];
      if (rawData != null) {
        final Map<String, dynamic> pMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
            ? Map<String, dynamic>.from(rawData['data'])
            : Map<String, dynamic>.from(rawData as Map);
        final purchase = Purchase.fromJson(pMap);
        return ApiResponse<Purchase>(success: true, message: response.message, data: purchase);
      }
    }

    return ApiResponse<Purchase>(success: false, message: response.message);
  }

  Future<ApiResponse<Purchase>> recordPurchasePayment({
    required int purchaseId,
    required double amount,
    required String paymentDate,
    String paymentMethod = 'cash',
    String? notes,
  }) async {
    final body = {
      'amount': amount,
      'payment_date': paymentDate,
      'payment_method': paymentMethod,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await _apiClient.post('${ApiEndpoints.purchases}/$purchaseId/payments', body: body);

    if (response.success) {
      final dynamic rawData = response.data ?? response.rawJson?['data'];
      if (rawData != null) {
        final Map<String, dynamic> pMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
            ? Map<String, dynamic>.from(rawData['data'])
            : Map<String, dynamic>.from(rawData as Map);
        final purchase = Purchase.fromJson(pMap);
        return ApiResponse<Purchase>(success: true, message: response.message, data: purchase);
      }
    }

    return ApiResponse<Purchase>(success: false, message: response.message);
  }

  Future<ApiResponse<void>> recordVendorPayment({
    required int vendorId,
    required double amount,
    required String paymentDate,
    String paymentMethod = 'cash',
    String? notes,
  }) async {
    final body = {
      'vendor_id': vendorId,
      'amount': amount,
      'payment_date': paymentDate,
      'payment_method': paymentMethod,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await _apiClient.post('${ApiEndpoints.vendors}/$vendorId/payments', body: body);
    return ApiResponse<void>(success: response.success, message: response.message);
  }
}
