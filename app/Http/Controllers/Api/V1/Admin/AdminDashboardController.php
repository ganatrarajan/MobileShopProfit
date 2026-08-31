<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\Device;
use App\Models\Repair;
use App\Models\Sale;
use App\Models\Shop;
use App\Models\Subscription;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;

class AdminDashboardController extends Controller
{
    use ApiResponse;

    public function index(): JsonResponse
    {
        $now = now();
        $startOfMonth = $now->copy()->startOfMonth();

        // 1. Shops Summary
        $totalShops = Shop::count();
        $activeShops = Shop::where('status', 'active')->count();
        $inactiveShops = Shop::where('status', '!=', 'active')->count();
        $newShopsThisMonth = Shop::where('created_at', '>=', $startOfMonth)->count();

        // 2. Subscriptions Summary
        $trialCount = Subscription::where('status', 'trial')->count();
        $activePaidCount = Subscription::where('status', 'active')->count();
        $expiredCount = Subscription::where('status', 'expired')->count();
        $cancelledCount = Subscription::where('status', 'cancelled')->count();

        // 3. Business & Revenue
        $totalRevenue = Subscription::join('plans', 'subscriptions.plan_id', '=', 'plans.id')
            ->where('subscriptions.payment_status', 'paid')
            ->sum('plans.price');

        $revenueThisMonth = Subscription::join('plans', 'subscriptions.plan_id', '=', 'plans.id')
            ->where('subscriptions.payment_status', 'paid')
            ->where('subscriptions.created_at', '>=', $startOfMonth)
            ->sum('plans.price');

        $newSubscriptionsThisMonth = Subscription::where('created_at', '>=', $startOfMonth)->count();

        // 4. Platform Usage Overview (bypass shop scope for admin aggregation)
        $totalCustomers = Customer::withoutGlobalScope('shop')->count();
        $totalRepairs = Repair::withoutGlobalScope('shop')->count();
        $totalSales = Sale::withoutGlobalScope('shop')->count();
        $totalDevices = Device::withoutGlobalScope('shop')->count();

        // 5. Recent Shops List (Last 5)
        $recentShops = Shop::with(['user', 'latestSubscription.plan'])
            ->latest()
            ->take(5)
            ->get();

        return $this->successResponse([
            'shops' => [
                'total'      => $totalShops,
                'active'     => $activeShops,
                'inactive'   => $inactiveShops,
                'new_month'  => $newShopsThisMonth,
            ],
            'subscriptions' => [
                'trial'      => $trialCount,
                'active'     => $activePaidCount,
                'expired'    => $expiredCount,
                'cancelled'  => $cancelledCount,
            ],
            'business' => [
                'total_revenue'       => (float) $totalRevenue,
                'revenue_this_month'  => (float) $revenueThisMonth,
                'new_subscriptions'   => $newSubscriptionsThisMonth,
            ],
            'usage' => [
                'total_customers' => $totalCustomers,
                'total_repairs'   => $totalRepairs,
                'total_sales'     => $totalSales,
                'total_devices'   => $totalDevices,
            ],
            'recent_shops' => $recentShops,
        ], 'Admin dashboard metrics retrieved successfully');
    }
}
