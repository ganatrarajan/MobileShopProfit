<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\PaymentGatewayConfig;
use App\Models\PaymentTransaction;
use App\Models\Plan;
use App\Models\Shop;
use App\Models\Subscription;
use App\Services\Payment\RazorpayDriver;
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
        $trialDays = 90; // Default 90 days free trial from shop creation

        $subscription = Subscription::with('plan')
            ->where('shop_id', $user->shop_id)
            ->latest()
            ->first();

        $now = now();

        // Enforce trial period start = shop creation date, expiry = shop creation date + 90 days
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

        // Fetch ONLY active (ON) plans sorted by sort_order
        $allPlans = Plan::where('status', 'active')
            ->orderBy('sort_order', 'asc')
            ->orderBy('price', 'asc')
            ->get()
            ->map(function ($p) {
                return [
                    'id'             => $p->id,
                    'name'           => $p->name,
                    'price'          => (float) $p->price,
                    'billing_period' => $p->billing_period,
                    'sort_order'     => (int) $p->sort_order,
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
                'plan'                  => $subscription->plan ? [
                    'id'             => $subscription->plan->id,
                    'name'           => $subscription->plan->name,
                    'price'          => (float) $subscription->plan->price,
                    'billing_period' => $subscription->plan->billing_period,
                ] : [
                    'id'             => 1,
                    'name'           => 'Mobile Profits Pro',
                    'price'          => 200.00,
                    'billing_period' => 'monthly',
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
                'amount'         => $plan->price,
                'currency'       => $config->currency ?? 'INR',
                'status'         => 'pending',
                'payment_method' => 'Online',
                'gateway_name'   => 'Razorpay',
            ]);

            $rzpResult = $driver->createOrder($transaction);
            $transaction->order_id = $rzpResult['order_id'];
            $transaction->gateway_response = $rzpResult['gateway_response'];
            $transaction->save();

            DB::commit();

            return response()->json([
                'success' => true,
                'status'  => 'success',
                'data'    => [
                    'order_id'    => $transaction->order_id,
                    'amount'      => (float) $transaction->amount,
                    'currency'    => $transaction->currency,
                    'key_id'      => $config->key_id,
                    'plan_name'   => $plan->name,
                    'shop_name'   => $user->shop ? $user->shop->name : 'Mobile Profits Shop',
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
                'message' => 'Payment already verified and subscription is active.',
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

            // Find or create shop subscription
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
                Subscription::create([
                    'shop_id'        => $user->shop_id,
                    'plan_id'        => $plan ? $plan->id : null,
                    'status'         => 'active',
                    'start_date'     => $now,
                    'expiry_date'    => $newExpiry,
                    'payment_status' => 'paid',
                ]);
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'status'  => 'success',
                'message' => 'Payment verified successfully! Subscription activated.',
                'data'    => [
                    'payment_id'  => $paymentId,
                    'expiry_date' => $newExpiry->format('Y-m-d'),
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
            return [
                'id'             => $txn->id,
                'plan_name'      => $txn->plan ? $txn->plan->name : 'Mobile Profits Subscription',
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
