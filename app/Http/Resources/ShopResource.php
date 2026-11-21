<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ShopResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $ownerMob = $this->owner_mobile ?: ($this->user?->mobile ?? ($request->user()?->mobile ?? ''));
        $shopPh = $this->phone ?: $ownerMob;

        return [
            'id'                   => $this->id,
            'user_id'              => $this->user_id,
            'name'                 => $this->name,
            'owner_name'           => $this->owner_name,
            'mobile'               => $ownerMob,
            'owner_mobile'         => $ownerMob,
            'phone'                => $shopPh,
            'shop_phone'           => $shopPh,
            'email'                => $this->email,
            'address'              => $this->address,
            'city'                 => $this->city,
            'state'                => $this->state,
            'pincode'              => $this->pincode,
            'google_maps_url'      => $this->google_maps_url,
            'latitude'             => $this->latitude !== null ? (float) $this->latitude : null,
            'longitude'            => $this->longitude !== null ? (float) $this->longitude : null,
            'upi_id'               => $this->upi_id,
            'tagline'              => $this->tagline,
            'terms_and_conditions' => $this->terms_and_conditions,
            'gst_number'           => $this->gst_number,
            'logo'                 => $this->logo,
            'logo_url'             => $this->logo_url,
            'signature_path'       => $this->signature_path,
            'signature_url'        => $this->signature_url,
            'currency'             => $this->currency ?? 'INR',
            'status'               => $this->status ?? 'active',
            'created_at'           => $this->created_at?->toIso8601String(),
        ];
    }
}
