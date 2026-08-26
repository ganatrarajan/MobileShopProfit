import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/inventory_item.dart';

class InventoryResponse {
  final InventoryMetrics metrics;
  final List<InventoryItem> items;
  final int currentPage;
  final int lastPage;
  final int total;

  InventoryResponse({
    required this.metrics,
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}

class InventoryRepository {
  final ApiClient _apiClient = ApiClient();

  /// Get inventory items with metrics, search, and stock status filters
  Future<ApiResponse<InventoryResponse>> getInventory({
    String? search,
    String? itemType,
    String? stockStatus,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (itemType != null && itemType.isNotEmpty && itemType != 'all') 'item_type': itemType,
      if (stockStatus != null && stockStatus.isNotEmpty && stockStatus != 'all') 'stock_status': stockStatus,
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final path = '${ApiEndpoints.inventory}?$queryString';

    final response = await _apiClient.get(path);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      List rawList = [];
      Map<String, dynamic> metricsMap = {};
      Map<String, dynamic> metaMap = {};

      if (rawData is List) {
        rawList = rawData;
      } else if (rawData is Map) {
        if (rawData['data'] is List) {
          rawList = rawData['data'];
        }
        if (rawData['metrics'] is Map) {
          metricsMap = Map<String, dynamic>.from(rawData['metrics']);
        }
        if (rawData['meta'] is Map) {
          metaMap = Map<String, dynamic>.from(rawData['meta']);
        }
      }

      final rawJson = response.rawJson;
      if (rawJson != null) {
        if (metricsMap.isEmpty && rawJson['metrics'] is Map) {
          metricsMap = Map<String, dynamic>.from(rawJson['metrics']);
        }
        if (metaMap.isEmpty && rawJson['meta'] is Map) {
          metaMap = Map<String, dynamic>.from(rawJson['meta']);
        }
      }

      final items = rawList.map((item) => InventoryItem.fromJson(Map<String, dynamic>.from(item))).toList();

      // Fallback metric calculation if server metrics map is empty
      if (metricsMap.isEmpty) {
        int totalItems = items.length;
        int lowStockCount = items.where((i) => i.isLowStock).length;
        int outOfStockCount = items.where((i) => i.isOutOfStock).length;
        double totalStockValue = items.fold(0.0, (sum, i) => sum + i.stockValue);

        metricsMap = {
          'total_items': totalItems,
          'low_stock_count': lowStockCount,
          'out_of_stock_count': outOfStockCount,
          'total_stock_value': totalStockValue,
        };
      }

      final metrics = InventoryMetrics.fromJson(metricsMap);

      final resObj = InventoryResponse(
        metrics: metrics,
        items: items,
        currentPage: metaMap['current_page'] is int ? metaMap['current_page'] : 1,
        lastPage: metaMap['last_page'] is int ? metaMap['last_page'] : 1,
        total: metaMap['total'] is int ? metaMap['total'] : items.length,
      );

      return ApiResponse<InventoryResponse>(
        success: true,
        message: response.message,
        data: resObj,
        rawJson: rawJson,
      );
    }

    return ApiResponse<InventoryResponse>(
      success: false,
      message: response.message,
    );
  }

  /// Create new inventory item
  Future<ApiResponse<InventoryItem>> createItem({
    required String name,
    required String itemType,
    required double purchasePrice,
    required double sellingPrice,
    String? category,
    String? brand,
    String? model,
    String? sku,
    int openingStock = 0,
    int minimumStock = 2,
    String unit = 'pcs',
    String? description,
    String? imei1,
    String? imei2,
    String? serialNumber,
  }) async {
    final body = {
      'name': name,
      'item_type': itemType,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      if (category != null && category.isNotEmpty) 'category': category,
      if (brand != null && brand.isNotEmpty) 'brand': brand,
      if (model != null && model.isNotEmpty) 'model': model,
      if (sku != null && sku.isNotEmpty) 'sku': sku,
      'opening_stock': openingStock,
      'minimum_stock': minimumStock,
      'unit': unit,
      if (description != null && description.isNotEmpty) 'description': description,
      if (imei1 != null && imei1.isNotEmpty) 'imei1': imei1,
      if (imei2 != null && imei2.isNotEmpty) 'imei2': imei2,
      if (serialNumber != null && serialNumber.isNotEmpty) 'serial_number': serialNumber,
    };

    final response = await _apiClient.post(ApiEndpoints.inventory, body: body);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> itemMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final item = InventoryItem.fromJson(itemMap);
      return ApiResponse<InventoryItem>(success: true, message: response.message, data: item);
    }

    return ApiResponse<InventoryItem>(success: false, message: response.message);
  }

  /// Get single item details
  Future<ApiResponse<InventoryItem>> getItemDetails(int id) async {
    final response = await _apiClient.get('/');

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> itemMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final item = InventoryItem.fromJson(itemMap);
      return ApiResponse<InventoryItem>(success: true, message: response.message, data: item);
    }

    return ApiResponse<InventoryItem>(success: false, message: response.message);
  }

  /// Update item details
  Future<ApiResponse<InventoryItem>> updateItem({
    required int id,
    String? name,
    String? itemType,
    double? purchasePrice,
    double? sellingPrice,
    String? category,
    String? brand,
    String? model,
    String? sku,
    int? minimumStock,
    String? unit,
    String? description,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (itemType != null) 'item_type': itemType,
      if (purchasePrice != null) 'purchase_price': purchasePrice,
      if (sellingPrice != null) 'selling_price': sellingPrice,
      if (category != null) 'category': category,
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      if (sku != null) 'sku': sku,
      if (minimumStock != null) 'minimum_stock': minimumStock,
      if (unit != null) 'unit': unit,
      if (description != null) 'description': description,
      if (isActive != null) 'is_active': isActive,
    };

    final response = await _apiClient.put('/', body: body);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> itemMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final item = InventoryItem.fromJson(itemMap);
      return ApiResponse<InventoryItem>(success: true, message: response.message, data: item);
    }

    return ApiResponse<InventoryItem>(success: false, message: response.message);
  }

  /// Delete inventory item
  Future<ApiResponse<void>> deleteItem(int id) async {
    final response = await _apiClient.delete('/');
    return ApiResponse<void>(
      success: response.success,
      message: response.message,
    );
  }

  /// Add stock (Purchase / Incoming)
  Future<ApiResponse<InventoryItem>> addStock({
    required int id,
    required int quantity,
    double? unitCost,
    String? notes,
    String? imei1,
    String? imei2,
    String? serialNumber,
  }) async {
    final body = {
      'quantity': quantity,
      if (unitCost != null) 'unit_cost': unitCost,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (imei1 != null && imei1.isNotEmpty) 'imei1': imei1,
      if (imei2 != null && imei2.isNotEmpty) 'imei2': imei2,
      if (serialNumber != null && serialNumber.isNotEmpty) 'serial_number': serialNumber,
    };

    final response = await _apiClient.post('//stock', body: body);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> itemMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final item = InventoryItem.fromJson(itemMap);
      return ApiResponse<InventoryItem>(success: true, message: response.message, data: item);
    }

    return ApiResponse<InventoryItem>(success: false, message: response.message);
  }

  /// Adjust stock (Damaged, Return, Lost, Correction)
  Future<ApiResponse<InventoryItem>> adjustStock({
    required int id,
    required String adjustmentType, // damaged, return, correction, lost
    required int quantity,
    required String notes,
  }) async {
    final body = {
      'adjustment_type': adjustmentType,
      'quantity': quantity,
      'notes': notes,
    };

    final response = await _apiClient.post('//adjustment', body: body);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      final Map<String, dynamic> itemMap = (rawData is Map && rawData.containsKey('data') && rawData['data'] is Map)
          ? Map<String, dynamic>.from(rawData['data'])
          : Map<String, dynamic>.from(rawData);
      final item = InventoryItem.fromJson(itemMap);
      return ApiResponse<InventoryItem>(success: true, message: response.message, data: item);
    }

    return ApiResponse<InventoryItem>(success: false, message: response.message);
  }
}
