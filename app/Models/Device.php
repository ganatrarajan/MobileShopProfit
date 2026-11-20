<?php

namespace App\Models;

use App\Traits\BelongsToShop;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Device extends Model
{
    use SoftDeletes;
    use BelongsToShop, HasFactory;

    protected $fillable = [
        'shop_id',
        'customer_id',
        'device_type',
        'brand',
        'model',
        'variant',
        'color',
        'imei_1',
        'imei_2',
        'serial_number',
        'purchase_date',
        'notes',
    ];

    protected $casts = [
        'purchase_date' => 'date',
    ];

    /**
     * Get the shop that owns the device.
     */
    public function shop(): BelongsTo
    {
        return $this->belongsTo(Shop::class);
    }

    /**
     * Get the customer that owns the device.
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    /**
     * Get the warranties belonging to the device.
     */
    public function warranties(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Warranty::class)->whereNull('warranties.deleted_at');
    }

    /**
     * Get the repair job cards belonging to the device.
     */
    public function repairs(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Repair::class)->whereNull('repairs.deleted_at');
    }

    /**
     * Get sales & invoice records linked to the device.
     */
    public function sales(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Sale::class)->whereNull('sales.deleted_at');
    }

    protected static function booted(): void
    {
        static::deleting(function ($device) {
            foreach ($device->warranties()->get() as $warranty) {
                $warranty->delete();
            }
        });
    }
}
