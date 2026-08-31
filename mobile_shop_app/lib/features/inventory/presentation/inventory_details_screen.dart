import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/inventory_repository.dart';
import '../models/inventory_item.dart';
import 'add_stock_dialog.dart';
import 'adjust_stock_dialog.dart';

class InventoryDetailsScreen extends StatefulWidget {
  final InventoryItem item;
  const InventoryDetailsScreen({super.key, required this.item});

  @override
  State<InventoryDetailsScreen> createState() => _InventoryDetailsScreenState();
}

class _InventoryDetailsScreenState extends State<InventoryDetailsScreen> {
  final InventoryRepository _inventoryRepository = InventoryRepository();
  late InventoryItem _item;
  bool _isLoading = false;

  final Map<String, Color> _movementColors = {
    'opening_stock': Colors.blue.shade700,
    'purchase': Colors.green.shade700,
    'sale': Colors.purple.shade700,
    'repair_usage': Colors.indigo.shade700,
    'damaged': Colors.red.shade700,
    'lost': Colors.red.shade900,
    'return': Colors.teal.shade700,
    'adjustment': Colors.amber.shade900,
  };

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _refreshDetails();
  }

  Future<void> _refreshDetails() async {
    setState(() => _isLoading = true);
    try {
      final res = await _inventoryRepository.getItemDetails(_item.id);
      if (mounted) {
        if (res.success && res.data != null) {
          setState(() {
            _item = res.data!;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openAddStock() async {
    final updatedItem = await showDialog<InventoryItem>(
      context: context,
      builder: (ctx) => AddStockDialog(item: _item),
    );

    if (updatedItem != null) {
      _refreshDetails();
    }
  }

  Future<void> _openAdjustStock() async {
    final updatedItem = await showDialog<InventoryItem>(
      context: context,
      builder: (ctx) => AdjustStockDialog(item: _item),
    );

    if (updatedItem != null) {
      _refreshDetails();
    }
  }

  Future<void> _confirmDeleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
              SizedBox(width: 8),
              Text('Delete Item'),
            ],
          ),
          content: Text('Are you sure you want to delete ${_item.name}? This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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
      final res = await _inventoryRepository.deleteItem(_item.id);
      if (mounted && res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_item.name} deleted.'), backgroundColor: Colors.green.shade700),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String statusLabel = 'In Stock';
    Color statusColor = Colors.green.shade700;
    if (_item.isOutOfStock) {
      statusLabel = 'Out of Stock';
      statusColor = Colors.red.shade700;
    } else if (_item.isLowStock) {
      statusLabel = 'Low Stock (${_item.currentStock})';
      statusColor = Colors.amber.shade900;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_item.name, overflow: TextOverflow.ellipsis),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshDetails,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                AppRoutes.editInventoryItem,
                arguments: _item,
              );
              if (result == true) _refreshDetails();
            },
            tooltip: 'Edit Item',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            onPressed: _confirmDeleteItem,
            tooltip: 'Delete Item',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Summary Header Card
                  CustomCard(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _item.name,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            StatusBadge(
                              label: statusLabel.toUpperCase(),
                              backgroundColor: Colors.white,
                              textColor: statusColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Category: ${_item.category} • Type: ${_item.itemType.replaceAll('_', ' ').toUpperCase()}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        if (_item.brand != null || _item.model != null || _item.sku != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${_item.brand ?? ''} ${_item.model ?? ''} ${_item.sku != null ? '(SKU: ${_item.sku})' : ''}'.trim(),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Total: ${_item.totalStock} ${_item.unit} | Remaining: ${_item.currentStock} ${_item.unit}',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Min: ${_item.minimumStock} ${_item.unit}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openAddStock,
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                          label: const Text('Add Stock'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openAdjustStock,
                          icon: const Icon(Icons.published_with_changes_rounded, size: 18),
                          label: const Text('Stock Adjust'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Financial Valuation Card
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_balance_wallet_rounded, color: AppColors.accent, size: 20),
                            SizedBox(width: 8),
                            Text('Stock Valuation & Pricing', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Purchase Price (Cost):', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            Text('₹${_item.purchasePrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Selling Price:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            Text('₹${_item.sellingPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Margin / Profit per Unit:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            Text(
                              '₹${(_item.sellingPrice - _item.purchasePrice).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.accent),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Stock Value (Cost):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('₹${_item.stockValue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Mobile Serials / IMEI Card (if mobile type)
                  if (_item.serials.isNotEmpty) ...[
                    CustomCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.phone_android_rounded, color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text('Device Identifiers (IMEI / Serial)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ..._item.serials.map((s) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (s.imei1 != null) Text('IMEI 1: ${s.imei1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  if (s.imei2 != null) Text('IMEI 2: ${s.imei2}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  if (s.serialNumber != null) Text('Serial: ${s.serialNumber}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  StatusBadge(
                                    label: s.status.toUpperCase(),
                                    backgroundColor: s.status == 'available' ? Colors.green.shade50 : Colors.grey.shade100,
                                    textColor: s.status == 'available' ? Colors.green.shade800 : Colors.grey.shade800,
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 4. Description & Notes
                  if (_item.description != null && _item.description!.isNotEmpty) ...[
                    CustomCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Item Description', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(_item.description!, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 5. Stock Movement Timeline History Card
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Stock Movement History (${_item.stockMovements.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            TextButton.icon(
                              onPressed: _openAddStock,
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Add'),
                            ),
                          ],
                        ),
                        if (_item.stockMovements.isEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text('No stock movements recorded yet.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ),
                        ] else ...[
                          ..._item.stockMovements.map((mvt) {
                            final mColor = _movementColors[mvt.movementType] ?? AppColors.primary;
                            final isAddition = mvt.quantity > 0;
                            final qtyStr = isAddition ? '+${mvt.quantity}' : '${mvt.quantity}';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        StatusBadge(
                                          label: mvt.movementType.replaceAll('_', ' ').toUpperCase(),
                                          backgroundColor: mColor.withOpacity(0.12),
                                          textColor: mColor,
                                        ),
                                        Text(
                                          qtyStr,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: isAddition ? Colors.green.shade700 : Colors.red.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Unit Cost: ₹${mvt.unitCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    if (mvt.notes != null && mvt.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text('Notes: ${mvt.notes}', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      mvt.createdAt ?? '',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
