<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UsedMobile extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'shop_id',
        'purchase_ref_number',
        'sale_invoice_number',
        'seller_name',
        'seller_phone',
        'seller_address',
        'id_proof_type',
        'id_proof_number',
        'id_proof_photo',
        'id_proof_back_photo',
        'seller_photo',
        'brand',
        'model',
        'imei1',
        'imei2',
        'serial_number',
        'color',
        'ram',
        'storage',
        'battery_health',
        'device_condition',
        'condition_notes',
        'accessories_included',
        'purchase_date',
        'purchase_price',
        'payment_mode',
        'purchase_notes',
        'repair_cost',
        'repair_details',
        'total_cost',
        'sale_date',
        'buyer_name',
        'buyer_phone',
        'buyer_address',
        'selling_price',
        'sale_payment_mode',
        'warranty_days',
        'warranty_expiry_date',
        'warranty_terms',
        'sale_notes',
        'profit',
        'status',
        'created_by',
        'sold_by',
    ];

    protected $casts = [
        'purchase_date' => 'date',
        'sale_date' => 'date',
        'warranty_expiry_date' => 'date',
        'accessories_included' => 'array',
        'purchase_price' => 'decimal:2',
        'repair_cost' => 'decimal:2',
        'total_cost' => 'decimal:2',
        'selling_price' => 'decimal:2',
        'profit' => 'decimal:2',
        'warranty_days' => 'integer',
    ];

    protected $appends = [
        'device_display_name',
        'profit_percentage',
        'is_in_stock',
        'is_sold',
    ];

    public function getDeviceDisplayNameAttribute(): string
    {
        $parts = array_filter([$this->brand, $this->model, $this->ram ? "{$this->ram}/{$this->storage}" : $this->storage]);
        return implode(' ', $parts);
    }

    public function getProfitPercentageAttribute(): float
    {
        if ($this->total_cost > 0 && $this->profit !== null) {
            return round(($this->profit / $this->total_cost) * 100, 1);
        }
        return 0.0;
    }

    public function getIsInStockAttribute(): bool
    {
        return $this->status === 'in_stock';
    }

    public function getIsSoldAttribute(): bool
    {
        return $this->status === 'sold';
    }

    public function scopeForShop($query, $shopId)
    {
        return $query->where('shop_id', $shopId);
    }

    public function scopeInStock($query)
    {
        return $query->where('status', 'in_stock');
    }

    public function scopeSold($query)
    {
        return $query->where('status', 'sold');
    }

    public function shop(): BelongsTo
    {
        return $this->belongsTo(Shop::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function seller(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sold_by');
    }

    /**
     * Generates next purchase reference number (e.g. UMB-000001).
     */
    public static function generatePurchaseRefNumber(int $shopId): string
    {
        $lastId = static::withoutGlobalScopes()
            ->where('shop_id', $shopId)
            ->max('id') ?? 0;

        return sprintf('UMB-%06d', $lastId + 1);
    }

    /**
     * Generates next sale invoice number (e.g. UMS-000001).
     */
    public static function generateSaleInvoiceNumber(int $shopId): string
    {
        $soldCount = static::withoutGlobalScopes()
            ->where('shop_id', $shopId)
            ->whereNotNull('sale_invoice_number')
            ->count();

        return sprintf('UMS-%06d', $soldCount + 1);
    }
}

