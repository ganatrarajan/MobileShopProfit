<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Repair extends Model
{
    use SoftDeletes;
    use HasFactory;

    protected $fillable = [
        'shop_id',
        'customer_id',
        'device_id',
        'job_number',
        'date_received',
        'expected_delivery_date',
        'delivered_date',
        'problem_description',
        'device_condition',
        'condition_notes',
        'accessories_received',
        'accessories_notes',
        'pin_passcode',
        'estimated_cost',
        'final_cost',
        'labour_cost',
        'amount_paid',
        'amount_due',
        'repair_status',
        'customer_notes',
        'internal_notes',
        'created_by',
    ];

    protected $casts = [
        'date_received' => 'date',
        'expected_delivery_date' => 'date',
        'delivered_date' => 'datetime',
        'device_condition' => 'array',
        'accessories_received' => 'array',
        'estimated_cost' => 'decimal:2',
        'final_cost' => 'decimal:2',
        'labour_cost' => 'decimal:2',
        'amount_paid' => 'decimal:2',
        'amount_due' => 'decimal:2',
    ];

    public function scopeForShop($query, $shopId)
    {
        return $query->where('shop_id', $shopId);
    }

    public function shop(): BelongsTo
    {
        return $this->belongsTo(Shop::class);
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class);
    }

    public function parts(): HasMany
    {
        return $this->hasMany(RepairPart::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(RepairPayment::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function recalculatePaymentStatus(): void
    {
        $totalPaid = (float) $this->payments()->sum('amount');
        $totalCost = (float) ($this->final_cost > 0 ? $this->final_cost : $this->estimated_cost);
        $due = max(0, $totalCost - $totalPaid);

        $this->update([
            'amount_paid' => $totalPaid,
            'amount_due' => $due,
        ]);
    }
}