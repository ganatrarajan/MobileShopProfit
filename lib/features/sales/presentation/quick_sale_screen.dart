import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../inventory/models/inventory_item.dart';
import '../../inventory/presentation/widgets/quick_add_inventory_modal.dart';
import '../data/sale_repository.dart';
import '../../warranty/data/warranty_repository.dart';
import '../../../core/utils/whatsapp_helper.dart';
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
  final WarrantyRepository _warrantyRepository = WarrantyRepository();
  bool _addWarrantyOnCreate = false;
  int _selectedWarrantyDays = 180;
  final TextEditingController _warrantyTermsController = TextEditingController();
  final InventoryRepository _inventoryRepository = InventoryRepository();

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerMobileController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Quick Item Mode controllers
  String _saleMode = 'inventory'; // 'inventory' or 'quick'
  final TextEditingController _quickItemNameController = TextEditingController();
  final TextEditingController _quickItemPriceController = TextEditingController();

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
    _scrollController.dispose();
    _searchController.dispose();
    _customerNameController.dispose();
    _customerMobileController.dispose();
    _notesController.dispose();
    _quickItemNameController.dispose();
    _quickItemPriceController.dispose();
    _warrantyTermsController.dispose();
    super.dispose();
  }

  void _showFormError(String errorMsg) {
    FocusManager.instance.primaryFocus?.unfocus();
    AppFeedback.showError(context, error: errorMsg);
    setState(() => _errorMessage = errorMsg);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
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

  double get _effectiveUnitPrice {
    if (_saleMode == 'quick') {
      return double.tryParse(_quickItemPriceController.text.trim()) ?? 0.0;
    }
    return _unitPrice;
  }

  double get _total => (_quantity * _effectiveUnitPrice) - _discount;

  Future<void> _submitQuickSale() async {
    if (_quantity <= 0) {
      _showFormError('Quantity must be at least 1.');
      return;
    }

    SaleItem saleItem;

    if (_saleMode == 'inventory') {
      if (_selectedItem == null) {
        _showFormError('Please select an inventory item for Quick Sale.');
        return;
      }

      if (_quantity > _selectedItem!.currentStock) {
        _showFormError('Insufficient stock. Only ${_selectedItem!.currentStock} available.');
        return;
      }

      saleItem = SaleItem(
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
    } else {
      final name = _quickItemNameController.text.trim();
      final price = double.tryParse(_quickItemPriceController.text.trim());

      if (name.isEmpty) {
        _showFormError('Please enter item name for Quick Item.');
        return;
      }
      if (price == null || price < 0) {
        _showFormError('Please enter a valid price for Quick Item.');
        return;
      }

      saleItem = SaleItem(
        inventoryItemId: null,
        productName: name,
        itemType: 'accessory',
        quantity: _quantity,
        unitPrice: price,
        costPrice: 0.0,
        discount: _discount,
      );
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
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
          final createdSale = res.data!;
          if (_addWarrantyOnCreate) {
            try {
              final startDateStr = DateTime.now().toIso8601String().split('T')[0];
              await _warrantyRepository.createWarranty(
                customerId: null,
                deviceId: null,
                warrantyType: 'sale',
                durationDays: _selectedWarrantyDays,
                saleId: createdSale.id,
                warrantyStartDate: startDateStr,
                warrantyTerms: _warrantyTermsController.text.trim(),
              );
            } catch (e) {
              debugPrint('[QuickSale Warranty Error]: ${e.toString()}');
            }
          }
          AppFeedback.showSuccess(
            context,
            title: '⚡ Quick Sale Completed',
            message: 'Invoice #${res.data!.invoiceNumber} completed successfully.',
          );
          if (mounted && ((createdSale.customerMobile != null && createdSale.customerMobile!.trim().isNotEmpty) || (createdSale.customer?.mobile != null && createdSale.customer!.mobile.trim().isNotEmpty))) {
            await WhatsAppHelper.showWhatsAppSalePromptDialog(context, createdSale);
          }
          setState(() {
            _selectedItem = null;
            _quantity = 1;
            _unitPrice = 0.0;
            _discount = 0.0;
            _customerNameController.clear();
            _customerMobileController.clear();
            _notesController.clear();
            _searchController.clear();
            _quickItemNameController.clear();
            _quickItemPriceController.clear();
            _isSubmitting = false;
          });
          _fetchInventoryItems();

          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context, true);
          }
        } else {
          _showFormError(res.message);
          setState(() => _isSubmitting = false);
        }
      }
    } catch (e) {
      if (mounted) {
        _showFormError(e.toString());
        setState(() => _isSubmitting = false);
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
        controller: _scrollController,
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

            // 1. Item Selection Card (From Inventory vs Quick Item)
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Sale Item *', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  // Mode Selector Tabs
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          avatar: Icon(
                            Icons.inventory_2_rounded,
                            size: 16,
                            color: _saleMode == 'inventory' ? Colors.white : AppColors.primary,
                          ),
                          label: const Center(child: Text('From Inventory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          selected: _saleMode == 'inventory',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _saleMode = 'inventory';
                              });
                            }
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(color: _saleMode == 'inventory' ? Colors.white : AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          avatar: Icon(
                            Icons.flash_on_rounded,
                            size: 16,
                            color: _saleMode == 'quick' ? Colors.white : AppColors.primary,
                          ),
                          label: const Center(child: Text('Quick Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          selected: _saleMode == 'quick',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _saleMode = 'quick';
                                _selectedItem = null;
                              });
                            }
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(color: _saleMode == 'quick' ? Colors.white : AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_saleMode == 'inventory') ...[
                    // Search bar with + New item quick button
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (q) => _fetchInventoryItems(q.trim()),
                            decoration: InputDecoration(
                              hintText: 'Search covers, chargers, screen guards...',
                              prefixIcon: const Icon(Icons.search_rounded, size: 20),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final newItem = await QuickAddInventoryModal.show(context);
                            if (newItem != null) {
                              await _fetchInventoryItems();
                              _selectItem(newItem);
                            }
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('New', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                            ),
                          ),
                        ),
                      ],
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
                  ] else ...[
                    // Quick Item Entry Mode
                    CustomTextField(
                      label: 'Item Name / Description *',
                      hint: 'e.g. Temper Glass, Charging Cable, Cover',
                      controller: _quickItemNameController,
                      prefixIcon: Icons.shopping_bag_outlined,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Selling Price (₹) *',
                            hint: 'e.g. 150',
                            controller: _quickItemPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            prefixIcon: Icons.currency_rupee_rounded,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Quantity selector (used for both modes)
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Quantity:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                    onPressed: (_saleMode == 'inventory' && _selectedItem != null && _quantity >= _selectedItem!.currentStock)
                        ? null
                        : () => setState(() => _quantity++),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

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

            // 3.5 Warranty Card
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield_rounded, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Warranty Card',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: _addWarrantyOnCreate,
                        onChanged: (val) => setState(() => _addWarrantyOnCreate = val),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                  if (_addWarrantyOnCreate) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Warranty Duration',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        {'label': '7 Days', 'days': 7},
                        {'label': '15 Days', 'days': 15},
                        {'label': '30 Days (1 Mo)', 'days': 30},
                        {'label': '90 Days (3 Mo)', 'days': 90},
                        {'label': '180 Days (6 Mo)', 'days': 180},
                        {'label': '365 Days (1 Yr)', 'days': 365},
                      ].map((p) {
                        final days = p['days'] as int;
                        final isSelected = _selectedWarrantyDays == days;
                        return ChoiceChip(
                          label: Text(p['label'] as String),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedWarrantyDays = days);
                          },
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Warranty Terms / Coverage (Optional)',
                      hint: 'e.g. Quick Sale Accessory Warranty',
                      controller: _warrantyTermsController,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

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
