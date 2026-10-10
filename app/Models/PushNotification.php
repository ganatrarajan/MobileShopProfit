<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class PushNotification extends Model
{
    use HasFactory;

    protected $fillable = [
        "title",
        "description",
        "image_url",
        "target_type",
        "target_user_ids",
        "recipients_count",
        "created_by",
        "sent_at",
    ];

    protected function casts(): array
    {
        return [
            "target_user_ids" => "array",
            "recipients_count" => "integer",
            "sent_at" => "datetime",
        ];
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, "created_by");
    }

    public function userNotifications(): HasMany
    {
        return $this->hasMany(UserNotification::class, "push_notification_id");
    }
}
