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
      id: json['id'] is int ? json['id'] as int : (json['id'] != null ? int.parse(json['id'].toString()) : null),
      purchaseId: json['purchase_id'] is int ? json['purchase_id'] as int : (json['purchase_id'] != null ? int.parse(json['purchase_id'].toString()) : null),
      inventoryItemId: json['inventory_item_id'] is int ? json['inventory_item_id'] as int : int.parse(json['inventory_item_id'].toString()),
      itemName: json['item_name']?.toString() ?? 'Item',
      itemCategory: json['item_category']?.toString(),
      sku: json['sku']?.toString(),
      quantity: json['quantity'] is int ? json['quantity'] as int : int.parse((json['quantity'] ?? 0).toString()),
      purchaseRate: (json['purchase_rate'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
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
