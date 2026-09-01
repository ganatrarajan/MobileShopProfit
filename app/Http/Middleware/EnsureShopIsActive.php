<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureShopIsActive
{
    /**
     * Handle an incoming request.
     * Ensure shop account is active before granting access, and block create/edit if subscription is expired.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        // Allow super_admin or admin to bypass shop active check
        if ($user && in_array($user->role, ['admin', 'super_admin'])) {
            return $next($request);
        }

        if ($user && $user->shop_id) {
            // 1. Deactivated Account Check (Applies to all requests)
            if ($user->shop && in_array(strtolower($user->shop->status), ['deactivated', 'inactive', 'suspended'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Your shop account has been deactivated. Please contact support.',
                ], 403);
            }

            // 2. Expired Subscription Check (Applies ONLY to Create/Edit/Delete write operations, GET listings remain open)
            if (in_array($request->method(), ['POST', 'DELETE'])) {
                // Allow payment/subscription, support requests, and logout endpoints
                $isExempt = $request->is('api/v1/subscription*') ||
                            $request->is('api/v1/support*') ||
                            $request->is('api/v1/auth/logout') ||
                            $request->is('api/v1/shop/logo');

                if (! $isExempt) {
                    $sub = \App\Models\Subscription::where('shop_id', $user->shop_id)->latest()->first();
                    if ($sub && $sub->expiry_date) {
                        $expiry = \Carbon\Carbon::parse($sub->expiry_date);
                        if (now()->greaterThan($expiry) || $sub->status === 'expired') {
                            return response()->json([
                                'success' => false,
                                'message' => 'Your subscription plan has expired. Please renew your plan to create or edit records.',
                            ], 403);
                        }
                    }
                }
            }
        }

        return $next($request);
    }
}
