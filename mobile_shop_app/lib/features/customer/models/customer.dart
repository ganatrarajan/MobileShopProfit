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
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      shopId: json['shop_id'] is int ? json['shop_id'] : int.parse(json['shop_id'].toString()),
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      alternateMobile: json['alternate_mobile'],
      email: json['email'],
      address: json['address'],
      city: json['city'],
      notes: json['notes'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
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