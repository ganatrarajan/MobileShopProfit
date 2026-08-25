<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreExpenseCategoryRequest;
use App\Http\Resources\ExpenseCategoryResource;
use App\Models\ExpenseCategory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class ExpenseCategoryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        $categories = ExpenseCategory::forShop($shopId)
            ->orderBy('is_system_default', 'desc')
            ->orderBy('name', 'asc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => ExpenseCategoryResource::collection($categories),
        ]);
    }

    public function store(StoreExpenseCategoryRequest $request): JsonResponse
    {
        $user = $request->user();
        $shopId = $user->shop_id ?? $user->shop?->id;

        if (!$shopId) {
            return response()->json(['message' => 'No active shop associated with user.'], 400);
        }

        $validated = $request->validated();
        $slug = Str::slug($validated['name']);

        // Check if category already exists for shop or system defaults
        $exists = ExpenseCategory::forShop($shopId)->where('slug', $slug)->exists();
        if ($exists) {
            return response()->json(['message' => 'Category name already exists.'], 422);
        }

        $category = ExpenseCategory::create([
            'shop_id' => $shopId,
            'name' => $validated['name'],
            'slug' => $slug,
            'is_system_default' => false,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Custom expense category created successfully.',
            'data' => new ExpenseCategoryResource($category),
        ], 201);
    }
}