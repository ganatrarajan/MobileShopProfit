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
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      shopId: json['shop_id'] is int ? json['shop_id'] as int : int.parse((json['shop_id'] ?? 0).toString()),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      gstNumber: json['gst_number']?.toString(),
      notes: json['notes']?.toString(),
      totalPurchase: (json['total_purchase'] ?? 0).toDouble(),
      totalPaid: (json['total_paid'] ?? 0).toDouble(),
      outstandingAmount: (json['outstanding_amount'] ?? 0).toDouble(),
      purchasesCount: json['purchases_count'] is int ? json['purchases_count'] as int : int.parse((json['purchases_count'] ?? 0).toString()),
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
