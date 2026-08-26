<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\DB;

class Technician extends Model
{
    use SoftDeletes;
    use HasFactory;

    protected $fillable = [
        'shop_id',
        'name',
        'mobile',
        'specialization',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function scopeForShop($query, $shopId)
    {
        return $query->where('shop_id', $shopId);
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function shop(): BelongsTo
    {
        return $this->belongsTo(Shop::class);
    }

    public function repairs(): HasMany
    {
        return $this->hasMany(Repair::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(TechnicianPayment::class);
    }

    public function getPendingJobsCountAttribute(): int
    {
        return $this->repairs()
            ->whereIn('repair_status', ['received', 'diagnosing', 'waiting_customer', 'waiting_parts', 'pending_approval'])
            ->count();
    }

    public function getInProgressJobsCountAttribute(): int
    {
        return $this->repairs()
            ->whereIn('repair_status', ['repairing', 'in_progress'])
            ->count();
    }

    public function getCompletedJobsCountAttribute(): int
    {
        return $this->repairs()
            ->whereIn('repair_status', ['ready', 'delivered'])
            ->count();
    }

    public function getTotalJobsCountAttribute(): int
    {
        return $this->repairs()->count();
    }

    public function getTotalValueHandledAttribute(): float
    {
        return (float) $this->repairs()
            ->sum(DB::raw('CASE WHEN final_cost > 0 THEN final_cost ELSE estimated_cost END'));
    }

    public function getTotalEarningsAttribute(): float
    {
        return (float) $this->repairs()->sum('technician_earning');
    }

    public function getTotalPaidAttribute(): float
    {
        return (float) $this->payments()->sum('amount');
    }

    public function getTotalPayableAttribute(): float
    {
        return max(0.0, round($this->total_earnings - $this->total_paid, 2));
    }
}