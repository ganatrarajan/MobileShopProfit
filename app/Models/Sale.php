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
        return $this->belongsTo(Customer::class)->withTrashed();
    }

    public function device()
    {
        return $this->belongsTo(Device::class)->withTrashed();
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

    public function warranty()
    {
        return $this->hasOne(Warranty::class)->whereNull('warranties.deleted_at')->latestOfMany();
    }

    public function warranties()
    {
        return $this->hasMany(Warranty::class)->whereNull('warranties.deleted_at');
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

    /**
     * Total purchase cost of the items sold in this sale.
     */
    public function getTotalCostAttribute(): float
    {
        if (!$this->relationLoaded('items')) {
            $this->load(['items.inventoryItem']);
        }
        return (float) $this->items->sum(function ($item) {
            $cost = $item->cost_price !== null && (float) $item->cost_price > 0
                ? (float) $item->cost_price
                : (float) ($item->inventoryItem->purchase_price ?? 0);
            return $cost * ($item->quantity ?? 1);
        });
    }

    /**
     * Realized cash-based net profit:
     * strictly based on money received minus item purchase cost.
     */
    public function getNetProfitAttribute(): float
    {
        $paid = (float) $this->amount_paid;
        $cost = $this->total_cost;
        if ($paid <= 0 || $paid <= $cost) {
            return 0.0;
        }
        return round($paid - $cost, 2);
    }

    /**
     * Expected net profit when the invoice is fully settled.
     */
    public function getExpectedNetProfitAttribute(): float
    {
        $grandTotal = (float) $this->grand_total;
        $cost = $this->total_cost;
        return round(max(0, $grandTotal - $cost), 2);
    }

    /**
     * Profit margin percentage based on collected cash.
     */
    public function getProfitMarginPercentAttribute(): float
    {
        $paid = (float) $this->amount_paid;
        $profit = $this->net_profit;
        if ($paid <= 0 || $profit <= 0) {
            return 0.0;
        }
        return round(($profit / $paid) * 100, 1);
    }

    protected static function booted(): void
    {
        static::deleting(function ($sale) {
            foreach ($sale->warranties()->get() as $warranty) {
                $warranty->delete();
            }
        });
    }
}