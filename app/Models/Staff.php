<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Staff extends Model
{
    use HasFactory, SoftDeletes;

    protected $table = 'staff';

    protected $fillable = [
        'shop_id',
        'user_id',
        'name',
        'mobile',
        'email',
        'designation',
        'salary',
        'joining_date',
        'address',
        'notes',
        'is_active',
    ];

    protected $casts = [
        'is_active'    => 'boolean',
        'salary'       => 'decimal:2',
        'joining_date' => 'date:Y-m-d',
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

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}

