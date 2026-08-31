<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\Subscription;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminSubscriptionController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $query = Subscription::with(['shop.user', 'plan']);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('search')) {
            $search = $request->search;
            $query->whereHas('shop', function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('owner_name', 'like', "%{$search}%");
            });
        }

        $perPage = (int) $request->input('per_page', 15);
        $subscriptions = $query->latest()->paginate($perPage);

        return $this->successResponse($subscriptions, 'Subscriptions list retrieved');
    }

    public function updateStatus(Request $request, $id): JsonResponse
    {
        $request->validate([
            'plan_id'        => 'nullable|exists:plans,id',
            'status'         => 'required|string|in:trial,active,expired,cancelled',
            'expiry_date'    => 'nullable|date',
            'payment_status' => 'required|string|in:free,paid,pending',
        ]);

        $subscription = Subscription::find($id);

        if (! $subscription) {
            return $this->errorResponse('Subscription not found', 404);
        }

        $oldStatus = $subscription->status;

        $subscription->update([
            'plan_id'        => $request->plan_id ?? $subscription->plan_id,
            'status'         => $request->status,
            'expiry_date'    => $request->expiry_date ? now()->parse($request->expiry_date) : $subscription->expiry_date,
            'payment_status' => $request->payment_status,
        ]);

        // Audit Log
        AdminAuditLog::create([
            'admin_id'    => $request->user()->id,
            'action'      => 'UPDATE_SUBSCRIPTION',
            'target_type' => 'Subscription',
            'target_id'   => $subscription->id,
            'details'     => "Updated subscription status for shop #{$subscription->shop_id} from {$oldStatus} to {$request->status}.",
            'ip_address'  => $request->ip(),
        ]);

        return $this->successResponse($subscription->load(['shop.user', 'plan']), 'Subscription updated successfully');
    }
}
