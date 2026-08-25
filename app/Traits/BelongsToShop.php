<?php

namespace App\Traits;

use App\Models\Shop;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

trait BelongsToShop
{
    /**
     * Boot the trait to attach global Shop scope and automatically set shop_id.
     */
    protected static function bootBelongsToShop(): void
    {
        static::creating(function ($model) {
            if (auth()->check() && ! $model->shop_id) {
                $model->shop_id = auth()->user()->shop_id;
            }
        });

        static::addGlobalScope('shop', function (Builder $builder) {
            if (auth()->check()) {
                $builder->where('shop_id', auth()->user()->shop_id);
            }
        });
    }

    /**
     * Get the shop that owns the model.
     */
    public function shop(): BelongsTo
    {
        return $this->belongsTo(Shop::class);
    }
}
