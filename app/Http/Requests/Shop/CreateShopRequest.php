<?php

namespace App\Http\Requests\Shop;

use Illuminate\Foundation\Http\FormRequest;

class CreateShopRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name'       => 'required|string|max:255',
            'owner_name' => 'required|string|max:255',
            'mobile'     => 'required|string|max:20',
            'phone'      => 'nullable|string|max:20',
            'email'      => 'nullable|string|email|max:255',
            'address'    => 'required|string',
            'city'       => 'required|string|max:100',
            'state'      => 'required|string|max:100',
            'pincode'         => 'required|string|max:20',
            'google_maps_url' => 'nullable|string|max:500',
            'latitude'        => 'nullable|numeric',
            'longitude'       => 'nullable|numeric',
            'upi_id'          => 'nullable|string|max:100',
            'tagline'         => 'nullable|string|max:255',
            'gst_number'      => 'nullable|string|max:50',
            'logo'       => 'nullable|image|mimes:jpeg,png,jpg,webp|max:2048',
        ];
    }
}
