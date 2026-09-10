<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\Expense;
use App\Models\InventoryItem;
use App\Models\Repair;
use App\Models\Sale;
use App\Models\Shop;
use App\Traits\ApiResponse;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminReportController extends Controller
{
    use ApiResponse;

    /**
     * Generate comprehensive aggregated platform business & financial report.
     */
    public function summary(Request $request): JsonResponse
    {
        $range = $request->input('date_range', '30days');
        $shopId = $request->input('shop_id');

        $startDate = null;
        $endDate = Carbon::now()->endOfDay();

        switch ($range) {
            case 'today':
                $startDate = Carbon::today();
                break;
            case 'yesterday':
                $startDate = Carbon::yesterday();
                $endDate = Carbon::yesterday()->endOfDay();
                break;
            case '7days':
                $startDate = Carbon::now()->subDays(6)->startOfDay();
                break;
            case '30days':
                $startDate = Carbon::now()->subDays(29)->startOfDay();
                break;
            case 'this_month':
                $startDate = Carbon::now()->startOfMonth();
                break;
            case 'last_month':
                $startDate = Carbon::now()->subMonth()->startOfMonth();
                $endDate = Carbon::now()->subMonth()->endOfMonth();
                break;
            case 'this_year':
                $startDate = Carbon::now()->startOfYear();
                break;
            case 'custom':
                if ($request->filled('start_date')) {
                    $startDate = Carbon::parse($request->start_date)->startOfDay();
                }
                if ($request->filled('end_date')) {
                    $endDate = Carbon::parse($request->end_date)->endOfDay();
                }
                break;
            case 'all':
            default:
                $startDate = null;
                break;
        }

        // Base Queries without shop global scope
        $salesQuery = Sale::withoutGlobalScope('shop');
        $repairsQuery = Repair::withoutGlobalScope('shop');
        $expensesQuery = Expense::withoutGlobalScope('shop');
        $customersQuery = Customer::withoutGlobalScope('shop');
        $inventoryQuery = InventoryItem::withoutGlobalScope('shop');

        // Apply shop filter if selected
        if ($shopId) {
            $salesQuery->where('shop_id', $shopId);
            $repairsQuery->where('shop_id', $shopId);
            $expensesQuery->where('shop_id', $shopId);
            $customersQuery->where('shop_id', $shopId);
            $inventoryQuery->where('shop_id', $shopId);
        }

        // Apply date range filter
        if ($startDate) {
            $salesQuery->whereBetween('sale_date', [$startDate, $endDate]);
            $repairsQuery->whereBetween('date_received', [$startDate, $endDate]);
            $expensesQuery->whereBetween('expense_date', [$startDate, $endDate]);
            $customersQuery->whereBetween('created_at', [$startDate, $endDate]);
        }

        // 1. Sales Metrics
        $totalSalesCount = (clone $salesQuery)->count();
        $totalSalesRevenue = (float) (clone $salesQuery)->sum('grand_total');
        $totalSalesPaid = (float) (clone $salesQuery)->sum('amount_paid');
        $totalSalesDue = (float) (clone $salesQuery)->sum('amount_due');

        $salesStatusBreakdown = (clone $salesQuery)
            ->select('payment_status', DB::raw('count(*) as count'), DB::raw('sum(grand_total) as total'))
            ->groupBy('payment_status')
            ->get();

        // 2. Repairs Metrics
        $totalRepairsCount = (clone $repairsQuery)->count();
        $totalRepairCost = (float) (clone $repairsQuery)
            ->selectRaw('SUM(CASE WHEN final_cost > 0 THEN final_cost ELSE estimated_cost END) as val')
            ->value('val');
        $totalRepairPaid = (float) (clone $repairsQuery)->sum('amount_paid');
        $totalRepairDue = (float) (clone $repairsQuery)->sum('amount_due');

        $repairsStatusBreakdown = (clone $repairsQuery)
            ->select('repair_status', DB::raw('count(*) as count'))
            ->groupBy('repair_status')
            ->get();

        // 3. Shop Expenses Metrics
        $totalExpensesCount = (clone $expensesQuery)->count();
        $totalShopExpenses = (float) (clone $expensesQuery)->sum('amount');

        $expensesCategoryBreakdown = (clone $expensesQuery)
            ->with('category')
            ->select('category_id', DB::raw('count(*) as count'), DB::raw('sum(amount) as total'))
            ->groupBy('category_id')
            ->get()
            ->map(function ($row) {
                return [
                    'category_name' => $row->category ? $row->category->name : 'Uncategorized',
                    'count'         => $row->count,
                    'total'         => (float) $row->total,
                ];
            });

        // 4. Gross Financial & Net Profit Calculations
        $totalGrossIncome = $totalSalesRevenue + $totalRepairCost;
        $totalActualCollected = $totalSalesPaid + $totalRepairPaid;
        $netPlatformProfit = $totalGrossIncome - $totalShopExpenses;

        // 5. Inventory Summary Metrics (Point in time)
        $totalStockItems = (clone $inventoryQuery)->count();
        $lowStockItemsCount = (clone $inventoryQuery)->whereRaw('current_stock <= minimum_stock AND current_stock > 0')->count();
        $outOfStockItemsCount = (clone $inventoryQuery)->where('current_stock', '<=', 0)->count();
        $inventoryCostValuation = (float) (clone $inventoryQuery)->selectRaw('SUM(current_stock * purchase_price) as val')->value('val');
        $inventorySellingValuation = (float) (clone $inventoryQuery)->selectRaw('SUM(current_stock * selling_price) as val')->value('val');

        // 6. Shop-wise Financial Performance Comparison Matrix
        $shopsList = Shop::all();
        $shopPerformance = $shopsList->map(function ($shop) use ($startDate, $endDate) {
            $sq = Sale::withoutGlobalScope('shop')->where('shop_id', $shop->id);
            $rq = Repair::withoutGlobalScope('shop')->where('shop_id', $shop->id);
            $eq = Expense::withoutGlobalScope('shop')->where('shop_id', $shop->id);

            if ($startDate) {
                $sq->whereBetween('sale_date', [$startDate, $endDate]);
                $rq->whereBetween('date_received', [$startDate, $endDate]);
                $eq->whereBetween('expense_date', [$startDate, $endDate]);
            }

            $sRev = (float) $sq->sum('grand_total');
            $rRev = (float) $rq->selectRaw('SUM(CASE WHEN final_cost > 0 THEN final_cost ELSE estimated_cost END) as val')->value('val');
            $exp = (float) $eq->sum('amount');
            $gross = $sRev + $rRev;
            $net = $gross - $exp;

            return [
                'shop_id'     => $shop->id,
                'shop_name'   => $shop->name,
                'owner_name'  => $shop->owner_name,
                'sales_rev'   => round($sRev, 2),
                'repairs_rev' => round($rRev, 2),
                'gross_rev'   => round($gross, 2),
                'expenses'    => round($exp, 2),
                'net_profit'  => round($net, 2),
            ];
        });

        return $this->successResponse([
            'date_range'  => $range,
            'start_date'  => $startDate ? $startDate->toDateString() : null,
            'end_date'    => $endDate ? $endDate->toDateString() : null,
            'financials'  => [
                'total_sales_revenue'   => round($totalSalesRevenue, 2),
                'total_sales_paid'      => round($totalSalesPaid, 2),
                'total_sales_due'       => round($totalSalesDue, 2),
                'total_repair_cost'     => round($totalRepairCost, 2),
                'total_repair_paid'     => round($totalRepairPaid, 2),
                'total_repair_due'      => round($totalRepairDue, 2),
                'total_gross_income'    => round($totalGrossIncome, 2),
                'total_actual_collected'=> round($totalActualCollected, 2),
                'total_shop_expenses'   => round($totalShopExpenses, 2),
                'net_platform_profit'   => round($netPlatformProfit, 2),
            ],
            'sales' => [
                'count'             => $totalSalesCount,
                'status_breakdown'  => $salesStatusBreakdown,
            ],
            'repairs' => [
                'count'             => $totalRepairsCount,
                'status_breakdown'  => $repairsStatusBreakdown,
            ],
            'expenses' => [
                'count'             => $totalExpensesCount,
                'category_breakdown'=> $expensesCategoryBreakdown,
            ],
            'inventory' => [
                'total_items'       => $totalStockItems,
                'low_stock_count'   => $lowStockItemsCount,
                'out_of_stock_count'=> $outOfStockItemsCount,
                'cost_valuation'    => round($inventoryCostValuation, 2),
                'selling_valuation' => round($inventorySellingValuation, 2),
            ],
            'shop_performance' => $shopPerformance,
        ], 'Admin business report generated successfully');
    }
}
