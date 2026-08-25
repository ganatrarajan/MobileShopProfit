<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ExpenseCategory extends Model
{
    use HasFactory;

    protected $fillable = [
        'shop_id',
        'name',
        'slug',
        'is_system_default',
    ];

    protected $casts = [
        'is_system_default' => 'boolean',
    ];

    public function scopeForShop($query, $shopId)
    {
        return $query->where(function ($q) use ($shopId) {
            $q->whereNull('shop_id')
              ->orWhere('shop_id', $shopId);
        });
    }

    public function expenses()
    {
        return $this->hasMany(Expense::class, 'category_id');
    }
}