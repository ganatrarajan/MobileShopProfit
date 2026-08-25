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
}
