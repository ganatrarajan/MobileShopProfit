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
      id: _toInt(json['id']),
      shopId: _toInt(json['shop_id']),
      purchaseId: json['purchase_id'] != null ? _toInt(json['purchase_id']) : null,
      vendorId: _toInt(json['vendor_id']),
      amount: _toDouble(json['amount']),
      paymentDate: json['payment_date'] != null ? DateTime.tryParse(json['payment_date'].toString()) ?? DateTime.now() : DateTime.now(),
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      notes: json['notes']?.toString(),
    );
  }
}