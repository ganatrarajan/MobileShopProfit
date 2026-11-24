<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StorePurchaseRequest;
use App\Http\Requests\UpdatePurchaseRequest;
use App\Http\Resources\PurchaseResource;
use App\Models\Purchase;
use App\Models\PurchaseItem;
use App\Models\PurchasePayment;
use App\Models\Vendor;
use App\Models\InventoryItem;
use App\Models\StockMovement;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class PurchaseController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        if (!$shopId) {
            return response()->json(['message' => 'No active shop associated with user.'], 400);
        }

        if ($user->role !== 'owner' && !$user->hasPermission('purchases')) {
            return response()->json([
                'success' => false,
                'message' => 'You do not have permission to access the Purchases module.',
            ], 403);
        }

        $query = Purchase::forShop($shopId)->with(['vendor', 'items.inventoryItem', 'payments']);

        // Search by purchase_number or vendor name
        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('purchase_number', 'like', "%{$search}%")
                  ->orWhereHas('vendor', function ($vq) use ($search) {
                      $vq->where('name', 'like', "%{$search}%")
                        ->orWhere('phone', 'like', "%{$search}%");
                  });
            });
        }

        // Vendor filter
        if ($request->filled('vendor_id') && $request->input('vendor_id') !== 'all') {
            $query->where('vendor_id', $request->input('vendor_id'));
        }

        // Payment status filter (paid, partial, pending)
        if ($request->filled('payment_status') && $request->input('payment_status') !== 'all') {
            $query->where('payment_status', $request->input('payment_status'));
        }

        // Filter by Period presets
        if ($request->filled('period') && $request->input('period') !== 'all_time') {
            $period = $request->input('period');
            $now = \Carbon\Carbon::now();
            if ($period === 'today') {
                $query->whereDate('purchase_date', $now->toDateString());
            } elseif ($period === 'yesterday') {
                $query->whereDate('purchase_date', $now->copy()->subDay()->toDateString());
            } elseif ($period === 'this_week') {
                $query->whereBetween('purchase_date', [$now->copy()->startOfWeek()->toDateString(), $now->copy()->endOfWeek()->toDateString()]);
            } elseif ($period === 'this_month') {
                $query->whereBetween('purchase_date', [$now->copy()->startOfMonth()->toDateString(), $now->copy()->endOfMonth()->toDateString()]);
            } elseif ($period === 'last_month') {
                $query->whereBetween('purchase_date', [$now->copy()->subMonth()->startOfMonth()->toDateString(), $now->copy()->subMonth()->endOfMonth()->toDateString()]);
            } elseif ($period === 'this_year') {
                $query->whereBetween('purchase_date', [$now->copy()->startOfYear()->toDateString(), $now->copy()->endOfYear()->toDateString()]);
            }
        }

        // Date range filters
        if ($request->filled('date_from')) {
            $query->whereDate('purchase_date', '>=', $request->input('date_from'));
        }
        if ($request->filled('date_to')) {
            $query->whereDate('purchase_date', '<=', $request->input('date_to'));
        }

        // Summary metrics
        $allPurchases = (clone $query)->get();
        $totalPurchasesCount = $allPurchases->count();
        $totalAmount = (float) $allPurchases->sum('grand_total');
        $totalPaid = (float) $allPurchases->sum('amount_paid');
        $totalOutstanding = (float) $allPurchases->sum('outstanding_amount');

        $perPage = (int) $request->input('per_page', 15);
        $sort = $request->input('sort', 'newest');
        switch ($sort) {
            case 'oldest':
                $query->orderBy('purchase_date', 'asc')->orderBy('id', 'asc');
                break;
            case 'amount_high':
                $query->orderBy('grand_total', 'desc');
                break;
            case 'amount_low':
                $query->orderBy('grand_total', 'asc');
                break;
            case 'newest':
            default:
                $query->orderBy('purchase_date', 'desc')->orderBy('id', 'desc');
                break;
        }

        $purchases = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'message' => 'Purchases retrieved successfully.',
            'metrics' => [
                'total_purchases' => $totalPurchasesCount,
                'total_amount' => round($totalAmount, 2),
                'total_paid' => round($totalPaid, 2),
                'total_outstanding' => round($totalOutstanding, 2),
            ],
            'data' => PurchaseResource::collection($purchases),
            'meta' => [
                'current_page' => $purchases->currentPage(),
                'last_page' => $purchases->lastPage(),
                'per_page' => $purchases->perPage(),
                'total' => $purchases->total(),
            ],
        ]);
    }

    public function store(StorePurchaseRequest $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        if (!$shopId) {
            return response()->json(['message' => 'No active shop associated with user.'], 400);
        }

        if ($user->role !== 'owner' && !$user->hasPermission('purchases')) {
            return response()->json([
                'success' => false,
                'message' => 'You do not have permission to access the Purchases module.',
            ], 403);
        }

        $validated = $request->validated();

        // Verify vendor belongs to shop
        $vendor = Vendor::forShop($shopId)->find($validated['vendor_id']);
        if (!$vendor) {
            return response()->json(['success' => false, 'message' => 'Please select a valid vendor.'], 422);
        }

        return DB::transaction(function () use ($shopId, $validated, $vendor) {
            // Generate purchase_number if not provided
            $purchaseNumber = $validated['purchase_number'] ?? null;
            if (!$purchaseNumber) {
                $maxId = Purchase::forShop($shopId)->withTrashed()->max('id') ?? 0;
                $purchaseNumber = 'PUR-' . (1000 + $maxId + 1);
            }

            // Calculate Subtotal & Line Items
            $subtotal = 0;
            $itemsData = [];
            foreach ($validated['items'] as $itemInput) {
                $invItem = InventoryItem::forShop($shopId)->find($itemInput['inventory_item_id']);
                if (!$invItem) {
                    throw new \InvalidArgumentException("Selected inventory item ID {$itemInput['inventory_item_id']} not found.");
                }

                $qty = (int) $itemInput['quantity'];
                $rate = (float) $itemInput['purchase_rate'];
                $itemTaxAmount = (float) ($itemInput['tax_amount'] ?? 0);
                $itemTaxRate = (float) ($itemInput['tax_rate'] ?? 0);
                $itemTaxType = $itemInput['tax_type'] ?? 'exclusive';
                $lineTotal = (float) ($itemInput['total_amount'] ?? ($qty * $rate));
                $subtotal += ($qty * $rate);

                $itemsData[] = [
                    'inventory_item' => $invItem,
                    'inventory_item_id' => $invItem->id,
                    'quantity' => $qty,
                    'imei1' => !empty($itemInput['imei1']) ? trim($itemInput['imei1']) : null,
                    'imei2' => !empty($itemInput['imei2']) ? trim($itemInput['imei2']) : null,
                    'serial_number' => !empty($itemInput['serial_number']) ? trim($itemInput['serial_number']) : null,
                    'purchase_rate' => $rate,
                    'tax_amount' => $itemTaxAmount,
                    'tax_rate' => $itemTaxRate,
                    'tax_type' => $itemTaxType,
                    'total_amount' => $lineTotal,
                ];
            }

            // Check for duplicate IMEIs across purchase items and against active inventory stock
            $batchImeis = [];
            foreach ($itemsData as $bItem) {
                foreach (['imei1', 'imei2', 'serial_number'] as $key) {
                    $val = $bItem[$key] ?? null;
                    if (!empty($val)) {
                        if (in_array($val, $batchImeis)) {
                            return response()->json([
                                'success' => false,
                                'message' => "Duplicate IMEI/Serial '{$val}' entered multiple times in this purchase.",
                            ], 422);
                        }
                        $batchImeis[] = $val;
                    }
                }
            }

            if (!empty($batchImeis)) {
                $existing = \App\Models\InventorySerial::forShop($shopId)
                    ->where('status', 'available')
                    ->where(function ($q) use ($batchImeis) {
                        $q->whereIn('imei1', $batchImeis)
                          ->orWhereIn('imei2', $batchImeis)
                          ->orWhereIn('serial_number', $batchImeis);
                    })
                    ->with('inventoryItem:id,name')
                    ->first();

                if ($existing) {
                    $dupVal = in_array($existing->imei1, $batchImeis)
                        ? $existing->imei1
                        : (in_array($existing->imei2, $batchImeis) ? $existing->imei2 : $existing->serial_number);
                    $itemName = $existing->inventoryItem ? " ({$existing->inventoryItem->name})" : '';
                    return response()->json([
                        'success' => false,
                        'message' => "IMEI/Serial '{$dupVal}' is already in stock for this shop{$itemName}. Cannot add duplicate until the current unit is sold.",
                    ], 422);
                }
            }

            $discount = (float) ($validated['discount'] ?? 0);
            $additionalCharges = (float) ($validated['additional_charges'] ?? 0);
            $taxRate = (float) ($validated['tax_rate'] ?? 0);
            $taxType = $validated['tax_type'] ?? 'exclusive';
            $isInterState = (bool) ($validated['is_inter_state'] ?? false);
            $taxAmount = (float) ($validated['tax_amount'] ?? 0);

            if ($taxAmount <= 0 && $taxRate > 0) {
                $taxable = max(0, $subtotal - $discount);
                if ($taxType === 'inclusive') {
                    $taxableBase = $taxable / (1 + ($taxRate / 100));
                    $taxAmount = round($taxable - $taxableBase, 2);
                } else {
                    $taxAmount = round($taxable * ($taxRate / 100), 2);
                }
            }

            if ($isInterState) {
                $igstAmount = $taxAmount;
                $cgstAmount = 0;
                $sgstAmount = 0;
            } else {
                $cgstAmount = round($taxAmount / 2, 2);
                $sgstAmount = round($taxAmount - $cgstAmount, 2);
                $igstAmount = 0;
            }

            $netBeforeAdd = $taxType === 'inclusive' ? ($subtotal - $discount) : ($subtotal - $discount + $taxAmount);
            $grandTotal = max(0, $netBeforeAdd + $additionalCharges);

            $amountPaid = (float) ($validated['amount_paid'] ?? 0);
            if ($amountPaid > $grandTotal) {
                return response()->json(['success' => false, 'message' => 'Amount paid cannot exceed grand total.'], 422);
            }

            $outstandingAmount = max(0, $grandTotal - $amountPaid);

            $paymentStatus = $validated['payment_status'] ?? 'pending';
            if ($amountPaid >= $grandTotal && $grandTotal > 0) {
                $paymentStatus = 'paid';
            } elseif ($amountPaid > 0) {
                $paymentStatus = 'partial';
            } else {
                $paymentStatus = 'pending';
            }

            $addToInventory = isset($validated['add_to_inventory']) ? (bool) $validated['add_to_inventory'] : true;

            // Create Purchase
            $purchase = Purchase::create([
                'shop_id' => $shopId,
                'vendor_id' => $vendor->id,
                'purchase_number' => $purchaseNumber,
                'purchase_date' => $validated['purchase_date'],
                'subtotal' => $subtotal,
                'discount' => $discount,
                'tax_amount' => $taxAmount,
                'tax_rate' => $taxRate,
                'tax_type' => $taxType,
                'is_inter_state' => $isInterState,
                'cgst_amount' => $cgstAmount,
                'sgst_amount' => $sgstAmount,
                'igst_amount' => $igstAmount,
                'additional_charges' => $additionalCharges,
                'grand_total' => $grandTotal,
                'amount_paid' => $amountPaid,
                'outstanding_amount' => $outstandingAmount,
                'payment_status' => $paymentStatus,
                'is_stock_added' => $addToInventory,
                'notes' => $validated['notes'] ?? null,
            ]);

            // Create Purchase Items
            foreach ($itemsData as $item) {
                PurchaseItem::create([
                    'purchase_id' => $purchase->id,
                    'inventory_item_id' => $item['inventory_item_id'],
                    'quantity' => $item['quantity'],
                    'imei1' => $item['imei1'],
                    'imei2' => $item['imei2'],
                    'serial_number' => $item['serial_number'],
                    'purchase_rate' => $item['purchase_rate'],
                    'tax_amount' => $item['tax_amount'],
                    'tax_rate' => $item['tax_rate'],
                    'tax_type' => $item['tax_type'],
                    'total_amount' => $item['total_amount'],
                ]);
            }

            // Record initial payment if amount_paid > 0
            if ($amountPaid > 0) {
                PurchasePayment::create([
                    'shop_id' => $shopId,
                    'purchase_id' => $purchase->id,
                    'vendor_id' => $vendor->id,
                    'amount' => $amountPaid,
                    'payment_date' => $validated['purchase_date'],
                    'payment_method' => 'cash',
                    'notes' => 'Initial payment recorded during purchase entry.',
                ]);
            }

            // Process Stock Addition if requested
            if ($addToInventory) {
                foreach ($itemsData as $item) {
                    $invItem = $item['inventory_item'];

                    // Update purchase cost price and GST setting on item
                    $invUpdates = ['purchase_price' => $item['purchase_rate']];
                    if ($taxRate > 0 || ($item['tax_rate'] ?? 0) > 0) {
                        $invUpdates['tax_rate'] = ($item['tax_rate'] ?? 0) > 0 ? $item['tax_rate'] : $taxRate;
                        $invUpdates['tax_type'] = $item['tax_type'] ?? $taxType;
                    }
                    $invItem->update($invUpdates);

                    // Add Stock Movement
                    StockMovement::create([
                        'shop_id' => $shopId,
                        'inventory_item_id' => $invItem->id,
                        'movement_type' => 'purchase',
                        'quantity' => $item['quantity'],
                        'unit_cost' => $item['purchase_rate'],
                        'reference_type' => 'App\Models\Purchase',
                        'reference_id' => $purchase->id,
                        'notes' => "Stock added from Purchase #{$purchase->purchase_number}",
                    ]);

                    // Record serial / IMEI if provided
                    if (!empty($item['imei1']) || !empty($item['imei2']) || !empty($item['serial_number'])) {
                        \App\Models\InventorySerial::create([
                            'shop_id' => $shopId,
                            'inventory_item_id' => $invItem->id,
                            'imei1' => $item['imei1'],
                            'imei2' => $item['imei2'],
                            'serial_number' => $item['serial_number'],
                            'status' => 'available',
                        ]);
                    }

                    $invItem->recalculateStock();
                }
            }

            $purchase->load(['vendor', 'items.inventoryItem', 'payments']);

            return response()->json([
                'success' => true,
                'message' => '✓ Purchase Created' . ($addToInventory ? ' & Inventory Updated' : ''),
                'data' => new PurchaseResource($purchase),
            ], 201);
        });
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        $purchase = Purchase::forShop($shopId)->with(['vendor', 'items.inventoryItem', 'payments'])->find($id);

        if (!$purchase) {
            return response()->json(['success' => false, 'message' => 'Purchase not found.'], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Purchase details retrieved.',
            'data' => new PurchaseResource($purchase),
        ]);
    }

    public function update(UpdatePurchaseRequest $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        $purchase = Purchase::forShop($shopId)->with('items')->find($id);

        if (!$purchase) {
            return response()->json(['success' => false, 'message' => 'Purchase not found.'], 404);
        }

        $validated = $request->validated();

        return DB::transaction(function () use ($shopId, $purchase, $validated) {
            if (isset($validated['vendor_id'])) {
                $vendor = Vendor::forShop($shopId)->find($validated['vendor_id']);
                if (!$vendor) {
                    return response()->json(['success' => false, 'message' => 'Please select a valid vendor.'], 422);
                }
                $purchase->vendor_id = $vendor->id;
            }

            // Reverse existing stock movements if stock was added previously
            if ($purchase->is_stock_added) {
                $this->revertPurchaseStockMovements($shopId, $purchase);
            }

            // Update Items if passed
            if (isset($validated['items'])) {
                $subtotal = 0;
                $itemsData = [];

                foreach ($validated['items'] as $itemInput) {
                    $invItem = InventoryItem::forShop($shopId)->find($itemInput['inventory_item_id']);
                    if (!$invItem) {
                        throw new \InvalidArgumentException("Inventory item ID {$itemInput['inventory_item_id']} not found.");
                    }

                    $qty = (int) $itemInput['quantity'];
                    $rate = (float) $itemInput['purchase_rate'];
                    $lineTotal = $qty * $rate;
                    $subtotal += $lineTotal;

                    $itemsData[] = [
                        'inventory_item' => $invItem,
                        'inventory_item_id' => $invItem->id,
                        'quantity' => $qty,
                        'imei1' => !empty($itemInput['imei1']) ? trim($itemInput['imei1']) : null,
                        'imei2' => !empty($itemInput['imei2']) ? trim($itemInput['imei2']) : null,
                        'serial_number' => !empty($itemInput['serial_number']) ? trim($itemInput['serial_number']) : null,
                        'purchase_rate' => $rate,
                        'total_amount' => $lineTotal,
                    ];
                }

                // Check for duplicate IMEIs across purchase items and against active inventory stock
                $batchImeis = [];
                foreach ($itemsData as $bItem) {
                    foreach (['imei1', 'imei2', 'serial_number'] as $key) {
                        $val = $bItem[$key] ?? null;
                        if (!empty($val)) {
                            if (in_array($val, $batchImeis)) {
                                return response()->json([
                                    'success' => false,
                                    'message' => "Duplicate IMEI/Serial '{$val}' entered multiple times in this purchase.",
                                ], 422);
                            }
                            $batchImeis[] = $val;
                        }
                    }
                }

                if (!empty($batchImeis)) {
                    $existing = \App\Models\InventorySerial::forShop($shopId)
                        ->where('status', 'available')
                        ->where(function ($q) use ($batchImeis) {
                            $q->whereIn('imei1', $batchImeis)
                              ->orWhereIn('imei2', $batchImeis)
                              ->orWhereIn('serial_number', $batchImeis);
                        })
                        ->with('inventoryItem:id,name')
                        ->first();

                    if ($existing) {
                        $dupVal = in_array($existing->imei1, $batchImeis)
                            ? $existing->imei1
                            : (in_array($existing->imei2, $batchImeis) ? $existing->imei2 : $existing->serial_number);
                        $itemName = $existing->inventoryItem ? " ({$existing->inventoryItem->name})" : '';
                        return response()->json([
                            'success' => false,
                            'message' => "IMEI/Serial '{$dupVal}' is already in stock for this shop{$itemName}. Cannot add duplicate until the current unit is sold.",
                        ], 422);
                    }
                }

                $purchase->items()->delete();
                foreach ($itemsData as $itemRow) {
                    PurchaseItem::create([
                        'purchase_id' => $purchase->id,
                        'inventory_item_id' => $itemRow['inventory_item_id'],
                        'quantity' => $itemRow['quantity'],
                        'imei1' => $itemRow['imei1'],
                        'imei2' => $itemRow['imei2'],
                        'serial_number' => $itemRow['serial_number'],
                        'purchase_rate' => $itemRow['purchase_rate'],
                        'total_amount' => $itemRow['total_amount'],
                    ]);
                }
                $purchase->subtotal = $subtotal;
            }

            if (isset($validated['discount'])) {
                $purchase->discount = (float) $validated['discount'];
            }
            if (isset($validated['additional_charges'])) {
                $purchase->additional_charges = (float) $validated['additional_charges'];
            }

            $grandTotal = max(0, (float)$purchase->subtotal - (float)$purchase->discount + (float)$purchase->additional_charges);
            $purchase->grand_total = $grandTotal;

            if (isset($validated['amount_paid'])) {
                $purchase->amount_paid = (float) $validated['amount_paid'];
            }

            if ($purchase->amount_paid > $grandTotal) {
                return response()->json(['success' => false, 'message' => 'Amount paid cannot exceed grand total.'], 422);
            }

            $purchase->outstanding_amount = max(0, $grandTotal - (float)$purchase->amount_paid);

            if ((float)$purchase->amount_paid >= $grandTotal && $grandTotal > 0) {
                $purchase->payment_status = 'paid';
            } elseif ((float)$purchase->amount_paid > 0) {
                $purchase->payment_status = 'partial';
            } else {
                $purchase->payment_status = 'pending';
            }

            if (isset($validated['purchase_date'])) {
                $purchase->purchase_date = $validated['purchase_date'];
            }
            if (isset($validated['notes'])) {
                $purchase->notes = $validated['notes'];
            }
            if (isset($validated['add_to_inventory'])) {
                $purchase->is_stock_added = (bool) $validated['add_to_inventory'];
            }

            $purchase->save();

            // Re-apply stock if is_stock_added is true
            if ($purchase->is_stock_added) {
                $freshItems = $purchase->items()->with('inventoryItem')->get();
                foreach ($freshItems as $pItem) {
                    $invItem = $pItem->inventoryItem;
                    if ($invItem) {
                        $invItem->update(['purchase_price' => $pItem->purchase_rate]);
                        StockMovement::create([
                            'shop_id' => $shopId,
                            'inventory_item_id' => $invItem->id,
                            'movement_type' => 'purchase',
                            'quantity' => $pItem->quantity,
                            'unit_cost' => $pItem->purchase_rate,
                            'reference_type' => 'App\Models\Purchase',
                            'reference_id' => $purchase->id,
                            'notes' => "Stock added from Purchase #{$purchase->purchase_number}",
                        ]);
                        // Record serial / IMEI if provided
                        if (!empty($pItem->imei1) || !empty($pItem->imei2) || !empty($pItem->serial_number)) {
                            \App\Models\InventorySerial::create([
                                'shop_id' => $shopId,
                                'inventory_item_id' => $invItem->id,
                                'imei1' => $pItem->imei1,
                                'imei2' => $pItem->imei2,
                                'serial_number' => $pItem->serial_number,
                                'status' => 'available',
                            ]);
                        }

                        $invItem->recalculateStock();
                    }
                }
            }

            $purchase->load(['vendor', 'items.inventoryItem', 'payments']);

            return response()->json([
                'success' => true,
                'message' => 'Purchase updated successfully.',
                'data' => new PurchaseResource($purchase),
            ]);
        });
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        if ($user->role !== 'owner') {
            return response()->json([
                'success' => false,
                'message' => 'Only the shop owner can delete purchases.',
            ], 403);
        }

        if (empty($user->security_pin)) {
            return response()->json([
                'success' => false,
                'message' => 'Please set up a 4-digit Security PIN in Settings before deleting purchases.',
                'requires_pin_setup' => true,
            ], 422);
        }

        $pin = $request->input('security_pin');
        if (empty($pin)) {
            return response()->json([
                'success' => false,
                'message' => 'Security PIN is required to delete purchase.',
                'requires_pin' => true,
            ], 422);
        }

        if (!Hash::check($pin, $user->security_pin)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid Security PIN.',
            ], 422);
        }

        $shopId = $user->shop_id ?? $user->shop?->id;

        $purchase = Purchase::forShop($shopId)->find($id);

        if (!$purchase) {
            return response()->json(['success' => false, 'message' => 'Purchase not found.'], 404);
        }

        return DB::transaction(function () use ($shopId, $purchase) {
            // Revert stock movements
            if ($purchase->is_stock_added) {
                $this->revertPurchaseStockMovements($shopId, $purchase);
            }

            $purchase->delete();

            return response()->json([
                'success' => true,
                'message' => 'Purchase deleted successfully and stock movements reverted.',
            ]);
        });
    }

    /**
     * Manually remove stock from inventory for an existing purchase if added previously.
     */
    public function removeStock(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        $purchase = Purchase::forShop($shopId)->with('items.inventoryItem')->find($id);

        if (!$purchase) {
            return response()->json(['success' => false, 'message' => 'Purchase not found.'], 404);
        }

        if (!$purchase->is_stock_added) {
            return response()->json([
                'success' => false,
                'message' => 'Stock for this purchase is not added in inventory.',
            ], 400);
        }

        // Validation check: ensure each item has enough stock before removing
        $insufficientItems = [];
        foreach ($purchase->items as $pItem) {
            $invItem = $pItem->inventoryItem;
            if ($invItem) {
                if ($invItem->current_stock < $pItem->quantity) {
                    $insufficientItems[] = "'{$invItem->name}' (Current stock: {$invItem->current_stock}, Required to remove: {$pItem->quantity})";
                }
            }
        }

        if (!empty($insufficientItems)) {
            $itemDetails = implode(', ', $insufficientItems);
            return response()->json([
                'success' => false,
                'message' => "Cannot remove stock because some items have been sold/used: {$itemDetails}.",
            ], 422);
        }

        return DB::transaction(function () use ($shopId, $purchase) {
            $this->revertPurchaseStockMovements($shopId, $purchase);
            $purchase->update(['is_stock_added' => false]);

            return response()->json([
                'success' => true,
                'message' => "✓ Inventory updated. Stock removed for purchase #{$purchase->purchase_number}.",
                'data' => new PurchaseResource($purchase->fresh(['vendor', 'items.inventoryItem', 'payments'])),
            ]);
        });
    }

    /**
     * Manually add stock to inventory for an existing purchase if not added already.
     */
    public function addStock(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        $purchase = Purchase::forShop($shopId)->with('items.inventoryItem')->find($id);

        if (!$purchase) {
            return response()->json(['success' => false, 'message' => 'Purchase not found.'], 404);
        }

        if ($purchase->is_stock_added) {
            return response()->json([
                'success' => false,
                'message' => 'Stock for this purchase has already been added to inventory.',
            ], 400);
        }

        // Validate that none of the IMEIs in this purchase are already in stock
        $batchImeis = [];
        foreach ($purchase->items as $pItem) {
            foreach (['imei1', 'imei2', 'serial_number'] as $key) {
                $val = $pItem->{$key} ?? null;
                if (!empty($val)) {
                    $batchImeis[] = $val;
                }
            }
        }

        if (!empty($batchImeis)) {
            $existing = \App\Models\InventorySerial::forShop($shopId)
                ->where('status', 'available')
                ->where(function ($q) use ($batchImeis) {
                    $q->whereIn('imei1', $batchImeis)
                      ->orWhereIn('imei2', $batchImeis)
                      ->orWhereIn('serial_number', $batchImeis);
                })
                ->with('inventoryItem:id,name')
                ->first();

            if ($existing) {
                $dupVal = in_array($existing->imei1, $batchImeis)
                    ? $existing->imei1
                    : (in_array($existing->imei2, $batchImeis) ? $existing->imei2 : $existing->serial_number);
                $itemName = $existing->inventoryItem ? " ({$existing->inventoryItem->name})" : '';
                return response()->json([
                    'success' => false,
                    'message' => "IMEI/Serial '{$dupVal}' is already in stock for this shop{$itemName}. Cannot add duplicate until the current unit is sold.",
                ], 422);
            }
        }

        return DB::transaction(function () use ($shopId, $purchase) {
            $addedCount = 0;
            foreach ($purchase->items as $pItem) {
                $invItem = $pItem->inventoryItem;
                if ($invItem) {
                    $invItem->update(['purchase_price' => $pItem->purchase_rate]);
                    StockMovement::create([
                        'shop_id' => $shopId,
                        'inventory_item_id' => $invItem->id,
                        'movement_type' => 'purchase',
                        'quantity' => $pItem->quantity,
                        'unit_cost' => $pItem->purchase_rate,
                        'reference_type' => 'App\Models\Purchase',
                        'reference_id' => $purchase->id,
                        'notes' => "Stock added from Purchase #{$purchase->purchase_number}",
                    ]);
                    // Record serial / IMEI if provided
                    if (!empty($pItem->imei1) || !empty($pItem->imei2) || !empty($pItem->serial_number)) {
                        \App\Models\InventorySerial::create([
                            'shop_id' => $shopId,
                            'inventory_item_id' => $invItem->id,
                            'imei1' => $pItem->imei1,
                            'imei2' => $pItem->imei2,
                            'serial_number' => $pItem->serial_number,
                            'status' => 'available',
                        ]);
                    }

                    $invItem->recalculateStock();
                    $addedCount += $pItem->quantity;
                }
            }

            $purchase->update(['is_stock_added' => true]);

            return response()->json([
                'success' => true,
                'message' => "✓ Inventory Updated. {$addedCount} items added to stock.",
                'data' => new PurchaseResource($purchase->fresh(['vendor', 'items.inventoryItem', 'payments'])),
            ]);
        });
    }

    /**
     * Helper to safely remove stock movements belonging to a purchase and recalculate stock.
     */
    private function revertPurchaseStockMovements(int $shopId, Purchase $purchase): void
    {
        // Clean up available serials recorded with this purchase
        $purchase->loadMissing('items');
        foreach ($purchase->items as $pItem) {
            $imeis = array_values(array_filter([$pItem->imei1, $pItem->imei2, $pItem->serial_number]));
            if (!empty($imeis)) {
                \App\Models\InventorySerial::forShop($shopId)
                    ->where('inventory_item_id', $pItem->inventory_item_id)
                    ->where('status', 'available')
                    ->where(function ($q) use ($imeis) {
                        $q->whereIn('imei1', $imeis)
                          ->orWhereIn('imei2', $imeis)
                          ->orWhereIn('serial_number', $imeis);
                    })
                    ->delete();
            }
        }

        $movements = StockMovement::forShop($shopId)
            ->where('reference_type', 'App\Models\Purchase')
            ->where('reference_id', $purchase->id)
            ->get();

        $affectedItemIds = $movements->pluck('inventory_item_id')->unique();

        StockMovement::forShop($shopId)
            ->where('reference_type', 'App\Models\Purchase')
            ->where('reference_id', $purchase->id)
            ->delete();

        foreach ($affectedItemIds as $itemId) {
            $invItem = InventoryItem::forShop($shopId)->find($itemId);
            if ($invItem) {
                $invItem->recalculateStock();
            }
        }
    }
}
