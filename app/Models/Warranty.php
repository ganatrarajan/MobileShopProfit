<?php

namespace App\Models;

use Carbon\Carbon;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Warranty extends Model
{
    use SoftDeletes;
    use HasFactory;

    protected $fillable = [
        'shop_id',
        'customer_id',
        'device_id',
        'sale_id',
        'repair_id',
        'warranty_number',
        'warranty_type',
        'warranty_start_date',
        'warranty_end_date',
        'duration_days',
        'warranty_terms',
        'status',
        'notes',
        'created_by',
    ];

    protected $casts = [
        'warranty_start_date' => 'date',
        'warranty_end_date' => 'date',
        'duration_days' => 'integer',
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

    public function sale(): BelongsTo
    {
        return $this->belongsTo(Sale::class);
    }

    public function repair(): BelongsTo
    {
        return $this->belongsTo(Repair::class);
    }

    public function claims(): HasMany
    {
        return $this->hasMany(WarrantyClaim::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    /**
     * Dynamically compute current warranty status based on current date.
     */
    public function getComputedStatusAttribute(): string
    {
        if ($this->status === 'voided') {
            return 'voided';
        }

        $today = Carbon::today();
        $endDate = Carbon::parse($this->warranty_end_date)->startOfDay();

        if ($today->gt($endDate)) {
            return 'expired';
        }

        $daysLeft = $today->diffInDays($endDate, false);
        if ($daysLeft <= 7) {
            return 'expiring_soon';
        }

        return 'active';
    }

    /**
     * Compute remaining days until expiry (can be negative if expired).
     */
    public function getDaysRemainingAttribute(): int
    {
        $today = Carbon::today();
        $endDate = Carbon::parse($this->warranty_end_date)->startOfDay();
        return (int) $today->diffInDays($endDate, false);
    }
}