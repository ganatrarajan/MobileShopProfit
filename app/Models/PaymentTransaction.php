<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PaymentTransaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'shop_id',
        'user_id',
        'plan_id',
        'order_id',
        'payment_id',
        'signature',
        'amount',
        'currency',
        'status',
        'payment_method',
        'gateway_name',
        'gateway_response',
        'failure_reason',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'gateway_response' => 'array',
    ];

    public function shop(): BelongsTo
    {
        return $this->belongsTo(Shop::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function plan(): BelongsTo
    {
        return $this->belongsTo(Plan::class);
    }
}
