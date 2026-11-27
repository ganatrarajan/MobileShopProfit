import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/gst_calculator.dart';
import '../../../core/services/profit_visibility_service.dart';
import '../../../core/widgets/barcode_scanner_screen.dart';
import '../../../core/widgets/app_searchable_bottom_sheet.dart';
import '../../device/data/device_repository.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/gst_input_card.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../inventory/models/inventory_item.dart';
import '../data/sale_repository.dart';
import '../models/sale.dart';

class EditSaleScreen extends StatefulWidget {
  final Sale sale;
  final String securityPin;

  const EditSaleScreen({
    super.key,
    required this.sale,
    required this.securityPin,
  });

  @override
  State<EditSaleScreen> createState() => _EditSaleScreenState();
}

class _EditSaleScreenState extends State<EditSaleScreen> {
  final SaleRepository _saleRepository = SaleRepository();
  final InventoryRepository _invRepository = InventoryRepository();

  late List<SaleItem> _items;
  late TextEditingController _notesController;
  late TextEditingController _discountController;
  late DateTime _saleDate;
  late TextEditingController _paidAmountController;
  late bool _syncPaidWithTotal;

  bool _gstEnabled = false;
  double _gstRate = 0.0;
  GstMode _gstMode = GstMode.exclusive;
  bool _isInterState = false;
  GstCalculationResult? _gstResult;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Copy items to avoid modifying parent reference prematurely
    _items = List<SaleItem>.from(widget.sale.items);
    _notesController = TextEditingController(text: widget.sale.notes ?? '');
    _discountController = TextEditingController(
      text: widget.sale.discount > 0 ? widget.sale.discount.toStringAsFixed(2) : '0',
    );

    // If sale was already fully paid, default to auto-syncing paid amount with grand total
    _syncPaidWithTotal = widget.sale.paymentStatus == 'paid';
    _paidAmountController = TextEditingController(
      text: _syncPaidWithTotal
          ? widget.sale.grandTotal.toStringAsFixed(2)
          : widget.sale.amountPaid.toStringAsFixed(2),
    );

    if (widget.sale.saleDate.isNotEmpty) {
      _saleDate = DateHelper.parseToLocal(widget.sale.saleDate) ?? DateTime.now();
    } else {
      _saleDate = DateTime.now();
    }

    _gstRate = widget.sale.taxRate;
    _gstEnabled = widget.sale.taxRate > 0 || widget.sale.taxAmount > 0;
    _gstMode = widget.sale.taxType == 'inclusive' ? GstMode.inclusive : GstMode.exclusive;
    _isInterState = widget.sale.isInterState;

    _recalculateGst();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _discountController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  void _recalculateGst() {
    if (_gstEnabled && _gstRate > 0) {
      _gstResult = GstCalculator.calculate(
        amount: max(0.0, _subtotal - _totalDiscount).toDouble(),
        rate: _gstRate,
        mode: _gstMode,
        isInterState: _isInterState,
        isEnabled: true,
      );
    } else {
      _gstResult = null;
    }
  }

  void _onPriceOrItemsChanged() {
    _recalculateGst();
    if (_syncPaidWithTotal) {
      _paidAmountController.text = _grandTotal.toStringAsFixed(2);
    } else {
      final currentPaid = double.tryParse(_paidAmountController.text.trim()) ?? 0.0;
      if (currentPaid > _grandTotal) {
        _paidAmountController.text = _grandTotal.toStringAsFixed(2);
      }
    }
  }

  double get _subtotal => _items.fold(0.0, (sum, i) => sum + (i.quantity * i.unitPrice));
  double get _itemsDiscount => _items.fold(0.0, (sum, i) => sum + i.discount);
  double get _saleDiscount => double.tryParse(_discountController.text.trim()) ?? 0.0;
  double get _totalDiscount => _itemsDiscount + _saleDiscount;
  double get _taxAmount => _gstResult?.taxAmount ?? 0.0;

  double get _grandTotal {
    final base = max(0.0, _subtotal - _totalDiscount).toDouble();
    if (!_gstEnabled || _gstRate <= 0) return base;
    return _gstMode == GstMode.inclusive ? base : (base + _taxAmount);
  }

  double get _effectivePaid {
    final val = double.tryParse(_paidAmountController.text.trim()) ?? 0.0;
    return min(val, _grandTotal);
  }
  double get _amountDue => max(0.0, _grandTotal - _effectivePaid);

  Future<void> _selectSaleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _saleDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _saleDate = picked);
    }
  }

  void _editItemDialog(int index) {
    final item = _items[index];
    final priceCtrl = TextEditingController(text: item.unitPrice.toStringAsFixed(2));
    final costPriceCtrl = TextEditingController(
      text: item.costPrice != null && item.costPrice! > 0 ? item.costPrice!.toStringAsFixed(2) : '',
    );
    final qtyCtrl = TextEditingController(text: item.quantity.toString());
    final discCtrl = TextEditingController(text: item.discount.toStringAsFixed(2));
    final brandCtrl = TextEditingController(text: item.brand ?? '');
    final modelCtrl = TextEditingController(text: item.model ?? '');
    final imei1Ctrl = TextEditingController(text: item.imei1 ?? '');
    final imei2Ctrl = TextEditingController(text: item.imei2 ?? '');
    final nameCtrl = TextEditingController(text: item.productName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Item #${index + 1}',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Item Name *',
                      hint: 'Product / Description',
                      controller: nameCtrl,
                    ),
                    const SizedBox(height: 12),
                    if (item.itemType == 'mobile') ...[
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Brand',
                              hint: 'Select or type brand',
                              controller: brandCtrl,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 20, color: AppColors.primary),
                                tooltip: 'Select Mobile Brand',
                                onPressed: () async {
                                  final brandOptions = [
                                    'Apple', 'Samsung', 'Vivo', 'Oppo', 'Realme', 'Xiaomi', 'OnePlus',
                                    'Motorola', 'Google', 'Poco', 'IQOO', 'Nothing', 'Infinix', 'Tecno', 'Lava', 'Nokia', 'Honor', 'Sony',
                                  ];
                                  try {
                                    final apiBrands = await DeviceRepository().getDeviceBrands();
                                    if (apiBrands.success && apiBrands.data != null) {
                                      for (final b in apiBrands.data!) {
                                        if (!brandOptions.contains(b)) brandOptions.add(b);
                                      }
                                    }
                                  } catch (_) {}

                                  if (!mounted) return;
                                  final selected = await AppSearchableBottomSheet.show(
                                    context,
                                    title: 'Select Mobile Brand',
                                    options: brandOptions,
                                    selectedValues: brandCtrl.text.isNotEmpty ? [brandCtrl.text] : [],
                                    searchHint: 'Search or add brand...',
                                    addCustomHint: '+ Add Custom Brand',
                                  );
                                  if (selected != null && selected is String && selected.isNotEmpty) {
                                    setSheetState(() {
                                      brandCtrl.text = selected;
                                      nameCtrl.text = '$selected ${modelCtrl.text}'.trim();
                                    });
                                  }
                                },
                              ),
                              onChanged: (v) {
                                nameCtrl.text = '$v ${modelCtrl.text}'.trim();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomTextField(
                              label: 'Model',
                              hint: 'Select or type model',
                              controller: modelCtrl,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 20, color: AppColors.primary),
                                tooltip: 'Select Model',
                                onPressed: () async {
                                  final brand = brandCtrl.text.trim();
                                  List<String> modelOptions = [];
                                  if (brand.isNotEmpty) {
                                    try {
                                      final apiModels = await DeviceRepository().getDeviceModels(brand);
                                      if (apiModels.success && apiModels.data != null) {
                                        modelOptions = apiModels.data!;
                                      }
                                    } catch (_) {}
                                  }

                                  if (!mounted) return;
                                  final selected = await AppSearchableBottomSheet.show(
                                    context,
                                    title: brand.isNotEmpty ? 'Select $brand Model' : 'Select Mobile Model',
                                    options: modelOptions.isNotEmpty ? modelOptions : ['Standard Model'],
                                    selectedValues: modelCtrl.text.isNotEmpty ? [modelCtrl.text] : [],
                                    searchHint: 'Search or add model...',
                                    addCustomHint: '+ Add Custom Model',
                                  );
                                  if (selected != null && selected is String && selected.isNotEmpty) {
                                    setSheetState(() {
                                      modelCtrl.text = selected;
                                      nameCtrl.text = '${brandCtrl.text} $selected'.trim();
                                    });
                                  }
                                },
                              ),
                              onChanged: (v) {
                                nameCtrl.text = '${brandCtrl.text} $v'.trim();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'IMEI 1 (Optional)',
                              hint: '15-digit IMEI 1 (optional)',
                              controller: imei1Ctrl,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppColors.primary),
                                tooltip: 'Scan IMEI 1',
                                onPressed: () async {
                                  final scanned = await BarcodeScannerScreen.scan(
                                    context,
                                    title: 'Scan IMEI 1',
                                  );
                                  if (scanned != null && scanned.trim().isNotEmpty) {
                                    final clean = scanned.replaceFirst(RegExp(r'^(imei1|imei|sn|s/n)[:\s-]+', caseSensitive: false), '').trim();
                                    setSheetState(() => imei1Ctrl.text = clean);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomTextField(
                              label: 'IMEI 2 (Optional)',
                              hint: '15-digit IMEI 2 (optional)',
                              controller: imei2Ctrl,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppColors.primary),
                                tooltip: 'Scan IMEI 2',
                                onPressed: () async {
                                  final scanned = await BarcodeScannerScreen.scan(
                                    context,
                                    title: 'Scan IMEI 2',
                                  );
                                  if (scanned != null && scanned.trim().isNotEmpty) {
                                    final clean = scanned.replaceFirst(RegExp(r'^(imei2|imei|sn|s/n)[:\s-]+', caseSensitive: false), '').trim();
                                    setSheetState(() => imei2Ctrl.text = clean);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
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
                            label: 'Purchase Cost (₹)',
                            hint: '0.00',
                            controller: costPriceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Quantity *',
                            hint: '1',
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomTextField(
                            label: 'Discount (₹)',
                            hint: '0.00',
                            controller: discCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                        final cost = double.tryParse(costPriceCtrl.text.trim()) ?? 0.0;
                        final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
                        final disc = double.tryParse(discCtrl.text.trim()) ?? 0.0;
                        final name = nameCtrl.text.trim();

                        if (name.isEmpty) {
                          AppFeedback.showError(context, title: 'Invalid Name', message: 'Item name cannot be empty.');
                          return;
                        }
                        if (price < 0) {
                          AppFeedback.showError(context, title: 'Invalid Price', message: 'Selling price must be 0 or more.');
                          return;
                        }
                        if (qty <= 0) {
                          AppFeedback.showError(context, title: 'Invalid Quantity', message: 'Quantity must be at least 1.');
                          return;
                        }

                        setState(() {
                          _items[index] = item.copyWith(
                            productName: name,
                            unitPrice: price,
                            costPrice: cost > 0 ? cost : null,
                            quantity: qty,
                            discount: disc,
                            brand: brandCtrl.text.trim().isNotEmpty ? brandCtrl.text.trim() : item.brand,
                            model: modelCtrl.text.trim().isNotEmpty ? modelCtrl.text.trim() : item.model,
                            imei1: imei1Ctrl.text.trim().isNotEmpty ? imei1Ctrl.text.trim() : null,
                            imei2: imei2Ctrl.text.trim().isNotEmpty ? imei2Ctrl.text.trim() : null,
                          );
                          _onPriceOrItemsChanged();
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Update Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _addItemDialog() {
    String saleMode = 'inventory'; // 'inventory' or 'quick'
    String itemType = 'accessory';

    // Controllers
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final imei1Ctrl = TextEditingController();
    final imei2Ctrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final costPriceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final discountCtrl = TextEditingController(text: '0');

    final searchCtrl = TextEditingController();
    List<InventoryItem> invItems = [];
    InventoryItem? selectedInvItem;
    bool isLoadingInv = false;

    Future<void> fetchInventory(StateSetter setSheetState, {String? query}) async {
      setSheetState(() => isLoadingInv = true);
      try {
        final res = await _invRepository.getInventory(search: query);
        if (res.success && res.data != null) {
          final items = List<InventoryItem>.from(res.data!.items);
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
          setSheetState(() => isLoadingInv = false);
        }
      } catch (_) {
        setSheetState(() => isLoadingInv = false);
      }
    }

    bool initialFetchDone = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
            final subtextColor = isDark ? Colors.white70 : AppColors.textSecondary;
            final sheetHeight = MediaQuery.of(context).size.height * 0.88;

            if (saleMode == 'inventory' && !initialFetchDone) {
              initialFetchDone = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                fetchInventory(setSheetState);
              });
            }

            return Container(
              height: sheetHeight,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Item to Invoice',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
                              onTap: () => setSheetState(() {
                                saleMode = 'inventory';
                                selectedInvItem = null;
                              }),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: saleMode == 'inventory' ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'From Inventory',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: saleMode == 'inventory' ? Colors.white : subtextColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: InkWell(
                              onTap: () => setSheetState(() {
                                saleMode = 'quick';
                                selectedInvItem = null;
                              }),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: saleMode == 'quick' ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'Custom Item',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: saleMode == 'quick' ? Colors.white : subtextColor,
                                    ),
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
                  // Content
                  Expanded(
                    child: saleMode == 'inventory'
                        ? Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: TextField(
                                  controller: searchCtrl,
                                  onChanged: (q) => fetchInventory(setSheetState, query: q.trim()),
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Search inventory by name, brand, model...',
                                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: isLoadingInv
                                    ? const Center(child: CircularProgressIndicator())
                                    : invItems.isEmpty
                                        ? const Center(child: Text('No inventory items found.'))
                                        : ListView.separated(
                                            padding: const EdgeInsets.all(16),
                                            itemCount: invItems.length,
                                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                                            itemBuilder: (_, i) {
                                              final item = invItems[i];
                                              final isSelected = selectedInvItem?.id == item.id;
                                              return InkWell(
                                                onTap: () {
                                                  setSheetState(() {
                                                    selectedInvItem = item;
                                                    priceCtrl.text = item.sellingPrice.toStringAsFixed(2);
                                                    costPriceCtrl.text = item.purchasePrice.toStringAsFixed(2);
                                                    nameCtrl.text = item.name;
                                                  });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                                                    border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                            Text(
                                                              'Stock: ${item.currentStock}  |  ₹${item.sellingPrice.toStringAsFixed(2)}',
                                                              style: TextStyle(fontSize: 12, color: subtextColor),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      if (isSelected)
                                                        const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ChoiceChip(
                                      label: const Text('Accessory'),
                                      selected: itemType == 'accessory',
                                      onSelected: (val) => setSheetState(() => itemType = 'accessory'),
                                    ),
                                    const SizedBox(width: 8),
                                    ChoiceChip(
                                      label: const Text('Mobile'),
                                      selected: itemType == 'mobile',
                                      onSelected: (val) => setSheetState(() => itemType = 'mobile'),
                                    ),
                                    const SizedBox(width: 8),
                                    ChoiceChip(
                                      label: const Text('Product'),
                                      selected: itemType == 'product',
                                      onSelected: (val) => setSheetState(() => itemType = 'product'),
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
                                          hint: 'Select or type brand',
                                          controller: brandCtrl,
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 20, color: AppColors.primary),
                                            tooltip: 'Select Mobile Brand',
                                            onPressed: () async {
                                              final brandOptions = [
                                                'Apple', 'Samsung', 'Vivo', 'Oppo', 'Realme', 'Xiaomi', 'OnePlus',
                                                'Motorola', 'Google', 'Poco', 'IQOO', 'Nothing', 'Infinix', 'Tecno', 'Lava', 'Nokia', 'Honor', 'Sony',
                                              ];
                                              try {
                                                final apiBrands = await DeviceRepository().getDeviceBrands();
                                                if (apiBrands.success && apiBrands.data != null) {
                                                  for (final b in apiBrands.data!) {
                                                    if (!brandOptions.contains(b)) brandOptions.add(b);
                                                  }
                                                }
                                              } catch (_) {}

                                              if (!mounted) return;
                                              final selected = await AppSearchableBottomSheet.show(
                                                context,
                                                title: 'Select Mobile Brand',
                                                options: brandOptions,
                                                selectedValues: brandCtrl.text.isNotEmpty ? [brandCtrl.text] : [],
                                                searchHint: 'Search or add brand...',
                                                addCustomHint: '+ Add Custom Brand',
                                              );
                                              if (selected != null && selected is String && selected.isNotEmpty) {
                                                setSheetState(() {
                                                  brandCtrl.text = selected;
                                                  nameCtrl.text = '$selected ${modelCtrl.text}'.trim();
                                                });
                                              }
                                            },
                                          ),
                                          onChanged: (v) {
                                            nameCtrl.text = '$v ${modelCtrl.text}'.trim();
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: CustomTextField(
                                          label: 'Model',
                                          hint: 'Select or type model',
                                          controller: modelCtrl,
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 20, color: AppColors.primary),
                                            tooltip: 'Select Model',
                                            onPressed: () async {
                                              final brand = brandCtrl.text.trim();
                                              List<String> modelOptions = [];
                                              if (brand.isNotEmpty) {
                                                try {
                                                  final apiModels = await DeviceRepository().getDeviceModels(brand);
                                                  if (apiModels.success && apiModels.data != null) {
                                                    modelOptions = apiModels.data!;
                                                  }
                                                } catch (_) {}
                                              }

                                              if (!mounted) return;
                                              final selected = await AppSearchableBottomSheet.show(
                                                context,
                                                title: brand.isNotEmpty ? 'Select $brand Model' : 'Select Mobile Model',
                                                options: modelOptions.isNotEmpty ? modelOptions : ['Standard Model'],
                                                selectedValues: modelCtrl.text.isNotEmpty ? [modelCtrl.text] : [],
                                                searchHint: 'Search or add model...',
                                                addCustomHint: '+ Add Custom Model',
                                              );
                                              if (selected != null && selected is String && selected.isNotEmpty) {
                                                setSheetState(() {
                                                  modelCtrl.text = selected;
                                                  nameCtrl.text = '${brandCtrl.text} $selected'.trim();
                                                });
                                              }
                                            },
                                          ),
                                          onChanged: (v) {
                                            nameCtrl.text = '${brandCtrl.text} $v'.trim();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomTextField(
                                          label: 'IMEI 1 (Optional)',
                                          hint: '15-digit IMEI 1 (optional)',
                                          controller: imei1Ctrl,
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppColors.primary),
                                            tooltip: 'Scan IMEI 1',
                                            onPressed: () async {
                                              final scanned = await BarcodeScannerScreen.scan(
                                                context,
                                                title: 'Scan IMEI 1',
                                              );
                                              if (scanned != null && scanned.trim().isNotEmpty) {
                                                final clean = scanned.replaceFirst(RegExp(r'^(imei1|imei|sn|s/n)[:\s-]+', caseSensitive: false), '').trim();
                                                setSheetState(() => imei1Ctrl.text = clean);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: CustomTextField(
                                          label: 'IMEI 2 (Optional)',
                                          hint: '15-digit IMEI 2 (optional)',
                                          controller: imei2Ctrl,
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: AppColors.primary),
                                            tooltip: 'Scan IMEI 2',
                                            onPressed: () async {
                                              final scanned = await BarcodeScannerScreen.scan(
                                                context,
                                                title: 'Scan IMEI 2',
                                              );
                                              if (scanned != null && scanned.trim().isNotEmpty) {
                                                final clean = scanned.replaceFirst(RegExp(r'^(imei2|imei|sn|s/n)[:\s-]+', caseSensitive: false), '').trim();
                                                setSheetState(() => imei2Ctrl.text = clean);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                CustomTextField(
                                  label: 'Item Name *',
                                  hint: 'Description / Item Name',
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
                                        label: 'Purchase Cost (₹)',
                                        hint: '0.00',
                                        controller: costPriceCtrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        label: 'Quantity *',
                                        hint: '1',
                                        controller: qtyCtrl,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: CustomTextField(
                                        label: 'Discount (₹)',
                                        hint: '0.00',
                                        controller: discountCtrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                  ),
                  // Bottom pinned button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: sheetBg,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        final name = saleMode == 'inventory'
                            ? (selectedInvItem != null ? selectedInvItem!.name : nameCtrl.text.trim())
                            : nameCtrl.text.trim();
                        final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                        final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
                        final disc = double.tryParse(discountCtrl.text.trim()) ?? 0.0;
                        final cost = double.tryParse(costPriceCtrl.text.trim()) ?? 0.0;

                        if (name.isEmpty) {
                          AppFeedback.showError(context, title: 'Item Name Required', message: 'Please enter or select an item name.');
                          return;
                        }
                        if (price < 0) {
                          AppFeedback.showError(context, title: 'Invalid Price', message: 'Price cannot be negative.');
                          return;
                        }
                        if (qty <= 0) {
                          AppFeedback.showError(context, title: 'Invalid Quantity', message: 'Quantity must be at least 1.');
                          return;
                        }

                        final newItem = SaleItem(
                          inventoryItemId: saleMode == 'inventory' ? selectedInvItem?.id : null,
                          productName: name,
                          itemType: saleMode == 'inventory' ? (selectedInvItem?.itemType ?? 'product') : itemType,
                          brand: saleMode == 'inventory' ? selectedInvItem?.brand : (brandCtrl.text.trim().isNotEmpty ? brandCtrl.text.trim() : null),
                          model: saleMode == 'inventory' ? selectedInvItem?.model : (modelCtrl.text.trim().isNotEmpty ? modelCtrl.text.trim() : null),
                          imei1: saleMode == 'inventory' ? null : (imei1Ctrl.text.trim().isNotEmpty ? imei1Ctrl.text.trim() : null),
                          imei2: saleMode == 'inventory' ? null : (imei2Ctrl.text.trim().isNotEmpty ? imei2Ctrl.text.trim() : null),
                          quantity: qty,
                          unitPrice: price,
                          costPrice: saleMode == 'inventory' ? selectedInvItem?.purchasePrice : (cost > 0 ? cost : null),
                          discount: disc,
                        );

                        setState(() {
                          _items.add(newItem);
                          _onPriceOrItemsChanged();
                        });
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                      label: const Text('Add to Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  Future<void> _saveChanges() async {
    if (_items.isEmpty) {
      AppFeedback.showError(
        context,
        title: 'Items Required',
        message: 'An invoice must have at least one item. Please add an item before saving.',
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final saleDateStr = _saleDate.toIso8601String().split('T')[0];

      final res = await _saleRepository.updateSale(
        id: widget.sale.id,
        securityPin: widget.securityPin,
        saleDate: saleDateStr,
        discount: _saleDiscount,
        taxAmount: _taxAmount,
        taxRate: _gstEnabled ? _gstRate : 0.0,
        taxType: _gstMode == GstMode.inclusive ? 'inclusive' : 'exclusive',
        isInterState: _isInterState,
        cgstAmount: _gstResult?.cgstAmount ?? 0.0,
        sgstAmount: _gstResult?.sgstAmount ?? 0.0,
        igstAmount: _gstResult?.igstAmount ?? 0.0,
        notes: _notesController.text.trim(),
        items: _items,
        paidAmount: _effectivePaid,
      );

      if (!mounted) return;

      if (res.success && res.data != null) {
        AppFeedback.showSuccess(
          context,
          title: 'Invoice Updated',
          message: 'Invoice #${widget.sale.invoiceNumber} updated successfully.',
        );
        Navigator.pop(context, res.data!);
      } else {
        setState(() => _isSaving = false);
        AppFeedback.showError(
          context,
          title: 'Update Failed',
          message: res.message.isNotEmpty ? res.message : 'Failed to update sale invoice.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppFeedback.showError(
          context,
          title: 'Error',
          message: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerName = widget.sale.customerName ?? widget.sale.customer?.name ?? 'Walk-in Customer';
    final customerMobile = widget.sale.customerMobile ?? widget.sale.customer?.mobile ?? 'N/A';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Invoice #${widget.sale.invoiceNumber}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('Admin Protected Mode', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveChanges,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_rounded, color: Colors.white, size: 18),
            label: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. LOCKED CUSTOMER DETAILS CARD
            CustomCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.lock_rounded, size: 18, color: Colors.amber.shade900),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Customer Details',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_rounded, size: 12, color: Colors.amber.shade900),
                            const SizedBox(width: 4),
                            Text(
                              'Locked / Non-Editable',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Name', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mobile', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text(customerMobile, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.sale.device != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Linked Device: ${widget.sale.device!.brand} ${widget.sale.device!.model}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. INVOICE ITEMS CARD
            CustomCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Invoice Items (${_items.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: _addItemDialog,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No items in invoice. Tap "+ Add Item" above.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 12),
                      itemBuilder: (ctx, idx) {
                        final item = _items[idx];
                        final isMobile = item.itemType == 'mobile';

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isMobile ? Colors.blue.shade50 : AppColors.accentLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isMobile ? Icons.smartphone_rounded : Icons.inventory_2_rounded,
                                color: isMobile ? Colors.blue.shade700 : AppColors.accent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                  if (item.imei1 != null && item.imei1!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'IMEI 1: ${item.imei1}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                  if (item.imei2 != null && item.imei2!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'IMEI 2: ${item.imei2}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.quantity} x ₹${item.unitPrice.toStringAsFixed(2)}${item.discount > 0 ? " (-₹${item.discount.toStringAsFixed(2)})" : ""} = ₹${item.total.toStringAsFixed(2)}${item.costPrice != null && item.costPrice! > 0 ? "  •  Cost: ${ProfitVisibilityService().format(item.costPrice)}" : ""}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                  tooltip: 'Edit item',
                                  onPressed: () => _editItemDialog(idx),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                  tooltip: 'Remove item',
                                  onPressed: () {
                                    if (_items.length <= 1) {
                                      AppFeedback.showError(
                                        context,
                                        title: 'Cannot Remove',
                                        message: 'An invoice must have at least one item.',
                                      );
                                      return;
                                    }
                                    setState(() {
                                      _items.removeAt(idx);
                                      _onPriceOrItemsChanged();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. INVOICE DATE & NOTES
            CustomCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Invoice Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _selectSaleDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Sale Date', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(
                                '${_saleDate.day.toString().padLeft(2, '0')}-${_saleDate.month.toString().padLeft(2, '0')}-${_saleDate.year}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Notes',
                    hint: 'Additional invoice notes or warranty remarks',
                    controller: _notesController,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. DISCOUNT & GST
            CustomCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Discount & Taxes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Overall Invoice Discount (₹)',
                    hint: '0.00',
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) {
                      setState(() => _onPriceOrItemsChanged());
                    },
                  ),
                  const SizedBox(height: 12),
                  GstInputCard(
                    amount: max(0, _subtotal - _totalDiscount),
                    initialEnabled: _gstEnabled,
                    initialMode: _gstMode,
                    initialRate: _gstRate,
                    initialInterState: _isInterState,
                    title: 'Apply GST / Tax',
                    onChanged: (res) {
                      setState(() {
                        _gstEnabled = res.isEnabled;
                        _gstMode = res.mode;
                        _gstRate = res.rate;
                        _isInterState = res.isInterState;
                        _gstResult = res;
                        _onPriceOrItemsChanged();
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 5. SUMMARY & PAYMENT CARD
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Items Subtotal', style: TextStyle(color: AppColors.textSecondary)),
                      Text('₹ ${_subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (_totalDiscount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Discount', style: TextStyle(color: Colors.green)),
                        Text('- ₹ ${_totalDiscount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ],
                  if (_taxAmount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('GST (${_gstRate.toStringAsFixed(0)}%)', style: const TextStyle(color: AppColors.primary)),
                        Text('₹ ${_taxAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                  ],
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Revised Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        '₹ ${_grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Paid Amount & Auto-sync Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payment Sync',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Auto-sync with Total',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 4),
                          Switch.adaptive(
                            value: _syncPaidWithTotal,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() {
                                _syncPaidWithTotal = val;
                                if (_syncPaidWithTotal) {
                                  _paidAmountController.text = _grandTotal.toStringAsFixed(2);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!_syncPaidWithTotal) ...[
                    CustomTextField(
                      label: 'Customer Paid Amount (₹)',
                      hint: '0.00',
                      controller: _paidAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) {
                        final entered = double.tryParse(val.trim()) ?? 0.0;
                        if (entered > _grandTotal) {
                          _paidAmountController.text = _grandTotal.toStringAsFixed(2);
                        }
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          label: Text('Full Paid (₹${_grandTotal.toStringAsFixed(2)})', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            setState(() {
                              _paidAmountController.text = _grandTotal.toStringAsFixed(2);
                            });
                          },
                        ),
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.grey.shade100,
                          label: const Text('Unpaid (₹0.00)', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            setState(() {
                              _paidAmountController.text = '0.00';
                            });
                          },
                        ),
                        if (widget.sale.amountPaid > 0 && widget.sale.amountPaid <= _grandTotal)
                          ActionChip(
                            visualDensity: VisualDensity.compact,
                            backgroundColor: Colors.orange.shade50,
                            label: Text('Original (₹${widget.sale.amountPaid.toStringAsFixed(2)})', style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              setState(() {
                                _paidAmountController.text = widget.sale.amountPaid.toStringAsFixed(2);
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount Paid', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text('₹ ${_effectivePaid.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Balance Due', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        '₹ ${_amountDue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _amountDue > 0 ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 6. BOTTOM SAVE BUTTON
            CustomButton(
              text: 'Save Invoice Changes',
              icon: Icons.check_circle_outline_rounded,
              isLoading: _isSaving,
              onPressed: _saveChanges,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
