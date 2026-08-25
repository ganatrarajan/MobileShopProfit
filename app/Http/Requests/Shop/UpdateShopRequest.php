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
            'name'       => 'sometimes|required|string|max:255',
            'owner_name' => 'sometimes|required|string|max:255',
            'mobile'     => 'sometimes|required|string|max:20',
            'phone'      => 'nullable|string|max:20',
            'email'      => 'nullable|string|email|max:255',
            'address'    => 'sometimes|required|string',
            'city'       => 'sometimes|required|string|max:100',
            'state'      => 'sometimes|required|string|max:100',
            'pincode'    => 'sometimes|required|string|max:20',
            'gst_number' => 'nullable|string|max:50',
            'currency'   => 'nullable|string|max:10',
        ];
    }
}
