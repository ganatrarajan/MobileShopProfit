<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Sale extends Model
{
    use SoftDeletes;
    use HasFactory;

    protected $fillable = [
        'shop_id',
        'sale_type',
        'customer_name',
        'customer_mobile',
        'customer_id',
        'device_id',
        'invoice_number',
        'sale_date',
        'subtotal',
        'discount',
        'tax_amount',
        'grand_total',
        'amount_paid',
        'amount_due',
        'payment_status',
        'notes',
        'created_by',
    ];

    protected $casts = [
        'sale_date' => 'datetime',
        'subtotal' => 'decimal:2',
        'discount' => 'decimal:2',
        'tax_amount' => 'decimal:2',
        'grand_total' => 'decimal:2',
        'amount_paid' => 'decimal:2',
        'amount_due' => 'decimal:2',
    ];

    public function scopeForShop($query, $shopId)
    {
        return $query->where('shop_id', $shopId);
    }

    public function shop()
    {
        return $this->belongsTo(Shop::class);
    }

    public function customer()
    {
        return $this->belongsTo(Customer::class);
    }

    public function device()
    {
        return $this->belongsTo(Device::class);
    }

    public function items()
    {
        return $this->hasMany(SaleItem::class);
    }

    public function payments()
    {
        return $this->hasMany(SalePayment::class)->orderBy('payment_date', 'asc');
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function recalculatePaymentStatus(): void
    {
        $paid = (float) $this->payments()->sum('amount');
        $due = max(0, (float) $this->grand_total - $paid);

        $status = 'due';
        if ($paid >= (float) $this->grand_total) {
            $status = 'paid';
        } elseif ($paid > 0) {
            $status = 'partially_paid';
        }

        $this->update([
            'amount_paid' => $paid,
            'amount_due' => $due,
            'payment_status' => $status,
        ]);
    }
}