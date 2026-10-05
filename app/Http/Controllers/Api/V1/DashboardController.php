<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use App\Models\InventoryItem;
use App\Models\Purchase;
use App\Models\Repair;
use App\Models\Shop;
use App\Models\Sale;
use App\Models\StockMovement;
use App\Models\Technician;
use App\Models\Warranty;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class DashboardController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        if (!$shopId) {
            return response()->json(['message' => 'No active shop associated with user.'], 400);
        }

        $period = $request->input('period', 'this_month');
        $now = Carbon::now();

        // Calculate Date Range based on period
        if ($period === 'today') {
            $startDate = $now->copy()->startOfDay();
            $endDate = $now->copy()->endOfDay();
        } elseif ($period === 'this_week') {
            $startDate = $now->copy()->startOfWeek();
            $endDate = $now->copy()->endOfWeek();
        } elseif ($period === 'last_month') {
            $startDate = $now->copy()->subMonth()->startOfMonth();
            $endDate = $now->copy()->endOfMonth();
        } elseif ($period === 'custom' && $request->filled('start_date') && $request->filled('end_date')) {
            $startDate = Carbon::parse($request->input('start_date'))->startOfDay();
            $endDate = Carbon::parse($request->input('end_date'))->endOfDay();
        } else { // this_month (default)
            $startDate = $now->copy()->startOfMonth();
            $endDate = $now->copy()->endOfMonth();
        }

        $sDateStr = $startDate->format('Y-m-d');
        $eDateStr = $endDate->format('Y-m-d');

        // 1. Sales Aggregations
        $salesAgg = DB::table('sales')
            ->where('shop_id', $shopId)
            ->whereNull('deleted_at')
            ->whereBetween('sale_date', [$sDateStr, $eDateStr])
            ->selectRaw('
                COALESCE(SUM(grand_total), 0) as total_sales,
                COALESCE(SUM(amount_paid), 0) as total_collected,
                COALESCE(SUM(amount_due), 0) as total_due,
                COUNT(*) as total_count,
                COALESCE(SUM(CASE WHEN sale_type = "regular" THEN 1 ELSE 0 END), 0) as regular_count,
                COALESCE(SUM(CASE WHEN sale_type = "quick" THEN 1 ELSE 0 END), 0) as quick_count
            ')->first();

        $totalSales = (float) ($salesAgg->total_sales ?? 0);
        $totalCollected = (float) ($salesAgg->total_collected ?? 0);
        $totalDue = (float) ($salesAgg->total_due ?? 0);
        $totalSalesCount = (int) ($salesAgg->total_count ?? 0);
        $regularSalesCount = (int) ($salesAgg->regular_count ?? 0);
        $quickSalesCount = (int) ($salesAgg->quick_count ?? 0);

        // Total Dues Across All Time
        $allTimeDues = (float) DB::table('sales')
            ->where('shop_id', $shopId)
            ->whereNull('deleted_at')
            ->where('payment_status', '!=', 'paid')
            ->sum('amount_due');

        // 2. Repair Aggregations
        $repairsAgg = DB::table('repairs')
            ->where('shop_id', $shopId)
            ->whereNull('deleted_at')
            ->selectRaw('
                COUNT(*) as total_count,
                COALESCE(SUM(CASE WHEN repair_status NOT IN ("delivered", "cancelled") THEN 1 ELSE 0 END), 0) as active_count,
                COALESCE(SUM(CASE WHEN repair_status = "ready" THEN 1 ELSE 0 END), 0) as ready_count,
                COALESCE(SUM(CASE WHEN repair_status = "pending_approval" THEN 1 ELSE 0 END), 0) as waiting_customer_count,
                COALESCE(SUM(CASE WHEN repair_status = "in_progress" THEN 1 ELSE 0 END), 0) as waiting_parts_count
            ')->first();

        $activeRepairsCount = (int) ($repairsAgg->active_count ?? 0);
        $readyRepairsCount = (int) ($repairsAgg->ready_count ?? 0);
        $waitingCustomerCount = (int) ($repairsAgg->waiting_customer_count ?? 0);
        $waitingPartsCount = (int) ($repairsAgg->waiting_parts_count ?? 0);
        $totalRepairsCount = (int) ($repairsAgg->total_count ?? 0);

        // 3. Inventory Aggregations
        $inventoryAgg = DB::table('inventory_items')
            ->where('shop_id', $shopId)
            ->whereNull('deleted_at')
            ->selectRaw('
                COUNT(*) as total_items,
                COALESCE(SUM(CASE WHEN current_stock <= minimum_stock AND current_stock > 0 THEN 1 ELSE 0 END), 0) as low_stock_count,
                COALESCE(SUM(CASE WHEN current_stock <= 0 THEN 1 ELSE 0 END), 0) as out_of_stock_count,
                COALESCE(SUM(purchase_price * current_stock), 0) as total_stock_value
            ')->first();

        $totalItems = (int) ($inventoryAgg->total_items ?? 0);
        $lowStockCount = (int) ($inventoryAgg->low_stock_count ?? 0);
        $outOfStockCount = (int) ($inventoryAgg->out_of_stock_count ?? 0);
        $totalStockValue = (float) ($inventoryAgg->total_stock_value ?? 0);

        // 4. Expenses Aggregations
        $totalExpensesSum = (float) DB::table('expenses')
            ->where('shop_id', $shopId)
            ->whereNull('deleted_at')
            ->whereBetween('expense_date', [$sDateStr, $eDateStr])
            ->sum('amount');

        $topCategory = DB::table('expenses')
            ->join('expense_categories', 'expenses.category_id', '=', 'expense_categories.id')
            ->where('expenses.shop_id', $shopId)
            ->whereNull('expenses.deleted_at')
            ->whereBetween('expenses.expense_date', [$sDateStr, $eDateStr])
            ->select('expense_categories.name', DB::raw('SUM(expenses.amount) as total_amount'))
            ->groupBy('expense_categories.id', 'expense_categories.name')
            ->orderBy('total_amount', 'desc')
            ->first();

        // 5. Purchase Aggregations
        $totalPurchases = 0.0;
        $totalPurchasePaid = 0.0;
        $totalPurchaseOutstanding = 0.0;
        $totalPurchasesCount = 0;
        $allTimeVendorDues = 0.0;

        if (Schema::hasTable('purchases')) {
            $purchaseAgg = DB::table('purchases')
                ->where('shop_id', $shopId)
                ->whereNull('deleted_at')
                ->whereBetween('purchase_date', [$sDateStr, $eDateStr])
                ->selectRaw('
                    COALESCE(SUM(grand_total), 0) as total_purchases,
                    COALESCE(SUM(amount_paid), 0) as total_paid,
                    COALESCE(SUM(outstanding_amount), 0) as total_outstanding,
                    COUNT(*) as total_count
                ')->first();

            $totalPurchases = (float) ($purchaseAgg->total_purchases ?? 0);
            $totalPurchasePaid = (float) ($purchaseAgg->total_paid ?? 0);
            $totalPurchaseOutstanding = (float) ($purchaseAgg->total_outstanding ?? 0);
            $totalPurchasesCount = (int) ($purchaseAgg->total_count ?? 0);
            $allTimeVendorDues = (float) DB::table('purchases')
                ->where('shop_id', $shopId)
                ->whereNull('deleted_at')
                ->where('payment_status', '!=', 'paid')
                ->sum('outstanding_amount');
        }

        // 6. Expiring Warranties Count (within next 7 days, matching computed_status 'expiring_soon')
        $expiringWarrantiesCount = (int) Warranty::forShop($shopId)
            ->where('status', 'active')
            ->whereBetween('warranty_end_date', [$now->format('Y-m-d'), $now->copy()->addDays(7)->format('Y-m-d')])
            ->count();

        // 7. Attention Items Generation
        $attention = [];
        if ($outOfStockCount > 0) {
            $attention[] = [
                'type' => 'out_of_stock',
                'title' => "{$outOfStockCount} products out of stock",
                'subtitle' => 'Restock items to avoid lost sales',
                'count' => $outOfStockCount,
                'action_route' => 'inventory',
                'filter' => 'out_of_stock',
            ];
        }
        if ($lowStockCount > 0) {
            $attention[] = [
                'type' => 'low_stock',
                'title' => "{$lowStockCount} products low in stock",
                'subtitle' => 'Stock is running below minimum levels',
                'count' => $lowStockCount,
                'action_route' => 'inventory',
                'filter' => 'low_stock',
            ];
        }
        if ($readyRepairsCount > 0) {
            $attention[] = [
                'type' => 'ready_repair',
                'title' => "{$readyRepairsCount} repairs ready for delivery",
                'subtitle' => 'Notify customers to collect devices',
                'count' => $readyRepairsCount,
                'action_route' => 'repairs',
                'filter' => 'ready',
            ];
        }
        if ($allTimeDues > 0) {
            $attention[] = [
                'type' => 'customer_dues',
                'title' => "Rs. " . number_format($allTimeDues, 2) . " customer dues pending",
                'subtitle' => 'Collect unpaid balances on invoices',
                'amount' => $allTimeDues,
                'action_route' => 'sales',
                'filter' => 'due',
            ];
        }
        if ($allTimeVendorDues > 0) {
            $attention[] = [
                'type' => 'vendor_dues',
                'title' => "Rs. " . number_format($allTimeVendorDues, 2) . " vendor dues pending",
                'subtitle' => 'Unpaid balance on purchases',
                'amount' => $allTimeVendorDues,
                'action_route' => 'vendors',
                'filter' => 'vendor_dues',
            ];
        }
        if ($expiringWarrantiesCount > 0) {
            $attention[] = [
                'type' => 'expiring_warranty',
                'title' => "{$expiringWarrantiesCount} warranties expiring soon",
                'subtitle' => 'Expiring within next 7 days',
                'count' => $expiringWarrantiesCount,
                'action_route' => 'warranties',
                'filter' => 'expiring_soon',
            ];
        }

        // 8. Recent Activity Merged Stream
        $recentActivities = [];

        // Recent Sales
        $recentSales = Sale::forShop($shopId)->latest()->take(3)->get();
        foreach ($recentSales as $sale) {
            $recentActivities[] = [
                'type' => 'sale',
                'title' => $sale->sale_type === 'quick' ? 'Quick Sale' : "Invoice #{$sale->invoice_number}",
                'subtitle' => $sale->customer_name ?? ($sale->customer?->name ?? 'Walk-in Customer'),
                'amount' => (float) $sale->grand_total,
                'time' => $sale->created_at?->format('d M, h:i A') ?? $sale->sale_date->format('d M'),
                'raw_time' => $sale->created_at?->toIso8601String() ?? $sDateStr,
            ];
        }

        // Recent Purchases
        if (Schema::hasTable('purchases')) {
            $recentPurchases = Purchase::forShop($shopId)->with('vendor')->latest()->take(3)->get();
            foreach ($recentPurchases as $p) {
                $recentActivities[] = [
                    'type' => 'purchase',
                    'title' => "Purchase #{$p->purchase_number}",
                    'subtitle' => $p->vendor_name ?? ($p->vendor?->name ?? 'Vendor'),
                    'amount' => (float) $p->grand_total,
                    'time' => $p->created_at?->format('d M, h:i A') ?? $p->purchase_date->format('d M'),
                    'raw_time' => $p->created_at?->toIso8601String() ?? $sDateStr,
                ];
            }
        }

        // Recent Repairs
        $recentRepairs = Repair::forShop($shopId)->with(['device', 'customer'])->latest()->take(3)->get();
        foreach ($recentRepairs as $repair) {
            $deviceStr = ($repair->device?->brand || $repair->device?->model)
                ? trim("{$repair->device->brand} {$repair->device->model}")
                : ($repair->customer?->name ?? 'Mobile Device');
            $recentActivities[] = [
                'type' => 'repair',
                'title' => "Repair #".($repair->job_number ?? $repair->id),
                'subtitle' => $deviceStr,
                'amount' => (float) $repair->estimated_cost,
                'time' => $repair->created_at?->format('d M, h:i A') ?? '',
                'raw_time' => $repair->created_at?->toIso8601String() ?? $sDateStr,
            ];
        }

        // Recent Expenses
        $recentExpenses = Expense::forShop($shopId)->with('category')->latest()->take(3)->get();
        foreach ($recentExpenses as $exp) {
            $recentActivities[] = [
                'type' => 'expense',
                'title' => ($exp->category?->name ?? 'Expense'),
                'subtitle' => $exp->title,
                'amount' => (float) $exp->amount,
                'time' => $exp->created_at?->format('d M, h:i A') ?? $exp->expense_date->format('d M'),
                'raw_time' => $exp->created_at?->toIso8601String() ?? $sDateStr,
            ];
        }

        // Sort combined activities by raw_time desc and take top 6
        usort($recentActivities, function ($a, $b) {
            return strcmp($b['raw_time'], $a['raw_time']);
        });
        $recentActivities = array_slice($recentActivities, 0, 6);

        // 9. Empty Shop Onboarding Check
        $isEmptyShop = ($totalSalesCount === 0 && $totalRepairsCount === 0 && $totalItems === 0 && $totalExpensesSum === 0.0 && $totalPurchasesCount === 0);

        $shopObj = Shop::find($shopId);
        $subObj = \App\Models\Subscription::where('shop_id', $shopId)->latest()->first();
        $daysRemainingVal = 999;
        if ($subObj && $subObj->expiry_date) {
            $expiryDate = \Carbon\Carbon::parse($subObj->expiry_date);
            $daysRemainingVal = max(0, (int) ceil(now()->diffInDays($expiryDate, false)));
        }

        $shopNameVal = $shopObj ? $shopObj->name : "My Mobile Shop";
        $ownerNameVal = ($shopObj && $shopObj->user) ? $shopObj->user->name : ($user ? $user->name : "Shop Owner");

        $netProfit = $totalSales - $totalPurchases - $totalExpensesSum;
        $netCashRemaining = $totalCollected - $totalPurchasePaid - $totalExpensesSum;

        return response()->json([
            'success' => true,
            'period' => $period,
            'date_range' => [
                'start_date' => $sDateStr,
                'end_date' => $eDateStr,
            ],
            'is_empty_shop' => $isEmptyShop,
            'shop_name' => $shopNameVal,
            'owner_name' => $ownerNameVal,
            'days_remaining' => $daysRemainingVal,
            'is_expiring_soon' => ($daysRemainingVal <= 10),
            'data' => [
                'shop_name' => $shopNameVal,
                'owner_name' => $ownerNameVal,
                'days_remaining' => $daysRemainingVal,
                'is_expiring_soon' => ($daysRemainingVal <= 10),
                'financial_overview' => [
                    'total_sales' => round($totalSales, 2),
                    'total_purchases' => round($totalPurchases, 2),
                    'total_expenses' => round($totalExpensesSum, 2),
                    'net_profit' => round($netProfit, 2),
                    'cash_collected' => round($totalCollected, 2),
                    'cash_paid_purchases' => round($totalPurchasePaid, 2),
                    'cash_paid_expenses' => round($totalExpensesSum, 2),
                    'net_cash_remaining' => round($netCashRemaining, 2),
                ],
                'sales' => [
                    'total_sales' => round($totalSales, 2),
                    'total_collected' => round($totalCollected, 2),
                    'total_due' => round($totalDue, 2),
                    'total_count' => $totalSalesCount,
                    'regular_sales_count' => $regularSalesCount,
                    'quick_sales_count' => $quickSalesCount,
                    'all_time_dues' => round($allTimeDues, 2),
                ],
                'purchases' => [
                    'total_purchases' => round($totalPurchases, 2),
                    'total_paid' => round($totalPurchasePaid, 2),
                    'total_outstanding' => round($totalPurchaseOutstanding, 2),
                    'total_count' => $totalPurchasesCount,
                    'all_time_vendor_dues' => round($allTimeVendorDues, 2),
                ],
                'repairs' => [
                    'active_repairs_count' => $activeRepairsCount,
                    'ready_count' => $readyRepairsCount,
                    'waiting_customer_count' => $waitingCustomerCount,
                    'waiting_parts_count' => $waitingPartsCount,
                    'total_repairs_count' => $totalRepairsCount,
                ],
                'inventory' => [
                    'total_items' => $totalItems,
                    'low_stock_count' => $lowStockCount,
                    'out_of_stock_count' => $outOfStockCount,
                    'total_stock_value' => round($totalStockValue, 2),
                ],
                'expenses' => [
                    'total_expenses_sum' => round($totalExpensesSum, 2),
                    'top_category' => $topCategory ? [
                        'name' => $topCategory->name,
                        'amount' => round((float) $topCategory->total_amount, 2),
                    ] : null,
                ],
                'technicians' => [
                    'total_technicians' => (int) Technician::forShop($shopId)->count(),
                    'active_technicians' => (int) Technician::forShop($shopId)->where('is_active', true)->count(),
                    'in_progress_jobs' => (int) Repair::forShop($shopId)->whereIn('repair_status', ['repairing', 'in_progress'])->whereNotNull('technician_id')->count(),
                    'pending_jobs' => (int) Repair::forShop($shopId)->whereIn('repair_status', ['received', 'diagnosing', 'waiting_customer', 'waiting_parts', 'pending_approval'])->whereNotNull('technician_id')->count(),
                    'completed_jobs' => (int) Repair::forShop($shopId)->whereIn('repair_status', ['ready', 'delivered'])->whereNotNull('technician_id')->count(),
                ],
                'attention' => $attention,
                'recent_activity' => $recentActivities,
            ],
        ]);
    }
}