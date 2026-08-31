double _parseDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}

int _parseInt(dynamic val) {
  if (val == null) return 0;
  if (val is int) return val;
  if (val is num) return val.toInt();
  final d = double.tryParse(val.toString());
  return d != null ? d.toInt() : 0;
}

class StockMovement {
  final int id;
  final int inventoryItemId;
  final String movementType;
  final int quantity;
  final double unitCost;
  final String? referenceType;
  final int? referenceId;
  final String? notes;
  final String? createdAt;

  StockMovement({
    required this.id,
    required this.inventoryItemId,
    required this.movementType,
    required this.quantity,
    required this.unitCost,
    this.referenceType,
    this.referenceId,
    this.notes,
    this.createdAt,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement(
      id: _parseInt(json['id']),
      inventoryItemId: _parseInt(json['inventory_item_id']),
      movementType: json['movement_type']?.toString() ?? 'adjustment',
      quantity: _parseInt(json['quantity']),
      unitCost: _parseDouble(json['unit_cost']),
      referenceType: json['reference_type']?.toString(),
      referenceId: json['reference_id'] != null ? _parseInt(json['reference_id']) : null,
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class InventorySerial {
  final int id;
  final String? imei1;
  final String? imei2;
  final String? serialNumber;
  final String status;

  InventorySerial({
    required this.id,
    this.imei1,
    this.imei2,
    this.serialNumber,
    required this.status,
  });

  factory InventorySerial.fromJson(Map<String, dynamic> json) {
    return InventorySerial(
      id: _parseInt(json['id']),
      imei1: json['imei1']?.toString(),
      imei2: json['imei2']?.toString(),
      serialNumber: json['serial_number']?.toString(),
      status: json['status']?.toString() ?? 'available',
    );
  }
}

class InventoryItem {
  final int id;
  final int shopId;
  final String name;
  final String category;
  final String? brand;
  final String? model;
  final String? sku;
  final String itemType; // mobile, spare_part, accessory, other
  final double purchasePrice;
  final double sellingPrice;
  final int openingStock;
  final int currentStock;
  final int minimumStock;

  int get totalStock => openingStock;
  final String unit;
  final String? description;
  final bool isActive;
  final double stockValue;
  final bool isLowStock;
  final bool isOutOfStock;
  final List<InventorySerial> serials;
  final List<StockMovement> stockMovements;
  final String? createdAt;

  InventoryItem({
    required this.id,
    required this.shopId,
    required this.name,
    required this.category,
    this.brand,
    this.model,
    this.sku,
    required this.itemType,
    required this.purchasePrice,
    required this.sellingPrice,
    this.openingStock = 0,
    required this.currentStock,
    required this.minimumStock,
    required this.unit,
    this.description,
    required this.isActive,
    required this.stockValue,
    required this.isLowStock,
    required this.isOutOfStock,
    this.serials = const [],
    this.stockMovements = const [],
    this.createdAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final rawSerials = json['serials'];
    List<InventorySerial> parsedSerials = [];
    if (rawSerials is List) {
      parsedSerials = rawSerials.map((s) => InventorySerial.fromJson(Map<String, dynamic>.from(s))).toList();
    }

    final rawMovements = json['stock_movements'];
    List<StockMovement> parsedMovements = [];
    if (rawMovements is List) {
      parsedMovements = rawMovements.map((m) => StockMovement.fromJson(Map<String, dynamic>.from(m))).toList();
    }

    final curStock = _parseInt(json['current_stock']);
    final opStock = json['opening_stock'] != null ? _parseInt(json['opening_stock']) : curStock;

    return InventoryItem(
      id: _parseInt(json['id']),
      shopId: _parseInt(json['shop_id']),
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      brand: json['brand']?.toString(),
      model: json['model']?.toString(),
      sku: json['sku']?.toString(),
      itemType: json['item_type']?.toString() ?? 'spare_part',
      purchasePrice: _parseDouble(json['purchase_price']),
      sellingPrice: _parseDouble(json['selling_price']),
      openingStock: opStock,
      currentStock: curStock,
      minimumStock: _parseInt(json['minimum_stock']),
      unit: json['unit']?.toString() ?? 'pcs',
      description: json['description']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active']?.toString() == '1',
      stockValue: _parseDouble(json['stock_value']),
      isLowStock: json['is_low_stock'] == true,
      isOutOfStock: json['is_out_of_stock'] == true,
      serials: parsedSerials,
      stockMovements: parsedMovements,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'category': category,
      'brand': brand,
      'model': model,
      'sku': sku,
      'item_type': itemType,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'opening_stock': openingStock,
      'current_stock': currentStock,
      'minimum_stock': minimumStock,
      'unit': unit,
      'description': description,
      'is_active': isActive,
    };
  }
}

class InventoryMetrics {
  final int totalItems;
  final int lowStockCount;
  final int outOfStockCount;
  final double totalStockValue;

  InventoryMetrics({
    required this.totalItems,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.totalStockValue,
  });

  factory InventoryMetrics.fromJson(Map<String, dynamic> json) {
    return InventoryMetrics(
      totalItems: _parseInt(json['total_items']),
      lowStockCount: _parseInt(json['low_stock_count']),
      outOfStockCount: _parseInt(json['out_of_stock_count']),
      totalStockValue: _parseDouble(json['total_stock_value']),
    );
  }
}
