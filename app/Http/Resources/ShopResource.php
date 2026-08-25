<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ShopResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'          => $this->id,
            'user_id'     => $this->user_id,
            'name'        => $this->name,
            'owner_name'  => $this->owner_name,
            'mobile'      => $this->mobile ?? $this->phone,
            'phone'       => $this->phone ?? $this->mobile,
            'email'       => $this->email,
            'address'     => $this->address,
            'city'        => $this->city,
            'state'       => $this->state,
            'pincode'     => $this->pincode,
            'gst_number'  => $this->gst_number,
            'logo'        => $this->logo,
            'logo_url'    => $this->logo_url,
            'currency'    => $this->currency ?? 'INR',
            'status'      => $this->status ?? 'active',
            'created_at'  => $this->created_at?->toIso8601String(),
        ];
    }
}
