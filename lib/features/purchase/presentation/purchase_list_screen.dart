import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/purchase_repository.dart';
import '../models/purchase.dart';
import 'add_purchase_screen.dart';
import 'purchase_details_screen.dart';
import 'vendor_list_screen.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  final PurchaseRepository _repository = PurchaseRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Purchase> _purchases = [];
  bool _isLoading = false;
  String _paymentStatusFilter = 'all';

  double _totalAmount = 0.0;
  double _totalPaid = 0.0;
  double _totalOutstanding = 0.0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchPurchases();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPurchases() async {
    setState(() => _isLoading = true);

    final response = await _repository.getPurchases(
      search: _searchController.text.trim(),
      paymentStatus: _paymentStatusFilter == 'all' ? null : _paymentStatusFilter,
    );

    setState(() => _isLoading = false);

    if (response.success && response.data != null) {
      final res = response.data!;
      setState(() {
        _purchases = res.purchases;
        _totalAmount = res.totalAmount;
        _totalPaid = res.totalPaid;
        _totalOutstanding = res.totalOutstanding;
        _totalCount = res.totalCount;
      });
    }
  }

  void _openAddPurchase() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPurchaseScreen()),
    );
    if (result == true) {
      _fetchPurchases();
    }
  }

  void _openVendorList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VendorListScreen()),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    final s = status.toLowerCase();
    if (s == 'paid') {
      bg = Colors.green.shade100;
      text = Colors.green.shade800;
    } else if (s == 'partial') {
      bg = Colors.amber.shade100;
      text = Colors.amber.shade900;
    } else {
      bg = Colors.red.shade100;
      text = Colors.red.shade800;
    }
    return StatusBadge(
      label: status.toUpperCase(),
      backgroundColor: bg,
      textColor: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined, color: AppColors.primary),
            tooltip: 'Vendors / Suppliers',
            onPressed: _openVendorList,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPurchases,
          ),
        ],
      ),
      body: Column(
        children: [
          // SUMMARY METRICS CARD
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Purchases', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('?${_totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Paid', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('?${_totalPaid.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.success)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Outstanding', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('?${_totalOutstanding.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.error)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // SEARCH & FILTERS
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search purchase #, vendor...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onSubmitted: (_) => _fetchPurchases(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _paymentStatusFilter,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Status')),
                        DropdownMenuItem(value: 'paid', child: Text('Paid')),
                        DropdownMenuItem(value: 'partial', child: Text('Partial')),
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _paymentStatusFilter = val);
                          _fetchPurchases();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // LIST OF PURCHASES
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _purchases.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.shopping_bag_outlined,
                        title: 'No Purchases Found',
                        message: 'Tap "+ Add Purchase" to record inventory purchases from suppliers.',
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchPurchases,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _purchases.length,
                          itemBuilder: (context, index) {
                            final p = _purchases[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 1,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '#${p.purchaseNumber}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    _buildStatusBadge(p.paymentStatus),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(p.vendorName, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text('Date: ${p.purchaseDate.toIso8601String().split('T')[0]} • ${p.items.length} item(s)', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Total: ?${p.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text('Paid: ?${p.amountPaid.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.success, fontSize: 12)),
                                        Text('Due: ?${p.outstandingAmount.toStringAsFixed(0)}', style: TextStyle(color: p.outstandingAmount > 0 ? AppColors.error : AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => PurchaseDetailsScreen(purchase: p)),
                                  );
                                  _fetchPurchases();
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _openAddPurchase,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Purchase', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

