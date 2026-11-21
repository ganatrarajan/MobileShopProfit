<?php

namespace App\Http\Requests\Shop;

use Illuminate\Foundation\Http\FormRequest;

class UpdateShopRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name'                 => 'sometimes|required|string|max:255',
            'owner_name'           => 'sometimes|nullable|string|max:255',
            'mobile'               => 'sometimes|nullable|string|max:20',
            'owner_mobile'         => 'sometimes|nullable|string|max:20',
            'phone'                => 'sometimes|nullable|string|max:20',
            'shop_phone'           => 'sometimes|nullable|string|max:20',
            'email'                => 'sometimes|nullable|email|max:255',
            'address'              => 'sometimes|nullable|string',
            'city'                 => 'sometimes|nullable|string|max:100',
            'state'                => 'sometimes|nullable|string|max:100',
            'pincode'              => 'sometimes|nullable|string|max:20',
            'google_maps_url'      => 'sometimes|nullable|string|max:500',
            'latitude'             => 'sometimes|nullable|numeric',
            'longitude'            => 'sometimes|nullable|numeric',
            'upi_id'               => 'sometimes|nullable|string|max:100',
            'tagline'              => 'sometimes|nullable|string|max:255',
            'terms_and_conditions' => 'sometimes|nullable|string',
            'gst_number'           => 'sometimes|nullable|string|max:50',
            'signature'            => 'sometimes|nullable',
            'signature_path'       => 'sometimes|nullable',
            'currency'             => 'sometimes|nullable|string|max:10',
        ];
    }
}
