<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TechnicianResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'shop_id' => $this->shop_id,
            'name' => $this->name,
            'mobile' => $this->mobile,
            'specialization' => $this->specialization,
            'is_active' => (bool) $this->is_active,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
            'workload' => [
                'pending_jobs' => $this->pending_jobs_count,
                'in_progress_jobs' => $this->in_progress_jobs_count,
                'completed_jobs' => $this->completed_jobs_count,
                'total_jobs' => $this->total_jobs_count,
                'total_value_handled' => round($this->total_value_handled, 2),
                'total_earnings' => round($this->total_earnings, 2),
                'total_paid' => round($this->total_paid, 2),
                'total_payable' => round($this->total_payable, 2),
            ],
            'recent_jobs' => RepairResource::collection($this->whenLoaded('repairs')),
        ];
    }
}