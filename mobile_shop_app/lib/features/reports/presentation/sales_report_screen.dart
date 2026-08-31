import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../data/reports_repository.dart';
import '../domain/report_models.dart';
import 'widgets/report_period_selector.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  final ReportsRepository _repository = ReportsRepository();

  String _selectedPeriod = 'this_month';
  DateTimeRange? _customDateRange;

  bool _isLoading = true;
  String? _errorMessage;

  SalesReportSummary? _summary;
  List<TopProductItem> _topProducts = [];
  List<dynamic> _detailsList = [];

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? startStr;
      String? endStr;
      if (_selectedPeriod == 'custom' && _customDateRange != null) {
        startStr = _customDateRange!.start.toIso8601String();
        endStr = _customDateRange!.end.toIso8601String();
      }

      final res = await _repository.getSalesReport(
        period: _selectedPeriod,
        startDate: startStr,
        endDate: endStr,
      );

      if (mounted) {
        if (res.success && res.data != null) {
          final data = res.data!;
          final summaryJson = data['summary'] as Map<String, dynamic>?;
          final topJson = data['top_products'] as List<dynamic>?;
          final detailsJson = data['details']?['data'] as List<dynamic>?;

          setState(() {
            _summary = summaryJson != null ? SalesReportSummary.fromJson(summaryJson) : null;
            _topProducts = topJson != null ? topJson.map((x) => TopProductItem.fromJson(x)).toList() : [];
            _detailsList = detailsJson ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = res.message;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPeriod = 'custom';
      });
      _fetchReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sales Report'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          ReportPeriodSelector(
            selectedPeriod: _selectedPeriod,
            onPeriodSelected: (period) {
              setState(() => _selectedPeriod = period);
              _fetchReport();
            },
            onCustomDateTap: _pickCustomDateRange,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _fetchReport, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchReport,
                        child: ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: [
                            if (_summary != null) ...[
                              // Summary Grid
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.6,
                                children: [
                                  _buildSummaryTile(
                                    title: 'Total Sales',
                                    value: '₹ ${_summary!.totalSales.toStringAsFixed(0)}',
                                    icon: Icons.receipt_long_rounded,
                                    color: Colors.blue.shade700,
                                  ),
                                  _buildSummaryTile(
                                    title: 'Transactions',
                                    value: '${_summary!.totalTransactions}',
                                    icon: Icons.confirmation_number_rounded,
                                    color: Colors.indigo.shade700,
                                  ),
                                  _buildSummaryTile(
                                    title: 'Regular Sales',
                                    value: '₹ ${_summary!.regularSales.toStringAsFixed(0)}',
                                    icon: Icons.storefront_rounded,
                                    color: Colors.teal.shade700,
                                  ),
                                  _buildSummaryTile(
                                    title: 'Quick Sales',
                                    value: '₹ ${_summary!.quickSales.toStringAsFixed(0)}',
                                    icon: Icons.bolt_rounded,
                                    color: Colors.amber.shade800,
                                  ),
                                  _buildSummaryTile(
                                    title: 'Total Collected',
                                    value: '₹ ${_summary!.totalCollected.toStringAsFixed(0)}',
                                    icon: Icons.check_circle_rounded,
                                    color: Colors.green.shade700,
                                  ),
                                  _buildSummaryTile(
                                    title: 'Outstanding',
                                    value: '₹ ${_summary!.totalOutstanding.toStringAsFixed(0)}',
                                    icon: Icons.pending_actions_rounded,
                                    color: Colors.red.shade700,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Top Selling Products Section
                            if (_topProducts.isNotEmpty) ...[
                              const Text('Top Selling Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(height: 10),
                              CustomCard(
                                padding: const EdgeInsets.all(12),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _topProducts.length,
                                  separatorBuilder: (ctx, idx) => const Divider(height: 1),
                                  itemBuilder: (ctx, idx) {
                                    final p = _topProducts[idx];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 14,
                                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                                child: Text('${idx + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(p.productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text('${p.totalQuantity} sold', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                              Text('₹ ${p.totalRevenue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Sales Detail List
                            const Text('Sales Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(height: 10),
                            _detailsList.isEmpty
                                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No transactions in selected period.', style: TextStyle(color: AppColors.textMuted))))
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _detailsList.length,
                                    separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                                    itemBuilder: (ctx, idx) {
                                      final item = _detailsList[idx];
                                      final inv = item['invoice_number']?.toString() ?? 'INV';
                                      final cust = item['customer_name']?.toString() ?? 'Walk-in Customer';
                                      final total = double.tryParse(item['grand_total']?.toString() ?? '') ?? 0.0;
                                      final paid = double.tryParse(item['amount_paid']?.toString() ?? '') ?? 0.0;
                                      final type = item['sale_type']?.toString() ?? 'regular';

                                      return CustomCard(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(inv, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(color: type == 'quick' ? Colors.amber.shade100 : Colors.blue.shade100, borderRadius: BorderRadius.circular(4)),
                                                      child: Text(type.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: type == 'quick' ? Colors.amber.shade900 : Colors.blue.shade900)),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(cust, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text('₹ ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                                Text('Paid: ₹ ${paid.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Colors.green)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
