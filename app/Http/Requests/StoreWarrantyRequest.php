<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreWarrantyRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'customer_id' => ['required', 'integer', 'exists:customers,id'],
            'device_id' => ['required', 'integer', 'exists:devices,id'],
            'sale_id' => ['nullable', 'integer', 'exists:sales,id'],
            'repair_id' => ['nullable', 'integer', 'exists:repairs,id'],
            'warranty_type' => ['required', 'string', 'in:sale,repair'],
            'warranty_start_date' => ['nullable', 'date'],
            'duration_days' => ['required', 'integer', 'min:1', 'max:3650'],
            'warranty_terms' => ['nullable', 'string', 'max:2000'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ];
    }
}