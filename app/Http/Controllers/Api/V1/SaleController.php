<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreSaleRequest;
use App\Http\Resources\SaleResource;
use App\Models\Sale;
use App\Models\SaleItem;
use App\Models\SalePayment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SaleController extends Controller
{
    /**
     * Display a listing of sales for the authenticated shop.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user->shop_id) {
            return response()->json([
                'success' => false,
                'message' => 'User is not associated with any shop.',
            ], 403);
        }

        $query = Sale::forShop($user->shop_id)
            ->with(['customer', 'device', 'items', 'payments']);

        // Search by invoice_number, customer_name, customer_mobile, customer model, or item details
        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('invoice_number', 'like', "%{$search}%")
                  ->orWhere('customer_name', 'like', "%{$search}%")
                  ->orWhere('customer_mobile', 'like', "%{$search}%")
                  ->orWhereHas('customer', function ($cq) use ($search) {
                      $cq->where('name', 'like', "%{$search}%")
                         ->orWhere('mobile', 'like', "%{$search}%");
                  })
                  ->orWhereHas('items', function ($iq) use ($search) {
                      $iq->where('product_name', 'like', "%{$search}%")
                         ->orWhere('imei_1', 'like', "%{$search}%")
                         ->orWhere('imei_2', 'like', "%{$search}%")
                         ->orWhere('brand', 'like', "%{$search}%")
                         ->orWhere('model', 'like', "%{$search}%");
                  });
            });
        }

        if ($request->filled('sale_type') && $request->input('sale_type') !== 'all') {
            $query->where('sale_type', $request->input('sale_type'));
        }

        if ($request->filled('payment_status') && $request->input('payment_status') !== 'all') {
            $query->where('payment_status', $request->input('payment_status'));
        }

        if ($request->filled('customer_id')) {
            $query->where('customer_id', $request->input('customer_id'));
        }

        if ($request->filled('date_from')) {
            $query->whereDate('sale_date', '>=', $request->input('date_from'));
        }

        if ($request->filled('date_to')) {
            $query->whereDate('sale_date', '<=', $request->input('date_to'));
        }

        $sales = $query->orderBy('sale_date', 'desc')
            ->orderBy('id', 'desc')
            ->paginate($request->input('per_page', 15));

        return response()->json([
            'success' => true,
            'data' => SaleResource::collection($sales),
            'meta' => [
                'current_page' => $sales->currentPage(),
                'last_page' => $sales->lastPage(),
                'per_page' => $sales->perPage(),
                'total' => $sales->total(),
            ],
        ]);
    }

    /**
     * Store a new sale.
     */
    public function store(StoreSaleRequest $request): JsonResponse
    {
        $user = $request->user();
        if (!$user->shop_id) {
            return response()->json([
                'success' => false,
                'message' => 'User is not associated with any shop.',
            ], 403);
        }

        $validated = $request->validated();

        // Validate customer ownership if provided
        if (!empty($validated['customer_id'])) {
            $customer = \App\Models\Customer::where('shop_id', $user->shop_id)
                ->find($validated['customer_id']);
            if (!$customer) {
                return response()->json([
                    'success' => false,
                    'message' => 'Selected customer does not belong to your shop.',
                ], 422);
            }
        }

        // Validate device ownership if provided
        if (!empty($validated['device_id'])) {
            $device = \App\Models\Device::where('shop_id', $user->shop_id)
                ->find($validated['device_id']);
            if (!$device) {
                return response()->json([
                    'success' => false,
                    'message' => 'Selected device does not belong to your shop.',
                ], 422);
            }
        }

        try {
            $sale = DB::transaction(function () use ($user, $validated) {
                // Generate per-shop unique invoice number collision-safely (including soft-deleted invoices)
                $maxSeq = 0;
                $allInvoices = Sale::withTrashed()
                    ->forShop($user->shop_id)
                    ->where('invoice_number', 'like', 'INV-%')
                    ->pluck('invoice_number');

                foreach ($allInvoices as $inv) {
                    if (preg_match('/INV-(\d+)/', $inv, $m)) {
                        $n = (int) $m[1];
                        if ($n > $maxSeq) {
                            $maxSeq = $n;
                        }
                    }
                }

                $seq = $maxSeq + 1;
                do {
                    $invoiceNumber = 'INV-' . str_pad($seq, 6, '0', STR_PAD_LEFT);
                    $exists = Sale::withTrashed()
                        ->forShop($user->shop_id)
                        ->where('invoice_number', $invoiceNumber)
                        ->exists();
                    if ($exists) {
                        $seq++;
                    }
                } while ($exists);

                // Calculate subtotal, item discounts, and item taxes
                $subtotal = 0;
                $totalItemDiscount = 0;
                $totalItemTax = 0;
                $processedItems = [];

                foreach ($validated['items'] as $itemData) {
                    $qty = (int) $itemData['quantity'];
                    $price = (float) $itemData['unit_price'];
                    $itemDiscount = (float) ($itemData['discount'] ?? 0);
                    $itemTax = (float) ($itemData['tax_amount'] ?? 0);
                    $itemTotal = ($qty * $price) - $itemDiscount + $itemTax;

                    $subtotal += ($qty * $price);
                    $totalItemDiscount += $itemDiscount;
                    $totalItemTax += $itemTax;

                    $processedItems[] = array_merge($itemData, [
                        'discount' => $itemDiscount,
                        'tax_amount' => $itemTax,
                        'total' => max(0, $itemTotal),
                    ]);
                }

                $saleDiscount = (float) ($validated['discount'] ?? 0);
                $saleTax = (float) ($validated['tax_amount'] ?? 0);

                $overallDiscount = $totalItemDiscount + $saleDiscount;
                $overallTax = $totalItemTax + $saleTax;

                $grandTotal = max(0, $subtotal - $overallDiscount + $overallTax);

                $sale = Sale::create([
                    'shop_id' => $user->shop_id,
                    'sale_type' => $validated['sale_type'] ?? 'regular',
                    'customer_id' => $validated['customer_id'] ?? null,
                    'customer_name' => $validated['customer_name'] ?? null,
                    'customer_mobile' => $validated['customer_mobile'] ?? null,
                    'device_id' => $validated['device_id'] ?? null,
                    'invoice_number' => $invoiceNumber,
                    'sale_date' => $validated['sale_date'] ?? now(),
                    'subtotal' => $subtotal,
                    'discount' => $saleDiscount,
                    'tax_amount' => $saleTax,
                    'grand_total' => $grandTotal,
                    'amount_paid' => 0,
                    'amount_due' => $grandTotal,
                    'payment_status' => 'due',
                    'notes' => $validated['notes'] ?? null,
                    'created_by' => $user->id,
                ]);

                foreach ($processedItems as $pItem) {
                    $invItemId = $pItem['inventory_item_id'] ?? null;
                    if ($invItemId) {
                        $invItem = \App\Models\InventoryItem::forShop($user->shop_id)->lockForUpdate()->find($invItemId);
                        if (!$invItem) {
                            throw new \Exception("Inventory item ID {$invItemId} not found.");
                        }
                        if ($invItem->current_stock < $pItem['quantity']) {
                            throw new \Exception("Insufficient stock for '{$invItem->name}'. Current stock: {$invItem->current_stock}, requested: {$pItem['quantity']}.");
                        }

                        // Deduct stock
                        $invItem->decrement('current_stock', $pItem['quantity']);

                        // Log StockMovement
                        \App\Models\StockMovement::create([
                            'shop_id' => $user->shop_id,
                            'inventory_item_id' => $invItem->id,
                            'movement_type' => 'sale',
                            'quantity' => -$pItem['quantity'],
                            'unit_cost' => $invItem->purchase_price,
                            'reference_type' => 'sale',
                            'reference_id' => $sale->id,
                            'notes' => "Sold {$pItem['quantity']} unit(s) via Invoice #{$sale->invoice_number}",
                        ]);
                    }
                    $sale->items()->create($pItem);
                }

                // Record initial payment if provided
                $initialPayment = (float) ($validated['payment_amount'] ?? 0);
                if ($initialPayment > 0) {
                    $paymentAmount = min($initialPayment, $grandTotal);
                    SalePayment::create([
                        'shop_id' => $user->shop_id,
                        'sale_id' => $sale->id,
                        'amount' => $paymentAmount,
                        'payment_method' => $validated['payment_method'] ?? 'cash',
                        'payment_date' => now(),
                        'notes' => $validated['payment_notes'] ?? 'Initial payment',
                        'created_by' => $user->id,
                    ]);

                    $sale->recalculatePaymentStatus();
                }

                return $sale->load(['customer', 'device', 'items', 'payments', 'creator']);
            });

            return response()->json([
                'success' => true,
                'message' => 'Sale invoice created successfully.',
                'data' => new SaleResource($sale),
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to create sale invoice: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Display details of a specific sale.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $sale = Sale::forShop($user->shop_id)
            ->with(['customer', 'device', 'items', 'payments.creator', 'creator'])
            ->find($id);

        if (!$sale) {
            return response()->json([
                'success' => false,
                'message' => 'Sale invoice not found or unauthorized.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => new SaleResource($sale),
        ]);
    }

    /**
     * Update sale notes / details.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $sale = Sale::forShop($user->shop_id)->find($id);

        if (!$sale) {
            return response()->json([
                'success' => false,
                'message' => 'Sale invoice not found or unauthorized.',
            ], 404);
        }

        $validated = $request->validate([
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $sale->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Sale invoice updated successfully.',
            'data' => new SaleResource($sale->load(['customer', 'device', 'items', 'payments', 'creator'])),
        ]);
    }

    /**
     * Remove / Delete the specified sale invoice.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $sale = Sale::forShop($user->shop_id)->with('items')->find($id);

        if (!$sale) {
            return response()->json([
                'success' => false,
                'message' => 'Sale invoice not found or unauthorized.',
            ], 404);
        }

        DB::transaction(function () use ($sale) {
            // Restore inventory stock for each sold item before deleting
            foreach ($sale->items as $item) {
                if ($item->inventory_item_id) {
                    $invItem = \App\Models\InventoryItem::forShop($sale->shop_id)->find($item->inventory_item_id);
                    if ($invItem) {
                        $invItem->increment('current_stock', $item->quantity);
                    }
                }
            }

            // Remove stock movement records generated by this sale so history stays accurate
            \App\Models\StockMovement::where('shop_id', $sale->shop_id)
                ->where('reference_type', 'sale')
                ->where('reference_id', $sale->id)
                ->delete();

            $sale->items()->delete();
            $sale->payments()->delete();
            $sale->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'Sale invoice deleted successfully.',
        ]);
    }
}
