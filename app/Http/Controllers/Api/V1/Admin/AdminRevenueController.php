<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Subscription;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;

class AdminRevenueController extends Controller
{
    use ApiResponse;

    public function index(): JsonResponse
    {
        $now = now();
        $startOfMonth = $now->copy()->startOfMonth();

        $totalRevenue = Subscription::join('plans', 'subscriptions.plan_id', '=', 'plans.id')
            ->where('subscriptions.payment_status', 'paid')
            ->sum('plans.price');

        $revenueThisMonth = Subscription::join('plans', 'subscriptions.plan_id', '=', 'plans.id')
            ->where('subscriptions.payment_status', 'paid')
            ->where('subscriptions.created_at', '>=', $startOfMonth)
            ->sum('plans.price');

        $paidSubscriptionsCount = Subscription::where('payment_status', 'paid')->count();

        $recentPayments = Subscription::with(['shop.user', 'plan'])
            ->where('payment_status', 'paid')
            ->latest()
            ->paginate(15);

        return $this->successResponse([
            'total_revenue'            => (float) $totalRevenue,
            'revenue_this_month'       => (float) $revenueThisMonth,
            'paid_subscriptions_count' => $paidSubscriptionsCount,
            'recent_payments'          => $recentPayments,
        ], 'Revenue summary retrieved');
    }
}
