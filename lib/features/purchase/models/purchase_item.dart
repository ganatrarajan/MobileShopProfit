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

class PurchaseItem {
  final int? id;
  final int? purchaseId;
  final int inventoryItemId;
  final String itemName;
  final String? itemCategory;
  final String? sku;
  final int quantity;
  final String? imei1;
  final String? imei2;
  final String? serialNumber;
  final double purchaseRate;
  final double taxAmount;
  final double taxRate;
  final String taxType; // exclusive, inclusive
  final double totalAmount;

  PurchaseItem({
    this.id,
    this.purchaseId,
    required this.inventoryItemId,
    required this.itemName,
    this.itemCategory,
    this.sku,
    required this.quantity,
    this.imei1,
    this.imei2,
    this.serialNumber,
    required this.purchaseRate,
    this.taxAmount = 0.0,
    this.taxRate = 0.0,
    this.taxType = 'exclusive',
    required this.totalAmount,
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      id: json['id'] != null ? _toInt(json['id']) : null,
      purchaseId: json['purchase_id'] != null ? _toInt(json['purchase_id']) : null,
      inventoryItemId: _toInt(json['inventory_item_id']),
      itemName: json['item_name']?.toString() ?? (json['inventory_item']?['name']?.toString() ?? 'Item'),
      itemCategory: json['item_category']?.toString(),
      sku: json['sku']?.toString(),
      quantity: _toInt(json['quantity']),
      imei1: json['imei1']?.toString(),
      imei2: json['imei2']?.toString(),
      serialNumber: json['serial_number']?.toString(),
      purchaseRate: _toDouble(json['purchase_rate']),
      taxAmount: _toDouble(json['tax_amount']),
      taxRate: _toDouble(json['tax_rate']),
      taxType: json['tax_type']?.toString() ?? 'exclusive',
      totalAmount: _toDouble(json['total_amount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventory_item_id': inventoryItemId,
      'quantity': quantity,
      if (imei1 != null && imei1!.isNotEmpty) 'imei1': imei1,
      if (imei2 != null && imei2!.isNotEmpty) 'imei2': imei2,
      if (serialNumber != null && serialNumber!.isNotEmpty) 'serial_number': serialNumber,
      'purchase_rate': purchaseRate,
      'tax_amount': taxAmount,
      'tax_rate': taxRate,
      'tax_type': taxType,
      'total_amount': totalAmount,
    };
  }
}