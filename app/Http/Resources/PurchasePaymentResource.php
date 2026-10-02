<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PurchasePaymentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'shop_id' => $this->shop_id,
            'purchase_id' => $this->purchase_id,
            'vendor_id' => $this->vendor_id,
            'amount' => round((float) $this->amount, 2),
            'payment_date' => $this->payment_date?->format('Y-m-d'),
            'payment_method' => $this->payment_method,
            'notes' => $this->notes,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
