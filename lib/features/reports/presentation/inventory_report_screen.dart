import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../data/reports_repository.dart';
import '../domain/report_models.dart';
import 'widgets/report_period_selector.dart';

class InventoryReportScreen extends StatefulWidget {
  const InventoryReportScreen({super.key});

  @override
  State<InventoryReportScreen> createState() => _InventoryReportScreenState();
}

class _InventoryReportScreenState extends State<InventoryReportScreen> {
  final ReportsRepository _repository = ReportsRepository();

  String _selectedPeriod = 'this_month';
  DateTimeRange? _customDateRange;

  bool _isLoading = true;
  String? _errorMessage;

  InventoryReportSummary? _summary;
  List<dynamic> _topSelling = [];
  dynamic _slowMoving;
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

      final res = await _repository.getInventoryReport(
        period: _selectedPeriod,
        startDate: startStr,
        endDate: endStr,
      );

      if (mounted) {
        if (res.success && res.data != null) {
          final data = res.data!;
          final summaryJson = data['summary'] is Map ? Map<String, dynamic>.from(data['summary']) : null;
          final detailsData = data['details'];
          List<dynamic>? detailsJson;
          if (detailsData is Map && detailsData['data'] is List) {
            detailsJson = detailsData['data'] as List<dynamic>;
          } else if (detailsData is List) {
            detailsJson = detailsData;
          }

          setState(() {
            _summary = summaryJson != null ? InventoryReportSummary.fromJson(summaryJson) : null;
            _topSelling = data['top_selling'] is List ? (data['top_selling'] as List<dynamic>) : [];
            _slowMoving = data['slow_moving'];
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
        title: const Text('Inventory Report'),
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
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.6,
                                children: [
                                  _buildSummaryTile(
                                    title: 'Total Stock Value',
                                    value: '₹ ${_summary!.totalInventoryValue.toStringAsFixed(0)}',
                                    icon: Icons.monetization_on_rounded,
                                    color: Colors.teal.shade700,
                                  ),
                                  _buildSummaryTile(
                                    title: 'Total Stock Quantity',
                                    value: '${_summary!.totalStockQty} pcs',
                                    icon: Icons.widgets_rounded,
                                    color: Colors.indigo.shade700,
                                  ),
                                  _buildSummaryTile(
                                    title: 'Total Product Items',
                                    value: '${_summary!.totalItems}',
                                    icon: Icons.inventory_2_rounded,
                                    color: Colors.blue.shade700,
                                  ),
                                  _buildSummaryTile(
                                    title: 'Low / Out of Stock',
                                    value: '${_summary!.lowStock + _summary!.outOfStock}',
                                    icon: Icons.warning_amber_rounded,
                                    color: Colors.amber.shade800,
                                  ),
                                  _buildSummaryTile(
                                    title: 'Purchased (In Period)',
                                    value: '${_summary!.stockPurchased} pcs',
                                    icon: Icons.shopping_bag_rounded,
                                    color: Colors.green.shade700,
                                  ),
                                  _buildSummaryTile(
                                    title: 'Sold (In Period)',
                                    value: '${_summary!.stockSold} pcs',
                                    icon: Icons.sell_rounded,
                                    color: Colors.orange.shade800,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],

                            if (_topSelling.isNotEmpty) ...[
                              const Text('Top Selling Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(height: 8),
                              CustomCard(
                                padding: const EdgeInsets.all(12),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _topSelling.length,
                                  separatorBuilder: (ctx, idx) => const Divider(height: 1),
                                  itemBuilder: (ctx, idx) {
                                    final item = _topSelling[idx];
                                    final name = item['name']?.toString() ?? item['inventory_item']?['name']?.toString() ?? 'Item';
                                    final totalQty = int.tryParse(item['quantity_sold']?.toString() ?? '') ?? int.tryParse(item['total_qty']?.toString() ?? '') ?? 0;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 12,
                                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                                child: Text('${idx + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                            ],
                                          ),
                                          Text('$totalQty sold', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Slow moving section
                            const Text('Slow Moving Inventory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(height: 8),
                            CustomCard(
                              padding: const EdgeInsets.all(14),
                              child: _slowMoving is String
                                  ? Text(_slowMoving.toString(), style: const TextStyle(color: AppColors.textMuted))
                                  : (_slowMoving is List && (_slowMoving as List).isEmpty)
                                      ? const Text('No slow moving items.', style: TextStyle(color: AppColors.textMuted))
                                      : ListView.separated(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: (_slowMoving as List).length,
                                          separatorBuilder: (ctx, idx) => const Divider(height: 1),
                                          itemBuilder: (ctx, idx) {
                                            final item = _slowMoving[idx];
                                            final st = int.tryParse(item['current_stock']?.toString() ?? '') ?? 0;
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(item['name']?.toString() ?? 'Item', style: const TextStyle(fontWeight: FontWeight.w600)),
                                                  Text('Stock: $st', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                            ),
                            const SizedBox(height: 20),

                            // Inventory details table
                            const Text('Inventory Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(height: 10),
                            _detailsList.isEmpty
                                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No inventory items found.', style: TextStyle(color: AppColors.textMuted))))
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _detailsList.length,
                                    separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                                    itemBuilder: (ctx, idx) {
                                      final item = _detailsList[idx];
                                      final name = item['name']?.toString() ?? 'Item';
                                      final cat = item['category']?.toString() ?? 'General';
                                      final stock = int.tryParse(item['current_stock']?.toString() ?? '') ?? 0;
                                      final cost = double.tryParse(item['purchase_price']?.toString() ?? '') ?? 0.0;

                                      return CustomCard(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                                const SizedBox(height: 4),
                                                Text('Category: $cat', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text('Stock: $stock pcs', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: stock <= 0 ? Colors.red : Colors.green.shade800)),
                                                Text('Cost: ₹ ${cost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
