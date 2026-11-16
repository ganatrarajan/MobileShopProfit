<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Repair;
use App\Models\Sale;
use App\Models\UsedMobile;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class ProfitLedgerController extends Controller
{
    /**
     * Get consolidated profit ledger records across Sales, Repairs, and Used Mobiles.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        if (!$shopId) {
            return response()->json([
                'success' => false,
                'message' => 'No active shop associated with user.',
            ], 400);
        }

        $period = $request->input('period', 'this_month');
        $category = $request->input('category', 'all'); // 'all', 'sales', 'repairs', 'used_mobiles'
        $search = trim($request->input('search', ''));
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
        } elseif ($period === 'this_year') {
            $startDate = $now->copy()->startOfYear();
            $endDate = $now->copy()->endOfYear();
        } elseif ($period === 'all_time') {
            $startDate = Carbon::create(2020, 1, 1)->startOfDay();
            $endDate = $now->copy()->addYear()->endOfDay();
        } elseif ($period === 'custom' && $request->filled('start_date') && $request->filled('end_date')) {
            $startDate = Carbon::parse($request->input('start_date'))->startOfDay();
            $endDate = Carbon::parse($request->input('end_date'))->endOfDay();
        } else { // this_month (default)
            $startDate = $now->copy()->startOfMonth();
            $endDate = $now->copy()->endOfMonth();
        }

        $sDateStr = $startDate->format('Y-m-d');
        $eDateStr = $endDate->format('Y-m-d');

        $items = [];
        $totalSalesProfit = 0.0;
        $totalRepairProfit = 0.0;
        $totalUsedMobileProfit = 0.0;
        $totalSalesRevenue = 0.0;
        $totalRepairRevenue = 0.0;
        $totalUsedMobileRevenue = 0.0;
        $totalSalesCost = 0.0;
        $totalRepairCost = 0.0;
        $totalUsedMobileCost = 0.0;
        $salesCount = 0;
        $repairCount = 0;
        $usedMobileCount = 0;

        // 1. Fetch Sales Profits
        if ($category === 'all' || $category === 'sales') {
            $salesQuery = Sale::forShop($shopId)
                ->whereBetween('sale_date', [$sDateStr, $eDateStr])
                ->with(['items.inventoryItem', 'customer']);

            $sales = $salesQuery->get();

            foreach ($sales as $sale) {
                $costSum = 0.0;
                $itemNames = [];

                foreach ($sale->items as $item) {
                    $itemCost = (float)($item->cost_price ?: ($item->inventoryItem?->purchase_price ?: 0));
                    $costSum += $itemCost * (int)$item->quantity;
                    $name = $item->item_name ?: ($item->inventoryItem?->name ?: 'Item');
                    $itemNames[] = "{$name} (x{$item->quantity})";
                }

                $paid = (float)$sale->amount_paid;
                $grandTotal = (float)$sale->grand_total;
                // Realized Net profit strictly based on amountPaid vs Cost
                $profit = max(0.0, round($paid - $costSum, 2));
                $margin = $paid > 0 && $profit > 0 ? round(($profit / $paid) * 100, 1) : 0;

                $totalSalesProfit += $profit;
                $totalSalesRevenue += $grandTotal;
                $totalSalesCost += $costSum;
                $salesCount++;

                $items[] = [
                    'id' => $sale->id,
                    'type' => 'sale',
                    'type_label' => 'Sale',
                    'ref_number' => $sale->invoice_number ?: "INV-{$sale->id}",
                    'title' => !empty($itemNames) ? implode(', ', array_slice($itemNames, 0, 3)) : 'Invoice Sale',
                    'customer_name' => $sale->customer_name ?: ($sale->customer?->name ?: 'Walk-in Customer'),
                    'customer_phone' => $sale->customer_mobile ?: ($sale->customer?->phone ?: ''),
                    'date' => $sale->sale_date ? Carbon::parse($sale->sale_date)->toIso8601String() : $sale->created_at->toIso8601String(),
                    'formatted_date' => $sale->sale_date ? Carbon::parse($sale->sale_date)->format('d M Y, h:i A') : $sale->created_at->format('d M Y'),
                    'revenue' => round($grandTotal, 2),
                    'amount_paid' => round($paid, 2),
                    'cost' => round($costSum, 2),
                    'profit' => round($profit, 2),
                    'profit_margin' => $margin,
                    'status' => $sale->payment_status ?: 'paid',
                    'cost_breakdown' => "Stock Cost: ₹" . number_format($costSum, 0),
                ];
            }
        }

        // 2. Fetch Repair Profits
        if ($category === 'all' || $category === 'repairs') {
            $repairsQuery = Repair::forShop($shopId)
                ->whereBetween('date_received', [$sDateStr, $eDateStr])
                ->with(['parts', 'device', 'customer']);

            $repairs = $repairsQuery->get();

            foreach ($repairs as $repair) {
                $partsCost = 0.0;
                $partsNames = [];
                foreach ($repair->parts as $part) {
                    $pCost = (float)($part->cost_price ?: $part->selling_price);
                    $partsCost += $pCost * (int)$part->quantity;
                    if (!empty($part->part_name)) {
                        $partsNames[] = $part->part_name;
                    }
                }

                $techFee = (float)($repair->technician_earning ?: $repair->labour_cost);
                $totalCost = $partsCost + $techFee;
                $effectiveRevenue = (float)$repair->amount_paid;
                if ($effectiveRevenue <= 0) {
                    $effectiveRevenue = (float)($repair->final_cost > 0 ? $repair->final_cost : $repair->estimated_cost);
                }

                $profit = max(0.0, round($repair->amount_paid - $totalCost, 2));
                $margin = $repair->amount_paid > 0 && $profit > 0 ? round(($profit / $repair->amount_paid) * 100, 1) : 0;

                $deviceStr = ($repair->device?->brand || $repair->device?->model)
                    ? trim("{$repair->device->brand} {$repair->device->model}")
                    : 'Mobile Device';

                $prob = $repair->problem_description ? " - {$repair->problem_description}" : '';

                $totalRepairProfit += $profit;
                $totalRepairRevenue += (float)($repair->final_cost > 0 ? $repair->final_cost : $repair->estimated_cost);
                $totalRepairCost += $totalCost;
                $repairCount++;

                $items[] = [
                    'id' => $repair->id,
                    'type' => 'repair',
                    'type_label' => 'Repair',
                    'ref_number' => $repair->job_number ?: "REP-{$repair->id}",
                    'title' => "{$deviceStr}{$prob}",
                    'customer_name' => $repair->customer?->name ?: ($repair->customer_name ?: 'Customer'),
                    'customer_phone' => $repair->customer?->phone ?: ($repair->customer_phone ?: ''),
                    'date' => $repair->date_received ? Carbon::parse($repair->date_received)->toIso8601String() : $repair->created_at->toIso8601String(),
                    'formatted_date' => $repair->date_received ? Carbon::parse($repair->date_received)->format('d M Y, h:i A') : $repair->created_at->format('d M Y'),
                    'revenue' => round((float)($repair->final_cost > 0 ? $repair->final_cost : $repair->estimated_cost), 2),
                    'amount_paid' => round((float)$repair->amount_paid, 2),
                    'cost' => round($totalCost, 2),
                    'profit' => round($profit, 2),
                    'profit_margin' => $margin,
                    'status' => $repair->repair_status ?: 'completed',
                    'cost_breakdown' => "Parts: ₹" . number_format($partsCost, 0) . ", Tech: ₹" . number_format($techFee, 0),
                ];
            }
        }

        // 3. Fetch Used Mobile Profits
        if (($category === 'all' || $category === 'used_mobiles') && Schema::hasTable('used_mobiles')) {
            $usedMobileQuery = UsedMobile::forShop($shopId)
                ->where('status', 'sold')
                ->whereBetween('sale_date', [$sDateStr, $eDateStr]);

            $usedMobiles = $usedMobileQuery->get();

            foreach ($usedMobiles as $um) {
                $selling = (float)$um->selling_price;
                $cost = (float)$um->total_cost;
                $profit = (float)$um->profit;
                $margin = $cost > 0 && $profit > 0 ? round(($profit / $cost) * 100, 1) : 0;

                $specs = array_filter([$um->ram ? "{$um->ram} RAM" : null, $um->storage ? "{$um->storage}" : null]);
                $specStr = !empty($specs) ? ' (' . implode('/', $specs) . ')' : '';

                $totalUsedMobileProfit += $profit;
                $totalUsedMobileRevenue += $selling;
                $totalUsedMobileCost += $cost;
                $usedMobileCount++;

                $items[] = [
                    'id' => $um->id,
                    'type' => 'used_mobile',
                    'type_label' => 'Used Mobile',
                    'ref_number' => $um->sale_invoice_number ?: ($um->purchase_ref_number ?: "UM-{$um->id}"),
                    'title' => "{$um->brand} {$um->model}{$specStr}",
                    'customer_name' => $um->buyer_name ?: 'Buyer',
                    'customer_phone' => $um->buyer_phone ?: '',
                    'date' => $um->sale_date ? Carbon::parse($um->sale_date)->toIso8601String() : $um->created_at->toIso8601String(),
                    'formatted_date' => $um->sale_date ? Carbon::parse($um->sale_date)->format('d M Y, h:i A') : $um->created_at->format('d M Y'),
                    'revenue' => round($selling, 2),
                    'amount_paid' => round($selling, 2),
                    'cost' => round($cost, 2),
                    'profit' => round($profit, 2),
                    'profit_margin' => $margin,
                    'status' => 'sold',
                    'cost_breakdown' => "Buy: ₹" . number_format($um->purchase_price, 0) . ($um->repair_cost > 0 ? ", Fix: ₹" . number_format($um->repair_cost, 0) : ''),
                ];
            }
        }

        // Apply Search Filtering if query provided
        if (!empty($search)) {
            $sLower = mb_strtolower($search);
            $items = array_filter($items, function ($item) use ($sLower) {
                return (str_contains(mb_strtolower($item['ref_number']), $sLower))
                    || (str_contains(mb_strtolower($item['title']), $sLower))
                    || (str_contains(mb_strtolower($item['customer_name']), $sLower))
                    || (str_contains(mb_strtolower($item['customer_phone']), $sLower));
            });
            $items = array_values($items);
        }

        // Sort combined items by date descending
        usort($items, function ($a, $b) {
            return strcmp($b['date'], $a['date']);
        });

        $totalNetProfit = round($totalSalesProfit + $totalRepairProfit + $totalUsedMobileProfit, 2);
        $totalRevenue = round($totalSalesRevenue + $totalRepairRevenue + $totalUsedMobileRevenue, 2);
        $totalCost = round($totalSalesCost + $totalRepairCost + $totalUsedMobileCost, 2);

        $summaryData = [
            'total_net_profit' => $totalNetProfit,
            'sales_profit' => round($totalSalesProfit, 2),
            'repair_profit' => round($totalRepairProfit, 2),
            'used_mobile_profit' => round($totalUsedMobileProfit, 2),
            'total_revenue' => $totalRevenue,
            'total_cost' => $totalCost,
            'total_count' => count($items),
            'sales_count' => $salesCount,
            'repair_count' => $repairCount,
            'used_mobile_count' => $usedMobileCount,
        ];

        return response()->json([
            'success' => true,
            'period' => $period,
            'category' => $category,
            'date_range' => [
                'start_date' => $sDateStr,
                'end_date' => $eDateStr,
            ],
            'summary' => $summaryData,
            'items' => $items,
            'data' => [
                'period' => $period,
                'category' => $category,
                'date_range' => [
                    'start_date' => $sDateStr,
                    'end_date' => $eDateStr,
                ],
                'summary' => $summaryData,
                'items' => $items,
            ],
        ]);
    }
}

