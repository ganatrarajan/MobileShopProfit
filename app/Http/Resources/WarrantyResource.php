<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class WarrantyResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'shop_id' => $this->shop_id,
            'customer_id' => $this->customer_id,
            'device_id' => $this->device_id,
            'sale_id' => $this->sale_id,
            'repair_id' => $this->repair_id,
            'warranty_number' => $this->warranty_number,
            'warranty_type' => $this->warranty_type,
            'warranty_start_date' => $this->warranty_start_date?->format('Y-m-d'),
            'warranty_end_date' => $this->warranty_end_date?->format('Y-m-d'),
            'duration_days' => (int) $this->duration_days,
            'warranty_terms' => $this->warranty_terms,
            'status' => $this->computed_status,
            'stored_status' => $this->status,
            'days_remaining' => $this->days_remaining,
            'notes' => $this->notes,
            'created_by' => $this->created_by,
            'creator_name' => $this->creator?->name,
            'claims_count' => $this->whenCounted('claims', $this->claims_count, function () {
                return $this->claims()->count();
            }),
            'customer' => $this->whenLoaded('customer', function () {
                return new CustomerResource($this->customer);
            }),
            'device' => $this->whenLoaded('device', function () {
                return new DeviceResource($this->device);
            }),
            'sale' => $this->whenLoaded('sale', function () {
                return new SaleResource($this->sale);
            }),
            'repair' => $this->whenLoaded('repair', function () {
                return new RepairResource($this->repair);
            }),
            'claims' => WarrantyClaimResource::collection($this->whenLoaded('claims')),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}