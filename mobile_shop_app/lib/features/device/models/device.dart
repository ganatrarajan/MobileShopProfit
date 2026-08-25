import '../../customer/models/customer.dart';

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
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      shopId: json['shop_id'] is int ? json['shop_id'] : int.parse(json['shop_id'].toString()),
      customerId: json['customer_id'] is int ? json['customer_id'] : int.parse(json['customer_id'].toString()),
      deviceType: json['device_type'] ?? 'Mobile',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      variant: json['variant'],
      color: json['color'],
      imei1: json['imei_1'],
      imei2: json['imei_2'],
      serialNumber: json['serial_number'],
      purchaseDate: json['purchase_date'],
      notes: json['notes'],
      customer: json['customer'] != null && json['customer'] is Map<String, dynamic>
          ? Customer.fromJson(json['customer'])
          : null,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
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