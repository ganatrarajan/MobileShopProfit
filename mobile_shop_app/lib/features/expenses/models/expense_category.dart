int _parseInt(dynamic val) {
  if (val == null) return 0;
  if (val is int) return val;
  if (val is num) return val.toInt();
  final d = double.tryParse(val.toString());
  return d != null ? d.toInt() : 0;
}

class ExpenseCategory {
  final int id;
  final int? shopId;
  final String name;
  final String slug;
  final bool isSystemDefault;
  final String? createdAt;

  ExpenseCategory({
    required this.id,
    this.shopId,
    required this.name,
    required this.slug,
    required this.isSystemDefault,
    this.createdAt,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: _parseInt(json['id']),
      shopId: json['shop_id'] != null ? _parseInt(json['shop_id']) : null,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      isSystemDefault: json['is_system_default'] == true,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'slug': slug,
      'is_system_default': isSystemDefault,
      'created_at': createdAt,
    };
  }
}
