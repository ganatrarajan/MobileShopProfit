<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class RegisterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name'      => 'required|string|max:255',
            'mobile'    => 'required|string|max:20|unique:users,mobile',
            'email'     => 'nullable|string|email|max:255|unique:users,email',
            'shop_name' => 'required|string|max:255',
            'password'  => 'required|string|min:8|confirmed',
        ];
    }

    public function messages(): array
    {
        return [
            'mobile.unique'      => 'This mobile number is already registered.',
            'email.unique'       => 'This email address is already registered.',
            'password.confirmed' => 'Password confirmation does not match.',
            'password.min'       => 'Password must be at least 8 characters long.',
        ];
    }
}
