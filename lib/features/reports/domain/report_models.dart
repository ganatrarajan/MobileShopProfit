class SalesReportSummary {
  final double totalSales;
  final int totalTransactions;
  final double regularSales;
  final double quickSales;
  final double totalCollected;
  final double totalOutstanding;
  final double totalDiscounts;

  SalesReportSummary({
    required this.totalSales,
    required this.totalTransactions,
    required this.regularSales,
    required this.quickSales,
    required this.totalCollected,
    required this.totalOutstanding,
    required this.totalDiscounts,
  });

  factory SalesReportSummary.fromJson(Map<String, dynamic> json) {
    return SalesReportSummary(
      totalSales: double.tryParse(json['total_sales']?.toString() ?? '') ?? 0.0,
      totalTransactions: int.tryParse(json['total_transactions']?.toString() ?? '') ?? 0,
      regularSales: double.tryParse(json['regular_sales']?.toString() ?? '') ?? 0.0,
      quickSales: double.tryParse(json['quick_sales']?.toString() ?? '') ?? 0.0,
      totalCollected: double.tryParse(json['total_collected']?.toString() ?? '') ?? 0.0,
      totalOutstanding: double.tryParse(json['total_outstanding']?.toString() ?? '') ?? 0.0,
      totalDiscounts: double.tryParse(json['total_discounts']?.toString() ?? '') ?? 0.0,
    );
  }
}

class TopProductItem {
  final String productName;
  final int totalQuantity;
  final double totalRevenue;

  TopProductItem({
    required this.productName,
    required this.totalQuantity,
    required this.totalRevenue,
  });

  factory TopProductItem.fromJson(Map<String, dynamic> json) {
    return TopProductItem(
      productName: json['product_name']?.toString() ?? 'Item',
      totalQuantity: int.tryParse(json['total_quantity']?.toString() ?? '') ?? 0,
      totalRevenue: double.tryParse(json['total_revenue']?.toString() ?? '') ?? 0.0,
    );
  }
}

class RepairReportSummary {
  final int totalRepairs;
  final int completed;
  final int active;
  final int delivered;
  final int cancelled;
  final double repairRevenue;
  final double averageRepairValue;
  final Map<String, dynamic> statusDistribution;

  RepairReportSummary({
    required this.totalRepairs,
    required this.completed,
    required this.active,
    required this.delivered,
    required this.cancelled,
    required this.repairRevenue,
    required this.averageRepairValue,
    required this.statusDistribution,
  });

  factory RepairReportSummary.fromJson(Map<String, dynamic> json) {
    return RepairReportSummary(
      totalRepairs: int.tryParse(json['total_repairs']?.toString() ?? '') ?? 0,
      completed: int.tryParse(json['completed']?.toString() ?? '') ?? 0,
      active: int.tryParse(json['active']?.toString() ?? '') ?? 0,
      delivered: int.tryParse(json['delivered']?.toString() ?? '') ?? 0,
      cancelled: int.tryParse(json['cancelled']?.toString() ?? '') ?? 0,
      repairRevenue: double.tryParse(json['repair_revenue']?.toString() ?? '') ?? 0.0,
      averageRepairValue: double.tryParse(json['average_repair_value']?.toString() ?? '') ?? 0.0,
      statusDistribution: json['status_distribution'] is Map
          ? Map<String, dynamic>.from(json['status_distribution'])
          : {},
    );
  }
}

class InventoryReportSummary {
  final double totalInventoryValue;
  final int totalItems;
  final int totalStockQty;
  final int lowStock;
  final int outOfStock;
  final int stockPurchased;
  final int stockSold;
  final int stockUsedInRepairs;
  final int damagedStock;
  final int returnedStock;

  InventoryReportSummary({
    required this.totalInventoryValue,
    required this.totalItems,
    required this.totalStockQty,
    required this.lowStock,
    required this.outOfStock,
    required this.stockPurchased,
    required this.stockSold,
    required this.stockUsedInRepairs,
    required this.damagedStock,
    required this.returnedStock,
  });

  factory InventoryReportSummary.fromJson(Map<String, dynamic> json) {
    return InventoryReportSummary(
      totalInventoryValue: double.tryParse(json['total_inventory_value']?.toString() ?? '') ?? 0.0,
      totalItems: int.tryParse(json['total_items']?.toString() ?? '') ?? 0,
      totalStockQty: int.tryParse(json['total_stock_qty']?.toString() ?? '') ?? 0,
      lowStock: int.tryParse(json['low_stock']?.toString() ?? '') ?? 0,
      outOfStock: int.tryParse(json['out_of_stock']?.toString() ?? '') ?? 0,
      stockPurchased: int.tryParse(json['stock_purchased']?.toString() ?? '') ?? 0,
      stockSold: int.tryParse(json['stock_sold']?.toString() ?? '') ?? 0,
      stockUsedInRepairs: int.tryParse(json['stock_used_in_repairs']?.toString() ?? '') ?? 0,
      damagedStock: int.tryParse(json['damaged_stock']?.toString() ?? '') ?? 0,
      returnedStock: int.tryParse(json['returned_stock']?.toString() ?? '') ?? 0,
    );
  }
}

class ExpenseCategoryReport {
  final int? categoryId;
  final String categoryName;
  final double totalAmount;
  final int count;

  ExpenseCategoryReport({
    this.categoryId,
    required this.categoryName,
    required this.totalAmount,
    required this.count,
  });

  factory ExpenseCategoryReport.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryReport(
      categoryId: int.tryParse(json['category_id']?.toString() ?? ''),
      categoryName: json['category_name']?.toString() ?? 'Uncategorized',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '') ?? 0.0,
      count: int.tryParse(json['count']?.toString() ?? '') ?? 0,
    );
  }
}

class WarrantyReportSummary {
  final int totalWarranties;
  final int active;
  final int expired;
  final int totalClaims;
  final int resolvedClaims;
  final int rejectedClaims;
  final String claimRate;

  WarrantyReportSummary({
    required this.totalWarranties,
    required this.active,
    required this.expired,
    required this.totalClaims,
    required this.resolvedClaims,
    required this.rejectedClaims,
    required this.claimRate,
  });

  factory WarrantyReportSummary.fromJson(Map<String, dynamic> json) {
    return WarrantyReportSummary(
      totalWarranties: int.tryParse(json['total_warranties']?.toString() ?? '') ?? 0,
      active: int.tryParse(json['active']?.toString() ?? '') ?? 0,
      expired: int.tryParse(json['expired']?.toString() ?? '') ?? 0,
      totalClaims: int.tryParse(json['total_claims']?.toString() ?? '') ?? 0,
      resolvedClaims: int.tryParse(json['resolved_claims']?.toString() ?? '') ?? 0,
      rejectedClaims: int.tryParse(json['rejected_claims']?.toString() ?? '') ?? 0,
      claimRate: json['claim_rate']?.toString() ?? 'Not enough data.',
    );
  }
}

class OutstandingReportSummary {
  final double totalCustomerDues;
  final double totalRepairDues;
  final double totalSalesDues;
  final double totalVendorDues;
  final double netBalance;
  final int totalRecordsCount;
  final int repairsCount;
  final int salesCount;
  final int purchasesCount;

  OutstandingReportSummary({
    required this.totalCustomerDues,
    required this.totalRepairDues,
    required this.totalSalesDues,
    required this.totalVendorDues,
    required this.netBalance,
    required this.totalRecordsCount,
    required this.repairsCount,
    required this.salesCount,
    required this.purchasesCount,
  });

  factory OutstandingReportSummary.fromJson(Map<String, dynamic> json) {
    return OutstandingReportSummary(
      totalCustomerDues: double.tryParse(json['total_customer_dues']?.toString() ?? '') ?? 0.0,
      totalRepairDues: double.tryParse(json['total_repair_dues']?.toString() ?? '') ?? 0.0,
      totalSalesDues: double.tryParse(json['total_sales_dues']?.toString() ?? '') ?? 0.0,
      totalVendorDues: double.tryParse(json['total_vendor_dues']?.toString() ?? '') ?? 0.0,
      netBalance: double.tryParse(json['net_balance']?.toString() ?? '') ?? 0.0,
      totalRecordsCount: int.tryParse(json['total_records_count']?.toString() ?? '') ?? 0,
      repairsCount: int.tryParse(json['repairs_count']?.toString() ?? '') ?? 0,
      salesCount: int.tryParse(json['sales_count']?.toString() ?? '') ?? 0,
      purchasesCount: int.tryParse(json['purchases_count']?.toString() ?? '') ?? 0,
    );
  }
}

class OutstandingReportItem {
  final String id;
  final int rawId;
  final String category; // repairs, sales, purchases
  final String categoryLabel;
  final String refNumber;
  final String date;
  final String partyName;
  final String partyPhone;
  final String partyType; // customer, vendor
  final int? customerId;
  final String? deviceName;
  final String? problemDescription;
  final double? labourCost;
  final List<Map<String, dynamic>> parts;
  final List<Map<String, dynamic>> items;
  final String description;
  final double totalAmount;
  final double amountPaid;
  final double amountDue;
  final String status;

  OutstandingReportItem({
    required this.id,
    required this.rawId,
    required this.category,
    required this.categoryLabel,
    required this.refNumber,
    required this.date,
    required this.partyName,
    required this.partyPhone,
    required this.partyType,
    this.customerId,
    this.deviceName,
    this.problemDescription,
    this.labourCost,
    this.parts = const [],
    this.items = const [],
    required this.description,
    required this.totalAmount,
    required this.amountPaid,
    required this.amountDue,
    required this.status,
  });

  factory OutstandingReportItem.fromJson(Map<String, dynamic> json) {
    final due = double.tryParse(json['amount_due']?.toString() ?? '') ?? 0.0;
    final paid = double.tryParse(json['amount_paid']?.toString() ?? '') ?? 0.0;
    double total = double.tryParse(json['total_amount']?.toString() ?? '') ?? 0.0;
    if (total <= 0 && (due > 0 || paid > 0)) {
      total = due + paid;
    }

    final rawParts = json['parts'];
    List<Map<String, dynamic>> parsedParts = [];
    if (rawParts is List) {
      parsedParts = rawParts.map((x) => Map<String, dynamic>.from(x as Map)).toList();
    }

    final rawItems = json['items'];
    List<Map<String, dynamic>> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems.map((x) => Map<String, dynamic>.from(x as Map)).toList();
    }

    return OutstandingReportItem(
      id: json['id']?.toString() ?? '',
      rawId: int.tryParse(json['raw_id']?.toString() ?? '') ?? 0,
      category: json['category']?.toString() ?? 'sales',
      categoryLabel: json['category_label']?.toString() ?? 'Dues',
      refNumber: json['ref_number']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      partyName: json['party_name']?.toString() ?? 'N/A',
      partyPhone: json['party_phone']?.toString() ?? '',
      partyType: json['party_type']?.toString() ?? 'customer',
      customerId: int.tryParse(json['customer_id']?.toString() ?? ''),
      deviceName: json['device_name']?.toString(),
      problemDescription: json['problem_description']?.toString(),
      labourCost: double.tryParse(json['labour_cost']?.toString() ?? ''),
      parts: parsedParts,
      items: parsedItems,
      description: json['description']?.toString() ?? '',
      totalAmount: total,
      amountPaid: paid,
      amountDue: due,
      status: json['status']?.toString() ?? '',
    );
  }
}
