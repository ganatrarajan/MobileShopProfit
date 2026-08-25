<?php

namespace App\Services\ProfitIntelligence;

use App\Models\Repair;
use Illuminate\Support\Facades\DB;

class RepairAnalysisService
{
    public function analyze(int $shopId): array
    {
        $totalRepairsCount = Repair::where('shop_id', $shopId)->count();

        if ($totalRepairsCount < 5) {
            return [
                'has_enough_data' => false,
                'message' => 'Not enough business data yet (need at least 5 repair records).',
                'underpriced_count' => 0,
                'potential_extra_profit' => 0.0,
                'details' => [],
            ];
        }

        // Group completed/delivered repairs by problem_description to find average estimated_cost
        $averages = Repair::where('shop_id', $shopId)
            ->whereIn('repair_status', ['completed', 'delivered'])
            ->whereNotNull('problem_description')
            ->select('problem_description', DB::raw('AVG(estimated_cost) as avg_cost'), DB::raw('COUNT(*) as total_count'))
            ->groupBy('problem_description')
            ->having('total_count', '>=', 1)
            ->get()
            ->keyBy('problem_description');

        $allRepairs = Repair::where('shop_id', $shopId)
            ->whereIn('repair_status', ['completed', 'delivered'])
            ->with(['customer', 'device'])
            ->get();

        $underpriced = [];
        $totalLoss = 0.0;

        foreach ($allRepairs as $repair) {
            $prob = $repair->problem_description;
            if (!$prob || !isset($averages[$prob])) {
                continue;
            }

            $avgCost = (float) $averages[$prob]->avg_cost;
            $actualCost = (float) $repair->estimated_cost;

            // If actual cost is at least 15% lower than the average for this problem type
            if ($avgCost > 0 && $actualCost < ($avgCost * 0.85)) {
                $diff = $avgCost - $actualCost;
                $totalLoss += $diff;

                $underpriced[] = [
                    'id' => $repair->id,
                    'job_number' => $repair->job_number,
                    'problem_description' => $repair->problem_description,
                    'customer_name' => $repair->customer ? $repair->customer->name : 'Customer',
                    'device' => $repair->device ? ($repair->device->brand . ' ' . $repair->device->model) : 'Device',
                    'actual_charged' => round($actualCost, 2),
                    'average_charged' => round($avgCost, 2),
                    'potential_increase' => round($diff, 2),
                    'suggestion' => "Consider raising the price for '{$repair->problem_description}' closer to your average rate of ₹" . number_format($avgCost, 0) . ".",
                ];
            }
        }

        return [
            'has_enough_data' => true,
            'underpriced_count' => count($underpriced),
            'potential_extra_profit' => round($totalLoss, 2),
            'details' => $underpriced,
        ];
    }
}