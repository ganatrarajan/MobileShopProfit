<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RepairPart extends Model
{
    use HasFactory;

    protected $fillable = [
        'repair_id',
        'part_name',
        'quantity',
        'cost_price',
        'selling_price',
        'notes',
    ];

    protected $casts = [
        'cost_price' => 'decimal:2',
        'selling_price' => 'decimal:2',
        'quantity' => 'integer',
    ];

    public function repair(): BelongsTo
    {
        return $this->belongsTo(Repair::class);
    }
}