<?php

namespace App\Services;

use App\Models\ReferralPointTransaction;
use App\Models\Shop;
use App\Models\SystemSetting;
use Illuminate\Support\Facades\DB;

class ReferralService
{
    /**
     * Get global/common referral configuration from system_settings.
     */
    public function getGlobalConfig(): array
    {
        return [
            'enabled'            => filter_var(SystemSetting::getByKey('referral_enabled', '1'), FILTER_VALIDATE_BOOLEAN),
            'reward_mode'        => SystemSetting::getByKey('referral_reward_mode', 'signup_and_recharge') ?: 'signup_and_recharge',
            'signup_points'      => (float) (SystemSetting::getByKey('referral_signup_points', '50') ?? 50),
            'welcome_points'     => (float) (SystemSetting::getByKey('referral_welcome_points', '0') ?? 0),
            'recharge_percent'   => (float) (SystemSetting::getByKey('referral_recharge_percent', '10') ?? 10),
            'max_redeem_percent' => (float) (SystemSetting::getByKey('referral_max_redeem_percent', '50') ?? 50),
            'app_link'           => (string) (SystemSetting::getByKey('referral_app_link', '') ?? ''),
        ];
    }

    /**
     * Resolve effective referral config for a specific shop.
     * Priority 1: Shop-wise override (if not null)
     * Priority 2: Common global setting
     */
    public function resolveConfig(Shop $shop): array
    {
        $global = $this->getGlobalConfig();

        $enabled = $shop->referral_enabled_override !== null
            ? (bool) $shop->referral_enabled_override
            : $global['enabled'];

        $rewardMode = ($shop->referral_reward_mode_override !== null && $shop->referral_reward_mode_override !== '')
            ? $shop->referral_reward_mode_override
            : $global['reward_mode'];

        $signupPoints = $shop->custom_referral_signup_points !== null
            ? (float) $shop->custom_referral_signup_points
            : $global['signup_points'];

        $rechargePercent = $shop->custom_referral_recharge_percent !== null
            ? (float) $shop->custom_referral_recharge_percent
            : $global['recharge_percent'];

        $maxRedeemPercent = $shop->custom_referral_max_redeem_percent !== null
            ? (float) $shop->custom_referral_max_redeem_percent
            : $global['max_redeem_percent'];

        $hasOverride = $shop->referral_enabled_override !== null
            || ($shop->referral_reward_mode_override !== null && $shop->referral_reward_mode_override !== '')
            || $shop->custom_referral_signup_points !== null
            || $shop->custom_referral_recharge_percent !== null
            || $shop->custom_referral_max_redeem_percent !== null;

        return [
            'enabled'            => $enabled,
            'reward_mode'        => $rewardMode,
            'signup_points'      => max(0.0, $signupPoints),
            'welcome_points'     => max(0.0, $global['welcome_points']),
            'recharge_percent'   => max(0.0, min(100.0, $rechargePercent)),
            'max_redeem_percent' => max(0.0, min(100.0, $maxRedeemPercent)),
            'app_link'           => $global['app_link'],
            'is_custom_override' => $hasOverride,
        ];
    }

    /**
     * Clean and find a referring shop by code.
     */
    public function findReferrerByCode(?string $rawCode, ?int $excludeShopId = null): ?Shop
    {
        if (!$rawCode) {
            return null;
        }

        $clean = strtoupper(trim($rawCode));
        $clean = preg_replace('/^REF[_:-]+/i', '', $clean);
        if (!$clean) {
            return null;
        }

        $query = Shop::where('referral_code', $clean)->where('status', 'active');
        if ($excludeShopId) {
            $query->where('id', '!=', $excludeShopId);
        }

        return $query->first();
    }

    /**
     * Link a newly registered shop to its referrer and award signup points if eligible.
     */
    public function handleSignupReferral(Shop $newShop, ?string $referralCode): void
    {
        $referrer = $this->findReferrerByCode($referralCode, $newShop->id);
        if (!$referrer) {
            return;
        }

        $refConfig = $this->resolveConfig($referrer);
        if (!$refConfig['enabled']) {
            return;
        }

        // Link permanently so even in 'recharge_only' mode future recharges reward the referrer
        $newShop->referred_by_shop_id = $referrer->id;
        $newShop->save();

        // Award signup points only if referrer's resolved mode allows signup rewards
        if ($refConfig['reward_mode'] === 'signup_and_recharge' && $refConfig['signup_points'] > 0) {
            $this->creditPoints(
                shop: $referrer,
                points: $refConfig['signup_points'],
                source: 'signup_bonus',
                description: "Signup bonus for referring {$newShop->name}",
                relatedShopId: $newShop->id
            );
        }

        // Optional welcome points for the newly registered shop
        if ($refConfig['welcome_points'] > 0) {
            $this->creditPoints(
                shop: $newShop,
                points: $refConfig['welcome_points'],
                source: 'welcome_bonus',
                description: "Welcome bonus via referral from {$referrer->name}",
                relatedShopId: $referrer->id
            );
        }
    }

    /**
     * Award recurring percentage commission to referrer on every paid plan recharge.
     * Calculated strictly on actual cash paid (excluding redeemed points).
     */
    public function handleRechargeCommission(
        Shop $payingShop,
        float $actualCashPaid,
        ?int $subscriptionId = null,
        ?int $paymentTransactionId = null
    ): float {
        if (!$payingShop->referred_by_shop_id || $actualCashPaid <= 0) {
            return 0.0;
        }

        $referrer = Shop::find($payingShop->referred_by_shop_id);
        if (!$referrer || $referrer->status !== 'active') {
            return 0.0;
        }

        $refConfig = $this->resolveConfig($referrer);
        if (!$refConfig['enabled'] || $refConfig['recharge_percent'] <= 0) {
            return 0.0;
        }

        $commission = round(($actualCashPaid * $refConfig['recharge_percent']) / 100, 2);
        if ($commission <= 0) {
            return 0.0;
        }

        $this->creditPoints(
            shop: $referrer,
            points: $commission,
            source: 'recharge_commission',
            description: "{$refConfig['recharge_percent']}% commission on {$payingShop->name}'s recharge (₹" . number_format($actualCashPaid, 2) . ")",
            relatedShopId: $payingShop->id,
            subscriptionId: $subscriptionId,
            paymentTransactionId: $paymentTransactionId,
            meta: [
                'cash_paid'          => $actualCashPaid,
                'commission_percent' => $refConfig['recharge_percent'],
            ]
        );

        return $commission;
    }

    /**
     * Calculate how many points a shop can redeem on a plan recharge.
     */
    public function calculateRedemption(Shop $shop, float $planPrice, bool $usePoints): array
    {
        $config = $this->resolveConfig($shop);
        $walletBalance = max(0.0, (float) ($shop->referral_points_balance ?? 0));
        $maxPercent = (float) $config['max_redeem_percent'];

        $maxAllowedByPercent = round(($planPrice * $maxPercent) / 100, 2);
        $maxRedeemable = max(0.0, round(min($walletBalance, $maxAllowedByPercent, $planPrice), 2));

        $pointsToUse = $usePoints ? $maxRedeemable : 0.0;
        $finalPayable = max(0.0, round($planPrice - $pointsToUse, 2));

        return [
            'points_used'        => $pointsToUse,
            'final_payable'      => $finalPayable,
            'max_redeemable'     => $maxRedeemable,
            'max_redeem_percent' => $maxPercent,
            'wallet_balance'     => $walletBalance,
        ];
    }

    /**
     * Atomically credit points to a shop wallet and record passbook entry.
     */
    public function creditPoints(
        Shop $shop,
        float $points,
        string $source,
        string $description,
        ?int $relatedShopId = null,
        ?int $subscriptionId = null,
        ?int $paymentTransactionId = null,
        array $meta = []
    ): ?ReferralPointTransaction {
        if ($points <= 0) {
            return null;
        }

        return DB::transaction(function () use (
            $shop,
            $points,
            $source,
            $description,
            $relatedShopId,
            $subscriptionId,
            $paymentTransactionId,
            $meta
        ) {
            $lockedShop = Shop::where('id', $shop->id)->lockForUpdate()->first();
            if (!$lockedShop) {
                return null;
            }

            $newBalance = round(((float) $lockedShop->referral_points_balance) + $points, 2);
            $lockedShop->referral_points_balance = $newBalance;
            $lockedShop->save();

            return ReferralPointTransaction::create([
                'shop_id'                => $lockedShop->id,
                'related_shop_id'        => $relatedShopId,
                'subscription_id'        => $subscriptionId,
                'payment_transaction_id' => $paymentTransactionId,
                'type'                   => 'credit',
                'source'                 => $source,
                'points'                 => round($points, 2),
                'balance_after'          => $newBalance,
                'description'            => $description,
                'meta'                   => !empty($meta) ? $meta : null,
            ]);
        });
    }

    /**
     * Atomically debit points from a shop wallet for plan recharge only.
     */
    public function debitPoints(
        Shop $shop,
        float $points,
        string $source,
        string $description,
        ?int $subscriptionId = null,
        ?int $paymentTransactionId = null,
        array $meta = []
    ): bool {
        if ($points <= 0) {
            return true;
        }

        return DB::transaction(function () use (
            $shop,
            $points,
            $source,
            $description,
            $subscriptionId,
            $paymentTransactionId,
            $meta
        ) {
            $lockedShop = Shop::where('id', $shop->id)->lockForUpdate()->first();
            if (!$lockedShop) {
                return false;
            }

            $currentBalance = (float) $lockedShop->referral_points_balance;
            if ($currentBalance < $points) {
                return false;
            }

            $newBalance = round($currentBalance - $points, 2);
            $lockedShop->referral_points_balance = $newBalance;
            $lockedShop->save();

            ReferralPointTransaction::create([
                'shop_id'                => $lockedShop->id,
                'subscription_id'        => $subscriptionId,
                'payment_transaction_id' => $paymentTransactionId,
                'type'                   => 'debit',
                'source'                 => $source,
                'points'                 => round($points, 2),
                'balance_after'          => $newBalance,
                'description'            => $description,
                'meta'                   => !empty($meta) ? $meta : null,
            ]);

            return true;
        });
    }
}

