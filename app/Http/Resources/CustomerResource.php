<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CustomerResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'               => $this->id,
            'shop_id'          => $this->shop_id,
            'name'             => $this->name,
            'mobile'           => $this->mobile,
            'alternate_mobile' => $this->alternate_mobile,
            'email'            => $this->email,
            'address'          => $this->address,
            'city'             => $this->city,
            'notes'            => $this->notes,
            'created_at'       => $this->created_at?->toIso8601String(),
            'updated_at'       => $this->updated_at?->toIso8601String(),
        ];
    }
}
