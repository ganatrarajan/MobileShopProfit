<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\BusinessAssistant\BusinessAssistantService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BusinessAssistantController extends Controller
{
    protected BusinessAssistantService $assistantService;

    public function __construct(BusinessAssistantService $assistantService)
    {
        $this->assistantService = $assistantService;
    }

    /**
     * GET /api/v1/business-assistant
     * Returns top business recommendations for shop owner action.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        if (!$shopId) {
            return response()->json([
                'success' => false,
                'message' => 'No active shop associated with user.',
            ], 400);
        }

        $result = $this->assistantService->getRecommendations($shopId);

        return response()->json([
            'success' => true,
            'message' => 'Business recommendations fetched successfully.',
            'data' => $result,
        ]);
    }
}
