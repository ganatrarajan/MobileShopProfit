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

    if (mounted) {
      setState(() => _isLoading = false);

      if (response.success && response.data != null) {
        setState(() {
          _vendors = response.data!.vendors;
        });
      }
    }
  }

  void _openAddVendor() async {
    final newVendor = await QuickAddVendorModal.show(context);
    if (newVendor != null) {
      _fetchVendors();
    }
  }

  void _openEditVendor(Vendor vendor) async {
    final updated = await QuickAddVendorModal.show(context, vendorToEdit: vendor);
    if (updated != null) {
      _fetchVendors();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Vendors & Suppliers',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _fetchVendors,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.primary,
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _fetchVendors(),
              decoration: InputDecoration(
                hintText: 'Search by vendor name, phone, GST...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _fetchVendors();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _vendors.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.people_outline_rounded,
                        title: 'No Vendors Found',
                        message: 'Tap + Add Vendor to add your mobile parts and device suppliers.',
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchVendors,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _vendors.length,
                          itemBuilder: (context, index) {
                            final v = _vendors[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 1.5,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.primary.withOpacity(0.12),
                                  child: Text(
                                    v.name.isNotEmpty ? v.name[0].toUpperCase() : 'V',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                                  ),
                                ),
                                title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text('${v.phone}     Total Purchased: \u20B9${v.totalPurchase.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('Outstanding', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text(
                                          '\u20B9${v.outstandingAmount.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: v.outstandingAmount > 0 ? AppColors.error : AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                                      tooltip: 'Edit Vendor',
                                      onPressed: () => _openEditVendor(v),
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
        heroTag: 'fab_vendor_list',
        backgroundColor: AppColors.primary,
        onPressed: _openAddVendor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Vendor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
