<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\PaymentGatewayConfig;
use App\Services\Payment\RazorpayDriver;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminPaymentGatewayController extends Controller
{
    public function getSettings(Request $request): JsonResponse
    {
        $config = PaymentGatewayConfig::where('gateway_name', 'Razorpay')->first();

        return response()->json([
            'status' => 'success',
            'data'   => [
                'gateway_name'              => $config ? $config->gateway_name : 'Razorpay',
                'key_id'                    => $config ? $config->key_id : '',
                'mode'                      => $config ? $config->mode : 'test',
                'currency'                  => $config ? $config->currency : 'INR',
                'active'                    => $config ? (bool) $config->active : true,
                'trial_months'              => $config ? $config->trial_months : 3,
                'key_secret_configured'     => $config ? !empty($config->key_secret) : false,
                'webhook_secret_configured' => $config ? !empty($config->webhook_secret) : false,
                'updated_at'                => $config ? $config->updated_at->toIso8601String() : null,
            ],
        ]);
    }

    public function saveSettings(Request $request): JsonResponse
    {
        $request->validate([
            'key_id'         => 'required|string|max:255',
            'key_secret'     => 'nullable|string|max:500',
            'webhook_secret' => 'nullable|string|max:500',
            'mode'           => 'required|in:test,live',
            'currency'       => 'required|string|max:10',
            'active'         => 'required|boolean',
            'trial_months'   => 'required|integer|min:0|max:24',
        ]);

        $config = PaymentGatewayConfig::firstOrNew(['gateway_name' => 'Razorpay']);

        $config->key_id       = $request->input('key_id');
        $config->mode         = $request->input('mode');
        $config->currency     = $request->input('currency');
        $config->active       = $request->boolean('active');
        $config->trial_months = (int) $request->input('trial_months');

        if ($request->filled('key_secret')) {
            $config->key_secret = $request->input('key_secret');
        }

        if ($request->filled('webhook_secret')) {
            $config->webhook_secret = $request->input('webhook_secret');
        }

        $userId = $request->user() ? $request->user()->id : null;
        if (!$config->exists) {
            $config->created_by = $userId;
        }
        $config->updated_by = $userId;

        $config->save();

        if ($userId) {
            AdminAuditLog::create([
                'admin_id'    => $userId,
                'action'      => 'update_payment_gateway_settings',
                'target_type' => 'PaymentGatewayConfig',
                'target_id'   => $config->id,
                'details'     => "Updated Razorpay gateway settings (Mode: {$config->mode}, Active: {$config->active})",
                'ip_address'  => $request->ip(),
            ]);
        }

        return response()->json([
            'status'  => 'success',
            'message' => 'Payment gateway settings saved successfully.',
            'data'    => [
                'gateway_name'              => $config->gateway_name,
                'key_id'                    => $config->key_id,
                'mode'                      => $config->mode,
                'currency'                  => $config->currency,
                'active'                    => (bool) $config->active,
                'trial_months'              => $config->trial_months,
                'key_secret_configured'     => !empty($config->key_secret),
                'webhook_secret_configured' => !empty($config->webhook_secret),
            ],
        ]);
    }

    public function testConnection(Request $request): JsonResponse
    {
        $keyId = $request->input('key_id');
        $keySecret = $request->input('key_secret');

        $driver = new RazorpayDriver();
        $result = $driver->testConnection($keyId, $keySecret);

        return response()->json($result, $result['success'] ? 200 : 400);
    }
}
