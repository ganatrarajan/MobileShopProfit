<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class InventoryItem extends Model
{

    protected static function booted(): void
    {
        static::creating(function ($item) {
            if ($item->opening_stock === null) {
                $item->opening_stock = (int) ($item->current_stock ?? 0);
            }
        });
    }

    use SoftDeletes;
    use HasFactory;

    protected $fillable = [
        'shop_id',
        'name',
        'category',
        'brand',
        'model',
        'sku',
        'item_type',
        'purchase_price',
        'selling_price',
        'opening_stock',
        'current_stock',
        'minimum_stock',
        'unit',
        'description',
        'is_active',
    ];

    protected $casts = [
        'purchase_price' => 'decimal:2',
        'selling_price' => 'decimal:2',
        'opening_stock' => 'integer',
        'current_stock' => 'integer',
        'minimum_stock' => 'integer',
        'is_active' => 'boolean',
    ];

    protected $appends = [
        'stock_value',
        'is_low_stock',
        'is_out_of_stock',
    ];

    public function scopeForShop($query, $shopId)
    {
        return $query->where('shop_id', $shopId);
    }

    public function shop(): BelongsTo
    {
        return $this->belongsTo(Shop::class);
    }

    public function stockMovements(): HasMany
    {
        return $this->hasMany(StockMovement::class)->latest();
    }

    public function serials(): HasMany
    {
        return $this->hasMany(InventorySerial::class);
    }

    public function getStockValueAttribute(): float
    {
        return (float) ($this->current_stock * $this->purchase_price);
    }

    public function getIsLowStockAttribute(): bool
    {
        return $this->current_stock <= $this->minimum_stock && $this->current_stock > 0;
    }

    public function getIsOutOfStockAttribute(): bool
    {
        return $this->current_stock <= 0;
    }

    /**
     * Recalculate and persist exact current stock based on opening stock and movement history.
     */
    public function recalculateStock(): int
    {
        $hasOpeningMovement = $this->stockMovements()
            ->where('movement_type', 'opening_stock')
            ->exists();

        $movementsSum = (int) $this->stockMovements()
            ->where('movement_type', '!=', 'opening_stock')
            ->sum('quantity');

        if ($hasOpeningMovement) {
            $openingMovementQty = (int) $this->stockMovements()
                ->where('movement_type', 'opening_stock')
                ->value('quantity');
            $newStock = $openingMovementQty + $movementsSum;
        } else {
            $newStock = (int) ($this->opening_stock ?? 0) + $movementsSum;
        }

        if ($this->current_stock !== $newStock) {
            $this->forceFill(['current_stock' => $newStock])->save();
        }

        return $newStock;
    }
}