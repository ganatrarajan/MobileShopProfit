<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ReferralPointTransaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'shop_id',
        'related_shop_id',
        'subscription_id',
        'payment_transaction_id',
        'type',
        'source',
        'points',
        'balance_after',
        'description',
        'meta',
    ];

    protected $casts = [
        'points'        => 'decimal:2',
        'balance_after' => 'decimal:2',
        'meta'          => 'array',
    ];

    public function shop(): BelongsTo
    {
        return $this->belongsTo(Shop::class);
    }

    public function relatedShop(): BelongsTo
    {
        return $this->belongsTo(Shop::class, 'related_shop_id');
    }

    public function paymentTransaction(): BelongsTo
    {
        return $this->belongsTo(PaymentTransaction::class, 'payment_transaction_id');
    }
}

