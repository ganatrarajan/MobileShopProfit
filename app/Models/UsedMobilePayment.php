<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UsedMobilePayment extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'shop_id',
        'used_mobile_id',
        'amount',
        'payment_method',
        'payment_date',
        'notes',
        'created_by',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'payment_date' => 'datetime',
    ];

    public function scopeForShop($query, $shopId)
    {
        return $query->where('shop_id', $shopId);
    }

    public function usedMobile(): BelongsTo
    {
        return $this->belongsTo(UsedMobile::class);
    }

    public function shop(): BelongsTo
    {
        return $this->belongsTo(Shop::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
