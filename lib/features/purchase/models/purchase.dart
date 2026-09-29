import 'vendor.dart';
import 'purchase_item.dart';
import 'purchase_payment.dart';

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

class Purchase {
  final int id;
  final int shopId;
  final int vendorId;
  final String vendorName;
  final Vendor? vendor;
  final String purchaseNumber;
  final DateTime purchaseDate;
  final double subtotal;
  final double discount;
  final double additionalCharges;
  final double grandTotal;
  final double amountPaid;
  final double outstandingAmount;
  final String paymentStatus; // paid, partial, pending
  final bool isStockAdded;
  final String? notes;
  final List<PurchaseItem> items;
  final List<PurchasePayment> payments;
  final DateTime? createdAt;

  Purchase({
    required this.id,
    required this.shopId,
    required this.vendorId,
    required this.vendorName,
    this.vendor,
    required this.purchaseNumber,
    required this.purchaseDate,
    required this.subtotal,
    this.discount = 0.0,
    this.additionalCharges = 0.0,
    required this.grandTotal,
    this.amountPaid = 0.0,
    this.outstandingAmount = 0.0,
    required this.paymentStatus,
    this.isStockAdded = true,
    this.notes,
    this.items = const [],
    this.payments = const [],
    this.createdAt,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List?;
    List<PurchaseItem> itemList = rawItems != null
        ? rawItems.map((i) => PurchaseItem.fromJson(Map<String, dynamic>.from(i as Map))).toList()
        : [];

    var rawPayments = json['payments'] as List?;
    List<PurchasePayment> paymentList = rawPayments != null
        ? rawPayments.map((p) => PurchasePayment.fromJson(Map<String, dynamic>.from(p as Map))).toList()
        : [];

    return Purchase(
      id: _toInt(json['id']),
      shopId: _toInt(json['shop_id']),
      vendorId: _toInt(json['vendor_id']),
      vendorName: json['vendor_name']?.toString() ?? (json['vendor']?['name']?.toString() ?? 'Vendor'),
      vendor: json['vendor'] != null && json['vendor'] is Map ? Vendor.fromJson(Map<String, dynamic>.from(json['vendor'] as Map)) : null,
      purchaseNumber: json['purchase_number']?.toString() ?? '',
      purchaseDate: json['purchase_date'] != null ? DateTime.tryParse(json['purchase_date'].toString()) ?? DateTime.now() : DateTime.now(),
      subtotal: _toDouble(json['subtotal']),
      discount: _toDouble(json['discount']),
      additionalCharges: _toDouble(json['additional_charges']),
      grandTotal: _toDouble(json['grand_total']),
      amountPaid: _toDouble(json['amount_paid']),
      outstandingAmount: _toDouble(json['outstanding_amount']),
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      isStockAdded: json['is_stock_added'] == true || json['is_stock_added'] == 1 || json['is_stock_added']?.toString() == '1',
      notes: json['notes']?.toString(),
      items: itemList,
      payments: paymentList,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}