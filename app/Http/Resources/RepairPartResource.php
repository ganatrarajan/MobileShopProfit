<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RepairPartResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'repair_id' => $this->repair_id,
            'part_name' => $this->part_name,
            'quantity' => (int) $this->quantity,
            'cost_price' => $this->cost_price !== null ? (float) $this->cost_price : null,
            'selling_price' => (float) $this->selling_price,
            'notes' => $this->notes,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}