<?php

namespace App\Services\ProfitIntelligence;

class ProfitIntelligenceService
{
    protected RepairAnalysisService $repairAnalysis;
    protected StockAnalysisService $stockAnalysis;
    protected WarrantyAnalysisService $warrantyAnalysis;
    protected PaymentAnalysisService $paymentAnalysis;
    protected ProductAnalysisService $productAnalysis;

    public function __construct(
        RepairAnalysisService $repairAnalysis,
        StockAnalysisService $stockAnalysis,
        WarrantyAnalysisService $warrantyAnalysis,
        PaymentAnalysisService $paymentAnalysis,
        ProductAnalysisService $productAnalysis
    ) {
        $this->repairAnalysis = $repairAnalysis;
        $this->stockAnalysis = $stockAnalysis;
        $this->warrantyAnalysis = $warrantyAnalysis;
        $this->paymentAnalysis = $paymentAnalysis;
        $this->productAnalysis = $productAnalysis;
    }

    public function getIntelligenceSummary(int $shopId): array
    {
        $repairResult = $this->repairAnalysis->analyze($shopId);
        $stockResult = $this->stockAnalysis->analyze($shopId);
        $warrantyResult = $this->warrantyAnalysis->analyze($shopId);
        $paymentResult = $this->paymentAnalysis->analyze($shopId);
        $productResult = $this->productAnalysis->analyze($shopId);

        // Compute Potential Extra Profit
        $potentialExtraProfit = 0.0;
        if ($repairResult['has_enough_data']) {
            $potentialExtraProfit += $repairResult['potential_extra_profit'];
        }
        if ($paymentResult['has_enough_data']) {
            $potentialExtraProfit += $paymentResult['total_outstanding'];
        }

        // Compute Business Health Score (0-100)
        $healthScore = 100;
        $deductions = [];

        if ($paymentResult['has_enough_data'] && $paymentResult['pending_customers_count'] > 0) {
            $pts = min(20, $paymentResult['pending_customers_count'] * 5);
            $healthScore -= $pts;
            $deductions[] = "₹" . number_format($paymentResult['total_outstanding'], 0) . " in pending customer dues ({$paymentResult['pending_customers_count']} unpaid invoices).";
        }

        if ($stockResult['has_enough_data'] && ($stockResult['slow_moving_count'] > 0 || $stockResult['dead_stock_count'] > 0)) {
            $totSlow = $stockResult['slow_moving_count'] + $stockResult['dead_stock_count'];
            $pts = min(20, $totSlow * 4);
            $healthScore -= $pts;
            $deductions[] = "₹" . number_format($stockResult['slow_moving_value'] + $stockResult['dead_stock_value'], 0) . " capital tied in slow-moving/dead stock ({$totSlow} items).";
        }

        if ($repairResult['has_enough_data'] && $repairResult['underpriced_count'] > 0) {
            $pts = min(15, $repairResult['underpriced_count'] * 3);
            $healthScore -= $pts;
            $deductions[] = "{$repairResult['underpriced_count']} repair services priced below your shop average rate.";
        }

        if ($productResult['has_enough_data'] && $productResult['low_margin_count'] > 0) {
            $pts = min(15, $productResult['low_margin_count'] * 3);
            $healthScore -= $pts;
            $deductions[] = "{$productResult['low_margin_count']} products earning less than 15% profit margin.";
        }

        if ($warrantyResult['has_enough_data'] && $warrantyResult['rework_claims_count'] > 0) {
            $pts = min(15, $warrantyResult['rework_claims_count'] * 5);
            $healthScore -= $pts;
            $deductions[] = "{$warrantyResult['rework_claims_count']} warranty rework claims incurring unexpected labor/parts costs.";
        }

        $healthScore = max(0, min(100, $healthScore));

        return [
            'business_health' => [
                'score' => $healthScore,
                'rating' => $healthScore >= 80 ? 'Excellent' : ($healthScore >= 60 ? 'Good' : 'Needs Attention'),
                'deduction_reasons' => $deductions,
            ],
            'potential_extra_profit' => round($potentialExtraProfit, 2),
            'potential_extra_profit_formatted' => "You could increase your monthly profit by approximately ₹" . number_format($potentialExtraProfit, 0) . ".",
            'cards' => [
                'underpriced_repairs' => [
                    'title' => 'Underpriced Repairs',
                    'category' => 'underpriced_repairs',
                    'count' => $repairResult['underpriced_count'],
                    'financial_impact' => $repairResult['potential_extra_profit'],
                    'has_enough_data' => $repairResult['has_enough_data'],
                    'message' => $repairResult['has_enough_data'] 
                        ? "{$repairResult['underpriced_count']} repairs have lower profit than your shop average." 
                        : $repairResult['message'],
                ],
                'slow_moving_stock' => [
                    'title' => 'Slow Moving / Dead Stock',
                    'category' => 'slow_moving_stock',
                    'count' => $stockResult['slow_moving_count'] + $stockResult['dead_stock_count'],
                    'financial_impact' => round($stockResult['slow_moving_value'] + $stockResult['dead_stock_value'], 2),
                    'has_enough_data' => $stockResult['has_enough_data'],
                    'message' => $stockResult['has_enough_data']
                        ? "{$stockResult['slow_moving_count']} slow items (>90 days) and {$stockResult['dead_stock_count']} dead items (>180 days)."
                        : $stockResult['message'],
                ],
                'warranty_loss' => [
                    'title' => 'Warranty / Rework Loss',
                    'category' => 'warranty_loss',
                    'count' => $warrantyResult['rework_claims_count'],
                    'financial_impact' => $warrantyResult['estimated_loss'],
                    'has_enough_data' => $warrantyResult['has_enough_data'],
                    'message' => $warrantyResult['has_enough_data']
                        ? "{$warrantyResult['rework_claims_count']} warranty repair claims came back for rework."
                        : $warrantyResult['message'],
                ],
                'pending_payments' => [
                    'title' => 'Pending Customer Payments',
                    'category' => 'pending_payments',
                    'count' => $paymentResult['pending_customers_count'],
                    'financial_impact' => $paymentResult['total_outstanding'],
                    'has_enough_data' => $paymentResult['has_enough_data'],
                    'message' => $paymentResult['has_enough_data']
                        ? "{$paymentResult['pending_customers_count']} customers still owe you money."
                        : $paymentResult['message'],
                ],
                'low_margin_products' => [
                    'title' => 'Low Margin Products',
                    'category' => 'low_margin_products',
                    'count' => $productResult['low_margin_count'],
                    'financial_impact' => 0.0,
                    'has_enough_data' => $productResult['has_enough_data'],
                    'message' => $productResult['has_enough_data']
                        ? "{$productResult['low_margin_count']} products have less than 15% profit margin."
                        : $productResult['message'],
                ],
            ],
        ];
    }

    public function getCategoryDetails(int $shopId, string $category): array
    {
        switch ($category) {
            case 'underpriced_repairs':
                return $this->repairAnalysis->analyze($shopId);
            case 'slow_moving_stock':
                $res = $this->stockAnalysis->analyze($shopId);
                return [
                    'has_enough_data' => $res['has_enough_data'],
                    'details' => array_merge($res['slow_moving_details'], $res['dead_stock_details']),
                ];
            case 'warranty_loss':
                return $this->warrantyAnalysis->analyze($shopId);
            case 'pending_payments':
                return $this->paymentAnalysis->analyze($shopId);
            case 'low_margin_products':
                return $this->productAnalysis->analyze($shopId);
            default:
                return ['has_enough_data' => false, 'message' => 'Invalid category.', 'details' => []];
        }
    }
}