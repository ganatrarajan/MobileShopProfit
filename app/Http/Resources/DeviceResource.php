<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DeviceResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'            => $this->id,
            'shop_id'       => $this->shop_id,
            'customer_id'   => $this->customer_id,
            'device_type'   => $this->device_type,
            'brand'         => $this->brand,
            'model'         => $this->model,
            'variant'       => $this->variant,
            'color'         => $this->color,
            'imei_1'        => $this->imei_1,
            'imei_2'        => $this->imei_2,
            'serial_number' => $this->serial_number,
            'purchase_date' => $this->purchase_date?->format('Y-m-d'),
            'notes'         => $this->notes,
            'customer'         => new CustomerResource($this->whenLoaded('customer')),
            'repairs_count'    => $this->repairs_count ?? ($this->relationLoaded('repairs') ? $this->repairs->count() : 0),
            'sales_count'      => $this->sales_count ?? ($this->relationLoaded('sales') ? $this->sales->count() : 0),
            'warranties_count' => $this->warranties_count ?? ($this->relationLoaded('warranties') ? $this->warranties->count() : 0),
            'repairs'          => $this->whenLoaded('repairs', function () {
                return $this->repairs->map(function ($r) {
                    return [
                        'id'             => $r->id,
                        'job_number'     => $r->job_number,
                        'problem'        => $r->problem ?? $r->problem_description,
                        'repair_status'  => $r->repair_status,
                        'estimated_cost' => (float) $r->estimated_cost,
                        'final_cost'     => (float) $r->final_cost,
                        'amount_paid'    => (float) $r->amount_paid,
                        'amount_due'     => (float) $r->amount_due,
                        'date_received'  => $r->date_received ? \Carbon\Carbon::parse($r->date_received)->format('Y-m-d') : null,
                        'technician'     => $r->technician ? [
                            'id'   => $r->technician->id,
                            'name' => $r->technician->name,
                        ] : null,
                        'created_at'     => $r->created_at?->toIso8601String(),
                    ];
                });
            }),
            'sales'            => $this->whenLoaded('sales', function () {
                return $this->sales->map(function ($s) {
                    return [
                        'id'             => $s->id,
                        'invoice_number' => $s->invoice_number,
                        'sale_date'      => $s->sale_date ? \Carbon\Carbon::parse($s->sale_date)->format('Y-m-d') : null,
                        'grand_total'    => (float) $s->grand_total,
                        'payment_status' => $s->payment_status,
                        'payment_method' => $s->payment_method,
                        'created_at'     => $s->created_at?->toIso8601String(),
                    ];
                });
            }),
            'warranties'       => $this->whenLoaded('warranties', function () {
                return $this->warranties->map(function ($w) {
                    return [
                        'id'         => $w->id,
                        'code'       => $w->warranty_code ?? "WAR-{$w->id}",
                        'status'     => $w->status,
                        'start_date' => $w->start_date ? \Carbon\Carbon::parse($w->start_date)->format('Y-m-d') : null,
                        'end_date'   => $w->end_date ? \Carbon\Carbon::parse($w->end_date)->format('Y-m-d') : null,
                        'created_at' => $w->created_at?->toIso8601String(),
                    ];
                });
            }),
            'created_at'       => $this->created_at?->toIso8601String(),
            'updated_at'       => $this->updated_at?->toIso8601String(),
        ];
    }
}
