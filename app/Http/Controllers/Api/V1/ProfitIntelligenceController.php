<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\ProfitIntelligence\ProfitIntelligenceService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProfitIntelligenceController extends Controller
{
    protected ProfitIntelligenceService $intelligenceService;

    public function __construct(ProfitIntelligenceService $intelligenceService)
    {
        $this->intelligenceService = $intelligenceService;
    }

    /**
     * GET /api/v1/profit-intelligence
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop->id ?? null;

        if (!$shopId) {
            return response()->json([
                'success' => false,
                'message' => 'Shop not found for user.',
            ], 404);
        }

        $data = $this->intelligenceService->getIntelligenceSummary($shopId);

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }

    /**
     * GET /api/v1/profit-intelligence/details/{category}
     */
    public function details(Request $request, string $category): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop->id ?? null;

        if (!$shopId) {
            return response()->json([
                'success' => false,
                'message' => 'Shop not found for user.',
            ], 404);
        }

        $data = $this->intelligenceService->getCategoryDetails($shopId, $category);

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }
}