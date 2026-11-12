<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class Shop extends Model
{
    use HasFactory;

    protected static function booted(): void
    {
        static::creating(function (Shop $shop) {
            if (empty($shop->referral_code)) {
                $prefix = strtoupper(preg_replace('/[^A-Za-z0-9]/', '', (string) $shop->name));
                $prefix = substr($prefix, 0, 4) ?: 'SHOP';
                do {
                    $code = $prefix . strtoupper(Str::random(4));
                } while (static::where('referral_code', $code)->exists());
                $shop->referral_code = $code;
            }
        });
    }

    protected $fillable = [
        'user_id',
        'name',
        'owner_name',
        'phone',
        'mobile',
        'email',
        'address',
        'city',
        'state',
        'pincode',
        'gst_number',
        'logo',
        'currency',
        'status',
        'referral_code',
        'referred_by_shop_id',
        'referral_points_balance',
        'referral_enabled_override',
        'referral_reward_mode_override',
        'custom_referral_signup_points',
        'custom_referral_recharge_percent',
        'custom_referral_max_redeem_percent',
        'custom_max_staff',
        'custom_staff_valid_until',
        'custom_staff_note',
        'custom_discount_percent',
        'custom_plan_prices',
        'custom_staff_price_per_day',
        'custom_discount_valid_until',
        'custom_discount_note',
        'custom_discount_is_one_time',
    ];

    protected $casts = [
        'referral_points_balance'            => 'float',
        'referral_enabled_override'          => 'boolean',
        'custom_referral_signup_points'      => 'float',
        'custom_referral_recharge_percent'   => 'float',
        'custom_referral_max_redeem_percent' => 'float',
        'custom_max_staff'                   => 'integer',
        'custom_staff_valid_until'           => 'date:Y-m-d',
        'custom_discount_percent'            => 'float',
        'custom_plan_prices'                 => 'array',
        'custom_staff_price_per_day'         => 'float',
        'custom_discount_valid_until'        => 'date:Y-m-d',
        'custom_discount_is_one_time'        => 'boolean',
    ];

    protected $appends = ['logo_url', 'effective_max_staff', 'staff_days_remaining', 'staff_valid_until_formatted'];

    /**
     * Get the effective max staff / technician logins allowed for this shop.
     * Takes custom shop-level override with expiry into account first,
     * then falls back to the subscription plan limit.
     */
    public function getEffectiveMaxStaffAttribute(): int
    {
        // 1. Check shop-level custom staff limit with validity date
        if ($this->custom_max_staff !== null) {
            if (!$this->custom_staff_valid_until || now()->startOfDay()->lte(Carbon::parse($this->custom_staff_valid_until)->endOfDay())) {
                return (int) $this->custom_max_staff;
            }
            // Validity has expired! Staff access ends immediately
            return 0;
        }

        // 2. Fallback to latest subscription plan limit
        $sub = $this->latestSubscription;
        if ($sub) {
            if ($sub->status === 'trial') {
                return 1; // 1 staff account allowed during free trial
            }
            if ($sub->plan) {
                return (int) ($sub->plan->max_staff_accounts ?? 0);
            }
        }

        return 0;
    }

    /**
     * Get remaining days of staff login validity.
     */
    public function getStaffDaysRemainingAttribute(): int
    {
        if ($this->effective_max_staff <= 0) {
            return 0;
        }

        if ($this->custom_staff_valid_until) {
            $exp = Carbon::parse($this->custom_staff_valid_until)->endOfDay();
            return max(0, (int) ceil(now()->diffInDays($exp, false)));
        }

        $sub = $this->latestSubscription;
        if ($sub && $sub->expiry_date) {
            $exp = Carbon::parse($sub->expiry_date)->endOfDay();
            return max(0, (int) ceil(now()->diffInDays($exp, false)));
        }

        return 0;
    }

    /**
     * Get staff validity expiry date formatted (e.g. 07 Dec 2026).
     */
    public function getStaffValidUntilFormattedAttribute(): ?string
    {
        if ($this->custom_staff_valid_until) {
            return Carbon::parse($this->custom_staff_valid_until)->format('d M Y');
        }

        $sub = $this->latestSubscription;
        if ($sub && $sub->expiry_date && ($sub->plan?->max_staff_accounts ?? 0) > 0) {
            return Carbon::parse($sub->expiry_date)->format('d M Y');
        }

        return null;
    }

    /**
     * Check whether this shop currently has an active custom staff override.
     */
    public function hasActiveCustomStaffOverride(): bool
    {
        if ($this->custom_max_staff === null) return false;
        if (!$this->custom_staff_valid_until) return true;
        return now()->startOfDay()->lte(Carbon::parse($this->custom_staff_valid_until)->endOfDay());
    }

    /**
     * Check whether this shop currently has an active custom discount or custom plan prices.
     */
    public function hasActiveCustomDiscount(): bool
    {
        $hasPercent = ($this->custom_discount_percent !== null && $this->custom_discount_percent > 0);
        $hasCustomPlans = !empty($this->custom_plan_prices);
        $hasCustomStaff = ($this->custom_staff_price_per_day !== null);

        if (!$hasPercent && !$hasCustomPlans && !$hasCustomStaff) {
            return false;
        }

        if (!$this->custom_discount_valid_until) {
            return true;
        }

        return now()->startOfDay()->lte(Carbon::parse($this->custom_discount_valid_until)->endOfDay());
    }

    /**
     * Calculate effective price for a plan for this specific shop.
     */
    public function calculatePlanPrice($plan): array
    {
        $basePrice = (float) $plan->price;
        if (!$this->hasActiveCustomDiscount()) {
            return [
                'price'            => $basePrice,
                'original_price'   => null,
                'discount_percent' => null,
                'is_discounted'    => false,
            ];
        }

        // 1. Check specific plan custom price override
        $planPrices = is_array($this->custom_plan_prices) ? $this->custom_plan_prices : [];
        $planKey = (string) $plan->id;
        if (isset($planPrices[$planKey]) && is_numeric($planPrices[$planKey])) {
            $customPrice = max(1.0, round((float) $planPrices[$planKey], 2));
            if ($customPrice < $basePrice) {
                $percent = round((($basePrice - $customPrice) / $basePrice) * 100);
                return [
                    'price'            => $customPrice,
                    'original_price'   => $basePrice,
                    'discount_percent' => $percent,
                    'is_discounted'    => true,
                ];
            }
            return [
                'price'            => $customPrice,
                'original_price'   => null,
                'discount_percent' => null,
                'is_discounted'    => false,
            ];
        }

        // 2. Fallback to general shop discount percentage
        if ($this->custom_discount_percent !== null && $this->custom_discount_percent > 0) {
            $discount = min(99.0, (float) $this->custom_discount_percent);
            $discountedPrice = max(1.0, round($basePrice * (1 - ($discount / 100.0)), 2));
            return [
                'price'            => $discountedPrice,
                'original_price'   => $basePrice,
                'discount_percent' => round($discount),
                'is_discounted'    => true,
            ];
        }

        return [
            'price'            => $basePrice,
            'original_price'   => null,
            'discount_percent' => null,
            'is_discounted'    => false,
        ];
    }

    /**
     * Get effective staff price per day for this shop.
     */
    public function getEffectiveStaffPricePerDay(): float
    {
        $defaultRate = (float) \App\Models\SystemSetting::getByKey('staff_price_per_day', '2.00');
        if (!$this->hasActiveCustomDiscount()) {
            return $defaultRate;
        }

        if ($this->custom_staff_price_per_day !== null && $this->custom_staff_price_per_day >= 0) {
            return (float) $this->custom_staff_price_per_day;
        }

        if ($this->custom_discount_percent !== null && $this->custom_discount_percent > 0) {
            $discount = min(99.0, (float) $this->custom_discount_percent);
            return max(0.5, round($defaultRate * (1 - ($discount / 100.0)), 2));
        }

        return $defaultRate;
    }

    /**
     * Get the full public URL for the shop logo.
     */
    public function getLogoUrlAttribute(): ?string
    {
        if ($this->logo) {
            return asset('storage/' . $this->logo);
        }

        return null;
    }

    /**
     * Get the owner user of the shop.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the users associated with the shop.
     */
    public function users(): HasMany
    {
        return $this->hasMany(User::class);
    }

    /**
     * Get all staff members associated with the shop.
     */
    public function staff(): HasMany
    {
        return $this->hasMany(Staff::class);
    }

    /**
     * Get all technicians associated with the shop.
     */
    public function technicians(): HasMany
    {
        return $this->hasMany(Technician::class);
    }

    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class);
    }

    public function latestSubscription()
    {
        return $this->hasOne(Subscription::class)->latestOfMany();
    }

    public function supportRequests(): HasMany
    {
        return $this->hasMany(SupportRequest::class);
    }

    public function customers(): HasMany
    {
        return $this->hasMany(Customer::class);
    }

    public function repairs(): HasMany
    {
        return $this->hasMany(Repair::class);
    }

    public function sales(): HasMany
    {
        return $this->hasMany(Sale::class);
    }

    public function devices(): HasMany
    {
        return $this->hasMany(Device::class);
    }

    public function inventoryItems(): HasMany
    {
        return $this->hasMany(InventoryItem::class);
    }

    public function referrer(): BelongsTo
    {
        return $this->belongsTo(Shop::class, 'referred_by_shop_id');
    }

    public function referredShops(): HasMany
    {
        return $this->hasMany(Shop::class, 'referred_by_shop_id');
    }

    public function referralTransactions(): HasMany
    {
        return $this->hasMany(ReferralPointTransaction::class)->latest();
    }
}
