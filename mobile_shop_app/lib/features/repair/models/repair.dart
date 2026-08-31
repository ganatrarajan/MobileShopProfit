import '../../customer/models/customer.dart';
import '../../device/models/device.dart';

double _parseDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}

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

List<String> _parseListString(dynamic val) {
  if (val == null) return [];
  if (val is List) {
    return val.map((e) => e.toString()).toList();
  }
  return [];
}

class RepairPart {
  final int id;
  final int repairId;
  final String partName;
  final int quantity;
  final double? costPrice;
  final double sellingPrice;
  final String? notes;
  final String? createdAt;

  RepairPart({
    required this.id,
    required this.repairId,
    required this.partName,
    this.quantity = 1,
    this.costPrice,
    this.sellingPrice = 0.0,
    this.notes,
    this.createdAt,
  });

  factory RepairPart.fromJson(Map<String, dynamic> json) {
    return RepairPart(
      id: _parseInt(json['id']),
      repairId: _parseInt(json['repair_id']),
      partName: json['part_name']?.toString() ?? '',
      quantity: _parseInt(json['quantity'], defaultValue: 1),
      costPrice: json['cost_price'] != null ? _parseDouble(json['cost_price']) : null,
      sellingPrice: _parseDouble(json['selling_price']),
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'repair_id': repairId,
      'part_name': partName,
      'quantity': quantity,
      if (costPrice != null) 'cost_price': costPrice,
      'selling_price': sellingPrice,
      if (notes != null) 'notes': notes,
    };
  }
}

class RepairPayment {
  final int id;
  final int shopId;
  final int repairId;
  final double amount;
  final String paymentMethod;
  final String? paymentDate;
  final String? notes;
  final int? createdBy;
  final String? creatorName;
  final String? createdAt;

  RepairPayment({
    required this.id,
    required this.shopId,
    required this.repairId,
    required this.amount,
    required this.paymentMethod,
    this.paymentDate,
    this.notes,
    this.createdBy,
    this.creatorName,
    this.createdAt,
  });

  factory RepairPayment.fromJson(Map<String, dynamic> json) {
    return RepairPayment(
      id: _parseInt(json['id']),
      shopId: _parseInt(json['shop_id']),
      repairId: _parseInt(json['repair_id']),
      amount: _parseDouble(json['amount']),
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      paymentDate: json['payment_date']?.toString(),
      notes: json['notes']?.toString(),
      createdBy: _parseNullableInt(json['created_by']),
      creatorName: json['creator_name']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'repair_id': repairId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_date': paymentDate,
      'notes': notes,
      'created_by': createdBy,
      'creator_name': creatorName,
      'created_at': createdAt,
    };
  }
}

class Repair {
  final int id;
  final int shopId;
  final int customerId;
  final int deviceId;
  final int? technicianId;
  final String? technicianName;
  final double technicianEarning;
  final double technicianPaidAmount;
  final double technicianPayable;
  final double shopShare;
  final String technicianPaymentStatus;
  final String jobNumber;
  final String dateReceived;
  final String? expectedDeliveryDate;
  final String? deliveredDate;
  final String problemDescription;
  final List<String> deviceCondition;
  final String? conditionNotes;
  final List<String> accessoriesReceived;
  final String? accessoriesNotes;
  final String? pinPasscode;
  final double estimatedCost;
  final double finalCost;
  final double labourCost;
  final double amountPaid;
  final double amountDue;
  final String repairStatus; // received, diagnosing, waiting_customer, waiting_parts, repairing, ready, delivered, cancelled
  final String? customerNotes;
  final String? internalNotes;
  final int? createdBy;
  final String? creatorName;
  final Customer? customer;
  final Device? device;
  final List<RepairPart> parts;
  final List<RepairPayment> payments;
  final String? createdAt;
  final String? updatedAt;

  Repair({
    required this.id,
    required this.shopId,
    required this.customerId,
    required this.deviceId,
    this.technicianId,
    this.technicianName,
    this.technicianEarning = 0.0,
    this.technicianPaidAmount = 0.0,
    this.technicianPayable = 0.0,
    this.shopShare = 0.0,
    this.technicianPaymentStatus = 'unassigned',
    required this.jobNumber,
    required this.dateReceived,
    this.expectedDeliveryDate,
    this.deliveredDate,
    required this.problemDescription,
    this.deviceCondition = const [],
    this.conditionNotes,
    this.accessoriesReceived = const [],
    this.accessoriesNotes,
    this.pinPasscode,
    this.estimatedCost = 0.0,
    this.finalCost = 0.0,
    this.labourCost = 0.0,
    this.amountPaid = 0.0,
    required this.amountDue,
    this.repairStatus = 'received',
    this.customerNotes,
    this.internalNotes,
    this.createdBy,
    this.creatorName,
    this.customer,
    this.device,
    this.parts = const [],
    this.payments = const [],
    this.createdAt,
    this.updatedAt,
  });

  double get netCost => finalCost > 0 ? finalCost : estimatedCost;

  factory Repair.fromJson(Map<String, dynamic> json) {
    return Repair(
      id: _parseInt(json['id']),
      shopId: _parseInt(json['shop_id']),
      customerId: _parseInt(json['customer_id']),
      deviceId: _parseInt(json['device_id']),
      technicianId: _parseNullableInt(json['technician_id']),
            technicianName: json['technician_name']?.toString() ?? (json['technician'] is Map ? json['technician']['name']?.toString() : null),
      technicianEarning: _parseDouble(json['technician_earning']),
      technicianPaidAmount: _parseDouble(json['technician_paid_amount']),
      technicianPayable: _parseDouble(json['technician_payable']),
      shopShare: _parseDouble(json['shop_share']),
      technicianPaymentStatus: json['technician_payment_status']?.toString() ?? 'unassigned',
      jobNumber: json['job_number']?.toString() ?? '',
      dateReceived: json['date_received']?.toString() ?? '',
      expectedDeliveryDate: json['expected_delivery_date']?.toString(),
      deliveredDate: json['delivered_date']?.toString(),
      problemDescription: json['problem_description']?.toString() ?? '',
      deviceCondition: _parseListString(json['device_condition']),
      conditionNotes: json['condition_notes']?.toString(),
      accessoriesReceived: _parseListString(json['accessories_received']),
      accessoriesNotes: json['accessories_notes']?.toString(),
      pinPasscode: json['pin_passcode']?.toString(),
      estimatedCost: _parseDouble(json['estimated_cost']),
      finalCost: _parseDouble(json['final_cost']),
      labourCost: _parseDouble(json['labour_cost']),
      amountPaid: _parseDouble(json['amount_paid']),
      amountDue: _parseDouble(json['amount_due']),
      repairStatus: json['repair_status']?.toString() ?? 'received',
      customerNotes: json['customer_notes']?.toString(),
      internalNotes: json['internal_notes']?.toString(),
      createdBy: _parseNullableInt(json['created_by']),
      creatorName: json['creator_name']?.toString(),
      customer: json['customer'] != null && json['customer'] is Map<String, dynamic>
          ? Customer.fromJson(json['customer'])
          : null,
      device: json['device'] != null && json['device'] is Map<String, dynamic>
          ? Device.fromJson(json['device'])
          : null,
      parts: json['parts'] != null && json['parts'] is List
          ? (json['parts'] as List).map((p) => RepairPart.fromJson(p as Map<String, dynamic>)).toList()
          : [],
      payments: json['payments'] != null && json['payments'] is List
          ? (json['payments'] as List).map((p) => RepairPayment.fromJson(p as Map<String, dynamic>)).toList()
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
      if (technicianId != null) 'technician_id': technicianId,
      if (technicianName != null) 'technician_name': technicianName,
      'job_number': jobNumber,
      'date_received': dateReceived,
      'expected_delivery_date': expectedDeliveryDate,
      'delivered_date': deliveredDate,
      'problem_description': problemDescription,
      'device_condition': deviceCondition,
      'condition_notes': conditionNotes,
      'accessories_received': accessoriesReceived,
      'accessories_notes': accessoriesNotes,
      'pin_passcode': pinPasscode,
      'estimated_cost': estimatedCost,
      'final_cost': finalCost,
      'labour_cost': labourCost,
      'amount_paid': amountPaid,
      'amount_due': amountDue,
      'repair_status': repairStatus,
      'customer_notes': customerNotes,
      'internal_notes': internalNotes,
      'created_by': createdBy,
      'creator_name': creatorName,
      'customer': customer?.toJson(),
      'device': device?.toJson(),
      'parts': parts.map((p) => p.toJson()).toList(),
      'payments': payments.map((p) => p.toJson()).toList(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
