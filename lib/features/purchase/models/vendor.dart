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

class Vendor {
  final int id;
  final int shopId;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? gstNumber;
  final String? notes;
  final double totalPurchase;
  final double totalPaid;
  final double outstandingAmount;
  final int purchasesCount;
  final DateTime? createdAt;

  Vendor({
    required this.id,
    required this.shopId,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.gstNumber,
    this.notes,
    this.totalPurchase = 0.0,
    this.totalPaid = 0.0,
    this.outstandingAmount = 0.0,
    this.purchasesCount = 0,
    this.createdAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: _toInt(json['id']),
      shopId: _toInt(json['shop_id']),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      gstNumber: json['gst_number']?.toString(),
      notes: json['notes']?.toString(),
      totalPurchase: _toDouble(json['total_purchase']),
      totalPaid: _toDouble(json['total_paid']),
      outstandingAmount: _toDouble(json['outstanding_amount']),
      purchasesCount: _toInt(json['purchases_count']),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'gst_number': gstNumber,
      'notes': notes,
    };
  }
}