<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserNotification extends Model
{
    use HasFactory;

    protected $fillable = [
        "user_id",
        "push_notification_id",
        "title",
        "description",
        "image_url",
        "is_read",
        "read_at",
    ];

    protected function casts(): array
    {
        return [
            "is_read" => "boolean",
            "read_at" => "datetime",
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function pushNotification(): BelongsTo
    {
        return $this->belongsTo(PushNotification::class);
    }
}
