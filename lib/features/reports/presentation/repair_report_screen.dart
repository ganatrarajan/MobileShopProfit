import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../data/reports_repository.dart';
import '../domain/report_models.dart';
import 'widgets/report_period_selector.dart';

class RepairReportScreen extends StatefulWidget {
  const RepairReportScreen({super.key});

  @override
  State<RepairReportScreen> createState() => _RepairReportScreenState();
}

class _RepairReportScreenState extends State<RepairReportScreen> {
  final ReportsRepository _repository = ReportsRepository();

  String _selectedPeriod = 'this_month';
  DateTimeRange? _customDateRange;

  bool _isLoading = true;
  String? _errorMessage;

  RepairReportSummary? _summary;
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

      final res = await _repository.getRepairReport(
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
            _summary = summaryJson != null ? RepairReportSummary.fromJson(summaryJson) : null;
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
        title: const Text('Repair Report'),
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
                                    title: 'Total Repairs',
                                    value: '${_summary!.totalRepairs}',
                                    icon: Icons.build_rounded,
                                    color: Colors.blue.shade700,
                                  ),
                                  _buildSummaryTile(
                                    title: 'Completed',
                                    value: '${_summary!.completed}',
                                    icon: Icons.check_circle_rounded,
                                    color: Colors.green.shade700,
                                  ),
                                  _buildSummaryTile(
                                    title: 'Active / In-Progress',
                                    value: '${_summary!.active}',
                                    icon: Icons.pending_rounded,
                                    color: Colors.amber.shade800,
                                  ),
                                  _buildSummaryTile(
                                    title: 'Cancelled',
                                    value: '${_summary!.cancelled}',
                                    icon: Icons.cancel_rounded,
                                    color: Colors.red.shade700,
                                  ),
                                  _buildSummaryTile(
                                    title: 'Repair Revenue',
                                    value: '₹ ${_summary!.repairRevenue.toStringAsFixed(0)}',
                                    icon: Icons.attach_money_rounded,
                                    color: Colors.teal.shade700,
                                  ),
                                  _buildSummaryTile(
                                    title: 'Avg Repair Value',
                                    value: '₹ ${_summary!.averageRepairValue.toStringAsFixed(0)}',
                                    icon: Icons.analytics_rounded,
                                    color: Colors.indigo.shade700,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],

                            const Text('Repair Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(height: 10),
                            _detailsList.isEmpty
                                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No repairs in selected period.', style: TextStyle(color: AppColors.textMuted))))
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _detailsList.length,
                                    separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                                    itemBuilder: (ctx, idx) {
                                      final item = _detailsList[idx];
                                      final job = item['job_number']?.toString() ?? 'JOB';
                                      final cust = item['customer']?['name']?.toString() ?? 'Customer';
                                      final status = item['repair_status']?.toString() ?? 'pending';
                                      final est = double.tryParse(item['estimated_cost']?.toString() ?? '') ?? 0.0;

                                      return CustomCard(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(job, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                                const SizedBox(height: 4),
                                                Text(cust, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text('₹ ${est.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                                  child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                                                ),
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
