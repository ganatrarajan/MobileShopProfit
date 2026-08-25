<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreSaleRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'sale_type' => ['nullable', 'string', 'in:quick,regular'],
            'customer_name' => ['nullable', 'string', 'max:255'],
            'customer_mobile' => ['nullable', 'string', 'max:50'],
            
            'customer_id' => [
                Rule::requiredIf(function () {
                    $saleType = $this->input('sale_type', 'regular');
                    if ($saleType === 'regular') {
                        return true;
                    }
                    $items = $this->input('items', []);
                    foreach ($items as $item) {
                        if (($item['item_type'] ?? '') === 'mobile') {
                            return true;
                        }
                    }
                    return false;
                }),
                'nullable',
                'integer',
                'exists:customers,id',
            ],
            'device_id' => ['nullable', 'integer', 'exists:devices,id'],
            'sale_date' => ['nullable', 'date'],
            'discount' => ['nullable', 'numeric', 'min:0'],
            'tax_amount' => ['nullable', 'numeric', 'min:0'],
            'notes' => ['nullable', 'string', 'max:1000'],
            
            'items' => ['required', 'array', 'min:1'],
            'items.*.inventory_item_id' => ['nullable', 'integer', 'exists:inventory_items,id'],
            'items.*.product_name' => ['required_without:items.*.item_name', 'nullable', 'string', 'max:255'],
            'items.*.item_name' => ['required_without:items.*.product_name', 'nullable', 'string', 'max:255'],
            'items.*.item_type' => ['nullable', 'string', 'in:mobile,accessory,product,service,spare_part,other'],
            'items.*.brand' => ['nullable', 'string', 'max:100'],
            'items.*.model' => ['nullable', 'string', 'max:100'],
            'items.*.imei_1' => ['nullable', 'string', 'max:50'],
            'items.*.imei_2' => ['nullable', 'string', 'max:50'],
            'items.*.serial_number' => ['nullable', 'string', 'max:100'],
            'items.*.quantity' => ['required', 'integer', 'min:1'],
            'items.*.unit_price' => ['required', 'numeric', 'min:0'],
            'items.*.discount' => ['nullable', 'numeric', 'min:0'],
            'items.*.tax_amount' => ['nullable', 'numeric', 'min:0'],
            'items.*.cost_price' => ['nullable', 'numeric', 'min:0'],

            'payment_amount' => ['nullable', 'numeric', 'min:0'],
            'payment_method' => ['nullable', 'string', 'in:cash,upi,card,bank_transfer,other'],
            'payment_notes' => ['nullable', 'string', 'max:500'],
        ];
    }

    protected function prepareForValidation(): void
    {
        $items = $this->input('items', []);
        foreach ($items as &$item) {
            if (!isset($item['product_name']) && isset($item['item_name'])) {
                $item['product_name'] = $item['item_name'];
            }
        }
        $this->merge([
            'items' => $items,
            'sale_type' => $this->input('sale_type', 'regular'),
        ]);
    }
}