<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\PaymentGatewayConfig;
use App\Models\PaymentTransaction;
use App\Models\Plan;
use App\Models\Shop;
use App\Models\Subscription;
use App\Services\Payment\RazorpayDriver;
use App\Services\ReferralService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Exception;

class SubscriptionController extends Controller
{
    public function status(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user || !$user->shop_id) {
            return response()->json(['success' => false, 'status' => 'error', 'message' => 'Shop account context required.'], 400);
        }

        $shop = $user->shop ?? Shop::find($user->shop_id);
        $shopCreated = $shop ? $shop->created_at : ($user->created_at ?? now());

        $config = PaymentGatewayConfig::where('gateway_name', 'Razorpay')->first();
        $trialDays = 30; // Default 30 days free trial from shop creation

        $subscription = Subscription::with('plan')
            ->where('shop_id', $user->shop_id)
            ->latest()
            ->first();

        $now = now();

        // Enforce trial period start = shop creation date, expiry = shop creation date + 30 days
        if (!$subscription || $subscription->status === 'trial') {
            $startDate = Carbon::parse($shopCreated);
            $expiryDate = $startDate->copy()->addDays($trialDays);

            if (!$subscription) {
                $defaultPlan = Plan::where('slug', 'monthly')->first() ?? Plan::first();
                $subscription = Subscription::create([
                    'shop_id'        => $user->shop_id,
                    'plan_id'        => $defaultPlan ? $defaultPlan->id : null,
                    'status'         => 'trial',
                    'start_date'     => $startDate,
                    'expiry_date'    => $expiryDate,
                    'payment_status' => 'free',
                ]);
                $subscription->load('plan');
            } else {
                $subscription->start_date = $startDate;
                $subscription->expiry_date = $expiryDate;
                $subscription->save();
            }
        }

        $expiryDate = Carbon::parse($subscription->expiry_date);
        $daysRemaining = max(0, (int) ceil($now->diffInDays($expiryDate, false)));
        $isExpired = $now->greaterThan($expiryDate);

        if ($isExpired && $subscription->status !== 'expired' && $subscription->status !== 'cancelled') {
            $subscription->status = 'expired';
            $subscription->save();
        }

        $currentPlan = $subscription->plan;
        $currentPlanStaff = $currentPlan ? (int) ($currentPlan->max_staff_accounts ?? 0) : 0;
        $isSubActive = ($subscription->status === 'active' && !$isExpired && $daysRemaining > 0);

        $staffPricePerDay = $shop ? $shop->getEffectiveStaffPricePerDay() : (float) \App\Models\SystemSetting::getByKey('staff_price_per_day', '2.00');
        $effectiveMaxStaff = $shop ? $shop->effective_max_staff : 0;
        $activeStaffCount = \App\Models\User::where('shop_id', $user->shop_id)->where('role', 'staff')->count();

        $staffDaysRemaining = 0;
        $staffValidUntil = null;
        $staffValidUntilFormatted = null;
        $isStaffExpired = false;

        if ($shop && $shop->custom_staff_valid_until) {
            $staffExp = Carbon::parse($shop->custom_staff_valid_until)->endOfDay();
            $staffValidUntil = $staffExp->format('Y-m-d');
            $staffValidUntilFormatted = $staffExp->format('d M Y');
            $staffDaysRemaining = max(0, (int) ceil($now->diffInDays($staffExp, false)));
            if ($now->greaterThan($staffExp) || $effectiveMaxStaff <= 0) {
                $isStaffExpired = true;
            }
        } elseif ($effectiveMaxStaff > 0 && $subscription && $subscription->expiry_date) {
            $staffValidUntil = $expiryDate->format('Y-m-d');
            $staffValidUntilFormatted = $expiryDate->format('d M Y');
            $staffDaysRemaining = $daysRemaining;
        } elseif ($activeStaffCount > 0 && $effectiveMaxStaff <= 0) {
            $isStaffExpired = true;
        }

        // Fetch ONLY active (ON) plans sorted by sort_order
        $hasCustomDiscount = $shop ? $shop->hasActiveCustomDiscount() : false;
        $allPlans = Plan::where('status', 'active')
            ->orderBy('sort_order', 'asc')
            ->orderBy('price', 'asc')
            ->get()
            ->map(function ($p) use ($currentPlan, $shop) {
                $targetStaff = (int) ($p->max_staff_accounts ?? 0);
                $isCurrent = $currentPlan && ($currentPlan->id === $p->id);
                $pricing = $shop ? $shop->calculatePlanPrice($p) : [
                    'price'            => (float) $p->price,
                    'original_price'   => null,
                    'discount_percent' => null,
                    'is_discounted'    => false,
                ];

                return [
                    'id'                 => $p->id,
                    'name'               => $p->name,
                    'price'              => (float) $pricing['price'],
                    'original_price'     => $pricing['original_price'] !== null ? (float) $pricing['original_price'] : null,
                    'discount_percent'   => $pricing['discount_percent'] !== null ? (int) $pricing['discount_percent'] : null,
                    'is_discounted'      => (bool) $pricing['is_discounted'],
                    'billing_period'     => $p->billing_period,
                    'max_staff_accounts' => $targetStaff,
                    'sort_order'         => (int) $p->sort_order,
                    'can_upgrade'        => false,
                    'upgrade_price'      => null,
                    'is_current'         => $isCurrent,
                ];
            });

        return response()->json([
            'success' => true,
            'status'  => 'success',
            'data'    => [
                'id'                    => $subscription->id,
                'shop_id'               => $subscription->shop_id,
                'status'                => $subscription->status,
                'start_date'            => $subscription->start_date ? Carbon::parse($subscription->start_date)->format('Y-m-d') : null,
                'expiry_date'           => $expiryDate->format('Y-m-d'),
                'expiry_date_formatted' => $expiryDate->format('d M Y'),
                'payment_status'        => $subscription->payment_status,
                'days_remaining'        => $daysRemaining,
                'is_trial'              => ($subscription->status === 'trial'),
                'is_expired'            => $isExpired,
                'staff_price_per_day'   => $staffPricePerDay,
                'effective_max_staff'         => $effectiveMaxStaff,
                'active_staff_count'          => $activeStaffCount,
                'staff_days_remaining'        => $staffDaysRemaining,
                'staff_valid_until'           => $staffValidUntil,
                'staff_valid_until_formatted' => $staffValidUntilFormatted,
                'is_staff_expired'            => $isStaffExpired,
                'can_add_staff'               => ($isSubActive || $subscription->status === 'trial') && $daysRemaining > 0,
                'has_custom_discount'        => $hasCustomDiscount,
                'custom_discount_percent'    => $shop ? $shop->custom_discount_percent : null,
                'custom_discount_note'       => $shop ? $shop->custom_discount_note : null,
                'custom_discount_is_one_time'=> (bool) ($shop ? $shop->custom_discount_is_one_time : false),
                'referral_points_balance'    => $shop ? (float) ($shop->referral_points_balance ?? 0) : 0.0,
                'referral_config'            => $shop ? (new ReferralService())->resolveConfig($shop) : null,
                'plan'                  => $subscription->plan ? [
                    'id'                 => $subscription->plan->id,
                    'name'               => $subscription->plan->name,
                    'price'              => (float) $subscription->plan->price,
                    'billing_period'     => $subscription->plan->billing_period,
                    'max_staff_accounts' => (int) ($subscription->plan->max_staff_accounts ?? 0),
                ] : [
                    'id'                 => 1,
                    'name'               => 'Solo Owner (1 Month)',
                    'price'              => 99.00,
                    'billing_period'     => 'monthly',
                    'max_staff_accounts' => 0,
                ],
                'plans'                 => $allPlans,
            ],
        ]);
    }

    public function createOrder(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user || !$user->shop_id) {
            return response()->json(['success' => false, 'status' => 'error', 'message' => 'Shop account required.'], 400);
        }

        $planId = $request->input('plan_id');
        $isUpgradeRequest = filter_var($request->input('is_upgrade', false), FILTER_VALIDATE_BOOLEAN);

        $plan = $planId ? Plan::find($planId) : Plan::where('slug', 'monthly')->first();

        if (!$plan) {
            $plan = Plan::create([
                'name'           => 'Mobile Profits Pro',
                'slug'           => 'monthly',
                'price'          => 200.00,
                'billing_period' => 'monthly',
                'status'         => 'active',
                'sort_order'     => 1,
            ]);
        }

        $subscription = Subscription::with('plan')
            ->where('shop_id', $user->shop_id)
            ->latest()
            ->first();

        $now = now();
        $isSubActive = false;
        $daysRemaining = 0;
        if ($subscription && $subscription->expiry_date) {
            $exp = Carbon::parse($subscription->expiry_date);
            $daysRemaining = max(0, (int) ceil($now->diffInDays($exp, false)));
            $isSubActive = ($subscription->status === 'active' && $now->lessThan($exp) && $daysRemaining > 0);
        }

        $currentPlan = $subscription?->plan;
        $currentStaff = $currentPlan ? (int) ($currentPlan->max_staff_accounts ?? 0) : 0;
        $targetStaff = (int) ($plan->max_staff_accounts ?? 0);

        // Charge the effective shop price (applies shop discount or custom plan price if any)
        $shop = Shop::find($user->shop_id);
        $pricing = $shop ? $shop->calculatePlanPrice($plan) : ['price' => (float) $plan->price];
        $originalAmount = (float) $pricing['price'];
        $orderType = 'standard';

        $usePoints = filter_var($request->input('use_points', false), FILTER_VALIDATE_BOOLEAN);
        $referralService = new ReferralService();
        $redemption = $shop
            ? $referralService->calculateRedemption($shop, $originalAmount, $usePoints)
            : ['points_used' => 0.0, 'final_payable' => $originalAmount];

        $pointsUsed = (float) $redemption['points_used'];
        $chargeAmount = (float) $redemption['final_payable'];

        // If 100% of the plan is covered by referral points, activate immediately without Razorpay
        if ($chargeAmount <= 0 && $pointsUsed > 0 && $shop) {
            DB::beginTransaction();
            try {
                $pointsOrderId = 'PTS-' . strtoupper(uniqid()) . '-' . time();
                $transaction = PaymentTransaction::create([
                    'shop_id'        => $user->shop_id,
                    'user_id'        => $user->id,
                    'plan_id'        => $plan->id,
                    'order_id'       => $pointsOrderId,
                    'payment_id'     => $pointsOrderId,
                    'amount'         => 0.00,
                    'currency'       => 'INR',
                    'status'         => 'successful',
                    'payment_method' => 'ReferralPoints',
                    'gateway_name'   => 'ReferralWallet',
                    'gateway_response' => [
                        'type'                 => $orderType,
                        'original_amount'      => $originalAmount,
                        'points_used'          => $pointsUsed,
                        'previous_plan_id'     => $currentPlan?->id,
                        'days_remaining'       => $daysRemaining,
                        'is_one_time_discount' => (bool) ($shop->custom_discount_is_one_time),
                    ],
                ]);

                $addMonths = 1;
                if ($plan->billing_period === '3_months') $addMonths = 3;
                elseif ($plan->billing_period === '6_months') $addMonths = 6;
                elseif ($plan->billing_period === 'annual') $addMonths = 12;

                if ($subscription && $subscription->expiry_date && $now->lessThan(Carbon::parse($subscription->expiry_date))) {
                    $newExpiry = Carbon::parse($subscription->expiry_date)->addMonths($addMonths);
                } else {
                    $newExpiry = $now->copy()->addMonths($addMonths);
                }

                if ($subscription) {
                    $subscription->update([
                        'plan_id'        => $plan->id,
                        'status'         => 'active',
                        'start_date'     => $now,
                        'expiry_date'    => $newExpiry,
                        'payment_status' => 'paid',
                    ]);
                } else {
                    $subscription = Subscription::create([
                        'shop_id'        => $user->shop_id,
                        'plan_id'        => $plan->id,
                        'status'         => 'active',
                        'start_date'     => $now,
                        'expiry_date'    => $newExpiry,
                        'payment_status' => 'paid',
                    ]);
                }

                $debited = $referralService->debitPoints(
                    shop: $shop,
                    points: $pointsUsed,
                    source: 'plan_redeem',
                    description: "Redeemed {$pointsUsed} pts for {$plan->name} (100% via Points)",
                    subscriptionId: $subscription->id,
                    paymentTransactionId: $transaction->id
                );

                if (!$debited) {
                    DB::rollBack();
                    return response()->json([
                        'success' => false,
                        'status'  => 'error',
                        'message' => 'Insufficient referral points balance.',
                    ], 400);
                }

                $planStaff = (int) ($plan->max_staff_accounts ?? 0);
                if ($planStaff > 0) {
                    $currentStaffExp = ($shop->custom_staff_valid_until && Carbon::parse($shop->custom_staff_valid_until)->isFuture())
                        ? Carbon::parse($shop->custom_staff_valid_until)
                        : $now;
                    $staffValidUntilDate = $currentStaffExp->copy()->addMonths($addMonths);
                    $shop->custom_max_staff = $planStaff;
                    $shop->custom_staff_valid_until = $staffValidUntilDate->format('Y-m-d H:i:s');
                    $shop->custom_staff_note = "Plan: {$plan->name} ({$planStaff} Staff) valid for {$addMonths} month(s) until " . $staffValidUntilDate->format('d M Y');
                    $shop->save();
                }

                if ($shop->custom_discount_is_one_time) {
                    $shop->custom_discount_percent = null;
                    $shop->custom_plan_prices = null;
                    $shop->custom_discount_valid_until = null;
                    $shop->custom_discount_is_one_time = false;
                    $shop->custom_discount_note = "One-time discount consumed on Order {$pointsOrderId}";
                    $shop->save();
                }

                DB::commit();

                return response()->json([
                    'success' => true,
                    'status'  => 'success',
                    'message' => "Plan activated using {$pointsUsed} Referral Points!",
                    'data'    => [
                        'free_via_points' => true,
                        'order_id'        => $pointsOrderId,
                        'amount'          => 0.0,
                        'original_amount' => $originalAmount,
                        'points_used'     => $pointsUsed,
                        'plan_name'       => $plan->name,
                        'expiry_date'     => $newExpiry->format('d M Y'),
                    ],
                ]);
            } catch (Exception $e) {
                DB::rollBack();
                return response()->json([
                    'success' => false,
                    'status'  => 'error',
                    'message' => 'Failed to activate plan with points: ' . $e->getMessage(),
                ], 400);
            }
        }

        $driver = new RazorpayDriver();
        $config = $driver->getConfig();

        if (!$config || !$config->active || !$config->key_id || !$config->key_secret) {
            return response()->json([
                'success' => false,
                'status'  => 'error',
                'message' => 'Payment gateway is currently offline or not configured by administrator.',
            ], 400);
        }

        DB::beginTransaction();
        try {
            $tempOrderId = 'TEMP-' . uniqid() . '-' . time();
            $transaction = PaymentTransaction::create([
                'shop_id'        => $user->shop_id,
                'user_id'        => $user->id,
                'plan_id'        => $plan->id,
                'order_id'       => $tempOrderId,
                'amount'         => $chargeAmount,
                'currency'       => $config->currency ?? 'INR',
                'status'         => 'pending',
                'payment_method' => 'Online',
                'gateway_name'   => 'Razorpay',
                'gateway_response' => [
                    'type'                  => $orderType,
                    'original_amount'       => $originalAmount,
                    'points_used'           => $pointsUsed,
                    'previous_plan_id'      => $currentPlan?->id,
                    'days_remaining'        => $daysRemaining,
                    'is_one_time_discount'  => (bool) ($shop?->custom_discount_is_one_time),
                ],
            ]);

            $rzpResult = $driver->createOrder($transaction);
            $transaction->order_id = $rzpResult['order_id'];
            $transaction->gateway_response = array_merge(
                $rzpResult['gateway_response'] ?? [],
                [
                    'type'                 => $orderType,
                    'original_amount'      => $originalAmount,
                    'points_used'          => $pointsUsed,
                    'previous_plan_id'     => $currentPlan?->id,
                    'days_remaining'       => $daysRemaining,
                    'is_one_time_discount' => (bool) ($shop?->custom_discount_is_one_time),
                ]
            );
            $transaction->save();

            DB::commit();

            return response()->json([
                'success' => true,
                'status'  => 'success',
                'data'    => [
                    'free_via_points' => false,
                    'order_id'        => $transaction->order_id,
                    'amount'          => (float) $transaction->amount,
                    'original_amount' => $originalAmount,
                    'points_used'     => $pointsUsed,
                    'currency'        => $transaction->currency,
                    'key_id'          => $config->key_id,
                    'plan_name'       => ($orderType === 'upgrade' ? "Upgrade to {$plan->name}" : $plan->name),
                    'is_upgrade'      => ($orderType === 'upgrade'),
                    'days_remaining'  => $daysRemaining,
                    'shop_name'       => $user->shop ? $user->shop->name : 'Mobile Profits Shop',
                ],
            ]);
        } catch (Exception $e) {
            DB::rollBack();
            Log::error("Subscription Order Creation Error: " . $e->getMessage());
            return response()->json([
                'success' => false,
                'status'  => 'error',
                'message' => 'Failed to create payment order: ' . $e->getMessage(),
            ], 400);
        }
    }

    /**
     * Create a Razorpay payment order specifically for Staff/Technician logins add-on.
     */
    public function createStaffAddonOrder(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user || !$user->shop_id) {
            return response()->json(['success' => false, 'status' => 'error', 'message' => 'Shop account required.'], 400);
        }

        $validated = $request->validate([
            'staff_count' => 'required|integer|min:1|max:50',
        ]);

        $staffCount = (int) $validated['staff_count'];

        $subscription = Subscription::where('shop_id', $user->shop_id)->latest()->first();
        if (!$subscription) {
            return response()->json(['success' => false, 'message' => 'No subscription found.'], 400);
        }

        $now = now();
        $expiryDate = Carbon::parse($subscription->expiry_date);
        $daysRemaining = max(1, (int) ceil($now->diffInDays($expiryDate, false)));

        if ($now->greaterThan($expiryDate) || $subscription->status === 'expired') {
            return response()->json(['success' => false, 'message' => 'Your subscription has expired. Please renew your plan first.'], 400);
        }

        $shop = Shop::find($user->shop_id);
        $dailyRate = $shop ? $shop->getEffectiveStaffPricePerDay() : (float) \App\Models\SystemSetting::getByKey('staff_price_per_day', '2.00');
        $totalAmount = round($daysRemaining * $dailyRate * $staffCount, 2);
        if ($totalAmount < 1.0) {
            $totalAmount = 1.0;
        }

        $driver = new RazorpayDriver();
        $config = $driver->getConfig();

        if (!$config || !$config->active || !$config->key_id || !$config->key_secret) {
            return response()->json([
                'success' => false,
                'status'  => 'error',
                'message' => 'Payment gateway is currently offline or not configured by administrator.',
            ], 400);
        }

        DB::beginTransaction();
        try {
            $tempOrderId = 'TEMP-STAFF-' . uniqid() . '-' . time();
            $transaction = PaymentTransaction::create([
                'shop_id'          => $user->shop_id,
                'user_id'          => $user->id,
                'plan_id'          => $subscription->plan_id,
                'order_id'         => $tempOrderId,
                'amount'           => $totalAmount,
                'currency'         => $config->currency ?? 'INR',
                'status'           => 'pending',
                'payment_method'   => 'Online',
                'gateway_name'     => 'Razorpay',
                'gateway_response' => [
                    'type'           => 'staff_addon',
                    'staff_count'    => $staffCount,
                    'days_remaining' => $daysRemaining,
                    'daily_rate'     => $dailyRate,
                    'valid_until'    => $expiryDate->format('Y-m-d H:i:s'),
                ],
            ]);

            $rzpResult = $driver->createOrder($transaction);
            $transaction->order_id = $rzpResult['order_id'];
            $transaction->gateway_response = array_merge(
                $rzpResult['gateway_response'] ?? [],
                [
                    'type'           => 'staff_addon',
                    'staff_count'    => $staffCount,
                    'days_remaining' => $daysRemaining,
                    'daily_rate'     => $dailyRate,
                    'valid_until'    => $expiryDate->format('Y-m-d H:i:s'),
                ]
            );
            $transaction->save();

            DB::commit();

            return response()->json([
                'success' => true,
                'status'  => 'success',
                'data'    => [
                    'order_id'       => $transaction->order_id,
                    'amount'         => (float) $transaction->amount,
                    'currency'       => $transaction->currency,
                    'key_id'         => $config->key_id,
                    'plan_name'      => "Staff Logins Add-on (+{$staffCount} Staff)",
                    'is_staff_addon' => true,
                    'staff_count'    => $staffCount,
                    'days_remaining' => $daysRemaining,
                    'shop_name'      => $user->shop ? $user->shop->name : 'Mobile Profits Shop',
                ],
            ]);
        } catch (Exception $e) {
            DB::rollBack();
            Log::error("Staff Addon Order Creation Error: " . $e->getMessage());
            return response()->json([
                'success' => false,
                'status'  => 'error',
                'message' => 'Failed to create payment order: ' . $e->getMessage(),
            ], 400);
        }
    }

    public function verifyPayment(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user || !$user->shop_id) {
            return response()->json(['success' => false, 'status' => 'error', 'message' => 'Shop account required.'], 400);
        }

        $request->validate([
            'razorpay_order_id'   => 'required|string',
            'razorpay_payment_id' => 'required|string',
            'razorpay_signature'  => 'required|string',
        ]);

        $orderId   = $request->input('razorpay_order_id');
        $paymentId = $request->input('razorpay_payment_id');
        $signature = $request->input('razorpay_signature');

        $transaction = PaymentTransaction::where('order_id', $orderId)->first();
        if (!$transaction) {
            return response()->json(['success' => false, 'status' => 'error', 'message' => 'Transaction order not found.'], 404);
        }

        // Idempotency check
        if ($transaction->status === 'successful') {
            return response()->json([
                'success' => true,
                'status'  => 'success',
                'message' => 'Payment already verified and active.',
            ]);
        }

        $driver = new RazorpayDriver();
        $verified = $driver->verifySignature([
            'razorpay_order_id'   => $orderId,
            'razorpay_payment_id' => $paymentId,
            'razorpay_signature'  => $signature,
        ]);

        if (!$verified) {
            $transaction->status = 'failed';
            $transaction->failure_reason = 'Signature verification failed';
            $transaction->save();

            return response()->json([
                'success' => false,
                'status'  => 'error',
                'message' => 'Payment signature verification failed. Invalid transaction token.',
            ], 400);
        }

        DB::beginTransaction();
        try {
            // Update transaction
            $transaction->status = 'successful';
            $transaction->payment_id = $paymentId;
            $transaction->signature = $signature;
            $transaction->save();

            $gwResponse = is_array($transaction->gateway_response)
                ? $transaction->gateway_response
                : (json_decode($transaction->gateway_response ?? '', true) ?: []);

            // 1. Check if this is a Staff Add-on purchase
            if (($gwResponse['type'] ?? '') === 'staff_addon') {
                $staffCount = (int) ($gwResponse['staff_count'] ?? 1);
                $shop = Shop::find($user->shop_id);
                $subscription = Subscription::where('shop_id', $user->shop_id)->latest()->first();
                $expiryDate = $subscription && $subscription->expiry_date
                    ? Carbon::parse($subscription->expiry_date)
                    : now()->addDays(30);

                $currentStaff = $shop ? $shop->effective_max_staff : 0;
                $newStaffLimit = $currentStaff + $staffCount;

                if ($shop) {
                    $shop->custom_max_staff = $newStaffLimit;
                    $shop->custom_staff_valid_until = $expiryDate->format('Y-m-d H:i:s');
                    $shop->custom_staff_note = "Purchased +{$staffCount} Staff Add-on (₹{$transaction->amount}) via Razorpay";
                    $shop->save();
                }

                DB::commit();

                return response()->json([
                    'success' => true,
                    'status'  => 'success',
                    'message' => "+{$staffCount} Staff login added successfully! Total allowed staff is now {$newStaffLimit}, valid until " . $expiryDate->format('d M Y') . ".",
                    'data'    => [
                        'payment_id'          => $paymentId,
                        'effective_max_staff' => $newStaffLimit,
                        'added_count'         => $staffCount,
                        'valid_until'         => $expiryDate->format('d M Y'),
                    ],
                ]);
            }

            // 2. Standard Plan Subscription or Renewal
            $plan = $transaction->plan ?: Plan::find($transaction->plan_id);
            $subscription = Subscription::where('shop_id', $user->shop_id)->latest()->first();
            $now = now();

            $addMonths = 1;
            if ($plan) {
                if ($plan->billing_period === '3_months') $addMonths = 3;
                elseif ($plan->billing_period === '6_months') $addMonths = 6;
                elseif ($plan->billing_period === 'annual') $addMonths = 12;
            }

            if ($subscription && $subscription->expiry_date && $now->lessThan(Carbon::parse($subscription->expiry_date))) {
                $newExpiry = Carbon::parse($subscription->expiry_date)->addMonths($addMonths);
            } else {
                $newExpiry = $now->copy()->addMonths($addMonths);
            }

            if ($subscription) {
                $subscription->update([
                    'plan_id'        => $plan ? $plan->id : $subscription->plan_id,
                    'status'         => 'active',
                    'start_date'     => $now,
                    'expiry_date'    => $newExpiry,
                    'payment_status' => 'paid',
                ]);
            } else {
                $subscription = Subscription::create([
                    'shop_id'        => $user->shop_id,
                    'plan_id'        => $plan ? $plan->id : null,
                    'status'         => 'active',
                    'start_date'     => $now,
                    'expiry_date'    => $newExpiry,
                    'payment_status' => 'paid',
                ]);
            }

            // Manage staff validity separately according to the plan duration purchased
            $shop = Shop::find($user->shop_id);
            $referralService = new ReferralService();

            // Deduct redeemed referral points if used for this order
            $pointsUsed = (float) ($gwResponse['points_used'] ?? 0);
            if ($shop && $pointsUsed > 0) {
                $planLabel = $plan ? $plan->name : 'Subscription Plan';
                $referralService->debitPoints(
                    shop: $shop,
                    points: $pointsUsed,
                    source: 'plan_redeem',
                    description: "Redeemed {$pointsUsed} pts on {$planLabel}",
                    subscriptionId: $subscription->id,
                    paymentTransactionId: $transaction->id
                );
            }

            // Award recurring recharge commission % to referrer (on actual cash paid only)
            if ($shop && (float) $transaction->amount > 0) {
                $referralService->handleRechargeCommission(
                    payingShop: $shop,
                    actualCashPaid: (float) $transaction->amount,
                    subscriptionId: $subscription->id,
                    paymentTransactionId: $transaction->id
                );
            }
            $staffValidUntilDate = null;
            if ($shop && $plan) {
                $planStaff = (int) ($plan->max_staff_accounts ?? 0);
                if ($planStaff > 0) {
                    // Strictly grant staff login for the purchased duration ($addMonths)
                    $currentStaffExp = ($shop->custom_staff_valid_until && Carbon::parse($shop->custom_staff_valid_until)->isFuture())
                        ? Carbon::parse($shop->custom_staff_valid_until)
                        : $now;
                    $staffValidUntilDate = $currentStaffExp->copy()->addMonths($addMonths);

                    $shop->custom_max_staff = $planStaff;
                    $shop->custom_staff_valid_until = $staffValidUntilDate->format('Y-m-d H:i:s');
                    $shop->custom_staff_note = "Plan: {$plan->name} ({$planStaff} Staff) valid for {$addMonths} month(s) until " . $staffValidUntilDate->format('d M Y');
                    $shop->save();
                }
            }

            // Consume one-time discount for this specific shop upon successful purchase!
            // Other shops will retain their discount until they make their purchase.
            if ($shop && $shop->custom_discount_is_one_time) {
                $discountConsumedInfo = ($shop->custom_discount_percent > 0)
                    ? "{$shop->custom_discount_percent}%"
                    : 'Custom Price';
                $shop->custom_discount_percent = null;
                $shop->custom_plan_prices = null;
                $shop->custom_discount_valid_until = null;
                $shop->custom_discount_is_one_time = false;
                $shop->custom_discount_note = "One-time {$discountConsumedInfo} discount consumed on Order {$orderId}";
                $shop->save();
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'status'  => 'success',
                'message' => 'Payment verified successfully! Subscription activated.',
                'data'    => [
                    'payment_id'                  => $paymentId,
                    'expiry_date'                 => $newExpiry->format('Y-m-d'),
                    'staff_valid_until'           => $staffValidUntilDate ? $staffValidUntilDate->format('Y-m-d') : null,
                    'staff_valid_until_formatted' => $staffValidUntilDate ? $staffValidUntilDate->format('d M Y') : null,
                ],
            ]);
        } catch (Exception $e) {
            DB::rollBack();
            Log::error("Verify Payment Error: " . $e->getMessage());
            return response()->json([
                'success' => false,
                'status'  => 'error',
                'message' => 'Failed to process verified payment: ' . $e->getMessage(),
            ], 400);
        }
    }

    /**
     * Purchase staff/technician logins add-on for the remaining days of the current plan.
     */
    public function purchaseStaffAddon(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user || !$user->shop_id) {
            return response()->json(['success' => false, 'message' => 'Shop account context required.'], 400);
        }

        $validated = $request->validate([
            'staff_count'    => 'required|integer|min:1|max:50',
            'payment_method' => 'nullable|string',
            'transaction_id' => 'nullable|string',
        ]);

        $staffCount = (int) $validated['staff_count'];

        $subscription = Subscription::where('shop_id', $user->shop_id)->latest()->first();
        if (!$subscription) {
            return response()->json(['success' => false, 'message' => 'No active subscription found.'], 400);
        }

        $now = now();
        $expiryDate = Carbon::parse($subscription->expiry_date);
        $daysRemaining = max(1, (int) ceil($now->diffInDays($expiryDate, false)));

        if ($now->greaterThan($expiryDate) || $subscription->status === 'expired') {
            return response()->json(['success' => false, 'message' => 'Your subscription has expired. Please renew your plan first.'], 400);
        }

        $shop = Shop::find($user->shop_id);
        $dailyRate = $shop ? $shop->getEffectiveStaffPricePerDay() : (float) \App\Models\SystemSetting::getByKey('staff_price_per_day', '2.00');
        $totalAmount = round($daysRemaining * $dailyRate * $staffCount, 2);

        $shop = Shop::find($user->shop_id);
        if (!$shop) {
            return response()->json(['success' => false, 'message' => 'Shop not found.'], 404);
        }

        DB::beginTransaction();
        try {
            $currentStaff = $shop->effective_max_staff;
            $newStaffLimit = $currentStaff + $staffCount;

            $shop->custom_max_staff = $newStaffLimit;
            $shop->custom_staff_valid_until = $expiryDate->format('Y-m-d H:i:s');
            $shop->custom_staff_note = "Purchased +{$staffCount} Staff Add-on for {$daysRemaining} days (₹{$totalAmount})";
            $shop->save();

            // Record transaction
            $orderId = 'STAFF_ADDON_' . strtoupper(\Illuminate\Support\Str::random(8));
            PaymentTransaction::create([
                'shop_id'          => $shop->id,
                'user_id'          => $user->id,
                'plan_id'          => $subscription->plan_id,
                'order_id'         => $orderId,
                'payment_id'       => $validated['transaction_id'] ?? ('PAY_' . strtoupper(\Illuminate\Support\Str::random(10))),
                'amount'           => $totalAmount,
                'currency'         => 'INR',
                'status'           => 'successful',
                'payment_method'   => $validated['payment_method'] ?? 'in_app',
                'gateway_name'     => 'Staff Add-on',
                'gateway_response' => json_encode([
                    'type'           => 'staff_addon',
                    'staff_count'    => $staffCount,
                    'days_remaining' => $daysRemaining,
                    'daily_rate'     => $dailyRate,
                    'valid_until'    => $expiryDate->format('d M Y'),
                ]),
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => "+{$staffCount} Staff login added successfully! Total allowed staff is now {$newStaffLimit}, valid until " . $expiryDate->format('d M Y') . ".",
                'data' => [
                    'effective_max_staff' => $newStaffLimit,
                    'added_count'         => $staffCount,
                    'amount_paid'         => $totalAmount,
                    'days_remaining'      => $daysRemaining,
                    'daily_rate'          => $dailyRate,
                    'valid_until'         => $expiryDate->format('d M Y'),
                ],
            ]);
        } catch (Exception $e) {
            DB::rollBack();
            Log::error('Staff Addon Purchase Error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to process staff add-on: ' . $e->getMessage()], 500);
        }
    }

    public function history(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user || !$user->shop_id) {
            return response()->json(['success' => false, 'status' => 'error', 'message' => 'Shop account required.'], 400);
        }

        $transactions = PaymentTransaction::with('plan')
            ->where('shop_id', $user->shop_id)
            ->orderBy('created_at', 'desc')
            ->get();

        $data = $transactions->map(function ($txn) {
            $gwResponse = is_array($txn->gateway_response)
                ? $txn->gateway_response
                : (json_decode($txn->gateway_response ?? '', true) ?: []);
            $isStaffAddon = ($gwResponse['type'] ?? '') === 'staff_addon' || str_starts_with($txn->order_id ?? '', 'STAFF_ADDON_');
            $staffCount = $gwResponse['staff_count'] ?? null;
            $addonTitle = $staffCount ? "👥 Staff Add-on (+{$staffCount} Staff)" : '👥 Staff Logins Add-on';

            return [
                'id'             => $txn->id,
                'plan_name'      => $isStaffAddon ? $addonTitle : ($txn->plan ? $txn->plan->name : 'Mobile Profits Subscription'),
                'amount'         => (float) $txn->amount,
                'currency'       => $txn->currency,
                'status'         => $txn->status,
                'order_id'       => $txn->order_id,
                'payment_id'     => $txn->payment_id,
                'payment_method' => $txn->payment_method,
                'created_at'     => $txn->created_at ? $txn->created_at->toIso8601String() : null,
            ];
        });

        return response()->json([
            'success' => true,
            'status'  => 'success',
            'data'    => $data,
        ]);
    }
}
