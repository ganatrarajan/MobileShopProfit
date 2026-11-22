<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\Expense;
use App\Models\InventoryItem;
use App\Models\Repair;
use App\Models\Sale;
use App\Models\SaleItem;
use App\Models\SalePayment;
use App\Models\StockMovement;
use App\Models\Warranty;
use App\Models\WarrantyClaim;
use App\Models\Purchase;
use App\Models\Vendor;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ReportController extends Controller
{
    /**
     * Helper to resolve start and end dates from preset or custom range.
     */
    private function resolveDateRange(Request $request): array
    {
        $preset = $request->query('period', 'this_month');

        switch ($preset) {
            case 'today':
                $start = Carbon::today();
                $end = Carbon::today()->endOfDay();
                break;
            case 'yesterday':
                $start = Carbon::yesterday();
                $end = Carbon::yesterday()->endOfDay();
                break;
            case 'this_week':
                $start = Carbon::now()->startOfWeek();
                $end = Carbon::now()->endOfWeek();
                break;
            case 'last_month':
                $start = Carbon::now()->subMonth()->startOfMonth();
                $end = Carbon::now()->subMonth()->endOfMonth();
                break;
            case 'this_year':
                $start = Carbon::now()->startOfYear();
                $end = Carbon::now()->endOfYear();
                break;
            case 'all_time':
                $start = Carbon::create(2020, 1, 1);
                $end = Carbon::now()->addYear();
                break;
            case 'custom':
                if ($request->filled('start_date') && $request->filled('end_date')) {
                    $start = Carbon::parse($request->query('start_date'))->startOfDay();
                    $end = Carbon::parse($request->query('end_date'))->endOfDay();
                } else {
                    $start = Carbon::now()->startOfMonth();
                    $end = Carbon::now()->endOfMonth();
                }
                break;
            case 'this_month':
            default:
                $start = Carbon::now()->startOfMonth();
                $end = Carbon::now()->endOfMonth();
                break;
        }

        return [$start, $end, $preset];
    }

    /**
     * 0. OUTSTANDING / REMAINING DUES REPORT (All Categories, Filterable)
     */
    public function outstanding(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop->id ?? null;
        [$start, $end, $period] = $this->resolveDateRange($request);
        $category = $request->query('category', 'all'); // all, repairs, sales, purchases
        $search = $request->query('search');
        $customerId = $request->query('customer_id') ?: $request->query('customerId');

        $isAllTime = ($period === 'all_time');
        $items = [];

        // 1. REPAIR DUES (Customer Receivables)
        $repairQuery = Repair::forShop($shopId)
            ->where(function($q) {
                $q->where('amount_due', '>', 0)
                  ->orWhereRaw('(COALESCE(final_cost, estimated_cost) - amount_paid) > 0');
            })
            ->where('repair_status', '!=', 'cancelled');

        if (!$isAllTime) {
            $repairQuery->whereBetween('date_received', [$start, $end]);
        }

        if (!empty($customerId)) {
            $repairQuery->where('customer_id', $customerId);
        }

        if (!empty($search)) {
            $s = '%' . $search . '%';
            $repairQuery->where(function ($q) use ($s) {
                $q->where('job_number', 'like', $s)
                  ->orWhereHas('customer', function($cq) use ($s) {
                      $cq->where('name', 'like', $s)
                         ->orWhere('mobile', 'like', $s)
                         ->orWhere('alternate_mobile', 'like', $s);
                  });
            });
        }

        $allRepairs = (clone $repairQuery)->with(['customer', 'device', 'parts'])->get();
        $totalRepairDues = 0;
        $totalRepairBilled = 0;
        $totalRepairPaid = 0;
        foreach ($allRepairs as $r) {
            $final = (float)($r->final_cost ?? 0);
            $est = (float)($r->estimated_cost ?? 0);
            $effectiveCost = $final > 0 ? $final : ($est > 0 ? $est : (float)$r->effective_cost);
            if ($effectiveCost <= 0) {
                $effectiveCost = (float)($r->amount_due ?? 0) + (float)($r->amount_paid ?? 0);
            }
            $paid = (float)($r->amount_paid ?? 0);
            $due = max(0, (float)($r->amount_due > 0 ? $r->amount_due : ($effectiveCost - $paid)));
            $totalRepairDues += $due;
            $totalRepairBilled += $effectiveCost;
            $totalRepairPaid += $paid;

            if ($category === 'all' || $category === 'repairs' || $category === 'customers') {
                $partsData = $r->parts ? $r->parts->map(function($p) {
                    $qty = (int)($p->quantity ?? 1);
                    $price = (float)($p->selling_price ?? 0);
                    return [
                        'id' => $p->id,
                        'part_name' => $p->part_name ?? 'Spare Part',
                        'quantity' => $qty,
                        'selling_price' => $price,
                        'cost_price' => (float)($p->cost_price ?? 0),
                        'total' => round($price * $qty, 2),
                    ];
                })->values()->toArray() : [];

                $items[] = [
                    'id' => 'repair_' . $r->id,
                    'raw_id' => $r->id,
                    'category' => 'repairs',
                    'category_label' => 'Repair Job',
                    'ref_number' => $r->job_number,
                    'date' => $r->date_received ? $r->date_received->format('Y-m-d') : $r->created_at->format('Y-m-d'),
                    'party_name' => $r->customer?->name ?? 'Walk-in Customer',
                    'party_phone' => $r->customer?->mobile ?? $r->customer?->alternate_mobile ?? '',
                    'party_type' => 'customer',
                    'customer_id' => $r->customer_id,
                    'device_name' => trim(($r->device?->brand ?? '') . ' ' . ($r->device?->model ?? '')),
                    'problem_description' => $r->problem_description ?? '',
                    'labour_cost' => (float)($r->labour_cost ?? 0),
                    'parts' => $partsData,
                    'description' => trim(($r->device?->brand ?? '') . ' ' . ($r->device?->model ?? 'Device')),
                    'total_amount' => $effectiveCost,
                    'amount_paid' => $paid,
                    'amount_due' => $due,
                    'status' => $r->repair_status,
                ];
            }
        }

        // 2. SALES DUES (Customer Receivables)
        $saleQuery = Sale::forShop($shopId)
            ->where(function($q) {
                $q->where('amount_due', '>', 0)
                  ->orWhereRaw('(grand_total - amount_paid) > 0');
            })
            ->where('payment_status', '!=', 'paid');

        if (!$isAllTime) {
            $saleQuery->whereBetween('sale_date', [$start, $end]);
        }

        if (!empty($customerId)) {
            $saleQuery->where('customer_id', $customerId);
        }

        if (!empty($search)) {
            $s = '%' . $search . '%';
            $saleQuery->where(function ($q) use ($s) {
                $q->where('invoice_number', 'like', $s)
                  ->orWhere('customer_name', 'like', $s)
                  ->orWhere('customer_mobile', 'like', $s)
                  ->orWhereHas('customer', function($cq) use ($s) {
                      $cq->where('name', 'like', $s)->orWhere('mobile', 'like', $s);
                  });
            });
        }

        $allSales = (clone $saleQuery)->with(['customer', 'items'])->get();
        $totalSalesDues = 0;
        $totalSalesBilled = 0;
        $totalSalesPaid = 0;
        foreach ($allSales as $s) {
            $total = (float)$s->grand_total;
            $paid = (float)$s->amount_paid;
            $due = max(0, (float)($s->amount_due > 0 ? $s->amount_due : ($total - $paid)));
            $totalSalesDues += $due;
            $totalSalesBilled += $total;
            $totalSalesPaid += $paid;

            if ($category === 'all' || $category === 'sales' || $category === 'customers') {
                $itemsData = $s->items ? $s->items->map(function($i) {
                    $qty = (int)($i->quantity ?? 1);
                    $price = (float)($i->unit_price ?? 0);
                    $lineTotal = (float)($i->total ?? ($price * $qty));
                    return [
                        'id' => $i->id,
                        'product_name' => $i->product_name ?? 'Item',
                        'quantity' => $qty,
                        'unit_price' => $price,
                        'total' => $lineTotal,
                    ];
                })->values()->toArray() : [];

                $items[] = [
                    'id' => 'sale_' . $s->id,
                    'raw_id' => $s->id,
                    'category' => 'sales',
                    'category_label' => 'Sale Invoice',
                    'ref_number' => $s->invoice_number,
                    'date' => $s->sale_date ? Carbon::parse($s->sale_date)->format('Y-m-d') : $s->created_at->format('Y-m-d'),
                    'party_name' => $s->customer_name ?? $s->customer?->name ?? 'Walk-in Customer',
                    'party_phone' => $s->customer_mobile ?? $s->customer?->mobile ?? $s->customer?->alternate_mobile ?? '',
                    'party_type' => 'customer',
                    'customer_id' => $s->customer_id,
                    'items' => $itemsData,
                    'description' => ucfirst($s->sale_type ?? 'regular') . ' Sale',
                    'total_amount' => $total,
                    'amount_paid' => $paid,
                    'amount_due' => $due,
                    'status' => $s->payment_status,
                ];
            }
        }

        // 3. PURCHASES DUES (Vendor Payables)
        $purchaseQuery = Purchase::forShop($shopId)
            ->where(function($q) {
                $q->where('outstanding_amount', '>', 0)
                  ->orWhereRaw('(grand_total - amount_paid) > 0');
            })
            ->where('payment_status', '!=', 'paid');

        if (!$isAllTime) {
            $purchaseQuery->whereBetween('purchase_date', [$start, $end]);
        }

        // If filtering by customer, vendor purchases are not relevant
        if (!empty($customerId)) {
            $purchaseQuery->whereRaw('1 = 0');
        }

        if (!empty($search)) {
            $s = '%' . $search . '%';
            $purchaseQuery->where(function ($q) use ($s) {
                $q->where('purchase_number', 'like', $s)
                  ->orWhereHas('vendor', function($vq) use ($s) {
                      $vq->where('name', 'like', $s)->orWhere('phone', 'like', $s);
                  });
            });
        }

        $allPurchases = (clone $purchaseQuery)->with('vendor')->get();
        $totalVendorDues = 0;
        $totalPurchaseBilled = 0;
        $totalPurchasePaid = 0;
        foreach ($allPurchases as $p) {
            $total = (float)$p->grand_total;
            $paid = (float)$p->amount_paid;
            $due = max(0, (float)($p->outstanding_amount > 0 ? $p->outstanding_amount : ($total - $paid)));
            $totalVendorDues += $due;
            $totalPurchaseBilled += $total;
            $totalPurchasePaid += $paid;

            if ($category === 'all' || $category === 'purchases' || $category === 'vendors') {
                $items[] = [
                    'id' => 'purchase_' . $p->id,
                    'raw_id' => $p->id,
                    'category' => 'purchases',
                    'category_label' => 'Vendor Purchase',
                    'ref_number' => $p->purchase_number,
                    'date' => $p->purchase_date ? Carbon::parse($p->purchase_date)->format('Y-m-d') : $p->created_at->format('Y-m-d'),
                    'party_name' => $p->vendor?->name ?? 'Vendor',
                    'party_phone' => $p->vendor?->phone ?? '',
                    'party_type' => 'vendor',
                    'description' => 'Inventory / Parts Purchase',
                    'total_amount' => $total,
                    'amount_paid' => $paid,
                    'amount_due' => $due,
                    'status' => $p->payment_status,
                ];
            }
        }

        // Sort items by date desc, then by amount_due desc
        usort($items, function($a, $b) {
            $dateCmp = strcmp($b['date'], $a['date']);
            if ($dateCmp !== 0) return $dateCmp;
            return $b['amount_due'] <=> $a['amount_due'];
        });

        $totalCustomerDues = $totalRepairDues + $totalSalesDues;
        $netBalance = $totalCustomerDues - $totalVendorDues;

        $selectedCustomer = null;
        if (!empty($customerId)) {
            $cust = Customer::find($customerId);
            if ($cust) {
                $selectedCustomer = [
                    'id' => $cust->id,
                    'name' => $cust->name,
                    'mobile' => $cust->mobile,
                    'alternate_mobile' => $cust->alternate_mobile,
                    'email' => $cust->email,
                    'address' => $cust->address,
                ];
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Outstanding dues report retrieved successfully.',
            'data' => [
                'period' => $period,
                'start_date' => $start->format('Y-m-d'),
                'end_date' => $end->format('Y-m-d'),
                'category' => $category,
                'customer_id' => $customerId ? (int)$customerId : null,
                'customer' => $selectedCustomer,
                'summary' => [
                    'total_customer_dues' => (float)$totalCustomerDues,
                    'total_repair_dues' => (float)$totalRepairDues,
                    'total_repair_billed' => (float)$totalRepairBilled,
                    'total_repair_paid' => (float)$totalRepairPaid,
                    'total_sales_dues' => (float)$totalSalesDues,
                    'total_sales_billed' => (float)$totalSalesBilled,
                    'total_sales_paid' => (float)$totalSalesPaid,
                    'total_vendor_dues' => (float)$totalVendorDues,
                    'total_purchase_billed' => (float)$totalPurchaseBilled,
                    'total_purchase_paid' => (float)$totalPurchasePaid,
                    'net_balance' => (float)$netBalance,
                    'total_records_count' => count($allRepairs) + count($allSales) + count($allPurchases),
                    'repairs_count' => count($allRepairs),
                    'sales_count' => count($allSales),
                    'purchases_count' => count($allPurchases),
                    'active_category' => $category,
                ],
                'details' => $items,
            ],
        ]);
    }

    /**
     * 1. SALES REPORT
     */
    public function sales(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop->id ?? null;
        [$start, $end, $period] = $this->resolveDateRange($request);

        $query = Sale::where('shop_id', $shopId)->whereBetween('sale_date', [$start, $end]);

        if ($request->filled('sale_type') && $request->query('sale_type') !== 'all') {
            $query->where('sale_type', $request->query('sale_type'));
        }

        if ($request->filled('search')) {
            $s = '%' . $request->query('search') . '%';
            $query->where(function ($q) use ($s) {
                $q->where('invoice_number', 'like', $s)
                  ->orWhere('customer_name', 'like', $s)
                  ->orWhere('customer_mobile', 'like', $s);
            });
        }

        // Summary Aggregation
        $totalSales = (float) (clone $query)->sum('grand_total');
        $totalTransactions = (int) (clone $query)->count();
        $regularSalesTotal = (float) (clone $query)->where('sale_type', 'regular')->sum('grand_total');
        $regularSalesCount = (int) (clone $query)->where('sale_type', 'regular')->count();
        $quickSalesTotal = (float) (clone $query)->where('sale_type', 'quick')->sum('grand_total');
        $quickSalesCount = (int) (clone $query)->where('sale_type', 'quick')->count();
        $totalCollected = (float) (clone $query)->sum('amount_paid');
        $totalOutstanding = (float) (clone $query)->sum('amount_due');
        $totalDiscounts = (float) (clone $query)->sum('discount');

        // Sales by day
        $salesByDayRaw = (clone $query)
            ->selectRaw('DATE(sale_date) as date, SUM(grand_total) as total, COUNT(*) as count')
            ->groupBy(DB::raw('DATE(sale_date)'))
            ->orderBy('date', 'asc')
            ->get();

        $salesByDay = $salesByDayRaw->map(fn($row) => [
            'date' => $row->date,
            'total' => (float) $row->total,
            'count' => (int) $row->count,
        ]);

        // Top Selling Products
        $saleIds = (clone $query)->pluck('id');
        $topProducts = SaleItem::whereIn('sale_id', $saleIds)
            ->select('product_name', DB::raw('SUM(quantity) as total_quantity'), DB::raw('SUM(total) as total_revenue'))
            ->groupBy('product_name')
            ->orderByDesc('total_quantity')
            ->limit(10)
            ->get()
            ->map(fn($item) => [
                'product_name' => $item->product_name,
                'total_quantity' => (int) $item->total_quantity,
                'total_revenue' => (float) $item->total_revenue,
            ]);

        // Paginated details
        $perPage = (int) $request->query('per_page', 15);
        $details = (clone $query)
            ->with('items')
            ->orderBy('sale_date', 'desc')
            ->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => [
                'period' => $period,
                'start_date' => $start->toIso8601String(),
                'end_date' => $end->toIso8601String(),
                'summary' => [
                    'total_sales' => $totalSales,
                    'total_transactions' => $totalTransactions,
                    'regular_sales' => $regularSalesTotal,
                    'regular_count' => $regularSalesCount,
                    'quick_sales' => $quickSalesTotal,
                    'quick_count' => $quickSalesCount,
                    'total_collected' => $totalCollected,
                    'total_outstanding' => $totalOutstanding,
                    'total_discounts' => $totalDiscounts,
                ],
                'sales_by_day' => $salesByDay,
                'top_products' => $topProducts,
                'details' => $details,
            ],
        ]);
    }

    /**
     * 2. REPAIR REPORT
     */
    public function repairs(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop->id ?? null;
        [$start, $end, $period] = $this->resolveDateRange($request);

        $query = Repair::where('shop_id', $shopId)->whereBetween('created_at', [$start, $end]);

        if ($request->filled('status') && $request->query('status') !== 'all') {
            $query->where('repair_status', $request->query('status'));
        }

        if ($request->filled('search')) {
            $s = '%' . $request->query('search') . '%';
            $query->where(function ($q) use ($s) {
                $q->where('job_number', 'like', $s)
                  ->orWhereHas('customer', fn($cq) => $cq->where('name', 'like', $s)->orWhere('mobile', 'like', $s))
                  ->orWhereHas('device', fn($dq) => $dq->where('brand', 'like', $s)->orWhere('model', 'like', $s));
            });
        }

        $totalRepairs = (int) (clone $query)->count();
        $completedRepairs = (int) (clone $query)->where('repair_status', 'completed')->count();
        $activeRepairs = (int) (clone $query)->whereIn('repair_status', ['pending', 'received', 'in_progress', 'waiting_parts'])->count();
        $deliveredRepairs = (int) (clone $query)->where('repair_status', 'delivered')->count();
        $cancelledRepairs = (int) (clone $query)->where('repair_status', 'cancelled')->count();

        $repairRevenue = (float) (clone $query)->whereIn('repair_status', ['completed', 'delivered'])->sum(DB::raw('COALESCE(final_cost, estimated_cost, 0)'));
        $repairDues = (float) (clone $query)->where('amount_due', '>', 0)->sum('amount_due');
        $repairPaid = (float) (clone $query)->sum('amount_paid');
        $avgRepairValue = ($completedRepairs + $deliveredRepairs) > 0
            ? round($repairRevenue / ($completedRepairs + $deliveredRepairs), 2)
            : 0.0;

        $statusDist = (clone $query)
            ->select('repair_status', DB::raw('COUNT(*) as count'))
            ->groupBy('repair_status')
            ->get()
            ->pluck('count', 'repair_status');

        $perPage = (int) $request->query('per_page', 15);
        $details = (clone $query)
            ->with(['customer', 'device'])
            ->orderBy('created_at', 'desc')
            ->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => [
                'period' => $period,
                'start_date' => $start->toIso8601String(),
                'end_date' => $end->toIso8601String(),
                'summary' => [
                    'total_repairs' => $totalRepairs,
                    'completed' => $completedRepairs,
                    'active' => $activeRepairs,
                    'delivered' => $deliveredRepairs,
                    'cancelled' => $cancelledRepairs,
                    'repair_revenue' => $repairRevenue,
                    'repair_dues' => $repairDues,
                    'repair_paid' => $repairPaid,
                    'average_repair_value' => $avgRepairValue,
                    'status_distribution' => $statusDist,
                ],
                'details' => $details,
            ],
        ]);
    }

    /**
     * 3. INVENTORY REPORT
     */
    public function inventory(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop->id ?? null;
        [$start, $end, $period] = $this->resolveDateRange($request);

        $query = InventoryItem::where('shop_id', $shopId);

        if ($request->filled('category') && $request->query('category') !== 'all') {
            $query->where('category', $request->query('category'));
        }

        if ($request->filled('item_type') && $request->query('item_type') !== 'all') {
            $query->where('item_type', $request->query('item_type'));
        }

        if ($request->filled('search')) {
            $s = '%' . $request->query('search') . '%';
            $query->where(function ($q) use ($s) {
                $q->where('name', 'like', $s)
                  ->orWhere('brand', 'like', $s)
                  ->orWhere('model', 'like', $s)
                  ->orWhere('sku', 'like', $s);
            });
        }

        $allShopItems = (clone $query)->get();

        $totalValue = 0.0;
        $totalItems = $allShopItems->count();
        $totalStockQty = 0;
        $lowStockCount = 0;
        $outOfStockCount = 0;

        foreach ($allShopItems as $item) {
            $stock = $item->recalculateStock();
            $totalStockQty += $stock;
            $totalValue += ($stock * (float) $item->purchase_price);
            if ($stock <= 0) {
                $outOfStockCount++;
            } elseif ($stock <= $item->minimum_stock) {
                $lowStockCount++;
            }
        }

        // Movement stats in period
        $movementsQuery = StockMovement::where('shop_id', $shopId)
            ->whereBetween('created_at', [$start, $end]);

        $stockPurchased = (int) (clone $movementsQuery)->where('movement_type', 'purchase')->sum('quantity');
        $movementSold = (int) abs((clone $movementsQuery)->where('movement_type', 'sale')->sum('quantity'));
        $saleItemSold = (int) \App\Models\SaleItem::whereHas('sale', function ($q) use ($shopId, $start, $end) {
            $q->where('shop_id', $shopId)->whereBetween('sale_date', [$start, $end]);
        })->sum('quantity');
        $stockSold = max($movementSold, $saleItemSold);
        $stockUsedRepair = (int) abs((clone $movementsQuery)->where('movement_type', 'repair_use')->sum('quantity'));
        $stockDamaged = (int) abs((clone $movementsQuery)->where('movement_type', 'damaged')->sum('quantity'));
        $stockReturned = (int) (clone $movementsQuery)->where('movement_type', 'return')->sum('quantity');

        // Top Selling Inventory Items (aggregated from SaleItem)
        $topSelling = \App\Models\SaleItem::whereHas('sale', function ($q) use ($shopId, $start, $end) {
                $q->where('shop_id', $shopId)->whereBetween('sale_date', [$start, $end]);
            })
            ->select('product_name', \Illuminate\Support\Facades\DB::raw('SUM(quantity) as total_sold'))
            ->groupBy('product_name')
            ->orderByDesc('total_sold')
            ->limit(5)
            ->get()
            ->map(function ($row) {
                return [
                    'name' => $row->product_name ?? 'Unknown Item',
                    'quantity_sold' => (int) $row->total_sold,
                ];
            });

        // Slow moving inventory (No sales in selected period)
        $soldItemIds = StockMovement::where('shop_id', $shopId)
            ->where('movement_type', 'sale')
            ->whereBetween('created_at', [$start, $end])
            ->pluck('inventory_item_id')
            ->toArray();

        $totalMovementCount = StockMovement::where('shop_id', $shopId)->count();
        if ($totalMovementCount < 3) {
            $slowMoving = 'Not enough data.';
        } else {
            $slowMoving = InventoryItem::where('shop_id', $shopId)
                ->whereNotIn('id', $soldItemIds)
                ->where('current_stock', '>', 0)
                ->limit(5)
                ->get()
                ->map(fn($item) => [
                    'item_id' => $item->id,
                    'name' => $item->name,
                    'current_stock' => $item->current_stock,
                ]);
        }

        $perPage = (int) $request->query('per_page', 15);
        $details = (clone $query)->orderBy('name', 'asc')->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => [
                'period' => $period,
                'start_date' => $start->toIso8601String(),
                'end_date' => $end->toIso8601String(),
                'summary' => [
                    'total_inventory_value' => round($totalValue, 2),
                    'total_items' => $totalItems,
                    'total_stock_qty' => $totalStockQty,
                    'low_stock' => $lowStockCount,
                    'out_of_stock' => $outOfStockCount,
                    'stock_purchased' => $stockPurchased,
                    'stock_sold' => $stockSold,
                    'stock_used_in_repairs' => $stockUsedRepair,
                    'damaged_stock' => $stockDamaged,
                    'returned_stock' => $stockReturned,
                ],
                'top_selling' => $topSelling,
                'slow_moving' => $slowMoving,
                'details' => $details,
            ],
        ]);
    }

    /**
     * 4. EXPENSE REPORT
     */
    public function expenses(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop->id ?? null;
        [$start, $end, $period] = $this->resolveDateRange($request);

        $query = Expense::where('shop_id', $shopId)->whereBetween('expense_date', [$start, $end]);

        if ($request->filled('category_id') && $request->query('category_id') !== 'all') {
            $query->where('category_id', $request->query('category_id'));
        }

        if ($request->filled('search')) {
            $s = '%' . $request->query('search') . '%';
            $query->where(function ($q) use ($s) {
                $q->where('title', 'like', $s)->orWhere('notes', 'like', $s);
            });
        }

        $totalExpenses = (float) (clone $query)->sum('amount');

        // Expense by category
        $byCategoryRaw = (clone $query)
            ->select('category_id', DB::raw('SUM(amount) as total'), DB::raw('COUNT(*) as count'))
            ->groupBy('category_id')
            ->orderByDesc('total')
            ->with('category')
            ->get();

        $byCategory = $byCategoryRaw->map(fn($row) => [
            'category_id' => $row->category_id,
            'category_name' => $row->category ? $row->category->name : 'Uncategorized',
            'total_amount' => (float) $row->total,
            'count' => (int) $row->count,
        ]);

        // Expense by date
        $byDateRaw = (clone $query)
            ->selectRaw('DATE(expense_date) as date, SUM(amount) as total')
            ->groupBy(DB::raw('DATE(expense_date)'))
            ->orderBy('date', 'asc')
            ->get();

        $byDate = $byDateRaw->map(fn($row) => [
            'date' => $row->date,
            'total_amount' => (float) $row->total,
        ]);

        $perPage = (int) $request->query('per_page', 15);
        $details = (clone $query)->with('category')->orderBy('expense_date', 'desc')->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => [
                'period' => $period,
                'start_date' => $start->toIso8601String(),
                'end_date' => $end->toIso8601String(),
                'summary' => [
                    'total_expenses' => $totalExpenses,
                ],
                'by_category' => $byCategory,
                'by_date' => $byDate,
                'details' => $details,
            ],
        ]);
    }

    /**
     * 5. PAYMENT REPORT
     */
    public function payments(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop->id ?? null;
        [$start, $end, $period] = $this->resolveDateRange($request);

        // Sales Payments
        $salePaymentsQuery = SalePayment::whereHas('sale', function ($q) use ($shopId, $start, $end) {
            $q->forShop($shopId)->whereBetween('sale_date', [$start, $end]);
        });

        $byMethodRaw = (clone $salePaymentsQuery)
            ->select('payment_method', DB::raw('SUM(amount) as total'), DB::raw('COUNT(*) as count'))
            ->groupBy('payment_method')
            ->get()
            ->pluck('total', 'payment_method');

        $methods = ['cash', 'upi', 'card', 'bank_transfer', 'other'];
        $byMethod = [];
        $totalCollected = 0.0;

        foreach ($methods as $m) {
            $amt = isset($byMethodRaw[$m]) ? (float) $byMethodRaw[$m] : 0.0;
            $byMethod[$m] = $amt;
            $totalCollected += $amt;
        }

        $perPage = (int) $request->query('per_page', 15);
        $details = (clone $salePaymentsQuery)
            ->with(['sale.customer'])
            ->orderBy('payment_date', 'desc')
            ->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => [
                'period' => $period,
                'start_date' => $start->toIso8601String(),
                'end_date' => $end->toIso8601String(),
                'summary' => [
                    'total_collected' => $totalCollected,
                    'by_method' => $byMethod,
                ],
                'details' => $details,
            ],
        ]);
    }

    /**
     * 6. CUSTOMER REPORT
     */
    public function customers(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop->id ?? null;
        [$start, $end, $period] = $this->resolveDateRange($request);

        $totalCustomers = Customer::where('shop_id', $shopId)->count();
        $newCustomers = Customer::where('shop_id', $shopId)->whereBetween('created_at', [$start, $end])->count();

        // Repeat customers: customers with > 1 sales
        $totalSalesCount = Sale::where('shop_id', $shopId)->count();
        if ($totalSalesCount < 2) {
            $repeatCustomers = 'Not enough data.';
        } else {
            $repeatCustomers = Customer::where('shop_id', $shopId)
                ->whereHas('sales', null, '>', 1)
                ->count();
        }

        // Top Customers by spending
        $topCustomers = Customer::where('shop_id', $shopId)
            ->withSum(['sales' => fn($q) => $q->whereBetween('sale_date', [$start, $end])], 'grand_total')
            ->orderByDesc('sales_sum_grand_total')
            ->limit(5)
            ->get()
            ->map(fn($c) => [
                'id' => $c->id,
                'name' => $c->name,
                'mobile' => $c->mobile,
                'total_spent' => (float) ($c->sales_sum_grand_total ?? 0.0),
            ]);

        $perPage = (int) $request->query('per_page', 15);
        $details = Customer::where('shop_id', $shopId)
            ->withCount(['sales', 'repairs'])
            ->withSum('sales', 'grand_total')
            ->orderBy('name', 'asc')
            ->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => [
                'period' => $period,
                'start_date' => $start->toIso8601String(),
                'end_date' => $end->toIso8601String(),
                'summary' => [
                    'total_customers' => $totalCustomers,
                    'new_customers' => $newCustomers,
                    'repeat_customers' => $repeatCustomers,
                ],
                'top_customers' => $topCustomers,
                'details' => $details,
            ],
        ]);
    }

    /**
     * 7. WARRANTY REPORT
     */
    public function warranties(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop->id ?? null;
        [$start, $end, $period] = $this->resolveDateRange($request);

        $query = Warranty::where('shop_id', $shopId)
            ->whereNull('warranties.deleted_at')
            ->whereBetween('created_at', [$start, $end]);

        $totalWarranties = (int) (clone $query)->count();
        $activeWarranties = (int) (clone $query)->where('status', 'active')->count();
        $expiredWarranties = (int) (clone $query)->where('status', 'expired')->count();

        $warrantyIds = (clone $query)->pluck('id');
        $totalClaims = WarrantyClaim::whereIn('warranty_id', $warrantyIds)->count();
        $resolvedClaims = WarrantyClaim::whereIn('warranty_id', $warrantyIds)->whereIn('claim_status', ['approved', 'resolved'])->count();
        $rejectedClaims = WarrantyClaim::whereIn('warranty_id', $warrantyIds)->where('claim_status', 'rejected')->count();

        if ($totalWarranties == 0) {
            $claimRate = 'Not enough data.';
        } else {
            $claimRate = round(($totalClaims / $totalWarranties) * 100, 2) . '%';
        }

        $perPage = (int) $request->query('per_page', 15);
        $details = (clone $query)
            ->with(['customer', 'claims'])
            ->orderBy('created_at', 'desc')
            ->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => [
                'period' => $period,
                'start_date' => $start->toIso8601String(),
                'end_date' => $end->toIso8601String(),
                'summary' => [
                    'total_warranties' => $totalWarranties,
                    'active' => $activeWarranties,
                    'expired' => $expiredWarranties,
                    'total_claims' => $totalClaims,
                    'resolved_claims' => $resolvedClaims,
                    'rejected_claims' => $rejectedClaims,
                    'claim_rate' => $claimRate,
                ],
                'details' => $details,
            ],
        ]);
    }

    /**
     * 8. CSV EXPORT FOUNDATION
     */
    public function export(Request $request): StreamedResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop->id ?? null;
        [$start, $end] = $this->resolveDateRange($request);
        $type = $request->query('type', 'sales');

        $fileName = "report_{$type}_" . date('Ymd_His') . ".csv";

        $response = new StreamedResponse(function () use ($type, $shopId, $start, $end) {
            $handle = fopen('php://output', 'w');

            if ($type === 'outstanding') {
                fputcsv($handle, ['Ref / Job #', 'Category', 'Party / Customer', 'Mobile', 'Date', 'Total Bill', 'Amount Paid', 'Pending Due', 'Status']);
                $repairs = Repair::forShop($shopId)->where(function($q) {
                    $q->where('amount_due', '>', 0)->orWhereRaw('(COALESCE(final_cost, estimated_cost) - amount_paid) > 0');
                })->where('repair_status', '!=', 'cancelled')->with(['customer', 'device'])->get();
                foreach ($repairs as $r) {
                    $effective = (float)($r->final_cost > 0 ? $r->final_cost : ($r->estimated_cost > 0 ? $r->estimated_cost : $r->effective_cost));
                    $paid = (float)$r->amount_paid;
                    $due = max(0, (float)($r->amount_due > 0 ? $r->amount_due : ($effective - $paid)));
                    fputcsv($handle, [
                        $r->job_number,
                        'Repair Job',
                        $r->customer?->name ?? 'Customer',
                        $r->customer?->mobile ?? $r->customer?->alternate_mobile ?? '',
                        $r->date_received ? $r->date_received->format('Y-m-d') : ($r->created_at ? $r->created_at->format('Y-m-d') : ''),
                        $effective,
                        $paid,
                        $due,
                        $r->repair_status,
                    ]);
                }
                $sales = Sale::forShop($shopId)->where(function($q) {
                    $q->where('amount_due', '>', 0)->orWhereRaw('(grand_total - amount_paid) > 0');
                })->where('payment_status', '!=', 'paid')->with('customer')->get();
                foreach ($sales as $s) {
                    $due = max(0, (float)($s->amount_due > 0 ? $s->amount_due : ($s->grand_total - $s->amount_paid)));
                    fputcsv($handle, [
                        $s->invoice_number,
                        'Sale Invoice',
                        $s->customer_name ?? $s->customer?->name ?? 'Customer',
                        $s->customer_mobile ?? $s->customer?->mobile ?? '',
                        $s->sale_date ?? ($s->created_at ? $s->created_at->format('Y-m-d') : ''),
                        $s->grand_total,
                        $s->amount_paid,
                        $due,
                        $s->payment_status,
                    ]);
                }
            } elseif ($type === 'sales') {
                fputcsv($handle, ['Invoice #', 'Sale Date', 'Type', 'Customer', 'Subtotal', 'Discount', 'Grand Total', 'Paid', 'Due', 'Payment Status']);
                $sales = Sale::where('shop_id', $shopId)->whereBetween('sale_date', [$start, $end])->orderBy('sale_date', 'desc')->get();
                foreach ($sales as $s) {
                    fputcsv($handle, [
                        $s->invoice_number,
                        $s->sale_date,
                        $s->sale_type,
                        $s->customer_name ?? 'Walk-in',
                        $s->subtotal,
                        $s->discount,
                        $s->grand_total,
                        $s->amount_paid,
                        $s->amount_due,
                        $s->payment_status,
                    ]);
                }
            } elseif ($type === 'repairs') {
                fputcsv($handle, ['Job #', 'Received Date', 'Customer', 'Mobile', 'Device', 'Issue', 'Estimated Cost', 'Final Cost', 'Amount Paid', 'Amount Due', 'Status']);
                $repairs = Repair::where('shop_id', $shopId)->whereBetween('created_at', [$start, $end])->with(['customer', 'device'])->orderBy('created_at', 'desc')->get();
                foreach ($repairs as $r) {
                    fputcsv($handle, [
                        $r->job_number,
                        $r->created_at ? $r->created_at->format('Y-m-d') : '',
                        $r->customer ? $r->customer->name : 'N/A',
                        $r->customer ? $r->customer->mobile : '',
                        $r->device ? "{$r->device->brand} {$r->device->model}" : '',
                        $r->problem_description ?? '',
                        $r->estimated_cost,
                        $r->final_cost ?? $r->estimated_cost,
                        $r->amount_paid,
                        $r->amount_due,
                        $r->repair_status,
                    ]);
                }
            } elseif ($type === 'inventory') {
                fputcsv($handle, ['Item Name', 'Category', 'Brand', 'Model', 'SKU', 'Current Stock', 'Min Stock', 'Purchase Cost', 'Selling Price', 'Total Valuation']);
                $items = InventoryItem::where('shop_id', $shopId)->orderBy('name', 'asc')->get();
                foreach ($items as $item) {
                    $stock = $item->recalculateStock();
                    $val = $stock * (float) $item->purchase_price;
                    fputcsv($handle, [
                        $item->name,
                        $item->category,
                        $item->brand,
                        $item->model,
                        $item->sku,
                        $stock,
                        $item->minimum_stock,
                        $item->purchase_price,
                        $item->selling_price,
                        $val,
                    ]);
                }
            } elseif ($type === 'expenses') {
                fputcsv($handle, ['Expense Date', 'Category', 'Title', 'Amount', 'Payment Method', 'Notes']);
                $expenses = Expense::where('shop_id', $shopId)->whereBetween('expense_date', [$start, $end])->with('category')->orderBy('expense_date', 'desc')->get();
                foreach ($expenses as $e) {
                    fputcsv($handle, [
                        $e->expense_date,
                        $e->category ? $e->category->name : 'N/A',
                        $e->title,
                        $e->amount,
                        $e->payment_method,
                        $e->notes ?? '',
                    ]);
                }
            } elseif ($type === 'payments') {
                fputcsv($handle, ['Payment Date', 'Invoice / Job #', 'Customer / Party', 'Payment Method', 'Amount', 'Transaction Ref']);
                $payments = SalePayment::whereHas('sale', function ($q) use ($shopId, $start, $end) {
                    $q->forShop($shopId)->whereBetween('sale_date', [$start, $end]);
                })->with('sale')->orderBy('payment_date', 'desc')->get();
                foreach ($payments as $p) {
                    fputcsv($handle, [
                        $p->payment_date,
                        $p->sale ? $p->sale->invoice_number : 'N/A',
                        $p->sale ? $p->sale->customer_name : 'Customer',
                        $p->payment_method,
                        $p->amount,
                        $p->transaction_reference ?? '',
                    ]);
                }
            } elseif ($type === 'customers') {
                fputcsv($handle, ['Customer Name', 'Mobile', 'Email', 'City', 'Total Sales Count', 'Total Spent']);
                $customers = Customer::where('shop_id', $shopId)->withCount('sales')->withSum('sales', 'grand_total')->orderBy('name', 'asc')->get();
                foreach ($customers as $c) {
                    fputcsv($handle, [
                        $c->name,
                        $c->mobile,
                        $c->email ?? '',
                        $c->city ?? '',
                        $c->sales_count ?? 0,
                        $c->sales_sum_grand_total ?? 0.0,
                    ]);
                }
            } elseif ($type === 'warranties') {
                fputcsv($handle, ['Warranty Code', 'Customer', 'Mobile', 'Item Name', 'Start Date', 'End Date', 'Status']);
                $warranties = Warranty::where('shop_id', $shopId)->whereBetween('created_at', [$start, $end])->with('customer')->orderBy('created_at', 'desc')->get();
                foreach ($warranties as $w) {
                    fputcsv($handle, [
                        $w->warranty_code ?? "WAR-{$w->id}",
                        $w->customer ? $w->customer->name : 'N/A',
                        $w->customer ? $w->customer->mobile : '',
                        $w->item_name ?? 'Product / Service',
                        $w->start_date,
                        $w->end_date,
                        $w->status,
                    ]);
                }
            } else {
                fputcsv($handle, ['ID', 'Date', 'Type', 'Status']);
                fputcsv($handle, [1, date('Y-m-d'), $type, 'Report Export Completed']);
            }

            fclose($handle);
        });

        $response->headers->set('Content-Type', 'text/csv');
        $response->headers->set('Content-Disposition', 'attachment; filename="' . $fileName . '"');

        return $response;
    }
}