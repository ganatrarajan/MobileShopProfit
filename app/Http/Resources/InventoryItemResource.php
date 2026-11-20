<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class InventoryItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $currentStock = $this->recalculateStock();

        $openingStock = (int) ($this->opening_stock ?? 0);

        $purchasedStock = (int) $this->stockMovements()
            ->where('inventory_item_id', $this->id)
            ->where('movement_type', '!=', 'opening_stock')
            ->where('quantity', '>', 0)
            ->sum('quantity');

        $totalStock = max($currentStock, $openingStock + $purchasedStock);

        $firstSerial = $this->relationLoaded('serials')
            ? $this->serials->first()
            : $this->serials()->first();

        return [
            'id' => $this->id,
            'shop_id' => $this->shop_id,
            'name' => $this->name,
            'category' => $this->category,
            'brand' => $this->brand,
            'model' => $this->model,
            'sku' => $this->sku,
            'item_type' => $this->item_type,
            'purchase_price' => (float) $this->purchase_price,
            'selling_price' => (float) $this->selling_price,
            'tax_rate' => (float) ($this->tax_rate ?? 0),
            'tax_type' => $this->tax_type ?? 'exclusive',
            'opening_stock' => $openingStock,
            'total_stock' => $totalStock,
            'current_stock' => $currentStock,
            'minimum_stock' => $this->minimum_stock,
            'unit' => $this->unit,
            'description' => $this->description,
            'is_active' => $this->is_active,
            'stock_value' => (float) ($currentStock * $this->purchase_price),
            'is_low_stock' => $currentStock <= $this->minimum_stock && $currentStock > 0,
            'is_out_of_stock' => $currentStock <= 0,
            'imei1' => $firstSerial?->imei1,
            'imei2' => $firstSerial?->imei2,
            'serial_number' => $firstSerial?->serial_number,
            'serials' => $this->relationLoaded('serials')
                ? $this->serials->map(fn($s) => [
                    'id' => $s->id,
                    'imei1' => $s->imei1,
                    'imei2' => $s->imei2,
                    'serial_number' => $s->serial_number,
                    'status' => $s->status,
                ])
                : ($firstSerial ? [[
                    'id' => $firstSerial->id,
                    'imei1' => $firstSerial->imei1,
                    'imei2' => $firstSerial->imei2,
                    'serial_number' => $firstSerial->serial_number,
                    'status' => $firstSerial->status,
                ]] : []),
            'stock_movements' => StockMovementResource::collection($this->whenLoaded('stockMovements')),
            'created_at' => $this->created_at ? $this->created_at->format('d M Y') : null,
        ];
    }
}