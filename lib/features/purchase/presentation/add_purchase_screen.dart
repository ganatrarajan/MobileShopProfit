import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../inventory/models/inventory_item.dart';
import '../../inventory/presentation/widgets/quick_add_inventory_modal.dart';
import '../data/purchase_repository.dart';
import '../models/vendor.dart';
import '../models/purchase_item.dart';
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

  Future<void> _loadVendors() async {
    setState(() => _isLoadingVendors = true);
    final response = await _purchaseRepository.getVendors(perPage: 100);
    setState(() => _isLoadingVendors = false);
    if (response.success && response.data != null) {
      setState(() {
        _vendorsList = response.data!.vendors;
      });
    }
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoadingInventory = true);
    final response = await _inventoryRepository.getItems(perPage: 200);
    setState(() => _isLoadingInventory = false);
    if (response.success && response.data != null) {
      setState(() {
        _inventoryItemsList = response.data!.items;
      });
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
      });
    }
  }

  Future<void> _openQuickAddInventory() async {
    final newItem = await QuickAddInventoryModal.show(context);
    if (newItem != null) {
      await _loadInventory();
      setState(() {
        _selectedItemForAdd = _inventoryItemsList.firstWhere(
          (i) => i.id == newItem.id,
          orElse: () => newItem,
        );
        _itemRateController.text = newItem.purchasePrice.toStringAsFixed(2);
      });
    }
  }

  void _addItemToPurchase() {
    if (_selectedItemForAdd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an inventory item.')),
      );
      return;
    }

    final qty = int.tryParse(_itemQtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity.')),
      );
      return;
    }

    final rate = double.tryParse(_itemRateController.text.trim()) ?? 0;
    if (rate < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the purchase price.')),
      );
      return;
    }

    final lineTotal = qty * rate;

    setState(() {
      _purchaseItems.add({
        'inventory_item': _selectedItemForAdd,
        'inventory_item_id': _selectedItemForAdd!.id,
        'item_name': _selectedItemForAdd!.name,
        'quantity': qty,
        'purchase_rate': rate,
        'total_amount': lineTotal,
      });

      // Reset item entry fields
      _selectedItemForAdd = null;
      _itemQtyController.text = '1';
      _itemRateController.text = '0';
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
    if (_selectedVendor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vendor.')),
      );
      return;
    }

    if (_purchaseItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item to purchase.')),
      );
      return;
    }

    if (_amountPaid > _grandTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount paid cannot exceed grand total.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final itemsPayload = _purchaseItems.map((i) => {
      'inventory_item_id': i['inventory_item_id'],
      'quantity': i['quantity'],
      'purchase_rate': i['purchase_rate'],
    }).toList();

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

    setState(() => _isSaving = false);

    if (response.success) {
      if (mounted) {
        final msg = '? Purchase Created' + (_addToInventory ? ' & Stock Updated' : '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message.isNotEmpty ? response.message : 'Failed to record purchase.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Purchase'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. VENDOR SECTION
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
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
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          TextButton.icon(
                            onPressed: _openQuickAddVendor,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('+ Add Vendor', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _isLoadingVendors
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<Vendor>(
                              value: _selectedVendor,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                hintText: 'Select Vendor',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: _vendorsList.map((v) {
                                return DropdownMenuItem<Vendor>(
                                  value: v,
                                  child: Text('${v.name} (${v.phone})'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _selectedVendor = val);
                              },
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. PURCHASE DATE
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Purchase Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today_rounded, size: 16),
                        label: Text(_purchaseDate.toIso8601String().split('T')[0]),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _purchaseDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) setState(() => _purchaseDate = picked);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. PRODUCT ENTRY SECTION
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Add Products / Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          TextButton.icon(
                            onPressed: _openQuickAddInventory,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('+ Add Item', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _isLoadingInventory
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<InventoryItem>(
                              value: _selectedItemForAdd,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                hintText: 'Select Inventory Item',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: _inventoryItemsList.map((item) {
                                return DropdownMenuItem<InventoryItem>(
                                  value: item,
                                  child: Text('${item.name} (Stock: ${item.currentStock})'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedItemForAdd = val;
                                  if (val != null) {
                                    _itemRateController.text = val.purchasePrice.toStringAsFixed(2);
                                  }
                                });
                              },
                            ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _itemQtyController,
                              label: 'Qty',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomTextField(
                              controller: _itemRateController,
                              label: 'Purchase Rate (?)',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _addItemToPurchase,
                            child: const Text('+ Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Text('Items Added:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textMuted)),
                      const SizedBox(height: 8),

                      if (_purchaseItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text('No items added to purchase yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _purchaseItems.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _purchaseItems[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item['item_name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('${item['quantity']} × ?${(item['purchase_rate'] as double).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('?${(item['total_amount'] as double).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                    onPressed: () => _removeItemFromPurchase(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. BILLING & PAYMENT SUMMARY
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Purchase Totals & Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:', style: TextStyle(color: AppColors.textMuted)),
                          Text('?${_subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _discountController,
                              label: 'Discount (?)',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) => _recalculateTotals(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomTextField(
                              controller: _additionalChargesController,
                              label: 'Additional Charges (?)',
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
                          Text('?${_grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      const Text('Payment Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                          label: 'Amount Paid (?)',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Outstanding Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('?${_outstanding.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: _outstanding > 0 ? AppColors.error : AppColors.success)),
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
                elevation: 1,
                color: Colors.blue.shade50,
                child: CheckboxListTile(
                  title: const Text('Add purchased items to Inventory?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
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


