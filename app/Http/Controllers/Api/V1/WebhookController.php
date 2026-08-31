<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\PaymentTransaction;
use App\Models\Plan;
use App\Models\Subscription;
use App\Services\Payment\RazorpayDriver;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class WebhookController extends Controller
{
    public function handleRazorpay(Request $request): JsonResponse
    {
        Log::info("Razorpay Webhook Callback Received", [
            'event'   => $request->input('event'),
            'headers' => $request->headers->all(),
        ]);

        $driver = new RazorpayDriver();
        $result = $driver->handleWebhook($request);

        if (!$result['verified']) {
            Log::warning("Razorpay Webhook Verification Failed", ['result' => $result]);
            return response()->json(['status' => 'error', 'message' => $result['message']], 400);
        }

        $status  = $result['status'] ?? 'ignored';
        $orderId = $result['order_id'] ?? null;

        if (!$orderId) {
            return response()->json(['status' => 'success', 'message' => 'Event ignored - no order_id']);
        }

        $transaction = PaymentTransaction::where('order_id', $orderId)->first();
        if (!$transaction) {
            Log::warning("Webhook transaction not found for order ID: {$orderId}");
            return response()->json(['status' => 'error', 'message' => 'Transaction not found'], 404);
        }

        // Idempotency: skip if already successful
        if ($transaction->status === 'successful' && $status === 'successful') {
            return response()->json(['status' => 'success', 'message' => 'Payment already processed']);
        }

        if ($status === 'successful') {
            DB::beginTransaction();
            try {
                $transaction->status         = 'successful';
                $transaction->payment_id     = $result['payment_id'] ?? $transaction->payment_id;
                $transaction->payment_method = $result['payment_method'] ?? 'Online';
                $transaction->gateway_response = $result['gateway_response'] ?? $transaction->gateway_response;
                $transaction->save();

                $plan = $transaction->plan ?: Plan::find($transaction->plan_id);
                $subscription = Subscription::where('shop_id', $transaction->shop_id)->latest()->first();

                $now = now();
                $addMonths = ($plan && $plan->billing_period === 'annual') ? 12 : 1;

                if ($subscription && $subscription->expiry_date && $now->lessThan($subscription->expiry_date)) {
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
                        'shop_id'        => $transaction->shop_id,
                        'plan_id'        => $plan ? $plan->id : null,
                        'status'         => 'active',
                        'start_date'     => $now,
                        'expiry_date'    => $newExpiry,
                        'payment_status' => 'paid',
                    ]);
                }

                DB::commit();
                return response()->json(['status' => 'success', 'message' => 'Payment processed and subscription updated via webhook.']);
            } catch (\Exception $e) {
                DB::rollBack();
                Log::error("Webhook error processing transaction: " . $e->getMessage());
                return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
            }
        }

        if ($status === 'failed') {
            $transaction->status = 'failed';
            $transaction->failure_reason = $result['failure_reason'] ?? 'Failed via webhook';
            $transaction->save();
            return response()->json(['status' => 'success', 'message' => 'Transaction marked failed']);
        }

        return response()->json(['status' => 'success', 'message' => 'Webhook received']);
    }
}
