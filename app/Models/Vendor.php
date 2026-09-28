<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Vendor extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'shop_id',
        'name',
        'phone',
        'email',
        'address',
        'gst_number',
        'notes',
    ];

    public function scopeForShop($query, $shopId)
    {
        return $query->where('shop_id', $shopId);
    }

    public function shop(): BelongsTo
    {
        return $this->belongsTo(Shop::class);
    }

    public function purchases(): HasMany
    {
        return $this->hasMany(Purchase::class)->latest();
    }

    public function payments(): HasMany
    {
        return $this->hasMany(PurchasePayment::class)->latest();
    }

    public function getTotalPurchaseAttribute(): float
    {
        return (float) $this->purchases()->sum('grand_total');
    }

    public function getTotalPaidAttribute(): float
    {
        return (float) $this->purchases()->sum('amount_paid');
    }

    public function getOutstandingAmountAttribute(): float
    {
        return (float) ($this->total_purchase - $this->total_paid);
    }
}
