<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreRepairRequest extends FormRequest
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
            'date_received' => ['nullable', 'date'],
            'expected_delivery_date' => ['nullable', 'date'],
            'problem_description' => ['required', 'string', 'max:2000'],
            'device_condition' => ['nullable', 'array'],
            'device_condition.*' => ['string', 'max:100'],
            'condition_notes' => ['nullable', 'string', 'max:1000'],
            'accessories_received' => ['nullable', 'array'],
            'accessories_received.*' => ['string', 'max:100'],
            'accessories_notes' => ['nullable', 'string', 'max:1000'],
            'pin_passcode' => ['nullable', 'string', 'max:100'],
            'estimated_cost' => ['nullable', 'numeric', 'min:0'],
            'final_cost' => ['nullable', 'numeric', 'min:0'],
            'labour_cost' => ['nullable', 'numeric', 'min:0'],
            'payment_amount' => ['nullable', 'numeric', 'min:0'],
            'payment_method' => ['nullable', 'string', 'in:cash,upi,card,bank_transfer,other'],
            'payment_notes' => ['nullable', 'string', 'max:500'],
            'customer_notes' => ['nullable', 'string', 'max:2000'],
            'internal_notes' => ['nullable', 'string', 'max:2000'],
        ];
    }
}