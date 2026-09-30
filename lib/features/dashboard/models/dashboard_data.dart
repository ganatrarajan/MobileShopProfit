double _parseDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}

int _parseInt(dynamic val) {
  if (val == null) return 0;
  if (val is int) return val;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString()) ?? 0;
}

class FinancialOverview {
  final double totalSales;
  final double totalPurchases;
  final double totalExpenses;
  final double netProfit;
  final double cashCollected;
  final double cashPaidPurchases;
  final double cashPaidExpenses;
  final double netCashRemaining;

  FinancialOverview({
    required this.totalSales,
    required this.totalPurchases,
    required this.totalExpenses,
    required this.netProfit,
    required this.cashCollected,
    required this.cashPaidPurchases,
    required this.cashPaidExpenses,
    required this.netCashRemaining,
  });

  factory FinancialOverview.fromJson(Map<String, dynamic> json) {
    return FinancialOverview(
      totalSales: _parseDouble(json['total_sales']),
      totalPurchases: _parseDouble(json['total_purchases']),
      totalExpenses: _parseDouble(json['total_expenses']),
      netProfit: _parseDouble(json['net_profit']),
      cashCollected: _parseDouble(json['cash_collected']),
      cashPaidPurchases: _parseDouble(json['cash_paid_purchases']),
      cashPaidExpenses: _parseDouble(json['cash_paid_expenses']),
      netCashRemaining: _parseDouble(json['net_cash_remaining']),
    );
  }
}

class SalesSummary {
  final double totalSales;
  final double totalCollected;
  final double totalDue;
  final int totalCount;
  final int regularSalesCount;
  final int quickSalesCount;
  final double allTimeDues;

  SalesSummary({
    required this.totalSales,
    required this.totalCollected,
    required this.totalDue,
    required this.totalCount,
    required this.regularSalesCount,
    required this.quickSalesCount,
    required this.allTimeDues,
  });

  factory SalesSummary.fromJson(Map<String, dynamic> json) {
    return SalesSummary(
      totalSales: _parseDouble(json['total_sales']),
      totalCollected: _parseDouble(json['total_collected']),
      totalDue: _parseDouble(json['total_due']),
      totalCount: _parseInt(json['total_count']),
      regularSalesCount: _parseInt(json['regular_sales_count']),
      quickSalesCount: _parseInt(json['quick_sales_count']),
      allTimeDues: _parseDouble(json['all_time_dues']),
    );
  }
}

class PurchaseSummary {
  final double totalPurchases;
  final double totalPaid;
  final double totalOutstanding;
  final int totalCount;
  final double allTimeVendorDues;

  PurchaseSummary({
    required this.totalPurchases,
    required this.totalPaid,
    required this.totalOutstanding,
    required this.totalCount,
    required this.allTimeVendorDues,
  });

  factory PurchaseSummary.fromJson(Map<String, dynamic> json) {
    return PurchaseSummary(
      totalPurchases: _parseDouble(json['total_purchases']),
      totalPaid: _parseDouble(json['total_paid']),
      totalOutstanding: _parseDouble(json['total_outstanding']),
      totalCount: _parseInt(json['total_count']),
      allTimeVendorDues: _parseDouble(json['all_time_vendor_dues']),
    );
  }
}

class RepairSummary {
  final int activeRepairsCount;
  final int readyCount;
  final int waitingCustomerCount;
  final int waitingPartsCount;
  final int totalRepairsCount;

  RepairSummary({
    required this.activeRepairsCount,
    required this.readyCount,
    required this.waitingCustomerCount,
    required this.waitingPartsCount,
    required this.totalRepairsCount,
  });

  factory RepairSummary.fromJson(Map<String, dynamic> json) {
    return RepairSummary(
      activeRepairsCount: _parseInt(json['active_repairs_count']),
      readyCount: _parseInt(json['ready_count']),
      waitingCustomerCount: _parseInt(json['waiting_customer_count']),
      waitingPartsCount: _parseInt(json['waiting_parts_count']),
      totalRepairsCount: _parseInt(json['total_repairs_count']),
    );
  }
}

class InventorySummary {
  final int totalItems;
  final int lowStockCount;
  final int outOfStockCount;
  final double totalStockValue;

  InventorySummary({
    required this.totalItems,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.totalStockValue,
  });

  factory InventorySummary.fromJson(Map<String, dynamic> json) {
    return InventorySummary(
      totalItems: _parseInt(json['total_items']),
      lowStockCount: _parseInt(json['low_stock_count']),
      outOfStockCount: _parseInt(json['out_of_stock_count']),
      totalStockValue: _parseDouble(json['total_stock_value']),
    );
  }
}

class TopExpenseCategory {
  final String name;
  final double amount;

  TopExpenseCategory({required this.name, required this.amount});

  factory TopExpenseCategory.fromJson(Map<String, dynamic> json) {
    return TopExpenseCategory(
      name: json['name']?.toString() ?? 'Other',
      amount: _parseDouble(json['amount']),
    );
  }
}

class ExpenseSummary {
  final double totalExpensesSum;
  final TopExpenseCategory? topCategory;

  ExpenseSummary({
    required this.totalExpensesSum,
    this.topCategory,
  });

  factory ExpenseSummary.fromJson(Map<String, dynamic> json) {
    return ExpenseSummary(
      totalExpensesSum: _parseDouble(json['total_expenses_sum']),
      topCategory: json['top_category'] != null && json['top_category'] is Map<String, dynamic>
          ? TopExpenseCategory.fromJson(Map<String, dynamic>.from(json['top_category']))
          : null,
    );
  }
}

class AttentionItem {
  final String type;
  final String title;
  final String subtitle;
  final int? count;
  final double? amount;
  final String actionRoute;
  final String filter;

  AttentionItem({
    required this.type,
    required this.title,
    required this.subtitle,
    this.count,
    this.amount,
    required this.actionRoute,
    required this.filter,
  });

  factory AttentionItem.fromJson(Map<String, dynamic> json) {
    return AttentionItem(
      type: json['type']?.toString() ?? 'general',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      count: json['count'] != null ? _parseInt(json['count']) : null,
      amount: json['amount'] != null ? _parseDouble(json['amount']) : null,
      actionRoute: json['action_route']?.toString() ?? 'dashboard',
      filter: json['filter']?.toString() ?? 'all',
    );
  }
}

class RecentActivityItem {
  final String type; // sale, purchase, repair, expense, stock
  final String title;
  final String subtitle;
  final double amount;
  final String time;

  RecentActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.time,
  });

  factory RecentActivityItem.fromJson(Map<String, dynamic> json) {
    return RecentActivityItem(
      type: json['type']?.toString() ?? 'sale',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      time: json['time']?.toString() ?? '',
    );
  }
}

class DashboardData {
  final String period;
  final String startDate;
  final String endDate;
  final bool isEmptyShop;
  final String shopName;
  final String ownerName;
  final int daysRemaining;
  final bool isExpiringSoon;
  final FinancialOverview financialOverview;
  final SalesSummary sales;
  final PurchaseSummary purchases;
  final RepairSummary repairs;
  final InventorySummary inventory;
  final ExpenseSummary expenses;
  final List<AttentionItem> attention;
  final List<RecentActivityItem> recentActivity;

  DashboardData({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.isEmptyShop,
    this.shopName = 'Mobile Repair Shop',
    this.ownerName = 'Shop Owner',
    this.daysRemaining = 999,
    this.isExpiringSoon = false,
    required this.financialOverview,
    required this.sales,
    required this.purchases,
    required this.repairs,
    required this.inventory,
    required this.expenses,
    required this.attention,
    required this.recentActivity,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> dataMap = (json.containsKey('data') && json['data'] is Map<String, dynamic>)
        ? json['data']
        : json;

    final dateRange = json['date_range'] is Map ? json['date_range'] : {};

    List attList = dataMap['attention'] is List ? dataMap['attention'] : [];
    List actList = dataMap['recent_activity'] is List ? dataMap['recent_activity'] : [];

    final String sName = (json['shop_name'] ??
            dataMap['shop_name'] ??
            (json['shop'] is Map ? json['shop']['name'] : null) ??
            (dataMap['shop'] is Map ? dataMap['shop']['name'] : null) ??
            (json['shop'] is Map ? json['shop']['shop_name'] : null) ??
            (dataMap['shop'] is Map ? dataMap['shop']['shop_name'] : null))
        ?.toString() ??
        '';

    final String oName = (json['owner_name'] ??
            dataMap['owner_name'] ??
            (json['shop'] is Map ? json['shop']['owner_name'] : null) ??
            (dataMap['shop'] is Map ? dataMap['shop']['owner_name'] : null) ??
            (json['user'] is Map ? json['user']['name'] : null) ??
            (dataMap['user'] is Map ? dataMap['user']['name'] : null))
        ?.toString() ??
        '';

    final int dRemaining = _parseInt(dataMap['days_remaining'] ?? json['days_remaining'] ?? 999);
    final bool expiring = (dataMap['is_expiring_soon'] == true || dRemaining <= 10);

    final salesObj = SalesSummary.fromJson(Map<String, dynamic>.from(dataMap['sales'] ?? {}));
    final purchasesObj = PurchaseSummary.fromJson(Map<String, dynamic>.from(dataMap['purchases'] ?? {}));
    final expensesObj = ExpenseSummary.fromJson(Map<String, dynamic>.from(dataMap['expenses'] ?? {}));

    FinancialOverview finOverview;
    if (dataMap['financial_overview'] != null && dataMap['financial_overview'] is Map<String, dynamic>) {
      finOverview = FinancialOverview.fromJson(Map<String, dynamic>.from(dataMap['financial_overview']));
    } else {
      final nProfit = salesObj.totalSales - purchasesObj.totalPurchases - expensesObj.totalExpensesSum;
      final cRem = salesObj.totalCollected - purchasesObj.totalPaid - expensesObj.totalExpensesSum;
      finOverview = FinancialOverview(
        totalSales: salesObj.totalSales,
        totalPurchases: purchasesObj.totalPurchases,
        totalExpenses: expensesObj.totalExpensesSum,
        netProfit: nProfit,
        cashCollected: salesObj.totalCollected,
        cashPaidPurchases: purchasesObj.totalPaid,
        cashPaidExpenses: expensesObj.totalExpensesSum,
        netCashRemaining: cRem,
      );
    }

    return DashboardData(
      period: json['period']?.toString() ?? 'this_month',
      startDate: dateRange['start_date']?.toString() ?? '',
      endDate: dateRange['end_date']?.toString() ?? '',
      isEmptyShop: json['is_empty_shop'] == true,
      shopName: sName.isNotEmpty ? sName : 'Mobile Repair Shop',
      ownerName: oName.isNotEmpty ? oName : 'Shop Owner',
      daysRemaining: dRemaining,
      isExpiringSoon: expiring,
      financialOverview: finOverview,
      sales: salesObj,
      purchases: purchasesObj,
      repairs: RepairSummary.fromJson(Map<String, dynamic>.from(dataMap['repairs'] ?? {})),
      inventory: InventorySummary.fromJson(Map<String, dynamic>.from(dataMap['inventory'] ?? {})),
      expenses: expensesObj,
      attention: attList.map((a) => AttentionItem.fromJson(Map<String, dynamic>.from(a))).toList(),
      recentActivity: actList.map((a) => RecentActivityItem.fromJson(Map<String, dynamic>.from(a))).toList(),
    );
  }
}
