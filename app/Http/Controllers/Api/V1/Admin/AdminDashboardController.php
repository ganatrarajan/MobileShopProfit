<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\Device;
use App\Models\PaymentTransaction;
use App\Models\Repair;
use App\Models\Sale;
use App\Models\Shop;
use App\Models\Subscription;
use App\Models\User;
use App\Models\UsedMobile;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

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

        // 3. Business & Revenue: strictly track actual money paid/earned from real transactions
        $successfulTxCount = (int) PaymentTransaction::where('status', 'successful')->count();
        if ($successfulTxCount > 0) {
            $totalRevenue = (float) PaymentTransaction::where('status', 'successful')->sum('amount');
            $revenueThisMonth = (float) PaymentTransaction::where('status', 'successful')
                ->where('created_at', '>=', $startOfMonth)
                ->sum('amount');
        } else {
            // Only if payment_transactions table has no records at all (legacy fallback)
            $totalRevenue = (float) Subscription::join('plans', 'subscriptions.plan_id', '=', 'plans.id')
                ->where('subscriptions.payment_status', 'paid')
                ->sum('plans.price');
            $revenueThisMonth = (float) Subscription::join('plans', 'subscriptions.plan_id', '=', 'plans.id')
                ->where('subscriptions.payment_status', 'paid')
                ->where('subscriptions.created_at', '>=', $startOfMonth)
                ->sum('plans.price');
        }

        // Paid shops count: count distinct shops that have purchased a paid plan
        $paidShopsCount = max(
            Subscription::where('payment_status', 'paid')->distinct('shop_id')->count('shop_id'),
            PaymentTransaction::where('status', 'successful')->distinct('shop_id')->count('shop_id')
        );

        // Total successful payment transactions count
        $successfulTxCount = PaymentTransaction::where('status', 'successful')->count();
        $paidCount = max($paidShopsCount, $successfulTxCount);

        $newSubscriptionsThisMonth = Subscription::where('created_at', '>=', $startOfMonth)->count();

        // 4. Platform Usage & App Opens Overview
        $totalCustomers = Customer::withoutGlobalScope('shop')->count();
        $totalRepairs = Repair::withoutGlobalScope('shop')->count();
        $totalSales = Sale::withoutGlobalScope('shop')->count();
        $totalDevices = Device::withoutGlobalScope('shop')->count();
        $todayAppOpens = User::where(function ($q) {
            $q->whereDate('last_app_opened_at', today())
              ->orWhereDate('last_mobile_login_at', today());
        })->count();
        $todayWebLogins = User::whereDate('last_web_login_at', today())->count();
        $todayMobileShopsCount = Shop::whereDate('last_mobile_login_at', today())->count();
        $todayWebShopsCount = Shop::whereDate('last_web_login_at', today())->count();

        // 4b. Used Mobiles Feature Adoption Metrics
        $totalUsedMobiles = UsedMobile::count();
        $usedMobilesShopsCount = UsedMobile::distinct('shop_id')->count('shop_id');
        $usedMobilesInStock = UsedMobile::where('status', 'in_stock')->count();
        $usedMobilesSold = UsedMobile::where('status', 'sold')->count();
        $usedMobilesTotalProfit = (float) UsedMobile::where('status', 'sold')->sum('profit');

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
                'trial'               => $trialCount,
                'active'              => $activePaidCount,
                'expired'             => $expiredCount,
                'cancelled'           => $cancelledCount,
                'paid_count'          => $paidShopsCount,
                'paid_shops_count'    => $paidShopsCount,
                'successful_tx_count' => $successfulTxCount,
            ],
            'business' => [
                'total_revenue'       => (float) $totalRevenue,
                'revenue_this_month'  => (float) $revenueThisMonth,
                'new_subscriptions'   => $newSubscriptionsThisMonth,
                'paid_count'          => $paidCount,
                'paid_shops_count'    => $paidShopsCount,
                'successful_tx_count' => $successfulTxCount,
            ],
            'usage' => [
                'total_customers'    => $totalCustomers,
                'total_repairs'      => $totalRepairs,
                'total_sales'        => $totalSales,
                'total_devices'      => $totalDevices,
                'today_app_opens'    => $todayAppOpens,
                'today_web_logins'   => $todayWebLogins,
                'today_mobile_shops' => $todayMobileShopsCount,
                'today_web_shops'    => $todayWebShopsCount,
            ],
            'used_mobiles' => [
                'total_devices' => $totalUsedMobiles,
                'shops_count'   => $usedMobilesShopsCount,
                'in_stock'      => $usedMobilesInStock,
                'sold'          => $usedMobilesSold,
                'total_profit'  => $usedMobilesTotalProfit,
            ],
            'recent_shops' => $recentShops,
        ], 'Admin dashboard metrics retrieved successfully');
    }

    /**
     * Get the list of users who opened the mobile app today.
     */
    public function appOpensTodayUsers(Request $request): JsonResponse
    {
        $query = User::with('shop')
            ->where(function ($q) {
                $q->whereDate('last_app_opened_at', today())
                  ->orWhereDate('last_mobile_login_at', today());
            })
            ->orderByRaw('COALESCE(last_mobile_login_at, last_app_opened_at) desc');

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('mobile', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%")
                  ->orWhereHas('shop', function ($sq) use ($search) {
                      $sq->where('name', 'like', "%{$search}%");
                  });
            });
        }

        $users = $query->get();

        return $this->successResponse($users, 'Users who opened mobile app today retrieved successfully');
    }

    /**
     * Get the list of users who logged into web portal today.
     */
    public function webLoginsTodayUsers(Request $request): JsonResponse
    {
        $query = User::with('shop')
            ->whereDate('last_web_login_at', today())
            ->orderBy('last_web_login_at', 'desc');

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('mobile', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%")
                  ->orWhereHas('shop', function ($sq) use ($search) {
                      $sq->where('name', 'like', "%{$search}%");
                  });
            });
        }

        $users = $query->get();

        return $this->successResponse($users, 'Users who logged into web portal today retrieved successfully');
    }
}
