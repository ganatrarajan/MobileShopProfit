double _parseDouble(dynamic val, {double defaultValue = 0.0}) {
  if (val == null) return defaultValue;
  if (val is double) return val;
  if (val is int) return val.toDouble();
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? defaultValue;
  return defaultValue;
}

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
  final String? signaturePath;
  final String? signatureUrl;
  final int repairsCount;
  final int salesCount;
  final int devicesCount;
  final int totalJobs;
  final double totalSpent;
  final double totalDue;
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
    this.signaturePath,
    this.signatureUrl,
    this.repairsCount = 0,
    this.salesCount = 0,
    this.devicesCount = 0,
    this.totalJobs = 0,
    this.totalSpent = 0.0,
    this.totalDue = 0.0,
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
      signaturePath: json['signature_path']?.toString(),
      signatureUrl: json['signature_url']?.toString(),
      repairsCount: _parseInt(json['repairs_count']),
      salesCount: _parseInt(json['sales_count']),
      devicesCount: _parseInt(json['devices_count']),
      totalJobs: _parseInt(json['total_jobs']),
      totalSpent: _parseDouble(json['total_spent']),
      totalDue: _parseDouble(json['total_due']),
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
      'signature_path': signaturePath,
      'signature_url': signatureUrl,
      'repairs_count': repairsCount,
      'sales_count': salesCount,
      'devices_count': devicesCount,
      'total_jobs': totalJobs,
      'total_spent': totalSpent,
      'total_due': totalDue,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}