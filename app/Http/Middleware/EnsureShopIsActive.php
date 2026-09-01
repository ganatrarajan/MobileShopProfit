<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureShopIsActive
{
    /**
     * Handle an incoming request.
     * Ensure shop account is active before granting access.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        // Allow super_admin or admin to bypass shop active check
        if ($user && in_array($user->role, ['admin', 'super_admin'])) {
            return $next($request);
        }

        if ($user && $user->shop) {
            if (in_array(strtolower($user->shop->status), ['deactivated', 'inactive', 'suspended'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Your shop account has been deactivated. Please contact support.',
                ], 403);
            }
        }

        return $next($request);
    }
}