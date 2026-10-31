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

class UsedMobileStats {
  final int totalPurchasedCount;
  final double totalPurchasedAmount;
  final int inStockCount;
  final double inStockInvestment;
  final int soldCount;
  final double totalSaleRevenue;
  final double totalProfitEarned;
  final double profitMarginPercentage;

  UsedMobileStats({
    this.totalPurchasedCount = 0,
    this.totalPurchasedAmount = 0.0,
    this.inStockCount = 0,
    this.inStockInvestment = 0.0,
    this.soldCount = 0,
    this.totalSaleRevenue = 0.0,
    this.totalProfitEarned = 0.0,
    this.profitMarginPercentage = 0.0,
  });

  factory UsedMobileStats.fromJson(Map<String, dynamic> json) {
    return UsedMobileStats(
      totalPurchasedCount: _toInt(json['total_purchased_count']),
      totalPurchasedAmount: _toDouble(json['total_purchased_amount']),
      inStockCount: _toInt(json['in_stock_count']),
      inStockInvestment: _toDouble(json['in_stock_investment']),
      soldCount: _toInt(json['sold_count']),
      totalSaleRevenue: _toDouble(json['total_sale_revenue']),
      totalProfitEarned: _toDouble(json['total_profit_earned']),
      profitMarginPercentage: _toDouble(json['profit_margin_percentage']),
    );
  }

  factory UsedMobileStats.empty() {
    return UsedMobileStats();
  }
}

