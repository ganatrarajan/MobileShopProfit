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
}