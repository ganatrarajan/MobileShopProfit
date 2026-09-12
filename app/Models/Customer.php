<?php

namespace App\Models;

use App\Traits\BelongsToShop;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Customer extends Model
{
    use SoftDeletes;
    use BelongsToShop, HasFactory;

    protected $fillable = [
        'shop_id',
        'name',
        'mobile',
        'alternate_mobile',
        'email',
        'address',
        'city',
        'notes',
    ];

    /**
     * Get the shop that owns the customer.
     */
    public function shop(): BelongsTo
    {
        return $this->belongsTo(Shop::class);
    }

    /**
     * Get the devices belonging to the customer.
     */
    public function devices(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Device::class);
    }

    /**
     * Get the sales belonging to the customer.
     */
    public function sales(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Sale::class);
    }

    /**
     * Get the repairs belonging to the customer.
     */
    public function repairs(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Repair::class);
    }

    /**
     * Get the warranties belonging to the customer.
     */
    public function warranties(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Warranty::class)->whereNull('warranties.deleted_at');
    }

    protected static function booted(): void
    {
        static::deleting(function ($customer) {
            foreach ($customer->warranties()->get() as $warranty) {
                $warranty->delete();
            }
        });
    }
}