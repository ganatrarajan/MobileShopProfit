<?php

namespace App\Http\Requests\Device;

use Illuminate\Foundation\Http\FormRequest;

class CreateDeviceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'device_type'   => 'required|string|in:Mobile,Tablet,Laptop,Other',
            'brand'         => 'required|string|max:255',
            'model'         => 'required|string|max:255',
            'variant'       => 'nullable|string|max:255',
            'color'         => 'nullable|string|max:255',
            'imei_1'        => ['nullable', 'string', 'digits:15'],
            'imei_2'        => ['nullable', 'string', 'digits:15'],
            'serial_number' => 'nullable|string|max:255',
            'purchase_date' => 'nullable|date',
            'notes'         => 'nullable|string',
        ];
    }

    public function messages(): array
    {
        return [
            'device_type.in' => 'Device type must be Mobile, Tablet, Laptop, or Other.',
            'imei_1.digits'  => 'IMEI 1 must be exactly 15 numeric digits.',
            'imei_2.digits'  => 'IMEI 2 must be exactly 15 numeric digits.',
        ];
    }
}
