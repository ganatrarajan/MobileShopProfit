<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'shop_id',
        'name',
        'email',
        'mobile',
        'phone',
        'role',
        'permissions',
        'password',
        'plain_password',
        'security_pin',
        'fcm_token',
        'last_app_opened_at',
        'last_mobile_login_at',
        'last_web_login_at',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'plain_password',
        'security_pin',
        'remember_token',
    ];

    /**
     * The accessors to append to the model's array form.
     *
     * @var list<string>
     */
    protected $appends = [
        'has_security_pin',
    ];

    /**
     * Determine if the user has a configured security pin.
     */
    public function getHasSecurityPinAttribute(): bool
    {
        return !empty($this->security_pin);
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at'   => 'datetime',
            'last_app_opened_at'  => 'datetime',
            'last_mobile_login_at'=> 'datetime',
            'last_web_login_at'   => 'datetime',
            'password'            => 'hashed',
            'permissions'         => 'array',
        ];
    }

    /**
     * Check if user has permission for a specific module.
     * Owner role always has unrestricted permission.
     */
    public function hasPermission(string $module): bool
    {
        if ($this->role === 'owner' || empty($this->role)) {
            return true;
        }

        if (empty($this->permissions)) {
            return in_array($module, ['repairs', 'sales']);
        }

        return (bool) ($this->permissions[$module] ?? false);
    }

    /**
     * Get staff profile associated with user.
     */
    public function staff()
    {
        return $this->hasOne(Staff::class, 'user_id');
    }

    /**
     * Get technician profile associated with user.
     */
    public function technician()
    {
        return $this->hasOne(Technician::class, 'user_id');
    }

    /**
     * Get the shop associated with the user.
     */
    public function shop(): BelongsTo
    {
        return $this->belongsTo(Shop::class);
    }
}
