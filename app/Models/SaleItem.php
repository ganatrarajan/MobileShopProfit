<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class SaleItem extends Model
{
    use SoftDeletes;
    use HasFactory;

    protected $fillable = [
        'sale_id',
        'inventory_item_id',
        'product_name',
        'item_type',
        'brand',
        'model',
        'imei_1',
        'imei_2',
        'serial_number',
        'quantity',
        'unit_price',
        'discount',
        'tax_amount',
        'cost_price',
        'total',
    ];

    protected $casts = [
        'quantity' => 'integer',
        'unit_price' => 'decimal:2',
        'discount' => 'decimal:2',
        'tax_amount' => 'decimal:2',
        'cost_price' => 'decimal:2',
        'total' => 'decimal:2',
    ];

    public function sale()
    {
        return $this->belongsTo(Sale::class);
    }

    public function inventoryItem()
    {
        return $this->belongsTo(InventoryItem::class, 'inventory_item_id');
    }

    public function getEffectiveCostPriceAttribute(): float
    {
        if ($this->cost_price !== null && (float) $this->cost_price > 0) {
            return (float) $this->cost_price;
        }
        if ($this->inventory_item_id && $this->inventoryItem) {
            return (float) ($this->inventoryItem->purchase_price ?? 0);
        }
        return 0.0;
    }
}