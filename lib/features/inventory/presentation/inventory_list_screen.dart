import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/inventory_repository.dart';
import '../models/inventory_item.dart';
import 'add_stock_dialog.dart';
import 'adjust_stock_dialog.dart';

class InventoryListScreen extends StatefulWidget {
  final bool isTab;
  const InventoryListScreen({super.key, this.isTab = false});

  @override
  State<InventoryListScreen> createState() => InventoryListScreenState();
}

class InventoryListScreenState extends State<InventoryListScreen> {
  void fetchInventory() => _fetchInventory();
  final InventoryRepository _inventoryRepository = InventoryRepository();
  final TextEditingController _searchController = TextEditingController();

  List<InventoryItem> _items = [];
  InventoryMetrics? _metrics;
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedType = 'all'; // all, mobile, spare_part, accessory, other
  String _selectedStockStatus = 'all'; // all, in_stock, low_stock, out_of_stock

  final Map<String, String> _typeLabels = {
    'all': 'All Types',
    'mobile': 'Mobiles',
    'spare_part': 'Spare Parts',
    'accessory': 'Accessories',
    'other': 'Other',
  };

  final Map<String, String> _stockStatusLabels = {
    'all': 'All Stock',
    'low_stock': 'Low Stock',
    'out_of_stock': 'Out of Stock',
  };

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInventory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _inventoryRepository.getInventory(
        search: _searchController.text.trim(),
        itemType: _selectedType,
        stockStatus: _selectedStockStatus,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _items = response.data!.items;
            _metrics = response.data!.metrics;
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

  Future<void> _openAddStock(InventoryItem item) async {
    final updatedItem = await showDialog<InventoryItem>(
      context: context,
      builder: (ctx) => AddStockDialog(item: item),
    );

    if (updatedItem != null) {
      _fetchInventory();
    }
  }

  Future<void> _openAdjustStock(InventoryItem item) async {
    final updatedItem = await showDialog<InventoryItem>(
      context: context,
      builder: (ctx) => AdjustStockDialog(item: item),
    );

    if (updatedItem != null) {
      _fetchInventory();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      children: [
        // 1. Metrics Header Card Bar
        if (_metrics != null)
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    title: 'Total Items',
                    value: _metrics!.totalItems.toString(),
                    icon: Icons.inventory_2_rounded,
                    color: Colors.lightBlueAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryMetric(
                    title: 'Low Stock',
                    value: _metrics!.lowStockCount.toString(),
                    icon: Icons.warning_amber_rounded,
                    color: Colors.amberAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryMetric(
                    title: 'Out of Stock',
                    value: _metrics!.outOfStockCount.toString(),
                    icon: Icons.highlight_off_rounded,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryMetric(
                    title: 'Stock Value',
                    value: '₹${_metrics!.totalStockValue.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet_rounded,
                    color: Colors.lightGreenAccent,
                  ),
                ),
              ],
            ),
          ),

        // 2. Search Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.primary,
          child: TextField(
            controller: _searchController,
            onChanged: (_) => _fetchInventory(),
            decoration: InputDecoration(
              hintText: 'Search Name, SKU, Brand, Model, IMEI...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ),

        // 3. Filter Chips Row
        Container(
          height: 48,
          color: Colors.white,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              ..._typeLabels.entries.map((entry) {
                final isSelected = _selectedType == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedType = entry.key);
                        _fetchInventory();
                      }
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 12),
                  ),
                );
              }),
              const SizedBox(width: 8),
              ..._stockStatusLabels.entries.map((entry) {
                final isSelected = _selectedStockStatus == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedStockStatus = entry.key);
                        _fetchInventory();
                      }
                    },
                    selectedColor: AppColors.accent,
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 12),
                  ),
                );
              }),
            ],
          ),
        ),
        const Divider(height: 1),

        // 4. Inventory List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)))
                  : _items.isEmpty
                      ? const Center(child: Text('No inventory items found'))
                      : RefreshIndicator(
                          onRefresh: _fetchInventory,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];

                              String statusLabel = 'In Stock';
                              Color statusColor = Colors.green.shade700;
                              if (item.isOutOfStock) {
                                statusLabel = 'Out of Stock';
                                statusColor = Colors.red.shade700;
                              } else if (item.isLowStock) {
                                statusLabel = 'Low Stock (${item.currentStock})';
                                statusColor = Colors.amber.shade900;
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: CustomCard(
                                  onTap: () async {
                                    final res = await Navigator.pushNamed(
                                      context,
                                      AppRoutes.inventoryDetails,
                                      arguments: item,
                                    );
                                    if (res == true) _fetchInventory();
                                  },
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          StatusBadge(
                                            label: statusLabel.toUpperCase(),
                                            backgroundColor: statusColor.withOpacity(0.12),
                                            textColor: statusColor,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            'Type: ${item.itemType.replaceAll('_', ' ').toUpperCase()} • Category: ${item.category}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                      if (item.brand != null || item.model != null || item.sku != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item.brand ?? ''} ${item.model ?? ''} ${item.sku != null ? '(SKU: ${item.sku})' : ''}'.trim(),
                                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                        ),
                                      ],
                                      const SizedBox(height: 10),
                                      const Divider(height: 1),
                                      const SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 4,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue.shade50,
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: Colors.blue.shade200),
                                                      ),
                                                      child: Text(
                                                        'Total: ${item.totalStock} ${item.unit}',
                                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue.shade900),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: item.isOutOfStock ? Colors.red.shade50 : (item.isLowStock ? Colors.amber.shade50 : Colors.green.shade50),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: item.isOutOfStock ? Colors.red.shade200 : (item.isLowStock ? Colors.amber.shade300 : Colors.green.shade300)),
                                                      ),
                                                      child: Text(
                                                        'Remaining: ${item.currentStock} ${item.unit}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: item.isOutOfStock ? Colors.red.shade900 : (item.isLowStock ? Colors.amber.shade900 : Colors.green.shade900),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Buy: ₹${item.purchasePrice.toStringAsFixed(2)} | Sell: ₹${item.sellingPrice.toStringAsFixed(2)}',
                                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Row(
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed: () => _openAddStock(item),
                                                icon: const Icon(Icons.add_rounded, size: 14),
                                                label: const Text('Stock', style: TextStyle(fontSize: 11)),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.green.shade800,
                                                  side: BorderSide(color: Colors.green.shade400),
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              IconButton(
                                                icon: const Icon(Icons.published_with_changes_rounded, size: 18, color: AppColors.primary),
                                                onPressed: () => _openAdjustStock(item),
                                                tooltip: 'Stock Adjustment',
                                              ),
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

    if (widget.isTab) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: content,
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'fab_inventory_tab',
          onPressed: () async {
            final result = await Navigator.pushNamed(context, AppRoutes.addInventoryItem);
            if (result == true) _fetchInventory();
          },
          backgroundColor: AppColors.accent,
          icon: const Icon(Icons.add_box_rounded, color: Colors.white),
          label: const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Inventory & Stock'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, AppRoutes.addInventoryItem);
              if (result == true) _fetchInventory();
            },
          ),
        ],
      ),
      body: content,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_inventory_list',
        onPressed: () async {
          final result = await Navigator.pushNamed(context, AppRoutes.addInventoryItem);
          if (result == true) _fetchInventory();
        },
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_box_rounded, color: Colors.white),
        label: const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
