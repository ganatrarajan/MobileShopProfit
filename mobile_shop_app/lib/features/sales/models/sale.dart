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

class SaleItem {
  final int? id;
  final int? saleId;
  final int? inventoryItemId;
  final String productName;
  final String itemType; // mobile, accessory, product, service, other
  final String? brand;
  final String? model;
  final String? imei1;
  final String? imei2;
  final String? serialNumber;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double taxAmount;
  final double? costPrice;
  final double total;

  SaleItem({
    this.id,
    this.saleId,
    this.inventoryItemId,
    required this.productName,
    this.itemType = 'product',
    this.brand,
    this.model,
    this.imei1,
    this.imei2,
    this.serialNumber,
    this.quantity = 1,
    required this.unitPrice,
    this.discount = 0.0,
    this.taxAmount = 0.0,
    this.costPrice,
    double? total,
  }) : total = total ?? ((quantity * unitPrice) - discount + taxAmount);

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: _parseNullableInt(json['id']),
      saleId: _parseNullableInt(json['sale_id']),
      inventoryItemId: _parseNullableInt(json['inventory_item_id']),
      productName: json['product_name']?.toString() ?? '',
      itemType: json['item_type']?.toString() ?? 'product',
      brand: json['brand']?.toString(),
      model: json['model']?.toString(),
      imei1: json['imei_1']?.toString(),
      imei2: json['imei_2']?.toString(),
      serialNumber: json['serial_number']?.toString(),
      quantity: _parseInt(json['quantity'], defaultValue: 1),
      unitPrice: _parseDouble(json['unit_price']),
      discount: _parseDouble(json['discount']),
      taxAmount: _parseDouble(json['tax_amount']),
      costPrice: json['cost_price'] != null ? _parseDouble(json['cost_price']) : null,
      total: _parseDouble(json['total']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      if (inventoryItemId != null) 'inventory_item_id': inventoryItemId,
      'product_name': productName,
      'item_type': itemType,
      'brand': brand,
      'model': model,
      'imei_1': imei1,
      'imei_2': imei2,
      'serial_number': serialNumber,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'tax_amount': taxAmount,
      'cost_price': costPrice,
      'total': total,
    };
  }
}

class SalePayment {
  final int id;
  final int shopId;
  final int saleId;
  final double amount;
  final String paymentMethod; // cash, upi, card, bank_transfer, other
  final String? paymentDate;
  final String? notes;
  final int? createdBy;
  final String? creatorName;
  final String? createdAt;

  SalePayment({
    required this.id,
    required this.shopId,
    required this.saleId,
    required this.amount,
    required this.paymentMethod,
    this.paymentDate,
    this.notes,
    this.createdBy,
    this.creatorName,
    this.createdAt,
  });

  factory SalePayment.fromJson(Map<String, dynamic> json) {
    return SalePayment(
      id: _parseInt(json['id']),
      shopId: _parseInt(json['shop_id']),
      saleId: _parseInt(json['sale_id']),
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
      'sale_id': saleId,
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

class Sale {
  final int id;
  final int shopId;
  final String saleType; // quick, regular
  final int? customerId;
  final String? customerName;
  final String? customerMobile;
  final int? deviceId;
  final String invoiceNumber;
  final String saleDate;
  final double subtotal;
  final double discount;
  final double taxAmount;
  final double grandTotal;
  final double amountPaid;
  final double amountDue;
  final String paymentStatus; // paid, partially_paid, due
  final String? notes;
  final int? createdBy;
  final String? creatorName;
  final Customer? customer;
  final Device? device;
  final List<SaleItem> items;
  final List<SalePayment> payments;
  final String? createdAt;
  final String? updatedAt;

  double get totalDiscount {
    double itemDiscounts = 0.0;
    for (final item in items) {
      itemDiscounts += item.discount;
    }
    return discount + itemDiscounts;
  }

  bool get isQuickSale => saleType == 'quick';

  Sale({
    required this.id,
    required this.shopId,
    this.saleType = 'regular',
    this.customerId,
    this.customerName,
    this.customerMobile,
    this.deviceId,
    required this.invoiceNumber,
    required this.saleDate,
    required this.subtotal,
    this.discount = 0.0,
    this.taxAmount = 0.0,
    required this.grandTotal,
    this.amountPaid = 0.0,
    required this.amountDue,
    required this.paymentStatus,
    this.notes,
    this.createdBy,
    this.creatorName,
    this.customer,
    this.device,
    this.items = const [],
    this.payments = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: _parseInt(json['id']),
      shopId: _parseInt(json['shop_id']),
      saleType: json['sale_type']?.toString() ?? 'regular',
      customerId: _parseNullableInt(json['customer_id']),
      customerName: json['customer_name']?.toString(),
      customerMobile: json['customer_mobile']?.toString(),
      deviceId: _parseNullableInt(json['device_id']),
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      saleDate: json['sale_date']?.toString() ?? '',
      subtotal: _parseDouble(json['subtotal']),
      discount: _parseDouble(json['discount']),
      taxAmount: _parseDouble(json['tax_amount']),
      grandTotal: _parseDouble(json['grand_total']),
      amountPaid: _parseDouble(json['amount_paid']),
      amountDue: _parseDouble(json['amount_due']),
      paymentStatus: json['payment_status']?.toString() ?? 'due',
      notes: json['notes']?.toString(),
      createdBy: _parseNullableInt(json['created_by']),
      creatorName: json['creator_name']?.toString(),
      customer: json['customer'] != null && json['customer'] is Map<String, dynamic>
          ? Customer.fromJson(json['customer'])
          : null,
      device: json['device'] != null && json['device'] is Map<String, dynamic>
          ? Device.fromJson(json['device'])
          : null,
      items: json['items'] != null && json['items'] is List
          ? (json['items'] as List).map((i) => SaleItem.fromJson(i as Map<String, dynamic>)).toList()
          : [],
      payments: json['payments'] != null && json['payments'] is List
          ? (json['payments'] as List).map((p) => SalePayment.fromJson(p as Map<String, dynamic>)).toList()
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
      'invoice_number': invoiceNumber,
      'sale_date': saleDate,
      'subtotal': subtotal,
      'discount': discount,
      'tax_amount': taxAmount,
      'grand_total': grandTotal,
      'amount_paid': amountPaid,
      'amount_due': amountDue,
      'payment_status': paymentStatus,
      'notes': notes,
      'created_by': createdBy,
      'creator_name': creatorName,
      'customer': customer?.toJson(),
      'device': device?.toJson(),
      'items': items.map((i) => i.toJson()).toList(),
      'payments': payments.map((p) => p.toJson()).toList(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
