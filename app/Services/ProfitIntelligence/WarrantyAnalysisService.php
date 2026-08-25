<?php

namespace App\Services\ProfitIntelligence;

use App\Models\Warranty;
use App\Models\WarrantyClaim;

class WarrantyAnalysisService
{
    public function analyze(int $shopId): array
    {
        $totalWarranties = Warranty::where('shop_id', $shopId)->count();

        if ($totalWarranties < 3) {
            return [
                'has_enough_data' => false,
                'message' => 'Not enough warranty data yet (need at least 3 warranty records).',
                'rework_claims_count' => 0,
                'estimated_loss' => 0.0,
                'details' => [],
            ];
        }

        $claims = WarrantyClaim::whereHas('warranty', fn($q) => $q->where('shop_id', $shopId))
            ->with(['warranty', 'customer', 'device'])
            ->get();

        $details = [];
        $totalLoss = 0.0;

        foreach ($claims as $claim) {
            $loss = 500.0;
            $totalLoss += $loss;

            $itemName = ($claim->warranty && !empty($claim->warranty->item_name)) 
                ? $claim->warranty->item_name 
                : ($claim->device ? ($claim->device->brand . ' ' . $claim->device->model) : 'Repaired Device');
                
            $custName = $claim->customer ? $claim->customer->name : 'Customer';

            $details[] = [
                'id' => $claim->id,
                'claim_number' => $claim->claim_number,
                'item_name' => $itemName,
                'customer_name' => $custName,
                'claim_date' => $claim->claim_date,
                'issue_description' => $claim->issue_description ?? 'Warranty Rework',
                'status' => $claim->claim_status,
                'estimated_loss' => round($loss, 2),
                'suggestion' => "Repeat rework claim on '{$itemName}'. Inspect replacement part quality or double-check technician testing checklist.",
            ];
        }

        return [
            'has_enough_data' => true,
            'rework_claims_count' => count($details),
            'estimated_loss' => round($totalLoss, 2),
            'details' => $details,
        ];
    }
}