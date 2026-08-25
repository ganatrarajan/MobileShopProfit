<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StockAdjustmentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'adjustment_type' => ['required', 'string', 'in:damaged,return,correction,lost'],
            'quantity' => ['required', 'integer'], // can be positive or negative
            'notes' => ['required', 'string', 'max:500'], // mandatory reason
        ];
    }
}