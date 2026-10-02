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
            'purchase_rate' => round((float) $this->purchase_rate, 2),
            'total_amount' => round((float) $this->total_amount, 2),
        ];
    }
}
