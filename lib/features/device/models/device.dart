import '../../customer/models/customer.dart';

int _parseInt(dynamic val, {int defaultValue = 0}) {
  if (val == null) return defaultValue;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? (double.tryParse(val)?.toInt() ?? defaultValue);
  return defaultValue;
}

class Device {
  final int id;
  final int shopId;
  final int customerId;
  final String deviceType;
  final String brand;
  final String model;
  final String? variant;
  final String? color;
  final String? imei1;
  final String? imei2;
  final String? serialNumber;
  final String? purchaseDate;
  final String? notes;
  final Customer? customer;
  final int repairsCount;
  final int salesCount;
  final int warrantiesCount;
  final List<dynamic> repairs;
  final List<dynamic> sales;
  final List<dynamic> warranties;
  final String? createdAt;
  final String? updatedAt;

  Device({
    required this.id,
    required this.shopId,
    required this.customerId,
    required this.deviceType,
    required this.brand,
    required this.model,
    this.variant,
    this.color,
    this.imei1,
    this.imei2,
    this.serialNumber,
    this.purchaseDate,
    this.notes,
    this.customer,
    this.repairsCount = 0,
    this.salesCount = 0,
    this.warrantiesCount = 0,
    this.repairs = const [],
    this.sales = const [],
    this.warranties = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: _parseInt(json['id']),
      shopId: _parseInt(json['shop_id']),
      customerId: _parseInt(json['customer_id']),
      deviceType: json['device_type']?.toString() ?? 'Mobile',
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      variant: json['variant']?.toString(),
      color: json['color']?.toString(),
      imei1: json['imei_1']?.toString(),
      imei2: json['imei_2']?.toString(),
      serialNumber: json['serial_number']?.toString(),
      purchaseDate: json['purchase_date']?.toString(),
      notes: json['notes']?.toString(),
      customer: json['customer'] != null && json['customer'] is Map<String, dynamic>
          ? Customer.fromJson(json['customer'])
          : null,
      repairsCount: _parseInt(json['repairs_count']),
      salesCount: _parseInt(json['sales_count']),
      warrantiesCount: _parseInt(json['warranties_count']),
      repairs: json['repairs'] is List ? json['repairs'] : const [],
      sales: json['sales'] is List ? json['sales'] : const [],
      warranties: json['warranties'] is List ? json['warranties'] : const [],
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'customer_id': customerId,
      'device_type': deviceType,
      'brand': brand,
      'model': model,
      'variant': variant,
      'color': color,
      'imei_1': imei1,
      'imei_2': imei2,
      'serial_number': serialNumber,
      'purchase_date': purchaseDate,
      'notes': notes,
      'customer': customer?.toJson(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Device copyWith({
    int? id,
    int? shopId,
    int? customerId,
    String? deviceType,
    String? brand,
    String? model,
    String? variant,
    String? color,
    String? imei1,
    String? imei2,
    String? serialNumber,
    String? purchaseDate,
    String? notes,
    Customer? customer,
    int? repairsCount,
    int? salesCount,
    int? warrantiesCount,
    List<dynamic>? repairs,
    List<dynamic>? sales,
    List<dynamic>? warranties,
    String? createdAt,
    String? updatedAt,
  }) {
    return Device(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      customerId: customerId ?? this.customerId,
      deviceType: deviceType ?? this.deviceType,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      variant: variant ?? this.variant,
      color: color ?? this.color,
      imei1: imei1 ?? this.imei1,
      imei2: imei2 ?? this.imei2,
      serialNumber: serialNumber ?? this.serialNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      notes: notes ?? this.notes,
      customer: customer ?? this.customer,
      repairsCount: repairsCount ?? this.repairsCount,
      salesCount: salesCount ?? this.salesCount,
      warrantiesCount: warrantiesCount ?? this.warrantiesCount,
      repairs: repairs ?? this.repairs,
      sales: sales ?? this.sales,
      warranties: warranties ?? this.warranties,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}