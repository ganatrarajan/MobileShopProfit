<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DeviceResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'            => $this->id,
            'shop_id'       => $this->shop_id,
            'customer_id'   => $this->customer_id,
            'device_type'   => $this->device_type,
            'brand'         => $this->brand,
            'model'         => $this->model,
            'variant'       => $this->variant,
            'color'         => $this->color,
            'imei_1'        => $this->imei_1,
            'imei_2'        => $this->imei_2,
            'serial_number' => $this->serial_number,
            'purchase_date' => $this->purchase_date?->format('Y-m-d'),
            'notes'         => $this->notes,
            'customer'      => new CustomerResource($this->whenLoaded('customer')),
            'created_at'    => $this->created_at?->toIso8601String(),
            'updated_at'    => $this->updated_at?->toIso8601String(),
        ];
    }
}
