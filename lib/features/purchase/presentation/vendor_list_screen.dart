import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../data/purchase_repository.dart';
import '../models/vendor.dart';
import 'vendor_details_screen.dart';
import 'widgets/quick_add_vendor_modal.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  final PurchaseRepository _repository = PurchaseRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Vendor> _vendors = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchVendors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchVendors() async {
    setState(() => _isLoading = true);

    final response = await _repository.getVendors(
      search: _searchController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (response.success && response.data != null) {
      setState(() {
        _vendors = response.data!.vendors;
      });
    }
  }

  void _openAddVendor() async {
    final newVendor = await QuickAddVendorModal.show(context);
    if (newVendor != null) {
      _fetchVendors();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendors / Suppliers'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchVendors,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search vendor name, phone, email, GST...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: (_) => _fetchVendors(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _vendors.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.people_outline,
                        title: 'No Vendors Found',
                        message: 'Tap "+ Add Vendor" to add your mobile parts and device suppliers.',
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchVendors,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _vendors.length,
                          itemBuilder: (context, index) {
                            final v = _vendors[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  child: Text(
                                    v.name.isNotEmpty ? v.name[0].toUpperCase() : 'V',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ),
                                title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('?? ${v.phone} • Total: ?${v.totalPurchase.toStringAsFixed(0)}'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Outstanding', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                    Text(
                                      '?${v.outstandingAmount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: v.outstandingAmount > 0 ? AppColors.error : AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => VendorDetailsScreen(vendor: v)),
                                  );
                                  _fetchVendors();
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
        onPressed: _openAddVendor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Vendor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

