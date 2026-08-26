<?php

namespace App\Services\BusinessAssistant;

use App\Models\Expense;
use App\Models\InventoryItem;
use App\Models\Repair;
use App\Models\Sale;
use App\Models\SaleItem;
use App\Models\Warranty;
use App\Models\WarrantyClaim;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class BusinessAssistantService
{
    /**
     * Get top actionable business recommendations for a given shop.
     * Limit: max 5 recommendations sorted by priority (high -> medium -> low).
     */
    public function getRecommendations(int $shopId): array
    {
        $recommendations = [];

        // 1. Payment Pending Recommendation (🔴 High)
        $paymentRec = $this->getPaymentPendingRecommendation($shopId);
        if ($paymentRec) {
            $recommendations[] = $paymentRec;
        }

        // 2. Warranty / Rework Issue Recommendation (🔴 High)
        $warrantyRec = $this->getWarrantyIssueRecommendation($shopId);
        if ($warrantyRec) {
            $recommendations[] = $warrantyRec;
        }

        // 3. Money Blocked in Stock Recommendation (🟠 Medium)
        $moneyBlockedRec = $this->getMoneyBlockedRecommendation($shopId);
        if ($moneyBlockedRec) {
            $recommendations[] = $moneyBlockedRec;
        }

        // 4. Slow Stock Item Recommendation (🟠 Medium)
        $slowStockRec = $this->getSlowStockRecommendation($shopId);
        if ($slowStockRec) {
            $recommendations[] = $slowStockRec;
        }

        // 5. Repair Pricing Review Recommendation (🟠 Medium)
        $repairPriceRec = $this->getRepairPricingRecommendation($shopId);
        if ($repairPriceRec) {
            $recommendations[] = $repairPriceRec;
        }

        // 6. Expense Increase Recommendation (🟡 Medium)
        $expenseRec = $this->getExpenseIncreaseRecommendation($shopId);
        if ($expenseRec) {
            $recommendations[] = $expenseRec;
        }

        // 7. Fast Selling Product Recommendation (🟢 Low)
        $fastStockRec = $this->getFastSellingRecommendation($shopId);
        if ($fastStockRec) {
            $recommendations[] = $fastStockRec;
        }

        // 8. Cross-Sell Opportunity Recommendation (💡 Low)
        $crossSellRec = $this->getCrossSellRecommendation($shopId);
        if ($crossSellRec) {
            $recommendations[] = $crossSellRec;
        }

        // Sort by priority rank: high (1), medium (2), low (3)
        usort($recommendations, function ($a, $b) {
            $rankMap = ['high' => 1, 'medium' => 2, 'low' => 3];
            $rankA = $rankMap[$a['priority']] ?? 99;
            $rankB = $rankMap[$b['priority']] ?? 99;
            return $rankA <=> $rankB;
        });

        // Limit to max 5 recommendations for main screen
        $topRecommendations = array_slice($recommendations, 0, 5);

        $hasData = count($topRecommendations) > 0;

        return [
            'has_sufficient_data' => $hasData,
            'has_enough_data' => $hasData,
            'notice' => $hasData ? null : 'Keep using the app. We need more sales and shop data before we can suggest the best actions for your business.',
            'message' => $hasData ? 'Success' : 'Keep using the app. We need more sales and shop data before we can suggest the best actions for your business.',
            'total_actions_count' => count($topRecommendations),
            'total_count' => count($topRecommendations),
            'attention_count' => count($topRecommendations),
            'items' => $topRecommendations,
            'recommendations' => $topRecommendations,
        ];
    }

    /**
     * 1. Check pending customer payment dues.
     */
    private function getPaymentPendingRecommendation(int $shopId): ?array
    {
        $salesDuesQuery = Sale::forShop($shopId)->where('payment_status', '!=', 'paid')->where('amount_due', '>', 0);
        $totalPending = (float) (clone $salesDuesQuery)->sum('amount_due');
        $customerCount = (int) (clone $salesDuesQuery)->whereNotNull('customer_id')->distinct('customer_id')->count('customer_id');

        if ($totalPending <= 0) {
            return null;
        }

        $custStr = $customerCount > 0 ? "{$customerCount} customer" . ($customerCount > 1 ? "s have" : " has") . " most of this pending amount." : "Multiple sales have balance payments pending.";

        return [
            'id' => 'rec_payment_pending',
            'priority' => 'high',
            'priority_badge' => '🔴 High',
            'type' => 'payment',
            'title' => 'COLLECT PAYMENT',
            'short_message' => '₹' . number_format($totalPending, 0) . ' is still pending from customer sales.',
            'reason' => $custStr,
            'suggested_action' => 'Contact these customers first to clear balance dues.',
            'potential_benefit' => 'Potential benefit: ₹' . number_format($totalPending, 0),
            'action_type' => 'navigate',
            'action_button_text' => 'View Pending Payments',
            'button_text' => 'View Pending Payments',
            'route' => '/sales',
            'action_route' => '/sales',
        ];
    }

    /**
     * 2. High warranty return rate on repairs/sales.
     */
    private function getWarrantyIssueRecommendation(int $shopId): ?array
    {
        $claimsCount = WarrantyClaim::whereHas('warranty', function ($q) use ($shopId) {
            $q->where('shop_id', $shopId);
        })->count();

        if ($claimsCount < 1) {
            return null;
        }

        // Find warranty with highest claims
        $problemWarranty = Warranty::forShop($shopId)
            ->withCount('claims')
            ->having('claims_count', '>=', 2)
            ->orderBy('claims_count', 'desc')
            ->first();

        if (!$problemWarranty) {
            return null;
        }

        $name = $problemWarranty->device ? ($problemWarranty->device->brand . ' ' . $problemWarranty->device->model) : 'Device repairs';

        return [
            'id' => 'rec_warranty_issue_' . $problemWarranty->id,
            'priority' => 'high',
            'priority_badge' => '🔴 High',
            'type' => 'warranty',
            'title' => 'WARRANTY ISSUE',
            'short_message' => "{$name} has {$problemWarranty->claims_count} warranty claims registered.",
            'reason' => 'This return rate is higher than your usual warranty average.',
            'suggested_action' => 'Check the spare part quality or repair assembly process.',
            'potential_benefit' => 'Potential benefit: Avoid repeated repair reworks & cost.',
            'action_type' => 'navigate',
            'action_button_text' => 'View Warranty',
            'route' => '/warranties',
        ];
    }

    /**
     * 3. Total Money blocked in slow moving stock (>60 days).
     */
    private function getMoneyBlockedRecommendation(int $shopId): ?array
    {
        $slowItems = InventoryItem::forShop($shopId)
            ->where('current_stock', '>', 0)
            ->where(function ($q) {
                $q->where('updated_at', '<=', Carbon::now()->subDays(60))
                  ->orWhere('created_at', '<=', Carbon::now()->subDays(60));
            })
            ->get();

        $totalBlocked = 0;
        foreach ($slowItems as $item) {
            $totalBlocked += ($item->current_stock * (float) $item->purchase_price);
        }

        if ($totalBlocked < 5000) {
            return null;
        }

        return [
            'id' => 'rec_money_blocked',
            'priority' => 'medium',
            'priority_badge' => '🟠 Medium',
            'type' => 'money_blocked',
            'title' => 'MONEY BLOCKED IN STOCK',
            'short_message' => '₹' . number_format($totalBlocked, 0) . ' is sitting in products that are selling very slowly.',
            'reason' => count($slowItems) . ' inventory items have shown minimal sales movement over the last 60 days.',
            'suggested_action' => 'Consider clearing some of this stock with small discounts or bundle offers.',
            'potential_benefit' => 'Potential estimated capital release: ₹' . number_format($totalBlocked, 0),
            'action_type' => 'navigate',
            'action_button_text' => 'View Inventory',
            'route' => '/inventory',
        ];
    }

    /**
     * 4. Specific slow moving stock item.
     */
    private function getSlowStockRecommendation(int $shopId): ?array
    {
        $slowItem = InventoryItem::forShop($shopId)
            ->where('current_stock', '>=', 5)
            ->where('purchase_price', '>', 0)
            ->where('updated_at', '<=', Carbon::now()->subDays(45))
            ->orderBy(DB::raw('current_stock * purchase_price'), 'desc')
            ->first();

        if (!$slowItem) {
            return null;
        }

        $moneyBlocked = $slowItem->current_stock * (float) $slowItem->purchase_price;

        return [
            'id' => 'rec_slow_stock_' . $slowItem->id,
            'priority' => 'medium',
            'priority_badge' => '🟠 Medium',
            'type' => 'slow_stock',
            'title' => 'SLOW STOCK',
            'short_message' => "{$slowItem->current_stock} units of {$slowItem->name} are still in stock.",
            'reason' => 'They have sold very slowly recently. Money blocked: ₹' . number_format($moneyBlocked, 0),
            'suggested_action' => 'Try a small offer or bundle them with a fast-selling accessory.',
            'potential_benefit' => 'Potential benefit: Clear ₹' . number_format($moneyBlocked, 0) . ' tied capital.',
            'action_type' => 'navigate',
            'action_button_text' => 'View Stock',
            'route' => '/inventory',
        ];
    }

    /**
     * 5. Repair pricing review.
     */
    private function getRepairPricingRecommendation(int $shopId): ?array
    {
        // Find repair models with lower average cost/profit
        $repairs = Repair::forShop($shopId)
            ->whereIn('repair_status', ['delivered', 'completed'])
            ->where('final_cost', '>', 0)
            ->get();

        if ($repairs->count() < 3) {
            return null;
        }

        $overallAvg = $repairs->avg('final_cost');

        // Group by problem_description
        $grouped = $repairs->groupBy('problem_description');

        foreach ($grouped as $problem => $group) {
            if ($group->count() >= 2) {
                $groupAvg = $group->avg('final_cost');
                if ($groupAvg < ($overallAvg * 0.85)) {
                    $suggestedMin = round($groupAvg * 1.15, -2);
                    $suggestedMax = round($groupAvg * 1.30, -2);

                    return [
                        'id' => 'rec_repair_pricing_' . md5($problem),
                        'priority' => 'medium',
                        'priority_badge' => '🟠 Medium',
                        'type' => 'repair_pricing',
                        'title' => 'REVIEW REPAIR PRICE',
                        'short_message' => "'{$problem}' repairs are giving lower profit than your overall shop average.",
                        'reason' => 'Your average price: ₹' . number_format($groupAvg, 0) . '. Usual shop repair range: ₹' . number_format($suggestedMin, 0) . '–₹' . number_format($suggestedMax, 0),
                        'suggested_action' => 'Review your repair charge before taking the next job.',
                        'potential_benefit' => 'Potential margin improvement: +15-20% per repair',
                        'action_type' => 'navigate',
                        'action_button_text' => 'View Repairs',
                        'route' => '/repairs',
                    ];
                }
            }
        }

        return null;
    }

    /**
     * 6. Consecutive month-over-month expense increase in category.
     */
    private function getExpenseIncreaseRecommendation(int $shopId): ?array
    {
        $now = Carbon::now();
        $m1Start = $now->copy()->startOfMonth();
        $m2Start = $now->copy()->subMonth()->startOfMonth();
        $m2End = $now->copy()->subMonth()->endOfMonth();
        $m3Start = $now->copy()->subMonths(2)->startOfMonth();
        $m3End = $now->copy()->subMonths(2)->endOfMonth();

        $expenses = Expense::forShop($shopId)->with('category')->get();
        if ($expenses->count() < 3) {
            return null;
        }

        $byCategory = $expenses->groupBy('category_id');

        foreach ($byCategory as $catId => $catExpenses) {
            $m3 = (float) $catExpenses->whereBetween('expense_date', [$m3Start, $m3End])->sum('amount');
            $m2 = (float) $catExpenses->whereBetween('expense_date', [$m2Start, $m2End])->sum('amount');
            $m1 = (float) $catExpenses->where('expense_date', '>=', $m1Start)->sum('amount');

            if ($m3 > 0 && $m2 > $m3 && $m1 > $m2) {
                $catName = $catExpenses->first()->category?->name ?? 'Shop';
                return [
                    'id' => 'rec_expense_increase_' . $catId,
                    'priority' => 'medium',
                    'priority_badge' => '🟡 Medium',
                    'type' => 'expense',
                    'title' => 'EXPENSE INCREASE',
                    'short_message' => "{$catName} expense has increased over recent months.",
                    'reason' => 'Expense trend: ₹' . number_format($m3, 0) . ' → ₹' . number_format($m2, 0) . ' → ₹' . number_format($m1, 0),
                    'suggested_action' => 'Review this expense category before it increases further.',
                    'potential_benefit' => 'Potential savings: Keep operational costs under control.',
                    'action_type' => 'navigate',
                    'action_button_text' => 'View Expenses',
                    'route' => '/expenses',
                ];
            }
        }

        return null;
    }

    /**
     * 7. Product selling fast with low remaining stock.
     */
    private function getFastSellingRecommendation(int $shopId): ?array
    {
        $fastItem = InventoryItem::forShop($shopId)
            ->where('current_stock', '>', 0)
            ->where('current_stock', '<=', 15)
            ->where('minimum_stock', '>', 0)
            ->orderBy('current_stock', 'asc')
            ->first();

        if (!$fastItem) {
            return null;
        }

        // Count recent sales quantity
        $soldRecent = (int) SaleItem::whereHas('sale', function ($q) use ($shopId) {
            $q->where('shop_id', $shopId)->where('sale_date', '>=', Carbon::now()->subDays(30));
        })->where('product_name', $fastItem->name)->sum('quantity');

        if ($soldRecent < 2) {
            return null;
        }

        return [
            'id' => 'rec_fast_selling_' . $fastItem->id,
            'priority' => 'low',
            'priority_badge' => '🟢 Selling Fast',
            'type' => 'fast_stock',
            'title' => 'SELLING FAST',
            'short_message' => "{$fastItem->name} is selling quickly ({$soldRecent} sold recently).",
            'reason' => "Current stock left: {$fastItem->current_stock} units.",
            'suggested_action' => 'Consider reordering stock soon to avoid out-of-stock lost sales.',
            'potential_benefit' => 'Potential benefit: Prevent lost sales opportunity.',
            'action_type' => 'navigate',
            'action_button_text' => 'View Product',
            'route' => '/inventory',
        ];
    }

    /**
     * 8. Cross-Sell Opportunity based on sales history.
     */
    private function getCrossSellRecommendation(int $shopId): ?array
    {
        // Find sales with multiple items
        $multiItemSaleIds = SaleItem::whereHas('sale', function ($q) use ($shopId) {
            $q->where('shop_id', $shopId);
        })->select('sale_id')
          ->groupBy('sale_id')
          ->having(DB::raw('COUNT(*)'), '>=', 2)
          ->take(50)
          ->pluck('sale_id');

        if ($multiItemSaleIds->count() < 2) {
            return null;
        }

        $pairs = [];
        foreach ($multiItemSaleIds as $sId) {
            $names = SaleItem::where('sale_id', $sId)->pluck('product_name')->toArray();
            sort($names);
            $count = count($names);
            for ($i = 0; $i < $count; $i++) {
                for ($j = $i + 1; $j < $count; $j++) {
                    $pairKey = $names[$i] . '|||' . $names[$j];
                    $pairs[$pairKey] = ($pairs[$pairKey] ?? 0) + 1;
                }
            }
        }

        if (empty($pairs)) {
            return null;
        }

        arsort($pairs);
        $bestPairKey = key($pairs);
        $occurrences = current($pairs);

        if ($occurrences < 2) {
            return null;
        }

        $parts = explode('|||', $bestPairKey);
        $prodA = $parts[0] ?? 'Screen Guard';
        $prodB = $parts[1] ?? 'Cover';

        return [
            'id' => 'rec_cross_sell_' . md5($bestPairKey),
            'priority' => 'low',
            'priority_badge' => '💡 Recommendation',
            'type' => 'cross_sell',
            'title' => 'SELL MORE',
            'short_message' => "Customers who buy {$prodA} often buy {$prodB}.",
            'reason' => "Based on actual shop sales history ({$occurrences} times purchased together).",
            'suggested_action' => "Offer a {$prodB} whenever a customer purchases a {$prodA}.",
            'potential_benefit' => 'Potential benefit: Higher average sale amount per customer.',
            'action_type' => 'navigate',
            'action_button_text' => 'View Products',
            'route' => '/inventory',
        ];
    }
}
