<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ExpenseCategoryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'shop_id' => $this->shop_id,
            'name' => $this->name,
            'slug' => $this->slug,
            'is_system_default' => (bool) $this->is_system_default,
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
        ];
    }
}