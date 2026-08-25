import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../data/reports_repository.dart';
import '../domain/report_models.dart';
import 'widgets/report_period_selector.dart';

class ExpenseReportScreen extends StatefulWidget {
  const ExpenseReportScreen({super.key});

  @override
  State<ExpenseReportScreen> createState() => _ExpenseReportScreenState();
}

class _ExpenseReportScreenState extends State<ExpenseReportScreen> {
  final ReportsRepository _repository = ReportsRepository();

  String _selectedPeriod = 'this_month';
  DateTimeRange? _customDateRange;

  bool _isLoading = true;
  String? _errorMessage;

  double _totalExpenses = 0.0;
  List<ExpenseCategoryReport> _byCategory = [];
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

      final res = await _repository.getExpenseReport(
        period: _selectedPeriod,
        startDate: startStr,
        endDate: endStr,
      );

      if (mounted) {
        if (res.success && res.data != null) {
          final data = res.data!;
          final total = double.tryParse(data['summary']?['total_expenses']?.toString() ?? '') ?? 0.0;
          final catJson = data['by_category'] as List<dynamic>?;
          final detailsJson = data['details']?['data'] as List<dynamic>?;

          setState(() {
            _totalExpenses = total;
            _byCategory = catJson != null ? catJson.map((x) => ExpenseCategoryReport.fromJson(x)).toList() : [];
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
        title: const Text('Expense Report'),
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
                            // Total Expense Card
                            CustomCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                                    child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.error, size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Total Expenses', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                      const SizedBox(height: 4),
                                      Text('₹ ${_totalExpenses.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.error)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Category Breakdown
                            if (_byCategory.isNotEmpty) ...[
                              const Text('Expenses by Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(height: 10),
                              CustomCard(
                                padding: const EdgeInsets.all(12),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _byCategory.length,
                                  separatorBuilder: (ctx, idx) => const Divider(height: 1),
                                  itemBuilder: (ctx, idx) {
                                    final cat = _byCategory[idx];
                                    final pct = _totalExpenses > 0 ? (cat.totalAmount / _totalExpenses) : 0.0;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(cat.categoryName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                              Text('${cat.count} expense records (${(pct * 100).toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                            ],
                                          ),
                                          Text('₹ ${cat.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.error)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Expense Table
                            const Text('Expense Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(height: 10),
                            _detailsList.isEmpty
                                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No expenses in selected period.', style: TextStyle(color: AppColors.textMuted))))
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _detailsList.length,
                                    separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                                    itemBuilder: (ctx, idx) {
                                      final exp = _detailsList[idx];
                                      final title = exp['title']?.toString() ?? 'Expense';
                                      final catName = exp['category']?['name']?.toString() ?? 'Category';
                                      final amt = double.tryParse(exp['amount']?.toString() ?? '') ?? 0.0;
                                      final method = exp['payment_method']?.toString() ?? 'cash';

                                      return CustomCard(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                                const SizedBox(height: 4),
                                                Text('$catName • ${method.toUpperCase()}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                              ],
                                            ),
                                            Text('₹ ${amt.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.error)),
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
}
