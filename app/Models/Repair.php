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
        'technician_id',
        'technician_earning',
        'technician_paid_amount',
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
        'technician_earning' => 'decimal:2',
        'technician_paid_amount' => 'decimal:2',
    ];

    protected $appends = [
        'technician_payable',
        'shop_share',
        'technician_payment_status',
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

    public function technician(): BelongsTo
    {
        return $this->belongsTo(Technician::class);
    }

    public function parts(): HasMany
    {
        return $this->hasMany(RepairPart::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(RepairPayment::class);
    }

    public function technicianPayments(): HasMany
    {
        return $this->hasMany(TechnicianPayment::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function getTechnicianPayableAttribute(): float
    {
        $earning = (float) $this->technician_earning;
        $paid = (float) $this->technician_paid_amount;
        return max(0.0, round($earning - $paid, 2));
    }

    public function getShopShareAttribute(): float
    {
        $totalCost = (float) ($this->final_cost > 0 ? $this->final_cost : $this->estimated_cost);
        $earning = (float) $this->technician_earning;
        return max(0.0, round($totalCost - $earning, 2));
    }

    public function getTechnicianPaymentStatusAttribute(): string
    {
        $earning = (float) $this->technician_earning;
        $paid = (float) $this->technician_paid_amount;

        if ($earning <= 0) {
            return 'unassigned';
        }
        if ($paid >= $earning) {
            return 'paid';
        }
        if ($paid > 0) {
            return 'partially_paid';
        }
        return 'unpaid';
    }

    public function recalculatePaymentStatus(): void
    {
        $totalPaid = (float) $this->payments()->sum('amount');
        $totalCost = (float) ($this->final_cost > 0 ? $this->final_cost : $this->estimated_cost);
        $due = max(0, $totalCost - $totalPaid);

        $directTechPaid = (float) $this->technicianPayments()->sum('amount');
        $techPaid = max((float) $this->technician_paid_amount, $directTechPaid);

        $this->update([
            'amount_paid' => $totalPaid,
            'amount_due' => $due,
            'technician_paid_amount' => $techPaid,
        ]);
    }
}