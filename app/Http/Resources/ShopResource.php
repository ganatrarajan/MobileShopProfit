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
            'mobile'      => $this->phone ?: ($this->user?->mobile ?? ''),
            'phone'       => $this->phone ?: ($this->user?->mobile ?? ''),
            'shop_phone'  => $this->phone ?: ($this->user?->mobile ?? ''),
            'owner_mobile'=> $this->user?->mobile ?? '',
            'email'       => $this->email,
            'address'     => $this->address,
            'city'        => $this->city,
            'state'       => $this->state,
            'pincode'         => $this->pincode,
            'google_maps_url' => $this->google_maps_url,
            'latitude'        => $this->latitude !== null ? (float) $this->latitude : null,
            'longitude'       => $this->longitude !== null ? (float) $this->longitude : null,
            'upi_id'          => $this->upi_id,
            'tagline'         => $this->tagline,
            'gst_number'      => $this->gst_number,
            'logo'        => $this->logo,
            'logo_url'    => $this->logo_url,
            'currency'    => $this->currency ?? 'INR',
            'status'      => $this->status ?? 'active',
            'created_at'  => $this->created_at?->toIso8601String(),
        ];
    }
}
