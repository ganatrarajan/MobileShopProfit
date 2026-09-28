class PurchasePayment {
  final int id;
  final int shopId;
  final int? purchaseId;
  final int vendorId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String? notes;

  PurchasePayment({
    required this.id,
    required this.shopId,
    this.purchaseId,
    required this.vendorId,
    required this.amount,
    required this.paymentDate,
    this.paymentMethod = 'cash',
    this.notes,
  });

  factory PurchasePayment.fromJson(Map<String, dynamic> json) {
    return PurchasePayment(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      shopId: json['shop_id'] is int ? json['shop_id'] as int : int.parse((json['shop_id'] ?? 0).toString()),
      purchaseId: json['purchase_id'] is int ? json['purchase_id'] as int : (json['purchase_id'] != null ? int.parse(json['purchase_id'].toString()) : null),
      vendorId: json['vendor_id'] is int ? json['vendor_id'] as int : int.parse(json['vendor_id'].toString()),
      amount: (json['amount'] ?? 0).toDouble(),
      paymentDate: json['payment_date'] != null ? DateTime.parse(json['payment_date'].toString()) : DateTime.now(),
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      notes: json['notes']?.toString(),
    );
  }
}
