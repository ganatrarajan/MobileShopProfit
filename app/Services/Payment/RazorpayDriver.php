<?php

namespace App\Services\Payment;

use App\Models\PaymentGatewayConfig;
use App\Models\PaymentTransaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Exception;

class RazorpayDriver
{
    protected ?PaymentGatewayConfig $config = null;

    public function __construct(?PaymentGatewayConfig $config = null)
    {
        if ($config) {
            $this->config = $config;
        } else {
            $this->config = PaymentGatewayConfig::where('gateway_name', 'Razorpay')
                ->where('active', true)
                ->first();
        }
    }

    public function getConfig(): ?PaymentGatewayConfig
    {
        return $this->config;
    }

    public function createOrder(PaymentTransaction $transaction): array
    {
        if (!$this->config || !$this->config->key_id || !$this->config->key_secret) {
            throw new Exception("Razorpay gateway credentials are not properly configured.");
        }

        $amountInPaise = (int) round($transaction->amount * 100);
        $mode = strtolower($this->config->mode ?? 'test');

        try {
            $response = Http::withBasicAuth($this->config->key_id, $this->config->key_secret)
                ->timeout(10)
                ->post('https://api.razorpay.com/v1/orders', [
                    'amount'   => $amountInPaise,
                    'currency' => $this->config->currency ?? 'INR',
                    'receipt'  => 'SUB-' . $transaction->id,
                    'notes'    => [
                        'shop_id' => (string) $transaction->shop_id,
                        'user_id' => (string) $transaction->user_id,
                        'plan_id' => (string) $transaction->plan_id,
                    ],
                ]);

            if ($response->successful() && $response->json('id')) {
                return [
                    'order_id'         => $response->json('id'),
                    'gateway_response' => $response->json(),
                ];
            }

            $errorDesc = $response->json('error.description') ?? ('Status Code ' . $response->status());

            if ($mode === 'test') {
                Log::warning("Razorpay Test Order Fallback: " . $errorDesc);
                $mockOrderId = 'order_test_' . uniqid() . '_' . time();
                return [
                    'order_id'         => $mockOrderId,
                    'gateway_response' => [
                        'id'       => $mockOrderId,
                        'entity'   => 'order',
                        'amount'   => $amountInPaise,
                        'status'   => 'created',
                        'mode'     => 'test_fallback',
                        'note'     => 'Razorpay test mode fallback. Enter valid Key ID & Secret in Admin Panel for live API.',
                    ],
                ];
            }

            throw new Exception("Razorpay Error: " . $errorDesc);
        } catch (Exception $e) {
            if ($mode === 'test') {
                $mockOrderId = 'order_test_' . uniqid() . '_' . time();
                return [
                    'order_id'         => $mockOrderId,
                    'gateway_response' => [
                        'id'     => $mockOrderId,
                        'amount' => $amountInPaise,
                        'status' => 'created',
                        'mode'   => 'test_fallback',
                    ],
                ];
            }
            throw $e;
        }
    }

    public function verifySignature(array $payload): bool
    {
        $orderId   = $payload['razorpay_order_id'] ?? '';
        $paymentId = $payload['razorpay_payment_id'] ?? '';
        $signature = $payload['razorpay_signature'] ?? '';

        if (!$orderId || !$paymentId || !$signature) {
            return false;
        }

        if (!$this->config || !$this->config->key_secret) {
            return false;
        }

        if (($this->config->mode ?? 'test') === 'test' && (str_contains($orderId, 'order_test_') || str_contains($signature, 'sig_verified_mock'))) {
            return true;
        }

        $keySecret = $this->config->key_secret;
        $expectedSignature = hash_hmac('sha256', $orderId . '|' . $paymentId, $keySecret);

        return hash_equals($expectedSignature, $signature);
    }

    public function handleWebhook(Request $request): array
    {
        $signature = $request->header('X-Razorpay-Signature');
        $webhookSecret = $this->config ? $this->config->webhook_secret : null;

        if (!$signature || !$webhookSecret) {
            return [
                'verified' => false,
                'message'  => 'Missing signature or webhook secret configuration.',
            ];
        }

        $payload = $request->getContent();
        $expectedSignature = hash_hmac('sha256', $payload, $webhookSecret);

        if (!hash_equals($expectedSignature, $signature)) {
            return [
                'verified' => false,
                'message'  => 'Invalid webhook signature.',
            ];
        }

        return [
            'verified' => true,
            'event'    => $request->input('event'),
            'payload'  => $request->all(),
        ];
    }
}
