<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class WarrantyClaimResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'shop_id' => $this->shop_id,
            'warranty_id' => $this->warranty_id,
            'customer_id' => $this->customer_id,
            'device_id' => $this->device_id,
            'claim_number' => $this->claim_number,
            'claim_date' => $this->claim_date?->format('Y-m-d'),
            'complaint' => $this->complaint,
            'claim_status' => $this->claim_status,
            'resolution' => $this->resolution,
            'notes' => $this->notes,
            'resolved_at' => $this->resolved_at?->toIso8601String(),
            'created_by' => $this->created_by,
            'creator_name' => $this->creator?->name,
            'customer' => $this->whenLoaded('customer', function () {
                return new CustomerResource($this->customer);
            }),
            'device' => $this->whenLoaded('device', function () {
                return new DeviceResource($this->device);
            }),
            'warranty' => $this->whenLoaded('warranty', function () {
                return new WarrantyResource($this->warranty);
            }),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}