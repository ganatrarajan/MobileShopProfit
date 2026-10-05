<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreWarrantyClaimRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'claim_date' => ['nullable', 'date'],
            'complaint' => ['required', 'string', 'max:2000'],
            'notes' => ['nullable', 'string', 'max:1000'],
            'customer_id' => ['nullable', 'integer', 'exists:customers,id'],
            'device_id' => ['nullable', 'integer', 'exists:devices,id'],
        ];
    }
}