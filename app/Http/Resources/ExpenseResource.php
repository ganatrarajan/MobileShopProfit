<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ExpenseResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'shop_id' => $this->shop_id,
            'category_id' => $this->category_id,
            'title' => $this->title,
            'amount' => (float) $this->amount,
            'expense_date' => $this->expense_date ? $this->expense_date->format('Y-m-d') : null,
            'payment_method' => $this->payment_method ?? 'cash',
            'notes' => $this->notes,
            'reference_number' => $this->reference_number,
            'is_recurring' => (bool) $this->is_recurring,
            'recurrence_type' => $this->recurrence_type,
            'created_by' => $this->created_by,
            'creator_name' => $this->creator?->name,
            'category' => $this->whenLoaded('category', function () {
                return new ExpenseCategoryResource($this->category);
            }),
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
        ];
    }
}