<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateWarrantyRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'warranty_start_date' => ['sometimes', 'date'],
            'duration_days' => ['sometimes', 'integer', 'min:1', 'max:3650'],
            'warranty_terms' => ['nullable', 'string', 'max:2000'],
            'status' => ['sometimes', 'string', 'in:active,expiring_soon,expired,voided'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ];
    }
}