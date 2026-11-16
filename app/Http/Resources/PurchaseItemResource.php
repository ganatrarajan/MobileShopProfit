<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PurchaseItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'purchase_id' => $this->purchase_id,
            'inventory_item_id' => $this->inventory_item_id,
            'item_name' => $this->inventoryItem?->name ?? 'Deleted Item',
            'item_category' => $this->inventoryItem?->category,
            'sku' => $this->inventoryItem?->sku,
            'quantity' => (int) $this->quantity,
            'imei1' => $this->imei1,
            'imei2' => $this->imei2,
            'current_stock' => (int) ($this->inventoryItem?->current_stock ?? 0),
            'purchase_rate' => round((float) $this->purchase_rate, 2),
            'tax_amount' => round((float) ($this->tax_amount ?? 0), 2),
            'tax_rate' => round((float) ($this->tax_rate ?? 0), 2),
            'tax_type' => $this->tax_type ?? 'exclusive',
            'total_amount' => round((float) $this->total_amount, 2),
        ];
    }
}
