<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PaymentGatewayConfig extends Model
{
    use HasFactory;

    protected $fillable = [
        'gateway_name',
        'key_id',
        'key_secret',
        'webhook_secret',
        'mode',
        'currency',
        'active',
        'trial_months',
        'created_by',
        'updated_by',
    ];

    protected $casts = [
        'active' => 'boolean',
        'trial_months' => 'integer',
    ];
}
