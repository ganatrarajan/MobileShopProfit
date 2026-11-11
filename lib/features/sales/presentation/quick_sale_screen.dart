import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/widgets/barcode_scanner_screen.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../inventory/models/inventory_item.dart';
import '../../used_mobile/data/used_mobile_repository.dart';
import '../../used_mobile/models/used_mobile.dart';
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
  void fetchInventoryItems() {} // Compatibility stub
  final SaleRepository _saleRepository = SaleRepository();
  final WarrantyRepository _warrantyRepository = WarrantyRepository();
  final InventoryRepository _inventoryRepository = InventoryRepository();

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerMobileController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0');

  // Warranty Card controls
  bool _addWarrantyOnCreate = false;
  int _selectedWarrantyDays = 180;
  final TextEditingController _warrantyTermsController = TextEditingController();

  // Multi-Item List for Quick Sale
  final List<SaleItem> _items = [];
  String _paymentMethod = 'cash';
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
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
    _customerNameController.dispose();
    _customerMobileController.dispose();
    _notesController.dispose();
    _discountController.dispose();
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

  double get _total {
    final t = _subtotal - _totalDiscount;
    return t < 0 ? 0.0 : t;
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
        message: 'A device with identifier $code is already added in this quick sale.',
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

      // 1. Inventory check
      final invRepo = InventoryRepository();
      final invRes = await invRepo.getInventory(search: searchKey);

      if (invRes.success && invRes.data != null && invRes.data!.items.isNotEmpty) {
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
                  : 'Available stock is only $availableStock unit(s). Already added $currentInCart to sale.';
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

      // 2. Used mobile check
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
              message: '${matchedUsed.deviceDisplayName} is already in the sale. Used phones only have 1 unit in stock.',
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

    // Quick/Custom Item controllers
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');

    // From Inventory state
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
        final res = await _inventoryRepository.getInventory(search: query);
        if (res.success && res.data != null) {
          final items = List<InventoryItem>.from(res.data!.items);
          // Sort: In-stock items (stock > 0) FIRST, Out-of-Stock (stock <= 0) at the LAST!
          items.sort((a, b) {
            final aIn = a.currentStock > 0 ? 1 : 0;
            final bIn = b.currentStock > 0 ? 1 : 0;
            if (aIn != bIn) {
              return bIn.compareTo(aIn); // in-stock first!
            }
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
                              'Add Quick Sale Item',
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
                              // Full-width Search Field + Scanner
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
                                                          showSheetError('Item "${item.name}" is out of stock (0 units). Cannot add to sale.');
                                                          return;
                                                        }
                                                        setSheetState(() {
                                                          selectedInvItem = item;
                                                          priceCtrl.text = item.sellingPrice.toStringAsFixed(2);
                                                          qtyCtrl.text = '1';
                                                          sheetError = null;
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
                                                                        'Cost: \u20B9${item.purchasePrice.toStringAsFixed(0)}',
                                                                        style: TextStyle(fontSize: 11, color: subtextColor),
                                                                      ),
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
                                                                  '\u20B9${item.sellingPrice.toStringAsFixed(2)}',
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
                                CustomTextField(
                                  label: 'Item Name *',
                                  hint: 'e.g. Back Cover, Screen Guard, Labour',
                                  controller: nameCtrl,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        label: 'Selling Price (\u20B9) *',
                                        hint: '0.00',
                                        controller: priceCtrl,
                                        keyboardType: TextInputType.number,
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
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      labelText: 'Selling Price (\u20B9)',
                                      labelStyle: const TextStyle(fontSize: 11),
                                      prefixText: '\u20B9 ',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onChanged: (_) => setSheetState(() {
                                      sheetError = null;
                                    }),
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
                                        setSheetState(() {
                                          qtyCtrl.text = (q - 1).toString();
                                          sheetError = null;
                                        });
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
                                        setSheetState(() {
                                          qtyCtrl.text = (q + 1).toString();
                                          sheetError = null;
                                        });
                                      } else {
                                        showSheetError('Maximum available stock is ${selectedInvItem!.currentStock}');
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Main Action Button
                        ElevatedButton(
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

                            final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                            final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;

                            if (qty <= 0) {
                              showSheetError('Quantity must be at least 1.');
                              return;
                            }

                            if (saleMode == 'inventory') {
                              final existingIndex = _items.indexWhere((si) => si.inventoryItemId != null && si.inventoryItemId == selectedInvItem!.id);
                              final currentInCart = existingIndex != -1 ? _items[existingIndex].quantity : 0;
                              final availableStock = selectedInvItem!.currentStock;

                              if (currentInCart + qty > availableStock) {
                                final remaining = availableStock - currentInCart;
                                if (remaining <= 0) {
                                  showSheetError('${selectedInvItem!.name} is already in the sale ($currentInCart in sale). Maximum stock is $availableStock.');
                                } else {
                                  showSheetError('Cannot add $qty more. Only $remaining unit(s) remaining in stock ($currentInCart already in sale).');
                                }
                                return;
                              }

                              if (selectedInvItem!.itemType == 'mobile' && existingIndex != -1) {
                                showSheetError('This mobile phone is already in the sale. Mobile devices have unique IMEIs and only 1 unit per item.');
                                return;
                              }

                              if (existingIndex != -1) {
                                setState(() {
                                  _items[existingIndex] = _items[existingIndex].copyWith(
                                    quantity: currentInCart + qty,
                                    unitPrice: price,
                                  );
                                });
                                Navigator.pop(ctx);
                                AppFeedback.showSuccess(
                                  context,
                                  title: '✓ Quantity Updated',
                                  message: '${selectedInvItem!.name} quantity updated to ${currentInCart + qty}.',
                                );
                                return;
                              }

                              setState(() {
                                _items.add(
                                  SaleItem(
                                    inventoryItemId: selectedInvItem!.id,
                                    productName: selectedInvItem!.name,
                                    itemType: selectedInvItem!.itemType,
                                    brand: selectedInvItem!.brand,
                                    model: selectedInvItem!.model,
                                    quantity: qty,
                                    unitPrice: price,
                                    costPrice: selectedInvItem!.purchasePrice,
                                    discount: 0.0,
                                  ),
                                );
                              });
                            } else {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) {
                                showSheetError('Please enter item name.');
                                return;
                              }
                              if (price < 0) {
                                showSheetError('Please enter a valid price.');
                                return;
                              }

                              setState(() {
                                _items.add(
                                  SaleItem(
                                    inventoryItemId: null,
                                    productName: name,
                                    itemType: 'accessory',
                                    quantity: qty,
                                    unitPrice: price,
                                    costPrice: 0.0,
                                    discount: 0.0,
                                  ),
                                );
                              });
                            }

                            Navigator.pop(ctx);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_shopping_cart_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                saleMode == 'inventory'
                                    ? (selectedInvItem != null
                                        ? 'Add to Sale \u2022 \u20B9${((double.tryParse(priceCtrl.text) ?? 0.0) * (int.tryParse(qtyCtrl.text) ?? 1)).toStringAsFixed(2)}'
                                        : 'Select an Item Above')
                                    : 'Add Custom Item to Sale',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
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

  Future<void> _submitQuickSale() async {
    if (_items.isEmpty) {
      _showFormError('Please add at least 1 item to complete Quick Sale.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final res = await _saleRepository.createSale(
        saleType: 'quick',
        customerId: null,
        customerName: _customerNameController.text.trim(),
        customerMobile: _customerMobileController.text.trim(),
        notes: _notesController.text.trim(),
        items: _items,
        discount: double.tryParse(_discountController.text.trim()) ?? 0.0,
        paymentAmount: _total,
        paymentMethod: _paymentMethod,
      );

      if (!mounted) return;

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
        if (!mounted) return;
        AppFeedback.showSuccess(
          context,
          title: '⚡ Quick Sale Completed',
          message: 'Invoice #${createdSale.invoiceNumber} completed successfully.',
        );
        if (mounted && ((createdSale.customerMobile != null && createdSale.customerMobile!.trim().isNotEmpty) || (createdSale.customer?.mobile != null && createdSale.customer!.mobile.trim().isNotEmpty))) {
          await WhatsAppHelper.showWhatsAppSalePromptDialog(context, createdSale);
        }
        if (!mounted) return;
        setState(() {
          _items.clear();
          _customerNameController.clear();
          _customerMobileController.clear();
          _notesController.clear();
          _discountController.text = '0';
          _isSubmitting = false;
        });

        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      } else {
        _showFormError(res.message);
        setState(() => _isSubmitting = false);
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
        title: const Text('⚡ Quick Sale', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                  ],
                ),
              ),

            // 1. Sale Items Section (Multi-Item Support)
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shopping_bag_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Sale Items (${_items.length})',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.qr_code_scanner_rounded, size: 15),
                            label: const Text('⚡ Scan to Sell', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                            onPressed: _scanToSell,
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('+ Add Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                            onPressed: _addItemDialog,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_items.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.25), width: 1.2),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_shopping_cart_rounded, size: 32, color: AppColors.primary),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'No items added to Quick Sale yet',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Scan barcode/IMEI or choose product from inventory',
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                                label: const Text('⚡ Scan to Sell', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                onPressed: _scanToSell,
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Choose Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                onPressed: _addItemDialog,
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, idx) {
                        final item = _items[idx];
                        final isInv = item.inventoryItemId != null;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isInv ? Colors.green.shade50.withOpacity(0.5) : Colors.purple.shade50.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isInv ? Colors.green.shade200 : Colors.purple.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isInv ? Colors.green.shade100 : Colors.purple.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isInv ? Icons.inventory_2_rounded : Icons.extension_rounded,
                                  color: isInv ? Colors.green.shade800 : Colors.purple.shade800,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.quantity} x \u20B9${item.unitPrice.toStringAsFixed(2)}${isInv ? " (Inventory Stock)" : " (Custom Item)"}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\u20B9${item.total.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                onPressed: () {
                                  setState(() => _items.removeAt(idx));
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Customer Details Card (Optional)
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Customer Details (Optional / Walk-in)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Customer Name',
                          hint: 'e.g. Walk-in / Rahul',
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
            const SizedBox(height: 14),

            // 4. Warranty Card
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

            // 5. Total Breakdown & Action Button
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
                      const Text('Subtotal:', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      Text('\u20B9${_subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('\u20B9${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
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
                          : Text('Complete Quick Sale (\u20B9${_total.toStringAsFixed(2)})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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