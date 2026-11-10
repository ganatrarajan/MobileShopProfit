class Staff {
  final int id;
  final int shopId;
  final int? userId;
  final String name;
  final String mobile;
  final String? email;
  final String? designation;
  final double? salary;
  final String? joiningDate;
  final String? address;
  final String? notes;
  final bool isActive;
  final String? loginPassword;
  final Map<String, bool> permissions;
  final String? createdAt;
  final String? updatedAt;

  Staff({
    required this.id,
    required this.shopId,
    this.userId,
    required this.name,
    required this.mobile,
    this.email,
    this.designation,
    this.salary,
    this.joiningDate,
    this.address,
    this.notes,
    required this.isActive,
    this.loginPassword,
    this.permissions = const {},
    this.createdAt,
    this.updatedAt,
  });

  bool canAccess(String module) {
    return permissions[module] == true;
  }

  factory Staff.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is double) return val;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    final Map<String, bool> parsedPermissions = {};
    if (json['permissions'] is Map) {
      (json['permissions'] as Map).forEach((k, v) {
        parsedPermissions[k.toString()] = v == true || v == 1 || v.toString() == 'true';
      });
    }

    return Staff(
      id: parseInt(json['id']),
      shopId: parseInt(json['shop_id']),
      userId: json['user_id'] != null ? parseInt(json['user_id']) : null,
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      email: json['email']?.toString(),
      designation: json['designation']?.toString() ?? 'Staff',
      salary: parseDouble(json['salary']),
      joiningDate: json['joining_date']?.toString(),
      address: json['address']?.toString(),
      notes: json['notes']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      loginPassword: json['login_password']?.toString(),
      permissions: parsedPermissions,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'user_id': userId,
      'name': name,
      'mobile': mobile,
      'email': email,
      'designation': designation,
      'salary': salary,
      'joining_date': joiningDate,
      'address': address,
      'notes': notes,
      'is_active': isActive,
      'login_password': loginPassword,
      'permissions': permissions,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Staff && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

