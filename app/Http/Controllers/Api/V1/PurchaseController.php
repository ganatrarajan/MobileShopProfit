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

class PurchaseController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        if (!$shopId) {
            return response()->json(['message' => 'No active shop associated with user.'], 400);
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
        $purchases = $query->orderBy('purchase_date', 'desc')
            ->orderBy('id', 'desc')
            ->paginate($perPage);

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
                $lineTotal = $qty * $rate;
                $subtotal += $lineTotal;

                $itemsData[] = [
                    'inventory_item' => $invItem,
                    'inventory_item_id' => $invItem->id,
                    'quantity' => $qty,
                    'purchase_rate' => $rate,
                    'total_amount' => $lineTotal,
                ];
            }

            $discount = (float) ($validated['discount'] ?? 0);
            $additionalCharges = (float) ($validated['additional_charges'] ?? 0);
            $grandTotal = max(0, $subtotal - $discount + $additionalCharges);

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
                    'purchase_rate' => $item['purchase_rate'],
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

                    // Update purchase cost price on item (without touching selling price)
                    $invItem->update(['purchase_price' => $item['purchase_rate']]);

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
                $purchase->items()->delete();
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

                    PurchaseItem::create([
                        'purchase_id' => $purchase->id,
                        'inventory_item_id' => $invItem->id,
                        'quantity' => $qty,
                        'purchase_rate' => $rate,
                        'total_amount' => $lineTotal,
                    ]);

                    $itemsData[] = [
                        'inventory_item' => $invItem,
                        'inventory_item_id' => $invItem->id,
                        'quantity' => $qty,
                        'purchase_rate' => $rate,
                    ];
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
