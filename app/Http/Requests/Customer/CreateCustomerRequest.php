<?php

namespace App\Http\Requests\Customer;

use Illuminate\Foundation\Http\FormRequest;

class CreateCustomerRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name'             => 'required|string|max:255',
            'mobile'           => ['required', 'string', 'regex:/^[6-9]\d{9}$/'],
            'alternate_mobile' => ['nullable', 'string', 'regex:/^[6-9]\d{9}$/'],
            'email'            => 'nullable|string|email|max:255',
            'address'          => 'nullable|string',
            'city'             => 'nullable|string|max:100',
            'notes'            => 'nullable|string',
        ];
    }

    public function messages(): array
    {
        return [
            'mobile.regex'           => 'Please enter a valid 10-digit Indian mobile number starting with 6, 7, 8, or 9.',
            'alternate_mobile.regex' => 'Please enter a valid 10-digit Indian alternate mobile number.',
        ];
    }
}
