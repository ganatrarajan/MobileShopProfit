<?php

namespace App\Services\ProfitIntelligence;

use App\Models\Repair;
use App\Models\Sale;
use Carbon\Carbon;

class PaymentAnalysisService
{
    public function analyze(int $shopId): array
    {
        $salesCount = Sale::where('shop_id', $shopId)->count();
        $repairsCount = Repair::where('shop_id', $shopId)->count();

        if (($salesCount + $repairsCount) < 1) {
            return [
                'has_enough_data' => false,
                'message' => 'Not enough business data yet (need at least 1 sale or repair record).',
                'pending_customers_count' => 0,
                'total_outstanding' => 0.0,
                'details' => [],
            ];
        }

        $now = Carbon::now();
        $details = [];
        $totalOutstanding = 0.0;

        // 1. Pending Sales Dues
        $pendingSales = Sale::where('shop_id', $shopId)
            ->where('amount_due', '>', 0)
            ->with('customer')
            ->get();

        foreach ($pendingSales as $sale) {
            $due = (float) $sale->amount_due;
            $totalOutstanding += $due;
            $daysPending = $sale->sale_date ? $now->diffInDays(Carbon::parse($sale->sale_date)) : 0;

            $details[] = [
                'id' => 'sale_' . $sale->id,
                'type' => 'sale',
                'invoice_number' => $sale->invoice_number,
                'customer_name' => $sale->customer ? $sale->customer->name : ($sale->customer_name ?? 'Walk-in Customer'),
                'customer_mobile' => $sale->customer ? $sale->customer->mobile : ($sale->customer_mobile ?? ''),
                'amount_due' => round($due, 2),
                'days_pending' => $daysPending,
                'suggestion' => $daysPending > 30 
                    ? "Sale invoice overdue by {$daysPending} days. Send payment reminder SMS immediately."
                    : "Sale payment pending for {$daysPending} days. Follow up with customer.",
            ];
        }

        // 2. Pending Repair Dues
        $pendingRepairs = Repair::where('shop_id', $shopId)
            ->where(function ($q) {
                $q->where('amount_due', '>', 0)
                  ->orWhereRaw('(CASE WHEN final_cost > 0 THEN final_cost ELSE estimated_cost END - amount_paid) > 0');
            })
            ->whereNotIn('repair_status', ['cancelled'])
            ->with(['customer', 'device'])
            ->get();

        foreach ($pendingRepairs as $repair) {
            $totalCost = (float) ($repair->final_cost > 0 ? $repair->final_cost : $repair->estimated_cost);
            $paid = (float) $repair->amount_paid;
            $due = (float) ($repair->amount_due > 0 ? $repair->amount_due : max(0, $totalCost - $paid));

            if ($due <= 0) {
                continue;
            }

            $totalOutstanding += $due;
            $daysPending = $repair->date_received ? $now->diffInDays(Carbon::parse($repair->date_received)) : 0;

            $custName = $repair->customer ? $repair->customer->name : 'Customer';
            $deviceName = $repair->device ? ($repair->device->brand . ' ' . $repair->device->model) : 'Device';

            $details[] = [
                'id' => 'repair_' . $repair->id,
                'type' => 'repair',
                'invoice_number' => $repair->job_number,
                'customer_name' => "$custName ($deviceName)",
                'customer_mobile' => $repair->customer ? $repair->customer->mobile : '',
                'amount_due' => round($due, 2),
                'days_pending' => $daysPending,
                'suggestion' => "Unpaid repair job '{$repair->job_number}' for {$deviceName}. Collect pending balance of ₹" . number_format($due, 0) . " before delivery.",
            ];
        }

        return [
            'has_enough_data' => true,
            'pending_customers_count' => count($details),
            'total_outstanding' => round($totalOutstanding, 2),
            'details' => $details,
        ];
    }
}