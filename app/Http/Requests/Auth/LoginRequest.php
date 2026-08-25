<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class LoginRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'login'    => 'required|string', // Mobile number OR Email
            'password' => 'required|string',
        ];
    }

    public function messages(): array
    {
        return [
            'login.required'    => 'Please enter your mobile number or email.',
            'password.required' => 'Please enter your password.',
        ];
    }
}
