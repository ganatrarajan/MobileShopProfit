<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateRepairStatusRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'repair_status' => [
                'required',
                'string',
                'in:received,diagnosing,waiting_customer,waiting_parts,repairing,ready,delivered,cancelled',
            ],
            'notes' => ['nullable', 'string', 'max:1000'],
        ];
    }
}