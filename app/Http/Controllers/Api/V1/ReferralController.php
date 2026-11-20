<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ReferralPointTransaction;
use App\Models\Shop;
use App\Services\ReferralService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReferralController extends Controller
{
    use ApiResponse;

    /**
     * Validate a referral code during registration (public endpoint).
     */
    public function validateCode(Request $request, ReferralService $referralService): JsonResponse
    {
        $request->validate([
            'referral_code' => 'required|string|max:32',
        ]);

        $referrer = $referralService->findReferrerByCode($request->input('referral_code'));
        if (!$referrer) {
            return $this->errorResponse('Invalid referral code. Please check and try again.', 404);
        }

        $config = $referralService->resolveConfig($referrer);
        if (!$config['enabled']) {
            return $this->errorResponse('This referral code is currently inactive.', 422);
        }

        $welcomePts = (float) $config['welcome_points'];
        $msg = $welcomePts > 0
            ? "Valid code from {$referrer->name}! You will receive {$welcomePts} welcome points."
            : "Valid code from {$referrer->name}!";

        return $this->successResponse([
            'valid'          => true,
            'referral_code'  => $referrer->referral_code,
            'referrer_shop'  => $referrer->name,
            'welcome_points' => $welcomePts,
        ], $msg);
    }

    /**
     * Get the authenticated shop's dynamic referral config, wallet balance, referrals list, and passbook.
     */
    public function summary(Request $request, ReferralService $referralService): JsonResponse
    {
        $user = $request->user();
        if (!$user || !$user->shop_id) {
            return $this->errorResponse('Shop account required.', 400);
        }

        $shop = Shop::find($user->shop_id);
        if (!$shop) {
            return $this->errorResponse('Shop not found.', 404);
        }

        $config = $referralService->resolveConfig($shop);

        $baseAppLink = !empty($config['app_link'])
            ? $config['app_link']
            : 'https://play.google.com/store/apps/details?id=com.repairehub';

        $separator = str_contains($baseAppLink, '?') ? '&' : '?';
        $shareLink = $baseAppLink . $separator . 'referrer=REF_' . $shop->referral_code;

        $shareMessage = "Manage your Mobile Shop Repairs, Inventory, Billing & Profit easily! "
            . "Download the app here: {$shareLink} "
            . "and use my Referral Code *{$shop->referral_code}* during signup.";

        if ($config['welcome_points'] > 0) {
            $shareMessage .= " You get {$config['welcome_points']} bonus points!";
        }

        $totalEarned = (float) ReferralPointTransaction::where('shop_id', $shop->id)
            ->where('type', 'credit')
            ->sum('points');

        $totalRedeemed = (float) ReferralPointTransaction::where('shop_id', $shop->id)
            ->where('type', 'debit')
            ->sum('points');

        // Referred shops + proper details (name, owner, city, phone, status, last payment, all payments)
        $referredShops = Shop::where('referred_by_shop_id', $shop->id)
            ->with(['subscriptions.plan'])
            ->orderByDesc('created_at')
            ->get(['id', 'name', 'owner_name', 'phone', 'city', 'status', 'created_at']);

        $referredShopIds = $referredShops->pluck('id')->all();

        // All payment transactions by referred shops
        $paymentTransactions = \App\Models\PaymentTransaction::whereIn('shop_id', $referredShopIds)
            ->where('status', 'successful')
            ->with('plan')
            ->orderByDesc('id')
            ->get()
            ->groupBy('shop_id');

        // All commission transactions earned from these referred shops
        $commissionTransactions = ReferralPointTransaction::where('shop_id', $shop->id)
            ->whereIn('related_shop_id', $referredShopIds)
            ->where('type', 'credit')
            ->orderByDesc('id')
            ->get()
            ->groupBy('related_shop_id');

        $referralsList = $referredShops->map(function ($rs) use ($paymentTransactions, $commissionTransactions) {
            $shopPayTxs = $paymentTransactions->get($rs->id, collect());
            $shopCommTxs = $commissionTransactions->get($rs->id, collect());

            $totalEarnedFromShop = (float) $shopCommTxs->sum('points');

            // Build detailed payments list for this referred shop
            $payments = [];

            // 1. Paid Recharges / Subscriptions
            foreach ($shopPayTxs as $pt) {
                // Find matching commission in ReferralPointTransaction
                $comm = $shopCommTxs->firstWhere('payment_transaction_id', $pt->id);
                $commPoints = $comm ? (float) $comm->points : 0.0;
                $commPercent = $comm && isset($comm->meta['commission_percent']) ? (float) $comm->meta['commission_percent'] : null;

                $payments[] = [
                    'id'                 => 'pay_' . $pt->id,
                    'type'               => 'recharge',
                    'title'              => $pt->plan ? $pt->plan->name : 'Subscription Plan',
                    'amount'             => (float) $pt->amount,
                    'payment_method'     => $pt->payment_method ?: 'Online',
                    'status'             => 'Success',
                    'date'               => $pt->created_at?->format('d M Y, h:i A'),
                    'raw_date'           => $pt->created_at?->toIso8601String(),
                    'commission_earned'  => $commPoints,
                    'commission_percent' => $commPercent,
                    'commission_status'  => $commPoints > 0 ? 'Credited' : 'No Commission',
                ];
            }

            // 2. Signup Bonus (if any)
            $signupComm = $shopCommTxs->firstWhere('source', 'signup_bonus');
            if ($signupComm) {
                $payments[] = [
                    'id'                 => 'signup_' . $signupComm->id,
                    'type'               => 'signup_bonus',
                    'title'              => 'Signup Referral Reward',
                    'amount'             => 0.0,
                    'payment_method'     => 'Referral Bonus',
                    'status'             => 'Success',
                    'date'               => $signupComm->created_at?->format('d M Y, h:i A'),
                    'raw_date'           => $signupComm->created_at?->toIso8601String(),
                    'commission_earned'  => (float) $signupComm->points,
                    'commission_percent' => null,
                    'commission_status'  => 'Credited',
                ];
            }

            // Sort payments by raw_date desc
            usort($payments, function ($a, $b) {
                return strcmp($b['raw_date'] ?? '', $a['raw_date'] ?? '');
            });

            // Last payment summary: prefer actual subscription recharge, fallback to signup bonus
            $latestRecharge = collect($payments)->firstWhere('type', 'recharge');
            $signupReward = collect($payments)->firstWhere('type', 'signup_bonus');

            $lastPayment = null;
            if ($latestRecharge) {
                $lastPayment = [
                    'type'               => 'recharge',
                    'amount'             => (float) $latestRecharge['amount'],
                    'plan_name'          => $latestRecharge['title'],
                    'date'               => $latestRecharge['date'],
                    'commission_earned'  => (float) $latestRecharge['commission_earned'],
                    'commission_percent' => $latestRecharge['commission_percent'],
                ];
            } elseif ($signupReward) {
                $lastPayment = [
                    'type'               => 'signup_bonus',
                    'amount'             => 0.0,
                    'plan_name'          => 'Signup Referral Reward',
                    'date'               => $signupReward['date'],
                    'commission_earned'  => (float) $signupReward['commission_earned'],
                    'commission_percent' => null,
                ];
            }

            // Active plan status
            $latestSub = $rs->subscriptions->sortByDesc('id')->first();
            $planStatus = 'No Active Plan';
            if ($latestSub && $latestSub->status === 'active' && $latestSub->expiry_date && $latestSub->expiry_date->isFuture()) {
                $planName = $latestSub->plan?->name ?? 'Plan';
                $planStatus = "Active ({$planName})";
            } elseif ($latestSub) {
                $planStatus = 'Expired';
            }

            return [
                'id'                      => $rs->id,
                'shop_name'               => $rs->name,
                'owner_name'              => $rs->owner_name ?: 'Shop Owner',
                'phone'                   => $rs->phone ?: '',
                'city'                    => $rs->city ?: 'Not Specified',
                'status'                  => $rs->status ?: 'active',
                'plan_status'             => $planStatus,
                'joined_at'               => $rs->created_at?->format('d M Y'),
                'total_commission_earned' => round($totalEarnedFromShop, 2),
                'last_payment'            => $lastPayment,
                'payments'                => $payments,
            ];
        })->values();

        $transactions = ReferralPointTransaction::where('shop_id', $shop->id)
            ->orderByDesc('id')
            ->limit(50)
            ->get()
            ->map(function ($tx) {
                return [
                    'id'            => $tx->id,
                    'type'          => $tx->type,
                    'source'        => $tx->source,
                    'points'        => (float) $tx->points,
                    'balance_after' => (float) $tx->balance_after,
                    'description'   => $tx->description,
                    'date'          => $tx->created_at?->format('d M Y, h:i A'),
                ];
            })->values();

        return $this->successResponse([
            'config'          => $config,
            'referral_code'   => $shop->referral_code,
            'share_link'      => $shareLink,
            'share_message'   => $shareMessage,
            'points_balance'  => (float) ($shop->referral_points_balance ?? 0),
            'total_earned'    => round($totalEarned, 2),
            'total_redeemed'  => round($totalRedeemed, 2),
            'referrals_count' => $referralsList->count(),
            'referrals'       => $referralsList,
            'transactions'    => $transactions,
        ], 'Referral summary retrieved');
    }

    /**
     * Get detailed payments and commission breakdown for a specific referred shop.
     */
    public function referredShopPayments(int $shopId, Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user || !$user->shop_id) {
            return $this->errorResponse('Shop account required.', 400);
        }

        $myShop = Shop::find($user->shop_id);
        if (!$myShop) {
            return $this->errorResponse('Shop not found.', 404);
        }

        $referredShop = Shop::where('id', $shopId)
            ->where('referred_by_shop_id', $myShop->id)
            ->with(['subscriptions.plan'])
            ->first();

        if (!$referredShop) {
            return $this->errorResponse('Referred shop not found.', 404);
        }

        $paymentTxs = \App\Models\PaymentTransaction::where('shop_id', $referredShop->id)
            ->where('status', 'successful')
            ->with('plan')
            ->orderByDesc('id')
            ->get();

        $commTxs = ReferralPointTransaction::where('shop_id', $myShop->id)
            ->where('related_shop_id', $referredShop->id)
            ->where('type', 'credit')
            ->orderByDesc('id')
            ->get();

        $payments = [];

        foreach ($paymentTxs as $pt) {
            $comm = $commTxs->firstWhere('payment_transaction_id', $pt->id);
            $commPoints = $comm ? (float) $comm->points : 0.0;
            $commPercent = $comm && isset($comm->meta['commission_percent']) ? (float) $comm->meta['commission_percent'] : null;

            $payments[] = [
                'id'                 => 'pay_' . $pt->id,
                'type'               => 'recharge',
                'title'              => $pt->plan ? $pt->plan->name : 'Subscription Plan',
                'amount'             => (float) $pt->amount,
                'payment_method'     => $pt->payment_method ?: 'Online',
                'status'             => 'Success',
                'date'               => $pt->created_at?->format('d M Y, h:i A'),
                'raw_date'           => $pt->created_at?->toIso8601String(),
                'commission_earned'  => $commPoints,
                'commission_percent' => $commPercent,
                'commission_status'  => $commPoints > 0 ? 'Credited' : 'No Commission',
            ];
        }

        $signupComm = $commTxs->firstWhere('source', 'signup_bonus');
        if ($signupComm) {
            $payments[] = [
                'id'                 => 'signup_' . $signupComm->id,
                'type'               => 'signup_bonus',
                'title'              => 'Signup Referral Reward',
                'amount'             => 0.0,
                'payment_method'     => 'Referral Bonus',
                'status'             => 'Success',
                'date'               => $signupComm->created_at?->format('d M Y, h:i A'),
                'raw_date'           => $signupComm->created_at?->toIso8601String(),
                'commission_earned'  => (float) $signupComm->points,
                'commission_percent' => null,
                'commission_status'  => 'Credited',
            ];
        }

        usort($payments, function ($a, $b) {
            return strcmp($b['raw_date'] ?? '', $a['raw_date'] ?? '');
        });

        return $this->successResponse([
            'shop' => [
                'id'                      => $referredShop->id,
                'shop_name'               => $referredShop->name,
                'owner_name'              => $referredShop->owner_name ?: 'Shop Owner',
                'phone'                   => $referredShop->phone ?: '',
                'city'                    => $referredShop->city ?: 'Not Specified',
                'status'                  => $referredShop->status ?: 'active',
                'joined_at'               => $referredShop->created_at?->format('d M Y'),
                'total_commission_earned' => round((float) $commTxs->sum('points'), 2),
            ],
            'payments' => $payments,
        ], 'Payments and commissions retrieved.');
    }
}

