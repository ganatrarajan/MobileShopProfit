<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SalePaymentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'shop_id' => $this->shop_id,
            'sale_id' => $this->sale_id,
            'amount' => (float) $this->amount,
            'payment_method' => $this->payment_method,
            'payment_date' => $this->payment_date?->toIso8601String(),
            'notes' => $this->notes,
            'created_by' => $this->created_by,
            'creator_name' => $this->creator?->name,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}