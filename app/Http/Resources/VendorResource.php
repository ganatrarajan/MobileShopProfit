<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class VendorResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'shop_id' => $this->shop_id,
            'name' => $this->name,
            'phone' => $this->phone,
            'email' => $this->email,
            'address' => $this->address,
            'gst_number' => $this->gst_number,
            'notes' => $this->notes,
            'total_purchase' => round($this->total_purchase, 2),
            'total_paid' => round($this->total_paid, 2),
            'outstanding_amount' => round($this->outstanding_amount, 2),
            'purchases_count' => $this->whenCounted('purchases', $this->purchases_count),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
