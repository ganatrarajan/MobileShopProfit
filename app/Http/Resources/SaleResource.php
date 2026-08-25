<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SaleResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'shop_id' => $this->shop_id,
            'sale_type' => $this->sale_type ?? 'regular',
            'customer_name' => $this->customer_name,
            'customer_mobile' => $this->customer_mobile,
            'customer_id' => $this->customer_id,
            'device_id' => $this->device_id,
            'invoice_number' => $this->invoice_number,
            'sale_date' => $this->sale_date?->toIso8601String(),
            'subtotal' => (float) $this->subtotal,
            'discount' => (float) $this->discount,
            'total_discount' => (float) ($this->discount + ($this->items ? $this->items->sum('discount') : 0)),
            'tax_amount' => (float) $this->tax_amount,
            'grand_total' => (float) $this->grand_total,
            'amount_paid' => (float) $this->amount_paid,
            'amount_due' => (float) $this->amount_due,
            'payment_status' => $this->payment_status,
            'notes' => $this->notes,
            'created_by' => $this->created_by,
            'creator_name' => $this->creator?->name,
            'customer' => $this->whenLoaded('customer', function () {
                return new CustomerResource($this->customer);
            }),
            'device' => $this->whenLoaded('device', function () {
                return new DeviceResource($this->device);
            }),
            'items' => SaleItemResource::collection($this->whenLoaded('items')),
            'payments' => SalePaymentResource::collection($this->whenLoaded('payments')),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}