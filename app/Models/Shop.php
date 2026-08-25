<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\Storage;

class Shop extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'name',
        'owner_name',
        'phone',
        'mobile',
        'email',
        'address',
        'city',
        'state',
        'pincode',
        'gst_number',
        'logo',
        'currency',
        'status',
    ];

    protected $appends = ['logo_url'];

    /**
     * Get the full public URL for the shop logo.
     */
    public function getLogoUrlAttribute(): ?string
    {
        if ($this->logo) {
            return asset('storage/' . $this->logo);
        }

        return null;
    }

    /**
     * Get the owner user of the shop.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the users associated with the shop.
     */
    public function users(): HasMany
    {
        return $this->hasMany(User::class);
    }
}
