<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PendingRegistration extends Model
{
    use HasFactory, HasUuids;

    protected $fillable = [
        'id',
        'mobile',
        'payload',
        'otp_code',
        'expires_at',
        'attempts',
        'verified_at',
    ];

    protected $casts = [
        'payload'     => 'array',
        'expires_at'  => 'datetime',
        'verified_at' => 'datetime',
        'attempts'    => 'integer',
    ];

    public function isExpired(): bool
    {
        return $this->expires_at->isPast();
    }
}
