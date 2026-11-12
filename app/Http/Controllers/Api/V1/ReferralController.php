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

        // Referred shops + total points earned from each
        $referredShops = Shop::where('referred_by_shop_id', $shop->id)
            ->orderByDesc('created_at')
            ->get(['id', 'name', 'owner_name', 'status', 'created_at']);

        $earnedByRelatedShop = ReferralPointTransaction::where('shop_id', $shop->id)
            ->where('type', 'credit')
            ->whereNotNull('related_shop_id')
            ->selectRaw('related_shop_id, SUM(points) as total_points')
            ->groupBy('related_shop_id')
            ->pluck('total_points', 'related_shop_id');

        $referralsList = $referredShops->map(function ($rs) use ($earnedByRelatedShop) {
            return [
                'id'            => $rs->id,
                'shop_name'     => $rs->name,
                'owner_name'    => $rs->owner_name,
                'joined_at'     => $rs->created_at?->format('d M Y'),
                'points_earned' => (float) ($earnedByRelatedShop[$rs->id] ?? 0),
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
}

