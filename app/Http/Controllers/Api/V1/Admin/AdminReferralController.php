<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\ReferralPointTransaction;
use App\Models\Shop;
use App\Models\SystemSetting;
use App\Services\ReferralService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminReferralController extends Controller
{
    use ApiResponse;

    /**
     * Get global/common referral settings.
     */
    public function getSettings(ReferralService $referralService): JsonResponse
    {
        return $this->successResponse(
            $referralService->getGlobalConfig(),
            'Global referral settings retrieved'
        );
    }

    /**
     * Update global/common referral settings.
     */
    public function updateSettings(Request $request, ReferralService $referralService): JsonResponse
    {
        $validated = $request->validate([
            'enabled'            => 'sometimes|boolean',
            'reward_mode'        => 'sometimes|string|in:signup_and_recharge,recharge_only',
            'signup_points'      => 'sometimes|numeric|min:0',
            'welcome_points'     => 'sometimes|numeric|min:0',
            'recharge_percent'   => 'sometimes|numeric|min:0|max:100',
            'max_redeem_percent' => 'sometimes|numeric|min:0|max:100',
            'app_link'           => 'nullable|string|max:500',
        ]);

        if (array_key_exists('enabled', $validated)) {
            SystemSetting::setKey('referral_enabled', $validated['enabled'] ? '1' : '0');
        }
        if (array_key_exists('reward_mode', $validated)) {
            SystemSetting::setKey('referral_reward_mode', $validated['reward_mode']);
        }
        if (array_key_exists('signup_points', $validated)) {
            SystemSetting::setKey('referral_signup_points', (string) $validated['signup_points']);
        }
        if (array_key_exists('welcome_points', $validated)) {
            SystemSetting::setKey('referral_welcome_points', (string) $validated['welcome_points']);
        }
        if (array_key_exists('recharge_percent', $validated)) {
            SystemSetting::setKey('referral_recharge_percent', (string) $validated['recharge_percent']);
        }
        if (array_key_exists('max_redeem_percent', $validated)) {
            SystemSetting::setKey('referral_max_redeem_percent', (string) $validated['max_redeem_percent']);
        }
        if (array_key_exists('app_link', $validated)) {
            SystemSetting::setKey('referral_app_link', (string) ($validated['app_link'] ?? ''));
        }

        if (class_exists(AdminAuditLog::class)) {
            AdminAuditLog::create([
                'admin_id'   => $request->user()?->id,
                'action'     => 'update_referral_global_settings',
                'model_type' => SystemSetting::class,
                'details'    => json_encode($validated),
            ]);
        }

        return $this->successResponse(
            $referralService->getGlobalConfig(),
            'Global referral settings updated successfully'
        );
    }

    /**
     * Get a specific shop's referral overrides, resolved config, and wallet summary.
     */
    public function getShopReferralSettings($shopId, ReferralService $referralService): JsonResponse
    {
        $shop = Shop::find($shopId);
        if (!$shop) {
            return $this->errorResponse('Shop not found', 404);
        }

        return $this->successResponse([
            'shop_id'           => $shop->id,
            'shop_name'         => $shop->name,
            'referral_code'     => $shop->referral_code,
            'referred_by_shop'  => $shop->referrer ? [
                'id'   => $shop->referrer->id,
                'name' => $shop->referrer->name,
            ] : null,
            'points_balance'    => (float) ($shop->referral_points_balance ?? 0),
            'overrides'         => [
                'referral_enabled_override'          => $shop->referral_enabled_override,
                'referral_reward_mode_override'      => $shop->referral_reward_mode_override,
                'custom_referral_signup_points'      => $shop->custom_referral_signup_points,
                'custom_referral_recharge_percent'   => $shop->custom_referral_recharge_percent,
                'custom_referral_max_redeem_percent' => $shop->custom_referral_max_redeem_percent,
            ],
            'effective_config'  => $referralService->resolveConfig($shop),
            'global_defaults'   => $referralService->getGlobalConfig(),
        ], 'Shop referral settings retrieved');
    }

    /**
     * Update shop-wise referral overrides (pass null to revert any field to global common setting).
     */
    public function updateShopReferralSettings(Request $request, $shopId, ReferralService $referralService): JsonResponse
    {
        $shop = Shop::find($shopId);
        if (!$shop) {
            return $this->errorResponse('Shop not found', 404);
        }

        $validated = $request->validate([
            'referral_enabled_override'          => 'nullable|boolean',
            'referral_reward_mode_override'      => 'nullable|string|in:signup_and_recharge,recharge_only',
            'custom_referral_signup_points'      => 'nullable|numeric|min:0',
            'custom_referral_recharge_percent'   => 'nullable|numeric|min:0|max:100',
            'custom_referral_max_redeem_percent' => 'nullable|numeric|min:0|max:100',
        ]);

        $shop->update([
            'referral_enabled_override'          => $request->has('referral_enabled_override') ? $validated['referral_enabled_override'] : $shop->referral_enabled_override,
            'referral_reward_mode_override'      => $request->has('referral_reward_mode_override') ? $validated['referral_reward_mode_override'] : $shop->referral_reward_mode_override,
            'custom_referral_signup_points'      => $request->has('custom_referral_signup_points') ? $validated['custom_referral_signup_points'] : $shop->custom_referral_signup_points,
            'custom_referral_recharge_percent'   => $request->has('custom_referral_recharge_percent') ? $validated['custom_referral_recharge_percent'] : $shop->custom_referral_recharge_percent,
            'custom_referral_max_redeem_percent' => $request->has('custom_referral_max_redeem_percent') ? $validated['custom_referral_max_redeem_percent'] : $shop->custom_referral_max_redeem_percent,
        ]);

        return $this->successResponse([
            'shop_id'          => $shop->id,
            'overrides'        => [
                'referral_enabled_override'          => $shop->referral_enabled_override,
                'referral_reward_mode_override'      => $shop->referral_reward_mode_override,
                'custom_referral_signup_points'      => $shop->custom_referral_signup_points,
                'custom_referral_recharge_percent'   => $shop->custom_referral_recharge_percent,
                'custom_referral_max_redeem_percent' => $shop->custom_referral_max_redeem_percent,
            ],
            'effective_config' => $referralService->resolveConfig($shop->fresh()),
        ], 'Shop referral settings updated');
    }

    /**
     * Admin manual points credit/debit for a shop.
     */
    public function adjustShopPoints(Request $request, $shopId, ReferralService $referralService): JsonResponse
    {
        $shop = Shop::find($shopId);
        if (!$shop) {
            return $this->errorResponse('Shop not found', 404);
        }

        $validated = $request->validate([
            'type'   => 'required|string|in:credit,debit',
            'points' => 'required|numeric|min:0.01',
            'reason' => 'required|string|max:255',
        ]);

        if ($validated['type'] === 'credit') {
            $tx = $referralService->creditPoints(
                shop: $shop,
                points: (float) $validated['points'],
                source: 'admin_adjustment',
                description: "Admin Credit: {$validated['reason']}"
            );
            return $this->successResponse([
                'points_balance' => (float) $shop->fresh()->referral_points_balance,
                'transaction'    => $tx,
            ], 'Points credited successfully');
        }

        $ok = $referralService->debitPoints(
            shop: $shop,
            points: (float) $validated['points'],
            source: 'admin_adjustment',
            description: "Admin Debit: {$validated['reason']}"
        );

        if (!$ok) {
            return $this->errorResponse('Insufficient points balance to debit.', 422);
        }

        return $this->successResponse([
            'points_balance' => (float) $shop->fresh()->referral_points_balance,
        ], 'Points debited successfully');
    }

    /**
     * Overall referral analytics for Admin dashboard.
     */
    public function overview(Request $request, ReferralService $referralService): JsonResponse
    {
        $totalCredited = (float) ReferralPointTransaction::where('type', 'credit')->sum('points');
        $totalRedeemed = (float) ReferralPointTransaction::where('type', 'debit')->sum('points');
        $totalReferredShops = Shop::whereNotNull('referred_by_shop_id')->count();

        $search = trim((string) $request->query('search', ''));
        $type = trim((string) $request->query('type', ''));
        $source = trim((string) $request->query('source', ''));

        $topReferrersQuery = Shop::withCount('referredShops')
            ->having('referred_shops_count', '>', 0);

        if ($search !== '') {
            $topReferrersQuery->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('owner_name', 'like', "%{$search}%")
                    ->orWhere('referral_code', 'like', "%{$search}%");
            });
        }

        $topReferrers = $topReferrersQuery
            ->orderByDesc('referred_shops_count')
            ->limit(10)
            ->get(['id', 'name', 'owner_name', 'referral_code', 'referral_points_balance']);

        $txQuery = ReferralPointTransaction::with([
                'shop:id,name',
                'relatedShop:id,name',
                'paymentTransaction:id,amount,gateway_response',
            ]);

        if (in_array($type, ['credit', 'debit'], true)) {
            $txQuery->where('type', $type);
        }
        if ($source !== '') {
            $txQuery->where('source', $source);
        }
        if ($search !== '') {
            $txQuery->where(function ($q) use ($search) {
                $q->where('description', 'like', "%{$search}%")
                    ->orWhereHas('shop', function ($sq) use ($search) {
                        $sq->where('name', 'like', "%{$search}%")
                            ->orWhere('referral_code', 'like', "%{$search}%");
                    });
            });
        }

        $recentTransactions = $txQuery
            ->orderByDesc('id')
            ->limit(50)
            ->get();

        return $this->successResponse([
            'global_config'        => $referralService->getGlobalConfig(),
            'total_credited'       => round($totalCredited, 2),
            'total_redeemed'       => round($totalRedeemed, 2),
            'total_referred_shops' => $totalReferredShops,
            'top_referrers'        => $topReferrers,
            'recent_transactions'  => $recentTransactions,
        ], 'Referral overview retrieved');
    }
}

