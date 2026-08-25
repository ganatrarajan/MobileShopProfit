<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $userId = $this->user()->id;

        return [
            'name'   => 'sometimes|required|string|max:255',
            'mobile' => ['sometimes', 'required', 'string', 'max:20', Rule::unique('users', 'mobile')->ignore($userId)],
            'email'  => ['sometimes', 'nullable', 'string', 'email', 'max:255', Rule::unique('users', 'email')->ignore($userId)],
            'phone'  => 'sometimes|nullable|string|max:20',
        ];
    }
}
