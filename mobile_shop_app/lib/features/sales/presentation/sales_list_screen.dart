import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/sale_repository.dart';
import '../models/sale.dart';

class SalesListScreen extends StatefulWidget {
  final bool isTab;
  const SalesListScreen({super.key, this.isTab = false});

  @override
  State<SalesListScreen> createState() => SalesListScreenState();
}

class SalesListScreenState extends State<SalesListScreen> {
  final SaleRepository _saleRepository = SaleRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Sale> _sales = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'all';
  String _selectedSaleType = 'all';

  // Date Filtering state
  String _datePreset = 'today'; // 'today', 'yesterday', 'this_month', 'all_time', 'custom'
  DateTimeRange? _customDateRange;

  double _totalSalesSum = 0.0;
  double _totalPaidSum = 0.0;
  double _totalDueSum = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchSales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? get _dateFrom {
    final now = DateTime.now();
    if (_datePreset == 'today') {
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    } else if (_datePreset == 'yesterday') {
      final y = now.subtract(const Duration(days: 1));
      return '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
    } else if (_datePreset == 'this_month') {
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    } else if (_datePreset == 'custom' && _customDateRange != null) {
      final s = _customDateRange!.start;
      return '${s.year}-${s.month.toString().padLeft(2, '0')}-${s.day.toString().padLeft(2, '0')}';
    }
    return null; // all_time
  }

  String? get _dateTo {
    final now = DateTime.now();
    if (_datePreset == 'today') {
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    } else if (_datePreset == 'yesterday') {
      final y = now.subtract(const Duration(days: 1));
      return '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
    } else if (_datePreset == 'this_month') {
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    } else if (_datePreset == 'custom' && _customDateRange != null) {
      final e = _customDateRange!.end;
      return '${e.year}-${e.month.toString().padLeft(2, '0')}-${e.day.toString().padLeft(2, '0')}';
    }
    return null; // all_time
  }

  String get _dateFilterLabel {
    switch (_datePreset) {
      case 'today':
        return 'Today';
      case 'yesterday':
        return 'Yesterday';
      case 'this_month':
        return 'This Month';
      case 'custom':
        if (_customDateRange != null) {
          final s = _customDateRange!.start;
          final e = _customDateRange!.end;
          return '${s.day}/${s.month} - ${e.day}/${e.month}';
        }
        return 'Custom';
      case 'all_time':
      default:
        return 'All Time';
    }
  }

  void fetchSales() => _fetchSales();

  Future<void> _fetchSales() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _saleRepository.getSales(
        search: _searchController.text.trim(),
        paymentStatus: _selectedStatus,
        saleType: _selectedSaleType,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          final list = response.data!;
          double salesSum = 0.0;
          double paidSum = 0.0;
          double dueSum = 0.0;

          for (final s in list) {
            salesSum += s.grandTotal;
            paidSum += s.amountPaid;
            dueSum += s.amountDue;
          }

          setState(() {
            _sales = list;
            _totalSalesSum = salesSum;
            _totalPaidSum = paidSum;
            _totalDueSum = dueSum;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = response.message;
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

  void _showDateFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Select Date Filter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.today_rounded),
                  title: const Text('Today'),
                  trailing: _datePreset == 'today' ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _datePreset = 'today');
                    _fetchSales();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title: const Text('Yesterday'),
                  trailing: _datePreset == 'yesterday' ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _datePreset = 'yesterday');
                    _fetchSales();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_view_month_rounded),
                  title: const Text('This Month'),
                  trailing: _datePreset == 'this_month' ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _datePreset = 'this_month');
                    _fetchSales();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.all_inclusive_rounded),
                  title: const Text('All Time'),
                  trailing: _datePreset == 'all_time' ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _datePreset = 'all_time');
                    _fetchSales();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.date_range_rounded),
                  title: const Text('Custom Date Range...'),
                  trailing: _datePreset == 'custom' ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDateRange: _customDateRange ?? DateTimeRange(
                        start: DateTime.now().subtract(const Duration(days: 7)),
                        end: DateTime.now(),
                      ),
                    );
                    if (picked != null) {
                      setState(() {
                        _datePreset = 'custom';
                        _customDateRange = picked;
                      });
                      _fetchSales();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteSale(Sale sale) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
              SizedBox(width: 8),
              Text('Delete Invoice'),
            ],
          ),
          content: Text('Are you sure you want to delete invoice ${sale.invoiceNumber}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final res = await _saleRepository.deleteSale(sale.id);
      if (mounted) {
        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invoice ${sale.invoiceNumber} deleted successfully.'),
              backgroundColor: Colors.green.shade700,
            ),
          );
          _fetchSales();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green.shade700;
      case 'partially_paid':
        return Colors.orange.shade800;
      case 'due':
      default:
        return Colors.red.shade700;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'PAID';
      case 'partially_paid':
        return 'PARTIAL';
      case 'due':
      default:
        return 'DUE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        // Summary Header Cards & Search
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: AppColors.primary,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryMetric(
                      title: 'Total Sales',
                      value: '₹ ${_totalSalesSum.toStringAsFixed(0)}',
                      icon: Icons.receipt_long_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryMetric(
                      title: 'Collected',
                      value: '₹ ${_totalPaidSum.toStringAsFixed(0)}',
                      icon: Icons.check_circle_rounded,
                      color: Colors.greenAccent.shade400,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryMetric(
                      title: 'Total Due',
                      value: '₹ ${_totalDueSum.toStringAsFixed(0)}',
                      icon: Icons.pending_actions_rounded,
                      color: Colors.amberAccent.shade200,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Search Field & Date Filter Chip
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _fetchSales(),
                      decoration: InputDecoration(
                        hintText: 'Search Invoice #, Customer, Mobile...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  _fetchSales();
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
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showDateFilterBottomSheet,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            _dateFilterLabel,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Filter Bar (Payment Status & Sale Type)
        Container(
          height: 48,
          color: Colors.white,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildFilterChip('All Sales', 'all'),
              _buildFilterChip('PAID', 'paid'),
              _buildFilterChip('PARTIAL', 'partially_paid'),
              _buildFilterChip('DUE', 'due'),
              const VerticalDivider(width: 16, indent: 4, endIndent: 4),
              _buildSaleTypeChip('All Types', 'all'),
              _buildSaleTypeChip('⚡ Quick Sales', 'quick'),
              _buildSaleTypeChip('🧾 Invoices', 'regular'),
            ],
          ),
        ),
        const Divider(height: 1),

        // Sales List
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
                          ElevatedButton(
                            onPressed: _fetchSales,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _sales.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.receipt_long_outlined, size: 60, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                'No sales found for $_dateFilterLabel',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              const Text('Tap Create Sale (+) to generate a new invoice', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchSales,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _sales.length,
                            itemBuilder: (context, index) {
                              final sale = _sales[index];
                              final statusColor = _getStatusColor(sale.paymentStatus);
                              final statusLabel = _getStatusLabel(sale.paymentStatus);
                              final customerName = sale.customer?.name ?? (sale.customerName != null && sale.customerName!.isNotEmpty ? sale.customerName! : 'Walk-in Customer');
                              final customerMobile = sale.customer?.mobile ?? sale.customerMobile ?? '';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: CustomCard(
                                  onTap: () async {
                                    final refreshed = await Navigator.pushNamed(
                                      context,
                                      AppRoutes.saleDetails,
                                      arguments: sale,
                                    );
                                    if (refreshed == true) {
                                      _fetchSales();
                                    }
                                  },
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: sale.isQuickSale ? Colors.amber.shade900.withOpacity(0.12) : AppColors.primary.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  sale.isQuickSale ? '⚡ ${sale.invoiceNumber}' : sale.invoiceNumber,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: sale.isQuickSale ? Colors.amber.shade900 : AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                sale.saleDate.length >= 10 ? sale.saleDate.substring(0, 10) : sale.saleDate,
                                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              StatusBadge(
                                                label: statusLabel,
                                                backgroundColor: statusColor.withOpacity(0.12),
                                                textColor: statusColor,
                                              ),
                                              const SizedBox(width: 4),
                                              InkWell(
                                                onTap: () => _confirmDeleteSale(sale),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(4.0),
                                                  child: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey.shade400),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textSecondary),
                                          const SizedBox(width: 6),
                                          Text(
                                            customerName,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                                          ),
                                          if (customerMobile.isNotEmpty) ...[
                                            Text(' ($customerMobile)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                          ],
                                        ],
                                      ),
                                      if (sale.items.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          '${sale.items.length} item(s): ${sale.items.map((i) => i.productName).join(', ')}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                      if (sale.totalDiscount > 0) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.local_offer_outlined, size: 13, color: Colors.green),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Discount: -₹${sale.totalDiscount.toStringAsFixed(2)}',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Grand Total', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                              Text(
                                                '₹ ${sale.grandTotal.toStringAsFixed(2)}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    sale.amountDue > 0 ? 'Due' : 'Paid',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: sale.amountDue > 0 ? Colors.red.shade700 : Colors.green.shade700,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    sale.amountDue > 0
                                                        ? '₹ ${sale.amountDue.toStringAsFixed(2)}'
                                                        : '₹ ${sale.amountPaid.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: sale.amountDue > 0 ? Colors.red.shade700 : Colors.green.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                                            ],
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sales & Billing'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, AppRoutes.createSale);
              if (result == true) {
                _fetchSales();
              }
            },
          ),
        ],
      ),
      body: content,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_sales_list',
        onPressed: () async {
          final result = await Navigator.pushNamed(context, AppRoutes.createSale);
          if (result == true) {
            _fetchSales();
          }
        },
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
        label: const Text('Create Sale', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSummaryMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
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
                  style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedStatus = value;
            });
            _fetchSales();
          }
        },
        selectedColor: AppColors.primary,
        backgroundColor: Colors.grey.shade100,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSaleTypeChip(String label, String value) {
    final isSelected = _selectedSaleType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedSaleType = value;
            });
            _fetchSales();
          }
        },
        selectedColor: Colors.amber.shade900,
        backgroundColor: Colors.grey.shade100,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }
}
