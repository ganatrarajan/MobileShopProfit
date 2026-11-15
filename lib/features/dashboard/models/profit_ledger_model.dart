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

class ProfitLedgerSummary {
  final double totalNetProfit;
  final double salesProfit;
  final double repairProfit;
  final double usedMobileProfit;
  final double totalRevenue;
  final double totalCost;
  final int totalCount;
  final int salesCount;
  final int repairCount;
  final int usedMobileCount;

  ProfitLedgerSummary({
    this.totalNetProfit = 0.0,
    this.salesProfit = 0.0,
    this.repairProfit = 0.0,
    this.usedMobileProfit = 0.0,
    this.totalRevenue = 0.0,
    this.totalCost = 0.0,
    this.totalCount = 0,
    this.salesCount = 0,
    this.repairCount = 0,
    this.usedMobileCount = 0,
  });

  factory ProfitLedgerSummary.fromJson(Map<String, dynamic> json) {
    return ProfitLedgerSummary(
      totalNetProfit: _parseDouble(json['total_net_profit']),
      salesProfit: _parseDouble(json['sales_profit']),
      repairProfit: _parseDouble(json['repair_profit']),
      usedMobileProfit: _parseDouble(json['used_mobile_profit']),
      totalRevenue: _parseDouble(json['total_revenue']),
      totalCost: _parseDouble(json['total_cost']),
      totalCount: _parseInt(json['total_count']),
      salesCount: _parseInt(json['sales_count']),
      repairCount: _parseInt(json['repair_count']),
      usedMobileCount: _parseInt(json['used_mobile_count']),
    );
  }
}

class ProfitLedgerItem {
  final int id;
  final String type; // 'sale' | 'repair' | 'used_mobile'
  final String typeLabel;
  final String refNumber;
  final String title;
  final String customerName;
  final String customerPhone;
  final String date;
  final String formattedDate;
  final double revenue;
  final double amountPaid;
  final double cost;
  final double profit;
  final double profitMargin;
  final String status;
  final String costBreakdown;

  ProfitLedgerItem({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.refNumber,
    required this.title,
    required this.customerName,
    required this.customerPhone,
    required this.date,
    required this.formattedDate,
    required this.revenue,
    required this.amountPaid,
    required this.cost,
    required this.profit,
    required this.profitMargin,
    required this.status,
    required this.costBreakdown,
  });

  factory ProfitLedgerItem.fromJson(Map<String, dynamic> json) {
    return ProfitLedgerItem(
      id: _parseInt(json['id']),
      type: json['type']?.toString() ?? 'sale',
      typeLabel: json['type_label']?.toString() ?? 'Sale',
      refNumber: json['ref_number']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'Customer',
      customerPhone: json['customer_phone']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      formattedDate: json['formatted_date']?.toString() ?? '',
      revenue: _parseDouble(json['revenue']),
      amountPaid: _parseDouble(json['amount_paid']),
      cost: _parseDouble(json['cost']),
      profit: _parseDouble(json['profit']),
      profitMargin: _parseDouble(json['profit_margin']),
      status: json['status']?.toString() ?? 'paid',
      costBreakdown: json['cost_breakdown']?.toString() ?? '',
    );
  }
}

class ProfitLedgerResponse {
  final String period;
  final String category;
  final String startDate;
  final String endDate;
  final ProfitLedgerSummary summary;
  final List<ProfitLedgerItem> items;

  ProfitLedgerResponse({
    required this.period,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.summary,
    required this.items,
  });

  factory ProfitLedgerResponse.fromJson(Map<String, dynamic> json) {
    // Check if the response is nested inside a 'data' Map
    final Map<String, dynamic> dataMap = (json['data'] is Map)
        ? Map<String, dynamic>.from(json['data'])
        : json;

    final dateRange = (dataMap['date_range'] is Map)
        ? dataMap['date_range']
        : (json['date_range'] is Map ? json['date_range'] : {});

    final summaryRaw = dataMap['summary'] ?? json['summary'] ?? {};
    final summaryObj = ProfitLedgerSummary.fromJson(
        Map<String, dynamic>.from(summaryRaw is Map ? summaryRaw : {}));

    dynamic rawItems = dataMap['items'] ?? dataMap['data'] ?? json['items'] ?? json['data'];
    if (rawItems is! List) {
      rawItems = [];
    }

    final itemsList = rawItems
        .map((i) => ProfitLedgerItem.fromJson(Map<String, dynamic>.from(i is Map ? i : {})))
        .toList();

    return ProfitLedgerResponse(
      period: (dataMap['period'] ?? json['period'])?.toString() ?? 'this_month',
      category: (dataMap['category'] ?? json['category'])?.toString() ?? 'all',
      startDate: dateRange['start_date']?.toString() ?? '',
      endDate: dateRange['end_date']?.toString() ?? '',
      summary: summaryObj,
      items: itemsList,
    );
  }
}

