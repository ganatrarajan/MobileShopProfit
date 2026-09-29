import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
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
  State<PurchaseListScreen> createState() => PurchaseListScreenState();
}

class PurchaseListScreenState extends State<PurchaseListScreen> {
  final PurchaseRepository _repository = PurchaseRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Purchase> _purchases = [];
  bool _isLoading = false;
  String _paymentStatusFilter = 'all';

  double _totalAmount = 0.0;
  double _totalPaid = 0.0;
  double _totalOutstanding = 0.0;

  @override
  void initState() {
    super.initState();
    fetchPurchases();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchPurchases() async {
    setState(() => _isLoading = true);

    final response = await _repository.getPurchases(
      search: _searchController.text.trim(),
      paymentStatus: _paymentStatusFilter == 'all' ? null : _paymentStatusFilter,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (response.success && response.data != null) {
        final res = response.data!;
        setState(() {
          _purchases = res.purchases;
          _totalAmount = res.totalAmount;
          _totalPaid = res.totalPaid;
          _totalOutstanding = res.totalOutstanding;
        });
      }
    }
  }

  void _openAddPurchase() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPurchaseScreen()),
    );
    if (result == true) {
      fetchPurchases();
    }
  }

  void _openVendorList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VendorListScreen()),
    );
  }

  void _openInventory() {
    Navigator.pushNamed(context, AppRoutes.inventory);
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Purchase Orders',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined, color: Colors.white),
            tooltip: 'Inventory Stock',
            onPressed: _openInventory,
          ),
          IconButton(
            icon: const Icon(Icons.people_alt_outlined, color: Colors.white),
            tooltip: 'Vendors / Suppliers',
            onPressed: _openVendorList,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: fetchPurchases,
          ),
        ],
      ),
      body: Column(
        children: [
          // SUMMARY METRICS CARD HEADER
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: AppColors.primary,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Purchases',
                        value: '\u20B9${_totalAmount.toStringAsFixed(0)}',
                        icon: Icons.shopping_bag_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Paid',
                        value: '\u20B9${_totalPaid.toStringAsFixed(0)}',
                        icon: Icons.check_circle_outline_rounded,
                        color: Colors.greenAccent.shade400,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Outstanding',
                        value: '\u20B9${_totalOutstanding.toStringAsFixed(0)}',
                        icon: Icons.pending_actions_rounded,
                        color: Colors.amberAccent.shade200,
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
                        onSubmitted: (_) => fetchPurchases(),
                        decoration: InputDecoration(
                          hintText: 'Search purchase #, vendor...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    fetchPurchases();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _paymentStatusFilter,
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Status')),
                            DropdownMenuItem(value: 'paid', child: Text('Paid')),
                            DropdownMenuItem(value: 'partial', child: Text('Partial')),
                            DropdownMenuItem(value: 'pending', child: Text('Pending')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _paymentStatusFilter = val);
                              fetchPurchases();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // LIST OF PURCHASES
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _purchases.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.shopping_bag_outlined,
                        title: 'No Purchases Found',
                        message: 'Tap + Add Purchase to record inventory purchases from suppliers.',
                      )
                    : RefreshIndicator(
                        onRefresh: fetchPurchases,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _purchases.length,
                          itemBuilder: (context, index) {
                            final p = _purchases[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 1.5,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '#${p.purchaseNumber}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                    ),
                                    _buildStatusBadge(p.paymentStatus),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(p.vendorName, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text('Date: ${p.purchaseDate.toIso8601String().split('T')[0]}     ${p.items.length} item(s)', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Total: \u20B9${p.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                                        Text('Paid: \u20B9${p.amountPaid.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 12)),
                                        Text('Due: \u20B9${p.outstandingAmount.toStringAsFixed(2)}', style: TextStyle(color: p.outstandingAmount > 0 ? AppColors.error : AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => PurchaseDetailsScreen(purchase: p)),
                                  );
                                  fetchPurchases();
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
        heroTag: 'fab_purchase_list',
        backgroundColor: AppColors.primary,
        onPressed: _openAddPurchase,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Purchase', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
