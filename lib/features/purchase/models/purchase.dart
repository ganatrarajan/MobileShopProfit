import 'vendor.dart';
import 'purchase_item.dart';
import 'purchase_payment.dart';

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
        ? rawItems.map((i) => PurchaseItem.fromJson(i as Map<String, dynamic>)).toList()
        : [];

    var rawPayments = json['payments'] as List?;
    List<PurchasePayment> paymentList = rawPayments != null
        ? rawPayments.map((p) => PurchasePayment.fromJson(p as Map<String, dynamic>)).toList()
        : [];

    return Purchase(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      shopId: json['shop_id'] is int ? json['shop_id'] as int : int.parse((json['shop_id'] ?? 0).toString()),
      vendorId: json['vendor_id'] is int ? json['vendor_id'] as int : int.parse(json['vendor_id'].toString()),
      vendorName: json['vendor_name']?.toString() ?? (json['vendor']?['name']?.toString() ?? 'Vendor'),
      vendor: json['vendor'] != null ? Vendor.fromJson(json['vendor'] as Map<String, dynamic>) : null,
      purchaseNumber: json['purchase_number']?.toString() ?? '',
      purchaseDate: json['purchase_date'] != null ? DateTime.parse(json['purchase_date'].toString()) : DateTime.now(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      additionalCharges: (json['additional_charges'] ?? 0).toDouble(),
      grandTotal: (json['grand_total'] ?? 0).toDouble(),
      amountPaid: (json['amount_paid'] ?? 0).toDouble(),
      outstandingAmount: (json['outstanding_amount'] ?? 0).toDouble(),
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      isStockAdded: json['is_stock_added'] == true || json['is_stock_added'] == 1,
      notes: json['notes']?.toString(),
      items: itemList,
      payments: paymentList,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}
