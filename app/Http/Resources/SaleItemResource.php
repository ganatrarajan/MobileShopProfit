<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SaleItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'sale_id' => $this->sale_id,
            'product_name' => $this->product_name,
            'item_type' => $this->item_type,
            'brand' => $this->brand,
            'model' => $this->model,
            'imei_1' => $this->imei_1,
            'imei_2' => $this->imei_2,
            'serial_number' => $this->serial_number,
            'quantity' => (int) $this->quantity,
            'unit_price' => (float) $this->unit_price,
            'discount' => (float) $this->discount,
            'tax_amount' => (float) $this->tax_amount,
            'cost_price' => $this->cost_price !== null ? (float) $this->cost_price : null,
            'total' => (float) $this->total,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}