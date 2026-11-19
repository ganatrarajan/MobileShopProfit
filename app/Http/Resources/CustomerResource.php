<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CustomerResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $salesTotal = (float) ($this->sales_total ?? 0);
        $repairsTotal = (float) ($this->repairs_total ?? 0);
        $salesDue = (float) ($this->sales_due ?? 0);
        $repairsDue = (float) ($this->repairs_due ?? 0);

        return [
            'id'               => $this->id,
            'shop_id'          => $this->shop_id,
            'name'             => $this->name,
            'mobile'           => $this->mobile,
            'phone'            => $this->mobile,
            'alternate_mobile' => $this->alternate_mobile,
            'email'            => $this->email,
            'address'          => $this->address,
            'city'             => $this->city,
            'notes'            => $this->notes,
            'repairs_count'    => (int) ($this->repairs_count ?? ($this->relationLoaded('repairs') ? $this->repairs->count() : 0)),
            'sales_count'      => (int) ($this->sales_count ?? ($this->relationLoaded('sales') ? $this->sales->count() : 0)),
            'devices_count'    => (int) ($this->devices_count ?? ($this->relationLoaded('devices') ? $this->devices->count() : 0)),
            'total_jobs'       => (int) (($this->repairs_count ?? 0) + ($this->sales_count ?? 0)),
            'total_spent'      => round($salesTotal + $repairsTotal, 2),
            'total_due'        => round($salesDue + $repairsDue, 2),
            'repairs'          => $this->whenLoaded('repairs'),
            'sales'            => $this->whenLoaded('sales'),
            'devices'          => $this->whenLoaded('devices'),
            'warranties'       => $this->whenLoaded('warranties'),
            'created_at'       => $this->created_at?->toIso8601String(),
            'updated_at'       => $this->updated_at?->toIso8601String(),
        ];
    }
}
