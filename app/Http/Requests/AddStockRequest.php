<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AddStockRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'quantity' => ['required', 'integer', 'min:1'],
            'unit_cost' => ['nullable', 'numeric', 'min:0'],
            'notes' => ['nullable', 'string', 'max:500'],
            'imei1' => ['nullable', 'string', 'max:50'],
            'imei2' => ['nullable', 'string', 'max:50'],
            'serial_number' => ['nullable', 'string', 'max:50'],
        ];
    }
}