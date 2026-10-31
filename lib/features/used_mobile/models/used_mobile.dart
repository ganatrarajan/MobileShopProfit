double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}

int _toInt(dynamic val) {
  if (val == null) return 0;
  if (val is int) return val;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString()) ?? 0;
}

class UsedMobile {
  final int id;
  final int shopId;
  final int? createdBy;
  final String purchaseRefNumber;
  final String sellerName;
  final String sellerPhone;
  final String? sellerAddress;
  final String? idProofType;
  final String? idProofNumber;
  final String? idProofImagePath;
  final String? idProofBackImagePath;

  final String brand;
  final String model;
  final String imei1;
  final String? imei2;
  final String? serialNumber;
  final String? color;
  final String? ram;
  final String? storage;
  final String? batteryHealth;

  final String deviceCondition; // mint, good, fair, damaged
  final String? conditionNotes;
  final List<String> accessoriesIncluded;
  final List<String> devicePhotos;

  final DateTime purchaseDate;
  final double purchasePrice;
  final String paymentMode;
  final String? purchaseNotes;

  final double repairCost;
  final String? repairDetails;
  final double totalCost;

  final String status; // in_stock, sold, returned, scrapped

  final String? saleInvoiceNumber;
  final String? buyerName;
  final String? buyerPhone;
  final String? buyerAddress;
  final DateTime? saleDate;
  final double? sellingPrice;
  final String? salePaymentMode;
  final int? warrantyDays;
  final String? warrantyTerms;
  final String? saleNotes;
  final double? profit;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  UsedMobile({
    required this.id,
    required this.shopId,
    this.createdBy,
    required this.purchaseRefNumber,
    required this.sellerName,
    required this.sellerPhone,
    this.sellerAddress,
    this.idProofType,
    this.idProofNumber,
    this.idProofImagePath,
    this.idProofBackImagePath,
    required this.brand,
    required this.model,
    required this.imei1,
    this.imei2,
    this.serialNumber,
    this.color,
    this.ram,
    this.storage,
    this.batteryHealth,
    this.deviceCondition = 'good',
    this.conditionNotes,
    this.accessoriesIncluded = const [],
    this.devicePhotos = const [],
    required this.purchaseDate,
    required this.purchasePrice,
    this.paymentMode = 'Cash',
    this.purchaseNotes,
    this.repairCost = 0.0,
    this.repairDetails,
    required this.totalCost,
    this.status = 'in_stock',
    this.saleInvoiceNumber,
    this.buyerName,
    this.buyerPhone,
    this.buyerAddress,
    this.saleDate,
    this.sellingPrice,
    this.salePaymentMode,
    this.warrantyDays,
    this.warrantyTerms,
    this.saleNotes,
    this.profit,
    this.createdAt,
    this.updatedAt,
  });

  bool get isInStock => status.toLowerCase() == 'in_stock';
  bool get isSold => status.toLowerCase() == 'sold';

  String get deviceDisplayName {
    final specParts = <String>[];
    if (ram != null && ram!.trim().isNotEmpty && storage != null && storage!.trim().isNotEmpty) {
      specParts.add('${ram!.trim()}/${storage!.trim()}');
    } else if (storage != null && storage!.trim().isNotEmpty) {
      specParts.add(storage!.trim());
    } else if (ram != null && ram!.trim().isNotEmpty) {
      specParts.add(ram!.trim());
    }
    if (color != null && color!.trim().isNotEmpty) {
      specParts.add(color!.trim());
    }

    final specsStr = specParts.isNotEmpty ? ' (${specParts.join(', ')})' : '';
    return '$brand $model$specsStr';
  }

  double get profitPercentage {
    if (totalCost <= 0 || profit == null) return 0.0;
    return (profit! / totalCost) * 100;
  }

  String get conditionLabel {
    switch (deviceCondition.toLowerCase()) {
      case 'mint':
        return 'Mint (Like New)';
      case 'good':
        return 'Good Condition';
      case 'fair':
        return 'Fair (Minor Flaws)';
      case 'damaged':
        return 'Damaged / For Parts';
      default:
        return deviceCondition.isNotEmpty ? deviceCondition : 'Good';
    }
  }

  factory UsedMobile.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    return UsedMobile(
      id: _toInt(json['id']),
      shopId: _toInt(json['shop_id']),
      createdBy: json['created_by'] != null ? _toInt(json['created_by']) : null,
      purchaseRefNumber: json['purchase_ref_number']?.toString() ?? '',
      sellerName: json['seller_name']?.toString() ?? '',
      sellerPhone: json['seller_phone']?.toString() ?? '',
      sellerAddress: json['seller_address']?.toString(),
      idProofType: json['id_proof_type']?.toString(),
      idProofNumber: json['id_proof_number']?.toString(),
      idProofImagePath: (json['id_proof_photo'] ?? json['id_proof_image_path'])?.toString(),
      idProofBackImagePath: (json['id_proof_back_photo'] ?? json['id_proof_back_image_path'])?.toString(),
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      imei1: json['imei1']?.toString() ?? '',
      imei2: json['imei2']?.toString(),
      serialNumber: json['serial_number']?.toString(),
      color: json['color']?.toString(),
      ram: json['ram']?.toString(),
      storage: json['storage']?.toString(),
      batteryHealth: json['battery_health']?.toString(),
      deviceCondition: json['device_condition']?.toString() ?? 'good',
      conditionNotes: json['condition_notes']?.toString(),
      accessoriesIncluded: parseList(json['accessories_included']),
      devicePhotos: parseList(json['device_photos']),
      purchaseDate: json['purchase_date'] != null
          ? DateTime.tryParse(json['purchase_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      purchasePrice: _toDouble(json['purchase_price']),
      paymentMode: json['payment_mode']?.toString() ?? 'Cash',
      purchaseNotes: json['purchase_notes']?.toString(),
      repairCost: _toDouble(json['repair_cost']),
      repairDetails: json['repair_details']?.toString(),
      totalCost: _toDouble(json['total_cost']),
      status: json['status']?.toString() ?? 'in_stock',
      saleInvoiceNumber: json['sale_invoice_number']?.toString(),
      buyerName: json['buyer_name']?.toString(),
      buyerPhone: json['buyer_phone']?.toString(),
      buyerAddress: json['buyer_address']?.toString(),
      saleDate: json['sale_date'] != null ? DateTime.tryParse(json['sale_date'].toString()) : null,
      sellingPrice: json['selling_price'] != null ? _toDouble(json['selling_price']) : null,
      salePaymentMode: json['sale_payment_mode']?.toString(),
      warrantyDays: json['warranty_days'] != null ? _toInt(json['warranty_days']) : null,
      warrantyTerms: json['warranty_terms']?.toString(),
      saleNotes: json['sale_notes']?.toString(),
      profit: json['profit'] != null ? _toDouble(json['profit']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'created_by': createdBy,
      'purchase_ref_number': purchaseRefNumber,
      'seller_name': sellerName,
      'seller_phone': sellerPhone,
      'seller_address': sellerAddress,
      'id_proof_type': idProofType,
      'id_proof_number': idProofNumber,
      'id_proof_photo': idProofImagePath,
      'id_proof_image_path': idProofImagePath,
      'id_proof_back_photo': idProofBackImagePath,
      'id_proof_back_image_path': idProofBackImagePath,
      'brand': brand,
      'model': model,
      'imei1': imei1,
      'imei2': imei2,
      'serial_number': serialNumber,
      'color': color,
      'ram': ram,
      'storage': storage,
      'battery_health': batteryHealth,
      'device_condition': deviceCondition,
      'condition_notes': conditionNotes,
      'accessories_included': accessoriesIncluded,
      'device_photos': devicePhotos,
      'purchase_date': purchaseDate.toIso8601String().split('T').first,
      'purchase_price': purchasePrice,
      'payment_mode': paymentMode,
      'purchase_notes': purchaseNotes,
      'repair_cost': repairCost,
      'repair_details': repairDetails,
      'total_cost': totalCost,
      'status': status,
      'sale_invoice_number': saleInvoiceNumber,
      'buyer_name': buyerName,
      'buyer_phone': buyerPhone,
      'buyer_address': buyerAddress,
      'sale_date': saleDate?.toIso8601String().split('T').first,
      'selling_price': sellingPrice,
      'sale_payment_mode': salePaymentMode,
      'warranty_days': warrantyDays,
      'warranty_terms': warrantyTerms,
      'sale_notes': saleNotes,
      'profit': profit,
    };
  }
}

