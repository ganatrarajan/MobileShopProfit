<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use App\Models\InventoryItem;
use App\Models\Repair;
use App\Models\Shop;
use App\Models\Sale;
use App\Models\StockMovement;
use App\Models\Warranty;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

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
            $endDate = $now->copy()->subMonth()->endOfMonth();
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
        $salesQuery = Sale::forShop($shopId)->whereDate('sale_date', '>=', $sDateStr)->whereDate('sale_date', '<=', $eDateStr);
        $totalSales = (float) (clone $salesQuery)->sum('grand_total');
        $totalCollected = (float) (clone $salesQuery)->sum('amount_paid');
        $totalDue = (float) (clone $salesQuery)->sum('amount_due');
        $totalSalesCount = (int) (clone $salesQuery)->count();
        $regularSalesCount = (int) (clone $salesQuery)->where('sale_type', 'regular')->count();
        $quickSalesCount = (int) (clone $salesQuery)->where('sale_type', 'quick')->count();

        // Total Dues Across All Time
        $allTimeDues = (float) Sale::forShop($shopId)->where('payment_status', '!=', 'paid')->sum('amount_due');

        // 2. Repair Aggregations
        $activeRepairsCount = (int) Repair::forShop($shopId)->whereNotIn('repair_status', ['delivered', 'cancelled'])->count();
        $readyRepairsCount = (int) Repair::forShop($shopId)->where('repair_status', 'ready')->count();
        $waitingCustomerCount = (int) Repair::forShop($shopId)->where('repair_status', 'pending_approval')->count();
        $waitingPartsCount = (int) Repair::forShop($shopId)->where('repair_status', 'in_progress')->count();
        $totalRepairsCount = (int) Repair::forShop($shopId)->count();

        // 3. Inventory Aggregations
        $totalItems = (int) InventoryItem::forShop($shopId)->count();
        $lowStockCount = (int) InventoryItem::forShop($shopId)
            ->whereColumn('current_stock', '<=', 'minimum_stock')
            ->where('current_stock', '>', 0)
            ->count();
        $outOfStockCount = (int) InventoryItem::forShop($shopId)->where('current_stock', '<=', 0)->count();
        $totalStockValue = (float) DB::table('inventory_items')
            ->where('shop_id', $shopId)
            ->sum(DB::raw('purchase_price * current_stock'));

        // 4. Expenses Aggregations
        $expenseQuery = Expense::forShop($shopId)->whereDate('expense_date', '>=', $sDateStr)->whereDate('expense_date', '<=', $eDateStr);
        $totalExpensesSum = (float) (clone $expenseQuery)->sum('amount');

        $topCategory = DB::table('expenses')
            ->join('expense_categories', 'expenses.category_id', '=', 'expense_categories.id')
            ->where('expenses.shop_id', $shopId)
            ->whereDate('expenses.expense_date', '>=', $sDateStr)->whereDate('expenses.expense_date', '<=', $eDateStr)
            ->select('expense_categories.name', DB::raw('SUM(expenses.amount) as total_amount'))
            ->groupBy('expense_categories.id', 'expense_categories.name')
            ->orderBy('total_amount', 'desc')
            ->first();

        // 5. Expiring Warranties Count (within next 30 days)
        $expiringWarrantiesCount = (int) Warranty::forShop($shopId)
            ->where('status', 'active')
            ->whereBetween('warranty_end_date', [$now->format('Y-m-d'), $now->copy()->addDays(30)->format('Y-m-d')])
            ->count();

        // 6. Attention Items Generation
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
                'title' => "₹" . number_format($allTimeDues, 2) . " customer dues pending",
                'subtitle' => 'Collect unpaid balances on invoices',
                'amount' => $allTimeDues,
                'action_route' => 'sales',
                'filter' => 'unpaid',
            ];
        }
        if ($expiringWarrantiesCount > 0) {
            $attention[] = [
                'type' => 'expiring_warranty',
                'title' => "{$expiringWarrantiesCount} warranties expiring soon",
                'subtitle' => 'Expiring within next 30 days',
                'count' => $expiringWarrantiesCount,
                'action_route' => 'warranties',
                'filter' => 'expiring',
            ];
        }

        // 7. Recent Activity Merged Stream
        $recentActivities = [];

        // Recent Sales
        $recentSales = Sale::forShop($shopId)->latest()->take(3)->get();
        foreach ($recentSales as $sale) {
            $recentActivities[] = [
                'type' => 'sale',
                'title' => $sale->sale_type === 'quick' ? '⚡ Quick Sale' : "🧾 Invoice #{$sale->invoice_number}",
                'subtitle' => $sale->customer_name ?? ($sale->customer?->name ?? 'Walk-in Customer'),
                'amount' => (float) $sale->grand_total,
                'time' => $sale->created_at?->format('d M, h:i A') ?? $sale->sale_date->format('d M'),
                'raw_time' => $sale->created_at?->toIso8601String() ?? $sDateStr,
            ];
        }

        // Recent Repairs
        $recentRepairs = Repair::forShop($shopId)->with(['device', 'customer'])->latest()->take(3)->get();
        foreach ($recentRepairs as $repair) {
            $deviceStr = ($repair->device?->brand || $repair->device?->model)
                ? trim("{$repair->device->brand} {$repair->device->model}")
                : ($repair->customer?->name ?? 'Mobile Device');
            $recentActivities[] = [
                'type' => 'repair',
                'title' => "🔧 Repair #".($repair->job_number ?? $repair->id),
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
                'title' => "💸 " . ($exp->category?->name ?? 'Expense'),
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

        // 8. Empty Shop Onboarding Check
        $isEmptyShop = ($totalSalesCount === 0 && $totalRepairsCount === 0 && $totalItems === 0 && $totalExpensesSum === 0.0);

        $shopObj = Shop::find($shopId);
        $shopNameVal = $shopObj ? $shopObj->name : "My Mobile Shop";
        $ownerNameVal = ($shopObj && $shopObj->user) ? $shopObj->user->name : ($user ? $user->name : "Shop Owner");

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
            'data' => [
                'shop_name' => $shopNameVal,
                'owner_name' => $ownerNameVal,
                'sales' => [
                    'total_sales' => round($totalSales, 2),
                    'total_collected' => round($totalCollected, 2),
                    'total_due' => round($totalDue, 2),
                    'total_count' => $totalSalesCount,
                    'regular_sales_count' => $regularSalesCount,
                    'quick_sales_count' => $quickSalesCount,
                    'all_time_dues' => round($allTimeDues, 2),
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
                'attention' => $attention,
                'recent_activity' => $recentActivities,
            ],
        ]);
    }
}