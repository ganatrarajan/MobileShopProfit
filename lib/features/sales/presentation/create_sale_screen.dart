import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../customer/data/customer_repository.dart';
import '../../customer/models/customer.dart';
import '../../device/data/device_repository.dart';
import '../../device/models/device.dart';
import '../data/sale_repository.dart';
import '../models/sale.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../inventory/models/inventory_item.dart';

import '../../subscription/utils/subscription_guard.dart';

class CreateSaleScreen extends StatefulWidget {
  const CreateSaleScreen({super.key});

  @override
  State<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends State<CreateSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _saleRepository = SaleRepository();
  final _customerRepository = CustomerRepository();
  final _deviceRepository = DeviceRepository();

  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '0');
  final _paymentAmountController = TextEditingController();
  final _notesController = TextEditingController();

  Customer? _selectedCustomer;
  Device? _selectedDevice;
  List<Customer> _customerList = [];
  List<Device> _deviceList = [];
  bool _isLoadingCustomers = false;
  bool _isLoadingDevices = false;

  final List<SaleItem> _items = [];
  String _paymentMethod = 'cash';
  String _paymentStatusMode = 'paid'; // 'paid', 'partial', 'due'
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'create sales invoices');
        if (!ok && mounted) Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _discountController.dispose();
    _taxController.dispose();
    _paymentAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoadingCustomers = true);
    try {
      final res = await _customerRepository.getCustomers();
      if (res.success && res.data != null) {
        setState(() {
          _customerList = res.data!;
          _isLoadingCustomers = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingCustomers = false);
    }
  }

  Future<void> _loadDevicesForCustomer(int customerId) async {
    setState(() => _isLoadingDevices = true);
    try {
      final res = await _deviceRepository.getDevicesForCustomer(customerId);
      if (res.success && res.data != null) {
        setState(() {
          _deviceList = res.data!;
          _isLoadingDevices = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingDevices = false);
    }
  }

  double get _subtotal {
    double sum = 0.0;
    for (final item in _items) {
      sum += (item.quantity * item.unitPrice);
    }
    return sum;
  }

  double get _totalDiscount {
    double saleDiscount = double.tryParse(_discountController.text.trim()) ?? 0.0;
    double itemDiscounts = 0.0;
    for (final item in _items) {
      itemDiscounts += item.discount;
    }
    return saleDiscount + itemDiscounts;
  }

  double get _totalTax {
    double saleTax = double.tryParse(_taxController.text.trim()) ?? 0.0;
    double itemTax = 0.0;
    for (final item in _items) {
      itemTax += item.taxAmount;
    }
    return saleTax + itemTax;
  }

  double get _grandTotal {
    final total = _subtotal - _totalDiscount + _totalTax;
    return total < 0 ? 0.0 : total;
  }

  double get _amountPaid {
    return double.tryParse(_paymentAmountController.text.trim()) ?? 0.0;
  }

  double get _amountDue {
    final due = _grandTotal - _amountPaid;
    return due < 0 ? 0.0 : due;
  }

  Widget _buildTypeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.white : AppColors.textSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addItemDialog() {
    String saleMode = 'inventory'; // 'inventory' or 'quick'
    String itemType = 'accessory';

    // Quick Item controllers
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final imei1Ctrl = TextEditingController();
    final imei2Ctrl = TextEditingController();
    final serialCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final discountCtrl = TextEditingController(text: '0');

    // From Inventory state
    final invRepository = InventoryRepository();
    final searchCtrl = TextEditingController();
    List<InventoryItem> invItems = [];
    InventoryItem? selectedInvItem;
    bool isLoadingInv = false;
    String? invError;

    Future<void> fetchInventory(StateSetter setDialogState, {String? query}) async {
      setDialogState(() {
        isLoadingInv = true;
        invError = null;
      });
      try {
        final res = await invRepository.getInventory(search: query);
        if (res.success && res.data != null) {
          setDialogState(() {
            invItems = res.data!.items;
            isLoadingInv = false;
          });
        } else {
          setDialogState(() {
            invError = res.message;
            isLoadingInv = false;
          });
        }
      } catch (e) {
        setDialogState(() {
          invError = e.toString();
          isLoadingInv = false;
        });
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (saleMode == 'inventory' && invItems.isEmpty && !isLoadingInv && invError == null) {
              fetchInventory(setDialogState);
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text('Add Sale Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Two Modes Selector Tabs
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('From Inventory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          selected: saleMode == 'inventory',
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                saleMode = 'inventory';
                                selectedInvItem = null;
                              });
                            }
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(color: saleMode == 'inventory' ? Colors.white : AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Quick Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          selected: saleMode == 'quick',
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                saleMode = 'quick';
                                selectedInvItem = null;
                              });
                            }
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(color: saleMode == 'quick' ? Colors.white : AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (saleMode == 'inventory') ...[
                        // INVENTORY SELECTION MODE
                        const SizedBox(height: 6),
                        TextField(
                          controller: searchCtrl,
                          onChanged: (q) => fetchInventory(setDialogState, query: q.trim()),
                          decoration: InputDecoration(
                            hintText: 'Search Name, SKU, Brand, Model...',
                            hintStyle: const TextStyle(fontSize: 12),
                            prefixIcon: const Icon(Icons.search_rounded, size: 18),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (isLoadingInv)
                          const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                        else if (invError != null)
                          Text(invError!, style: const TextStyle(color: AppColors.error, fontSize: 12))
                        else if (invItems.isEmpty)
                          const Padding(padding: EdgeInsets.all(12), child: Text('No inventory items found.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)))
                        else
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.separated(
                              itemCount: invItems.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final item = invItems[idx];
                                final isSelected = selectedInvItem?.id == item.id;
                                final isOut = item.isOutOfStock;

                                return ListTile(
                                  dense: true,
                                  tileColor: isSelected ? AppColors.primary.withOpacity(0.08) : null,
                                  title: Text(
                                    item.name,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isOut ? Colors.grey : AppColors.textPrimary),
                                  ),
                                  subtitle: Text(
                                    '${item.brand ?? ''} ${item.model ?? ''} • ${item.itemType.replaceAll('_', ' ').toUpperCase()}'.trim(),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('₹${item.sellingPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                                      Text(
                                        isOut ? 'Out of Stock' : 'Stock: ${item.currentStock}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isOut ? FontWeight.bold : FontWeight.normal,
                                          color: isOut ? AppColors.error : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: isOut
                                      ? null
                                      : () {
                                          setDialogState(() {
                                            selectedInvItem = item;
                                            nameCtrl.text = item.name;
                                            priceCtrl.text = item.sellingPrice.toStringAsFixed(2);
                                            qtyCtrl.text = '1';
                                          });
                                        },
                                );
                              },
                            ),
                          ),
                        if (selectedInvItem != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(selectedInvItem!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text('Available Stock: ${selectedInvItem!.currentStock} | Cost Price: ₹${selectedInvItem!.purchasePrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: 'Selling Price (₹) *',
                                hint: 'Price',
                                controller: priceCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomTextField(
                                label: 'Qty *',
                                hint: '1',
                                controller: qtyCtrl,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          label: 'Item Discount (₹)',
                          hint: '0',
                          controller: discountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ] else ...[
                        // QUICK ITEM MODE
                        const SizedBox(height: 10),
                        const Text('Item Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildTypeOption(
                              label: 'Accessory',
                              icon: Icons.headset_mic_rounded,
                              isSelected: itemType == 'accessory',
                              onTap: () {
                                setDialogState(() => itemType = 'accessory');
                              },
                            ),
                            const SizedBox(width: 6),
                            _buildTypeOption(
                              label: 'Mobile',
                              icon: Icons.smartphone_rounded,
                              isSelected: itemType == 'mobile',
                              onTap: () {
                                setDialogState(() {
                                  itemType = 'mobile';
                                  nameCtrl.text = '${brandCtrl.text} ${modelCtrl.text}'.trim();
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            _buildTypeOption(
                              label: 'Other',
                              icon: Icons.inventory_2_rounded,
                              isSelected: itemType == 'product',
                              onTap: () {
                                setDialogState(() => itemType = 'product');
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Item Name / Description *',
                          hint: 'e.g. Screen Guard or Fast Charger',
                          controller: nameCtrl,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: 'Selling Price (₹) *',
                                hint: 'Price',
                                controller: priceCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomTextField(
                                label: 'Qty *',
                                hint: '1',
                                controller: qtyCtrl,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          label: 'Item Discount (₹)',
                          hint: '0',
                          controller: discountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                    final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
                    final disc = double.tryParse(discountCtrl.text.trim()) ?? 0.0;

                    if (saleMode == 'inventory' && selectedInvItem == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select an item from inventory.')),
                      );
                      return;
                    }

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter item name.')),
                      );
                      return;
                    }

                    if (price <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid price.')),
                      );
                      return;
                    }

                    if (qty <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Quantity must be at least 1.')),
                      );
                      return;
                    }

                    if (saleMode == 'inventory' && selectedInvItem != null) {
                      if (qty > selectedInvItem!.currentStock) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Cannot sell ${qty} unit(s). Only ${selectedInvItem!.currentStock} available in stock.')),
                        );
                        return;
                      }
                    }

                    final newItem = SaleItem(
                      inventoryItemId: saleMode == 'inventory' ? selectedInvItem?.id : null,
                      productName: name,
                      itemType: saleMode == 'inventory' ? selectedInvItem!.itemType : itemType,
                      brand: saleMode == 'inventory' ? selectedInvItem?.brand : (brandCtrl.text.trim().isNotEmpty ? brandCtrl.text.trim() : null),
                      model: saleMode == 'inventory' ? selectedInvItem?.model : (modelCtrl.text.trim().isNotEmpty ? modelCtrl.text.trim() : null),
                      quantity: qty,
                      unitPrice: price,
                      costPrice: saleMode == 'inventory' ? selectedInvItem?.purchasePrice : null,
                      discount: disc,
                    );

                    setState(() {
                      _items.add(newItem);
                      _paymentAmountController.text = _grandTotal.toStringAsFixed(2);
                    });

                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                  label: const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitSale() async {
    if (_items.isEmpty) {
      setState(() => _errorMessage = 'Please add at least one sale item.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final discount = double.tryParse(_discountController.text.trim()) ?? 0.0;
      final tax = double.tryParse(_taxController.text.trim()) ?? 0.0;
      final initialPayment = double.tryParse(_paymentAmountController.text.trim()) ?? 0.0;

      final response = await _saleRepository.createSale(
        customerId: _selectedCustomer?.id,
        deviceId: _selectedDevice?.id,
        discount: discount,
        taxAmount: tax,
        notes: _notesController.text.trim(),
        items: _items,
        paymentAmount: initialPayment,
        paymentMethod: _paymentMethod,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invoice ${response.data!.invoiceNumber} generated successfully!'),
              backgroundColor: Colors.green.shade700,
            ),
          );
          Navigator.pop(context, true);
        } else {
          setState(() => _errorMessage = response.message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Sale / Invoice'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(8),
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
                const SizedBox(height: 16),
              ],

              // 1. Customer & Device Selection Card (Optional)
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.person_outline_rounded, color: AppColors.accent, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Customer & Device',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Link customer or walk-in sale',
                                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedCustomer != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedCustomer = null;
                                _selectedDevice = null;
                                _deviceList = [];
                              });
                            },
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                            child: const Text('Walk-in Sale', style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<Customer>(
                      value: _selectedCustomer,
                      isExpanded: true,
                      hint: _isLoadingCustomers
                          ? const Text('Loading customers...')
                          : const Text('Select Customer (Optional / Walk-in)'),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      ),
                      items: _customerList.map((c) {
                        return DropdownMenuItem<Customer>(
                          value: c,
                          child: Text('${c.name} (${c.mobile})', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCustomer = val;
                          _selectedDevice = null;
                        });
                        if (val != null) {
                          _loadDevicesForCustomer(val.id);
                        }
                      },
                    ),
                    if (_selectedCustomer != null) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Device>(
                        value: _selectedDevice,
                        isExpanded: true,
                        hint: _isLoadingDevices
                            ? const Text('Loading customer devices...')
                            : const Text('Select Customer Device (Optional)'),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.primary),
                        ),
                        items: _deviceList.map((d) {
                          final imeiStr = d.imei1 != null ? ' - ${d.imei1}' : '';
                          return DropdownMenuItem<Device>(
                            value: d,
                            child: Text('${d.brand} ${d.model}$imeiStr', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedDevice = val);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Sale Items Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sale Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ElevatedButton.icon(
                    onPressed: _addItemDialog,
                    icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                    label: const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_items.isEmpty) ...[
                CustomCard(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        const Text('No items added yet', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: _addItemDialog,
                          child: const Text('+ Tap to Add Mobile / Accessory / Product'),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  itemBuilder: (ctx, idx) {
                    final item = _items[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: CustomCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: item.itemType == 'mobile' ? Colors.blue.shade50 : AppColors.accentLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                item.itemType == 'mobile' ? Icons.smartphone_rounded : Icons.headset_mic_rounded,
                                color: item.itemType == 'mobile' ? Colors.blue.shade700 : AppColors.accent,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  if (item.imei1 != null) ...[
                                    Text('IMEI: ${item.imei1}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.quantity} x ₹${item.unitPrice.toStringAsFixed(2)} ${item.discount > 0 ? "(-₹${item.discount.toStringAsFixed(2)})" : ""}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹ ${item.total.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _items.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),

              // 3. Discount & Tax Inputs
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Overall Discount & Tax', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Overall Discount (₹)',
                            hint: '0',
                            controller: _discountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) {
                              setState(() {
                                _paymentAmountController.text = _grandTotal.toStringAsFixed(2);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'Tax / GST Amount (₹)',
                            hint: '0',
                            controller: _taxController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) {
                              setState(() {
                                _paymentAmountController.text = _grandTotal.toStringAsFixed(2);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Financial Calculations Summary Card (Prominent Grand Total)
              CustomCard(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('₹ ${_subtotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (_totalDiscount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Discount:', style: TextStyle(color: Colors.greenAccent, fontSize: 13)),
                          Text('- ₹ ${_totalDiscount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                    if (_totalTax > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax / GST:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text('+ ₹ ${_totalTax.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: Colors.white30, height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('GRAND TOTAL', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('Final Invoice Amount', style: TextStyle(color: Colors.white60, fontSize: 11)),
                          ],
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '₹ ${_grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Payment Details Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Status / Collection Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _paymentStatusMode = 'paid';
                                _paymentAmountController.text = _grandTotal.toStringAsFixed(2);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                              decoration: BoxDecoration(
                                color: _paymentStatusMode == 'paid' ? Colors.green.shade700 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _paymentStatusMode == 'paid' ? Colors.green.shade700 : Colors.grey.shade300),
                              ),
                              child: Center(
                                child: Text(
                                  '🟢 Paid',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _paymentStatusMode == 'paid' ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _paymentStatusMode = 'partial';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                              decoration: BoxDecoration(
                                color: _paymentStatusMode == 'partial' ? Colors.orange.shade800 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _paymentStatusMode == 'partial' ? Colors.orange.shade800 : Colors.grey.shade300),
                              ),
                              child: Center(
                                child: Text(
                                  '🟠 Partial',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _paymentStatusMode == 'partial' ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _paymentStatusMode = 'due';
                                _paymentAmountController.text = '0';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                              decoration: BoxDecoration(
                                color: _paymentStatusMode == 'due' ? Colors.red.shade700 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _paymentStatusMode == 'due' ? Colors.red.shade700 : Colors.grey.shade300),
                              ),
                              child: Center(
                                child: Text(
                                  '🔴 Unpaid',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _paymentStatusMode == 'due' ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_paymentStatusMode != 'due') ...[
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Paid Amount (₹)',
                              hint: '0.00',
                              controller: _paymentAmountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _paymentStatusMode = 'paid';
                                _paymentAmountController.text = _grandTotal.toStringAsFixed(2);
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentLight,
                              foregroundColor: AppColors.accent,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                            ),
                            child: const Text('Full Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text('Payment Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'upi', child: Text('UPI / PhonePe / GPay')),
                        DropdownMenuItem(value: 'card', child: Text('Credit / Debit Card')),
                        DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _paymentMethod = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        String statusLabel;
                        String statusVal;
                        Color bg;
                        Color border;
                        Color textClr;

                        if (_paymentStatusMode == 'due') {
                          statusLabel = 'PAYMENT STATUS:';
                          statusVal = 'UNPAID / DUE';
                          bg = Colors.red.shade50;
                          border = Colors.red.shade200;
                          textClr = Colors.red.shade800;
                        } else if (_paymentStatusMode == 'partial' || _amountDue > 0) {
                          statusLabel = 'AMOUNT DUE:';
                          statusVal = '₹ ${_amountDue.toStringAsFixed(2)}';
                          bg = Colors.orange.shade50;
                          border = Colors.orange.shade200;
                          textClr = Colors.orange.shade900;
                        } else {
                          statusLabel = 'PAYMENT STATUS:';
                          statusVal = 'PAID IN FULL';
                          bg = Colors.green.shade50;
                          border = Colors.green.shade200;
                          textClr = Colors.green.shade800;
                        }

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textClr,
                                ),
                              ),
                              Text(
                                statusVal,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textClr,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Invoice Notes (Optional)',
                hint: 'Internal notes or terms',
                controller: _notesController,
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              CustomButton(
                text: 'Save & Generate Invoice',
                isLoading: _isSubmitting,
                onPressed: _submitSale,
                icon: Icons.receipt_rounded,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
