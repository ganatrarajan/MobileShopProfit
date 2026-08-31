import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../data/profit_intelligence_repository.dart';

class ProfitIntelligenceDetailScreen extends StatefulWidget {
  final String category;
  final String title;

  const ProfitIntelligenceDetailScreen({
    super.key,
    required this.category,
    required this.title,
  });

  @override
  State<ProfitIntelligenceDetailScreen> createState() => _ProfitIntelligenceDetailScreenState();
}

class _ProfitIntelligenceDetailScreenState extends State<ProfitIntelligenceDetailScreen> {
  final ProfitIntelligenceRepository _repository = ProfitIntelligenceRepository();

  bool _isLoading = true;
  String? _errorMessage;
  bool _hasEnoughData = true;
  String? _dataMessage;
  List<dynamic> _detailsList = [];

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _repository.getCategoryDetails(widget.category);
      if (mounted) {
        if (res.success && res.data != null) {
          final data = res.data!;
          setState(() {
            _hasEnoughData = data['has_enough_data'] == true;
            _dataMessage = data['message']?.toString();
            _detailsList = (data['details'] as List<dynamic>?) ?? [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _fetchDetails, child: const Text('Retry')),
                    ],
                  ),
                )
              : !_hasEnoughData
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              _dataMessage ?? 'Not enough business data yet.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchDetails,
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_detailsList.length} Items Found',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const Text('Actionable Insights', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _detailsList.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Text('No optimization issues detected in this category.', style: TextStyle(color: AppColors.textMuted)),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _detailsList.length,
                                  separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                                  itemBuilder: (ctx, idx) {
                                    final item = _detailsList[idx];
                                    return _buildDetailCard(item);
                                  },
                                ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildDetailCard(dynamic item) {
    switch (widget.category) {
      case 'underpriced_repairs':
        final job = item['job_number']?.toString() ?? 'JOB';
        final prob = item['problem_description']?.toString() ?? 'Repair';
        final charged = double.tryParse(item['actual_charged']?.toString() ?? '') ?? 0.0;
        final avg = double.tryParse(item['average_charged']?.toString() ?? '') ?? 0.0;
        final inc = double.tryParse(item['potential_increase']?.toString() ?? '') ?? 0.0;
        final sugg = item['suggestion']?.toString() ?? '';

        return CustomCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(job, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  Text('+ ₹ ${inc.toStringAsFixed(0)} loss', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                ],
              ),
              const SizedBox(height: 4),
              Text(prob, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Charged: ₹${charged.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(width: 16),
                  Text('Shop Avg: ₹${avg.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                ],
              ),
              if (sugg.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(child: Text(sugg, style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );

      case 'slow_moving_stock':
        final name = item['name']?.toString() ?? 'Item';
        final stock = int.tryParse(item['current_stock']?.toString() ?? '') ?? 0;
        final val = double.tryParse(item['stock_value']?.toString() ?? '') ?? 0.0;
        final days = int.tryParse(item['days_inactive']?.toString() ?? '') ?? 0;
        final sugg = item['suggestion']?.toString() ?? '';

        return CustomCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                  Text('₹ ${val.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                ],
              ),
              const SizedBox(height: 6),
              Text('Stock: $stock pcs • Inactive for $days days', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              if (sugg.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Colors.purple),
                      const SizedBox(width: 8),
                      Expanded(child: Text(sugg, style: TextStyle(fontSize: 11, color: Colors.purple.shade900, fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );

      case 'warranty_loss':
        final claimNum = item['claim_number']?.toString() ?? 'CLM';
        final itemName = item['item_name']?.toString() ?? 'Repaired Item';
        final custName = item['customer_name']?.toString() ?? 'Customer';
        final status = item['status']?.toString() ?? 'resolved';
        final loss = double.tryParse(item['estimated_loss']?.toString() ?? '') ?? 0.0;
        final sugg = item['suggestion']?.toString() ?? '';

        return CustomCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(claimNum, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  Text('Loss: ₹ ${loss.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                ],
              ),
              const SizedBox(height: 4),
              Text('$itemName • $custName', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
              ),
              if (sugg.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.build_circle_rounded, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(sugg, style: TextStyle(fontSize: 11, color: Colors.red.shade900, fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );

      case 'pending_payments':
        final inv = item['invoice_number']?.toString() ?? 'INV';
        final cust = item['customer_name']?.toString() ?? 'Customer';
        final due = double.tryParse(item['amount_due']?.toString() ?? '') ?? 0.0;
        final days = int.tryParse(item['days_pending']?.toString() ?? '') ?? 0;
        final sugg = item['suggestion']?.toString() ?? '';

        return CustomCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(inv, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  Text('Due: ₹ ${due.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                ],
              ),
              const SizedBox(height: 4),
              Text(cust, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Pending for $days days', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              if (sugg.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_read_rounded, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(child: Text(sugg, style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );

      case 'low_margin_products':
        final name = item['name']?.toString() ?? 'Item';
        final cost = double.tryParse(item['purchase_price']?.toString() ?? '') ?? 0.0;
        final sell = double.tryParse(item['selling_price']?.toString() ?? '') ?? 0.0;
        final pct = double.tryParse(item['margin_percentage']?.toString() ?? '') ?? 0.0;
        final sugg = item['suggestion']?.toString() ?? '';

        return CustomCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                    child: Text('$pct% margin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Cost: ₹ ${cost.toStringAsFixed(2)} • Sell: ₹ ${sell.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              if (sugg.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.price_change_rounded, size: 16, color: Colors.teal),
                      const SizedBox(width: 8),
                      Expanded(child: Text(sugg, style: TextStyle(fontSize: 11, color: Colors.teal.shade900, fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );

      default:
        return CustomCard(
          padding: const EdgeInsets.all(16),
          child: Text(item.toString()),
        );
    }
  }
}
