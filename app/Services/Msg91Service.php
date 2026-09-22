<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class Msg91Service
{
    protected string $authKey;
    protected string $widgetId;
    protected string $templateId;
    protected bool $enabled;

    public function __construct()
    {
        $this->authKey = config('services.msg91.auth_key', env('MSG91_AUTH_KEY', ''));
        $this->widgetId = config('services.msg91.widget_id', env('MSG91_WIDGET_ID', ''));
        $this->templateId = config('services.msg91.template_id', env('MSG91_OTP_TEMPLATE_ID', ''));
        $this->enabled = filter_var(config('services.msg91.enabled', env('MSG91_ENABLED', true)), FILTER_VALIDATE_BOOLEAN);
    }

    /**
     * Send OTP via MSG91 SMS API.
     *
     * @param string $mobile 10-digit or full mobile number with country code
     * @param string $otp 6-digit OTP code
     * @return array ['success' => bool, 'message' => string]
     */
    public function sendOtp(string $mobile, string $otp): array
    {
        // Format mobile number to include country code (default +91 for India)
        $formattedMobile = preg_replace('/[^0-9]/', '', $mobile);
        if (strlen($formattedMobile) === 10) {
            $formattedMobile = '91' . $formattedMobile;
        }

        if (!$this->enabled || empty($this->authKey)) {
            Log::info("MSG91 OTP (Dev Mode) for {$formattedMobile}: {$otp}");
            return [
                'success' => true,
                'message' => 'OTP sent successfully (Development Mode).',
                'req_id'  => null,
            ];
        }

        try {
            $url = 'https://api.msg91.com/api/v5/widget/sendOtp';
            
            $payload = [
                'widgetId'   => $this->widgetId,
                'identifier' => $formattedMobile,
            ];

            if (!empty($this->templateId)) {
                $payload['templateId'] = $this->templateId;
            }

            if (!empty($otp)) {
                $payload['otp'] = $otp;
            }

            $response = Http::timeout(8)->withHeaders([
                'authkey'      => $this->authKey,
                'Content-Type' => 'application/json',
            ])->post($url, $payload);

            $resData = $response->json();

            if ($response->successful() && isset($resData['type']) && $resData['type'] !== 'error') {
                Log::info("MSG91 Widget OTP sent to {$formattedMobile}", ['response' => $resData]);
                return [
                    'success' => true,
                    'message' => 'OTP sent successfully via MSG91 Widget.',
                    'req_id'  => $resData['message'] ?? null,
                ];
            }

            // Fallback to control.msg91.com API if Widget API expects captcha token
            $fallbackUrl = 'https://control.msg91.com/api/v5/otp';
            $fallbackPayload = [
                'widget_id' => $this->widgetId,
                'mobile'    => $formattedMobile,
                'otp'       => $otp,
            ];

            $fbRes = Http::timeout(8)->withHeaders([
                'authkey'      => $this->authKey,
                'Content-Type' => 'application/json',
            ])->post($fallbackUrl, $fallbackPayload);

            $fbData = $fbRes->json();

            if ($fbRes->successful()) {
                Log::info("MSG91 Fallback OTP sent to {$formattedMobile}", ['response' => $fbData]);
                return [
                    'success' => true,
                    'message' => 'OTP sent successfully via MSG91.',
                    'req_id'  => $fbData['message'] ?? null,
                ];
            }

            return [
                'success' => false,
                'message' => $resData['message'] ?? 'Failed to send OTP via SMS gateway.',
                'req_id'  => null,
            ];
        } catch (\Throwable $e) {
            Log::error("MSG91 Exception: " . $e->getMessage());
            return [
                'success' => false,
                'message' => 'SMS service exception: ' . $e->getMessage(),
                'req_id'  => null,
            ];
        }
    }

    /**
     * Verify OTP with MSG91 SMS gateway.
     */
    public function verifyOtp(string $mobile, string $otp, ?string $reqId = null): array
    {
        $formattedMobile = preg_replace('/[^0-9]/', '', $mobile);
        if (strlen($formattedMobile) === 10) {
            $formattedMobile = '91' . $formattedMobile;
        }

        if (!$this->enabled || empty($this->authKey)) {
            return [
                'success' => true,
                'message' => 'OTP verified (Development Mode).',
            ];
        }

        try {
            // 1. Primary MSG91 Widget Verify API endpoint (requires reqId and widgetId)
            if (!empty($reqId)) {
                $widgetUrl = 'https://api.msg91.com/api/v5/widget/verifyOtp';
                $widgetPayload = [
                    'widgetId' => $this->widgetId,
                    'reqId'    => $reqId,
                    'otp'      => $otp,
                ];

                $response = Http::timeout(8)->withHeaders([
                    'authkey'      => $this->authKey,
                    'Content-Type' => 'application/json',
                ])->post($widgetUrl, $widgetPayload);

                $resData = $response->json();

                if ($response->successful() && isset($resData['type']) && strtolower($resData['type']) === 'success') {
                    Log::info("MSG91 Widget OTP verified for {$formattedMobile}", ['response' => $resData]);
                    return [
                        'success' => true,
                        'message' => 'OTP verified successfully via MSG91 Widget.',
                    ];
                }

                if (isset($resData['type']) && strtolower($resData['type']) === 'error') {
                    Log::warning("MSG91 Widget verifyOtp failed for {$formattedMobile}", ['response' => $resData]);
                    return [
                        'success' => false,
                        'message' => $resData['message'] ?? 'Invalid OTP code.',
                    ];
                }
            }

            // 2. Fallback control.msg91.com OTP verify endpoint
            $url = "https://control.msg91.com/api/v5/otp/verify?mobile={$formattedMobile}&otp={$otp}";

            $response = Http::timeout(6)->withHeaders([
                'authkey'      => $this->authKey,
                'Content-Type' => 'application/json',
            ])->post($url);

            $resData = $response->json();

            if ($response->successful() && isset($resData['type']) && strtolower($resData['type']) === 'success') {
                Log::info("MSG91 OTP verified for {$formattedMobile}", ['response' => $resData]);
                return [
                    'success' => true,
                    'message' => 'OTP verified successfully via MSG91.',
                ];
            }

            Log::warning("MSG91 verifyOtp failed for {$formattedMobile}", ['response' => $resData]);
            return [
                'success' => false,
                'message' => $resData['message'] ?? 'Invalid OTP code.',
            ];
        } catch (\Throwable $e) {
            Log::error("MSG91 Verify Exception: " . $e->getMessage());
            return [
                'success' => false,
                'message' => 'SMS service exception: ' . $e->getMessage(),
            ];
        }
    }
}
