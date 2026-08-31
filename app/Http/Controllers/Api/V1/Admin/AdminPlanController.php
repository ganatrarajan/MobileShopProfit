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
        $plans = Plan::withCount('subscriptions')->get();

        return $this->successResponse($plans, 'Plans retrieved successfully');
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name'           => 'required|string',
            'price'          => 'required|numeric|min:0',
            'billing_period' => 'required|string|in:monthly,annual',
        ]);

        $plan = Plan::create([
            'name'           => $request->name,
            'slug'           => Str::slug($request->name),
            'price'          => $request->price,
            'billing_period' => $request->billing_period,
            'status'         => 'active',
        ]);

        return $this->successResponse($plan, 'Plan created successfully', 201);
    }

    public function update(Request $request, $id): JsonResponse
    {
        $plan = Plan::find($id);

        if (! $plan) {
            return $this->errorResponse('Plan not found', 404);
        }

        $request->validate([
            'name'           => 'required|string',
            'price'          => 'required|numeric|min:0',
            'billing_period' => 'required|string|in:monthly,annual',
            'status'         => 'required|string|in:active,inactive',
        ]);

        $plan->update([
            'name'           => $request->name,
            'slug'           => Str::slug($request->name),
            'price'          => $request->price,
            'billing_period' => $request->billing_period,
            'status'         => $request->status,
        ]);

        return $this->successResponse($plan, 'Plan updated successfully');
    }
}
