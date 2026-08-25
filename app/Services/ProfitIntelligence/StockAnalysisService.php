<?php

namespace App\Services\ProfitIntelligence;

use App\Models\InventoryItem;
use App\Models\SaleItem;
use App\Models\StockMovement;
use Carbon\Carbon;

class StockAnalysisService
{
    public function analyze(int $shopId): array
    {
        $items = InventoryItem::where('shop_id', $shopId)->get();

        if ($items->count() < 3) {
            return [
                'has_enough_data' => false,
                'message' => 'Not enough inventory data yet (need at least 3 items).',
                'slow_moving_count' => 0,
                'slow_moving_value' => 0.0,
                'dead_stock_count' => 0,
                'dead_stock_value' => 0.0,
                'slow_moving_details' => [],
                'dead_stock_details' => [],
            ];
        }

        $slowMoving = [];
        $deadStock = [];
        $slowValue = 0.0;
        $deadValue = 0.0;

        $now = Carbon::now();

        foreach ($items as $item) {
            $stock = $item->recalculateStock();
            if ($stock <= 0) {
                continue;
            }

            // Find last sale date
            $lastSaleMovement = StockMovement::where('inventory_item_id', $item->id)
                ->where('movement_type', 'sale')
                ->latest('created_at')
                ->first();

            $lastSaleDate = $lastSaleMovement ? $lastSaleMovement->created_at : $item->created_at;
            $daysSinceSale = $lastSaleDate ? $now->diffInDays($lastSaleDate) : 100;

            $val = $stock * (float) $item->purchase_price;

            if ($daysSinceSale >= 180) {
                $deadValue += $val;
                $deadStock[] = [
                    'id' => $item->id,
                    'name' => $item->name,
                    'category' => $item->category,
                    'current_stock' => $stock,
                    'purchase_price' => (float) $item->purchase_price,
                    'stock_value' => round($val, 2),
                    'days_inactive' => $daysSinceSale,
                    'suggestion' => "No sales in {$daysSinceSale} days. Consider liquidating at cost price (₹" . number_format($item->purchase_price, 0) . ") to recover capital.",
                ];
            } elseif ($daysSinceSale >= 90) {
                $slowValue += $val;
                $slowMoving[] = [
                    'id' => $item->id,
                    'name' => $item->name,
                    'category' => $item->category,
                    'current_stock' => $stock,
                    'purchase_price' => (float) $item->purchase_price,
                    'stock_value' => round($val, 2),
                    'days_inactive' => $daysSinceSale,
                    'suggestion' => "No sales in {$daysSinceSale} days. Offer a 15% discount or bundle with fast-selling items to accelerate movement.",
                ];
            }
        }

        return [
            'has_enough_data' => true,
            'slow_moving_count' => count($slowMoving),
            'slow_moving_value' => round($slowValue, 2),
            'dead_stock_count' => count($deadStock),
            'dead_stock_value' => round($deadValue, 2),
            'slow_moving_details' => $slowMoving,
            'dead_stock_details' => $deadStock,
        ];
    }
}