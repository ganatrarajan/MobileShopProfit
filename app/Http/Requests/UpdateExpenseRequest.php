<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateExpenseRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'category_id' => ['sometimes', 'required', 'integer', 'exists:expense_categories,id'],
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'amount' => ['sometimes', 'required', 'numeric', 'gt:0'],
            'expense_date' => ['sometimes', 'required', 'date'],
            'payment_method' => ['nullable', 'string', 'in:cash,upi,bank_transfer,card,other'],
            'notes' => ['nullable', 'string', 'max:1000'],
            'reference_number' => ['nullable', 'string', 'max:100'],
            'is_recurring' => ['nullable', 'boolean'],
            'recurrence_type' => ['nullable', 'string', 'in:monthly,yearly'],
        ];
    }
}