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

        if ($user->role !== 'owner' && !$user->hasPermission('sales')) {
            return response()->json([
                'success' => false,
                'message' => 'You do not have permission to access the Sales module.',
            ], 403);
        }

        $query = Sale::forShop($user->shop_id)
            ->with(['customer', 'device', 'items.inventoryItem', 'payments', 'warranty']);

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

        // Filter by Period presets
        if ($request->filled('period') && $request->input('period') !== 'all_time') {
            $period = $request->input('period');
            $now = \Carbon\Carbon::now();
            if ($period === 'today') {
                $query->whereDate('sale_date', $now->toDateString());
            } elseif ($period === 'yesterday') {
                $query->whereDate('sale_date', $now->copy()->subDay()->toDateString());
            } elseif ($period === 'this_week') {
                $query->whereBetween('sale_date', [$now->copy()->startOfWeek()->startOfDay(), $now->copy()->endOfWeek()->endOfDay()]);
            } elseif ($period === 'this_month') {
                $query->whereBetween('sale_date', [$now->copy()->startOfMonth()->startOfDay(), $now->copy()->endOfMonth()->endOfDay()]);
            } elseif ($period === 'last_month') {
                $query->whereBetween('sale_date', [$now->copy()->subMonth()->startOfMonth()->startOfDay(), $now->copy()->subMonth()->endOfMonth()->endOfDay()]);
            } elseif ($period === 'this_year') {
                $query->whereBetween('sale_date', [$now->copy()->startOfYear()->startOfDay(), $now->copy()->endOfYear()->endOfDay()]);
            }
        }

        if ($request->filled('date_from')) {
            $query->whereDate('sale_date', '>=', $request->input('date_from'));
        }

        if ($request->filled('date_to')) {
            $query->whereDate('sale_date', '<=', $request->input('date_to'));
        }

        $summaryQuery = clone $query;
        $totalBilled = (float) (clone $summaryQuery)->sum('grand_total');
        $totalPaid = (float) (clone $summaryQuery)->sum('amount_paid');
        $totalDue = (float) (clone $summaryQuery)->sum('amount_due');
        $totalCount = (int) (clone $summaryQuery)->count();

        $totalProfit = 0.0;
        $totalCost = 0.0;
        if ($user->role === 'owner') {
            $salesForSummary = (clone $summaryQuery)->with(['items.inventoryItem'])->get();
            foreach ($salesForSummary as $s) {
                $totalProfit += (float) $s->net_profit;
                $totalCost += (float) $s->total_cost;
            }
        }

        $summary = [
            'total_billed' => round($totalBilled, 2),
            'total_paid' => round($totalPaid, 2),
            'total_due' => round($totalDue, 2),
            'total_profit' => round($totalProfit, 2),
            'total_cost' => round($totalCost, 2),
            'total_count' => $totalCount,
        ];

        $sort = $request->input('sort', 'newest');
        switch ($sort) {
            case 'oldest':
                $query->orderBy('sale_date', 'asc')->orderBy('id', 'asc');
                break;
            case 'amount_high':
                $query->orderBy('grand_total', 'desc');
                break;
            case 'amount_low':
                $query->orderBy('grand_total', 'asc');
                break;
            case 'newest':
            default:
                $query->orderBy('sale_date', 'desc')->orderBy('id', 'desc');
                break;
        }

        $sales = $query->paginate($request->input('per_page', 15));

        return response()->json([
            'success' => true,
            'data' => SaleResource::collection($sales),
            'summary' => $summary,
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
                    $itemTaxRate = (float) ($itemData['tax_rate'] ?? 0);
                    $itemTaxType = $itemData['tax_type'] ?? null;

                    // If item tax rate not explicitly provided, inherit from inventory item if present
                    if ($itemTaxRate <= 0 && !empty($itemData['inventory_item_id'])) {
                        $inv = \App\Models\InventoryItem::forShop($user->shop_id)->find($itemData['inventory_item_id']);
                        if ($inv && (float) $inv->tax_rate > 0) {
                            $itemTaxRate = (float) $inv->tax_rate;
                            $itemTaxType = $itemTaxType ?? ($inv->tax_type ?? 'exclusive');
                        }
                    }
                    $itemTaxType = $itemTaxType ?? 'exclusive';

                    if ($itemTax <= 0 && $itemTaxRate > 0) {
                        $lineTaxable = max(0, ($qty * $price) - $itemDiscount);
                        if ($itemTaxType === 'inclusive') {
                            $lineBase = $lineTaxable / (1 + ($itemTaxRate / 100));
                            $itemTax = round($lineTaxable - $lineBase, 2);
                        } else {
                            $itemTax = round($lineTaxable * ($itemTaxRate / 100), 2);
                        }
                    }

                    $itemTotal = ($qty * $price) - $itemDiscount + ($itemTaxType === 'inclusive' ? 0 : $itemTax);

                    $subtotal += ($qty * $price);
                    $totalItemDiscount += $itemDiscount;
                    $totalItemTax += $itemTax;

                    $processedItems[] = array_merge($itemData, [
                        'tax_rate' => $itemTaxRate,
                        'tax_type' => $itemTaxType,
                        'discount' => $itemDiscount,
                        'tax_amount' => $itemTax,
                        'total' => max(0, $itemTotal),
                    ]);
                }

                $saleDiscount = (float) ($validated['discount'] ?? 0);
                $saleTax = (float) ($validated['tax_amount'] ?? 0);
                $taxRate = (float) ($validated['tax_rate'] ?? 0);
                $taxType = $validated['tax_type'] ?? 'exclusive';
                $isInterState = (bool) ($validated['is_inter_state'] ?? false);

                if ($saleTax <= 0 && $taxRate > 0) {
                    $taxable = max(0, $subtotal - $saleDiscount);
                    if ($taxType === 'inclusive') {
                        $taxableBase = $taxable / (1 + ($taxRate / 100));
                        $saleTax = round($taxable - $taxableBase, 2);
                    } else {
                        $saleTax = round($taxable * ($taxRate / 100), 2);
                    }
                } elseif ($saleTax <= 0 && $totalItemTax > 0) {
                    $saleTax = $totalItemTax;
                    $firstTaxed = collect($processedItems)->first(fn($i) => ($i['tax_rate'] ?? 0) > 0);
                    if ($firstTaxed) {
                        $taxRate = (float) $firstTaxed['tax_rate'];
                        $taxType = $firstTaxed['tax_type'] ?? 'exclusive';
                    }
                }

                if ($isInterState) {
                    $igstAmount = $saleTax;
                    $cgstAmount = 0;
                    $sgstAmount = 0;
                } else {
                    $cgstAmount = round($saleTax / 2, 2);
                    $sgstAmount = round($saleTax - $cgstAmount, 2);
                    $igstAmount = 0;
                }

                $overallDiscount = $totalItemDiscount + $saleDiscount;
                $overallTax = ($saleTax == $totalItemTax) ? $saleTax : ($totalItemTax + $saleTax);

                $grandTotal = max(0, $subtotal - $overallDiscount + ($taxType === 'inclusive' ? 0 : $overallTax));

                // Validation: Payment amount cannot exceed the bill grand total
                $initialPayment = (float) ($validated['payment_amount'] ?? 0);
                if ($initialPayment > (float) $grandTotal) {
                    throw new \Exception("Paid amount (₹" . number_format($initialPayment, 2) . ") cannot exceed the total bill amount (₹" . number_format($grandTotal, 2) . ").");
                }

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
                    'tax_rate' => $taxRate,
                    'tax_type' => $taxType,
                    'is_inter_state' => $isInterState,
                    'cgst_amount' => $cgstAmount,
                    'sgst_amount' => $sgstAmount,
                    'igst_amount' => $igstAmount,
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

                        // Ensure cost_price is populated from inventory item purchase_price
                        if (empty($pItem['cost_price']) && !empty($invItem->purchase_price)) {
                            $pItem['cost_price'] = $invItem->purchase_price;
                        }

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

                        // Mark inventory serial as sold
                        $serialQuery = \App\Models\InventorySerial::forShop($user->shop_id)
                            ->where('inventory_item_id', $invItem->id)
                            ->where('status', 'available');

                        if (!empty($pItem['imei_1']) || !empty($pItem['imei_2']) || !empty($pItem['serial_number'])) {
                            $serialQuery->where(function ($q) use ($pItem) {
                                if (!empty($pItem['imei_1'])) $q->orWhere('imei1', $pItem['imei_1'])->orWhere('imei2', $pItem['imei_1']);
                                if (!empty($pItem['imei_2'])) $q->orWhere('imei1', $pItem['imei_2'])->orWhere('imei2', $pItem['imei_2']);
                                if (!empty($pItem['serial_number'])) $q->orWhere('serial_number', $pItem['serial_number']);
                            });
                        }

                        $serialToMark = $serialQuery->first();
                        if ($serialToMark) {
                            $serialToMark->update(['status' => 'sold']);
                        }
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

                // Optionally create Warranty if requested during sale creation
                $hasWarranty = !empty($validated['has_warranty']) 
                    || !empty($validated['create_warranty']) 
                    || !empty($validated['warranty_duration_days']) 
                    || !empty($validated['duration_days']);

                if ($hasWarranty) {
                    $duration = (int) ($validated['warranty_duration_days'] ?? $validated['duration_days'] ?? 30);
                    $startDate = \Carbon\Carbon::today();
                    $endDate = (clone $startDate)->addDays($duration);

                    $count = \App\Models\Warranty::withTrashed()->forShop($user->shop_id)->lockForUpdate()->count();
                    $warrantyNumber = 'WAR-' . str_pad($count + 1, 6, '0', STR_PAD_LEFT);

                    \App\Models\Warranty::create([
                        'shop_id' => $user->shop_id,
                        'customer_id' => $sale->customer_id,
                        'device_id' => $sale->device_id,
                        'sale_id' => $sale->id,
                        'repair_id' => null,
                        'warranty_number' => $warrantyNumber,
                        'warranty_type' => 'sale',
                        'warranty_start_date' => $startDate->toDateString(),
                        'warranty_end_date' => $endDate->toDateString(),
                        'duration_days' => $duration,
                        'warranty_terms' => $validated['warranty_terms'] ?? null,
                        'status' => 'active',
                        'notes' => $validated['warranty_notes'] ?? null,
                        'created_by' => $user->id,
                    ]);
                }

                return $sale->load(['customer', 'device', 'items', 'payments', 'creator', 'warranty']);
            });

            return response()->json([
                'success' => true,
                'message' => 'Sale invoice created successfully.',
                'data' => new SaleResource($sale),
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    /**
     * Display details of a specific sale.
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        $sale = Sale::forShop($user->shop_id)
            ->with(['customer', 'device', 'items', 'payments.creator', 'creator', 'warranty'])
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
            'customer_name' => ['nullable', 'string', 'max:255'],
            'customer_mobile' => ['nullable', 'string', 'max:50'],
            'sale_date' => ['nullable', 'date'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $sale->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Sale invoice updated successfully.',
            'data' => new SaleResource($sale->load(['customer', 'device', 'items', 'payments', 'creator'])),
        ]);
    }

    private function resolveSaleId(mixed $sale): int
    {
        if ($sale instanceof Sale) {
            return (int) $sale->id;
        }
        return (int) $sale;
    }

    /**
     * Remove / Delete the specified sale invoice.
     */
    public function destroy(Request $request, mixed $sale): JsonResponse
    {
        $user = $request->user();
        if ($user->role !== 'owner') {
            return response()->json([
                'success' => false,
                'message' => 'Only the shop owner can delete sales invoices.',
            ], 403);
        }

        $id = $this->resolveSaleId($sale);
        $saleRecord = Sale::forShop($user->shop_id)->with('items')->find($id);

        if (!$saleRecord) {
            return response()->json([
                'success' => false,
                'message' => 'Sale invoice not found or unauthorized.',
            ], 404);
        }

        DB::transaction(function () use ($saleRecord) {
            // Restore inventory stock and serials for each sold item before deleting
            foreach ($saleRecord->items as $item) {
                if ($item->inventory_item_id) {
                    $invItem = \App\Models\InventoryItem::forShop($saleRecord->shop_id)->find($item->inventory_item_id);
                    if ($invItem) {
                        $invItem->increment('current_stock', $item->quantity);
                    }

                    // Restore serial back to available
                    $serialQuery = \App\Models\InventorySerial::forShop($saleRecord->shop_id)
                        ->where('inventory_item_id', $item->inventory_item_id)
                        ->where('status', 'sold');

                    if (!empty($item->imei_1) || !empty($item->imei_2) || !empty($item->serial_number)) {
                        $serialQuery->where(function ($q) use ($item) {
                            if (!empty($item->imei_1)) $q->orWhere('imei1', $item->imei_1)->orWhere('imei2', $item->imei_1);
                            if (!empty($item->imei_2)) $q->orWhere('imei1', $item->imei_2)->orWhere('imei2', $item->imei_2);
                            if (!empty($item->serial_number)) $q->orWhere('serial_number', $item->serial_number);
                        });
                    }

                    $serialToRestore = $serialQuery->first();
                    if ($serialToRestore) {
                        $serialToRestore->update(['status' => 'available']);
                    }
                }
            }

            // Remove stock movement records generated by this sale so history stays accurate
            \App\Models\StockMovement::where('shop_id', $saleRecord->shop_id)
                ->where('reference_type', 'sale')
                ->where('reference_id', $saleRecord->id)
                ->delete();

            $saleRecord->items()->delete();
            $saleRecord->payments()->delete();
            $saleRecord->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'Sale invoice deleted successfully.',
        ]);
    }
}
