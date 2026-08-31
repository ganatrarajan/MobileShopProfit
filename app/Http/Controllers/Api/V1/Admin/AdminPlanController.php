<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Plan;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class AdminPlanController extends Controller
{
    use ApiResponse;

    public function index(): JsonResponse
    {
        $plans = Plan::withCount('subscriptions')
            ->orderBy('sort_order', 'asc')
            ->orderBy('price', 'asc')
            ->get();

        return $this->successResponse($plans, 'Plans retrieved successfully');
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name'           => 'required|string',
            'price'          => 'required|numeric|min:0',
            'billing_period' => 'required|string|in:monthly,3_months,6_months,annual',
            'status'         => 'nullable|string|in:active,inactive',
            'sort_order'     => 'nullable|integer|min:0',
        ]);

        $plan = Plan::create([
            'name'           => $request->name,
            'slug'           => Str::slug($request->name . '-' . $request->billing_period . '-' . time()),
            'price'          => $request->price,
            'billing_period' => $request->billing_period,
            'status'         => $request->status ?? 'active',
            'sort_order'     => $request->sort_order ?? 0,
        ]);

        return $this->successResponse($plan, 'Plan created successfully', 201);
    }

    public function update(Request $request, $id): JsonResponse
    {
        $plan = Plan::find($id);

        if (!$plan) {
            return $this->errorResponse('Plan not found', 404);
        }

        $request->validate([
            'name'           => 'required|string',
            'price'          => 'required|numeric|min:0',
            'billing_period' => 'required|string|in:monthly,3_months,6_months,annual',
            'status'         => 'required|string|in:active,inactive',
            'sort_order'     => 'nullable|integer|min:0',
        ]);

        $plan->update([
            'name'           => $request->name,
            'slug'           => Str::slug($request->name . '-' . $request->billing_period),
            'price'          => $request->price,
            'billing_period' => $request->billing_period,
            'status'         => $request->status,
            'sort_order'     => $request->sort_order ?? $plan->sort_order,
        ]);

        return $this->successResponse($plan, 'Plan updated successfully');
    }

    public function toggleStatus($id): JsonResponse
    {
        $plan = Plan::find($id);

        if (!$plan) {
            return $this->errorResponse('Plan not found', 404);
        }

        $plan->status = ($plan->status === 'active') ? 'inactive' : 'active';
        $plan->save();

        return $this->successResponse($plan, 'Plan status updated to ' . $plan->status);
    }
}
