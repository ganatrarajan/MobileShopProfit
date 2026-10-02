<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Purchase extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'shop_id',
        'vendor_id',
        'purchase_number',
        'purchase_date',
        'subtotal',
        'discount',
        'additional_charges',
        'grand_total',
        'amount_paid',
        'outstanding_amount',
        'payment_status',
        'is_stock_added',
        'notes',
    ];

    protected $casts = [
        'purchase_date' => 'date',
        'subtotal' => 'decimal:2',
        'discount' => 'decimal:2',
        'additional_charges' => 'decimal:2',
        'grand_total' => 'decimal:2',
        'amount_paid' => 'decimal:2',
        'outstanding_amount' => 'decimal:2',
        'is_stock_added' => 'boolean',
    ];

    public function scopeForShop($query, $shopId)
    {
        return $query->where('shop_id', $shopId);
    }

    public function shop(): BelongsTo
    {
        return $this->belongsTo(Shop::class);
    }

    public function vendor(): BelongsTo
    {
        return $this->belongsTo(Vendor::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(PurchaseItem::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(PurchasePayment::class)->latest();
    }

    /**
     * Update payment status and outstanding amount based on grand total and amount paid.
     */
    public function updatePaymentTotals(): void
    {
        $paid = (float) $this->amount_paid;
        $total = (float) $this->grand_total;
        $outstanding = max(0, $total - $paid);

        $status = 'pending';
        if ($paid >= $total && $total > 0) {
            $status = 'paid';
        } elseif ($paid > 0) {
            $status = 'partial';
        }

        $this->forceFill([
            'outstanding_amount' => $outstanding,
            'payment_status' => $status,
        ])->save();
    }
}
