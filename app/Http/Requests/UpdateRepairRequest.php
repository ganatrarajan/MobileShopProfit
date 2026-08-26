<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateRepairRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'technician_id' => ['nullable', 'integer', 'exists:technicians,id'],
            'technician_earning' => ['nullable', 'numeric', 'min:0'],
            'problem_description' => ['sometimes', 'string', 'max:2000'],
            'device_condition' => ['nullable', 'array'],
            'device_condition.*' => ['string', 'max:100'],
            'condition_notes' => ['nullable', 'string', 'max:1000'],
            'accessories_received' => ['nullable', 'array'],
            'accessories_received.*' => ['string', 'max:100'],
            'accessories_notes' => ['nullable', 'string', 'max:1000'],
            'pin_passcode' => ['nullable', 'string', 'max:100'],
            'expected_delivery_date' => ['nullable', 'date'],
            'estimated_cost' => ['nullable', 'numeric', 'min:0'],
            'final_cost' => ['nullable', 'numeric', 'min:0'],
            'labour_cost' => ['nullable', 'numeric', 'min:0'],
            'customer_notes' => ['nullable', 'string', 'max:2000'],
            'internal_notes' => ['nullable', 'string', 'max:2000'],
        ];
    }
}