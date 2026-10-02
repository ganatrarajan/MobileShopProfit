<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class VerifyOtpRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'verification_id' => 'required|string|uuid|exists:pending_registrations,id',
            'otp'             => 'required|string|size:4',
        ];
    }

    public function messages(): array
    {
        return [
            'verification_id.required' => 'Invalid or missing registration session ID.',
            'verification_id.exists'   => 'Registration session has expired or is invalid.',
            'otp.required'             => 'OTP code is required.',
            'otp.size'                 => 'OTP code must be exactly 4 digits.',
        ];
    }
}
