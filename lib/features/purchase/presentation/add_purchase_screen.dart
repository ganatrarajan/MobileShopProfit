import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../inventory/models/inventory_item.dart';
import '../../inventory/presentation/widgets/quick_add_inventory_modal.dart';
import '../data/purchase_repository.dart';
import '../models/vendor.dart';
import 'widgets/quick_add_vendor_modal.dart';

class AddPurchaseScreen extends StatefulWidget {
  const AddPurchaseScreen({super.key});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final PurchaseRepository _purchaseRepository = PurchaseRepository();
  final InventoryRepository _inventoryRepository = InventoryRepository();

  Vendor? _selectedVendor;
  List<Vendor> _vendorsList = [];
  bool _isLoadingVendors = false;

  List<InventoryItem> _inventoryItemsList = [];
  bool _isLoadingInventory = false;

  DateTime _purchaseDate = DateTime.now();
  final TextEditingController _discountController = TextEditingController(text: '0');
  final TextEditingController _additionalChargesController = TextEditingController(text: '0');
  final TextEditingController _amountPaidController = TextEditingController(text: '0');
  final TextEditingController _notesController = TextEditingController();

  String _paymentStatus = 'pending'; // paid, partial, pending
  bool _addToInventory = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Items added to the purchase draft
  final List<Map<String, dynamic>> _purchaseItems = [];

  // Line item controllers for adding new line
  InventoryItem? _selectedItemForAdd;
  final TextEditingController _itemQtyController = TextEditingController(text: '1');
  final TextEditingController _itemRateController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _loadVendors();
    _loadInventory();
  }

  @override
  void dispose() {
    _discountController.dispose();
    _additionalChargesController.dispose();
    _amountPaidController.dispose();
    _notesController.dispose();
    _itemQtyController.dispose();
    _itemRateController.dispose();
    super.dispose();
  }

  void _showFormError(String msg) {
    setState(() => _errorMessage = msg);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _loadVendors() async {
    setState(() => _isLoadingVendors = true);
    final response = await _purchaseRepository.getVendors(perPage: 100);
    if (mounted) setState(() => _isLoadingVendors = false);
    if (response.success && response.data != null) {
      if (mounted) {
        setState(() {
          _vendorsList = response.data!.vendors;
        });
      }
    }
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoadingInventory = true);
    final response = await _inventoryRepository.getInventory();
    if (mounted) setState(() => _isLoadingInventory = false);
    if (response.success && response.data != null) {
      if (mounted) {
        setState(() {
          _inventoryItemsList = response.data!.items;
        });
      }
    }
  }

  Future<void> _openQuickAddVendor() async {
    final newVendor = await QuickAddVendorModal.show(context);
    if (newVendor != null) {
      await _loadVendors();
      setState(() {
        _selectedVendor = _vendorsList.firstWhere(
          (v) => v.id == newVendor.id,
          orElse: () => newVendor,
        );
        _errorMessage = null;
      });
    }
  }

  Future<void> _openQuickAddInventory() async {
    final newItem = await QuickAddInventoryModal.show(context, isFromPurchase: true);
    if (newItem != null) {
      await _loadInventory();
      setState(() {
        _selectedItemForAdd = _inventoryItemsList.firstWhere(
          (item) => item.id == newItem.id,
          orElse: () => newItem,
        );
        _itemRateController.text = newItem.purchasePrice > 0
            ? newItem.purchasePrice.toStringAsFixed(2)
            : newItem.sellingPrice.toStringAsFixed(2);
        _errorMessage = null;
      });
    }
  }

  void _showVendorSearchBottomSheet() {
    String filterQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredVendors = _vendorsList.where((v) {
              final q = filterQuery.toLowerCase();
              return v.name.toLowerCase().contains(q) || v.phone.contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Vendor',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _openQuickAddVendor();
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                        label: const Text('+ Add Vendor', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: false,
                    decoration: InputDecoration(
                      hintText: 'Search by vendor name or phone...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        filterQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _isLoadingVendors
                        ? const Center(child: CircularProgressIndicator())
                        : filteredVendors.isEmpty
                            ? Center(
                                child: Text(
                                  _vendorsList.isEmpty ? 'No vendors found. Tap + Add Vendor to create one.' : 'No vendors match your search.',
                                  style: const TextStyle(color: AppColors.textMuted),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filteredVendors.length,
                                separatorBuilder: (ctx, idx) => const Divider(height: 1),
                                itemBuilder: (ctx, index) {
                                  final v = filteredVendors[index];
                                  final isSelected = _selectedVendor?.id == v.id;
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primary.withOpacity(0.1),
                                      child: Text(
                                        v.name.isNotEmpty ? v.name[0].toUpperCase() : 'V',
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(v.phone, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                                    trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedVendor = v;
                                        _errorMessage = null;
                                      });
                                      Navigator.pop(ctx);
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showItemSearchBottomSheet() {
    String filterQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredItems = _inventoryItemsList.where((item) {
              final q = filterQuery.toLowerCase();
              return item.name.toLowerCase().contains(q) ||
                  (item.sku != null && item.sku!.toLowerCase().contains(q)) ||
                  item.category.toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Product / Item',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _openQuickAddInventory();
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                        label: const Text('+ New Item', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: false,
                    decoration: InputDecoration(
                      hintText: 'Search product by name, SKU or category...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        filterQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _isLoadingInventory
                        ? const Center(child: CircularProgressIndicator())
                        : filteredItems.isEmpty
                            ? Center(
                                child: Text(
                                  _inventoryItemsList.isEmpty ? 'No inventory items available.' : 'No items match your search.',
                                  style: const TextStyle(color: AppColors.textMuted),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filteredItems.length,
                                separatorBuilder: (ctx, idx) => const Divider(height: 1),
                                itemBuilder: (ctx, index) {
                                  final item = filteredItems[index];
                                  final isSelected = _selectedItemForAdd?.id == item.id;
                                  final displayPrice = item.purchasePrice > 0 ? item.purchasePrice : item.sellingPrice;
                                  return ListTile(
                                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      'Stock: ${item.currentStock} | Cost: \u20B9${displayPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                    ),
                                    trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedItemForAdd = item;
                                        _itemRateController.text = displayPrice.toStringAsFixed(2);
                                        _errorMessage = null;
                                      });
                                      Navigator.pop(ctx);
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addItemToPurchase() {
    final itemToAdd = _selectedItemForAdd;
    if (itemToAdd == null) {
      _showFormError('Please select an inventory item.');
      return;
    }

    final qty = int.tryParse(_itemQtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      _showFormError('Enter a valid quantity.');
      return;
    }

    final rate = double.tryParse(_itemRateController.text.trim()) ?? 0.0;
    if (rate < 0) {
      _showFormError('Enter the purchase price.');
      return;
    }

    final lineTotal = qty * rate;

    setState(() {
      _purchaseItems.add({
        'inventory_item': itemToAdd,
        'inventory_item_id': itemToAdd.id,
        'item_name': itemToAdd.name,
        'quantity': qty,
        'purchase_rate': rate,
        'total_amount': lineTotal,
      });

      _selectedItemForAdd = null;
      _itemQtyController.text = '1';
      _itemRateController.text = '0';
      _errorMessage = null;
    });

    _recalculateTotals();
  }

  void _removeItemFromPurchase(int index) {
    setState(() {
      _purchaseItems.removeAt(index);
    });
    _recalculateTotals();
  }

  double get _subtotal {
    return _purchaseItems.fold(0.0, (sum, item) => sum + (item['total_amount'] as double));
  }

  double get _discount {
    return double.tryParse(_discountController.text.trim()) ?? 0.0;
  }

  double get _additionalCharges {
    return double.tryParse(_additionalChargesController.text.trim()) ?? 0.0;
  }

  double get _grandTotal {
    final total = _subtotal - _discount + _additionalCharges;
    return total < 0 ? 0.0 : total;
  }

  double get _amountPaid {
    return double.tryParse(_amountPaidController.text.trim()) ?? 0.0;
  }

  double get _outstanding {
    final out = _grandTotal - _amountPaid;
    return out < 0 ? 0.0 : out;
  }

  void _recalculateTotals() {
    setState(() {
      if (_paymentStatus == 'paid') {
        _amountPaidController.text = _grandTotal.toStringAsFixed(2);
      } else if (_paymentStatus == 'pending') {
        _amountPaidController.text = '0';
      }
    });
  }

  Future<void> _submitPurchase() async {
    setState(() => _errorMessage = null);

    if (_selectedVendor == null) {
      _showFormError('Please select a vendor.');
      return;
    }

    if (_purchaseItems.isEmpty) {
      _showFormError('Please add at least one item to the purchase.');
      return;
    }

    setState(() => _isSaving = true);

    final itemsPayload = _purchaseItems.map((pi) {
      return {
        'inventory_item_id': pi['inventory_item_id'],
        'quantity': pi['quantity'],
        'purchase_rate': pi['purchase_rate'],
      };
    }).toList();

    try {
      final response = await _purchaseRepository.createPurchase(
        vendorId: _selectedVendor!.id,
        purchaseDate: _purchaseDate.toIso8601String().split('T')[0],
        items: itemsPayload,
        discount: _discount,
        additionalCharges: _additionalCharges,
        amountPaid: _amountPaid,
        paymentStatus: _paymentStatus,
        addToInventory: _addToInventory,
        notes: _notesController.text.trim(),
      );

      if (mounted) setState(() => _isSaving = false);

      if (response.success && response.data != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchase Order created successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          _showFormError(response.message.isNotEmpty ? response.message : 'Failed to save purchase.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showFormError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Create Purchase Order',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 1. VENDOR SELECTION CARD
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1.5,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Vendor / Supplier *',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                          ),
                          TextButton.icon(
                            onPressed: _openQuickAddVendor,
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                            label: const Text('+ Add Vendor', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _showVendorSearchBottomSheet,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey.shade50,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.storefront_rounded, color: _selectedVendor != null ? AppColors.primary : Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedVendor != null
                                      ? '${_selectedVendor!.name} (${_selectedVendor!.phone})'
                                      : 'Select Vendor / Supplier',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: _selectedVendor != null ? FontWeight.bold : FontWeight.normal,
                                    color: _selectedVendor != null ? AppColors.textPrimary : AppColors.textMuted,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. PURCHASE DATE
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1.5,
                child: ListTile(
                  title: const Text('Purchase Date', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  subtitle: Text(
                    _purchaseDate.toIso8601String().split('T')[0],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                  ),
                  trailing: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _purchaseDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _purchaseDate = picked);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 3. ADD ITEMS SECTION
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1.5,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Select Product / Item *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                          TextButton.icon(
                            onPressed: _openQuickAddInventory,
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                            label: const Text('+ New Item', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _showItemSearchBottomSheet,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey.shade50,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, color: _selectedItemForAdd != null ? AppColors.primary : Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedItemForAdd != null ? _selectedItemForAdd!.name : 'Select Product / Item',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: _selectedItemForAdd != null ? FontWeight.bold : FontWeight.normal,
                                    color: _selectedItemForAdd != null ? AppColors.textPrimary : AppColors.textMuted,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _itemQtyController,
                              label: 'Quantity',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomTextField(
                              controller: _itemRateController,
                              label: 'Purchase Rate (\u20B9)',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(45),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _addItemToPurchase,
                        icon: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary),
                        label: const Text('+ Add Item to Purchase Draft', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),

                      // DRAFT ITEMS LIST
                      if (_purchaseItems.isNotEmpty) ...[
                        const Divider(height: 24),
                        const Text('Added Purchase Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _purchaseItems.length,
                          itemBuilder: (ctx, idx) {
                            final item = _purchaseItems[idx];
                            final double rate = item['purchase_rate'];
                            final double total = item['total_amount'];
                            return Card(
                              color: Colors.grey.shade50,
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                visualDensity: VisualDensity.compact,
                                title: Text(item['item_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  '${item['quantity']} x \u20B9${rate.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '\u20B9${total.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () => _removeItemFromPurchase(idx),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. BILLING & PAYMENT SUMMARY
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1.5,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Purchase Totals & Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:', style: TextStyle(color: AppColors.textMuted)),
                          Text('\u20B9${_subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _discountController,
                              label: 'Discount (\u20B9)',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) => _recalculateTotals(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomTextField(
                              controller: _additionalChargesController,
                              label: 'Additional Charges (\u20B9)',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) => _recalculateTotals(),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('\u20B9${_grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      const Text('Payment Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Pending')),
                              selected: _paymentStatus == 'pending',
                              selectedColor: Colors.red.shade100,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _paymentStatus = 'pending';
                                    _amountPaidController.text = '0';
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Partial')),
                              selected: _paymentStatus == 'partial',
                              selectedColor: Colors.amber.shade100,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _paymentStatus = 'partial');
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Paid')),
                              selected: _paymentStatus == 'paid',
                              selectedColor: Colors.green.shade100,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _paymentStatus = 'paid';
                                    _amountPaidController.text = _grandTotal.toStringAsFixed(2);
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_paymentStatus != 'pending')
                        CustomTextField(
                          controller: _amountPaidController,
                          label: 'Amount Paid (\u20B9)',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Outstanding Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('\u20B9${_outstanding.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: _outstanding > 0 ? AppColors.error : AppColors.success)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _notesController,
                        label: 'Notes (Optional)',
                        hint: 'Additional invoice / delivery notes',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 5. STOCK INTEGRATION OPTION
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1.5,
                color: Colors.purple.shade50,
                child: CheckboxListTile(
                  title: const Text('Add purchased items to Inventory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                  subtitle: const Text('Automatically increases item stock in inventory immediately after saving.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  value: _addToInventory,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    if (val != null) setState(() => _addToInventory = val);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // SUBMIT BUTTON
              CustomButton(
                text: 'Save Purchase',
                isLoading: _isSaving,
                onPressed: _submitPurchase,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
