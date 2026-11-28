import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/whatsapp_icon.dart';
import '../../subscription/utils/subscription_guard.dart';
import '../data/customer_repository.dart';
import '../models/customer.dart';
import '../utils/customer_export_helper.dart';

class CustomerListScreen extends StatefulWidget {
  final bool isTab;
  const CustomerListScreen({super.key, this.isTab = false});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final CustomerRepository _repository = CustomerRepository();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  List<Customer> _customers = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // Pagination state
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalCustomers = 0;

  // Filter & Sort state
  String _selectedFilter = 'all'; // all, with_due, has_repairs, has_sales
  String _selectedSort = 'newest'; // newest, oldest, name_asc, name_desc, due_desc

  final List<Map<String, String>> _filterOptions = [
    {'key': 'all', 'label': 'All Customers'},
    {'key': 'with_due', 'label': 'Due Balance'},
    {'key': 'has_repairs', 'label': 'Repairs'},
    {'key': 'has_sales', 'label': 'Sales'},
  ];

  final Map<String, String> _sortLabels = {
    'newest': 'Newest First',
    'oldest': 'Oldest First',
    'name_asc': 'Name (A to Z)',
    'name_desc': 'Name (Z to A)',
    'due_desc': 'Highest Due First',
  };

  int get _dueCustomersCount => _customers.where((c) => c.totalDue > 0).length;
  double get _totalDueSum => _customers.fold(0.0, (sum, c) => sum + c.totalDue);

  @override
  void initState() {
    super.initState();
    _fetchCustomers(page: 1);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _currentPage < _lastPage) {
        _fetchCustomers(page: _currentPage + 1, isLoadMore: true);
      }
    }
  }

  Future<void> _fetchCustomers({int page = 1, bool isLoadMore = false, String? query}) async {
    final search = query ?? _searchController.text.trim();

    if (isLoadMore) {
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        if (page == 1) _customers = [];
      });
    }

    try {
      final response = await _repository.getCustomersPaged(
        page: page,
        perPage: 15,
        search: search.isNotEmpty ? search : null,
        filter: _selectedFilter,
        sort: _selectedSort,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          final result = response.data!;
          setState(() {
            _currentPage = result.currentPage;
            _lastPage = result.lastPage;
            _totalCustomers = result.total;

            if (isLoadMore) {
              _customers.addAll(result.customers);
              _isLoadingMore = false;
            } else {
              _customers = List.from(result.customers);
              _isLoading = false;
            }
          });
        } else {
          setState(() {
            _errorMessage = response.message;
            _isLoading = false;
            _isLoadingMore = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchCustomers(page: 1, query: query);
    });
  }

  void _onFilterSelected(String filterKey) {
    if (_selectedFilter == filterKey) return;
    setState(() => _selectedFilter = filterKey);
    _fetchCustomers(page: 1);
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.sort_rounded, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Sort Customers',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ..._sortLabels.entries.map((entry) {
                  final isSelected = _selectedSort == entry.key;
                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? AppColors.primary : Colors.grey,
                    ),
                    title: Text(
                      entry.value,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      if (_selectedSort != entry.key) {
                        setState(() => _selectedSort = entry.key);
                        _fetchCustomers(page: 1);
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // EXPORT LOGIC (PDF & EXCEL)
  // ==========================================
  Future<void> _exportCustomers({required bool isPdf}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    isPdf ? 'Preparing PDF Directory...' : 'Preparing Excel Spreadsheet...',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final response = await _repository.getCustomersPaged(
        search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
        filter: _selectedFilter,
        sort: _selectedSort,
        all: true,
      );

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!response.success || response.data == null) {
        if (mounted) {
          AppFeedback.showError(context, error: response.message);
        }
        return;
      }

      final allCustomers = response.data!.customers;
      if (allCustomers.isEmpty) {
        if (mounted) {
          AppFeedback.showInfo(context, title: 'No Data', message: 'No customers available to export.');
        }
        return;
      }

      final shop = await AuthStorage().getShop();
      final shopName = (shop?['shop_name'] ?? shop?['name'] ?? 'Mobile Care').toString();
      final shopAddress = shop?['address']?.toString();
      final shopPhone = (shop?['phone'] ?? shop?['mobile'])?.toString();

      if (!mounted) return;

      if (isPdf) {
        await CustomerExportHelper.exportToPdf(
          context: context,
          customers: allCustomers,
          shopName: shopName,
          shopAddress: shopAddress,
          shopPhone: shopPhone,
        );
      } else {
        await CustomerExportHelper.exportToExcelCsv(
          context: context,
          customers: allCustomers,
          shopName: shopName,
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (mounted) {
        AppFeedback.showError(context, error: 'Export failed: $e');
      }
    }
  }

  // ==========================================
  // IMPORT MODAL DIALOG
  // ==========================================
  void _showImportModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomerImportBottomSheet(
        onImportSuccess: () {
          _fetchCustomers(page: 1);
        },
      ),
    );
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirm = await AppDialogs.showConfirmation(
      context,
      title: 'Delete Customer?',
      message: 'This will remove "${customer.name}" from your active customer list.',
      confirmLabel: 'Delete Customer',
    );

    if (confirm) {
      try {
        final res = await _repository.deleteCustomer(customer.id);
        if (mounted) {
          if (res.success) {
            AppFeedback.showSuccess(
              context,
              title: 'Customer Deleted',
              message: '${customer.name} has been deleted successfully.',
            );
            _fetchCustomers(page: 1);
          } else {
            AppFeedback.showError(context, error: res.message);
          }
        }
      } catch (e) {
        if (mounted) AppFeedback.showError(context, error: e);
      }
    }
  }

  // ==========================================
  // COMPACT SUMMARY METRIC CARD
  // ==========================================
  Widget _buildSummaryMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.22) : Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.22),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12.5, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.85),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget bodyContent = Column(
      children: [
        // ==========================================
        // Integrated Header: Metrics, Search, Filter Pills
        // ==========================================
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          color: AppColors.primary,
          child: Column(
            children: [
              // Tab-mode only header bar (when standalone AppBar is absent)
              if (widget.isTab) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Customer Management',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Sort List',
                          icon: const Icon(Icons.sort_rounded, color: Colors.white, size: 22),
                          onPressed: _showSortBottomSheet,
                        ),
                        IconButton(
                          tooltip: 'Import Customers',
                          icon: const Icon(Icons.file_upload_outlined, color: Colors.white, size: 22),
                          onPressed: _showImportModal,
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Export Customers',
                          icon: const Icon(Icons.file_download_outlined, color: Colors.white, size: 22),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (value) {
                            if (value == 'pdf') {
                              _exportCustomers(isPdf: true);
                            } else if (value == 'excel') {
                              _exportCustomers(isPdf: false);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'pdf',
                              child: Row(
                                children: [
                                  Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 20),
                                  SizedBox(width: 12),
                                  Text('Export PDF Directory'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'excel',
                              child: Row(
                                children: [
                                  Icon(Icons.table_chart_rounded, color: Colors.green, size: 20),
                                  SizedBox(width: 12),
                                  Text('Export Excel (.csv)'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],

              // Row 1: Summary Metric Strip
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryMetric(
                      title: 'Customers',
                      value: _totalCustomers > 0 ? '$_totalCustomers' : '${_customers.length}',
                      icon: Icons.people_alt_rounded,
                      color: Colors.white,
                      isSelected: _selectedFilter == 'all',
                      onTap: () => _onFilterSelected('all'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryMetric(
                      title: 'With Due',
                      value: '$_dueCustomersCount',
                      icon: Icons.pending_actions_rounded,
                      color: Colors.amberAccent.shade200,
                      isSelected: _selectedFilter == 'with_due',
                      onTap: () => _onFilterSelected('with_due'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryMetric(
                      title: 'Total Due',
                      value: '₹${_totalDueSum.toStringAsFixed(0)}',
                      icon: Icons.currency_rupee_rounded,
                      color: Colors.redAccent.shade100,
                      isSelected: _selectedFilter == 'with_due',
                      onTap: () => _onFilterSelected('with_due'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: Search Bar (Consistent Clean White Input)
              SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search by name, mobile number, or city...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 18),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                            onPressed: () {
                              _debounceTimer?.cancel();
                              _searchController.clear();
                              _fetchCustomers(page: 1, query: '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Row 3: Modern Filter Pills (Clean custom containers, no Material 3 tint issues)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filterOptions.map((opt) {
                    final isSelected = _selectedFilter == opt['key'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: InkWell(
                        onTap: () => _onFilterSelected(opt['key']!),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5.5),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white.withOpacity(0.30),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                const Icon(Icons.check_rounded, size: 13, color: AppColors.primary),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                opt['label']!,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // ==========================================
        // Main Customer List Content
        // ==========================================
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await _fetchCustomers(page: 1);
            },
            child: _isLoading
                ? AppShimmer.listLoading()
                : _errorMessage != null
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _fetchCustomers(page: 1),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _customers.isEmpty
                        ? AppEmptyState(
                            icon: Icons.people_outline_rounded,
                            title: 'No customers found',
                            description: _searchController.text.isNotEmpty || _selectedFilter != 'all'
                                ? 'No customer matches your current search or filter criteria.'
                                : 'Add your first customer or import from CSV to start managing billing and repairs.',
                            actionLabel: '+ Add Customer',
                            onActionPressed: () async {
                              final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'add customers');
                              if (!ok) return;
                              if (!mounted) return;
                              await Navigator.pushNamed(context, AppRoutes.addCustomer);
                              if (!mounted) return;
                              _fetchCustomers(page: 1);
                            },
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
                            itemCount: _customers.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _customers.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                    ),
                                  ),
                                );
                              }

                              final customer = _customers[index];
                              final hasDue = customer.totalDue > 0;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 9.0),
                                child: CustomCard(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                  onTap: () async {
                                    await Navigator.pushNamed(
                                      context,
                                      AppRoutes.customerDetails,
                                      arguments: customer,
                                    );
                                    _fetchCustomers(page: _currentPage);
                                  },
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Customer Avatar
                                      CircleAvatar(
                                        radius: 21,
                                        backgroundColor: hasDue
                                            ? const Color(0xFFFEF2F2)
                                            : AppColors.primary.withOpacity(0.12),
                                        child: Text(
                                          customer.name.trim().isNotEmpty
                                              ? customer.name.trim()[0].toUpperCase()
                                              : 'C',
                                          style: TextStyle(
                                            color: hasDue ? const Color(0xFFDC2626) : AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Customer Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Name & Due Badge
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    customer.name,
                                                    style: const TextStyle(
                                                      fontSize: 14.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (hasDue)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFEF2F2),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: const Color(0xFFFECACA), width: 0.8),
                                                    ),
                                                    child: Text(
                                                      'Due: ₹${customer.totalDue.toStringAsFixed(0)}',
                                                      style: const TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w800,
                                                        color: Color(0xFFDC2626),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),

                                            // Mobile & Location
                                            Row(
                                              children: [
                                                const Icon(Icons.phone_rounded, size: 12.5, color: AppColors.textSecondary),
                                                const SizedBox(width: 4),
                                                Text(
                                                  customer.mobile,
                                                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                                ),
                                                if (customer.city != null && customer.city!.isNotEmpty) ...[
                                                  const SizedBox(width: 6),
                                                  Text('•', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                                  const SizedBox(width: 5),
                                                  const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                                                  const SizedBox(width: 2),
                                                  Expanded(
                                                    child: Text(
                                                      customer.city!,
                                                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),

                                            // Count Badges
                                            if (customer.repairsCount > 0 || customer.salesCount > 0 || customer.totalSpent > 0) ...[
                                              const SizedBox(height: 5),
                                              Wrap(
                                                spacing: 5,
                                                runSpacing: 4,
                                                children: [
                                                  if (customer.repairsCount > 0)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue.shade50,
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: Colors.blue.shade100, width: 0.8),
                                                      ),
                                                      child: Text(
                                                        '🔧 ${customer.repairsCount} Repairs',
                                                        style: TextStyle(fontSize: 9.5, color: Colors.blue.shade800, fontWeight: FontWeight.w600),
                                                      ),
                                                    ),
                                                  if (customer.salesCount > 0)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
                                                      decoration: BoxDecoration(
                                                        color: Colors.teal.shade50,
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: Colors.teal.shade100, width: 0.8),
                                                      ),
                                                      child: Text(
                                                        '🛍️ ${customer.salesCount} Sales',
                                                        style: TextStyle(fontSize: 9.5, color: Colors.teal.shade800, fontWeight: FontWeight.w600),
                                                      ),
                                                    ),
                                                  if (customer.totalSpent > 0)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade100,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        '₹${customer.totalSpent.toStringAsFixed(0)} spent',
                                                        style: TextStyle(fontSize: 9.5, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // Trailing: WhatsApp & Delete
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () => WhatsAppHelper.showCustomerWhatsAppOptions(context, customer),
                                            borderRadius: BorderRadius.circular(16),
                                            child: const Padding(
                                              padding: EdgeInsets.all(5.0),
                                              child: WhatsAppIcon(size: 20),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          InkWell(
                                            onTap: () => _deleteCustomer(customer),
                                            borderRadius: BorderRadius.circular(16),
                                            child: Padding(
                                              padding: const EdgeInsets.all(5.0),
                                              child: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade400, size: 20),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ),
      ],
    );

    if (widget.isTab) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: bodyContent,
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'fab_customer_tab',
          onPressed: () async {
            final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'add customers');
            if (!ok) return;
            if (!mounted) return;
            await Navigator.pushNamed(context, AppRoutes.addCustomer);
            if (!mounted) return;
            _fetchCustomers(page: 1);
          },
          backgroundColor: AppColors.accent,
          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
          label: const Text('Add Customer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Customer Directory',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sort List',
            icon: const Icon(Icons.sort_rounded, color: Colors.white),
            onPressed: _showSortBottomSheet,
          ),
          IconButton(
            tooltip: 'Import Customers',
            icon: const Icon(Icons.file_upload_outlined, color: Colors.white),
            onPressed: _showImportModal,
          ),
          PopupMenuButton<String>(
            tooltip: 'Export Customers',
            icon: const Icon(Icons.file_download_outlined, color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'pdf') {
                _exportCustomers(isPdf: true);
              } else if (value == 'excel') {
                _exportCustomers(isPdf: false);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 20),
                    SizedBox(width: 12),
                    Text('Export PDF Directory'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_rounded, color: Colors.green, size: 20),
                    SizedBox(width: 12),
                    Text('Export Excel (.csv)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: bodyContent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_customer_list',
        onPressed: () async {
          final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'add customers');
          if (!ok) return;
          if (!mounted) return;
          await Navigator.pushNamed(context, AppRoutes.addCustomer);
          if (!mounted) return;
          _fetchCustomers(page: 1);
        },
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Add Customer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ==========================================
// CUSTOMER IMPORT BOTTOM SHEET WIDGET
// ==========================================
class _CustomerImportBottomSheet extends StatefulWidget {
  final VoidCallback onImportSuccess;
  const _CustomerImportBottomSheet({required this.onImportSuccess});

  @override
  State<_CustomerImportBottomSheet> createState() => _CustomerImportBottomSheetState();
}

class _CustomerImportBottomSheetState extends State<_CustomerImportBottomSheet> {
  final CustomerRepository _repository = CustomerRepository();

  File? _selectedFile;
  String? _fileName;
  List<Map<String, dynamic>> _parsedRows = [];
  bool _isParsing = false;
  bool _isImporting = false;
  String? _errorMessage;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);

        setState(() {
          _selectedFile = file;
          _fileName = result.files.single.name;
          _isParsing = true;
          _errorMessage = null;
        });

        // Read and parse CSV
        final bytes = await file.readAsBytes();
        String content;
        try {
          content = utf8.decode(bytes);
        } catch (_) {
          content = latin1.decode(bytes);
        }

        final rows = CustomerExportHelper.parseCsv(content);

        setState(() {
          _isParsing = false;
          _parsedRows = rows;
          if (rows.isEmpty) {
            _errorMessage = 'No valid customer rows found in file. Ensure headers: name, mobile, etc.';
          }
        });
      }
    } catch (e) {
      setState(() {
        _isParsing = false;
        _errorMessage = 'Failed to read file: $e';
      });
    }
  }

  Future<void> _startImport() async {
    if (_parsedRows.isEmpty) return;

    setState(() {
      _isImporting = true;
      _errorMessage = null;
    });

    try {
      final response = _selectedFile != null
          ? await _repository.importCustomersFile(_selectedFile!.path)
          : await _repository.importCustomersRows(_parsedRows);

      if (!mounted) return;

      setState(() => _isImporting = false);

      if (response.success) {
        final data = response.data;
        final total = data?['total'] ?? _parsedRows.length;
        final imported = data?['imported'] ?? 0;
        final updated = data?['updated'] ?? 0;
        final skipped = data?['skipped'] ?? 0;

        Navigator.pop(context); // Close bottom sheet

        AppFeedback.showSuccess(
          context,
          title: 'Import Completed',
          message: 'Total: $total | Added: $imported | Updated: $updated | Skipped: $skipped',
        );

        widget.onImportSuccess();
      } else {
        setState(() {
          _errorMessage = response.message.isNotEmpty ? response.message : 'Import failed. Please check format.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _errorMessage = 'Import error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sheet Title & Close
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.file_upload_rounded, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Customers',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Upload CSV or Excel exported contact list',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Step 1: Download Sample Template
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Need sample file format?',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Download our template file with dummy data to see required headers.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => CustomerExportHelper.downloadSampleCsvTemplate(context),
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: const Text('Download Sample CSV', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue.shade800,
                            side: BorderSide(color: Colors.blue.shade300),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Step 2: Choose File
            const Text(
              'Select CSV File to Import',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),

            InkWell(
              onTap: _isImporting ? null : _pickFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedFile != null ? Colors.green : Colors.grey.shade300,
                    style: BorderStyle.solid,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFile != null ? Icons.check_circle_rounded : Icons.folder_open_rounded,
                      size: 36,
                      color: _selectedFile != null ? Colors.green : Colors.grey.shade600,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fileName ?? 'Tap to select CSV / Excel contacts file',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _fileName != null ? FontWeight.bold : FontWeight.normal,
                        color: _fileName != null ? AppColors.textPrimary : Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Supports .csv format with name, mobile, city, address',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            if (_isParsing) ...[
              const SizedBox(height: 16),
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text('Analyzing CSV file...', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Step 3: Preview parsed data
            if (_parsedRows.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${_parsedRows.length} valid customer rows recognized',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Mini preview of first 3 items
                    ..._parsedRows.take(3).map((r) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            '• ${r['name'] ?? 'Unknown'} (${r['mobile'] ?? '-'}) ${r['city'] != null ? ' - ${r['city']}' : ''}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        )),
                    if (_parsedRows.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '...and ${_parsedRows.length - 3} more customers',
                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Import Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_parsedRows.isEmpty || _isImporting) ? null : _startImport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isImporting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Text('Importing Customers...', style: TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      )
                    : Text(
                        _parsedRows.isNotEmpty ? 'Import ${_parsedRows.length} Customers' : 'Select File to Import',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
