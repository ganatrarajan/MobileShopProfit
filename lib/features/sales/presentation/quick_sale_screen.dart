import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../inventory/models/inventory_item.dart';
import '../data/sale_repository.dart';
import '../models/sale.dart';

import '../../subscription/utils/subscription_guard.dart';

class QuickSaleScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  const QuickSaleScreen({super.key, this.onSuccess});

  @override
  State<QuickSaleScreen> createState() => QuickSaleScreenState();
}

class QuickSaleScreenState extends State<QuickSaleScreen> {
  void fetchInventoryItems() => _fetchInventoryItems();
  final SaleRepository _saleRepository = SaleRepository();
  final InventoryRepository _inventoryRepository = InventoryRepository();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerMobileController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<InventoryItem> _inventoryItems = [];
  InventoryItem? _selectedItem;
  bool _isLoadingItems = false;
  String? _inventoryError;

  int _quantity = 1;
  double _unitPrice = 0.0;
  double _discount = 0.0;
  String _paymentMethod = 'cash';
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInventoryItems();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'make quick sales');
        if (!ok && mounted) Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerNameController.dispose();
    _customerMobileController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchInventoryItems([String? query]) async {
    setState(() {
      _isLoadingItems = true;
      _inventoryError = null;
    });

    try {
      final res = await _inventoryRepository.getInventory(search: query);
      if (mounted) {
        if (res.success && res.data != null) {
          setState(() {
            _inventoryItems = res.data!.items;
            _isLoadingItems = false;
          });
        } else {
          setState(() {
            _inventoryError = res.message;
            _isLoadingItems = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _inventoryError = e.toString();
          _isLoadingItems = false;
        });
      }
    }
  }

  void _selectItem(InventoryItem item) {
    if (item.isOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item is out of stock! Cannot complete sale.')),
      );
      return;
    }

    setState(() {
      _selectedItem = item;
      _unitPrice = item.sellingPrice;
      _quantity = 1;
    });
  }

  double get _total => (_quantity * _unitPrice) - _discount;

  Future<void> _submitQuickSale() async {
    if (_selectedItem == null) {
      setState(() => _errorMessage = 'Please select an inventory item for Quick Sale.');
      return;
    }

    if (_quantity <= 0) {
      setState(() => _errorMessage = 'Quantity must be at least 1.');
      return;
    }

    if (_quantity > _selectedItem!.currentStock) {
      setState(() => _errorMessage = 'Insufficient stock. Only ${_selectedItem!.currentStock} available.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final saleItem = SaleItem(
        inventoryItemId: _selectedItem!.id,
        productName: _selectedItem!.name,
        itemType: _selectedItem!.itemType,
        brand: _selectedItem!.brand,
        model: _selectedItem!.model,
        quantity: _quantity,
        unitPrice: _unitPrice,
        costPrice: _selectedItem!.purchasePrice,
        discount: _discount,
      );

      final res = await _saleRepository.createSale(
        saleType: 'quick',
        customerId: null, // Optional for Quick Sale
        customerName: _customerNameController.text.trim(),
        customerMobile: _customerMobileController.text.trim(),
        notes: _notesController.text.trim(),
        items: [saleItem],
        paymentAmount: _total,
        paymentMethod: _paymentMethod,
      );

      if (mounted) {
        if (res.success && res.data != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚡ Quick Sale #${res.data!.invoiceNumber} completed successfully! Stock updated.'),
              backgroundColor: Colors.green.shade700,
            ),
          );
          setState(() {
            _selectedItem = null;
            _quantity = 1;
            _unitPrice = 0.0;
            _discount = 0.0;
            _customerNameController.clear();
            _customerMobileController.clear();
            _notesController.clear();
            _searchController.clear();
            _isSubmitting = false;
          });
          _fetchInventoryItems();

          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context, true);
          }
        } else {
          setState(() {
            _errorMessage = res.message;
            _isSubmitting = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: Colors.amberAccent, size: 22),
            SizedBox(width: 6),
            Text('Quick Sale'),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(8)),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ),
              const SizedBox(height: 14),
            ],

            // 1. Inventory Item Picker Card
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Inventory Item *', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    onChanged: (q) => _fetchInventoryItems(q.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search covers, chargers, screen guards...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_isLoadingItems)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
                  else if (_inventoryError != null)
                    Text(_inventoryError!, style: const TextStyle(color: AppColors.error, fontSize: 12))
                  else if (_inventoryItems.isEmpty)
                    const Padding(padding: EdgeInsets.all(12), child: Text('No items found in stock.', style: TextStyle(color: AppColors.textMuted)))
                  else
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListView.separated(
                        itemCount: _inventoryItems.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final item = _inventoryItems[idx];
                          final isSelected = _selectedItem?.id == item.id;
                          final isOut = item.isOutOfStock;

                          return ListTile(
                            dense: true,
                            tileColor: isSelected ? AppColors.primary.withOpacity(0.08) : null,
                            title: Text(
                              item.name,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isOut ? Colors.grey : AppColors.textPrimary),
                            ),
                            subtitle: Text('Stock: ${item.currentStock} ${item.unit} | ₹${item.sellingPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11)),
                            trailing: isOut
                                ? const Text('OUT OF STOCK', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 10))
                                : Icon(isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded, color: isSelected ? Colors.green : AppColors.primary, size: 20),
                            onTap: () => _selectItem(item),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Selected Item & Quantity Card
            if (_selectedItem != null) ...[
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_selectedItem!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                              Text('Available Stock: ${_selectedItem!.currentStock} ${_selectedItem!.unit}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Text('₹${_unitPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Text('Quantity:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.primary),
                          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                          onPressed: _quantity < _selectedItem!.currentStock ? () => setState(() => _quantity++) : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 2. Optional Customer Information (Stored on sale only, no permanent customer creation)
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 18, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text('Customer Information (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Stored with this Quick Sale transaction only. Will NOT create a permanent customer record.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Customer Name',
                          hint: 'e.g. Amit',
                          controller: _customerNameController,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          label: 'Customer Mobile',
                          hint: 'e.g. 9876543210',
                          controller: _customerMobileController,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Payment Method Card
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Method *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPaymentChip('cash', 'Cash', Icons.payments_rounded),
                      _buildPaymentChip('upi', 'UPI / QR', Icons.qr_code_2_rounded),
                      _buildPaymentChip('card', 'Card', Icons.credit_card_rounded),
                      _buildPaymentChip('bank_transfer', 'Bank', Icons.account_balance_rounded),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Total & Complete Quick Sale Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      Text('₹${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitQuickSale,
                      icon: const Icon(Icons.bolt_rounded, color: Colors.white),
                      label: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Complete Quick Sale (₹${_total.toStringAsFixed(2)})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade900,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentChip(String value, String label, IconData icon) {
    final isSelected = _paymentMethod == value;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.primary),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _paymentMethod = value);
      },
      selectedColor: AppColors.primary,
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
    );
  }
}
