<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\PaymentTransaction;
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

        $totalRevenue = PaymentTransaction::where('status', 'successful')->sum('amount');
        $revenueThisMonth = PaymentTransaction::where('status', 'successful')
            ->where('created_at', '>=', $startOfMonth)
            ->sum('amount');

        $paidSubscriptionsCount = Subscription::where('payment_status', 'paid')->count();
        $failedPaymentsCount = PaymentTransaction::where('status', 'failed')->count();

        $recentPayments = PaymentTransaction::with(['shop', 'user', 'plan'])
            ->where('status', 'successful')
            ->latest()
            ->paginate(15);

        return $this->successResponse([
            'total_revenue'            => (float) $totalRevenue,
            'revenue_this_month'       => (float) $revenueThisMonth,
            'paid_subscriptions_count' => $paidSubscriptionsCount,
            'failed_payments_count'    => $failedPaymentsCount,
            'recent_payments'          => $recentPayments,
        ], 'Revenue summary retrieved');
    }
}
