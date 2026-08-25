import '../../customer/models/customer.dart';
import '../../device/models/device.dart';
import '../../repair/models/repair.dart';
import '../../sales/models/sale.dart';

int _parseInt(dynamic val, {int defaultValue = 0}) {
  if (val == null) return defaultValue;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? (double.tryParse(val)?.toInt() ?? defaultValue);
  return defaultValue;
}

int? _parseNullableInt(dynamic val) {
  if (val == null) return null;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val);
  return null;
}

class WarrantyClaim {
  final int id;
  final int shopId;
  final int warrantyId;
  final int customerId;
  final int deviceId;
  final String claimNumber;
  final String claimDate;
  final String complaint;
  final String claimStatus; // open, checking, approved, rejected, repairing, resolved, closed
  final String? resolution;
  final String? notes;
  final String? resolvedAt;
  final int? createdBy;
  final String? creatorName;
  final Customer? customer;
  final Device? device;
  final String? createdAt;
  final String? updatedAt;

  WarrantyClaim({
    required this.id,
    required this.shopId,
    required this.warrantyId,
    required this.customerId,
    required this.deviceId,
    required this.claimNumber,
    required this.claimDate,
    required this.complaint,
    this.claimStatus = 'open',
    this.resolution,
    this.notes,
    this.resolvedAt,
    this.createdBy,
    this.creatorName,
    this.customer,
    this.device,
    this.createdAt,
    this.updatedAt,
  });

  factory WarrantyClaim.fromJson(Map<String, dynamic> json) {
    return WarrantyClaim(
      id: _parseInt(json['id']),
      shopId: _parseInt(json['shop_id']),
      warrantyId: _parseInt(json['warranty_id']),
      customerId: _parseInt(json['customer_id']),
      deviceId: _parseInt(json['device_id']),
      claimNumber: json['claim_number']?.toString() ?? '',
      claimDate: json['claim_date']?.toString() ?? '',
      complaint: json['complaint']?.toString() ?? '',
      claimStatus: json['claim_status']?.toString() ?? 'open',
      resolution: json['resolution']?.toString(),
      notes: json['notes']?.toString(),
      resolvedAt: json['resolved_at']?.toString(),
      createdBy: _parseNullableInt(json['created_by']),
      creatorName: json['creator_name']?.toString(),
      customer: json['customer'] != null && json['customer'] is Map<String, dynamic>
          ? Customer.fromJson(json['customer'])
          : null,
      device: json['device'] != null && json['device'] is Map<String, dynamic>
          ? Device.fromJson(json['device'])
          : null,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'warranty_id': warrantyId,
      'customer_id': customerId,
      'device_id': deviceId,
      'claim_number': claimNumber,
      'claim_date': claimDate,
      'complaint': complaint,
      'claim_status': claimStatus,
      'resolution': resolution,
      'notes': notes,
      'resolved_at': resolvedAt,
      'created_by': createdBy,
      'creator_name': creatorName,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class Warranty {
  final int id;
  final int shopId;
  final int customerId;
  final int deviceId;
  final int? saleId;
  final int? repairId;
  final String warrantyNumber;
  final String warrantyType; // sale, repair
  final String warrantyStartDate;
  final String warrantyEndDate;
  final int durationDays;
  final String? warrantyTerms;
  final String status; // active, expiring_soon, expired, voided
  final String storedStatus;
  final int daysRemaining;
  final String? notes;
  final int? createdBy;
  final String? creatorName;
  final int claimsCount;
  final Customer? customer;
  final Device? device;
  final Sale? sale;
  final Repair? repair;
  final List<WarrantyClaim> claims;
  final String? createdAt;
  final String? updatedAt;

  Warranty({
    required this.id,
    required this.shopId,
    required this.customerId,
    required this.deviceId,
    this.saleId,
    this.repairId,
    required this.warrantyNumber,
    required this.warrantyType,
    required this.warrantyStartDate,
    required this.warrantyEndDate,
    required this.durationDays,
    this.warrantyTerms,
    required this.status,
    required this.storedStatus,
    required this.daysRemaining,
    this.notes,
    this.createdBy,
    this.creatorName,
    this.claimsCount = 0,
    this.customer,
    this.device,
    this.sale,
    this.repair,
    this.claims = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Warranty.fromJson(Map<String, dynamic> json) {
    return Warranty(
      id: _parseInt(json['id']),
      shopId: _parseInt(json['shop_id']),
      customerId: _parseInt(json['customer_id']),
      deviceId: _parseInt(json['device_id']),
      saleId: _parseNullableInt(json['sale_id']),
      repairId: _parseNullableInt(json['repair_id']),
      warrantyNumber: json['warranty_number']?.toString() ?? '',
      warrantyType: json['warranty_type']?.toString() ?? 'sale',
      warrantyStartDate: json['warranty_start_date']?.toString() ?? '',
      warrantyEndDate: json['warranty_end_date']?.toString() ?? '',
      durationDays: _parseInt(json['duration_days'], defaultValue: 30),
      warrantyTerms: json['warranty_terms']?.toString(),
      status: json['status']?.toString() ?? 'active',
      storedStatus: json['stored_status']?.toString() ?? 'active',
      daysRemaining: _parseInt(json['days_remaining'], defaultValue: 0),
      notes: json['notes']?.toString(),
      createdBy: _parseNullableInt(json['created_by']),
      creatorName: json['creator_name']?.toString(),
      claimsCount: _parseInt(json['claims_count']),
      customer: json['customer'] != null && json['customer'] is Map<String, dynamic>
          ? Customer.fromJson(json['customer'])
          : null,
      device: json['device'] != null && json['device'] is Map<String, dynamic>
          ? Device.fromJson(json['device'])
          : null,
      sale: json['sale'] != null && json['sale'] is Map<String, dynamic>
          ? Sale.fromJson(json['sale'])
          : null,
      repair: json['repair'] != null && json['repair'] is Map<String, dynamic>
          ? Repair.fromJson(json['repair'])
          : null,
      claims: json['claims'] != null && json['claims'] is List
          ? (json['claims'] as List).map((c) => WarrantyClaim.fromJson(c as Map<String, dynamic>)).toList()
          : [],
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'customer_id': customerId,
      'device_id': deviceId,
      'sale_id': saleId,
      'repair_id': repairId,
      'warranty_number': warrantyNumber,
      'warranty_type': warrantyType,
      'warranty_start_date': warrantyStartDate,
      'warranty_end_date': warrantyEndDate,
      'duration_days': durationDays,
      'warranty_terms': warrantyTerms,
      'status': status,
      'stored_status': storedStatus,
      'days_remaining': daysRemaining,
      'notes': notes,
      'created_by': createdBy,
      'creator_name': creatorName,
      'claims_count': claimsCount,
      'customer': customer?.toJson(),
      'device': device?.toJson(),
      'sale': sale?.toJson(),
      'repair': repair?.toJson(),
      'claims': claims.map((c) => c.toJson()).toList(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
