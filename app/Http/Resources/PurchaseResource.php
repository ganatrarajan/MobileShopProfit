<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PurchaseResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'shop_id' => $this->shop_id,
            'vendor_id' => $this->vendor_id,
            'vendor' => new VendorResource($this->whenLoaded('vendor')),
            'vendor_name' => $this->vendor?->name ?? 'Unknown Vendor',
            'purchase_number' => $this->purchase_number,
            'purchase_date' => $this->purchase_date?->format('Y-m-d'),
            'subtotal' => round((float) $this->subtotal, 2),
            'discount' => round((float) $this->discount, 2),
            'additional_charges' => round((float) $this->additional_charges, 2),
            'grand_total' => round((float) $this->grand_total, 2),
            'amount_paid' => round((float) $this->amount_paid, 2),
            'outstanding_amount' => round((float) $this->outstanding_amount, 2),
            'payment_status' => $this->payment_status,
            'is_stock_added' => (bool) $this->is_stock_added,
            'notes' => $this->notes,
            'items' => PurchaseItemResource::collection($this->whenLoaded('items')),
            'payments' => PurchasePaymentResource::collection($this->whenLoaded('payments')),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
