<?php

namespace App\Services\ProfitIntelligence;

use App\Models\InventoryItem;

class ProductAnalysisService
{
    public function analyze(int $shopId): array
    {
        $items = InventoryItem::where('shop_id', $shopId)->get();

        if ($items->count() < 3) {
            return [
                'has_enough_data' => false,
                'message' => 'Not enough inventory data yet (need at least 3 items).',
                'low_margin_count' => 0,
                'details' => [],
            ];
        }

        $lowMargin = [];

        foreach ($items as $item) {
            $sell = (float) $item->selling_price;
            $cost = (float) $item->purchase_price;

            if ($sell > 0 && $cost > 0) {
                $margin = (($sell - $cost) / $sell) * 100;
                if ($margin < 15.0) { // Less than 15% profit margin
                    $lowMargin[] = [
                        'id' => $item->id,
                        'name' => $item->name,
                        'category' => $item->category,
                        'purchase_price' => round($cost, 2),
                        'selling_price' => round($sell, 2),
                        'profit_per_unit' => round($sell - $cost, 2),
                        'margin_percentage' => round($margin, 1),
                        'suggestion' => "Margin is only " . round($margin, 1) . "%. Increase selling price to ₹" . number_format(ceil($cost * 1.25), 0) . " to achieve a healthy 20%+ margin.",
                    ];
                }
            }
        }

        return [
            'has_enough_data' => true,
            'low_margin_count' => count($lowMargin),
            'details' => $lowMargin,
        ];
    }
}