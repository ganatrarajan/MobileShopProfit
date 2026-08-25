int _parseInt(dynamic val, {int defaultValue = 0}) {
  if (val == null) return defaultValue;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? (double.tryParse(val)?.toInt() ?? defaultValue);
  return defaultValue;
}

class Customer {
  final int id;
  final int shopId;
  final String name;
  final String mobile;
  final String? alternateMobile;
  final String? email;
  final String? address;
  final String? city;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  Customer({
    required this.id,
    required this.shopId,
    required this.name,
    required this.mobile,
    this.alternateMobile,
    this.email,
    this.address,
    this.city,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: _parseInt(json['id']),
      shopId: _parseInt(json['shop_id']),
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      alternateMobile: json['alternate_mobile']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'mobile': mobile,
      'alternate_mobile': alternateMobile,
      'email': email,
      'address': address,
      'city': city,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}