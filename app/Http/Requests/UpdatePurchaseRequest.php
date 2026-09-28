<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdatePurchaseRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'vendor_id' => ['sometimes', 'required', 'integer'],
            'purchase_date' => ['sometimes', 'required', 'date'],
            'purchase_number' => ['nullable', 'string', 'max:50'],
            'items' => ['sometimes', 'required', 'array', 'min:1'],
            'items.*.inventory_item_id' => ['required', 'integer'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
            'items.*.purchase_rate' => ['required', 'numeric', 'min:0'],
            'discount' => ['nullable', 'numeric', 'min:0'],
            'additional_charges' => ['nullable', 'numeric', 'min:0'],
            'amount_paid' => ['nullable', 'numeric', 'min:0'],
            'payment_status' => ['nullable', 'string', 'in:paid,partial,pending'],
            'add_to_inventory' => ['nullable', 'boolean'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ];
    }

    public function messages(): array
    {
        return [
            'vendor_id.required' => 'Please select a vendor.',
            'items.required' => 'Please add at least one item to the purchase.',
            'items.*.quantity.min' => 'Enter a valid quantity.',
            'items.*.purchase_rate.required' => 'Enter the purchase price.',
        ];
    }
}
