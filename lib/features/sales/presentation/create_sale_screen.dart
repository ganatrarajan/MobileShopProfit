import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_error_mapper.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/widgets/app_searchable_bottom_sheet.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../customer/data/customer_repository.dart';
import '../../customer/models/customer.dart';
import '../../customer/presentation/widgets/quick_add_customer_modal.dart';
import '../../device/data/device_repository.dart';
import '../../device/models/device.dart';
import '../../device/presentation/widgets/quick_add_device_modal.dart';
import '../data/sale_repository.dart';
import '../../warranty/data/warranty_repository.dart';
import '../models/sale.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../inventory/models/inventory_item.dart';
import '../../inventory/presentation/widgets/quick_add_inventory_modal.dart';
import '../../../core/widgets/barcode_scanner_screen.dart';
import '../../used_mobile/data/used_mobile_repository.dart';
import '../../used_mobile/models/used_mobile.dart';

class CreateSaleScreen extends StatefulWidget {
  const CreateSaleScreen({super.key});

  @override
  State<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends State<CreateSaleScreen> {
  final _formKey = GlobalKey<FormState>();
    final _saleRepository = SaleRepository();
  final _warrantyRepository = WarrantyRepository();
  bool _addWarrantyOnCreate = false;
  int _selectedWarrantyDays = 180;
  final _warrantyTermsController = TextEditingController();
  final _customerRepository = CustomerRepository();
  final _deviceRepository = DeviceRepository();

  final ScrollController _scrollController = ScrollController();
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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _paymentAmountController.dispose();
    _notesController.dispose();
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

  StateSetter? _activeCustomerModalState;
  StateSetter? _activeDeviceModalState;

  Future<void> _loadCustomers() async {
    if (!mounted) return;
    setState(() => _isLoadingCustomers = true);
    _activeCustomerModalState?.call(() {});
    try {
      final res = await _customerRepository.getCustomers();
      if (mounted) {
        if (res.success && res.data != null) {
          setState(() {
            _customerList = res.data!;
            _isLoadingCustomers = false;
          });
        } else {
          setState(() => _isLoadingCustomers = false);
        }
        _activeCustomerModalState?.call(() {});
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingCustomers = false);
        _activeCustomerModalState?.call(() {});
      }
    }
  }

  Future<void> _loadDevicesForCustomer(int customerId) async {
    if (!mounted) return;
    setState(() => _isLoadingDevices = true);
    _activeDeviceModalState?.call(() {});
    try {
      final res = await _deviceRepository.getDevicesForCustomer(customerId);
      if (mounted) {
        if (res.success && res.data != null) {
          setState(() {
            _deviceList = res.data!;
            _isLoadingDevices = false;
          });
        } else {
          setState(() => _isLoadingDevices = false);
        }
        _activeDeviceModalState?.call(() {});
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingDevices = false);
        _activeDeviceModalState?.call(() {});
      }
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

  void _showCustomerSearchBottomSheet() {
    String filterQuery = '';

    if (_customerList.isEmpty && !_isLoadingCustomers) {
      _loadCustomers();
    }

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
            _activeCustomerModalState = setModalState;
            final filteredCustomers = _customerList.where((c) {
              final q = filterQuery.toLowerCase();
              return c.name.toLowerCase().contains(q) || c.mobile.contains(q);
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
                      const Expanded(
                        child: Text(
                          'Select Customer',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final newCust = await QuickAddCustomerModal.show(context);
                              if (newCust != null && mounted) {
                                _loadCustomers();
                                setState(() {
                                  _selectedCustomer = newCust;
                                  _selectedDevice = null;
                                });
                                _loadDevicesForCustomer(newCust.id);
                                if (ctx.mounted) Navigator.pop(ctx);
                              }
                            },
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add New', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextField(
                    onChanged: (val) {
                      setModalState(() => filterQuery = val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by customer name or mobile...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _isLoadingCustomers
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : filteredCustomers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('No customers found', style: TextStyle(color: AppColors.textSecondary)),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: () => _loadCustomers(),
                                      icon: const Icon(Icons.refresh_rounded, size: 16),
                                      label: const Text('Reload Customers'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: filteredCustomers.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final customer = filteredCustomers[idx];
                                  final isSelected = _selectedCustomer?.id == customer.id;
                                  return ListTile(
                                    title: Text(
                                      customer.name,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      ),
                                    ),
                                    subtitle: Text(customer.mobile, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedCustomer = customer;
                                        _selectedDevice = null;
                                      });
                                      _loadDevicesForCustomer(customer.id);
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
    ).then((_) => _activeCustomerModalState = null);
  }

  void _showDeviceSearchBottomSheet() {
    if (_selectedCustomer == null) return;
    String filterQuery = '';

    if (_deviceList.isEmpty && !_isLoadingDevices) {
      _loadDevicesForCustomer(_selectedCustomer!.id);
    }

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
            _activeDeviceModalState = setModalState;
            final filteredDevices = _deviceList.where((d) {
              final q = filterQuery.toLowerCase();
              return d.brand.toLowerCase().contains(q) ||
                  d.model.toLowerCase().contains(q) ||
                  (d.imei1 != null && d.imei1!.contains(q));
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
                      const Expanded(
                        child: Text(
                          'Select Customer Device',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final newDev = await QuickAddDeviceModal.show(context, initialCustomer: _selectedCustomer);
                              if (newDev != null && mounted) {
                                if (_selectedCustomer != null) {
                                  _loadDevicesForCustomer(_selectedCustomer!.id);
                                }
                                setState(() {
                                  _selectedDevice = newDev;
                                });
                                if (ctx.mounted) Navigator.pop(ctx);
                              }
                            },
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add New', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextField(
                    onChanged: (val) {
                      setModalState(() => filterQuery = val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search model, brand, IMEI...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _isLoadingDevices
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : filteredDevices.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('No devices found', style: TextStyle(color: AppColors.textSecondary)),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: () {
                                        if (_selectedCustomer != null) {
                                          _loadDevicesForCustomer(_selectedCustomer!.id);
                                        }
                                      },
                                      icon: const Icon(Icons.refresh_rounded, size: 16),
                                      label: const Text('Reload Devices'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: filteredDevices.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final device = filteredDevices[idx];
                                  final isSelected = _selectedDevice?.id == device.id;
                                  final imeiStr = device.imei1 != null ? 'IMEI: ${device.imei1}' : '';
                                  return ListTile(
                                    title: Text(
                                      '${device.brand} ${device.model}',
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      ),
                                    ),
                                    subtitle: imeiStr.isNotEmpty ? Text(imeiStr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)) : null,
                                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedDevice = device;
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
    ).then((_) => _activeDeviceModalState = null);
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

  bool _isProcessingScan = false;

  Future<void> _scanToSell() async {
    final scanned = await BarcodeScannerScreen.scan(
      context,
      title: 'Scan Barcode or IMEI to Sell',
      instruction: 'Scan device barcode or IMEI on phone box sticker',
    );
    if (scanned == null || scanned.trim().isEmpty) return;
    await _processScannedCodeToSell(scanned.trim());
  }

  Future<void> _processScannedCodeToSell(String code) async {
    if (_isProcessingScan) return;
    _isProcessingScan = true;

    final cleanCode = code.replaceFirst(RegExp(r'^(s/n|sn|serial|imei1|imei2|imei|p/n|pn)[:\s-]+', caseSensitive: false), '').trim();
    final cleanDigits = code.replaceAll(RegExp(r'\D'), '');
    final codeLower = code.toLowerCase();
    final cleanCodeLower = cleanCode.toLowerCase();

    // Check if an item with this IMEI or Serial is already in invoice
    final alreadyAdded = _items.any(
      (si) {
        final s1 = si.imei1?.trim().toLowerCase();
        final s2 = si.imei2?.trim().toLowerCase();
        final sn = si.serialNumber?.trim().toLowerCase();
        return s1 == codeLower || s1 == cleanCodeLower ||
            s2 == codeLower || s2 == cleanCodeLower ||
            sn == codeLower || sn == cleanCodeLower;
      },
    );
    if (alreadyAdded) {
      _isProcessingScan = false;
      AppFeedback.showError(
        context,
        title: 'Already Added',
        message: 'A device with identifier $code is already added in this sale invoice.',
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(child: Text('Looking up "$code" in inventory & showroom...')),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final searchKey = cleanCode.isNotEmpty ? cleanCode : code;

      // 1. First check Inventory items by IMEI/Barcode/SKU/Serial
      final invRepo = InventoryRepository();
      final invRes = await invRepo.getInventory(search: searchKey);

      if (invRes.success && invRes.data != null && invRes.data!.items.isNotEmpty) {
        // Find best match in returned items
        InventoryItem? matchedItem;
        String? matchedImei1;
        String? matchedImei2;
        String? matchedSerial;

        for (final item in invRes.data!.items) {
          for (final s in item.serials) {
            final s1Digits = s.imei1?.replaceAll(RegExp(r'\D'), '') ?? '';
            final s2Digits = s.imei2?.replaceAll(RegExp(r'\D'), '') ?? '';
            final s1Lower = s.imei1?.trim().toLowerCase();
            final s2Lower = s.imei2?.trim().toLowerCase();
            final sSerialLower = s.serialNumber?.trim().toLowerCase();
            final sSerialDigits = s.serialNumber?.replaceAll(RegExp(r'\D'), '') ?? '';

            final isImeiMatch = (cleanDigits.length >= 8 && (s1Digits == cleanDigits || s2Digits == cleanDigits)) ||
                s1Lower == codeLower || s1Lower == cleanCodeLower ||
                s2Lower == codeLower || s2Lower == cleanCodeLower;

            final isSerialMatch = (sSerialLower != null && (sSerialLower == codeLower || sSerialLower == cleanCodeLower)) ||
                (sSerialDigits.isNotEmpty && cleanDigits.isNotEmpty && sSerialDigits == cleanDigits) ||
                (sSerialLower != null && cleanCodeLower.length >= 5 && (sSerialLower.contains(cleanCodeLower) || cleanCodeLower.contains(sSerialLower)));

            if (isImeiMatch || isSerialMatch) {
              matchedItem = item;
              matchedImei1 = s.imei1;
              matchedImei2 = s.imei2;
              matchedSerial = s.serialNumber;
              break;
            }
          }
          if (matchedItem != null) break;
        }

        // If not matched directly on serials, match on SKU or exact barcode
        matchedItem ??= invRes.data!.items.firstWhere(
          (i) => i.sku?.toLowerCase() == codeLower || i.sku?.toLowerCase() == cleanCodeLower,
          orElse: () => invRes.data!.items.first,
        );

        if (matchedItem.currentStock <= 0) {
          if (mounted) {
            AppFeedback.showError(
              context,
              title: 'Out of Stock',
              message: '${matchedItem.name} has 0 units in stock. Cannot sell without available stock.',
            );
          }
          return;
        }

        if (matchedImei1 == null && ScannedBoxResult.isValidImei(cleanCode.isNotEmpty ? cleanCode : code)) {
          matchedImei1 = cleanCode.isNotEmpty ? cleanCode : code;
        } else if (matchedSerial == null && !ScannedBoxResult.isValidImei(code)) {
          matchedSerial = cleanCode.isNotEmpty ? cleanCode : code;
        }

        // Check if this item is already in invoice
        final existingIndex = _items.indexWhere((si) {
          if (si.inventoryItemId != null && si.inventoryItemId == matchedItem!.id) return true;
          final s1 = si.imei1?.trim().toLowerCase();
          final s2 = si.imei2?.trim().toLowerCase();
          final sn = si.serialNumber?.trim().toLowerCase();
          if (matchedImei1 != null && (s1 == matchedImei1.toLowerCase() || s2 == matchedImei1.toLowerCase())) return true;
          if (matchedSerial != null && sn == matchedSerial.toLowerCase()) return true;
          return false;
        });

        if (existingIndex != -1) {
          final existingItem = _items[existingIndex];
          final currentInCart = existingItem.quantity;
          final availableStock = matchedItem.currentStock;

          if (matchedItem.itemType == 'mobile' || currentInCart >= availableStock) {
            if (mounted) {
              final reason = matchedItem.itemType == 'mobile'
                  ? 'Mobile phones are unique devices with separate IMEIs. Only $availableStock unit(s) in stock.'
                  : 'Available stock is only $availableStock unit(s). Already added $currentInCart to invoice.';
              AppFeedback.showError(
                context,
                title: 'Stock Limit Reached',
                message: '${matchedItem.name} cannot be added again. $reason',
              );
            }
            return;
          }

          if (mounted) {
            setState(() {
              _items[existingIndex] = existingItem.copyWith(
                quantity: currentInCart + 1,
              );
              _paymentAmountController.text = _grandTotal.toStringAsFixed(2);
            });
            AppFeedback.showSuccess(
              context,
              title: '✓ Quantity Updated',
              message: '${matchedItem.name} quantity increased to ${currentInCart + 1} ($availableStock available).',
            );
          }
          return;
        }

        final saleItem = SaleItem(
          inventoryItemId: matchedItem.id,
          productName: matchedItem.name,
          itemType: matchedItem.itemType,
          brand: matchedItem.brand,
          model: matchedItem.model,
          imei1: matchedImei1,
          imei2: matchedImei2,
          serialNumber: matchedSerial,
          quantity: 1,
          unitPrice: matchedItem.sellingPrice,
          costPrice: matchedItem.purchasePrice > 0 ? matchedItem.purchasePrice : null,
        );

        if (mounted) {
          setState(() {
            _items.add(saleItem);
            _paymentAmountController.text = _grandTotal.toStringAsFixed(2);
          });
          final idLabel = matchedImei1 != null ? " (IMEI: $matchedImei1)" : (matchedSerial != null ? " (S/N: $matchedSerial)" : "");
          AppFeedback.showSuccess(
            context,
            title: '✓ Item Added to Sale',
            message: '${matchedItem.name}$idLabel added to invoice.',
          );
        }
        return;
      }

      // 2. Second check Used Mobiles (Second Hand / Showroom phones)
      final usedRepo = UsedMobileRepository();
      final usedRes = await usedRepo.getUsedMobiles(search: searchKey);

      if (usedRes.mobiles.isNotEmpty) {
        UsedMobile? matchedUsed;
        for (final m in usedRes.mobiles) {
          final m1 = m.imei1.replaceAll(RegExp(r'\D'), '');
          final m2 = m.imei2?.replaceAll(RegExp(r'\D'), '') ?? '';
          final m1Lower = m.imei1.trim().toLowerCase();
          final m2Lower = m.imei2?.trim().toLowerCase();
          final mSerialLower = m.serialNumber?.trim().toLowerCase();
          final mSerialDigits = m.serialNumber?.replaceAll(RegExp(r'\D'), '') ?? '';

          final isImeiMatch = (cleanDigits.length >= 8 && (m1 == cleanDigits || m2 == cleanDigits)) ||
              m1Lower == codeLower || m1Lower == cleanCodeLower ||
              m2Lower == codeLower || m2Lower == cleanCodeLower;

          final isSerialMatch = (mSerialLower != null && (mSerialLower == codeLower || mSerialLower == cleanCodeLower)) ||
              (mSerialDigits.isNotEmpty && cleanDigits.isNotEmpty && mSerialDigits == cleanDigits) ||
              (mSerialLower != null && cleanCodeLower.length >= 5 && (mSerialLower.contains(cleanCodeLower) || cleanCodeLower.contains(mSerialLower)));

          if (isImeiMatch || isSerialMatch) {
            matchedUsed = m;
            break;
          }
        }
        matchedUsed ??= usedRes.mobiles.first;

        // Check if this used mobile is already added
        final alreadyAddedUsed = _items.any((si) {
          final s1 = si.imei1?.trim().toLowerCase();
          final s2 = si.imei2?.trim().toLowerCase();
          final sn = si.serialNumber?.trim().toLowerCase();
          final m1 = matchedUsed!.imei1.trim().toLowerCase();
          final m2 = matchedUsed.imei2?.trim().toLowerCase();
          final mSn = matchedUsed.serialNumber?.trim().toLowerCase();
          return (m1.isNotEmpty && (s1 == m1 || s2 == m1)) ||
              (m2 != null && m2.isNotEmpty && (s1 == m2 || s2 == m2)) ||
              (mSn != null && mSn.isNotEmpty && sn == mSn) ||
              si.productName == matchedUsed.deviceDisplayName;
        });

        if (alreadyAddedUsed) {
          if (mounted) {
            AppFeedback.showError(
              context,
              title: 'Mobile Already Added',
              message: '${matchedUsed.deviceDisplayName} is already in the sale invoice. Used phones only have 1 unit in stock.',
            );
          }
          return;
        }

        if (matchedUsed.isSold) {
          if (mounted) {
            final idInfo = matchedUsed.serialNumber != null && matchedUsed.serialNumber!.isNotEmpty
                ? 'S/N: ${matchedUsed.serialNumber}'
                : 'IMEI: ${matchedUsed.imei1.isNotEmpty ? matchedUsed.imei1 : code}';
            AppFeedback.showError(
              context,
              title: 'Mobile Already Sold',
              message: '${matchedUsed.deviceDisplayName} ($idInfo) was already sold previously.',
            );
          }
          return;
        }

        final unitPrice = (matchedUsed.sellingPrice != null && matchedUsed.sellingPrice! > 0)
            ? matchedUsed.sellingPrice!
            : matchedUsed.totalCost;

        final isImei = ScannedBoxResult.isValidImei(code) || ScannedBoxResult.isValidImei(cleanCode);
        final saleItem = SaleItem(
          productName: matchedUsed.deviceDisplayName,
          itemType: 'mobile',
          brand: matchedUsed.brand,
          model: matchedUsed.model,
          imei1: matchedUsed.imei1.isNotEmpty ? matchedUsed.imei1 : (isImei ? (cleanCode.isNotEmpty ? cleanCode : code) : null),
          imei2: matchedUsed.imei2,
          serialNumber: (matchedUsed.serialNumber != null && matchedUsed.serialNumber!.isNotEmpty)
              ? matchedUsed.serialNumber
              : (!isImei ? (cleanCode.isNotEmpty ? cleanCode : code) : null),
          quantity: 1,
          unitPrice: unitPrice > 0 ? unitPrice : 0.0,
          costPrice: matchedUsed.totalCost > 0 ? matchedUsed.totalCost : null,
        );

        if (mounted) {
          setState(() {
            _items.add(saleItem);
          });
          final idLabel = (matchedUsed.serialNumber != null && matchedUsed.serialNumber!.isNotEmpty)
              ? 'S/N: ${matchedUsed.serialNumber}'
              : 'IMEI: ${matchedUsed.imei1.isNotEmpty ? matchedUsed.imei1 : code}';
          AppFeedback.showSuccess(
            context,
            title: '✓ Used Mobile Added to Sale',
            message: '${matchedUsed.deviceDisplayName} ($idLabel) added to invoice.',
          );
        }
        return;
      }

      // 3. Not found in either
      if (mounted) {
        AppFeedback.showError(
          context,
          title: 'No Matching Item',
          message: 'No product or phone matched "$code". Tap "Add Item" to add manually or create a new inventory item.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, error: 'Scan lookup failed: $e');
      }
    } finally {
      _isProcessingScan = false;
    }
  }

  void _addItemDialog() {
    String saleMode = 'inventory'; // 'inventory' or 'quick'
    String itemType = 'accessory';

    // Quick/Custom Item controllers
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
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
    String? sheetError;

    Future<void> fetchInventory(StateSetter setSheetState, {String? query}) async {
      setSheetState(() {
        isLoadingInv = true;
        invError = null;
      });
      try {
        final res = await invRepository.getInventory(search: query);
        if (res.success && res.data != null) {
          final items = List<InventoryItem>.from(res.data!.items);
          // Sort: In-stock items (stock > 0) FIRST, Out-of-Stock (stock <= 0) at the LAST!
          items.sort((a, b) {
            final aIn = a.currentStock > 0 ? 1 : 0;
            final bIn = b.currentStock > 0 ? 1 : 0;
            if (aIn != bIn) return bIn.compareTo(aIn);
            return b.currentStock.compareTo(a.currentStock);
          });
          setSheetState(() {
            invItems = items;
            isLoadingInv = false;
          });
        } else {
          setSheetState(() {
            invError = res.message;
            isLoadingInv = false;
          });
        }
      } catch (e) {
        setSheetState(() {
          invError = e.toString();
          isLoadingInv = false;
        });
      }
    }

    bool initialFetchDone = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void showSheetError(String msg) {
              setSheetState(() => sheetError = msg);
              showDialog(
                context: ctx,
                builder: (dCtx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  title: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Item Limit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  content: Text(msg, style: const TextStyle(fontSize: 14)),
                  actions: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(dCtx),
                      child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }

            if (saleMode == 'inventory' && !initialFetchDone) {
              initialFetchDone = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                fetchInventory(setSheetState);
              });
            }

            final isDark = Theme.of(context).brightness == Brightness.dark;
            final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
            final textColor = isDark ? Colors.white : AppColors.textPrimary;
            final subtextColor = isDark ? Colors.white70 : AppColors.textSecondary;
            final sheetHeight = MediaQuery.of(context).size.height * 0.88;

            return Container(
              height: sheetHeight,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Header Row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Add Sale Item',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // Tabs: From Inventory vs Custom Item
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setSheetState(() {
                                  saleMode = 'inventory';
                                  selectedInvItem = null;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: saleMode == 'inventory' ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.inventory_2_rounded, size: 16, color: saleMode == 'inventory' ? Colors.white : subtextColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        'From Inventory',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: saleMode == 'inventory' ? Colors.white : subtextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setSheetState(() {
                                  saleMode = 'quick';
                                  selectedInvItem = null;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: saleMode == 'quick' ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.flash_on_rounded, size: 16, color: saleMode == 'quick' ? Colors.white : subtextColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Custom Item',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: saleMode == 'quick' ? Colors.white : subtextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 12),

                  // MAIN CONTENT
                  Expanded(
                    child: saleMode == 'inventory'
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Full-width Search Field + Quick Add "+ New" button
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: searchCtrl,
                                        onChanged: (q) => fetchInventory(setSheetState, query: q.trim()),
                                        style: const TextStyle(fontSize: 13),
                                        decoration: InputDecoration(
                                          hintText: 'Search stock by name, brand, model...',
                                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                                          suffixIcon: searchCtrl.text.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                                  onPressed: () {
                                                    searchCtrl.clear();
                                                    fetchInventory(setSheetState);
                                                  },
                                                )
                                              : null,
                                          filled: true,
                                          fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () async {
                                        final scanned = await BarcodeScannerScreen.scan(
                                          context,
                                          title: 'Scan Item Barcode / IMEI',
                                        );
                                        if (scanned != null && scanned.trim().isNotEmpty) {
                                          searchCtrl.text = scanned.trim();
                                          fetchInventory(setSheetState, query: scanned.trim());
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.qr_code_scanner_rounded, size: 18, color: Color(0xFF10B981)),
                                            SizedBox(width: 2),
                                            Text('Scan', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () async {
                                        final newItem = await QuickAddInventoryModal.show(context);
                                        if (newItem != null) {
                                          await fetchInventory(setSheetState);
                                          setSheetState(() {
                                            selectedInvItem = newItem;
                                            nameCtrl.text = newItem.name;
                                            priceCtrl.text = newItem.sellingPrice.toStringAsFixed(2);
                                            qtyCtrl.text = '1';
                                          });
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                                            SizedBox(width: 2),
                                            Text('New', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 6),

                              // Inventory Items List
                              Expanded(
                                child: isLoadingInv
                                    ? const Center(child: CircularProgressIndicator())
                                    : invError != null
                                        ? Center(child: Text('Error: $invError', style: const TextStyle(color: AppColors.error)))
                                        : invItems.isEmpty
                                            ? Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey.shade400),
                                                    const SizedBox(height: 8),
                                                    const Text('No inventory items found', style: TextStyle(color: AppColors.textSecondary)),
                                                  ],
                                                ),
                                              )
                                            : ListView.builder(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                                itemCount: invItems.length,
                                                itemBuilder: (ctx, idx) {
                                                  final item = invItems[idx];
                                                  final isSelected = selectedInvItem?.id == item.id;
                                                  final isOutOfStock = item.currentStock <= 0;

                                                  return Card(
                                                    elevation: isSelected ? 2 : 0.5,
                                                    margin: const EdgeInsets.only(bottom: 8),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                      side: BorderSide(
                                                        color: isSelected
                                                            ? AppColors.primary
                                                            : (isOutOfStock ? Colors.red.shade100 : Colors.grey.shade200),
                                                        width: isSelected ? 2 : 1,
                                                      ),
                                                    ),
                                                    color: isSelected
                                                        ? AppColors.primary.withOpacity(0.06)
                                                        : (isOutOfStock
                                                            ? (isDark ? const Color(0xFF2D1F1F) : const Color(0xFFFFF5F5))
                                                            : (isDark ? const Color(0xFF1E293B) : Colors.white)),
                                                    child: InkWell(
                                                      borderRadius: BorderRadius.circular(12),
                                                      onTap: () {
                                                        if (isOutOfStock) {
                                                          AppFeedback.showError(context, error: 'Item "${item.name}" is out of stock!');
                                                          return;
                                                        }
                                                        setSheetState(() {
                                                          selectedInvItem = item;
                                                          nameCtrl.text = item.name;
                                                          priceCtrl.text = item.sellingPrice.toStringAsFixed(2);
                                                          qtyCtrl.text = '1';
                                                        });
                                                      },
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(12),
                                                        child: Row(
                                                          children: [
                                                            // Leading Icon
                                                            Container(
                                                              width: 40,
                                                              height: 40,
                                                              decoration: BoxDecoration(
                                                                color: isOutOfStock
                                                                    ? Colors.red.shade100
                                                                    : (isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.1)),
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Icon(
                                                                isOutOfStock
                                                                    ? Icons.highlight_off_rounded
                                                                    : (isSelected ? Icons.check_rounded : Icons.inventory_2_rounded),
                                                                color: isOutOfStock ? Colors.red.shade700 : (isSelected ? Colors.white : AppColors.primary),
                                                                size: 20,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 12),
                                                            // Name & Stock Info
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text(
                                                                    item.name,
                                                                    style: TextStyle(
                                                                      fontWeight: FontWeight.bold,
                                                                      fontSize: 14,
                                                                      color: isOutOfStock ? Colors.grey.shade600 : textColor,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 4),
                                                                  Row(
                                                                    children: [
                                                                      if (isOutOfStock)
                                                                        Container(
                                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                                          decoration: BoxDecoration(
                                                                            color: Colors.red.shade50,
                                                                            borderRadius: BorderRadius.circular(4),
                                                                            border: Border.all(color: Colors.red.shade200),
                                                                          ),
                                                                          child: Text(
                                                                            'Out of Stock (0)',
                                                                            style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 10.5),
                                                                          ),
                                                                        )
                                                                      else
                                                                        Container(
                                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                                          decoration: BoxDecoration(
                                                                            color: Colors.green.shade50,
                                                                            borderRadius: BorderRadius.circular(4),
                                                                            border: Border.all(color: Colors.green.shade200),
                                                                          ),
                                                                          child: Text(
                                                                            'Stock: ${item.currentStock}',
                                                                            style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 10.5),
                                                                          ),
                                                                        ),
                                                                      const SizedBox(width: 8),
                                                                      Text(
                                                                        'Cost: ₹${item.purchasePrice.toStringAsFixed(0)}',
                                                                        style: TextStyle(fontSize: 11, color: subtextColor),
                                                                      ),
                                                                      if (item.brand != null && item.brand!.isNotEmpty) ...[
                                                                        const SizedBox(width: 6),
                                                                        Flexible(
                                                                          child: Text(
                                                                            '• ${item.brand}',
                                                                            style: TextStyle(fontSize: 11, color: subtextColor),
                                                                            overflow: TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            // Selling Price
                                                            Column(
                                                              crossAxisAlignment: CrossAxisAlignment.end,
                                                              children: [
                                                                Text(
                                                                  '₹${item.sellingPrice.toStringAsFixed(2)}',
                                                                  style: TextStyle(
                                                                    fontWeight: FontWeight.w900,
                                                                    fontSize: 15,
                                                                    color: isOutOfStock ? Colors.grey : const Color(0xFF047857),
                                                                  ),
                                                                ),
                                                                if (isSelected)
                                                                  const Text(
                                                                    'Selected',
                                                                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10),
                                                                  ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Item Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildTypeOption(
                                      label: 'Accessory',
                                      icon: Icons.headset_mic_rounded,
                                      isSelected: itemType == 'accessory',
                                      onTap: () => setSheetState(() => itemType = 'accessory'),
                                    ),
                                    const SizedBox(width: 6),
                                    _buildTypeOption(
                                      label: 'Mobile',
                                      icon: Icons.smartphone_rounded,
                                      isSelected: itemType == 'mobile',
                                      onTap: () {
                                        setSheetState(() {
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
                                      onTap: () => setSheetState(() => itemType = 'product'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (itemType == 'mobile') ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomTextField(
                                          label: 'Brand',
                                          hint: 'e.g. Apple',
                                          controller: brandCtrl,
                                          onChanged: (v) {
                                            nameCtrl.text = '$v ${modelCtrl.text}'.trim();
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: CustomTextField(
                                          label: 'Model',
                                          hint: 'e.g. iPhone 13',
                                          controller: modelCtrl,
                                          onChanged: (v) {
                                            nameCtrl.text = '${brandCtrl.text} $v'.trim();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                CustomTextField(
                                  label: 'Item Name / Description *',
                                  hint: 'e.g. Back Cover, Screen Guard, Service',
                                  controller: nameCtrl,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        label: 'Selling Price (₹) *',
                                        hint: '0.00',
                                        controller: priceCtrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: CustomTextField(
                                        label: 'Quantity *',
                                        hint: '1',
                                        controller: qtyCtrl,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                CustomTextField(
                                  label: 'Item Discount (₹)',
                                  hint: '0',
                                  controller: discountCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ],
                            ),
                          ),
                  ),

                  // PINNED BOTTOM ACTION PANEL
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (saleMode == 'inventory' && selectedInvItem != null) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Selected: ${selectedInvItem!.name}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'Available: ${selectedInvItem!.currentStock}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: SizedBox(
                                  height: 42,
                                  child: TextField(
                                    controller: priceCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      labelText: 'Selling Price (₹)',
                                      labelStyle: const TextStyle(fontSize: 11),
                                      prefixText: '₹ ',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onChanged: (_) => setSheetState(() {}),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Quantity Stepper
                              Row(
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.primary),
                                    onPressed: () {
                                      final q = int.tryParse(qtyCtrl.text.trim()) ?? 1;
                                      if (q > 1) {
                                        setSheetState(() => qtyCtrl.text = (q - 1).toString());
                                      }
                                    },
                                  ),
                                  SizedBox(
                                    width: 32,
                                    child: Text(
                                      qtyCtrl.text.isEmpty ? '1' : qtyCtrl.text,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                                    onPressed: () {
                                      final q = int.tryParse(qtyCtrl.text.trim()) ?? 1;
                                      if (q < selectedInvItem!.currentStock) {
                                        setSheetState(() => qtyCtrl.text = (q + 1).toString());
                                      } else {
                                        AppFeedback.showError(context, error: 'Maximum available stock is ${selectedInvItem!.currentStock}');
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 42,
                                  child: TextField(
                                    controller: discountCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(fontSize: 13),
                                    decoration: InputDecoration(
                                      labelText: 'Disc (₹)',
                                      labelStyle: const TextStyle(fontSize: 11),
                                      prefixText: '₹ ',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onChanged: (_) => setSheetState(() {}),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],

                        if (sheetError != null) ...[
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade400, width: 1.2),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    sheetError!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => setSheetState(() => sheetError = null),
                                  child: const Icon(Icons.close_rounded, color: Colors.red, size: 16),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Main Action Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (saleMode == 'inventory' && selectedInvItem == null)
                                ? Colors.grey.shade400
                                : AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: (saleMode == 'inventory' && selectedInvItem == null) ? 0 : 2,
                          ),
                          onPressed: () {
                            if (saleMode == 'inventory' && selectedInvItem == null) {
                              showSheetError('Please tap an in-stock item from the list above first.');
                              return;
                            }

                            final name = saleMode == 'inventory'
                                ? (nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : selectedInvItem!.name)
                                : nameCtrl.text.trim();
                            final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                            final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
                            final disc = double.tryParse(discountCtrl.text.trim()) ?? 0.0;

                            if (name.isEmpty) {
                              showSheetError('Please enter item name.');
                              return;
                            }
                            if (price <= 0) {
                              showSheetError('Please enter a valid selling price.');
                              return;
                            }
                            if (qty <= 0) {
                              showSheetError('Quantity must be at least 1.');
                              return;
                            }
                            if (saleMode == 'inventory' && selectedInvItem != null) {
                              final existingIndex = _items.indexWhere((si) => si.inventoryItemId != null && si.inventoryItemId == selectedInvItem!.id);
                              final currentInCart = existingIndex != -1 ? _items[existingIndex].quantity : 0;
                              final availableStock = selectedInvItem!.currentStock;

                              if (currentInCart + qty > availableStock) {
                                final remaining = availableStock - currentInCart;
                                if (remaining <= 0) {
                                  showSheetError('${selectedInvItem!.name} is already in the invoice ($currentInCart in sale). Maximum stock is $availableStock.');
                                } else {
                                  showSheetError('Cannot add $qty more. Only $remaining unit(s) remaining in stock ($currentInCart already in sale).');
                                }
                                return;
                              }

                              if (selectedInvItem!.itemType == 'mobile' && existingIndex != -1) {
                                showSheetError('This mobile phone is already added to invoice. Only $availableStock unit in stock.');
                                return;
                              }

                              if (existingIndex != -1) {
                                setState(() {
                                  _items[existingIndex] = _items[existingIndex].copyWith(
                                    quantity: currentInCart + qty,
                                    unitPrice: price,
                                    discount: disc,
                                  );
                                  _paymentAmountController.text = _grandTotal.toStringAsFixed(2);
                                });
                                Navigator.pop(ctx);
                                AppFeedback.showSuccess(
                                  context,
                                  title: '✓ Quantity Updated',
                                  message: '${selectedInvItem!.name} quantity updated to ${currentInCart + qty}.',
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
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                          label: Text(
                            saleMode == 'inventory' ? 'Add to Sale' : 'Add Custom Item',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ],
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

  Future<void> _submitSale() async {
    if (_items.isEmpty) {
      _showFormError('Please add at least one sale item.');
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
          final createdSale = response.data!;
          if (_addWarrantyOnCreate) {
            try {
              final startDateStr = DateTime.now().toIso8601String().split('T')[0];
              await _warrantyRepository.createWarranty(
                customerId: _selectedCustomer?.id,
                deviceId: _selectedDevice?.id,
                warrantyType: 'sale',
                durationDays: _selectedWarrantyDays,
                saleId: createdSale.id,
                warrantyStartDate: startDateStr,
                warrantyTerms: _warrantyTermsController.text.trim(),
              );
            } catch (_) {}
          }
          if (mounted) {
            AppFeedback.showSuccess(
              context,
              title: 'Invoice Created',
              message: 'Invoice ${response.data!.invoiceNumber} generated successfully!',
            );
            Navigator.pop(context, true);
          }
        } else {
          _showFormError(AppErrorMapper.mapMessage(response.message));
        }
      }
    } catch (e) {
      if (mounted) {
        _showFormError(AppErrorMapper.mapMessage(e.toString()));
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
        controller: _scrollController,
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
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
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
                    InkWell(
                      onTap: _showCustomerSearchBottomSheet,
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Customer (Optional / Walk-in)',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.person_rounded, color: AppColors.primary),
                          suffixIcon: const Icon(Icons.search_rounded, size: 22, color: AppColors.primary),
                        ),
                        child: Text(
                          _selectedCustomer != null
                              ? '${_selectedCustomer!.name} (${_selectedCustomer!.mobile})'
                              : (_isLoadingCustomers ? 'Loading customers...' : 'Tap to search & select customer (${_customerList.length} registered)'),
                          style: TextStyle(
                            color: _selectedCustomer == null ? AppColors.textMuted : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: _selectedCustomer != null ? FontWeight.w600 : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (_selectedCustomer != null) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _showDeviceSearchBottomSheet,
                        borderRadius: BorderRadius.circular(10),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Customer Device (Optional)',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.primary),
                            suffixIcon: const Icon(Icons.search_rounded, size: 22, color: AppColors.primary),
                          ),
                          child: Text(
                            _selectedDevice != null
                                ? '${_selectedDevice!.brand} ${_selectedDevice!.model}${_selectedDevice!.imei1 != null ? ' (IMEI: ${_selectedDevice!.imei1})' : ''}'
                                : (_isLoadingDevices ? 'Loading devices...' : 'Tap to search & select device (${_deviceList.length} available)'),
                            style: TextStyle(
                              color: _selectedDevice == null ? AppColors.textMuted : AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: _selectedDevice != null ? FontWeight.w600 : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Sale Items Section
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  const Text('Sale Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _scanToSell,
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 15, color: Colors.white),
                        label: const Text('⚡ Scan to Sell', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addItemDialog,
                        icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                        label: const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_items.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white12
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 36, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        const Text('No items added to invoice yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        const Text(
                          'Scan barcode/IMEI with camera or choose product from inventory',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _scanToSell,
                              icon: const Icon(Icons.qr_code_scanner_rounded, size: 16, color: Colors.white),
                              label: const Text('⚡ Scan to Sell', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _addItemDialog,
                              icon: const Icon(Icons.add_shopping_cart_rounded, size: 16, color: AppColors.primary),
                              label: const Text('Choose Item', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
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
                                mainAxisSize: MainAxisSize.min,
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
                              mainAxisSize: MainAxisSize.min,
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
                          mainAxisSize: MainAxisSize.min,
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
                    InkWell(
                      onTap: () async {
                        final methodMap = {
                          'Cash': 'cash',
                          'UPI / PhonePe / GPay': 'upi',
                          'Credit / Debit Card': 'card',
                          'Bank Transfer': 'bank_transfer',
                          'Other': 'other',
                        };
                        final currentLabel = methodMap.entries.firstWhere((e) => e.value == _paymentMethod, orElse: () => const MapEntry('Cash', 'cash')).key;

                        final selected = await AppSearchableBottomSheet.show(
                          context,
                          title: 'Select Payment Method',
                          options: ['Cash', 'UPI / PhonePe / GPay', 'Credit / Debit Card', 'Bank Transfer', 'Other'],
                          selectedValues: [currentLabel],
                          searchHint: 'Search payment method...',
                        );
                        if (selected != null && selected is String && methodMap.containsKey(selected)) {
                          setState(() => _paymentMethod = methodMap[selected]!);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.payments_rounded, color: AppColors.primary),
                          suffixIcon: const Icon(Icons.arrow_drop_down_rounded, size: 28, color: AppColors.primary),
                        ),
                        child: Text(
                          _paymentMethod == 'upi'
                              ? 'UPI / PhonePe / GPay'
                              : _paymentMethod == 'card'
                                  ? 'Credit / Debit Card'
                                  : _paymentMethod == 'bank_transfer'
                                      ? 'Bank Transfer'
                                      : _paymentMethod == 'other'
                                          ? 'Other'
                                          : 'Cash',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ),
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
              const SizedBox(height: 16),
              // Warranty Card
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
                        hint: 'e.g. Product & Parts Warranty',
                        controller: _warrantyTermsController,
                      ),
                    ],
                  ],
                ),
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
