<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RepairResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'shop_id' => $this->shop_id,
            'customer_id' => $this->customer_id,
            'device_id' => $this->device_id,
            'job_number' => $this->job_number,
            'date_received' => $this->date_received?->format('Y-m-d'),
            'expected_delivery_date' => $this->expected_delivery_date?->format('Y-m-d'),
            'delivered_date' => $this->delivered_date?->toIso8601String(),
            'problem_description' => $this->problem_description,
            'device_condition' => $this->device_condition ?? [],
            'condition_notes' => $this->condition_notes,
            'accessories_received' => $this->accessories_received ?? [],
            'accessories_notes' => $this->accessories_notes,
            'pin_passcode' => $this->pin_passcode,
            'estimated_cost' => (float) $this->estimated_cost,
            'final_cost' => (float) $this->final_cost,
            'labour_cost' => (float) $this->labour_cost,
            'amount_paid' => (float) $this->amount_paid,
            'amount_due' => (float) $this->amount_due,
            'repair_status' => $this->repair_status,
            'customer_notes' => $this->customer_notes,
            'internal_notes' => $this->internal_notes,
            'created_by' => $this->created_by,
            'creator_name' => $this->creator?->name,
            'customer' => $this->whenLoaded('customer', function () {
                return new CustomerResource($this->customer);
            }),
            'device' => $this->whenLoaded('device', function () {
                return new DeviceResource($this->device);
            }),
            'parts' => RepairPartResource::collection($this->whenLoaded('parts')),
            'payments' => RepairPaymentResource::collection($this->whenLoaded('payments')),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}