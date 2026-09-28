<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StorePurchaseRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'vendor_id' => ['required', 'integer'],
            'purchase_date' => ['required', 'date'],
            'purchase_number' => ['nullable', 'string', 'max:50'],
            'items' => ['required', 'array', 'min:1'],
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
            'purchase_date.required' => 'Please select a purchase date.',
            'items.required' => 'Please add at least one item to the purchase.',
            'items.min' => 'Please add at least one item to the purchase.',
            'items.*.inventory_item_id.required' => 'Please select an inventory item for each line item.',
            'items.*.quantity.required' => 'Enter a valid quantity.',
            'items.*.quantity.min' => 'Enter a valid quantity.',
            'items.*.purchase_rate.required' => 'Enter the purchase price.',
            'items.*.purchase_rate.min' => 'Enter the purchase price.',
        ];
    }
}
