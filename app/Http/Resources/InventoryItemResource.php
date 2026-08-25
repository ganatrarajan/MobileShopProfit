<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class InventoryItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $currentStock = $this->recalculateStock();

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
            'opening_stock' => (int) ($this->opening_stock ?? $currentStock),
            'total_stock' => (int) ($this->opening_stock ?? $currentStock),
            'current_stock' => $currentStock,
            'minimum_stock' => $this->minimum_stock,
            'unit' => $this->unit,
            'description' => $this->description,
            'is_active' => $this->is_active,
            'stock_value' => (float) ($currentStock * $this->purchase_price),
            'is_low_stock' => $currentStock <= $this->minimum_stock && $currentStock > 0,
            'is_out_of_stock' => $currentStock <= 0,
            'serials' => $this->whenLoaded('serials', function() {
                return $this->serials->map(fn($s) => [
                    'id' => $s->id,
                    'imei1' => $s->imei1,
                    'imei2' => $s->imei2,
                    'serial_number' => $s->serial_number,
                    'status' => $s->status,
                ]);
            }),
            'stock_movements' => StockMovementResource::collection($this->whenLoaded('stockMovements')),
            'created_at' => $this->created_at ? $this->created_at->format('d M Y') : null,
        ];
    }
}
