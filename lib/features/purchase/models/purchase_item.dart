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
  final double purchaseRate;
  final double totalAmount;

  PurchaseItem({
    this.id,
    this.purchaseId,
    required this.inventoryItemId,
    required this.itemName,
    this.itemCategory,
    this.sku,
    required this.quantity,
    required this.purchaseRate,
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
      purchaseRate: _toDouble(json['purchase_rate']),
      totalAmount: _toDouble(json['total_amount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventory_item_id': inventoryItemId,
      'quantity': quantity,
      'purchase_rate': purchaseRate,
      'total_amount': totalAmount,
    };
  }
}